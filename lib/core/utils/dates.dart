import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Date formatting in one place, driven by the active locale.
///
/// Four screens each carried their own `_formatDate`, and all four produced
/// `dd/MM/yyyy` with Western digits regardless of language. A fifth built month
/// names from a hardcoded English array, so an Arabic reader saw "January 2026"
/// with the month in Latin script and the year beside it.
///
/// `intl` already ships the month names, digit shapes and field order for every
/// locale in the app. Deriving them from the locale means Arabic gets
/// Arabic-Indic digits and Arabic month names without a table to maintain — and
/// means adding a fourth language adds no date code at all.
abstract final class Dates {
  static String _tag(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// A full calendar date, e.g. `14/03/2026` in English.
  ///
  /// `yMd` rather than a literal pattern, because field order is not universal
  /// and hardcoding day-before-month is only correct by accident.
  static String short(BuildContext context, DateTime when) =>
      DateFormat.yMd(_tag(context)).format(when);

  /// Month and year, e.g. `March 2026`. Used for "selling since".
  static String monthYear(BuildContext context, DateTime when) =>
      DateFormat.yMMMM(_tag(context)).format(when);
}
