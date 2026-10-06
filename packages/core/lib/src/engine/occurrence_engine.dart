/// Occurrence lifecycle (OCC-*) and time rules (TIM-10…12, OVD-1).
library;

import '../model/enums.dart';
import '../model/prefs.dart';
import '../model/reminder.dart';
import '../time/calendar.dart';
import '../time/zones.dart';

/// Things that move an occurrence between states (behavior-spec §3 transitions table).
enum OccurrenceAction { snooze, alertFired, done, skip, prepared, timePassed }

class InvalidTransition implements Exception {
  InvalidTransition(this.from, this.action, this.kind);
  final OccurrenceState from;
  final OccurrenceAction action;
  final Kind kind;
  @override
  String toString() => 'InvalidTransition: $action not allowed from $from for $kind';
}

/// Applies one action. Throws [InvalidTransition] for anything the spec doesn't allow.
OccurrenceState transition(OccurrenceState from, OccurrenceAction action, Kind kind) {
  const open = {OccurrenceState.pending, OccurrenceState.snoozed};
  final completable = kind == Kind.task || kind == Kind.occasion;
  final next = switch (action) {
    OccurrenceAction.snooze when open.contains(from) => OccurrenceState.snoozed,
    OccurrenceAction.alertFired when from == OccurrenceState.snoozed => OccurrenceState.pending,
    OccurrenceAction.alertFired when from == OccurrenceState.pending || from == OccurrenceState.prepared => from,
    // Done: Task and Occasion only. An occasion can be done after "I'm prepared" (day-of Done).
    OccurrenceAction.done when completable && (open.contains(from) || from == OccurrenceState.prepared) =>
      OccurrenceState.done,
    OccurrenceAction.skip when open.contains(from) || from == OccurrenceState.prepared => OccurrenceState.skipped,
    OccurrenceAction.prepared when kind == Kind.occasion && open.contains(from) => OccurrenceState.prepared, // OCC-3
    // OCC-1: tasks never pass. OCC-2: meetings/events pass at end; occasions at the end of their day.
    OccurrenceAction.timePassed when (kind == Kind.meeting || kind == Kind.event) && open.contains(from) =>
      OccurrenceState.passed,
    OccurrenceAction.timePassed
        when kind == Kind.occasion && (open.contains(from) || from == OccurrenceState.prepared) =>
      OccurrenceState.passed,
    _ => null,
  };
  if (next == null) throw InvalidTransition(from, action, kind);
  return next;
}

/// OCC-5: Undo restores the state before done/skip.
OccurrenceState undo(OccurrenceState current, OccurrenceState previous) {
  if (current != OccurrenceState.done && current != OccurrenceState.skipped && current != OccurrenceState.prepared) {
    throw StateError('Nothing to undo from $current');
  }
  return previous;
}

/// Instants for one occurrence of a reminder, derived from the timing rules.
class OccurrenceTimes {
  OccurrenceTimes._(this.anchor, this.due, this.end, this.start);

  /// TIM-10: alerts are measured from here.
  final DateTime anchor;

  /// TIM-12: overdue is measured from here.
  final DateTime due;

  /// When the occurrence is over (OCC-2 passing). Tasks: same as [due].
  final DateTime end;

  /// The occurrence's start as wall time (after "this one" overrides).
  final DateTime start;

  /// [start] is this occurrence's wall-time start (series start, expansion result, or override).
  factory OccurrenceTimes.of(Reminder r, DateTime start, UserPrefs prefs, {DateTime? overrideEnd}) {
    final t = r.timing;
    if (t.type == TimingType.date) {
      // TIM-4: date-only follows the device zone. Anchor = day time; due/end = end of that day.
      final zone = prefs.deviceTimeZone;
      final day = dateOnly(start);
      final anchor = wallToInstant(day.add(Duration(minutes: prefs.dayTime.minutes)), zone);
      final endOfDay = wallToInstant(DateTime.utc(day.year, day.month, day.day, 23, 59, 59), zone);
      return OccurrenceTimes._(anchor, endOfDay, endOfDay, day);
    }

    final zone = t.timeZone ?? prefs.defaultTimeZone;
    final startInstant = wallToInstant(start, zone);
    // Keep the series duration for each occurrence; overrides win.
    final duration = t.end?.difference(t.start);
    final endWall = overrideEnd ?? (duration != null ? start.add(duration) : null);
    final endInstant = endWall != null
        ? wallToInstant(endWall, zone)
        : switch (r.kind) {
            // TIM-11 defaults
            Kind.meeting => startInstant.add(const Duration(minutes: 30)),
            Kind.event => startInstant.add(const Duration(hours: 1)),
            _ => startInstant,
          };
    final due = r.kind == Kind.task ? (endWall != null ? endInstant : startInstant) : startInstant;
    return OccurrenceTimes._(startInstant, due, endInstant, start);
  }

  /// OVD-1: completable, still open, and past its due time.
  bool isOverdue(Reminder r, OccurrenceState state, DateTime now) =>
      r.completable && (state == OccurrenceState.pending || state == OccurrenceState.snoozed) && now.isAfter(due);

  /// OCC-2: should this occurrence become `passed` now?
  bool shouldPass(Reminder r, OccurrenceState state, DateTime now) {
    if (state.isResolved) return false;
    if (r.kind == Kind.task) return false; // OCC-1
    if (r.kind == Kind.occasion) return !now.isBefore(end);
    return state != OccurrenceState.prepared && !now.isBefore(end);
  }
}
