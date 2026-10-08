/// One acceptance case from docs/parser-test-set.md §4 (generated into parser_cases.g.dart).
class ParserCase {
  const ParserCase({
    required this.id,
    required this.input,
    required this.locale,
    required this.title,
    required this.timing,
    required this.kind,
    required this.context,
    required this.rrule,
    required this.afterCompletion,
    required this.alerts,
    required this.nag,
    required this.billKind,
    required this.amount,
    this.subKind,
    required this.flags,
  });

  final String id;
  final String input;
  final String locale;
  final String title;
  final ExpectedTiming? timing;
  final String kind;
  final String context;
  final String? rrule;
  final bool afterCompletion;

  /// Null = the row doesn't state alerts (type defaults apply, parser returns null).
  final List<String>? alerts;
  final String? nag;

  /// Bills only: payment / subscription / trial (BIL-1).
  final String? billKind;

  /// 'USD 1200.00' (PRS-37); null = no amount.
  final String? amount;

  /// SUB-2 subtype, e.g. 'holiday'; null = the row doesn't state one (not checked).
  final String? subKind;
  final Set<String> flags;
}

class ExpectedTiming {
  const ExpectedTiming({required this.type, required this.start, required this.end, required this.tz});

  final String type;
  final String start;
  final String? end;
  final String? tz;
}
