/// App actions around reminders: save → plan → sync to native; apply notification taps (journal).
/// docs/architecture.md §6 key runtime flows.
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
    final active = await reminders.watchActive().first;
    final saved = await occurrences.byPlannerId();
    final alarms = planner.plan(active, saved, _now());
    await gateway.sync(alarms);
    return alarms;
  }

  /// App start / resume (architecture.md §6): apply notification taps, then resync.
  Future<void> onAppStart() async {
    await applyJournal();
    await resync();
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
    // key = reminderId~yyyyMMddHHmm:stage:seq  (AlarmPlanner.occurrenceId, SCH-4)
    final occId = e.alarmKey.split(':').first;
    final tilde = occId.lastIndexOf('~');
    if (tilde < 0) return; // e.g. the PRM-7 test reminder
    final reminderId = occId.substring(0, tilde);
    final occKey = _parseKey(occId.substring(tilde + 1));
    final r = await reminders.byId(reminderId);
    if (r == null || occKey == null) return;
    final current = (await occurrences.find(reminderId, occKey))?.state ?? OccurrenceState.pending;
    final p = prefs();

    try {
      switch (e.type) {
        case JournalActionType.done:
          final next = transition(current, OccurrenceAction.done, r.kind);
          await occurrences.save(reminderId: reminderId, occurrenceKey: occKey, state: next, resolvedAt: e.actedAt);
          if (r.repeatMode == RepeatMode.afterCompletion && r.rrule != null) {
            await _advanceAfterCompletion(r, e.actedAt, p); // REC-6
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
            snoozedUntil: e.actedAt.add(delay),
          );
        case JournalActionType.tomorrow:
          await occurrences.save(
            reminderId: reminderId,
            occurrenceKey: occKey,
            state: transition(current, OccurrenceAction.snooze, r.kind),
            snoozedUntil: _tomorrow(e.actedAt, p), // PRF-5
          );
        case JournalActionType.undo:
          // OCC-5: back to open
          await occurrences.save(reminderId: reminderId, occurrenceKey: occKey, state: OccurrenceState.pending);
      }
    } on InvalidTransition {
      // Stale tap (e.g. already resolved in the app) — ignore.
    }
  }

  /// REC-6: an after-completion reminder's next due date counts from the completion day.
  Future<void> _advanceAfterCompletion(Reminder r, DateTime completedAt, UserPrefs p) async {
    final zone = r.timing.type == TimingType.date ? p.deviceTimeZone : (r.timing.timeZone ?? p.defaultTimeZone);
    final next = RecurrenceRule.parse(r.rrule!)
        .nextAfterCompletion(from: instantToWall(completedAt, zone), originalStart: r.timing.start);
    final duration = r.timing.end?.difference(r.timing.start);
    await reminders.update(
      Reminder(
        meta: r.meta,
        title: r.title,
        notes: r.notes,
        rawInput: r.rawInput,
        kind: r.kind,
        context: r.context,
        timing: Timing(
          type: r.timing.type,
          start: r.timing.type == TimingType.date ? dateOnly(next) : next,
          end: duration == null ? null : next.add(duration),
          timeZone: r.timing.timeZone,
          timeZoneSetManually: r.timing.timeZoneSetManually,
        ),
        alertPlan: r.alertPlan,
        rrule: r.rrule,
        repeatMode: r.repeatMode,
        nagInterval: r.nagInterval,
        source: r.source,
        templateId: r.templateId,
        status: r.status,
      ),
    );
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

  static DateTime? _parseKey(String s) {
    if (s.length != 12) return null;
    final n = int.tryParse(s);
    if (n == null) return null;
    return DateTime.utc(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
      int.parse(s.substring(8, 10)),
      int.parse(s.substring(10, 12)),
    );
  }
}
