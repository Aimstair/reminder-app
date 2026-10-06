import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/l10n/gen/app_localizations_en.dart';
import 'package:reminder_app/notifications/alert_text.dart';
import 'package:reminder_core/reminder_core.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);
final _now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

Reminder _r(Kind kind, Timing timing, List<AlertStage> plan, {Duration? nag}) => Reminder(
  meta: RecordMeta(id: 'r', createdAt: _now, updatedAt: _now, deviceId: 'd'),
  title: 'T',
  kind: kind,
  context: ReminderContext.personal,
  timing: timing,
  alertPlan: plan,
  nagInterval: nag,
);

List<String> _bodies(Reminder r, {DateTime? now}) {
  final builder = NotificationTextBuilder(l10n: AppLocalizationsEn(), prefs: _prefs, locale: 'en');
  return AlarmPlanner(prefs: _prefs, text: builder.call)
      .plan([r], {}, now ?? _now)
      .map((a) => a.body.replaceAll(' ', ' '))
      .toList(); // intl uses a narrow no-break space before AM/PM
}

void main() {
  setUpAll(() => NotificationTextBuilder.init('en'));

  test('meeting: "In 10 min · 10:00 AM" (copy.md notif.meeting)', () {
    final r = _r(
      Kind.meeting,
      Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 6, 10), timeZone: _ny),
      const [AlertStage(AlertOffset(-10, OffsetUnit.minutes))],
    );
    expect(_bodies(r), ['In 10 min · 10:00 AM']);
  });

  test('task at its time: "Now · 6:00 PM"', () {
    final r = _r(
      Kind.task,
      Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 5, 18), timeZone: _ny),
      const [AlertStage(AlertOffset.zero)],
    );
    expect(_bodies(r), ['Now · 6:00 PM']);
  });

  test('occasion one week out: "In 1 week · Mon, Oct 12"', () {
    final r = _r(Kind.occasion, Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 19)), const [
      AlertStage(AlertOffset(-7, OffsetUnit.days)),
    ]);
    expect(_bodies(r), ['In 1 week · Mon, Oct 19']);
  });

  test('Start by: "Start today · due Fri, Oct 9" (ALR-5)', () {
    final r = _r(Kind.task, Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 9)), const [
      AlertStage(AlertOffset(-2, OffsetUnit.days), label: 'start_by'),
    ]);
    expect(_bodies(r), ['Start today · due Fri, Oct 9']);
  });

  test('nag: "Still to do · due today"', () {
    final r = _r(Kind.task, Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 6)), const [
      AlertStage(AlertOffset.zero),
    ], nag: const Duration(hours: 2));
    final bodies = _bodies(r);
    expect(bodies.first, 'Today');
    expect(bodies[1], 'Still to do · due today');
  });

  test('passport six months out: "In 6 months · Tue, Jun 1"', () {
    final r = _r(Kind.task, Timing(type: TimingType.date, start: DateTime.utc(2027, 6, 1)), const [
      AlertStage(AlertOffset(-6, OffsetUnit.months)),
    ]);
    expect(_bodies(r, now: wallToInstant(DateTime.utc(2026, 11, 25), _ny)), ['In 6 months · Tue, Jun 1']);
  });
}
