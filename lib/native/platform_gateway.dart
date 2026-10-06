/// Dart side of the platform bridge (pigeons/platform_api.dart): device calendar (CAL-*), share
/// target (S-63), launch actions from the tile / widget / notifications (S-61, S-62, NTF-3), backup
/// files (DAT-5) and the home-screen widget.
library;

import 'dart:async';

import 'package:reminder_core/reminder_core.dart';

import 'platform_api.g.dart';

export 'platform_api.g.dart' show DeviceCalendar, DeviceEvent;

/// DeviceEvent → core CalendarEvent. All-day instances already start at UTC midnight.
CalendarEvent calendarEventFrom(DeviceEvent e, {required bool fromBirthdayCalendar}) {
  final rrule = e.rrule;
  return CalendarEvent(
    calendarId: e.calendarId,
    eventId: e.eventId,
    title: e.title,
    begin: DateTime.fromMillisecondsSinceEpoch(e.beginMs, isUtc: true),
    end: DateTime.fromMillisecondsSinceEpoch(e.endMs, isUtc: true),
    allDay: e.allDay,
    timeZone: e.timeZone,
    recurring: rrule != null && rrule.isNotEmpty,
    yearly: rrule != null && rrule.contains('FREQ=YEARLY'),
    otherAttendees: e.otherAttendees,
    fromBirthdayCalendar: fromBirthdayCalendar,
  );
}

class PlatformGateway implements PlatformFlutterApi {
  PlatformGateway([PlatformHostApi? api]) : _api = api ?? PlatformHostApi();

  final PlatformHostApi _api;
  final _shared = StreamController<String>.broadcast();
  final _actions = StreamController<String>.broadcast();
  bool _listening = false;

  /// Registers for pushes from Kotlin (app already running). Call once the binding is ready.
  void listen() {
    if (_listening) return;
    _listening = true;
    PlatformFlutterApi.setUp(this);
  }

  /// Shared text arriving while the app runs (S-63).
  Stream<String> get sharedText {
    listen();
    return _shared.stream;
  }

  /// `capture` or `open:<alarmKey>` arriving while the app runs.
  Stream<String> get launchActions {
    listen();
    return _actions.stream;
  }

  @override
  void onSharedText(String text) => _shared.add(text);

  @override
  void onLaunchAction(String action) => _actions.add(action);

  // ---- calendar ----

  Future<bool> hasCalendarPermission() => _api.hasCalendarPermission();
  Future<bool> requestCalendarPermission() => _api.requestCalendarPermission();
  Future<List<DeviceCalendar>> calendars() => _api.readCalendars();

  Future<List<CalendarEvent>> events({
    required DateTime from,
    required DateTime to,
    required Set<String> calendarIds,
  }) async {
    if (calendarIds.isEmpty) return const [];
    final cals = await _api.readCalendars();
    final birthdays = {for (final c in cals) if (c.isBirthdays) c.id};
    final raw = await _api.readEvents(from.millisecondsSinceEpoch, to.millisecondsSinceEpoch, calendarIds.toList());
    return [for (final e in raw) calendarEventFrom(e, fromBirthdayCalendar: birthdays.contains(e.calendarId))];
  }

  // ---- launch inputs ----

  Future<String?> takeSharedText() => _api.takeSharedText();
  Future<String?> takeLaunchAction() => _api.takeLaunchAction();

  // ---- backup, widget, device ----

  Future<String?> saveBackup(String fileName, String json) => _api.saveBackup(fileName, json);
  Future<String?> openBackup() => _api.openBackup();
  Future<void> updateWidget(String json) => _api.updateWidget(json);
  Future<String> deviceBrand() => _api.deviceBrand();
}
