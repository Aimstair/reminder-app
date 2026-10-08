/// Money display (BIL-2) without a BuildContext, so notifications and the widget can use it too.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:intl/intl.dart';
import 'package:reminder_core/reminder_core.dart';

/// "$1,200.00", "€450.00", "¥500" in the user's number style.
String formatMoney(Money m, String locale) {
  try {
    return NumberFormat.simpleCurrency(locale: locale, name: m.currency, decimalDigits: m.decimals).format(m.value);
  } catch (_) {
    return m.toString();
  }
}

/// BIL-2 default currency: the phone's region (en_PH → PHP), USD when unknown. Uses the device
/// locale, not the app's (the app is English-only, so its locale has no region).
String deviceCurrency() {
  try {
    final l = PlatformDispatcher.instance.locale;
    final tag = l.countryCode == null ? l.languageCode : '${l.languageCode}_${l.countryCode}';
    return NumberFormat.simpleCurrency(locale: tag).currencyName ?? 'USD';
  } catch (_) {
    return 'USD';
  }
}

/// Currencies offered in the amount dialog: the default first, then common ones.
List<String> currencyChoices(String preferred) => [
  preferred,
  for (final c in const ['USD', 'EUR', 'GBP', 'PHP', 'JPY', 'CAD', 'AUD', 'INR', 'SGD', 'MXN', 'CHF'])
    ?(c == preferred ? null : c),
];
