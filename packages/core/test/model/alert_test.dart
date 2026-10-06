import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

void main() {
  group('ALR-1 alert offsets', () {
    test('parse and print round-trip', () {
      for (final s in ['-7d', '-1d', '0', '-10m', '-1h', '-6mo', '-2w', '15m']) {
        expect(AlertOffset.parse(s).toString(), s);
      }
    });

    test('rejects garbage', () {
      expect(() => AlertOffset.parse('soon'), throwsFormatException);
    });

    test('stage JSON round-trip keeps label and channels', () {
      const stage = AlertStage(AlertOffset(-2, OffsetUnit.days), label: 'Start by');
      expect(AlertStage.fromJson(stage.toJson()), stage);
    });
  });

  group('ALR-4 default alert plans', () {
    test('Meeting −10m, Event −1h, Task at time', () {
      expect(defaultAlertPlan(Kind.meeting, TimingType.datetime).map((s) => '${s.offset}'), ['-10m']);
      expect(defaultAlertPlan(Kind.event, TimingType.datetime).map((s) => '${s.offset}'), ['-1h']);
      expect(defaultAlertPlan(Kind.task, TimingType.date).map((s) => '${s.offset}'), ['0']);
    });

    test('Occasion −7d, −1d, on the day', () {
      expect(defaultAlertPlan(Kind.occasion, TimingType.date).map((s) => '${s.offset}'), ['-7d', '-1d', '0']);
    });

    test('OCC-3 prep stages are the ones before the anchor', () {
      final plan = defaultAlertPlan(Kind.occasion, TimingType.date);
      expect(plan.where((s) => s.isPrep).length, 2);
    });
  });

  test('DAT-4 ids are unique UUID v7', () {
    final ids = List.generate(100, (_) => newId());
    expect(ids.toSet().length, 100);
    expect(ids.first[14], '7'); // version nibble
  });

  test('sources serialize and restore', () {
    const src = ContactSource(contactId: 'c1', field: 'birthday', userEditedDate: true);
    final back = ReminderSource.fromJson(src.toJson()) as ContactSource;
    expect(back.contactId, 'c1');
    expect(back.userEditedDate, isTrue);
    expect(ReminderSource.fromJson(const {'type': 'manual'}), isA<ManualSource>());
  });
}
