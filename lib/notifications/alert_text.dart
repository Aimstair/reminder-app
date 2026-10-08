/// Notification wording (NTF-1, copy.md §2) for the planner. Works without a BuildContext so the
/// background top-up job can use it.
library;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:reminder_core/reminder_core.dart';

import '../l10n/gen/app_localizations.dart';
import '../ui/money_format.dart';

class NotificationTextBuilder {
  NotificationTextBuilder({required this.l10n, required this.prefs, String? locale})
    : _locale = locale ?? l10n.localeName;

  /// Loads date-format data for [locale]; call once before use (UI and background jobs).
  static Future<void> init(String locale) => initializeDateFormatting(locale);

  final AppLocalizations l10n;
  final UserPrefs prefs;
  final String _locale;

  ({String title, String body}) call(AlertContext c) {
    final r = c.reminder;
    final zone = r.timing.type == TimingType.date ? prefs.deviceTimeZone : (r.timing.timeZone ?? prefs.defaultTimeZone);
    final isDate = r.timing.type == TimingType.date;
    final anchorWall = instantToWall(c.times.anchor, zone);
    final fireWall = instantToWall(c.fireAt, zone);
    final dayDiff = dateOnly(anchorWall).difference(dateOnly(fireWall)).inDays;

    String time(DateTime w) => DateFormat.jm(_locale).format(w);
    String date(DateTime w) => DateFormat('EEE, MMM d', _locale).format(w);
    String when(DateTime w) {
      final d = dateOnly(w).difference(dateOnly(fireWall)).inDays;
      final day = d == 0 ? l10n.dayToday : (d == 1 ? l10n.dayTomorrow : date(w));
      return isDate ? day : (d == 0 ? time(w) : '$day ${time(w)}');
    }

    final String body;
    if (c.alertKind == AlertKind.nag) {
      body = dayDiff >= 0 ? l10n.notifNagToday : l10n.notifNagSince(date(anchorWall)); // notif.nag
    } else if (r.kind == Kind.bill && c.stage?.label == null) {
      body = _billBody(r, when(anchorWall)); // BIL-4
    } else if (c.stage?.label != null) {
      body = l10n.notifStartBy(isDate ? date(anchorWall) : '${date(anchorWall)} ${time(anchorWall)}'); // ALR-5
    } else {
      final lead = c.times.anchor.difference(c.fireAt);
      if (lead.inMinutes <= 1) {
        body = isDate ? l10n.notifToday : l10n.notifNow(time(anchorWall));
      } else {
        body = l10n.notifBefore(_relative(lead, dayDiff, isDate), when(anchorWall));
      }
    }
    return (title: r.title, body: body);
  }

  /// BIL-4: "$1,200.00 · due tomorrow", "Renews Fri, Oct 9 · $11.99", "Trial ends today · then $15.49".
  String _billBody(Reminder r, String when) {
    // "Today" / "Tomorrow" sit mid-sentence here.
    for (final w in [l10n.dayToday, l10n.dayTomorrow]) {
      if (when.startsWith(w)) when = w.toLowerCase() + when.substring(w.length);
    }
    final amount = r.amount == null ? null : formatMoney(r.amount!, _locale);
    return switch (r.billKind) {
      BillKind.payment => amount == null ? l10n.notifBillDueNoAmount(when) : l10n.notifBillDue(amount, when),
      BillKind.subscription => amount == null ? l10n.notifRenewsNoAmount(when) : l10n.notifRenews(when, amount),
      BillKind.trial => amount == null ? l10n.notifTrialEndsNoAmount(when) : l10n.notifTrialEnds(when, amount),
    };
  }

  /// "10 min", "2 hours", "1 day", "1 week", "6 months".
  String _relative(Duration lead, int dayDiff, bool isDate) {
    if (!isDate && lead.inMinutes < 60) return l10n.relMinutes(lead.inMinutes);
    if (!isDate && lead.inHours < 24 && dayDiff == 0) return l10n.relHours(lead.inHours);
    if (dayDiff >= 28 && dayDiff % 30 <= 3) return l10n.relMonths((dayDiff / 30).round());
    if (dayDiff >= 7 && dayDiff % 7 == 0) return l10n.relWeeks(dayDiff ~/ 7);
    return l10n.relDays(dayDiff == 0 ? 1 : dayDiff);
  }
}
