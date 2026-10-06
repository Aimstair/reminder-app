/// Output of the quick-capture parser — the shape defined in docs/parser-test-set.md §2.
library;

enum Kind { task, meeting, event, occasion }

enum ReminderContext { personal, work }

enum TimingType { datetime, date }

enum RepeatMode { fixed, afterCompletion }

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
  });

  /// Empty when nothing is left after extraction (PRS-36).
  final String title;

  /// Null only when a required date is missing (Occasion without a date, PRS-36).
  final ParsedTiming? timing;
  final Kind kind;
  final ReminderContext context;

  /// RFC 5545 RRULE, e.g. `FREQ=WEEKLY;BYDAY=FR`.
  final String? rrule;
  final RepeatMode? repeatMode;

  /// Only when the input states alerts, e.g. `['-14d', '0']` (PRS-24…28). Null = type defaults.
  final List<String>? alerts;

  /// Nag interval, e.g. `2h` (PRS-27).
  final String? nag;
  final Set<ParseFlag> flags;

  @override
  String toString() =>
      'ParseResult(title: "$title", timing: $timing, kind: $kind, context: $context, rrule: $rrule, '
      'repeatMode: $repeatMode, alerts: $alerts, nag: $nag, flags: $flags)';
}

/// Inputs the parser needs besides the text.
class ParseContext {
  const ParseContext({
    required this.now,
    required this.defaultTimeZone,
    this.locale = 'en-US',
    this.dayTimeHour = 9,
    this.dayTimeMinute = 0,
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
}
