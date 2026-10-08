/// An amount of money in a currency's minor units (BIL-2): `Money(120000, 'USD')` = $1,200.00.
library;

class Money {
  const Money(this.minor, this.currency);

  final int minor;

  /// ISO 4217 code, upper case.
  final String currency;

  /// Digits after the decimal point for [currency] (most have 2).
  static int decimalsOf(String currency) => _zeroDecimal.contains(currency) ? 0 : 2;
  static const _zeroDecimal = {'JPY', 'KRW', 'VND', 'CLP', 'ISK', 'UGX', 'PYG', 'XAF', 'XOF', 'IDR'};

  int get decimals => decimalsOf(currency);

  /// The amount as a decimal number (for display and sums).
  double get value => minor / _pow10(decimals);

  /// From a typed number ("1,200", "15.49", "15,49" with [decimalComma]); null if it isn't one.
  static Money? parse(String number, String currency, {bool decimalComma = false}) {
    var t = number.trim().replaceAll(' ', '');
    if (decimalComma) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
    final v = double.tryParse(t);
    if (v == null || v < 0 || v > 1e12) return null;
    final c = currency.toUpperCase();
    return Money((v * _pow10(decimalsOf(c))).round(), c);
  }

  Map<String, Object?> toJson() => {'minor': minor, 'currency': currency};

  static Money? fromJson(Object? j) {
    if (j is! Map) return null;
    final m = j['minor'], c = j['currency'];
    return m is num && c is String ? Money(m.toInt(), c) : null;
  }

  /// "USD 1200.00" — stable, for tests and storage; screens use the app's currency formatter.
  @override
  String toString() => '$currency ${value.toStringAsFixed(decimals)}';

  @override
  bool operator ==(Object other) => other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  static int _pow10(int n) => n == 0 ? 1 : 100;
}

/// Sum per currency (BIL-6), largest total first.
List<Money> sumByCurrency(Iterable<Money> amounts) {
  final totals = <String, int>{};
  for (final m in amounts) {
    totals[m.currency] = (totals[m.currency] ?? 0) + m.minor;
  }
  final out = [for (final e in totals.entries) Money(e.value, e.key)];
  out.sort((a, b) => b.value.compareTo(a.value));
  return out;
}
