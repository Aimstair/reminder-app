import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

void main() {
  group('BIL-2 money', () {
    test('BIL-2 parses typed numbers into minor units', () {
      expect(Money.parse('1,200', 'usd'), const Money(120000, 'USD'));
      expect(Money.parse('15.49', 'USD'), const Money(1549, 'USD'));
      expect(Money.parse('15,49', 'EUR', decimalComma: true), const Money(1549, 'EUR'));
      expect(Money.parse('500', 'JPY'), const Money(500, 'JPY'), reason: 'yen has no minor unit');
      expect(Money.parse('abc', 'USD'), isNull);
      expect(Money.parse('-5', 'USD'), isNull);
    });

    test('BIL-2 round-trips through JSON and prints a stable form', () {
      const m = Money(120000, 'USD');
      expect(Money.fromJson(m.toJson()), m);
      expect(m.toString(), 'USD 1200.00');
      expect(const Money(500, 'JPY').toString(), 'JPY 500');
    });

    test('BIL-6 sums per currency, largest first', () {
      final s = sumByCurrency(const [Money(1000, 'EUR'), Money(120000, 'USD'), Money(1549, 'USD'), Money(500, 'EUR')]);
      expect(s, const [Money(121549, 'USD'), Money(1500, 'EUR')]);
    });
  });

  group('BIL-3 defaults', () {
    test('ALR-4 bill plans per kind', () {
      String plan(BillKind b) => defaultAlertPlan(Kind.bill, TimingType.date, bill: b).map((s) => s.offset).join(',');
      expect(plan(BillKind.payment), '-2d,0');
      expect(plan(BillKind.subscription), '-1d');
      expect(plan(BillKind.trial), '-3d,-1d');
    });

    test('BIL-3 the user\'s Bill default applies to payments only', () {
      const custom = [AlertStage(AlertOffset(-5, OffsetUnit.days))];
      const prefs = UserPrefs(defaultTimeZone: 'UTC', deviceTimeZone: 'UTC', alertDefaults: {Kind.bill: custom});
      expect(prefs.alertPlanFor(Kind.bill, TimingType.date), custom);
      expect(prefs.alertPlanFor(Kind.bill, TimingType.date, bill: BillKind.trial).length, 2);
    });

    test('BIL-1 bills are completable', () {
      final r = Reminder(
        meta: RecordMeta(id: 'b', createdAt: DateTime.utc(2026), updatedAt: DateTime.utc(2026), deviceId: 'd'),
        title: 'Rent',
        kind: Kind.bill,
        context: ReminderContext.personal,
        timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 11, 1)),
        alertPlan: const [],
      );
      expect(r.completable, isTrue);
      expect(r.billKind, BillKind.payment);
    });
  });
}
