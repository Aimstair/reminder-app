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

  test('TPL-3 Bill due: monthly bill (payment), −2d and 0, nag on', () {
    final p = _apply(Template.billDue, 'Electric on the 15th');
    expect(
      [p.kind, p.billKind, p.rrule, p.alerts, p.nag],
      [
        Kind.bill,
        BillKind.payment,
        'FREQ=MONTHLY',
        ['-2d', '0'],
        '2h',
      ],
    );
  });

  test('TPL-3 Free trial: a trial bill ending in 7 days, "… free trial", −3d and −1d', () {
    final p = _apply(Template.freeTrial, 'Netflix');
    expect(p.title, 'Netflix free trial');
    expect(p.timing!.start, '2026-10-12');
    expect([p.kind, p.billKind, p.rrule, p.nag], [Kind.bill, BillKind.trial, null, null]);
    expect(p.alerts, ['-3d', '-1d']);
  });

  test('TPL-3 Subscription: monthly subscription bill with the typed amount, −1d', () {
    final p = _apply(Template.subscription, 'Spotify \$11.99 on the 20th');
    expect(
      [p.kind, p.billKind, p.rrule, p.alerts, p.nag],
      [
        Kind.bill,
        BillKind.subscription,
        'FREQ=MONTHLY',
        ['-1d'],
        null,
      ],
    );
    expect(p.amount, const Money(1199, 'USD'));
    expect(p.title, 'Spotify');
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
