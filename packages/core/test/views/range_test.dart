import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);
final _now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);
final _meta0 = RecordMeta(id: 'x', createdAt: _now, updatedAt: _now, deviceId: 'd');

Reminder _r(String title, Kind kind, Timing timing, {String? rrule}) => Reminder(
  meta: RecordMeta(id: title, createdAt: _now, updatedAt: _now, deviceId: 'd'),
  title: title,
  kind: kind,
  context: ReminderContext.personal,
  timing: timing,
  alertPlan: const [],
  rrule: rrule,
);

Timing _dt(int m, int d, int h, {int? endH}) => Timing(
  type: TimingType.datetime,
  start: DateTime.utc(2026, m, d, h),
  end: endH == null ? null : DateTime.utc(2026, m, d, endH),
  timeZone: _ny,
);

void main() {
  final view = RangeView(prefs: _prefs);
  final oct5 = DateTime.utc(2026, 10, 5);

  test('VW-3 date items are all-day and sort first; timed items keep start/end', () {
    final items = view.build([
      _r('Meeting', Kind.meeting, _dt(10, 5, 10, endH: 11)),
      _r('Bill', Kind.task, Timing(type: TimingType.date, start: oct5)),
    ], {}, oct5, oct5, _now);
    expect(items.map((i) => i.reminder.title), ['Bill', 'Meeting']);
    expect(items.first.allDay, isTrue);
    expect(formatWallDateTime(items.last.end!), '2026-10-05T11:00');
  });

  test('VW-6 completed occurrences stay visible with their state', () {
    final r = _r('Task', Kind.task, _dt(10, 5, 9));
    final occ = Occurrence(meta: _meta0, reminderId: r.id, occurrenceKey: r.timing.start, state: OccurrenceState.done);
    final item = view.build([r], {AlarmPlanner.occurrenceId(r.id, r.timing.start): occ}, oct5, oct5, _now).single;
    expect(item.resolved, isTrue);
    expect(item.overdue, isFalse);
  });

  test('VW-5 open tasks in the past are overdue on their own day; meetings over are passed', () {
    final items = view.build([
      _r('Old task', Kind.task, _dt(10, 2, 9)),
      _r('Past meeting', Kind.meeting, _dt(10, 2, 9)),
    ], {}, DateTime.utc(2026, 10, 2), DateTime.utc(2026, 10, 2), _now);
    expect(items.firstWhere((i) => i.reminder.title == 'Old task').overdue, isTrue);
    expect(items.firstWhere((i) => i.reminder.title == 'Past meeting').state, OccurrenceState.passed);
  });

  test('VW-7 recurring items appear on any month', () {
    final r = _r('Rent', Kind.task, Timing(type: TimingType.date, start: DateTime.utc(2026, 1, 31)),
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=31');
    final items = view.build([r], {}, DateTime.utc(2027, 2, 1), DateTime.utc(2027, 2, 28), _now);
    expect(items.map((i) => formatWallDate(i.start)), ['2027-02-28']); // REC-3
  });

  test('REC-12 an occurrence moved into the range by "this one" shows on its new day', () {
    final r = _r('Standup', Kind.meeting, _dt(10, 6, 9), rrule: 'FREQ=DAILY');
    final occ = Occurrence(
      meta: _meta0,
      reminderId: r.id,
      occurrenceKey: DateTime.utc(2026, 10, 20, 9),
      overrideStart: DateTime.utc(2026, 10, 10, 15),
    );
    final items = view.build([r], {AlarmPlanner.occurrenceId(r.id, occ.occurrenceKey): occ},
        DateTime.utc(2026, 10, 10), DateTime.utc(2026, 10, 10), _now);
    expect(items.map((i) => formatWallDateTime(i.start)), ['2026-10-10T09:00', '2026-10-10T15:00']);
  });
}
