/// Quick capture → reminder (FL-2, CAP-*): turns a parser result into a Reminder ready to save.
library;

import '../model/alert.dart';
import '../model/prefs.dart';
import '../model/reminder.dart';
import '../model/wall_time.dart';
import '../parser/parse_result.dart';

/// Whether [p] can be saved as is (CAP-7: a title and, for occasions, a date are required).
bool canSave(ParseResult p) =>
    p.title.trim().isNotEmpty && p.timing != null && !p.flags.contains(ParseFlag.dateMissing);

/// Builds the reminder for a parse result. Unstated alerts use the type defaults (ALR-4); timed
/// reminders take the stated zone or the default zone (PRF-1, TIM-2).
Reminder reminderFromParse(ParseResult p, {required RecordMeta meta, required UserPrefs prefs, String? rawInput}) {
  final t = p.timing;
  if (t == null) throw ArgumentError('reminderFromParse needs a timing (canSave)');
  final timing = Timing(
    type: t.type,
    start: parseWall(t.start),
    end: t.end == null ? null : parseWall(t.end!),
    timeZone: t.type == TimingType.datetime ? (t.tz ?? prefs.defaultTimeZone) : null,
    timeZoneSetManually: t.tz != null,
  );
  return Reminder(
    meta: meta,
    title: p.title.trim(),
    rawInput: rawInput,
    kind: p.kind,
    context: p.context,
    timing: timing,
    alertPlan: p.alerts == null
        ? prefs.alertPlanFor(p.kind, t.type, bill: p.billKind)
        : [for (final a in p.alerts!) AlertStage(AlertOffset.parse(a))],
    rrule: p.rrule,
    repeatMode: p.repeatMode ?? RecurrenceMode.fixed,
    nagInterval: p.nag == null ? null : _duration(AlertOffset.parse(p.nag!)),
    amount: p.kind == Kind.bill ? p.amount : null, // BIL-2
    billKind: p.billKind,
  );
}

Duration _duration(AlertOffset o) => switch (o.unit) {
  OffsetUnit.minutes => Duration(minutes: o.amount),
  OffsetUnit.hours => Duration(hours: o.amount),
  OffsetUnit.days => Duration(days: o.amount),
  OffsetUnit.weeks => Duration(days: 7 * o.amount),
  OffsetUnit.months => Duration(days: 30 * o.amount),
};
