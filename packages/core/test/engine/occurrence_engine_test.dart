import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _prefs = UserPrefs(defaultTimeZone: 'America/New_York', deviceTimeZone: 'America/New_York');
final _meta = RecordMeta(id: 'r1', createdAt: DateTime.utc(2026), updatedAt: DateTime.utc(2026), deviceId: 'd');

Reminder _r(Kind kind, Timing timing) => Reminder(
  meta: _meta,
  title: 't',
  kind: kind,
  context: ReminderContext.personal,
  timing: timing,
  alertPlan: const [],
);

DateTime _ny(int y, int m, int d, [int h = 0, int mi = 0]) =>
    wallToInstant(DateTime.utc(y, m, d, h, mi), 'America/New_York');

void main() {
  group('OCC transitions', () {
    test('pending → snoozed → pending when the snooze fires', () {
      final s = transition(OccurrenceState.pending, OccurrenceAction.snooze, Kind.task);
      expect(s, OccurrenceState.snoozed);
      expect(transition(s, OccurrenceAction.alertFired, Kind.task), OccurrenceState.pending);
    });

    test('Done works for tasks and occasions, not meetings or events', () {
      expect(transition(OccurrenceState.pending, OccurrenceAction.done, Kind.task), OccurrenceState.done);
      expect(transition(OccurrenceState.snoozed, OccurrenceAction.done, Kind.occasion), OccurrenceState.done);
      expect(
        () => transition(OccurrenceState.pending, OccurrenceAction.done, Kind.meeting),
        throwsA(isA<InvalidTransition>()),
      );
    });

    test('BIL-1 bills are completable (Paid / Got it) and never pass on their own, like tasks', () {
      expect(transition(OccurrenceState.pending, OccurrenceAction.done, Kind.bill), OccurrenceState.done);
      expect(transition(OccurrenceState.snoozed, OccurrenceAction.done, Kind.bill), OccurrenceState.done);
      expect(
        () => transition(OccurrenceState.pending, OccurrenceAction.timePassed, Kind.bill),
        throwsA(isA<InvalidTransition>()),
      );
    });

    test("OCC-3 I'm prepared is for occasions only, and Done still works afterwards", () {
      final s = transition(OccurrenceState.pending, OccurrenceAction.prepared, Kind.occasion);
      expect(s, OccurrenceState.prepared);
      expect(transition(s, OccurrenceAction.done, Kind.occasion), OccurrenceState.done);
      expect(
        () => transition(OccurrenceState.pending, OccurrenceAction.prepared, Kind.task),
        throwsA(isA<InvalidTransition>()),
      );
    });

    test('OCC-1 tasks never pass; OCC-2 meetings, events and occasions do', () {
      expect(
        () => transition(OccurrenceState.pending, OccurrenceAction.timePassed, Kind.task),
        throwsA(isA<InvalidTransition>()),
      );
      expect(transition(OccurrenceState.pending, OccurrenceAction.timePassed, Kind.meeting), OccurrenceState.passed);
      expect(transition(OccurrenceState.prepared, OccurrenceAction.timePassed, Kind.occasion), OccurrenceState.passed);
    });

    test('terminal states accept nothing', () {
      for (final a in OccurrenceAction.values) {
        expect(() => transition(OccurrenceState.done, a, Kind.task), throwsA(isA<InvalidTransition>()));
      }
    });

    test('OCC-5 undo restores the previous state', () {
      expect(undo(OccurrenceState.done, OccurrenceState.snoozed), OccurrenceState.snoozed);
      expect(() => undo(OccurrenceState.pending, OccurrenceState.pending), throwsStateError);
    });
  });

  group('TIM-10…12 times', () {
    test('date task: anchor at day time, due at end of day (TIM-12)', () {
      final r = _r(Kind.task, Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 15)));
      final t = OccurrenceTimes.of(r, DateTime.utc(2026, 10, 15), _prefs);
      expect(t.anchor, _ny(2026, 10, 15, 9));
      expect(t.due, wallToInstant(DateTime.utc(2026, 10, 15, 23, 59, 59), 'America/New_York'));
      // Not overdue at 9:01 AM on the day, overdue the next morning (OVD-1)
      expect(t.isOverdue(r, OccurrenceState.pending, _ny(2026, 10, 15, 9, 1)), isFalse);
      expect(t.isOverdue(r, OccurrenceState.pending, _ny(2026, 10, 16, 8)), isTrue);
    });

    test('datetime task with an end is due at the end (TIM-12)', () {
      final r = _r(
        Kind.task,
        Timing(
          type: TimingType.datetime,
          start: DateTime.utc(2026, 10, 6, 14),
          end: DateTime.utc(2026, 10, 6, 16),
          timeZone: 'America/New_York',
        ),
      );
      final t = OccurrenceTimes.of(r, DateTime.utc(2026, 10, 6, 14), _prefs);
      expect(t.anchor, _ny(2026, 10, 6, 14));
      expect(t.due, _ny(2026, 10, 6, 16));
    });

    test('meeting gets a default 30-minute end and passes then (TIM-11, OCC-2)', () {
      final r = _r(
        Kind.meeting,
        Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 6, 10), timeZone: 'America/New_York'),
      );
      final t = OccurrenceTimes.of(r, DateTime.utc(2026, 10, 6, 10), _prefs);
      expect(t.end, _ny(2026, 10, 6, 10, 30));
      expect(t.shouldPass(r, OccurrenceState.pending, _ny(2026, 10, 6, 10, 29)), isFalse);
      expect(t.shouldPass(r, OccurrenceState.pending, _ny(2026, 10, 6, 10, 30)), isTrue);
      expect(t.isOverdue(r, OccurrenceState.pending, _ny(2026, 10, 7)), isFalse); // not completable
    });

    test('zoned meeting: Tokyo 9:00 is 20:00 the evening before in New York (TIM-2)', () {
      final r = _r(
        Kind.meeting,
        Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 6, 9), timeZone: 'Asia/Tokyo'),
      );
      final t = OccurrenceTimes.of(r, DateTime.utc(2026, 10, 6, 9), _prefs);
      expect(instantToWall(t.anchor, 'America/New_York'), DateTime.utc(2026, 10, 5, 20));
    });

    test('OCC-1 tasks never pass on their own', () {
      final r = _r(Kind.task, Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 1)));
      final t = OccurrenceTimes.of(r, DateTime.utc(2026, 10, 1), _prefs);
      expect(t.shouldPass(r, OccurrenceState.pending, _ny(2027, 1, 1)), isFalse);
    });

    test('TIM-4 date-only follows the device zone', () {
      const tokyo = UserPrefs(defaultTimeZone: 'America/New_York', deviceTimeZone: 'Asia/Tokyo');
      final r = _r(Kind.occasion, Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 12)));
      final t = OccurrenceTimes.of(r, DateTime.utc(2026, 10, 12), tokyo);
      expect(instantToWall(t.anchor, 'Asia/Tokyo'), DateTime.utc(2026, 10, 12, 9));
    });
  });
}
