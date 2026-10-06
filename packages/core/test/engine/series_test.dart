import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 10, 1);
RecordMeta _m(String id) => RecordMeta(id: id, createdAt: _t0, updatedAt: _t0, deviceId: 'd');

Reminder _weekly({String rrule = 'FREQ=WEEKLY;BYDAY=MO'}) => Reminder(
  meta: _m('r'),
  title: '1:1',
  kind: Kind.meeting,
  context: ReminderContext.work,
  timing: Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 5, 10), timeZone: 'UTC'),
  alertPlan: const [],
  rrule: rrule,
);

void main() {
  test('REC-13 "this and future" ends the old series the day before', () {
    final ended = endSeriesBefore(_weekly(), DateTime.utc(2026, 10, 19, 10))!;
    expect(ended.rrule, 'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261018');
    final keys = RecurrenceRule.parse(ended.rrule!).expand(ended.timing.start, to: DateTime.utc(2027));
    expect(keys.map(formatWallDate), ['2026-10-05', '2026-10-12']);
  });

  test('REC-13 from the first occurrence nothing remains of the old series', () {
    expect(endSeriesBefore(_weekly(), DateTime.utc(2026, 10, 5, 10)), isNull);
  });

  test('setUntil replaces COUNT', () {
    expect(setUntil('FREQ=DAILY;COUNT=5', DateTime.utc(2026, 1, 2)), 'FREQ=DAILY;UNTIL=20260102');
  });

  test('REC-9 a series with UNTIL has no occurrence after its last one', () {
    final r = _weekly(rrule: 'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261012');
    expect(hasLaterOccurrence(r, DateTime.utc(2026, 10, 5, 10)), isTrue);
    expect(hasLaterOccurrence(r, DateTime.utc(2026, 10, 12, 10)), isFalse);
  });

  test('DAT-3 one-time reminders archive 7 days after done', () {
    final r = Reminder(
      meta: _m('t'),
      title: 'x',
      kind: Kind.task,
      context: ReminderContext.personal,
      timing: Timing(type: TimingType.date, start: _t0),
      alertPlan: const [],
    );
    final done = Occurrence(
      meta: _m('o'),
      reminderId: 't',
      occurrenceKey: _t0,
      state: OccurrenceState.done,
      resolvedAt: DateTime.utc(2026, 10, 2),
    );
    expect(shouldArchive(r, last: done, now: DateTime.utc(2026, 10, 8)), isFalse);
    expect(shouldArchive(r, last: done, now: DateTime.utc(2026, 10, 9)), isTrue);
  });

  test('REC-6/REC-7 next start after completion keeps the time of day', () {
    final r = Reminder(
      meta: _m('f'),
      title: 'AC filter',
      kind: Kind.task,
      context: ReminderContext.personal,
      timing: Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 1, 9), timeZone: 'UTC'),
      alertPlan: const [],
      rrule: 'FREQ=MONTHLY;INTERVAL=3',
      repeatMode: RepeatMode.afterCompletion,
    );
    expect(formatWallDateTime(nextAfterCompletionStart(r, fromWall: DateTime.utc(2026, 10, 10, 15))),
        '2027-01-10T09:00');
  });
}
