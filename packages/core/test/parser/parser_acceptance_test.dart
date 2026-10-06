// Parser acceptance tests — one test per row of docs/parser-test-set.md §4 (generated data).
// Setup per §1: now = Mon Oct 5 2026 14:00, default zone America/New_York, day time 09:00.
import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

import 'parser_case.dart';
import 'parser_cases.g.dart';

const _flagNames = {
  ParseFlag.ambiguousTime: 'ambiguous_time',
  ParseFlag.ambiguousDate: 'ambiguous_date',
  ParseFlag.pastDateRolled: 'past_date_rolled',
  ParseFlag.timeInPast: 'time_in_past',
  ParseFlag.titleMissing: 'title_missing',
  ParseFlag.dateMissing: 'date_missing',
};

ReminderParser _parser(String locale) => ReminderParser(
  ParseContext(now: DateTime(2026, 10, 5, 14, 0), defaultTimeZone: 'America/New_York', locale: locale),
);

/// Compares every field the row states (docs/parser-test-set.md §2). Returns mismatches.
List<String> check(ParserCase c, ParseResult r) {
  final errs = <String>[];
  void eq(String field, Object? expected, Object? actual) {
    if (expected != actual) errs.add('$field: expected <$expected> got <$actual>');
  }

  eq('title', c.title, r.title);
  if (c.timing == null) {
    eq('timing', null, r.timing?.toString());
  } else if (r.timing == null) {
    errs.add('timing: expected ${c.timing!.start} got null');
  } else {
    eq('timing.type', c.timing!.type, r.timing!.type.name);
    eq('timing.start', c.timing!.start, r.timing!.start);
    eq('timing.end', c.timing!.end, r.timing!.end);
    eq('timing.tz', c.timing!.tz, r.timing!.tz);
  }
  eq('kind', c.kind, r.kind.name);
  eq('context', c.context, r.context.name);
  eq('rrule', c.rrule, r.rrule);
  eq('afterCompletion', c.afterCompletion, r.repeatMode == RecurrenceMode.afterCompletion);
  if (c.alerts != null) eq('alerts', c.alerts!.join(','), r.alerts?.join(','));
  eq('nag', c.nag, r.nag);
  eq('flags', (c.flags.toList()..sort()).join(','), (r.flags.map((f) => _flagNames[f]!).toList()..sort()).join(','));
  return errs;
}

void main() {
  group('parser-test-set.md', () {
    for (final c in parserCases) {
      test('${c.id} ${c.input}', () {
        final r = _parser(c.locale).parse(c.input);
        final errs = check(c, r);
        expect(errs, isEmpty, reason: errs.join('\n'));
      });
    }
  });

  test('pass rate ≥ 90% (v0 exit) — report', () {
    var pass = 0;
    final failed = <String>[];
    for (final c in parserCases) {
      final errs = check(c, _parser(c.locale).parse(c.input));
      if (errs.isEmpty) {
        pass++;
      } else {
        failed.add('${c.id} "${c.input}": ${errs.join('; ')}');
      }
    }
    final rate = pass / parserCases.length;
    // ignore: avoid_print
    print('Parser: $pass/${parserCases.length} (${(rate * 100).toStringAsFixed(1)}%)\n${failed.join('\n')}');
    expect(rate, greaterThanOrEqualTo(0.90));
  });
}
