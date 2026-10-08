/// BIL-6 Bills summary on Schedule: what's still due from today to the end of the month.
library;

import '../model/enums.dart';
import '../model/money.dart';
import 'range.dart';

class BillsSummary {
  const BillsSummary({required this.totals, required this.unpaid});

  /// Per currency, [preferred] first, then by size. Empty when nothing has an amount.
  final List<Money> totals;

  /// Unresolved payment and subscription occurrences (with or without an amount).
  final int unpaid;
}

/// [items]: the range from today to the month's last day. Free trials count as nothing (BIL-6).
BillsSummary billsSummary(Iterable<DayItem> items, {required String preferred}) {
  final due = [
    for (final i in items)
      if (i.reminder.kind == Kind.bill && i.reminder.billKind != BillKind.trial && !i.resolved) i,
  ];
  final totals = sumByCurrency([for (final i in due) ?i.reminder.amount]);
  totals.sort((a, b) => a.currency == preferred ? -1 : (b.currency == preferred ? 1 : 0));
  return BillsSummary(totals: totals, unpaid: due.length);
}

/// BIL-5: the subscription a kept trial becomes is named without the trial wording —
/// "Netflix free trial ends" → "Netflix", "Cancel Hulu trial" → "Hulu". Unchanged if nothing is left.
String subscriptionTitleFromTrial(String title) {
  final t = title
      .replaceAll(RegExp(r'^\s*cancel\s+', caseSensitive: false), '')
      .replaceAll(RegExp(r'\b(free\s+)?trial(\s+(ends?|ending|expires?))?\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (t.isEmpty) return title;
  return t[0].toUpperCase() + t.substring(1);
}
