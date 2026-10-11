/// Place reminder rules (LOC-4…LOC-8, LOC-13): active days, hours, what can ring now, and the geofence
/// set Dart hands to Kotlin. Kotlin repeats the same checks when a geofence fires (places/PlaceRules.kt).
library;

import 'dart:convert';

import '../model/enums.dart';
import '../model/place.dart';
import '../model/prefs.dart';
import '../model/reminder.dart';
import '../planner/alarm_planner.dart';
import '../recurrence/recurrence.dart';
import '../time/calendar.dart';
import '../time/zones.dart';

/// LOC-6: "Every time" rings at most this often per reminder.
const placeEveryTimeGap = Duration(hours: 1);

/// LOC-4: occurrence keys (days at 00:00) of [r] between [fromDay] and [toDay] inclusive.
/// "Any day" has a single occurrence keyed on the day it was made, whatever the range.
List<DateTime> placeOccurrenceKeys(Reminder r, DateTime fromDay, DateTime toDay) {
  final t = r.place!;
  final from = dateOnly(fromDay), to = dateOnly(toDay);
  final start = dateOnly(r.timing.start);
  switch (t.active) {
    case PlaceActive.anyDay:
      return [start];
    case PlaceActive.onDate:
      return start.isBefore(from) || start.isAfter(to) ? const [] : [start];
    case PlaceActive.repeats:
      final rule = r.rrule;
      if (rule == null) return start.isBefore(from) || start.isAfter(to) ? const [] : [start];
      return [
        for (final d in RecurrenceRule.parse(rule).expand(start, from: from, to: to.add(const Duration(hours: 23))))
          dateOnly(d),
      ];
  }
}

/// LOC-5: the day whose hours contain [wall] (device local time), or null when it's outside the hours.
/// A range that ends at or before it starts runs past midnight and belongs to the day it starts.
DateTime? placeWindowDay(PlaceTrigger t, DateTime wall) {
  final day = dateOnly(wall);
  if (t.anyTime) return day;
  final m = wall.hour * 60 + wall.minute;
  final from = t.hoursFrom!.minutes, to = t.hoursTo!.minutes;
  if (from < to) return m >= from && m < to ? day : null;
  if (m >= from) return day; // evening part
  if (m < to) return addDays(day, -1); // after midnight → yesterday's window
  return null;
}

/// LOC-7 (without fire history): the occurrence key [r] would ring for at [wall], or null when today
/// isn't an active day, it's outside the hours, or the reminder is paused.
DateTime? placeKeyAt(Reminder r, DateTime wall) {
  final t = r.place!;
  if (t.paused) return null;
  final day = placeWindowDay(t, wall);
  if (day == null) return null;
  if (t.active == PlaceActive.anyDay) return dateOnly(r.timing.start);
  return placeOccurrenceKeys(r, day, day).isEmpty ? null : day;
}

/// LOC-7: does [event] at [wall] ring [r]? [occurrence] = saved state of the occurrence it would ring,
/// [lastFire] = when this reminder last rang (any occurrence) for the "Every time" gap.
bool placeShouldRing(
  Reminder r,
  PlaceEvent event,
  DateTime wall, {
  required DateTime now,
  Occurrence? occurrence,
  DateTime? lastFire,
}) {
  final t = r.place!;
  if (!t.fires(event) || r.meta.isDeleted || r.status != ReminderStatus.active) return false;
  if (placeKeyAt(r, wall) == null) return false;
  if (occurrence != null && occurrence.state.isResolved) return false;
  if (t.remind == PlaceRemind.firstTime) return occurrence?.firedAt == null;
  return lastFire == null || !now.isBefore(lastFire.add(placeEveryTimeGap));
}

/// "Active now" dot (S-19): could ring right now if the user arrived or left.
bool placeActiveNow(Reminder r, DateTime wall, {Occurrence? occurrence}) {
  final t = r.place!;
  if (r.meta.isDeleted || r.status != ReminderStatus.active) return false;
  final key = placeKeyAt(r, wall);
  if (key == null) return false;
  if (occurrence != null && occurrence.occurrenceKey == key) {
    if (occurrence.state.isResolved) return false;
    if (t.remind == PlaceRemind.firstTime && occurrence.firedAt != null) return false;
  }
  return true;
}

/// LOC-8: an "On a date" or finished "Repeats" reminder with no active day left after [today] (and none
/// waiting to be done) is over — the app archives it (DAT-3).
bool placeExpired(Reminder r, DateTime today, {required bool hasOpenFired}) {
  final t = r.place!;
  if (hasOpenFired) return false;
  switch (t.active) {
    case PlaceActive.anyDay:
      return false;
    case PlaceActive.onDate:
      return dateOnly(r.timing.start).isBefore(dateOnly(today));
    case PlaceActive.repeats:
      if (r.rrule == null) return dateOnly(r.timing.start).isBefore(dateOnly(today));
      final rule = RecurrenceRule.parse(r.rrule!);
      if (rule.until == null && rule.count == null) return false;
      return placeOccurrenceKeys(r, today, DateTime.utc(9999)).isEmpty;
  }
}

/// One reminder inside a geofence payload (LOC-13).
class GeofenceReminder {
  const GeofenceReminder({
    required this.reminderId,
    required this.title,
    required this.arrivedBody,
    required this.leftBody,
    required this.trigger,
    required this.days,
  });

  final String reminderId;
  final String title;

  /// Notification bodies, already localized (copy.md `notif.place.*`).
  final String arrivedBody;
  final String leftBody;
  final PlaceTrigger trigger;

  /// Active days in the window → occurrence id. "Any day" has one entry with day = null.
  final List<({DateTime? day, String occurrenceId})> days;

  Map<String, Object?> toJson() => {
    'id': reminderId,
    'title': title,
    'arrived': arrivedBody,
    'left': leftBody,
    'arrive': trigger.onArrive,
    'leave': trigger.onLeave,
    'from': trigger.hoursFrom?.minutes ?? -1,
    'to': trigger.hoursTo?.minutes ?? -1,
    'every': trigger.remind == PlaceRemind.everyTime,
    'days': [
      for (final d in days) {'day': d.day == null ? null : _ymd(d.day!), 'occ': d.occurrenceId},
    ],
  };
}

/// One geofence for one place (LOC-13): transitions = union of its reminders' Arrive/Leave.
class GeofencePlan {
  const GeofencePlan({required this.place, required this.reminders});

  final Place place;
  final List<GeofenceReminder> reminders;

  bool get arrive => reminders.any((r) => r.trigger.onArrive);
  bool get leave => reminders.any((r) => r.trigger.onLeave);

  /// What Kotlin keeps in native.db `geofences.payload`.
  String payloadJson({required Duration lateCutoff}) => jsonEncode({
    'place': place.name,
    'late_ms': lateCutoff.inMilliseconds,
    'reminders': [for (final r in reminders) r.toJson()],
  });
}

typedef PlaceTextBuilder = ({String arrived, String left}) Function(Place place);

/// LOC-13: geofences for every place with an unpaused, unresolved place reminder active today or in the
/// next [window] (Any day always counts). [saved] = occurrences keyed like the planner.
List<GeofencePlan> planGeofences({
  required List<Reminder> reminders,
  required Map<String, Place> places,
  required Map<String, Occurrence> saved,
  required UserPrefs prefs,
  required DateTime now,
  required PlaceTextBuilder text,
  Duration window = const Duration(days: 14),
}) {
  final today = dateOnly(instantToWall(now, prefs.deviceTimeZone));
  final last = addDays(today, window.inDays);
  final byPlace = <String, List<GeofenceReminder>>{};
  for (final r in reminders) {
    final t = r.place;
    if (t == null || t.paused || r.meta.isDeleted || r.status != ReminderStatus.active) continue;
    final place = places[t.placeId];
    if (place == null || place.meta.isDeleted) continue;
    // Yesterday too: a window past midnight still belongs to yesterday (LOC-5).
    final keys = placeOccurrenceKeys(r, addDays(today, -1), last);
    final days = <({DateTime? day, String occurrenceId})>[];
    for (final k in keys) {
      final id = AlarmPlanner.occurrenceId(r.id, k);
      if (saved[id]?.state.isResolved ?? false) continue; // done / skipped
      days.add((day: t.active == PlaceActive.anyDay ? null : k, occurrenceId: id));
    }
    if (days.isEmpty) continue;
    final words = text(place);
    (byPlace[place.id] ??= []).add(GeofenceReminder(
      reminderId: r.id,
      title: r.title,
      arrivedBody: words.arrived,
      leftBody: words.left,
      trigger: t,
      days: days,
    ));
  }
  return [
    for (final e in byPlace.entries) GeofencePlan(place: places[e.key]!, reminders: e.value),
  ];
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
