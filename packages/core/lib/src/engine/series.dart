/// Editing recurring reminders (REC-11…15) and archiving (DAT-3).
library;

import '../model/enums.dart';
import '../model/reminder.dart';
import '../recurrence/recurrence.dart';
import '../time/calendar.dart';

/// Scope chosen in the S-34 dialog.
enum EditScope { thisOne, thisAndFuture, all }

/// REC-13: the series up to (not including) the occurrence on [occurrenceKey]'s day, by adding
/// `UNTIL` = the day before. Returns null when nothing would remain (editing from the first occurrence).
Reminder? endSeriesBefore(Reminder r, DateTime occurrenceKey) {
  if (r.rrule == null) return null;
  final firstDay = dateOnly(r.timing.start);
  final cut = addDays(dateOnly(occurrenceKey), -1);
  if (cut.isBefore(firstDay)) return null;
  return r.copyWith(rrule: () => setUntil(r.rrule!, cut));
}

/// Replaces any UNTIL/COUNT in [rrule] with `UNTIL=yyyyMMdd` (date, inclusive).
String setUntil(String rrule, DateTime day) {
  final parts = rrule.split(';').where((p) => !p.startsWith('UNTIL=') && !p.startsWith('COUNT=')).toList();
  String two(int n) => n.toString().padLeft(2, '0');
  parts.add('UNTIL=${day.year}${two(day.month)}${two(day.day)}');
  return parts.join(';');
}

/// REC-6 / REC-7: the next start of an after-completion series. Done → from the completion day;
/// skipped → from the skipped occurrence's own date.
DateTime nextAfterCompletionStart(Reminder r, {required DateTime fromWall}) =>
    RecurrenceRule.parse(r.rrule!).nextAfterCompletion(from: fromWall, originalStart: r.timing.start);

/// REC-9: does a fixed series have any occurrence after [occurrenceKey]?
bool hasLaterOccurrence(Reminder r, DateTime occurrenceKey) {
  if (r.rrule == null) return false;
  if (r.repeatMode == RecurrenceMode.afterCompletion) return true; // REC-6 continues until stopped
  final rule = RecurrenceRule.parse(r.rrule!);
  if (rule.until == null && rule.count == null) return true;
  final after = occurrenceKey.add(const Duration(minutes: 1));
  return rule.expand(r.timing.start, from: after, to: DateTime.utc(9999)).isNotEmpty;
}

/// DAT-3: one-time reminders are archived 7 days after being resolved; recurring ones when the
/// series has ended and its last occurrence is resolved.
bool shouldArchive(Reminder r, {required Occurrence? last, required DateTime now}) {
  if (r.status != ReminderStatus.active || r.isCalendarEvent) return false;
  if (last == null || !last.state.isResolved) return false;
  if (r.rrule != null && hasLaterOccurrence(r, last.occurrenceKey)) return false;
  final resolvedAt = last.resolvedAt ?? last.meta.updatedAt;
  return r.rrule != null || !now.isBefore(resolvedAt.add(const Duration(days: 7)));
}
