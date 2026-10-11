import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

ParseResult _parse(String input, {bool detect = true}) => ReminderParser(
  ParseContext(
    now: DateTime(2026, 10, 5, 14),
    defaultTimeZone: 'America/New_York',
    savedPlaces: const ['Home', 'Work'],
    detectPlaces: detect,
  ),
).parse(input);

void main() {
  test('LOC-16 a place phrase with a date is marked dated (→ On a date)', () {
    expect(_parse('bring tickets when I get to the stadium saturday').place!.dated, isTrue);
    expect(_parse('take out bins when I get home').place!.dated, isFalse);
  });

  test('LOC-16 ignoring the suggestion keeps the phrase in the title', () {
    final r = _parse('take out bins when I get home', detect: false);
    expect(r.place, isNull);
    expect(r.title, 'Take out bins when I get home');
  });
}
