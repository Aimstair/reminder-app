/// App actions around reminders: save → plan → sync to native; apply notification taps (journal);
/// occurrence actions, reschedule and scoped edits. docs/architecture.md §6 key runtime flows.
library;

import 'package:reminder_core/reminder_core.dart';

import '../data/occurrence_repository.dart';
import '../data/reminder_repository.dart';
import '../native/alarm_gateway.dart';

class ReminderService {
  ReminderService({
    required this.reminders,
    required this.occurrences,
    required this.gateway,
    required this.prefs,
    required this.text,
    Clock? clock,
  }) : _now = clock ?? (() => DateTime.now().toUtc());

  final ReminderRepository reminders;
  final OccurrenceRepository occurrences;
  final AlarmGateway gateway;
  final UserPrefs Function() prefs;
  final AlertTextBuilder Function(UserPrefs prefs) text;
  final Clock _now;

  /// Imported calendar events (CAL-*), in memory; set by the calendar service.
  List<Reminder> Function() calendarReminders = () => const [];

  /// PRM-7: a pending test alarm, included in every sync until it has fired.
  PlannedAlarm? _testAlarm;

  /// FL-2: save a new reminder and schedule its alerts.
  Future<void> create(Reminder r) async {
    await reminders.insert(r);
    await resync();
  }

  Future<void> edit(Reminder r) async {
    await reminders.update(r);
    await resync();
  }

  /// DAT-1/DAT-2: soft delete and cancel alerts (Undo → [restore]).
  Future<void> delete(String id) async {
    await reminders.softDelete(id);
    await resync();
  }

  Future<void> restore(String id) async {
    await reminders.restore(id);
    await resync();
  }

  /// SCH-5: recompute the 14-day alarm set and hand it to the native side.
  Future<List<PlannedAlarm>> resync() async {
    final p = prefs();
    final planner = AlarmPlanner(prefs: p, text: text(p));
    final active = [...await reminders.watchActive().first, ...calendarReminders()];
    final saved = await occurrences.byPlannerId();
    final now = _now();
    final alarms = planner.plan(active, saved, now);
    final test = _testAlarm;
    if (test != null) {
      if (now.isAfter(test.fireAt.add(const Duration(minutes: 5)))) {
        _testAlarm = null;
      } else {
        alarms.add(test);
      }
    }
    await gateway.sync(alarms);
    return alarms;
  }

  /// App start / resume (architecture.md §6): apply notification taps, tidy up, then resync.
  Future<void> onAppStart() async {
    await applyJournal();
    await housekeeping();
    await resync();
  }

  /// DAT-1 purge after 30 days · DAT-3 archive resolved reminders.
  Future<void> housekeeping() async {
    await reminders.purgeDeleted();
    final now = _now();
    for (final r in await reminders.watchActive().first) {
      final occs = await occurrences.forReminder(r.id);
      if (occs.isEmpty) continue;
      if (shouldArchive(r, last: occs.first, now: now)) {
        await reminders.update(r.copyWith(status: ReminderStatus.archived));
      }
    }
  }

  /// Applies notification buttons tapped while Flutter wasn't running (NTF-8).
  Future<void> applyJournal() async {
    final entries = await gateway.readJournal();
    if (entries.isEmpty) return;
    for (final e in entries) {
      await _apply(e);
    }
    await gateway.markApplied(entries.map((e) => e.id).toList());
  }

  Future<void> _apply(JournalAction e) async {
    final parsed = parseAlarmKey(e.alarmKey);
    if (parsed == null) return; // e.g. the PRM-7 test reminder
    await _act(parsed.reminderId, parsed.occurrenceKey, e.type, e.actedAt);
  }

  /// In-app action on one occurrence (e.g. swipe to Done on Schedule), then resync alarms.
  /// Returns the state before the action, for Undo (OCC-5).
  Future<OccurrenceState> act(String reminderId, DateTime occurrenceKey, JournalActionType type) async {
    final before = (await occurrences.find(reminderId, occurrenceKey))?.state ?? OccurrenceState.pending;
    await _act(reminderId, occurrenceKey, type, _now());
    await resync();
    return before;
  }

  /// OCC-5 Undo / "Mark as not done": put an occurrence back in [state].
  Future<void> setState(String reminderId, DateTime occurrenceKey, OccurrenceState state) async {
    await occurrences.save(reminderId: reminderId, occurrenceKey: occurrenceKey, state: state);
    await resync();
  }

  Future<void> _act(String reminderId, DateTime occKey, JournalActionType type, DateTime actedAt) async {
    final r = await reminders.byId(reminderId);
    if (r == null) return;
    final current = (await occurrences.find(reminderId, occKey))?.state ?? OccurrenceState.pending;
    final p = prefs();

    try {
      switch (type) {
        case JournalActionType.done:
          final next = transition(current, OccurrenceAction.done, r.kind);
          await occurrences.save(reminderId: reminderId, occurrenceKey: occKey, state: next, resolvedAt: actedAt);
          if (r.repeatMode == RepeatMode.afterCompletion && r.rrule != null) {
            // REC-6: next due counts from the completion day
            final zone = r.timing.type == TimingType.date ? p.deviceTimeZone : (r.timing.timeZone ?? p.defaultTimeZone);
            await _advanceAfterCompletion(r, instantToWall(actedAt, zone));
          }
        case JournalActionType.skip:
          final next = transition(current, OccurrenceAction.skip, r.kind);
          await occurrences.save(reminderId: reminderId, occurrenceKey: occKey, state: next, resolvedAt: actedAt);
          if (r.repeatMode == RepeatMode.afterCompletion && r.rrule != null) {
            await _advanceAfterCompletion(r, occKey); // REC-7: from the skipped due date
          }
        case JournalActionType.prepared:
          final next = transition(current, OccurrenceAction.prepared, r.kind); // OCC-3
          await occurrences.save(reminderId: reminderId, occurrenceKey: occKey, state: next);
        case JournalActionType.snooze:
          final delay = (r.kind == Kind.meeting || r.kind == Kind.event)
              ? const Duration(minutes: 5)
              : const Duration(hours: 1); // NTF-2 / NTF-4
          await occurrences.save(
            reminderId: reminderId,
            occurrenceKey: occKey,
            state: transition(current, OccurrenceAction.snooze, r.kind),
            snoozedUntil: actedAt.add(delay),
          );
        case JournalActionType.tomorrow:
          await occurrences.save(
            reminderId: reminderId,
            occurrenceKey: occKey,
            state: transition(current, OccurrenceAction.snooze, r.kind),
            snoozedUntil: _tomorrow(actedAt, p), // PRF-5
          );
        case JournalActionType.undo:
          // OCC-5: back to open
          await occurrences.save(reminderId: reminderId, occurrenceKey: occKey, state: OccurrenceState.pending);
      }
    } on InvalidTransition {
      // Stale tap (e.g. already resolved in the app) — ignore.
    }
  }

  /// REC-6 / REC-7: an after-completion reminder moves to its next start.
  Future<void> _advanceAfterCompletion(Reminder r, DateTime fromWall) async {
    final next = nextAfterCompletionStart(r, fromWall: fromWall);
    final duration = r.timing.end?.difference(r.timing.start);
    await reminders.update(
      r.copyWith(
        timing: Timing(
          type: r.timing.type,
          start: r.timing.type == TimingType.date ? dateOnly(next) : next,
          end: duration == null ? null : next.add(duration),
          timeZone: r.timing.timeZone,
          timeZoneSetManually: r.timing.timeZoneSetManually,
        ),
      ),
    );
  }

  /// NTF-7 / S-33: move one occurrence. One-time reminders change their own timing; repeating ones
  /// store a "this one" override (REC-12). [newStart] is a wall time in the reminder's zone.
  Future<void> reschedule(Reminder r, DateTime occurrenceKey, DateTime newStart) async {
    final occ = await occurrences.find(r.id, occurrenceKey);
    final currentStart = occ?.overrideStart ?? occurrenceKey;
    final currentEnd = occ?.overrideEnd ??
        (r.timing.end == null ? null : currentStart.add(r.timing.end!.difference(r.timing.start)));
    final newEnd = currentEnd?.add(newStart.difference(currentStart));
    final type = r.timing.type;
    final start = type == TimingType.date ? dateOnly(newStart) : newStart;

    if (r.rrule == null || r.repeatMode == RepeatMode.afterCompletion) {
      await reminders.update(r.copyWith(
        timing: Timing(
          type: type,
          start: start,
          end: newEnd,
          timeZone: r.timing.timeZone,
          timeZoneSetManually: r.timing.timeZoneSetManually,
        ),
      ));
    } else {
      await occurrences.save(
        reminderId: r.id,
        occurrenceKey: occurrenceKey,
        state: OccurrenceState.pending, // SCH-8: alerts recomputed from the new anchor
        overrideStart: start,
        overrideEnd: newEnd,
      );
    }
    await resync();
  }

  /// REC-11…13: save [edited] for occurrence [occurrenceKey] of [original] with the chosen scope.
  Future<void> editScoped(Reminder original, Reminder edited, DateTime occurrenceKey, EditScope scope) async {
    Timing shifted() {
      final start = occurrenceKey.add(edited.timing.start.difference(original.timing.start));
      return Timing(
        type: edited.timing.type,
        start: start,
        end: edited.timing.end == null ? null : start.add(edited.timing.end!.difference(edited.timing.start)),
        timeZone: edited.timing.timeZone,
        timeZoneSetManually: edited.timing.timeZoneSetManually,
      );
    }

    switch (scope) {
      case EditScope.all:
        await reminders.update(edited);
      case EditScope.thisOne:
        // REC-12: time and alert plan only; the series stays as it is.
        final occ = await occurrences.find(original.id, occurrenceKey);
        final t = shifted();
        await occurrences.save(
          reminderId: original.id,
          occurrenceKey: occurrenceKey,
          state: occ?.state ?? OccurrenceState.pending,
          overrideStart: t.start,
          overrideEnd: t.end,
          overrideAlertPlan: edited.alertPlan,
        );
      case EditScope.thisAndFuture:
        // REC-13: the old series ends before this occurrence; a new one starts here with the edits.
        final ended = endSeriesBefore(original, occurrenceKey);
        if (ended == null) {
          await reminders.update(edited);
        } else {
          await reminders.update(ended);
          await reminders.insert(edited.copyWith(meta: await reminders.newMeta(), timing: shifted()));
        }
    }
    await resync();
  }

  /// REC-15: "This one" → skipped occurrence · "All" → delete the reminder (DAT-1).
  Future<void> deleteScoped(Reminder r, DateTime occurrenceKey, EditScope scope) async {
    if (scope == EditScope.thisOne && r.rrule != null) {
      await occurrences.save(
        reminderId: r.id,
        occurrenceKey: occurrenceKey,
        state: OccurrenceState.skipped,
        resolvedAt: _now(),
      );
      await resync();
    } else {
      await delete(r.id);
    }
  }

  /// PRM-7: a real alarm 15 s ahead through the normal path. Returns when it was scheduled.
  Future<DateTime> sendTestReminder({required String title, required String body}) async {
    final now = _now();
    _testAlarm = PlannedAlarm(
      key: 'test~${now.millisecondsSinceEpoch}:0:0',
      fireAt: now.add(const Duration(seconds: 15)),
      title: title,
      body: body,
      kind: 'test',
      lateCutoff: const Duration(minutes: 10),
    );
    await resync();
    return now;
  }

  /// PRF-5: tomorrow at day time, or the same time tomorrow.
  DateTime _tomorrow(DateTime actedAt, UserPrefs p) {
    final wall = instantToWall(actedAt, p.deviceTimeZone);
    final day = addDays(dateOnly(wall), 1);
    final at = p.tomorrowMode == TomorrowMode.dayTime
        ? day.add(Duration(minutes: p.dayTime.minutes))
        : DateTime.utc(day.year, day.month, day.day, wall.hour, wall.minute);
    return wallToInstant(at, p.deviceTimeZone);
  }
}

/// SCH-4 key `reminderId~yyyyMMddHHmm:stage:seq` → its occurrence. Null for keys without one (test).
({String reminderId, DateTime occurrenceKey})? parseAlarmKey(String alarmKey) {
  final occId = alarmKey.split(':').first;
  final tilde = occId.lastIndexOf('~');
  if (tilde < 0) return null;
  final s = occId.substring(tilde + 1);
  if (s.length != 12 || int.tryParse(s) == null) return null;
  final reminderId = occId.substring(0, tilde);
  if (reminderId == 'test') return null;
  return (
    reminderId: reminderId,
    occurrenceKey: DateTime.utc(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
      int.parse(s.substring(8, 10)),
      int.parse(s.substring(10, 12)),
    ),
  );
}
