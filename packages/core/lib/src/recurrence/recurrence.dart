/// RRULE subset used by the app (REC-*). Own implementation because our rules intentionally differ
/// from RFC 5545 in two places: month-end clamp (REC-3) and Feb 29 → Feb 28 (REC-4), where the RFC
/// would skip the month/year instead.
library;

import '../time/calendar.dart';

enum Freq { daily, weekly, monthly, yearly }

class RecurrenceRule {
  const RecurrenceRule({
    required this.freq,
    this.interval = 1,
    this.byDay = const [],
    this.byMonth,
    this.byMonthDay,
    this.bySetPos,
    this.until,
    this.count,
  });

  final Freq freq;
  final int interval;

  /// ISO weekdays (Monday = 1).
  final List<int> byDay;
  final int? byMonth;
  final int? byMonthDay;
  final int? bySetPos;

  /// Last allowed date (inclusive, date part only).
  final DateTime? until;
  final int? count;

  static const _days = {'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7};

  factory RecurrenceRule.parse(String rrule) {
    final parts = <String, String>{};
    for (final p in rrule.split(';')) {
      final i = p.indexOf('=');
      if (i <= 0) throw FormatException('Bad RRULE part "$p"');
      parts[p.substring(0, i).toUpperCase()] = p.substring(i + 1);
    }
    final freq = switch (parts['FREQ']) {
      'DAILY' => Freq.daily,
      'WEEKLY' => Freq.weekly,
      'MONTHLY' => Freq.monthly,
      'YEARLY' => Freq.yearly,
      _ => throw FormatException('Unsupported FREQ in "$rrule"'),
    };
    DateTime? until;
    final u = parts['UNTIL'];
    if (u != null)
      until = DateTime.utc(int.parse(u.substring(0, 4)), int.parse(u.substring(4, 6)), int.parse(u.substring(6, 8)));
    return RecurrenceRule(
      freq: freq,
      interval: int.tryParse(parts['INTERVAL'] ?? '') ?? 1,
      byDay:
          (parts['BYDAY']?.split(',') ?? const [])
              .map((d) => _days[d] ?? (throw FormatException('Bad BYDAY $d')))
              .toList()
            ..sort(),
      byMonth: int.tryParse(parts['BYMONTH'] ?? ''),
      byMonthDay: int.tryParse(parts['BYMONTHDAY'] ?? ''),
      bySetPos: int.tryParse(parts['BYSETPOS'] ?? ''),
      until: until,
      count: int.tryParse(parts['COUNT'] ?? ''),
    );
  }

  /// Occurrence starts (wall times) of a series beginning at [dtstart], in order.
  /// Only starts within [from]…[to] (inclusive) are returned, but COUNT always counts from [dtstart].
  Iterable<DateTime> expand(DateTime dtstart, {DateTime? from, required DateTime to}) sync* {
    var produced = 0;
    for (final d in _raw(dtstart)) {
      if (d.isAfter(to)) return;
      if (until != null && dateOnly(d).isAfter(until!)) return;
      if (count != null && produced >= count!) return;
      produced++;
      if (from == null || !d.isBefore(from)) yield d;
    }
  }

  /// Unbounded candidates ≥ dtstart.
  Iterable<DateTime> _raw(DateTime start) sync* {
    final h = start.hour, mi = start.minute;
    switch (freq) {
      case Freq.daily:
        for (var k = 0; ; k++) {
          yield addDays(start, k * interval);
        }
      case Freq.weekly:
        final days = byDay.isEmpty ? [start.weekday] : byDay;
        final weekStart = addDays(dateOnly(start), -(start.weekday - 1)); // Monday
        for (var w = 0; ; w += interval) {
          for (final wd in days) {
            final d = addDays(weekStart, w * 7 + wd - 1);
            final dt = DateTime.utc(d.year, d.month, d.day, h, mi);
            if (!dt.isBefore(start)) yield dt;
          }
        }
      case Freq.monthly:
        for (var k = 0; ; k += interval) {
          final first = addMonths(DateTime.utc(start.year, start.month, 1), k);
          final DateTime? d;
          if (bySetPos != null && byDay.isNotEmpty) {
            d = _setPos(first.year, first.month);
          } else {
            d = clampDay(first.year, first.month, byMonthDay ?? start.day); // REC-3
          }
          if (d == null) continue;
          final dt = DateTime.utc(d.year, d.month, d.day, h, mi);
          if (!dt.isBefore(start)) yield dt;
        }
      case Freq.yearly:
        final month = byMonth ?? start.month;
        final day = byMonthDay ?? start.day;
        for (var k = 0; ; k += interval) {
          final dt = clampDay(start.year + k, month, day, h, mi); // REC-4: Feb 29 → Feb 28
          if (!dt.isBefore(start)) yield dt;
        }
    }
  }

  /// REC-5: e.g. last business day = BYDAY=MO..FR;BYSETPOS=-1.
  DateTime? _setPos(int year, int month) {
    final last = lastOfMonth(year, month).day;
    final matches = [
      for (var d = 1; d <= last; d++)
        if (byDay.contains(DateTime.utc(year, month, d).weekday)) DateTime.utc(year, month, d),
    ];
    if (matches.isEmpty) return null;
    final i = bySetPos! > 0 ? bySetPos! - 1 : matches.length + bySetPos!;
    return (i >= 0 && i < matches.length) ? matches[i] : null;
  }

  /// REC-6 / REC-7: next occurrence of an after-completion series.
  /// Done → from the completion date; skipped → from the skipped occurrence's due date.
  /// Keeps the original time of day.
  DateTime nextAfterCompletion({required DateTime from, required DateTime originalStart}) {
    final base = DateTime.utc(from.year, from.month, from.day, originalStart.hour, originalStart.minute);
    return switch (freq) {
      Freq.daily => addDays(base, interval),
      Freq.weekly => addDays(base, 7 * interval),
      Freq.monthly => addMonths(base, interval),
      Freq.yearly => addMonths(base, 12 * interval),
    };
  }
}
