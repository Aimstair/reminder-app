import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);

/// Now = Mon Oct 5 2026, 14:00 New York.
final _now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

Reminder _r(String title, Kind kind, Timing timing, {String? rrule}) => Reminder(
      meta: RecordMeta(id: title, createdAt: _now, updatedAt: _now, deviceId: 'd'),
      title: title,
      kind: kind,
      context: ReminderContext.personal,
      timing: timing,
      alertPlan: const [],
      rrule: rrule,
    );

Timing _date(int m, int d) => Timing(type: TimingType.date, start: DateTime.utc(2026, m, d));
Timing _dt(int m, int d, int h) => Timing(type: TimingType.datetime, start: DateTime.utc(2026, m, d, h), timeZone: _ny);

Map<String, ScheduleGroup> _groups(List<ScheduleItem> items) => {for (final i in items) i.reminder.title: i.group};

void main() {
  final view = ScheduleView(prefs: _prefs);

  test('VW-12 groups: Overdue · Today · Tomorrow · This week · Later', () {
    final items = view.build([
      _r('Pay bill', Kind.task, _date(10, 4)), // yesterday, date task → overdue
      _r('Dry cleaning', Kind.task, _date(10, 5)), // today
      _r('Call mom', Kind.task, _dt(10, 5, 18)),
      _r('Standup', Kind.meeting, _dt(10, 6, 9)),
      _r('Report', Kind.task, _date(10, 9)), // Fri
      _r("Mom's birthday", Kind.occasion, _date(10, 12)), // next Mon
    ], {}, _now);
    expect(_groups(items), {
      'Pay bill': ScheduleGroup.overdue,
      'Dry cleaning': ScheduleGroup.today,
      'Call mom': ScheduleGroup.today,
      'Standup': ScheduleGroup.tomorrow,
      'Report': ScheduleGroup.thisWeek,
      "Mom's birthday": ScheduleGroup.later,
    });
    expect(items.first.overdue, isTrue);
  });

  test('OVD-2 overdue items come first, oldest first', () {
    final items = view.build([
      _r('newer', Kind.task, _dt(10, 5, 9)),
      _r('older', Kind.task, _dt(10, 2, 9)),
    ], {}, _now);
    expect(items.map((i) => i.reminder.title), ['older', 'newer']);
    expect(items.every((i) => i.group == ScheduleGroup.overdue), isTrue);
  });

  test('OCC-2 a meeting that ended is no longer listed; tasks stay (OCC-1)', () {
    final items = view.build([
      _r('Morning sync', Kind.meeting, _dt(10, 5, 9)),
      _r('Old task', Kind.task, _dt(10, 5, 9)),
    ], {}, _now);
    expect(items.map((i) => i.reminder.title), ['Old task']);
  });

  test('VW-6 resolved occurrences are hidden from Schedule', () {
    final r = _r('Done thing', Kind.task, _date(10, 6));
    final occ = Occurrence(
      meta: RecordMeta(id: 'o', createdAt: _now, updatedAt: _now, deviceId: 'd'),
      reminderId: r.id,
      occurrenceKey: DateTime.utc(2026, 10, 6),
      state: OccurrenceState.done,
    );
    expect(view.build([r], {AlarmPlanner.occurrenceId(r.id, DateTime.utc(2026, 10, 6)): occ}, _now), isEmpty);
  });

  test('repeating reminders list each upcoming occurrence', () {
    final items = view.build([_r('Standup', Kind.meeting, _dt(10, 6, 9), rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR')], {},
        _now);
    expect(items.take(3).map((i) => formatWallDate(i.start)), ['2026-10-06', '2026-10-07', '2026-10-08']);
  });

  test('a zoned meeting shows at its local time on the right day (TIM-6)', () {
    final tokyo = Reminder(
      meta: RecordMeta(id: 't', createdAt: _now, updatedAt: _now, deviceId: 'd'),
      title: 'Tokyo call',
      kind: Kind.meeting,
      context: ReminderContext.work,
      timing: Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 6, 9), timeZone: 'Asia/Tokyo'),
      alertPlan: const [],
    );
    final item = view.build([tokyo], {}, _now).single;
    expect(formatWallDateTime(item.start), '2026-10-05T20:00'); // Mon 8 PM New York
    expect(item.group, ScheduleGroup.today);
  });
}
