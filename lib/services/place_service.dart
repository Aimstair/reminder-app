/// Places and place reminders (LOC-*): saving places, deleting them with their reminders (LOC-2),
/// keeping the native geofences in step with the data (LOC-13) and the location status (PRM-10).
library;

import 'dart:async';

import 'package:reminder_core/reminder_core.dart';

import '../data/place_repository.dart';
import '../data/reminder_repository.dart';
import '../native/place_gateway.dart';
import 'reminder_service.dart';

/// Last geofence sync, for the Places banners (LOC-14, PRM-10).
class GeofenceState {
  const GeofenceState({this.registered = 0, this.requested = 0, this.error});
  final int registered;
  final int requested;

  /// `permission` · `location_off` · `play_services` · `register_failed`; null when fine.
  final String? error;

  bool get overLimit => error == null && requested > registered;
}

class PlaceService {
  PlaceService({
    required this.places,
    required this.reminders,
    required this.service,
    required this.gateway,
    required this.prefs,
    required this.text,
    Clock? clock,
  }) : _now = clock ?? (() => DateTime.now().toUtc());

  final PlaceRepository places;
  final ReminderRepository reminders;
  final ReminderService service;
  final PlaceGateway gateway;
  final UserPrefs Function() prefs;

  /// Localized "Arrived at {place}" / "Left {place}" (copy.md §2).
  final PlaceTextBuilder text;
  final Clock _now;

  /// Places by id, kept current for notification text and the parser (PRS-43).
  Map<String, Place> byId = const {};
  StreamSubscription<List<Place>>? _sub;

  final _state = StreamController<GeofenceState>.broadcast();
  GeofenceState state = const GeofenceState();
  Stream<GeofenceState> get states => _state.stream;

  LocationStatus status = LocationStatus.allGranted;

  Future<void> start() async {
    byId = {for (final p in await places.all()) p.id: p};
    _sub = places.watchAll().listen((list) => byId = {for (final p in list) p.id: p});
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _state.close();
  }

  /// PRM-5 / PRM-10: re-read on app open and when a screen comes back from Settings.
  Future<LocationStatus> refreshStatus() async {
    try {
      status = await gateway.status();
    } catch (_) {}
    return status;
  }

  Future<void>? _running;
  var _again = false;

  /// LOC-13: register the geofence set computed from the current data. Called after every alarm sync;
  /// runs one at a time, and once more if data changed while a sync was running.
  Future<void> syncGeofences() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = () async {
      try {
        do {
          _again = false;
          await _syncOnce();
        } while (_again);
      } finally {
        _running = null;
      }
    }();
  }

  Future<void> _syncOnce() async {
    final active = await reminders.watchActive().first;
    final p = prefs();
    final plans = planGeofences(
      reminders: active.where((r) => r.kind == Kind.place).toList(),
      places: byId,
      saved: await service.occurrences.byPlannerId(),
      prefs: p,
      now: _now(),
      text: text,
    );
    try {
      final r = await gateway.sync(plans, p.lateAlertCutoff ?? const Duration(days: 3650));
      state = GeofenceState(registered: r.registered, requested: r.requested, error: r.error);
    } catch (_) {
      state = GeofenceState(requested: plans.length, error: 'register_failed');
    }
    if (!_state.isClosed) _state.add(state);
  }

  /// LOC-1: a new saved place.
  Future<Place> createPlace({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    int radiusMeters = placeDefaultRadius,
    PlaceIcon icon = PlaceIcon.pin,
    PlaceColor color = PlaceColor.teal,
  }) async {
    final p = await places.create(
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      radiusMeters: radiusMeters,
      icon: icon,
      color: color,
    );
    byId = {...byId, p.id: p};
    return p;
  }

  /// LOC-2: moving or resizing a place re-registers its geofence.
  Future<Place> updatePlace(Place p) async {
    final updated = await places.update(p);
    byId = {...byId, updated.id: updated};
    await service.resync();
    return updated;
  }

  /// Place reminders at [placeId] (not deleted).
  Future<List<Reminder>> remindersAt(String placeId) async => [
    for (final r in await reminders.watchAll().first)
      if (r.place?.placeId == placeId) r,
  ];

  /// LOC-2: soft-deletes the place and its reminders. Returns the reminder ids for Undo.
  Future<List<String>> deletePlace(Place p) async {
    final ids = [for (final r in await remindersAt(p.id)) r.id];
    for (final id in ids) {
      await reminders.softDelete(id);
    }
    await places.setDeleted(p.id, true);
    await service.resync();
    return ids;
  }

  Future<void> restorePlace(Place p, List<String> reminderIds) async {
    await places.setDeleted(p.id, false);
    for (final id in reminderIds) {
      await reminders.restore(id);
    }
    await service.resync();
  }

  /// LOC-12: pause / resume one place reminder.
  Future<void> setPaused(Reminder r, bool paused) => service.edit(r.copyWith(place: r.place!.copyWith(paused: paused)));

  /// LOC-8: archive "On a date" / ended "Repeats" reminders with no active day left (part of housekeeping).
  Future<void> archiveExpired() async {
    final p = prefs();
    final today = dateOnly(instantToWall(_now(), p.deviceTimeZone));
    final saved = await service.occurrences.byPlannerId();
    for (final r in await reminders.watchActive().first) {
      if (r.kind != Kind.place) continue;
      final openFired = saved.values.any((o) => o.reminderId == r.id && o.firedAt != null && !o.state.isResolved);
      if (placeExpired(r, today, hasOpenFired: openFired)) {
        await reminders.update(r.copyWith(status: ReminderStatus.archived));
      }
    }
  }
}
