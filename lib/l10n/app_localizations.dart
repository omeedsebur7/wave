import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wave/l10n/generated/app_localizations.dart';

/// The one list of localization delegates the app and its tests both use.
///
/// ── WHY THIS FILE EXISTS ────────────────────────────────────────────────────
///
/// Flutter ships `GlobalMaterialLocalizations` for about 80 languages. Sorani
/// Kurdish (`ckb`) is not one of them. So an app that declares `Locale('ckb')`
/// in supportedLocales and hands the framework only the Global delegates gets:
///
///     This application's locale, ckb, is not supported by all of its
///     localization delegates.
///
/// which is a warning, not a crash — and that is the problem. The app keeps
/// running: WAVE's own ARB strings render in Kurdish, while every string owned
/// by Material and Cupertino silently falls back to English. "Cancel" on a
/// dialog, the date picker, the text-selection menu, the pull-to-refresh
/// semantics label, the back button's tooltip.
///
/// For a market where two of three launch locales are RTL, that means a Kurdish
/// buyer sees Kurdish body text next to an English "Cancel" — the kind of
/// half-translated screen that reads as an app not really meant for them.
///
/// The fix is to satisfy those delegates with Arabic. Not because Kurdish is
/// Arabic — it is not — but because for the strings Material owns, Arabic is
/// far closer than English on the two axes that matter here: it is RTL, and it
/// is a language this audience overwhelmingly reads. An imperfect Arabic
/// "Cancel" beats a perfect English one in an RTL layout.
///
/// This is a stopgap, and worth naming as one. The right long-term answer is
/// contributing `ckb` upstream to flutter_localizations, or shipping a
/// hand-written MaterialLocalizations for it. Until then this keeps the seams
/// from showing, and the test in test/widgets/order_tracker_test.dart holds it
/// honest by failing if the warning comes back.
abstract final class WaveLocalizations {
  /// Every delegate, in resolution order.
  ///
  /// The ckb fallbacks come first deliberately. Ordering is not strictly
  /// required — the Global delegates report `isSupported('ckb') == false`, so
  /// they decline and resolution falls through — but relying on another
  /// package's negative answer to reach your own delegate is a dependency on
  /// something nobody wrote down. Putting them first makes the intent explicit.
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    // Without this first entry the ARB files are dead weight and every screen
    // renders whatever was hardcoded into it.
    AppL10n.delegate,

    _CkbMaterialLocalizationsDelegate(),
    _CkbWidgetsLocalizationsDelegate(),
    _CkbCupertinoLocalizationsDelegate(),

    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Launch languages (§6).
  ///
  /// Arabic first, because it is the majority language of the target market and
  /// this is a marketplace: a buyer who cannot read the listing does not buy.
  /// Kurdish Sorani second, English last — English is the development language,
  /// not the audience's.
  ///
  /// Two of the three are RTL, which is why §2 insisted on an RTL-aware shell
  /// from day one. Retrofitted RTL always misses something.
  static const List<Locale> supported = [
    Locale('ar'),
    Locale('ckb'),
    Locale('en'),
  ];

  /// Fallback when the system locale is not one we ship.
  ///
  /// Arabic rather than English: this audience is far more likely to read
  /// Arabic, and English is the development language, not the market's.
  static const Locale fallback = Locale('ar');

  /// Whether a locale reads right to left.
  ///
  /// Derived from one place so a third RTL locale does not have to be
  /// remembered in every `textDirection` ternary scattered through the tests.
  static bool isRtl(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'ckb';
}

/// Serves Arabic Material strings for `ckb`.
class _CkbMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CkbMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) =>
      false;
}

/// Serves Arabic Widgets localizations for `ckb`.
///
/// Load-bearing beyond strings: WidgetsLocalizations is where
/// `textDirection` comes from, so without this a `ckb` locale resolves LTR and
/// every Directionality-aware widget lays out backwards. That is why the
/// widget tests had to pass `textDirection` by hand — they were compensating
/// for a missing delegate rather than testing RTL.
class _CkbWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _CkbWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<WidgetsLocalizations> old,
  ) =>
      false;
}

/// Serves Arabic Cupertino strings for `ckb`.
class _CkbCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CkbCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) =>
      false;
}