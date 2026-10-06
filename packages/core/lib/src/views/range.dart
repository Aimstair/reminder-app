/// Day / Month view data (S-13, S-14): every occurrence that falls on the given days, in the device
/// zone — including completed ones (VW-6) and recurring ones computed on the fly (VW-7).
library;

import '../engine/occurrence_engine.dart';
import '../model/enums.dart';
import '../model/prefs.dart';
import '../model/reminder.dart';
import '../planner/alarm_planner.dart';
import '../recurrence/recurrence.dart';
import '../time/calendar.dart';
import '../time/zones.dart';

class DayItem {
  const DayItem({
    required this.reminder,
    required this.occurrenceKey,
    required this.start,
    required this.end,
    required this.allDay,
    required this.times,
    required this.state,
    required this.overdue,
  });

  final Reminder reminder;
  final DateTime occurrenceKey;

  /// Device-zone wall times. For all-day items: the day at 00:00, end = null.
  final DateTime start;
  final DateTime? end;

  /// VW-3: `date` items go to the all-day strip / month labels.
  final bool allDay;
  final OccurrenceTimes times;

  /// Saved state; `passed` is derived for meetings/events/occasions that are over (OCC-2).
  final OccurrenceState state;
  final bool overdue;

  bool get resolved => state.isResolved;
  String get occurrenceId => AlarmPlanner.occurrenceId(reminder.id, occurrenceKey);
  DateTime get day => dateOnly(start);
}

/// Occurrence keys (series wall times) of [r] whose start falls within [fromWall]…[toWall]
/// (wall times in the reminder's own zone). After-completion series only have their current one.
Iterable<DateTime> occurrenceKeysBetween(Reminder r, DateTime fromWall, DateTime toWall) {
  if (r.rrule == null || r.repeatMode == RecurrenceMode.afterCompletion) {
    final s = r.timing.start;
    return (s.isBefore(fromWall) || s.isAfter(toWall)) ? const [] : [s];
  }
  return RecurrenceRule.parse(r.rrule!).expand(r.timing.start, from: fromWall, to: toWall);
}

class RangeView {
  const RangeView({required this.prefs});
  final UserPrefs prefs;

  /// Items whose (device-zone) day is within [fromDay]…[toDay] inclusive, sorted by day, all-day first,
  /// then start time.
  List<DayItem> build(
    List<Reminder> reminders,
    Map<String, Occurrence> saved,
    DateTime fromDay,
    DateTime toDay,
    DateTime now,
  ) {
    final device = prefs.deviceTimeZone;
    final from = dateOnly(fromDay), to = dateOnly(toDay);
    final items = <DayItem>[];
    final overridden = <String, List<Occurrence>>{};
    for (final o in saved.values) {
      if (o.overrideStart != null) (overridden[o.reminderId] ??= []).add(o);
    }

    for (final r in reminders) {
      if (r.meta.isDeleted) continue;
      // ±1 day of padding covers zones far from the device zone; exact filtering below.
      final keys = <DateTime>{
        ...occurrenceKeysBetween(r, addDays(from, -1), addDays(to, 2)),
        // A "this one" reschedule can move an occurrence into the range from elsewhere (REC-12).
        for (final o in overridden[r.id] ?? const <Occurrence>[]) o.occurrenceKey,
      };
      for (final key in keys) {
        final occ = saved[AlarmPlanner.occurrenceId(r.id, key)];
        var state = occ?.state ?? OccurrenceState.pending;
        final startWall = occ?.overrideStart ?? key;
        final times = OccurrenceTimes.of(r, startWall, prefs, overrideEnd: occ?.overrideEnd);
        final allDay = r.timing.type == TimingType.date;
        final local = allDay ? dateOnly(startWall) : instantToWall(times.anchor, device);
        final day = dateOnly(local);
        if (day.isBefore(from) || day.isAfter(to)) continue;
        if (times.shouldPass(r, state, now)) state = OccurrenceState.passed;
        final hasEnd = !allDay && times.end.isAfter(times.anchor);
        items.add(DayItem(
          reminder: r,
          occurrenceKey: key,
          start: local,
          end: hasEnd ? instantToWall(times.end, device) : null,
          allDay: allDay,
          times: times,
          state: state,
          overdue: times.isOverdue(r, state, now),
        ));
      }
    }
    items.sort((a, b) {
      final d = a.day.compareTo(b.day);
      if (d != 0) return d;
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      return a.start.compareTo(b.start);
    });
    return items;
  }
}
