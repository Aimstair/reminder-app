// Generates test/parser/parser_cases.g.dart from the tables in docs/parser-test-set.md §4.
// The doc is the source of truth: edit the doc, then run
//   dart run tool/gen_parser_cases.dart
// Section S (stretch) is not counted and is skipped.
import 'dart:io';

const _months = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};
const _flags = {
  'ambiguous_time',
  'ambiguous_date',
  'past_date_rolled',
  'time_in_past',
  'title_missing',
  'date_missing',
};
const _defaultYear = 2026;

void main() {
  final doc = File('../../docs/parser-test-set.md').readAsLinesSync();
  final rowRe = RegExp(r'^\| ([A-N]\d+) \|');
  final cases = <String>[];
  final errors = <String>[];

  for (final line in doc) {
    if (!rowRe.hasMatch(line)) continue;
    final cols = line.split('|').map((c) => c.trim()).toList();
    // ['', id, input, title, when, type, ctx, repeat, notes, '']
    final id = cols[1];
    try {
      cases.add(_case(id, cols[2], cols[3], cols[4], cols[5], cols[6], cols[7], cols[8]));
    } catch (e) {
      errors.add('$id: $e');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Could not parse rows:\n${errors.join('\n')}');
    exit(1);
  }

  final out = StringBuffer()
    ..writeln('// GENERATED from docs/parser-test-set.md by tool/gen_parser_cases.dart — do not edit.')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln("import 'parser_case.dart';")
    ..writeln()
    ..writeln('const parserCases = <ParserCase>[');
  cases.forEach(out.writeln);
  out.writeln('];');
  File('test/parser/parser_cases.g.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(out.toString());
  stdout.writeln('Wrote ${cases.length} cases to test/parser/parser_cases.g.dart');
}

String _q(String s) => "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

String _case(String id, String input, String title, String when, String type, String ctx, String repeat, String notes) {
  var locale = 'en-US';
  final loc = RegExp(r'^`\[(en-[A-Z]{2})\]`\s*').firstMatch(input);
  if (loc != null) {
    locale = loc.group(1)!;
    input = input.substring(loc.end);
  }
  if (input == '*(empty string)*') input = '';
  if (title == '*(empty)*') title = '';

  final kind = {'T': 'task', 'M': 'meeting', 'E': 'event', 'O': 'occasion'}[type] ?? (throw 'bad type $type');
  final context = {'P': 'personal', 'W': 'work'}[ctx] ?? (throw 'bad ctx $ctx');

  // Repeat / alerts column
  final rrule = RegExp(r'`(FREQ=[^`]+)`').firstMatch(repeat)?.group(1);
  final afterCompletion = repeat.contains('after_completion');
  List<String>? alerts;
  final alertsMatch = RegExp(r'alerts ([^·]+)').firstMatch(repeat);
  if (alertsMatch != null) {
    final raw = alertsMatch.group(1)!.trim();
    alerts = raw == '*(none)*'
        ? []
        : raw
              .replaceAll(RegExp(r'\([^)]*\)'), '')
              .split(',')
              .map((s) => s.trim().replaceAll('−', '-'))
              .where((s) => s.isNotEmpty)
              .toList();
  }
  final nag = RegExp(r'nag (\w+)').firstMatch(repeat)?.group(1);

  final flags = RegExp(r'`(\w+)`').allMatches(notes).map((m) => m.group(1)!).where(_flags.contains).toList();

  return '  ParserCase(id: ${_q(id)}, input: ${_q(input)}, locale: ${_q(locale)}, title: ${_q(title)}, '
      'timing: ${_timing(when)}, kind: ${_q(kind)}, context: ${_q(context)}, '
      'rrule: ${rrule == null ? 'null' : _q(rrule)}, afterCompletion: $afterCompletion, '
      'alerts: ${alerts == null ? 'null' : '[${alerts.map(_q).join(', ')}]'}, '
      'nag: ${nag == null ? 'null' : _q(nag)}, flags: {${flags.map(_q).join(', ')}}),';
}

/// "Oct 11 18:00" · "Oct 12 (date)" · "2027-03-01 (date)" · "Oct 6 14:00–16:00"
/// "Oct 10 21:00 – Oct 11 01:00" · "Oct 6 09:00–09:30 [Asia/Tokyo]" · "Nov 1 01:30 (EDT, first)" · "*(none)*"
String _timing(String when) {
  if (when == '*(none)*') return 'null';
  String? tz;
  final tzm = RegExp(r'\s*\[([A-Za-z_/]+)\]$').firstMatch(when);
  if (tzm != null) {
    tz = tzm.group(1);
    when = when.substring(0, tzm.start);
  }
  final isDate = when.endsWith('(date)');
  when = when.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

  const date = r'(\d{4}-\d{2}-\d{2}|[A-Z][a-z]{2} \d{1,2})';
  String iso(String d) {
    if (RegExp(r'^\d{4}-').hasMatch(d)) return d;
    final p = d.split(' ');
    final m = _months[p[0]] ?? (throw 'bad month ${p[0]}');
    return '$_defaultYear-${m.toString().padLeft(2, '0')}-${p[1].padLeft(2, '0')}';
  }

  String? start, end;
  String type;
  Match? m;
  if (isDate && (m = RegExp('^$date\$').firstMatch(when)) != null) {
    type = 'date';
    start = iso(m!.group(1)!);
  } else if ((m = RegExp('^$date (\\d{2}:\\d{2}) – $date (\\d{2}:\\d{2})\$').firstMatch(when)) != null) {
    type = 'datetime';
    start = '${iso(m!.group(1)!)}T${m.group(2)}';
    end = '${iso(m.group(3)!)}T${m.group(4)}';
  } else if ((m = RegExp('^$date (\\d{2}:\\d{2})–(\\d{2}:\\d{2})\$').firstMatch(when)) != null) {
    type = 'datetime';
    start = '${iso(m!.group(1)!)}T${m.group(2)}';
    end = '${iso(m.group(1)!)}T${m.group(3)}';
  } else if ((m = RegExp('^$date (\\d{2}:\\d{2})\$').firstMatch(when)) != null) {
    type = 'datetime';
    start = '${iso(m!.group(1)!)}T${m.group(2)}';
  } else {
    throw 'unrecognized When "$when"';
  }
  return 'ExpectedTiming(type: ${_q(type)}, start: ${_q(start)}, '
      'end: ${end == null ? 'null' : _q(end)}, tz: ${tz == null ? 'null' : _q(tz)})';
}
