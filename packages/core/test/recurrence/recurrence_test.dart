import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

String _d(DateTime d) => formatWallDateTime(d);

List<String> _expand(String rrule, DateTime start, DateTime to, {DateTime? from}) =>
    RecurrenceRule.parse(rrule).expand(start, from: from, to: to).map(_d).toList();

void main() {
  final to2027 = DateTime.utc(2027, 12, 31);

  group('REC-2 fixed expansion', () {
    test('daily with interval', () {
      expect(_expand('FREQ=DAILY;INTERVAL=3', DateTime.utc(2026, 10, 6, 9), DateTime.utc(2026, 10, 15, 23, 59)), [
        '2026-10-06T09:00',
        '2026-10-09T09:00',
        '2026-10-12T09:00',
        '2026-10-15T09:00',
      ]);
    });

    test('weekly on several days', () {
      expect(_expand('FREQ=WEEKLY;BYDAY=MO,TH', DateTime.utc(2026, 10, 5, 18), DateTime.utc(2026, 10, 16)), [
        '2026-10-05T18:00',
        '2026-10-08T18:00',
        '2026-10-12T18:00',
        '2026-10-15T18:00',
      ]);
    });

    test('every other Monday', () {
      expect(_expand('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO', DateTime.utc(2026, 10, 5, 15), DateTime.utc(2026, 11, 3)), [
        '2026-10-05T15:00',
        '2026-10-19T15:00',
        '2026-11-02T15:00',
      ]);
    });

    test('weekdays', () {
      expect(
        _expand(
          'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
          DateTime.utc(2026, 10, 8, 9, 30),
          DateTime.utc(2026, 10, 13, 23, 59),
        ),
        ['2026-10-08T09:30', '2026-10-09T09:30', '2026-10-12T09:30', '2026-10-13T09:30'],
      );
    });

    test('weekly without BYDAY uses the start weekday', () {
      expect(_expand('FREQ=WEEKLY;INTERVAL=2', DateTime.utc(2026, 10, 6), DateTime.utc(2026, 11, 1)), [
        '2026-10-06T00:00',
        '2026-10-20T00:00',
      ]);
    });
  });

  group('REC-3 month-end clamp', () {
    test('the 31st falls on the last day of shorter months', () {
      expect(_expand('FREQ=MONTHLY;BYMONTHDAY=31', DateTime.utc(2026, 10, 31), DateTime.utc(2027, 3, 31)), [
        '2026-10-31T00:00',
        '2026-11-30T00:00',
        '2026-12-31T00:00',
        '2027-01-31T00:00',
        '2027-02-28T00:00',
        '2027-03-31T00:00',
      ]);
    });

    test('quarterly', () {
      expect(_expand('FREQ=MONTHLY;INTERVAL=3', DateTime.utc(2027, 1, 15), to2027), [
        '2027-01-15T00:00',
        '2027-04-15T00:00',
        '2027-07-15T00:00',
        '2027-10-15T00:00',
      ]);
    });
  });

  group('REC-4 Feb 29 yearly', () {
    test('falls on Feb 28 in non-leap years, Feb 29 in leap years', () {
      expect(_expand('FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29', DateTime.utc(2027, 2, 28), DateTime.utc(2029, 12, 31)), [
        '2027-02-28T00:00',
        '2028-02-29T00:00',
        '2029-02-28T00:00',
      ]);
    });

    test('plain yearly', () {
      expect(_expand('FREQ=YEARLY', DateTime.utc(2026, 10, 12), DateTime.utc(2028, 12, 31)), [
        '2026-10-12T00:00',
        '2027-10-12T00:00',
        '2028-10-12T00:00',
      ]);
    });
  });

  test('REC-5 last business day of the month', () {
    expect(
      _expand('FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1', DateTime.utc(2026, 10, 30), DateTime.utc(2027, 1, 31)),
      ['2026-10-30T00:00', '2026-11-30T00:00', '2026-12-31T00:00', '2027-01-29T00:00'],
    );
  });

  group('REC-9 / PRS-20 end conditions', () {
    test('UNTIL is inclusive', () {
      expect(_expand('FREQ=DAILY;UNTIL=20261008', DateTime.utc(2026, 10, 6, 9), to2027), [
        '2026-10-06T09:00',
        '2026-10-07T09:00',
        '2026-10-08T09:00',
      ]);
    });

    test('COUNT counts from the series start even when a window starts later', () {
      final all = _expand('FREQ=WEEKLY;BYDAY=WE;COUNT=6', DateTime.utc(2026, 10, 7), to2027);
      expect(all, hasLength(6));
      final windowed = _expand(
        'FREQ=WEEKLY;BYDAY=WE;COUNT=6',
        DateTime.utc(2026, 10, 7),
        to2027,
        from: DateTime.utc(2026, 10, 30),
      );
      expect(windowed, ['2026-11-04T00:00', '2026-11-11T00:00']);
    });
  });

  group('REC-6 / REC-7 repeat after completion', () {
    final rule = RecurrenceRule.parse('FREQ=MONTHLY;INTERVAL=3');
    final due = DateTime.utc(2026, 10, 1, 9);

    test('done late → counted from the completion date', () {
      expect(_d(rule.nextAfterCompletion(from: DateTime.utc(2026, 10, 10), originalStart: due)), '2027-01-10T09:00');
    });

    test('done early → counted from the completion date', () {
      expect(_d(rule.nextAfterCompletion(from: DateTime.utc(2026, 9, 25), originalStart: due)), '2026-12-25T09:00');
    });

    test('skipped → counted from the skipped due date', () {
      expect(_d(rule.nextAfterCompletion(from: due, originalStart: due)), '2027-01-01T09:00');
    });
  });

  test('rejects unsupported rules', () {
    expect(() => RecurrenceRule.parse('FREQ=HOURLY'), throwsFormatException);
  });
}
