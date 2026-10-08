import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);

/// Now = Mon Oct 5 2026, 14:00 New York (same as the parser tests).
final _now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

DateTime _at(int y, int m, int d, [int h = 0, int mi = 0]) => wallToInstant(DateTime.utc(y, m, d, h, mi), _ny);
String _local(DateTime instant) => formatWallDateTime(instantToWall(instant, _ny));

AlarmPlanner _planner([UserPrefs prefs = _prefs]) =>
    AlarmPlanner(prefs: prefs, text: (c) => (title: c.reminder.title, body: c.alertKind.name));

Reminder _r(
  String id,
  Kind kind,
  Timing timing, {
  List<AlertStage>? plan,
  String? rrule,
  RecurrenceMode repeatMode = RecurrenceMode.fixed,
  Duration? nag,
}) => Reminder(
  meta: RecordMeta(id: id, createdAt: _now, updatedAt: _now, deviceId: 'd'),
  title: id,
  kind: kind,
  context: ReminderContext.personal,
  timing: timing,
  alertPlan: plan ?? defaultAlertPlan(kind, timing.type),
  rrule: rrule,
  repeatMode: repeatMode,
  nagInterval: nag,
);

Timing _date(int y, int m, int d) => Timing(type: TimingType.date, start: DateTime.utc(y, m, d));
Timing _dt(int y, int m, int d, int h, [int mi = 0, String zone = _ny]) =>
    Timing(type: TimingType.datetime, start: DateTime.utc(y, m, d, h, mi), timeZone: zone);

Occurrence _occ(
  String reminderId,
  DateTime start,
  OccurrenceState state, {
  DateTime? snoozedUntil,
  Set<String> sent = const {},
}) => Occurrence(
  meta: RecordMeta(id: 'o', createdAt: _now, updatedAt: _now, deviceId: 'd'),
  reminderId: reminderId,
  occurrenceKey: start,
  state: state,
  snoozedUntil: snoozedUntil,
  alertsSent: sent,
);

void main() {
  test('occasion: −7d already past, −1d and day-of planned at day time (ALR-2, ALR-4)', () {
    final mom = _r('mom', Kind.occasion, _date(2026, 10, 12), rrule: 'FREQ=YEARLY');
    final alarms = _planner().plan([mom], {}, _now);
    expect(alarms.map((a) => _local(a.fireAt)), ['2026-10-11T09:00', '2026-10-12T09:00']);
    expect(alarms.map((a) => a.kind), ['occasion_prep', 'occasion_day']);
    expect(alarms.first.key, 'mom~202610120000:1:0');
  });

  test("OCC-3 I'm prepared drops prep alerts but keeps the day-of alert", () {
    final mom = _r('mom', Kind.occasion, _date(2026, 10, 12), rrule: 'FREQ=YEARLY');
    final id = AlarmPlanner.occurrenceId('mom', DateTime.utc(2026, 10, 12));
    final alarms = _planner().plan(
      [mom],
      {id: _occ('mom', DateTime.utc(2026, 10, 12), OccurrenceState.prepared)},
      _now,
    );
    expect(alarms.map((a) => _local(a.fireAt)), ['2026-10-12T09:00']);
  });

  test('OCC-4 resolved occurrences get no alarms; next year is outside the window (SCH-2)', () {
    final mom = _r('mom', Kind.occasion, _date(2026, 10, 12), rrule: 'FREQ=YEARLY');
    final id = AlarmPlanner.occurrenceId('mom', DateTime.utc(2026, 10, 12));
    expect(_planner().plan([mom], {id: _occ('mom', DateTime.utc(2026, 10, 12), OccurrenceState.done)}, _now), isEmpty);
  });

  test('SCH-2 only the next 14 days are planned', () {
    final standup = _r('standup', Kind.meeting, _dt(2026, 10, 6, 9, 30), rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR');
    final alarms = _planner().plan([standup], {}, _now);
    expect(alarms, hasLength(10)); // Oct 6 … Oct 19 weekdays
    expect(_local(alarms.first.fireAt), '2026-10-06T09:20'); // −10 min
    expect(alarms.every((a) => a.fireAt.isBefore(_now.add(const Duration(days: 14)))), isTrue);
  });

  test('ALR-3 month offsets: passport −6 months enters the window only when close', () {
    final passport = _r(
      'passport',
      Kind.task,
      _date(2027, 6, 1),
      plan: const [AlertStage(AlertOffset(-6, OffsetUnit.months))],
    );
    expect(_planner().plan([passport], {}, _now), isEmpty);
    final nov25 = _at(2026, 11, 25, 12);
    final alarms = _planner().plan([passport], {}, nov25);
    expect(alarms.map((a) => _local(a.fireAt)), ['2026-12-01T09:00']);
  });

  test('ALR-6 all stages past but occurrence ahead → one alert at the anchor', () {
    final soon = _r(
      'soon',
      Kind.task,
      _dt(2026, 10, 5, 14, 30),
      plan: const [AlertStage(AlertOffset(-1, OffsetUnit.hours))],
    );
    final alarms = _planner().plan([soon], {}, _now);
    expect(alarms.map((a) => (a.key, _local(a.fireAt))), [('soon~202610051430:anchor:0', '2026-10-05T14:30')]);
  });

  test('ALR-6 no anchor fallback when the stages passed after saving (they fired)', () {
    // Event at 15:00 with a −1h alert, saved at 13:00; the 14:00 alert has fired, now 14:10.
    final saved = _now.subtract(const Duration(hours: 1));
    final event = Reminder(
      meta: RecordMeta(id: 'ev', createdAt: saved, updatedAt: saved, deviceId: 'd'),
      title: 'ev',
      kind: Kind.event,
      context: ReminderContext.personal,
      timing: _dt(2026, 10, 5, 15, 0),
      alertPlan: const [AlertStage(AlertOffset(-1, OffsetUnit.hours))],
    );
    final later = _at(2026, 10, 5, 14, 10);
    expect(_planner().plan([event], {}, later), isEmpty);
  });

  test('SCH-6 alerts already shown are not planned again', () {
    final mom = _r('mom', Kind.occasion, _date(2026, 10, 12), rrule: 'FREQ=YEARLY');
    final start = DateTime.utc(2026, 10, 12);
    final id = AlarmPlanner.occurrenceId('mom', start);
    final alarms = _planner().plan(
      [mom],
      {
        id: _occ('mom', start, OccurrenceState.pending, sent: {'$id:1:0'}),
      },
      _now,
    );
    expect(alarms.map((a) => a.key), ['$id:2:0']);
  });

  test('NTF-4 snoozed alert re-fires at snoozedUntil', () {
    final task = _r('call', Kind.task, _dt(2026, 10, 5, 13));
    final start = DateTime.utc(2026, 10, 5, 13);
    final until = _at(2026, 10, 5, 15);
    final alarms = _planner().plan(
      [task],
      {AlarmPlanner.occurrenceId('call', start): _occ('call', start, OccurrenceState.snoozed, snoozedUntil: until)},
      _now,
    );
    expect(alarms.map((a) => _local(a.fireAt)), ['2026-10-05T15:00']);
    expect(alarms.single.key, contains(':snz'));
  });

  group('nag until done', () {
    final rent = _r('rent', Kind.task, _date(2026, 10, 6), nag: const Duration(hours: 2));

    test('ALR-10/11 every 2 h after the last stage, only between 8 AM and 10 PM', () {
      final alarms = _planner().plan([rent], {}, _now);
      final oct6 = alarms
          .where((a) => _local(a.fireAt).startsWith('2026-10-06'))
          .map((a) => _local(a.fireAt).substring(11));
      expect(oct6, ['09:00', '11:00', '13:00', '15:00', '17:00', '19:00', '21:00']);
      final oct7 = alarms
          .where((a) => _local(a.fireAt).startsWith('2026-10-07'))
          .map((a) => _local(a.fireAt).substring(11));
      expect(oct7.first, '08:00'); // 23:00 would be outside nag hours → next start
    });

    test('ALR-13 nagging stops after 3 days', () {
      final alarms = _planner().plan([rent], {}, _now);
      final last = alarms.map((a) => a.fireAt).reduce((a, b) => a.isAfter(b) ? a : b);
      expect(last.isAfter(_at(2026, 10, 9, 9)), isFalse);
    });

    test('nag hours follow the setting (PRF-4)', () {
      const late = UserPrefs(
        defaultTimeZone: _ny,
        deviceTimeZone: _ny,
        nagStart: ClockTime(10, 0),
        nagEnd: ClockTime(18, 0),
      );
      final alarms = _planner(late).plan([rent], {}, _now);
      final times = alarms.map((a) => _local(a.fireAt).substring(11)).toSet();
      expect(times.every((t) => t.compareTo('10:00') >= 0 && t.compareTo('18:00') <= 0 || t == '09:00'), isTrue);
    });
  });

  test('REC-6 after-completion reminders plan from their current due date', () {
    final filter = _r(
      'filter',
      Kind.task,
      _date(2026, 10, 8),
      rrule: 'FREQ=MONTHLY;INTERVAL=3',
      repeatMode: RecurrenceMode.afterCompletion,
    );
    final alarms = _planner().plan([filter], {}, _now);
    expect(alarms.map((a) => _local(a.fireAt)), ['2026-10-08T09:00']);
  });

  test('daily 9 AM stays 9 AM local across the DST change (TIM-2)', () {
    final meds = _r('meds', Kind.task, _dt(2026, 10, 25, 9), rrule: 'FREQ=DAILY');
    final alarms = _planner().plan([meds], {}, _at(2026, 10, 25, 8));
    expect(alarms.map((a) => _local(a.fireAt).substring(11)).toSet(), {'09:00'});
    expect(alarms.map((a) => _local(a.fireAt).substring(0, 10)), contains('2026-11-02'));
  });

  test('SCH-3 at most 400 alarms, earliest first', () {
    final many = [for (var i = 0; i < 40; i++) _r('r$i', Kind.task, _dt(2026, 10, 6, 9), rrule: 'FREQ=DAILY')];
    final alarms = _planner().plan(many, {}, _now);
    expect(alarms, hasLength(400));
    for (var i = 1; i < alarms.length; i++) {
      expect(alarms[i].fireAt.isBefore(alarms[i - 1].fireAt), isFalse);
    }
  });

  test('occurrence ids never contain ":" (native side splits keys on it)', () {
    expect(AlarmPlanner.occurrenceId('abc', DateTime.utc(2026, 10, 5, 14, 30)), 'abc~202610051430');
  });

  test('deleted and archived reminders get no alarms', () {
    final r = _r('x', Kind.task, _dt(2026, 10, 6, 9));
    final deleted = Reminder(
      meta: r.meta.touched(_now, deletedAt: _now),
      title: r.title,
      kind: r.kind,
      context: r.context,
      timing: r.timing,
      alertPlan: r.alertPlan,
    );
    expect(_planner().plan([deleted], {}, _now), isEmpty);
  });
}
