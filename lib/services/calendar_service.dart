/// Device calendar import (CAL-1…10): reads the selected calendars, keeps the events in memory as
/// read-only reminders with overlays applied, and feeds them to views and the alarm planner.
library;

import 'dart:async';

import 'package:reminder_core/reminder_core.dart';

import '../data/overlay_repository.dart';
import '../data/prefs_repository.dart';
import '../native/platform_gateway.dart';

/// What the service needs from the platform (PlatformGateway in the app, a fake in tests).
abstract class CalendarReader {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<List<DeviceCalendar>> calendars();
  Future<List<CalendarEvent>> events({required DateTime from, required DateTime to, required Set<String> calendarIds});
}

class PlatformCalendarReader implements CalendarReader {
  PlatformCalendarReader(this._p);
  final PlatformGateway _p;
  @override
  Future<bool> hasPermission() => _p.hasCalendarPermission();
  @override
  Future<bool> requestPermission() => _p.requestCalendarPermission();
  @override
  Future<List<DeviceCalendar>> calendars() => _p.calendars();
  @override
  Future<List<CalendarEvent>> events({required DateTime from, required DateTime to, required Set<String> calendarIds}) =>
      _p.events(from: from, to: to, calendarIds: calendarIds);
}

class CalendarService {
  CalendarService({required this.reader, required this.prefs, required this.overlays, required this.deviceId});

  final CalendarReader reader;
  final PrefsRepository prefs;
  final OverlayRepository overlays;
  final String deviceId;

  final _changes = StreamController<List<Reminder>>.broadcast();
  List<CalendarEvent> _events = const [];
  List<Reminder> _reminders = const [];
  List<DeviceCalendar> calendars = const [];
  bool permission = false;
  DateTime? _lastRefresh;

  /// CAL-8 titles to mention once in the digest.
  final removedTitles = <String>[];

  /// Imported events as reminders (empty when not connected or permission revoked, CAL-10).
  List<Reminder> get reminders => _reminders;
  List<CalendarEvent> get events => _events;
  Stream<List<Reminder>> get changes => _changes.stream;

  bool get connected => prefs.flag(PrefKeys.calendarConnected);
  Set<String> get selected => prefs.stringSet(PrefKeys.selectedCalendars);

  /// Onboarding S-03/S-04 and Settings S-55: ask for permission, then load calendars.
  Future<bool> connect() async {
    permission = await reader.requestPermission();
    if (!permission) return false;
    calendars = await reader.calendars();
    if (prefs.raw(PrefKeys.selectedCalendars) == null) {
      // All on by default (S-04); the contacts birthday calendar stays off while contacts import is on (CON-7).
      await prefs.set(PrefKeys.selectedCalendars, [for (final c in calendars) c.id]);
    }
    await prefs.set(PrefKeys.calendarConnected, true);
    await refresh(force: true);
    return true;
  }

  Future<void> disconnect() async {
    await prefs.set(PrefKeys.calendarConnected, false);
    _set(const [], const []);
  }

  Future<void> setSelected(Set<String> ids) async {
    await prefs.set(PrefKeys.selectedCalendars, ids.toList());
    await refresh(force: true);
  }

  /// CAL-2: window 1 day ago → 60 days ahead; on app open (at most every 15 min unless forced).
  Future<void> refresh({bool force = false, DateTime? now}) async {
    final t = now ?? DateTime.now().toUtc();
    if (!force && _lastRefresh != null && t.difference(_lastRefresh!) < const Duration(minutes: 15)) {
      await rebuild();
      return;
    }
    _lastRefresh = t;
    if (!connected) return _set(const [], const []);
    try {
      permission = await reader.hasPermission();
      if (!permission) return _set(const [], const []); // CAL-10: hidden, overlays kept
      calendars = await reader.calendars();
      final contactsOn = prefs.flag(PrefKeys.contactsImport);
      final birthdayCals = {for (final c in calendars) if (c.isBirthdays) c.id};
      final ids = selected.where((id) => !(contactsOn && birthdayCals.contains(id))).toSet(); // CON-7
      final events = await reader.events(
        from: t.subtract(const Duration(days: 1)),
        to: t.add(const Duration(days: 60)),
        calendarIds: ids,
      );
      final orphaned = await overlays.markOrphans({for (final e in events) '${e.calendarId}/${e.eventId}'});
      removedTitles.addAll(orphaned.map((o) => o.eventId)); // titles aren't kept; digest shows a count
      _events = events;
      await rebuild();
    } catch (_) {
      // errCalendar is shown by the UI when needed; keep the last good data.
    }
  }

  /// Re-applies overlays (after "Remind me" or a type correction).
  Future<void> rebuild() async {
    final ov = await overlays.all();
    _set(_events, [for (final e in _events) reminderFromEvent(e, overlays: ov, deviceId: deviceId)]);
  }

  CalendarEvent? eventFor(Reminder r) {
    final s = r.source;
    if (s is! DeviceCalendarSource) return null;
    return _events.where((e) => e.instanceId == r.id).firstOrNull;
  }

  DeviceCalendar? calendarFor(Reminder r) {
    final s = r.source;
    if (s is! DeviceCalendarSource) return null;
    return calendars.where((c) => c.id == s.calendarId).firstOrNull;
  }

  /// CAL-6 "Remind me" (S-32): [series] applies to every instance.
  Future<void> remindMe(Reminder r, List<AlertStage> plan, {required bool series}) async {
    final e = eventFor(r);
    if (e == null) return;
    await overlays.save(
      calendarId: e.calendarId,
      eventId: e.eventId,
      instanceBegin: series ? null : e.begin,
      alertPlan: plan,
    );
    await rebuild();
  }

  /// CAL-5: type/context corrections apply to the whole series.
  Future<void> correct(Reminder r, {Kind? kind, ReminderContext? context}) async {
    final e = eventFor(r);
    if (e == null) return;
    await overlays.save(calendarId: e.calendarId, eventId: e.eventId, kindOverride: kind, contextOverride: context);
    await rebuild();
  }

  void _set(List<CalendarEvent> events, List<Reminder> reminders) {
    _events = events;
    _reminders = reminders;
    _changes.add(reminders);
  }
}
