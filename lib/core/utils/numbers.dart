import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware number formatting for counts and percentages.
///
/// The companion to `context.money`. Prices go through `intl` and so render with
/// Arabic-Indic digits under `ar`; bare counts interpolated as `'$count'` do not,
/// because Dart's `toString` knows nothing about locales.
///
/// The result was mixed numeral systems inside a single row — an Arabic price
/// beside a Western quantity — which reads worse than either choice made
/// consistently. Every rendered number goes through here.
extension NumbersX on BuildContext {
  String _tag() => Localizations.localeOf(this).toLanguageTag();

  /// A whole number: quantities, counts, badge totals.
  String number(num value) => NumberFormat.decimalPattern(_tag()).format(value);

  /// A number with a fixed number of decimal places.
  ///
  /// `toStringAsFixed` writes a `.` separator whatever the locale, and Arabic
  /// uses `٫`. A rating shown as "4.5" beside prices written with `٫` looks like
  /// a different kind of value rather than the same kind formatted differently.
  String decimal(num value, {int decimals = 1}) =>
      NumberFormat.decimalPatternDigits(
        locale: _tag(),
        decimalDigits: decimals,
      ).format(value);

  /// An abbreviated count: 1200 becomes `1.2K` in English.
  ///
  /// The suffix is not language-neutral. `K` and `M` are English abbreviations,
  /// and `intl` carries the right short form for each locale — Arabic abbreviates
  /// thousands as `ألف`, not `K`. Hand-rolling this produced Latin suffixes
  /// beside Arabic-Indic digits.
  String compact(num value) =>
      NumberFormat.compact(locale: _tag()).format(value);

  /// A fraction rendered as a percentage.
  ///
  /// [decimals] exists because a share under 10% loses its meaning when rounded
  /// to a whole number — 0.4% and 4% are very different for a seller reading a
  /// conversion rate.
  String percent(double fraction, {int decimals = 0}) =>
      NumberFormat.decimalPercentPattern(
        locale: _tag(),
        decimalDigits: decimals,
      ).format(fraction);
}
