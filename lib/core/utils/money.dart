import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Currency formatting in one place.
///
/// Prices are stored as minor units in an int and only ever become a decimal
/// at the moment of display. IQD is the awkward case: it has no minor unit in
/// practice, so "minor" is just whole dinars and formatting must not append
/// two decimal places to a 25,000 IQD price.
abstract final class Money {
  static const _decimalPlaces = <String, int>{
    'IQD': 0, // dinars are quoted whole
    'USD': 2,
    'EUR': 2,
  };

  static int decimalsFor(String currency) => _decimalPlaces[currency] ?? 2;

  /// [locale] is a BCP-47 language tag, e.g. `ar`, and decides digit shapes and
  /// grouping separators as much as it decides where the symbol sits.
  ///
  /// It defaults to English rather than the ambient locale because this class
  /// has no BuildContext. That default is why every price rendered with Western
  /// digits in Arabic and Kurdish: no call site passed one. Prefer
  /// `context.money(...)` below, which cannot forget.
  static String format(
    int minor,
    String currency, {
    String? locale,
  }) {
    final decimals = decimalsFor(currency);
    final value = minor / _pow10(decimals);

    final formatter = NumberFormat.currency(
      locale: locale ?? 'en',
      symbol: currency == 'IQD' ? '' : null,
      decimalDigits: decimals,
      name: currency,
    );

    final formatted = formatter.format(value).trim();
    // IQD reads naturally as a suffix, unlike $ or €.
    return currency == 'IQD' ? '$formatted IQD' : formatted;
  }

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}

/// Formats money in the locale the person is actually reading.
///
/// The bare [Money.format] takes an optional locale and silently defaults to
/// English when it is omitted — and it was omitted at all twenty-six call
/// sites, which is exactly the kind of default that looks harmless and
/// localizes nothing. This has no way to forget, because the context is the
/// receiver.
extension MoneyX on BuildContext {
  String money(int minor, String currency) => Money.format(
        minor,
        currency,
        locale: Localizations.localeOf(this).toLanguageTag(),
      );
}
