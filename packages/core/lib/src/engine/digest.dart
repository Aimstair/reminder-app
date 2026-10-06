/// Daily digest (DIG-1…3, OVD-3): what needs attention, computed from the schedule.
library;

import '../model/enums.dart';
import '../model/prefs.dart';
import '../model/reminder.dart';
import '../time/calendar.dart';
import '../time/zones.dart';
import '../views/range.dart';
import '../views/schedule.dart';

class Digest {
  const Digest({
    required this.overdue,
    required this.stale,
    required this.missed,
    required this.upcomingOccasions,
    required this.removedFromCalendar,
  });

  /// DIG-2 §1 (OVD-1), oldest first.
  final List<ScheduleItem> overdue;

  /// OVD-3: overdue for 30+ days — ask "Still relevant?" (subset of [overdue]).
  final List<ScheduleItem> stale;

  /// DIG-2 §2: alerts not shown (SCH-7 beyond cutoff, notifications off). Count from the native fire log.
  final int missed;

  /// DIG-2 §3: occasions in the next 7 days, not yet prepared or done.
  final List<DayItem> upcomingOccasions;

  /// DIG-2 §4 (CAL-8): titles of events with alerts that disappeared from the calendar.
  final List<String> removedFromCalendar;

  bool get isEmpty =>
      overdue.isEmpty && missed == 0 && upcomingOccasions.isEmpty && removedFromCalendar.isEmpty;
}

Digest buildDigest({
  required List<Reminder> reminders,
  required Map<String, Occurrence> saved,
  required UserPrefs prefs,
  required DateTime now,
  int missed = 0,
  List<String> removedFromCalendar = const [],
}) {
  final schedule = ScheduleView(prefs: prefs).build(reminders, saved, now);
  final overdue = schedule.where((i) => i.overdue).toList();
  final stale = overdue.where((i) => now.difference(i.times.due) >= const Duration(days: 30)).toList();
  final today = dateOnly(instantToWall(now, prefs.deviceTimeZone));
  final occasions = RangeView(prefs: prefs)
      .build(reminders, saved, today, addDays(today, 7), now)
      .where((i) =>
          i.reminder.kind == Kind.occasion &&
          (i.state == OccurrenceState.pending || i.state == OccurrenceState.snoozed))
      .toList();
  return Digest(
    overdue: overdue,
    stale: stale,
    missed: missed,
    upcomingOccasions: occasions,
    removedFromCalendar: removedFromCalendar,
  );
}

/// DIG-1: the digest card shows from the digest time until the day ends (or it's dismissed).
bool digestVisible({required UserPrefs prefs, required DateTime now, DateTime? dismissedDay}) {
  final wall = instantToWall(now, prefs.deviceTimeZone);
  final today = dateOnly(wall);
  if (dismissedDay != null && dateOnly(dismissedDay) == today) return false;
  return wall.hour * 60 + wall.minute >= prefs.digestTime.minutes;
}
