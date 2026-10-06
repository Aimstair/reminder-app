import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

final _t = DateTime.utc(2026, 10, 5);
RecordMeta _m(String id) => RecordMeta(id: id, createdAt: _t, updatedAt: _t, deviceId: 'd');
const _anna = ContactDate(contactId: '1', name: 'Anna', field: ContactDateField.birthday, month: 3, day: 14);

void main() {
  test('CON-4 a birthday becomes a yearly occasion with default alerts', () {
    final r = reminderFromContact(_anna, meta: _m('r'), today: _t);
    expect(r.title, "Anna's birthday");
    expect(r.kind, Kind.occasion);
    expect(r.rrule, 'FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=14');
    expect(formatWallDate(r.timing.start), '2027-03-14'); // CON-5 next occurrence
    expect(r.alertPlan.length, 3);
    expect((r.source as ContactSource).field, 'birthday');
  });

  test('CON-5 Feb 29 without a year falls on Feb 28 in common years', () {
    const leap = ContactDate(contactId: '2', name: 'Leo', field: ContactDateField.birthday, month: 2, day: 29);
    expect(formatWallDate(nextDate(leap, _t)), '2027-02-28');
  });

  test('CON-6 re-scan: add / suggest / update / removed; user-edited dates are kept', () {
    final existing = reminderFromContact(_anna, meta: _m('a'), today: _t);
    const moved = ContactDate(contactId: '1', name: 'Anna', field: ContactDateField.birthday, month: 3, day: 15);
    const bob = ContactDate(contactId: '3', name: 'Bob', field: ContactDateField.anniversary, month: 6, day: 1);
    var plan = planContactSync(existing: [existing], found: [moved, bob], autoAdd: true);
    expect(plan.add.map((c) => c.name), ['Bob']);
    expect(plan.update.single.$2.day, 15);
    plan = planContactSync(existing: [existing], found: [bob], autoAdd: false);
    expect(plan.suggest.map((c) => c.name), ['Bob']);
    expect(plan.removed.single.title, "Anna's birthday");
    final edited = existing.copyWith(
      source: const ContactSource(contactId: '1', field: 'birthday', userEditedDate: true),
    );
    expect(planContactSync(existing: [edited], found: [moved], autoAdd: true).update, isEmpty);
  });
}
