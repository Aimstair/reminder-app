import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);
final _now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

Reminder _r(String title, Kind kind, DateTime day, {String? notes}) => Reminder(
  meta: RecordMeta(id: title, createdAt: _now, updatedAt: _now, deviceId: 'd'),
  title: title,
  notes: notes,
  kind: kind,
  context: ReminderContext.personal,
  timing: Timing(type: TimingType.date, start: day),
  alertPlan: const [],
);

void main() {
  test('DIG-2 overdue, OVD-3 stale after 30 days, occasions in the next 7 days', () {
    final d = buildDigest(
      reminders: [
        _r('Old bill', Kind.task, DateTime.utc(2026, 8, 20)),
        _r('Yesterday', Kind.task, DateTime.utc(2026, 10, 4)),
        _r("Mom's birthday", Kind.occasion, DateTime.utc(2026, 10, 9)),
        _r('Far party', Kind.occasion, DateTime.utc(2026, 10, 30)),
      ],
      saved: {},
      prefs: _prefs,
      now: _now,
      missed: 1,
    );
    expect(d.overdue.map((i) => i.reminder.title), ['Old bill', 'Yesterday']);
    expect(d.stale.map((i) => i.reminder.title), ['Old bill']);
    expect(d.upcomingOccasions.map((i) => i.reminder.title), ["Mom's birthday"]);
    expect(d.isEmpty, isFalse);
  });

  test('DIG-1 card shows from digest time until dismissed for the day', () {
    final early = wallToInstant(DateTime.utc(2026, 10, 5, 7), _ny);
    expect(digestVisible(prefs: _prefs, now: early), isFalse);
    expect(digestVisible(prefs: _prefs, now: _now), isTrue);
    expect(digestVisible(prefs: _prefs, now: _now, dismissedDay: DateTime.utc(2026, 10, 5)), isFalse);
  });

  test('S-40 search: all words, notes too, accents ignored, title hits first', () {
    final list = [
      _r('Café with Ana', Kind.event, DateTime.utc(2026, 10, 9)),
      _r('Groceries', Kind.task, DateTime.utc(2026, 10, 9), notes: 'cafe beans'),
    ];
    expect(searchReminders(list, 'cafe').map((r) => r.title), ['Café with Ana', 'Groceries']);
    expect(searchReminders(list, 'cafe ana').map((r) => r.title), ['Café with Ana']);
    expect(searchReminders(list, '  '), isEmpty);
  });

  test('ATT-1 search finds a reminder by a link or file name', () {
    final r = _r('Trip', Kind.event, DateTime.utc(2026, 10, 9)).copyWith(
      attachments: [
        Attachment.link('airline.com/booking', name: 'Boarding pass'),
        const Attachment(kind: AttachmentKind.file, uri: '/x', name: 'Hotel-voucher.pdf'),
      ],
    );
    expect(searchReminders([r], 'boarding'), [r]);
    expect(searchReminders([r], 'voucher'), [r]);
    expect(searchReminders([r], 'airline'), isEmpty, reason: 'names only, not addresses');
  });
}
