/// Text formatting shared by screens (copy.md §1 date & time rules, repeat and alert summaries).
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:reminder_core/reminder_core.dart';

import '../l10n/gen/app_localizations.dart';

class Fmt {
  Fmt(this.l10n, this.locale);

  factory Fmt.of(BuildContext context) =>
      Fmt(AppLocalizations.of(context), Localizations.localeOf(context).toString());

  final AppLocalizations l10n;
  final String locale;

  /// 12h/24h follows the device via the locale pattern.
  String time(DateTime wall) => DateFormat.jm(locale).format(wall);

  /// "Mon, Oct 12" this year, "Mon, Oct 12, 2027" otherwise.
  String date(DateTime wall, {DateTime? today}) {
    final now = today ?? DateTime.now();
    return wall.year == now.year ? DateFormat.MMMEd(locale).format(wall) : DateFormat.yMMMEd(locale).format(wall);
  }

  String monthYear(DateTime wall) => DateFormat.yMMMM(locale).format(wall);
  String month(DateTime wall) => DateFormat.MMMM(locale).format(wall);
  String weekdayShort(DateTime wall) => DateFormat.E(locale).format(wall);
  String weekdayNarrow(DateTime wall) => DateFormat.E(locale).format(wall).substring(0, 1);
  String dayLong(DateTime wall) => DateFormat.MMMMEEEEd(locale).format(wall);

  /// "Tomorrow · 6:00 PM", "Mon, Oct 12 · All day" (relative first, absolute second).
  String when(DateTime wall, {required bool allDay, DateTime? end, DateTime? today}) {
    // The phone's local date, not the UTC one (they differ for part of the day outside UTC).
    final t = dateOnly(today ?? DateTime.now());
    final d = dateOnly(wall);
    final day = d == t
        ? l10n.groupToday
        : d == addDays(t, 1)
            ? l10n.groupTomorrow
            : date(wall, today: t);
    if (allDay) return '$day · ${l10n.allDay}';
    final range = end == null ? time(wall) : l10n.timeRange(time(wall), time(end));
    return '$day · $range';
  }

  /// Repeat summary (copy.md §4).
  String repeat(String? rrule, RecurrenceMode mode, {DateTime? start}) {
    if (rrule == null) return l10n.repeatNever;
    final parts = {for (final kv in rrule.split(';').map((e) => e.split('='))) kv[0]: kv.length > 1 ? kv[1] : ''};
    final n = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final byDay = parts['BYDAY'];
    String every;
    switch (parts['FREQ']) {
      case 'DAILY':
        every = l10n.everyDays(n);
      case 'WEEKLY' when byDay == 'MO,TU,WE,TH,FR' && n == 1:
        every = l10n.repeatWeekdays;
      case 'WEEKLY' when n == 1 && byDay != null && !byDay.contains(','):
        every = l10n.everyWeekday(_weekdayName(byDay));
      case 'WEEKLY':
        every = l10n.everyWeeks(n);
      case 'MONTHLY' when parts['BYSETPOS'] == '-1':
        every = l10n.repeatLastBusinessDay;
      case 'MONTHLY' when n == 1 && int.tryParse(parts['BYMONTHDAY'] ?? '') != null:
        every = l10n.monthlyOnDay(ordinal(int.parse(parts['BYMONTHDAY']!)));
      case 'MONTHLY':
        every = l10n.everyMonths(n);
      case 'YEARLY':
        every = l10n.everyYears(n);
      default:
        every = l10n.repeatCustom;
    }
    return mode == RecurrenceMode.afterCompletion ? l10n.repeatAfterDone(every) : every;
  }

  String _weekdayName(String code) {
    const days = {'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7};
    final d = days[code] ?? 1;
    return DateFormat.EEEE(locale).format(DateTime.utc(2026, 10, 4 + d)); // Oct 5 2026 is a Monday
  }

  /// One stage: "At time", "10 min before", "1 week before".
  /// [allDay]: a zero offset on a date-only item reads "on the day" (copy.md §4).
  String offset(AlertOffset offset, {bool allDay = false}) {
    var o = offset;
    if (o.amount == 0) return allDay ? l10n.alertOnTheDay : l10n.alertAtTime;
    // Whole weeks read as weeks: −7 days → "1 week before" (copy.md §4).
    if (o.unit == OffsetUnit.days && o.amount % 7 == 0) o = AlertOffset(o.amount ~/ 7, OffsetUnit.weeks);
    final n = o.amount.abs();
    final rel = switch (o.unit) {
      OffsetUnit.minutes => l10n.relMinutes(n),
      OffsetUnit.hours => l10n.relHours(n),
      OffsetUnit.days => l10n.relDays(n),
      OffsetUnit.weeks => l10n.relWeeks(n),
      OffsetUnit.months => l10n.relMonths(n),
    };
    return o.amount < 0 ? l10n.alertBefore(rel) : rel;
  }

  String alerts(List<AlertStage> plan, {bool allDay = false}) {
    if (plan.isEmpty) return l10n.alertNone;
    final parts = [for (final s in plan) offset(s.offset, allDay: allDay)];
    // "2 days before, on the day": lowercase after the first item, capitalized when alone.
    return [
      for (var i = 0; i < parts.length; i++)
        i == 0 ? parts[i][0].toUpperCase() + parts[i].substring(1) : parts[i],
    ].join(', ');
  }

  /// 1st, 2nd, 3rd… in English; a plain number elsewhere until translations bring their own.
  String ordinal(int n) {
    if (!locale.startsWith('en')) return '$n';
    final tens = n % 100;
    final suffix = tens >= 11 && tens <= 13 ? 'th' : switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
    return '$n$suffix';
  }

  String duration(Duration d) =>
      d.inMinutes % 60 == 0 ? l10n.relHours(d.inHours) : l10n.relMinutes(d.inMinutes);

  String state(OccurrenceState s, {bool overdue = false}) {
    if (overdue) return l10n.stateOverdue;
    return switch (s) {
      OccurrenceState.pending => l10n.statePending,
      OccurrenceState.snoozed => l10n.stateSnoozed,
      OccurrenceState.prepared => l10n.statePrepared,
      OccurrenceState.done => l10n.stateDone,
      OccurrenceState.skipped => l10n.stateSkipped,
      OccurrenceState.passed => l10n.statePassed,
    };
  }

  String kind(Kind k) => switch (k) {
    Kind.task => l10n.typeTask,
    Kind.meeting => l10n.typeMeeting,
    Kind.event => l10n.typeEvent,
    Kind.occasion => l10n.typeOccasion,
  };

  String context(ReminderContext c) => c == ReminderContext.work ? l10n.ctxWork : l10n.ctxPersonal;

  /// "America/New_York" → "New York".
  static String city(String zone) => zone.split('/').last.replaceAll('_', ' ');
}
