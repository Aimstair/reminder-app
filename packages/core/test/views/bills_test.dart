import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);
final _now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

Reminder _bill(String title, int day, {Money? amount, BillKind kind = BillKind.payment, String? rrule}) => Reminder(
  meta: RecordMeta(id: title, createdAt: _now, updatedAt: _now, deviceId: 'd'),
  title: title,
  kind: Kind.bill,
  billKind: kind,
  amount: amount,
  context: ReminderContext.personal,
  timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, day)),
  alertPlan: const [],
  rrule: rrule,
);

void main() {
  test('BIL-6 sums unpaid payments and subscriptions to the month end, preferred currency first', () {
    final rent = _bill('Rent', 31, amount: const Money(120000, 'USD'));
    final gym = _bill('Gym', 20, amount: const Money(4900, 'EUR'), kind: BillKind.subscription);
    final spotify = _bill('Spotify', 12, amount: const Money(1199, 'USD'), kind: BillKind.subscription);
    final trial = _bill('Hulu trial', 9, amount: const Money(1799, 'USD'), kind: BillKind.trial);
    final water = _bill('Water', 8); // no amount, still unpaid
    final paid = _bill('Phone', 7, amount: const Money(5000, 'USD'));
    final saved = {
      AlarmPlanner.occurrenceId(paid.id, paid.timing.start): Occurrence(
        meta: RecordMeta(id: 'o', createdAt: _now, updatedAt: _now, deviceId: 'd'),
        reminderId: paid.id,
        occurrenceKey: paid.timing.start,
        state: OccurrenceState.done,
      ),
    };
    final items = RangeView(prefs: _prefs).build(
      [rent, gym, spotify, trial, water, paid],
      saved,
      DateTime.utc(2026, 10, 5),
      DateTime.utc(2026, 10, 31),
      _now,
    );

    final s = billsSummary(items, preferred: 'EUR');
    expect(s.unpaid, 4, reason: 'rent, gym, spotify, water — not the trial, not the paid phone bill');
    expect(s.totals, const [Money(4900, 'EUR'), Money(121199, 'USD')]);
  });

  test('BIL-6 nothing due → no totals', () {
    final s = billsSummary(const [], preferred: 'USD');
    expect([s.totals, s.unpaid], [isEmpty, 0]);
  });

  test('BIL-5 a kept trial drops the trial wording from its title', () {
    expect(subscriptionTitleFromTrial('Netflix free trial ends'), 'Netflix');
    expect(subscriptionTitleFromTrial('Cancel Hulu trial'), 'Hulu');
    expect(subscriptionTitleFromTrial('Disney+ trial expires'), 'Disney+');
    expect(subscriptionTitleFromTrial('Free trial'), 'Free trial', reason: 'nothing left → unchanged');
  });
}
