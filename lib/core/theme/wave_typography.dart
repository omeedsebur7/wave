import 'package:flutter/material.dart';

/// Type system from §3.3 and §P2.
abstract final class WaveFonts {
  static const display = 'PlusJakartaSans';
  static const body = 'Inter';
  static const arabic = 'IBMPlexSansArabic';

  static const arabicScriptLocales = {'ckb', 'ar', 'fa', 'ur'};

  static String displayFor(Locale locale) =>
      arabicScriptLocales.contains(locale.languageCode) ? arabic : display;

  static String bodyFor(Locale locale) =>
      arabicScriptLocales.contains(locale.languageCode) ? arabic : body;
}

/// Strict semantic text styles required by the design system (P2).
/// Material names (e.g., bodyMedium) are strictly forbidden.
class WaveTextStyles extends ThemeExtension<WaveTextStyles> {
  const WaveTextStyles({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.caption,
    required this.price,
    required this.priceStruck,
  });

  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle price;
  final TextStyle priceStruck;

  @override
  ThemeExtension<WaveTextStyles> copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? price,
    TextStyle? priceStruck,
  }) {
    return WaveTextStyles(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      price: price ?? this.price,
      priceStruck: priceStruck ?? this.priceStruck,
    );
  }

  @override
  ThemeExtension<WaveTextStyles> lerp(ThemeExtension<WaveTextStyles>? other, double t) {
    if (other is! WaveTextStyles) return this;
    return WaveTextStyles(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      price: TextStyle.lerp(price, other.price, t)!,
      priceStruck: TextStyle.lerp(priceStruck, other.priceStruck, t)!,
    );
  }
}

abstract final class WaveTypography {
  static WaveTextStyles textTheme(Color primary, Color secondary, Locale locale) {
    final isArabic = WaveFonts.arabicScriptLocales.contains(locale.languageCode);
    final displayFamily = WaveFonts.displayFor(locale);
    final bodyFamily = WaveFonts.bodyFor(locale);

    // §P2: Line height: 1.2–1.3 for display, 1.45–1.6 for body in Latin. 
    // For Arabic-script text, raise body to 1.7–1.8.
    final displayHeight = isArabic ? 1.5 : 1.25; 
    final bodyHeight = isArabic ? 1.75 : 1.46; 

    // §P2: Letter-spacing must be 0 for Arabic-script text.
    final letterSpacingDisplay = isArabic ? 0.0 : -0.5;
    final letterSpacingHeadline = isArabic ? 0.0 : -0.25;

    final displayStyle = TextStyle(
      fontFamily: displayFamily,
      fontSize: 32,
      height: displayHeight,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacingDisplay,
      color: primary,
    );

    final priceStyle = displayStyle.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return WaveTextStyles(
      display: displayStyle,
      headline: TextStyle(
        fontFamily: displayFamily,
        fontSize: 24,
        height: isArabic ? 1.6 : 1.33,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacingHeadline,
        color: primary,
      ),
      title: TextStyle(
        fontFamily: displayFamily,
        fontSize: 18,
        height: isArabic ? 1.7 : 1.33,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      body: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        height: bodyHeight,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyStrong: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        height: bodyHeight,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      label: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        height: bodyHeight,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      caption: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 13,
        height: isArabic ? 1.7 : 1.38,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      price: priceStyle,
      priceStruck: priceStyle.copyWith(
        decoration: TextDecoration.lineThrough,
        color: secondary,
        fontSize: 18, 
      ),
    );
  }
}
