import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 10, 5, 14);
final _parser = ReminderParser(ParseContext(now: _now, defaultTimeZone: 'UTC'));
ParseResult _apply(Template t, String s) => applyTemplate(t, _parser.parse(s), input: s, now: _now);

void main() {
  test('TPL-3 Birthday: name only → "\'s birthday", yearly occasion, date still needed', () {
    final p = _apply(Template.birthday, 'Anna');
    expect(p.title, "Anna's birthday");
    expect(p.kind, Kind.occasion);
    expect(p.rrule, 'FREQ=YEARLY');
    expect(p.alerts, ['-7d', '-1d', '0']);
    expect(canSave(p), isFalse);
    expect(canSave(_apply(Template.birthday, 'Anna oct 12')), isTrue);
  });

  test('TPL-3 Bill due: monthly task, −2d and 0, nag on', () {
    final p = _apply(Template.billDue, 'Electric on the 15th');
    expect([p.kind, p.rrule, p.alerts, p.nag], [Kind.task, 'FREQ=MONTHLY', ['-2d', '0'], '2h']);
  });

  test('TPL-3 Free trial: in 7 days, "Cancel … trial", −1d', () {
    final p = _apply(Template.freeTrial, 'Netflix');
    expect(p.title, 'Cancel Netflix trial');
    expect(p.timing!.start, '2026-10-12');
    expect(p.alerts, ['-1d']);
  });

  test('TPL-3 Night out: date only → 19:00', () {
    final p = _apply(Template.nightOut, 'Luigi friday');
    expect(p.timing!.start, startsWith('2026-10-09T19:00'));
    expect(p.kind, Kind.event);
  });

  test('TPL-3 Appointment: −1d at 20:00 the evening before, −1h', () {
    final p = _apply(Template.appointment, 'Dentist friday 2pm');
    expect(p.alerts, ['-1080m', '-1h']); // Thu 20:00 → Fri 14:00 = 18 h
  });

  test('TPL-3 Renewal: yearly, −1 month, −1 week, 0', () {
    expect(_apply(Template.renewal, 'Passport jun 1').alerts, ['-1mo', '-1w', '0']);
  });
}
