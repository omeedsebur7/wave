import 'package:flutter/widgets.dart';
import 'package:wave/l10n/generated/app_localizations.dart';

/// Shorthand for the generated localizations.
///
/// `context.l10n.buyNow` rather than `AppL10n.of(context).buyNow`. The shorter
/// form matters more than it looks: a lookup that is tedious to type is one
/// people skip, and every skipped lookup is a hardcoded English string that
/// will never be translated.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
