/// Output of the quick-capture parser — the shape defined in docs/parser-test-set.md §2.
library;

import '../model/enums.dart';
import '../model/money.dart';

export '../model/enums.dart' show BillKind, Kind, ReminderContext, RecurrenceMode, SubKind, TimingType;

/// Which preview chips to highlight (CAP-7, PRS-*).
enum ParseFlag { ambiguousTime, ambiguousDate, pastDateRolled, timeInPast, titleMissing, dateMissing }

class ParsedTiming {
  const ParsedTiming({required this.type, required this.start, this.end, this.tz});

  final TimingType type;

  /// Wall time in the reminder's zone: `2026-10-11T18:00`, or `2026-10-12` for date-only.
  final String start;
  final String? end;

  /// IANA zone, only when it differs from the user's default zone.
  final String? tz;

  @override
  String toString() => '$type $start${end != null ? '–$end' : ''}${tz != null ? ' [$tz]' : ''}';
}

/// PRS-43: a place phrase ("when I get home") — the capture sheet suggests a place reminder (LOC-16).
class ParsedPlace {
  const ParsedPlace({
    required this.name,
    required this.saved,
    required this.arrive,
    required this.leave,
    this.dated = false,
  });

  /// The saved place's name, or the words as typed ("the stadium").
  final String name;
  final bool saved;
  final bool arrive;
  final bool leave;

  /// The text also said when ("saturday") → the place reminder is "On a date" (LOC-16).
  final bool dated;

  @override
  String toString() => '$name${saved ? ' ✓' : ' ✗'} ${arrive ? 'A' : ''}${leave ? 'L' : ''}';
}

class ParseResult {
  const ParseResult({
    required this.title,
    required this.timing,
    required this.kind,
    required this.context,
    required this.flags,
    this.rrule,
    this.repeatMode,
    this.alerts,
    this.nag,
    this.amount,
    this.billKind = BillKind.payment,
    this.subKind,
    this.place,
  });

  /// Empty when nothing is left after extraction (PRS-36).
  final String title;

  /// Null only when a required date is missing (Occasion without a date, PRS-36).
  final ParsedTiming? timing;
  final Kind kind;
  final ReminderContext context;

  /// RFC 5545 RRULE, e.g. `FREQ=WEEKLY;BYDAY=FR`.
  final String? rrule;
  final RecurrenceMode? repeatMode;

  /// Only when the input states alerts, e.g. `['-14d', '0']` (PRS-24…28). Null = type defaults.
  final List<String>? alerts;

  /// Nag interval, e.g. `2h` (PRS-27).
  final String? nag;

  /// PRS-37: bills only.
  final Money? amount;

  /// BIL-1: meaningful when [kind] is [Kind.bill].
  final BillKind billKind;

  /// SUB-2: subtype guessed from the words (birthday, video call, appointment…).
  final SubKind? subKind;

  /// PRS-43: a place phrase was found.
  final ParsedPlace? place;
  final Set<ParseFlag> flags;

  @override
  String toString() =>
      'ParseResult(title: "$title", timing: $timing, kind: $kind, context: $context, rrule: $rrule, '
      'repeatMode: $repeatMode, alerts: $alerts, nag: $nag, amount: $amount, billKind: $billKind, subKind: $subKind, place: $place, flags: $flags)';
}

/// Inputs the parser needs besides the text.
class ParseContext {
  const ParseContext({
    required this.now,
    required this.defaultTimeZone,
    this.locale = 'en-US',
    this.dayTimeHour = 9,
    this.dayTimeMinute = 0,
    this.currency = 'USD',
    this.savedPlaces = const [],
    this.detectPlaces = true,
  });

  /// Current wall time in [defaultTimeZone]. Only the calendar fields are used.
  final DateTime now;

  /// IANA zone (PRF-1).
  final String defaultTimeZone;

  /// Decides numeric date order: `en-US` → month/day, others → day/month (D3).
  final String locale;

  /// Day time for date-only items and "morning" (PRF-3).
  final int dayTimeHour;
  final int dayTimeMinute;

  /// ISO 4217 default currency (BIL-2, the phone's region) for "$" and bare "dollars".
  final String currency;

  /// PRS-43: names of the user's saved places (LOC-1).
  final List<String> savedPlaces;

  /// False = leave place phrases in the title (saving a normal reminder after ignoring LOC-16's card).
  final bool detectPlaces;
}
