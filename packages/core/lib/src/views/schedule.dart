/// Schedule view data (S-12, VW-12, OVD-2): upcoming occurrences grouped Overdue · Today · Tomorrow ·
/// This week · Later. Pure logic — the UI only renders it.
library;

import '../engine/occurrence_engine.dart';
import '../model/enums.dart';
import '../model/place.dart';
import '../model/prefs.dart';
import '../model/reminder.dart';
import '../planner/alarm_planner.dart';
import '../recurrence/recurrence.dart';
import '../time/calendar.dart';
import '../time/zones.dart';

enum ScheduleGroup { overdue, today, tomorrow, thisWeek, later }

class ScheduleItem {
  const ScheduleItem({
    required this.reminder,
    required this.occurrenceKey,
    required this.start,
    required this.times,
    required this.state,
    required this.group,
    required this.overdue,
    this.firedAt,
    this.firedBy,
  });

  final Reminder reminder;

  /// Original start (identifies the occurrence).
  final DateTime occurrenceKey;

  /// Displayed start as wall time in the device zone (after overrides; date-only = the day).
  final DateTime start;
  final OccurrenceTimes times;
  final OccurrenceState state;
  final ScheduleGroup group;
  final bool overdue;

  /// VW-17: when and why a place reminder rang (instant); null for everything else.
  final DateTime? firedAt;
  final PlaceEvent? firedBy;

  String get occurrenceId => AlarmPlanner.occurrenceId(reminder.id, occurrenceKey);
}

class ScheduleView {
  const ScheduleView({required this.prefs, this.horizon = const Duration(days: 60)});

  final UserPrefs prefs;

  /// How far ahead "Later" reaches (VW-12 scrolls indefinitely; the UI pages further on demand).
  final Duration horizon;

  /// Builds the grouped list. Resolved occurrences are hidden (VW-6: Schedule hides completed).
  List<ScheduleItem> build(List<Reminder> reminders, Map<String, Occurrence> saved, DateTime now) {
    final deviceZone = prefs.deviceTimeZone;
    final today = dateOnly(instantToWall(now, deviceZone));
    final weekEnd = addDays(today, 7 - today.weekday % 7); // exclusive: the coming Sunday starts "Later"
    final items = <ScheduleItem>[];
    final fired = <String, List<Occurrence>>{};
    for (final o in saved.values) {
      if (o.firedAt != null && !o.state.isResolved) (fired[o.reminderId] ??= []).add(o);
    }

    for (final r in reminders) {
      if (r.meta.isDeleted || r.status != ReminderStatus.active) continue;
      if (r.kind == Kind.place) {
        // VW-17 / LOC-10: only place reminders that rang and aren't done; due at the end of that day (LOC-8).
        for (final o in fired[r.id] ?? const <Occurrence>[]) {
          final day = dateOnly(instantToWall(o.firedAt!, deviceZone));
          final times = OccurrenceTimes.of(r, day, prefs);
          final overdue = times.isOverdue(r, o.state, now);
          items.add(ScheduleItem(
            reminder: r,
            occurrenceKey: o.occurrenceKey,
            start: instantToWall(o.firedAt!, deviceZone),
            times: times,
            state: o.state,
            group: overdue ? ScheduleGroup.overdue : ScheduleGroup.today,
            overdue: overdue,
            firedAt: o.firedAt,
            firedBy: o.firedBy,
          ));
        }
        continue;
      }
      for (final key in _keys(r, now)) {
        final occ = saved[AlarmPlanner.occurrenceId(r.id, key)];
        final state = occ?.state ?? OccurrenceState.pending;
        if (state.isResolved) continue;
        final startWall = occ?.overrideStart ?? key;
        final times = OccurrenceTimes.of(r, startWall, prefs, overrideEnd: occ?.overrideEnd);
        if (times.shouldPass(r, state, now)) continue; // OCC-2: meetings/events over → gone
        final overdue = times.isOverdue(r, state, now);
        final local = r.timing.type == TimingType.date ? dateOnly(startWall) : instantToWall(times.anchor, deviceZone);
        final day = dateOnly(local);
        final group = overdue
            ? ScheduleGroup.overdue
            : day == today || day.isBefore(today)
                ? ScheduleGroup.today
                : day == addDays(today, 1)
                    ? ScheduleGroup.tomorrow
                    : day.isBefore(weekEnd)
                        ? ScheduleGroup.thisWeek
                        : ScheduleGroup.later;
        items.add(ScheduleItem(
          reminder: r,
          occurrenceKey: key,
          start: local,
          times: times,
          state: state,
          group: group,
          overdue: overdue,
        ));
      }
    }

    items.sort((a, b) {
      final g = a.group.index.compareTo(b.group.index);
      if (g != 0) return g;
      // OVD-2: overdue oldest first; others chronological; date-only items sort at day time
      return a.times.anchor.compareTo(b.times.anchor);
    });
    return items;
  }

  /// Occurrence keys to consider: one-time and after-completion → the single start;
  /// fixed repeats → expansion from a few days back (overdue tasks) to the horizon.
  Iterable<DateTime> _keys(Reminder r, DateTime now) {
    final zone = r.timing.type == TimingType.date ? prefs.deviceTimeZone : (r.timing.timeZone ?? prefs.defaultTimeZone);
    final nowWall = instantToWall(now, zone);
    if (r.rrule == null || r.repeatMode == RecurrenceMode.afterCompletion) return [r.timing.start];
    // Overdue repeating tasks stay visible until resolved (OVD-2); look back 31 days.
    final from = r.completable ? addDays(nowWall, -31) : addDays(dateOnly(nowWall), -1);
    return RecurrenceRule.parse(r.rrule!).expand(r.timing.start, from: from, to: nowWall.add(horizon));
  }
}
