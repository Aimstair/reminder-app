/// Capture templates (TPL-1…4): preset type, repeat and alerts the parser must not change (CAP-11).
library;

import '../model/wall_time.dart';
import '../parser/parse_result.dart';
import '../time/calendar.dart';

/// TPL-1 order on the capture sheet.
enum Template { birthday, billDue, subscription, freeTrial, renewal, nightOut, appointment }

/// TPL-3 definitions.
extension TemplateDef on Template {
  Kind get kind => switch (this) {
    Template.birthday => Kind.occasion,
    Template.billDue || Template.subscription || Template.freeTrial => Kind.bill, // BIL-1
    Template.renewal => Kind.task,
    Template.nightOut || Template.appointment => Kind.event,
  };

  BillKind get billKind => switch (this) {
    Template.subscription => BillKind.subscription,
    Template.freeTrial => BillKind.trial,
    _ => BillKind.payment,
  };

  /// SUB-1: Birthday is a birthday; Appointment an appointment; Night out a social event.
  SubKind? get subKind => switch (this) {
    Template.birthday => SubKind.birthday,
    Template.appointment => SubKind.appointment,
    Template.nightOut => SubKind.social,
    _ => null,
  };

  String? get rrule => switch (this) {
    Template.birthday || Template.renewal => 'FREQ=YEARLY',
    Template.billDue || Template.subscription => 'FREQ=MONTHLY',
    _ => null,
  };

  List<String> get alerts => switch (this) {
    Template.birthday => const ['-7d', '-1d', '0'],
    Template.billDue => const ['-2d', '0'],
    Template.subscription => const ['-1d'],
    Template.renewal => const ['-1mo', '-1w', '0'],
    Template.freeTrial => const ['-3d', '-1d'],
    Template.nightOut => const ['-1d', '-1h'],
    Template.appointment => const ['-1d', '-1h'], // −1d is moved to 20:00 the evening before in apply()
  };

  String? get nag => this == Template.billDue ? '2h' : null;

  String get id => name;
}

/// TPL-2: applies [t] to a parse of what the user typed ([input]). [now] = wall time in the default zone.
ParseResult applyTemplate(Template t, ParseResult p, {required String input, required DateTime now}) {
  var title = p.title.trim();
  var timing = p.timing;
  // Nothing was taken out of the input → the date is the parser's CAP-1 default, not typed.
  final noDateTyped = title.toLowerCase() == input.trim().toLowerCase();
  final flags = {...p.flags}..remove(ParseFlag.titleMissing);

  switch (t) {
    case Template.birthday:
      // "Anna" → "Anna's birthday"
      if (title.isNotEmpty && !title.toLowerCase().contains('birthday')) title = "$title's birthday";
      if (timing != null && timing.type == TimingType.datetime) {
        timing = ParsedTiming(type: TimingType.date, start: timing.start.substring(0, 10));
      }
      if (noDateTyped) flags.add(ParseFlag.dateMissing); // a birthday needs its date
    case Template.freeTrial:
      // "Netflix" → "Netflix free trial"; the date is the day it ends (BIL-1).
      if (title.isNotEmpty && !title.toLowerCase().contains('trial')) title = '$title free trial';
      if (timing == null || noDateTyped) {
        timing = ParsedTiming(type: TimingType.date, start: formatWallDate(addDays(dateOnly(now), 7)));
      }
    case Template.nightOut:
      if (timing != null && timing.type == TimingType.date) {
        timing = ParsedTiming(type: TimingType.datetime, start: '${timing.start}T19:00', tz: timing.tz);
      }
    case Template.billDue || Template.subscription || Template.renewal || Template.appointment:
      break;
  }

  var alerts = t.alerts;
  if (t == Template.appointment && timing != null) {
    // −1d at 20:00 the evening before: offset from the anchor in minutes.
    final anchor = timing.type == TimingType.datetime
        ? parseWall(timing.start)
        : parseWall(timing.start).add(const Duration(hours: 9));
    final eve = DateTime.utc(anchor.year, anchor.month, anchor.day - 1, 20);
    alerts = ['-${anchor.difference(eve).inMinutes}m', '-1h'];
  }

  if (title.isEmpty) flags.add(ParseFlag.titleMissing);
  return ParseResult(
    title: title,
    timing: timing,
    kind: t.kind,
    context: p.context,
    flags: flags,
    rrule: t.rrule ?? p.rrule,
    repeatMode: t.rrule != null ? RecurrenceMode.fixed : p.repeatMode,
    alerts: alerts,
    nag: t.nag ?? (t.kind == Kind.bill ? null : p.nag),
    amount: t.kind == Kind.bill ? p.amount : null,
    billKind: t.billKind,
    subKind: t.subKind ?? (p.kind == t.kind ? p.subKind : null),
  );
}
