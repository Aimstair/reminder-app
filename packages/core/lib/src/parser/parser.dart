/// Quick-capture natural-language parser (docs/parser-test-set.md, behavior-spec §8 CAP-*).
///
/// Approach: match phrases in a fixed order (prefixes → alerts → recurrence → times → dates),
/// mark each matched span as used, then build the title from the unused text and resolve
/// date/time with the CAP rules. Pure Dart; calendar math uses UTC DateTimes as wall-clock containers.
library;

import '../capture/subkind.dart';
import '../model/money.dart';
import '../time/zones.dart';
import 'parse_result.dart';
import 'vocab.dart';

class ReminderParser {
  ReminderParser(this.context) {
    ensureTimeZones();
  }

  final ParseContext context;

  ParseResult parse(String input) => _Run(input, context).run();
}

// ---------------------------------------------------------------------------

enum _DateKind { absolute, today, relative, weekday, nth, monthYear }

class _DateSpec {
  _DateSpec(this.kind, {this.day, this.weekday, this.next = false, this.nth, this.yearGiven = false});
  final _DateKind kind;
  DateTime? day; // absolute / relative / monthYear
  final int? weekday; // 1..7
  final bool next; // "next Friday"
  final int? nth; // "the 15th"
  final bool yearGiven;
}

class _Time {
  _Time(this.minutes, {this.ambiguous = false});
  int minutes; // minutes since midnight; 1440 = midnight (next day)
  final bool ambiguous;
}

class _Recurrence {
  String freq = 'DAILY';
  int interval = 1;
  List<int> byDay = [];
  int? byMonth;
  int? byMonthDay;
  int? bySetPos;
  DateTime? until;
  int? count;
  bool lastBusinessDay = false;
  bool afterCompletion = false;

  String build() {
    final parts = ['FREQ=$freq'];
    if (interval > 1) parts.add('INTERVAL=$interval');
    if (byMonth != null) parts.add('BYMONTH=$byMonth');
    if (byDay.isNotEmpty) parts.add('BYDAY=${byDay.map((d) => rruleDay[d]).join(',')}');
    if (byMonthDay != null) parts.add('BYMONTHDAY=$byMonthDay');
    if (bySetPos != null) parts.add('BYSETPOS=$bySetPos');
    if (until != null) parts.add('UNTIL=${_ymd(until!).replaceAll('-', '')}');
    if (count != null) parts.add('COUNT=$count');
    return parts.join(';');
  }
}

class _Run {
  _Run(String input, this.ctx)
    : text = input.trim().replaceAll(RegExp(r'\s+'), ' '),
      today = DateTime.utc(ctx.now.year, ctx.now.month, ctx.now.day) {
    lower = text.toLowerCase();
    used = List.filled(text.length, false);
    nowMinutes = ctx.now.hour * 60 + ctx.now.minute;
  }

  final ParseContext ctx;
  final String text;
  final DateTime today;
  late final String lower;
  late final List<bool> used;
  late final int nowMinutes;

  final flags = <ParseFlag>{};
  ReminderContext? contextOverride;
  _DateSpec? date;
  _Time? time;
  _Time? endTime;
  Duration? relative; // "in 30 minutes"
  String? zone;
  _Recurrence? rec;
  bool untilDoneNag = false;
  bool noAlert = false;
  ({int amount, String unit})? alertBefore;
  bool nightBefore = false;
  bool dayBefore = false;
  int? startByWeekday;

  /// PRS-37: amount found in the text, and the characters it used (given back on non-bills).
  Money? amount;
  List<int> amountSpan = const [];

  // ---- span helpers ----

  bool _free(int s, int e) {
    for (var i = s; i < e; i++) {
      if (used[i]) return false;
    }
    return true;
  }

  static final _connector = RegExp(r'\b(at|on|by|for|due|from|in|until)\s+$');

  void _use(int s, int e, {bool absorb = true}) {
    for (var i = s; i < e; i++) {
      used[i] = true;
    }
    if (!absorb) return;
    final m = _connector.firstMatch(lower.substring(0, s));
    if (m != null && _free(m.start, s)) {
      for (var i = m.start; i < s; i++) {
        used[i] = true;
      }
    }
  }

  /// All matches whose span is still unused, consuming each as it goes.
  List<RegExpMatch> _take(RegExp re, {bool absorb = true}) {
    final out = <RegExpMatch>[];
    for (final m in re.allMatches(lower)) {
      if (m.end > m.start && _free(m.start, m.end)) {
        _use(m.start, m.end, absorb: absorb);
        out.add(m);
      }
    }
    return out;
  }

  static int _num(String s) => int.tryParse(s) ?? numberWords[s] ?? 1;

  // ---- pipeline ----

  ParseResult run() {
    _prefixes();
    _amount(); // first, so "$15.49" never reads as a time
    _alerts();
    _recurrence();
    _relativeTime();
    _ranges();
    _times();
    _dates();

    var title = _title();
    final (kind, billKind) = _kind(title);
    if (kind != Kind.bill && amount != null) {
      // PRS-37: an amount only belongs to a bill; elsewhere it stays in the title.
      for (final i in amountSpan) {
        used[i] = false;
      }
      amount = null;
      title = _title();
    }
    final context =
        contextOverride ??
        (kind == Kind.meeting || _hasAny(title.toLowerCase(), workWords)
            ? ReminderContext.work
            : ReminderContext.personal);

    // PRS-14: meal default time for Events without a time
    if (kind == Kind.event && time == null && relative == null) {
      for (final e in mealHours.entries) {
        if (RegExp('\\b${e.key}\\b').hasMatch(title.toLowerCase())) {
          time = _Time(e.value * 60);
          break;
        }
      }
    }

    // PRS-30: occasions repeat yearly
    if (kind == Kind.occasion && rec == null) rec = _Recurrence()..freq = 'YEARLY';
    // PRS-38: bill defaults
    if (kind == Kind.bill) {
      switch (billKind) {
        case BillKind.payment:
          untilDoneNag = true;
        case BillKind.subscription:
          if (rec == null) {
            rec = _Recurrence()..freq = 'MONTHLY';
            if (date?.kind == _DateKind.absolute && date!.day != null) rec!.byMonthDay = date!.day!.day;
          }
        case BillKind.trial:
          rec = null;
          if (date == null && time == null && relative == null) {
            date = _DateSpec(_DateKind.relative, day: today.add(const Duration(days: 7)));
            flags.add(ParseFlag.ambiguousDate);
          }
      }
    }
    if (rec != null && rec!.freq == 'WEEKLY' && rec!.byDay.isEmpty && date?.kind == _DateKind.weekday) {
      rec!.byDay = [date!.weekday!]; // "weekly on Sunday"
    }
    if (rec != null && rec!.freq == 'MONTHLY' && date?.kind == _DateKind.nth) {
      rec!.byMonthDay = date!.nth; // "on the 1st every month"
    }
    if (rec != null && rec!.freq == 'YEARLY' && _clamped != null) {
      // REC-4: keep the real day (Feb 29) so leap years land on it; the first date shown is clamped
      rec!
        ..byMonth = _clamped!.month
        ..byMonthDay = _clamped!.day;
    }

    final timing = _timing(kind);
    final alerts = _alertList(kind, timing);

    if (title.isEmpty) flags.add(ParseFlag.titleMissing);

    return ParseResult(
      title: title,
      timing: timing,
      kind: kind,
      context: context,
      rrule: rec?.build(),
      repeatMode: rec == null ? null : (rec!.afterCompletion ? RecurrenceMode.afterCompletion : RecurrenceMode.fixed),
      alerts: alerts,
      nag: untilDoneNag ? '2h' : null,
      amount: amount,
      billKind: billKind,
      subKind: guessSubKind(kind, title), // SUB-2
      flags: flags,
    );
  }

  /// PRS-37: "$1,200", "€450", "USD 320", "85 dollars"…
  void _amount() {
    const number = r'(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)';
    final symbols = currencySymbols.keys.map(RegExp.escape).join('|');
    final codes = currencyCodes.join('|');
    final words = currencyWords.keys.join('|');
    // "k" = thousand ("$2k", "1.5k dollars"), only when no letter follows ("2kg" is not money).
    const k = r'(?<k>k(?![a-z]))?';
    final n = '(?<n>$number)';
    final patterns = [
      RegExp('(?<u>$symbols)\\s?$n$k(?!\\d)'), // $100 · € 450
      RegExp('\\b(?<u>$codes)\\s?$n$k\\b(?: (?:$words)\\b)?'), // USD 100 · usd100 · "USD 100 dollars"
      RegExp('(?<![\\w.,])$n$k\\s?(?<u>$symbols)'), // 100$ · 450 € · 20£
      RegExp('\\b$n$k\\s?(?<u>$codes|$words)\\b(?: (?:$words)\\b)?'), // 100 usd · 85 dollars · 100 USD dollars
    ];
    for (final re in patterns) {
      final m = re.firstMatch(lower);
      if (m == null || !_free(m.start, m.end)) continue;
      var money = Money.parse(m.namedGroup('n')!, _currencyFor(m.namedGroup('u')!));
      if (money == null) continue;
      if (m.namedGroup('k') != null) money = Money(money.minor * 1000, money.currency);
      final before = [...used];
      _use(m.start, m.end);
      amountSpan = [
        for (var j = 0; j < used.length; j++)
          if (used[j] && !before[j]) j,
      ];
      amount = money;
      return;
    }
  }

  String _currencyFor(String unit) {
    final u = unit.toLowerCase();
    if (currencySymbols.containsKey(u)) return currencySymbols[u] ?? _dollar;
    if (currencyWords.containsKey(u)) {
      return switch (currencyWords[u]) {
        null => _dollar,
        'peso' => pesoCurrencies.contains(ctx.currency) ? ctx.currency : 'PHP',
        final c => c,
      };
    }
    return u.toUpperCase();
  }

  /// "$" means the default currency when it is a dollar, else USD (PRS-37).
  String get _dollar => dollarCurrencies.contains(ctx.currency) ? ctx.currency : 'USD';

  void _prefixes() {
    // PRS-32: "work:" / "personal:"
    final p = RegExp(r'^(work|personal):\s*').firstMatch(lower);
    if (p != null) {
      contextOverride = p.group(1) == 'work' ? ReminderContext.work : ReminderContext.personal;
      _use(p.start, p.end, absorb: false);
    }
    // PRS-33 fillers
    final f = RegExp(r"^(?:(?:work|personal):\s*)?(?:please )?(remind me to|don'?t forget to|remember to)\s+")
        .firstMatch(lower);
    if (f != null) _use(f.start, f.end, absorb: false);
  }

  void _alerts() {
    const units = r'(minutes?|mins?|hours?|hrs?|days?|weeks?|months?)';
    for (final m in _take(
      RegExp('\\bremind me (\\d+|a|an|one|two|three|four|five|six) $units (?:before|earlier)\\b'),
    )) {
      final unit = m.group(2)!;
      var amount = _num(m.group(1)!);
      String u;
      if (unit.startsWith('min')) {
        u = 'm';
      } else if (unit.startsWith('h')) {
        u = 'h';
      } else if (unit.startsWith('week')) {
        u = 'd';
        amount *= 7;
      } else if (unit.startsWith('month')) {
        u = 'mo';
      } else {
        u = 'd';
      }
      alertBefore = (amount: amount, unit: u); // PRS-24
    }
    if (_take(RegExp(r'\bremind me the night before\b')).isNotEmpty) nightBefore = true; // PRS-25
    if (_take(RegExp(r'\bremind me the day before\b')).isNotEmpty) dayBefore = true;
    if (_take(RegExp(r'\b(?:nag me|until done)\b')).isNotEmpty) untilDoneNag = true; // PRS-27
    if (_take(RegExp(r'\bno (?:alerts?|reminders?)\b')).isNotEmpty) noAlert = true; // PRS-28
    // PRS-26: "start Wednesday"
    final s = _take(RegExp('\\bstart (?:on )?($weekdayPattern)\\b'));
    if (s.isNotEmpty) startByWeekday = weekdayNames[s.first.group(1)!];
  }

  void _recurrence() {
    // PRS-21: repeat after completion
    final ac = _take(
      RegExp(
        r'\b(?:every )?(\d+|a|an|other) (day|week|month|year)s? '
        r'(?:after (?:done|completion|(?:the )?last one|i last did it)|since (?:the )?last time)\b',
      ),
    );
    if (ac.isNotEmpty) {
      final m = ac.first;
      rec = _Recurrence()
        ..freq = _freq(m.group(2)!)
        ..interval = m.group(1) == 'other' ? 2 : _num(m.group(1)!)
        ..afterCompletion = true;
      return;
    }

    if (_take(RegExp(r'\blast business day of (?:the |each |every )?month\b')).isNotEmpty) {
      rec = _Recurrence()
        ..freq = 'MONTHLY'
        ..byDay = [1, 2, 3, 4, 5]
        ..bySetPos = -1
        ..lastBusinessDay = true; // REC-5
    }

    final dayList = '(?:$weekdayPattern)(?:\\s*(?:,|and|&)\\s*(?:$weekdayPattern))*';
    final everyDays = _take(RegExp('\\bevery (other )?($dayList)\\b'));
    if (everyDays.isNotEmpty) {
      final m = everyDays.first;
      rec ??= _Recurrence();
      rec!
        ..freq = 'WEEKLY'
        ..interval = m.group(1) != null ? 2 : 1
        ..byDay = (RegExp(
          weekdayPattern,
        ).allMatches(m.group(2)!).map((d) => weekdayNames[d.group(0)!]!).toSet().toList()..sort());
    }

    if (_take(RegExp(r'\bevery weekday\b')).isNotEmpty) {
      rec = _Recurrence()
        ..freq = 'WEEKLY'
        ..byDay = [1, 2, 3, 4, 5];
    }

    // PRS-42 "mondays and thursdays", "on fridays" → weekly on those days
    const fullDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final plural = '(?:${fullDays.join('|')})s';
    final plurals = _take(RegExp('\\b(?:on )?($plural(?:\\s*(?:,|and|&)\\s*$plural)*)\\b'));
    if (plurals.isNotEmpty && rec == null) {
      rec = _Recurrence()
        ..freq = 'WEEKLY'
        ..byDay = (RegExp(
          fullDays.join('|'),
        ).allMatches(plurals.first.group(1)!).map((d) => fullDays.indexOf(d.group(0)!) + 1).toSet().toList()..sort());
    }

    // PRS-42 "biweekly" / "fortnightly" = every 2 weeks; "twice a year" = every 6 months
    if (_take(RegExp(r'\b(?:bi-?weekly|fortnightly|every fortnight)\b')).isNotEmpty) {
      rec ??= (_Recurrence()
        ..freq = 'WEEKLY'
        ..interval = 2);
    }
    if (_take(RegExp(r'\b(?:twice a year|semi-?annually|bi-?annually)\b')).isNotEmpty) {
      rec ??= (_Recurrence()
        ..freq = 'MONTHLY'
        ..interval = 6);
    }

    final everyN = _take(RegExp(r'\bevery (\d+|other|two|three|four|five|six) (day|week|month|year)s?\b'));
    if (everyN.isNotEmpty) {
      final m = everyN.first;
      rec = _Recurrence()
        ..freq = _freq(m.group(2)!)
        ..interval = m.group(1) == 'other' ? 2 : _num(m.group(1)!);
    }

    final every = _take(RegExp(r'\bevery (day|week|month|year)\b'));
    if (every.isNotEmpty) rec ??= _Recurrence()..freq = _freq(every.first.group(1)!);

    final word = _take(RegExp(r'\b(daily|weekly|monthly|yearly|annually|quarterly)\b'));
    if (word.isNotEmpty) {
      final w = word.first.group(1)!;
      rec ??= _Recurrence();
      switch (w) {
        case 'daily':
          rec!.freq = 'DAILY';
        case 'weekly':
          rec!.freq = 'WEEKLY';
        case 'monthly':
          rec!.freq = 'MONTHLY';
        case 'quarterly':
          rec!
            ..freq = 'MONTHLY'
            ..interval = 3;
        default:
          rec!.freq = 'YEARLY';
      }
    }

    if (rec == null) return;
    // PRS-20
    final until = _take(RegExp('\\buntil ($monthPattern)\\.? (\\d{1,2})(?:st|nd|rd|th)?(?:,? (\\d{4}))?\\b'));
    if (until.isNotEmpty) {
      final m = until.first;
      rec!.until = _monthDay(monthNames[m.group(1)!]!, int.parse(m.group(2)!), m.group(3)).day;
    }
    final count = _take(RegExp(r'\bfor (\d+) (?:weeks|times|days|months|years)\b'));
    if (count.isNotEmpty) rec!.count = int.parse(count.first.group(1)!);
  }

  static String _freq(String unit) => switch (unit) {
    'day' => 'DAILY',
    'week' => 'WEEKLY',
    'month' => 'MONTHLY',
    _ => 'YEARLY',
  };

  void _relativeTime() {
    // PRS-12: "in 30 minutes", "in 2 hours" (number + unit without "in" is not a time)
    // PRS-42: also "in 1.5 hours", "in an hour and a half"
    final m = _take(
      RegExp(r'\bin (\d+(?:\.\d+)?|a|an|one|two|three|half an?) (minutes?|mins?|hours?|hrs?)( and a half)?\b'),
      absorb: false,
    );
    if (m.isEmpty) return;
    final g = m.first.group(1)!;
    final n = g.startsWith('half') ? 0.5 : (double.tryParse(g) ?? _num(g).toDouble());
    final u = m.first.group(2)!;
    final extra = m.first.group(3) != null ? 0.5 : 0.0;
    relative = u.startsWith('m') ? Duration(minutes: n.round()) : Duration(minutes: ((n + extra) * 60).round());
  }

  /// CAP-5: bare hours 1–6 → PM, 7–11 → AM, 12 → noon.
  static int _bareHour(int h) => (h >= 1 && h <= 6) ? h + 12 : h;

  static int _to24(int h, String meridiem) {
    if (meridiem.startsWith('a')) return h == 12 ? 0 : h;
    return h == 12 ? 12 : h + 12;
  }

  void _ranges() {
    // PRS-13
    final r = _take(
      RegExp(
        r'\b(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm)?(?:\s*[-–]\s*|\s+(?:to|until|till|through)\s+)'
        r'(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm)\b',
      ),
    );
    if (r.isNotEmpty) {
      final m = r.first;
      final em = m.group(6)!;
      final eh = _to24(int.parse(m.group(4)!), em);
      final emin = int.tryParse(m.group(5) ?? '') ?? 0;
      final sh0 = int.parse(m.group(1)!);
      final smin = int.tryParse(m.group(2) ?? '') ?? 0;
      int sh;
      if (m.group(3) != null) {
        sh = _to24(sh0, m.group(3)!);
      } else {
        sh = _to24(sh0, em);
        if (sh * 60 + smin > eh * 60 + emin) sh = _to24(sh0, em.startsWith('a') ? 'pm' : 'am');
      }
      time = _Time(sh * 60 + smin);
      endTime = _Time(eh * 60 + emin);
      _zoneAfter(m.end);
      return;
    }
    final f = _take(
      RegExp(r'\bfrom (\d{1,2})(?::(\d{2}))?\s*(am|pm)? to (\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b'),
      absorb: false,
    );
    if (f.isNotEmpty) {
      final m = f.first;
      int conv(String h, String? mer) => mer != null ? _to24(int.parse(h), mer) : _bareHour(int.parse(h));
      final ambiguous = m.group(3) == null || m.group(6) == null;
      time = _Time(conv(m.group(1)!, m.group(3)) * 60 + (int.tryParse(m.group(2) ?? '') ?? 0), ambiguous: ambiguous);
      endTime = _Time(conv(m.group(4)!, m.group(6)) * 60 + (int.tryParse(m.group(5) ?? '') ?? 0));
      if (ambiguous) flags.add(ParseFlag.ambiguousTime);
      _zoneAfter(m.end);
    }
  }

  void _times() {
    if (time == null) {
      // PRS-42 "half past 3", "quarter past 5pm", "quarter to 5", "10 past 9"
      final e = _take(
        RegExp(r'\b(half|quarter|5|10|20|25) (past|after|to|till) (\d{1,2})(?:\s?(am|pm|a\.m\.|p\.m\.))?(?![a-z\d:])'),
      );
      if (e.isNotEmpty) {
        final m = e.first;
        final mins = switch (m.group(1)!) {
          'half' => 30,
          'quarter' => 15,
          final d => int.parse(d),
        };
        final h0 = int.parse(m.group(3)!);
        final h = m.group(4) != null ? _to24(h0, m.group(4)!) : _bareHour(h0);
        final total = m.group(2) == 'to' || m.group(2) == 'till' ? h * 60 - mins : h * 60 + mins;
        time = _Time((total + 24 * 60) % (24 * 60), ambiguous: m.group(4) == null);
        if (m.group(4) == null) flags.add(ParseFlag.ambiguousTime);
      }
    }
    if (time == null) {
      // PRS-9 explicit am/pm
      final e = _take(RegExp(r'\b(\d{1,2})(?:[:.](\d{2}))?\s?(am|pm|a\.m\.|p\.m\.)(?![a-z])'));
      if (e.isNotEmpty) {
        final m = e.first;
        time = _Time(_to24(int.parse(m.group(1)!), m.group(3)!) * 60 + (int.tryParse(m.group(2) ?? '') ?? 0));
        _zoneAfter(m.end);
      }
    }
    if (time == null) {
      // PRS-42 "3 o'clock", "at 3 oclock" (CAP-5 for the half of the day)
      final e = _take(RegExp(r"\b(\d{1,2}) ?o'? ?clock\b"));
      if (e.isNotEmpty) {
        final h = int.parse(e.first.group(1)!);
        time = _Time(_bareHour(h) * 60, ambiguous: true);
        flags.add(ParseFlag.ambiguousTime);
      }
    }
    if (time == null) {
      // PRS-42 "9p" / "9a", "0930" (four digits with a leading zero, or after "at": "at 1430")
      final e = _take(RegExp(r'\b(\d{1,2})([ap])\b'));
      if (e.isNotEmpty) {
        time = _Time(_to24(int.parse(e.first.group(1)!), e.first.group(2)!) * 60);
      } else {
        final mil = _take(RegExp(r'\b(?:(0\d)|at ([01]\d|2[0-3]))([0-5]\d)\b(?!\s*(?:am|pm))'));
        if (mil.isNotEmpty) {
          final m = mil.first;
          time = _Time(int.parse(m.group(1) ?? m.group(2)!) * 60 + int.parse(m.group(3)!));
        }
      }
    }
    if (time == null) {
      // PRS-42 end of the working day: "eod", "by end of day", "cob", "close of business" → 17:00
      if (_take(RegExp(r'\b(?:eod|cob|end of (?:the )?(?:business )?day|close of business)\b')).isNotEmpty) {
        time = _Time(17 * 60);
      }
    }
    if (time == null) {
      // 24-hour or bare h:mm (PRS-10 for 1–12)
      final c = _take(RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b'));
      if (c.isNotEmpty) {
        final m = c.first;
        final h = int.parse(m.group(1)!);
        final amb = h >= 1 && h <= 12;
        time = _Time((amb ? _bareHour(h) : h) * 60 + int.parse(m.group(2)!), ambiguous: amb);
        if (amb) flags.add(ParseFlag.ambiguousTime);
        _zoneAfter(m.end);
      }
    }
    if (time == null) {
      final b = _take(RegExp(r'\bat (\d{1,2})\b(?!\s*(?:am|pm|[:.\-–]|\d))'), absorb: false);
      if (b.isNotEmpty) {
        final h = int.parse(b.first.group(1)!);
        time = _Time(_bareHour(h) * 60, ambiguous: true);
        flags.add(ParseFlag.ambiguousTime);
      }
    }
    if (time == null && _take(RegExp(r'\bnoon\b')).isNotEmpty) time = _Time(12 * 60);
    if (time == null && _take(RegExp(r'\bmidnight\b')).isNotEmpty) time = _Time(24 * 60);
    if (time == null && _take(RegExp(r'\b(?:tonight|tonite|2nite)\b'), absorb: false).isNotEmpty) {
      time = _Time(20 * 60);
      date ??= _DateSpec(_DateKind.today, day: today);
    }
    if (time == null) {
      // PRS-11 time words ("date night" is a title, not a time)
      for (final m in RegExp(r'\b(?:(this) )?(morning|afternoon|evening|night)\b').allMatches(lower)) {
        if (!_free(m.start, m.end)) continue;
        if (m.group(2) == 'night' && lower.substring(0, m.start).endsWith('date ')) continue;
        _use(m.start, m.end, absorb: false);
        time = _Time(switch (m.group(2)) {
          'morning' => ctx.dayTimeHour * 60 + ctx.dayTimeMinute,
          'afternoon' => 15 * 60,
          'evening' => 18 * 60,
          _ => 20 * 60,
        });
        if (m.group(1) == 'this') date ??= _DateSpec(_DateKind.today, day: today);
        break;
      }
    }
  }

  /// PRS-16/17: a zone written right after a time.
  void _zoneAfter(int pos) {
    final rest = lower.substring(pos);
    final abbr = RegExp('^\\s*(${zoneAbbreviations.keys.join('|')})\\b').firstMatch(rest);
    if (abbr != null) {
      zone = zoneAbbreviations[abbr.group(1)!];
      _use(pos, pos + abbr.end, absorb: false);
      return;
    }
    final city = RegExp('^\\s*(${cityZones.keys.join('|')})(?: time)?\\b').firstMatch(rest);
    if (city != null) {
      zone = cityZones[city.group(1)!];
      _use(pos, pos + city.end, absorb: false);
    }
  }

  void _setDate(_DateSpec d) => date ??= d;

  void _dates() {
    for (final _ in _take(RegExp(r'\bday after tomorrow\b'))) {
      _setDate(_DateSpec(_DateKind.relative, day: today.add(const Duration(days: 2))));
    }
    // PRS-42 "a week from today / tomorrow / Friday" → that day + 7
    for (final m in _take(RegExp('\\b(a|one|two|\\d+) weeks? from (today|tomorrow|now|$weekdayPattern)\\b'))) {
      final base = switch (m.group(2)!) {
        'today' || 'now' => today,
        'tomorrow' => today.add(const Duration(days: 1)),
        final w => _nextWeekday(weekdayNames[w]!, includeToday: false),
      };
      _setDate(_DateSpec(_DateKind.relative, day: base.add(Duration(days: 7 * _num(m.group(1)!)))));
    }
    // PRS-42 "in a fortnight" = in 2 weeks
    for (final _ in _take(RegExp(r'\bin a fortnight\b'), absorb: false)) {
      _setDate(_DateSpec(_DateKind.relative, day: today.add(const Duration(days: 14))));
    }
    // PRS-42 "next month" / "next year" → its first day, flagged so the user can check
    for (final m in _take(RegExp(r'(?<!of (?:the )?)\bnext (month|year)\b'))) {
      flags.add(ParseFlag.ambiguousDate);
      final d = m.group(1) == 'month'
          ? _addMonths(DateTime.utc(today.year, today.month), 1)
          : DateTime.utc(today.year + 1, 1, 1);
      _setDate(_DateSpec(_DateKind.relative, day: d));
    }
    // PRS-42 common spellings: tmrw, tmr, tmw, 2moro, 2morrow, tomorow, tomoz
    for (final _ in _take(RegExp(r'\b(?:tomorrow|tmrw|tmr|tmw|2moro|2morrow|tomorow|tommorow|tomoz)\b'))) {
      _setDate(_DateSpec(_DateKind.relative, day: today.add(const Duration(days: 1))));
    }
    for (final _ in _take(RegExp(r'\btoday\b'))) {
      _setDate(_DateSpec(_DateKind.today, day: today));
    }
    for (final m in _take(
      RegExp(r'\bin (\d+|a|an|one|two|three|four|five|six) (days?|weeks?|months?|years?)\b'),
      absorb: false,
    )) {
      final n = _num(m.group(1)!);
      final u = m.group(2)!;
      final d = u.startsWith('day')
          ? today.add(Duration(days: n))
          : u.startsWith('week')
          ? today.add(Duration(days: 7 * n))
          : u.startsWith('month')
          ? _addMonths(today, n)
          : _addMonths(today, 12 * n);
      _setDate(_DateSpec(_DateKind.relative, day: d));
    }
    // PRS-6
    // PRS-42 also "eow" / "eom"
    for (final m in _take(RegExp(r'\b(?:end of (?:the )?(week|month)|(eow|eom))\b'))) {
      final week = m.group(1) == 'week' || m.group(2) == 'eow';
      final d = week ? _nextWeekday(5, includeToday: true) : _lastOfMonth(today);
      _setDate(_DateSpec(_DateKind.relative, day: d));
    }
    for (final _ in _take(RegExp(r'\b(?:this )?weekend\b'))) {
      _setDate(_DateSpec(_DateKind.relative, day: _nextWeekday(6, includeToday: true)));
    }
    for (final _ in _take(RegExp(r'\bnext week\b'))) {
      _setDate(_DateSpec(_DateKind.relative, day: _startOfNextWeek().add(Duration(days: _isUS ? 1 : 0))));
    }
    // PRS-1 ISO
    for (final m in _take(RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b'))) {
      _setDate(
        _DateSpec(
          _DateKind.absolute,
          day: DateTime.utc(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!)),
          yearGiven: true,
        ),
      );
    }
    // PRS-41 year first with slashes or dots: 2026/10/15
    for (final m in _take(RegExp(r'\b(\d{4})[/.](\d{1,2})[/.](\d{1,2})\b'))) {
      final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
      if (mo < 1 || mo > 12 || d < 1 || d > 31) continue;
      _setDate(_DateSpec(_DateKind.absolute, day: _clampDay(y, mo, d), yearGiven: true));
    }
    // PRS-41 "last day of October / of the month / of next month"
    for (final m in _take(RegExp('\\blast day of (?:the )?(this month|next month|month|$monthPattern)\\b'))) {
      final what = m.group(1)!;
      if (what == 'next month') {
        _setDate(
          _DateSpec(_DateKind.relative, day: _lastOfMonth(_addMonths(DateTime.utc(today.year, today.month), 1))),
        );
      } else if (what.endsWith('month')) {
        _setDate(_DateSpec(_DateKind.relative, day: _lastOfMonth(today)));
      } else {
        final mo = monthNames[what]!;
        _setDate(_monthDay(mo, DateTime.utc(today.year, mo + 1, 0).day, null));
      }
    }
    // PRS-41 "15th of this month / of next month"
    for (final m in _take(RegExp('\\b(?:the )?($_dayToken)(?: day)? of (this|next) month\\b'))) {
      final n = _dayNum(m.group(1)!);
      if (n == null) continue;
      final base = m.group(2) == 'next' ? _addMonths(DateTime.utc(today.year, today.month), 1) : today;
      _setDate(_DateSpec(_DateKind.relative, day: _clampDay(base.year, base.month, n)));
    }
    // PRS-41 "15th day of Oct", "the 15th of October", "the fifteenth of October", "day 15 of October"
    for (final m in _take(
      RegExp('\\b(?:the |day )?($_dayToken)(?: day)? of (?:the month of )?($monthPattern)\\b(?:,? (\\d{4})\\b)?'),
    )) {
      final n = _dayNum(m.group(1)!);
      if (n == null) continue;
      _setDate(_monthDay(monthNames[m.group(2)!]!, n, m.group(3)));
    }
    // month + day (+ year): "Oct 15", "Oct. 15th", "Oct the 15th", "October fifteenth", "Oct-15", "Oct 15 2027"
    for (final m in _take(RegExp('\\b($monthPattern)(?:\\.? the |\\.? |-)($_dayToken)\\b(?:,? (\\d{4})\\b)?'))) {
      final n = _dayNum(m.group(2)!);
      if (n == null) continue;
      _setDate(_monthDay(monthNames[m.group(1)!]!, n, m.group(3)));
    }
    // day + month (+ year): "15 Oct", "15th October", "15-Oct", "15. October", "fifteenth of" is above
    for (final m in _take(RegExp('\\b($_dayToken)(?:\\.? |-)($monthPattern)\\b(?:,? (\\d{4})\\b)?'))) {
      final n = _dayNum(m.group(1)!);
      if (n == null) continue;
      _setDate(_monthDay(monthNames[m.group(2)!]!, n, m.group(3)));
    }
    // PRS-3 month + year
    for (final m in _take(RegExp('\\b($monthPattern) (\\d{4})\\b'))) {
      flags.add(ParseFlag.ambiguousDate);
      _setDate(
        _DateSpec(
          _DateKind.monthYear,
          day: DateTime.utc(int.parse(m.group(2)!), monthNames[m.group(1)!]!, 1),
          yearGiven: true,
        ),
      );
    }
    // numeric m/d or d/m by locale
    for (final m in _take(RegExp(r'\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b'))) {
      final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
      var month = _isUS ? a : b, day = _isUS ? b : a;
      // PRS-42: "15/10" in en-US can only be day/month (and "10/15" in en-GB month/day) — read it that way.
      if (month > 12 && day <= 12) (month, day) = (day, month);
      if (month < 1 || month > 12 || day < 1 || day > 31) continue;
      var y = m.group(3);
      if (y != null && y.length == 2) y = '20$y';
      _setDate(_monthDay(month, day, y));
    }
    // PRS-8 "the 15th", "on 15th", "by 3rd", "due 1st"; a bare "15th" only as the last thing typed
    final nth = _take(RegExp(r'\b(?:the|on|by|due) (\d{1,2})(?:st|nd|rd|th)\b'));
    // …or when everything after it is already understood ("dentist 15th", "dentist 15th at 3pm")
    for (final m in RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)\b').allMatches(lower)) {
      final rest = [for (var i = m.end; i < lower.length; i++) used[i] || !RegExp(r'[a-z0-9]').hasMatch(lower[i])];
      if (_free(m.start, m.end) && rest.every((ok) => ok)) {
        _use(m.start, m.end);
        nth.add(m);
      }
    }
    for (final m in nth) {
      final n = int.parse(m.group(1)!);
      if (n < 1 || n > 31) continue;
      var d = _clampDay(today.year, today.month, n);
      if (d.isBefore(today)) {
        final nm = _addMonths(DateTime.utc(today.year, today.month, 1), 1);
        d = _clampDay(nm.year, nm.month, n);
      }
      _setDate(_DateSpec(_DateKind.nth, day: d, nth: n));
    }
    // PRS-7 weekdays
    // "this coming Friday" / "coming Friday" = "Friday" (PRS-42)
    for (final m in _take(RegExp('\\b(?:(this|next|(?:this )?coming) )?($weekdayPattern)\\b'))) {
      _setDate(_DateSpec(_DateKind.weekday, weekday: weekdayNames[m.group(2)!]!, next: m.group(1) == 'next'));
    }
  }

  bool get _isUS => ctx.locale.toLowerCase() == 'en-us';

  /// PRS-41: a day of the month as typed — "15", "15th" or "fifteenth".
  static final _dayToken = '\\d{1,2}(?:st|nd|rd|th)?|$ordinalPattern';

  static int? _dayNum(String s) {
    final n = int.tryParse(s.replaceAll(RegExp(r'(st|nd|rd|th)$'), '')) ?? ordinalWords[s];
    return n == null || n < 1 || n > 31 ? null : n;
  }

  _DateSpec _monthDay(int month, int day, String? year) {
    if (year != null) {
      return _DateSpec(_DateKind.absolute, day: _clampDay(int.parse(year), month, day), yearGiven: true);
    }
    var d = _clampDay(today.year, month, day); // REC-4: Feb 29 → Feb 28 in non-leap years
    var rolled = false;
    if (d.isBefore(today)) {
      d = _clampDay(today.year + 1, month, day); // PRS-2
      rolled = true;
    }
    final spec = _DateSpec(_DateKind.absolute, day: d);
    if (rolled) _rolled = true;
    if (d.day != day) _clamped ??= (month: month, day: day);
    return spec;
  }

  bool _rolled = false;

  /// Month/day the user wrote when it had to be clamped (e.g. Feb 29 in a non-leap year).
  ({int month, int day})? _clamped;

  // ---- title, kind ----

  String _title() {
    final b = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      b.write(used[i] ? ' ' : text[i]);
    }
    var t = b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll(RegExp(r'^[,;:\-–·\s]+|[,;:\-–·\s]+$'), '');
    t = t.replaceAll(RegExp(r'\s+(at|on|by|for|due|from|in|until)$', caseSensitive: false), '').trim();
    if (t.isEmpty) return '';
    return t[0].toUpperCase() + t.substring(1);
  }

  static bool _hasAny(String s, List<String> words) =>
      words.any((w) => RegExp('(?<![a-z0-9])${RegExp.escape(w)}(?![a-z0-9])').hasMatch(s));

  (Kind, BillKind) _kind(String title) {
    const pay = BillKind.payment;
    if (rec?.afterCompletion ?? false) return (Kind.task, pay); // REC-10
    final t = title.toLowerCase();
    if (RegExp(r'\b(birthday|bday|anniversary)\b(?!\s+(party|dinner|drinks)\b)').hasMatch(t)) {
      return (Kind.occasion, pay);
    }
    // PRS-39: holidays are occasions, unless it's the party/dinner/shopping for one or a task about it.
    if (_hasAny(t, holidayWords) &&
        !RegExp(r'\b(party|dinner|drinks|lunch|brunch|shopping|gifts?|presents|market|concert|show|sale)\b')
            .hasMatch(t) &&
        !taskVerbs.any((v) => t == v || t.startsWith('$v '))) {
      return (Kind.occasion, pay);
    }
    if (_hasAny(t, meetingPhrases)) return (Kind.meeting, pay);
    // PRS-29 (3) bills: trial and subscription words win over verbs; payment words don't.
    if (_hasAny(t, trialWords)) return (Kind.bill, BillKind.trial);
    if (_hasAny(t, subscriptionWords)) return (Kind.bill, BillKind.subscription);
    String? verb;
    for (final v in taskVerbs) {
      if (t == v || t.startsWith('$v ')) {
        verb = v;
        break;
      }
    }
    if (verb == 'pay') return (Kind.bill, pay);
    if (verb == null && (amount != null || _hasAny(t, paymentWords))) return (Kind.bill, pay);
    if (verb != null) return (Kind.task, pay);
    if (_hasAny(t, eventWords)) return (Kind.event, pay);
    return (Kind.task, pay);
  }

  // ---- timing ----

  ParsedTiming? _timing(Kind kind) {
    final zoneName = zone ?? ctx.defaultTimeZone;
    final tzOut = (zone != null && zone != ctx.defaultTimeZone) ? zone : null;

    if (relative != null) {
      final start = DateTime.utc(ctx.now.year, ctx.now.month, ctx.now.day, ctx.now.hour, ctx.now.minute).add(relative!);
      return ParsedTiming(type: TimingType.datetime, start: _ymdhm(start), end: _defaultEnd(kind, start), tz: tzOut);
    }

    DateTime? day = _resolveDay();
    if (day == null) {
      if (time != null) {
        // CAP-3: time only → today if still ahead, else tomorrow
        day = (time!.minutes > nowMinutes) ? today : today.add(const Duration(days: 1));
      } else if (kind == Kind.occasion) {
        flags.add(ParseFlag.dateMissing); // PRS-36
        return null;
      } else {
        day = today.add(const Duration(days: 1)); // CAP-1
      }
    }

    if (_rolled && rec == null) flags.add(ParseFlag.pastDateRolled);

    if (time == null) {
      return ParsedTiming(type: TimingType.date, start: _ymd(day), tz: null);
    }

    if (date?.kind == _DateKind.today && time!.minutes <= nowMinutes && rec == null) {
      flags.add(ParseFlag.timeInPast); // PRS-15
    }

    var start = day.add(Duration(minutes: time!.minutes));
    start = normalizeWall(start, zoneName); // TIM-13/14
    DateTime? end;
    if (endTime != null) {
      end = day.add(Duration(minutes: endTime!.minutes));
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    }
    final endStr = end != null ? _ymdhm(end) : _defaultEnd(kind, start);
    return ParsedTiming(type: TimingType.datetime, start: _ymdhm(start), end: endStr, tz: tzOut);
  }

  /// TIM-11 default end: Meeting +30 min, Event +1 h, Task none.
  static String? _defaultEnd(Kind kind, DateTime start) => switch (kind) {
    Kind.meeting => _ymdhm(start.add(const Duration(minutes: 30))),
    Kind.event => _ymdhm(start.add(const Duration(hours: 1))),
    _ => null,
  };

  DateTime? _resolveDay() {
    final d = date;
    if (d == null) {
      if (rec != null && rec!.lastBusinessDay) return _lastBusinessDay();
      if (rec != null && rec!.byDay.isNotEmpty) return _firstOfDays(rec!.byDay);
      return null;
    }
    switch (d.kind) {
      case _DateKind.weekday:
        return _resolveWeekday(d.weekday!, d.next);
      default:
        return d.day;
    }
  }

  /// CAP-4 / PRS-7.
  DateTime _resolveWeekday(int w, bool next) {
    if (next) {
      flags.add(ParseFlag.ambiguousDate);
      final start = _startOfNextWeek();
      final offset = _isUS ? w % 7 : w - 1;
      return start.add(Duration(days: offset));
    }
    final diff = (w - today.weekday + 7) % 7;
    if (diff == 0) {
      if (time == null) {
        flags.add(ParseFlag.ambiguousDate);
        return today;
      }
      return time!.minutes > nowMinutes ? today : today.add(const Duration(days: 7));
    }
    return today.add(Duration(days: diff));
  }

  /// First upcoming day in [days] (today counts if the time is still ahead or there's no time).
  DateTime _firstOfDays(List<int> days) {
    for (var i = 0; i < 14; i++) {
      final d = today.add(Duration(days: i));
      if (!days.contains(d.weekday)) continue;
      if (i == 0 && time != null && time!.minutes <= nowMinutes) continue;
      return d;
    }
    return today;
  }

  /// Sunday (en-US) or Monday of next week.
  DateTime _startOfNextWeek() {
    if (_isUS) {
      final days = 7 - (today.weekday % 7);
      return today.add(Duration(days: days == 0 ? 7 : days));
    }
    return today.add(Duration(days: 8 - today.weekday));
  }

  DateTime _nextWeekday(int w, {required bool includeToday}) {
    var diff = (w - today.weekday + 7) % 7;
    if (diff == 0 && !includeToday) diff = 7;
    return today.add(Duration(days: diff));
  }

  DateTime _lastBusinessDay() {
    DateTime lbd(DateTime month) {
      var d = _lastOfMonth(month);
      while (d.weekday > 5) {
        d = d.subtract(const Duration(days: 1));
      }
      return d;
    }

    final thisMonth = lbd(today);
    return thisMonth.isBefore(today) ? lbd(_addMonths(DateTime.utc(today.year, today.month, 1), 1)) : thisMonth;
  }

  // ---- alerts ----

  List<String>? _alertList(Kind kind, ParsedTiming? timing) {
    if (noAlert) return [];
    final keepDayOf = kind == Kind.occasion;
    if (alertBefore != null) {
      return ['-${alertBefore!.amount}${alertBefore!.unit}', if (keepDayOf) '0'];
    }
    if (dayBefore) return ['-1d', if (keepDayOf) '0'];
    if (nightBefore && timing != null) {
      final anchor = _anchor(timing);
      final prev = DateTime.utc(anchor.year, anchor.month, anchor.day).subtract(const Duration(days: 1));
      final at = prev.add(const Duration(hours: 20));
      final mins = anchor.difference(at).inMinutes;
      return [mins % 60 == 0 ? '-${mins ~/ 60}h' : '-${mins}m', if (keepDayOf) '0'];
    }
    if (startByWeekday != null && timing != null) {
      final due = DateTime.parse('${timing.start.substring(0, 10)}T00:00:00Z');
      var diff = (due.weekday - startByWeekday! + 7) % 7;
      if (diff == 0) diff = 7;
      return ['-${diff}d', '0']; // ALR-5 "Start by"
    }
    return null;
  }

  DateTime _anchor(ParsedTiming t) => t.type == TimingType.datetime
      ? DateTime.parse('${t.start}:00Z')
      : DateTime.parse('${t.start}T00:00:00Z').add(Duration(hours: ctx.dayTimeHour, minutes: ctx.dayTimeMinute));
}

// ---------------------------------------------------------------------------
// Calendar helpers (UTC DateTimes used as wall-clock containers)

DateTime _clampDay(int year, int month, int day) {
  final last = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, day > last ? last : day);
}

DateTime _addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final y = d.year + total ~/ 12;
  final m = total % 12 + 1;
  return _clampDay(y, m, d.day);
}

DateTime _lastOfMonth(DateTime d) => DateTime.utc(d.year, d.month + 1, 0);

String _two(int n) => n.toString().padLeft(2, '0');
String _ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _ymdhm(DateTime d) => '${_ymd(d)}T${_two(d.hour)}:${_two(d.minute)}';
