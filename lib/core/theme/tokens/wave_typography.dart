import 'package:flutter/material.dart';

abstract final class WaveFonts {
  static const arabic = 'NotoSansArabic';
  static const latin = 'Inter';

  static const arabicFirst = <String>[latin];
  static const latinFirst = <String>[arabic];
}

abstract final class WaveIsolate {
  static const _lri = '\u2066';
  static const _rli = '\u2067';
  static const _fsi = '\u2068';
  static const _pdi = '\u2069';

  static String number(String s) => '$_lri$s$_pdi';
  static String arabic(String s) => '$_rli$s$_pdi';
  static String auto(String s) => '$_fsi$s$_pdi';
}

@immutable
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

  factory WaveTextStyles.forLocale(
    Locale locale,
    Color primary,
    Color secondary,
  ) {
    final ar = locale.languageCode == 'ku' ||
        locale.languageCode == 'ckb' ||
        locale.languageCode == 'ar' ||
        locale.languageCode == 'fa';

    final family = ar ? WaveFonts.arabic : WaveFonts.latin;
    final fallback = ar ? WaveFonts.arabicFirst : WaveFonts.latinFirst;

    TextStyle s(double size, FontWeight w, double h, Color c) => TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontSize: size,
          fontWeight: w,
          height: h,
          letterSpacing: 0,
          color: c,
        );

    return WaveTextStyles(
      display: s(32, FontWeight.w700, ar ? 1.35 : 1.2, primary),
      headline: s(24, FontWeight.w700, ar ? 1.4 : 1.25, primary),
      title: s(18, FontWeight.w600, ar ? 1.5 : 1.35, primary),
      body: s(15, FontWeight.w400, 1.6, primary),
      bodyStrong: s(15, FontWeight.w600, 1.6, primary),
      label: s(13, FontWeight.w600, ar ? 1.5 : 1.3, primary),
      caption: s(12, FontWeight.w400, ar ? 1.6 : 1.4, secondary),
      price: s(16, FontWeight.w600, ar ? 1.4 : 1.2, primary)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      priceStruck: s(13, FontWeight.w400, ar ? 1.4 : 1.2, secondary).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        decoration: TextDecoration.lineThrough,
      ),
    );
  }

  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle price;
  final TextStyle priceStruck;

  // --- LEGACY BRIDGE: Keeps old screens from crashing until migrated ---
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get displayLarge => display;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get headlineMedium => headline;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get headlineSmall => title;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get titleLarge => headline;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get titleMedium => title;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get bodyLarge => body;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get bodyMedium => body;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get bodySmall => caption;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get labelMedium => label;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  TextStyle get titleSmall => label;

  TextTheme toTextTheme() => TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: headline,
        headlineLarge: headline,
        headlineMedium: headline,
        headlineSmall: title,
        titleLarge: title,
        titleMedium: title,
        titleSmall: label,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: label,
        labelMedium: label,
        labelSmall: caption,
      );

  // ignore: prefer_constructors_over_static_methods
  static WaveTextStyles of(BuildContext context) {
    final ext = Theme.of(context).extension<WaveTextStyles>();
    assert(ext != null, 'WaveTextStyles missing. Wrap in AppTheme.');
    return ext ??
        WaveTextStyles.forLocale(
          const Locale('en'),
          const Color(0xFF161A21),
          const Color(0xFF5C6470),
        );
  }

  @override
  WaveTextStyles copyWith({
    TextStyle? display, TextStyle? headline, TextStyle? title,
    TextStyle? body, TextStyle? bodyStrong, TextStyle? label,
    TextStyle? caption, TextStyle? price, TextStyle? priceStruck,
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
  WaveTextStyles lerp(covariant WaveTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return WaveTextStyles(
      display: l(display, other.display),
      headline: l(headline, other.headline),
      title: l(title, other.title),
      body: l(body, other.body),
      bodyStrong: l(bodyStrong, other.bodyStrong),
      label: l(label, other.label),
      caption: l(caption, other.caption),
      price: l(price, other.price),
      priceStruck: l(priceStruck, other.priceStruck),
    );
  }
}
