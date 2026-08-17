import 'package:flutter/material.dart';

/// Type system from §3.3.
///
/// Two roles — a display face used sparingly for prices, hero numbers and
/// section titles, and a body face tuned for dense feeds and chat. Arabic-script
/// locales swap in IBM Plex Sans Arabic 1:1 against the same roles, so changing
/// locale never breaks the scale.
abstract final class WaveFonts {
  static const display = 'PlusJakartaSans';
  static const body = 'Inter';
  static const arabic = 'IBMPlexSansArabic';

  /// Locale codes that should render in the Arabic-script companion face.
  /// ckb = Kurdish Sorani, ar = Arabic, fa = Farsi.
  static const arabicScriptLocales = {'ckb', 'ar', 'fa', 'ur'};

  static String displayFor(Locale locale) =>
      arabicScriptLocales.contains(locale.languageCode) ? arabic : display;

  static String bodyFor(Locale locale) =>
      arabicScriptLocales.contains(locale.languageCode) ? arabic : body;
}

/// Scale: display 32/40, headline 24/32, title 18/24, body 15/22, caption 13/18.
abstract final class WaveTypography {
  static TextTheme textTheme(Color primary, Color secondary, Locale locale) {
    final displayFamily = WaveFonts.displayFor(locale);
    final bodyFamily = WaveFonts.bodyFor(locale);

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFamily,
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: displayFamily,
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
    );
  }

  /// Prices and hero numbers use the display face with tabular figures so
  /// digits don't jitter as a cart total updates.
  static TextStyle price(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
