/// Device calendar import (CAL-*): events read from the phone become read-only, never-completable
/// reminders in memory (not stored). User additions live in overlays (CAL-5, CAL-6).
library;

import '../capture/subkind.dart';
import '../model/alert.dart';
import '../model/enums.dart';
import '../model/reminder.dart';
import '../time/calendar.dart';
import '../time/zones.dart';

/// One event instance as read from the device (instants in UTC).
class CalendarEvent {
  const CalendarEvent({
    required this.calendarId,
    required this.eventId,
    required this.title,
    required this.begin,
    required this.end,
    required this.allDay,
    this.timeZone,
    this.recurring = false,
    this.yearly = false,
    this.otherAttendees = 0,
    this.fromBirthdayCalendar = false,
  });

  final String calendarId;

  /// The event (series) id; instances of a recurring event share it.
  final String eventId;
  final String title;
  final DateTime begin;
  final DateTime end;
  final bool allDay;
  final String? timeZone;
  final bool recurring;
  final bool yearly;

  /// Attendees other than the user (CAL-4 rule 3).
  final int otherAttendees;

  /// The device "Birthdays"/contacts calendar (CAL-4 rule 1).
  final bool fromBirthdayCalendar;

  /// Stable id of this instance — also the reminder id the app uses for it.
  String get instanceId => 'cal:$calendarId:$eventId:${begin.millisecondsSinceEpoch}';
}

/// User additions to an imported event (CAL-5, CAL-6). [scope] `series` applies to every instance.
class EventOverlay {
  const EventOverlay({
    required this.id,
    required this.calendarId,
    required this.eventId,
    required this.alertPlan,
    this.instanceBegin,
    this.kindOverride,
    this.contextOverride,
  });

  final String id;
  final String calendarId;
  final String eventId;

  /// Null = whole series; otherwise only the instance starting at this instant.
  final DateTime? instanceBegin;
  final List<AlertStage> alertPlan;
  final Kind? kindOverride;
  final ReminderContext? contextOverride;

  bool appliesTo(CalendarEvent e) =>
      e.calendarId == calendarId && e.eventId == eventId && (instanceBegin == null || instanceBegin == e.begin);
}

/// CAL-4: first matching rule wins. [contactsImportOn] → the birthday calendar is excluded anyway (CON-7).
(Kind, ReminderContext) autoTag(CalendarEvent e) {
  if (e.fromBirthdayCalendar) return (Kind.occasion, ReminderContext.personal);
  if (e.allDay && e.yearly) return (Kind.occasion, ReminderContext.personal);
  if (e.otherAttendees > 0) return (Kind.meeting, ReminderContext.work);
  return (Kind.event, ReminderContext.personal);
}

/// CAL-1/CON-7: which events to import.
bool shouldImport(CalendarEvent e, {required Set<String> selectedCalendars, required bool contactsImportOn}) =>
    selectedCalendars.contains(e.calendarId) && !(contactsImportOn && e.fromBirthdayCalendar);

/// Builds the in-memory reminder for an event instance. Instance-scoped overlays win over series ones.
Reminder reminderFromEvent(CalendarEvent e, {required List<EventOverlay> overlays, required String deviceId}) {
  final matching = overlays.where((o) => o.appliesTo(e)).toList()
    ..sort((a, b) => (a.instanceBegin == null ? 1 : 0).compareTo(b.instanceBegin == null ? 1 : 0));
  final overlay = matching.isEmpty ? null : matching.first;
  final series = overlays.where((o) => o.appliesTo(e) && o.instanceBegin == null).firstOrNull;
  final (kind, context) = autoTag(e);
  final zone = e.allDay ? 'UTC' : (e.timeZone ?? 'UTC');
  final timing = e.allDay
      ? Timing(type: TimingType.date, start: dateOnly(e.begin)) // all-day events are stored at UTC midnight
      : Timing(
          type: TimingType.datetime,
          start: instantToWall(e.begin, zone),
          end: instantToWall(e.end, zone),
          timeZone: zone,
          timeZoneSetManually: true,
        );
  final type = overlay?.kindOverride ?? series?.kindOverride ?? kind;
  return Reminder(
    meta: RecordMeta(id: e.instanceId, createdAt: e.begin, updatedAt: e.begin, deviceId: deviceId),
    title: e.title.trim().isEmpty ? '(No title)' : e.title.trim(),
    kind: type,
    subKind: guessSubKind(type, e.title), // SUB-2
    context: overlay?.contextOverride ?? series?.contextOverride ?? context,
    timing: timing,
    alertPlan: overlay?.alertPlan ?? const [], // CAL-6: no alerts by default
    source: DeviceCalendarSource(calendarId: e.calendarId, eventId: e.eventId),
  );
}

/// CAL-9: similarity of two titles (0…1), Dice coefficient on letter pairs, case/space-insensitive.
double titleSimilarity(String a, String b) {
  List<String> pairs(String s) {
    final t = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return [for (var i = 0; i < t.length - 1; i++) t.substring(i, i + 2)];
  }

  final pa = pairs(a), pb = pairs(b);
  if (pa.isEmpty || pb.isEmpty) return a.trim().toLowerCase() == b.trim().toLowerCase() ? 1 : 0;
  final rest = [...pb];
  var hits = 0;
  for (final p in pa) {
    if (rest.remove(p)) hits++;
  }
  return 2 * hits / (pa.length + pb.length);
}

/// CAL-9: an imported event that looks like the same thing as manual reminder [r] (starts at [rStart]).
CalendarEvent? findDuplicate(Reminder r, DateTime rStart, Iterable<CalendarEvent> events) {
  if (r.isCalendarEvent) return null;
  for (final e in events) {
    if (titleSimilarity(r.title, e.title) >= 0.8 && rStart.difference(e.begin).abs() <= const Duration(minutes: 30)) {
      return e;
    }
  }
  return null;
}
