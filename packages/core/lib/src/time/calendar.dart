/// Calendar math on wall times (UTC DateTimes used as containers). REC-3/REC-4/ALR-3 clamping.
library;

/// The date with [day] clamped to the month's last day (Feb 30 → Feb 28/29).
DateTime clampDay(int year, int month, int day, [int hour = 0, int minute = 0]) {
  final last = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, day > last ? last : day, hour, minute);
}

/// Adds months keeping the wall time; month-end clamped (ALR-3: −1 month from Mar 31 → Feb 28/29).
DateTime addMonths(DateTime d, int months, {int? day}) {
  final total = d.month - 1 + months;
  final y = d.year + (total >= 0 ? total ~/ 12 : (total - 11) ~/ 12);
  final m = ((total % 12) + 12) % 12 + 1;
  return clampDay(y, m, day ?? d.day, d.hour, d.minute);
}

DateTime addDays(DateTime d, int days) => DateTime.utc(d.year, d.month, d.day + days, d.hour, d.minute);

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime lastOfMonth(int year, int month) => DateTime.utc(year, month + 1, 0);
