import 'package:flutter/material.dart';

abstract final class _Raw {
  static const n25 = Color(0xFFF2F4F8);
  static const n50 = Color(0xFFF7F8FA);
  static const n100 = Color(0xFFEDEFF3);
  static const n200 = Color(0xFFDFE3E9);
  static const n400 = Color(0xFFA3ACBB);
  static const n500 = Color(0xFF8A94A6);
  static const n600 = Color(0xFF767E8D);
  static const n700 = Color(0xFF5C6470);
  static const n800 = Color(0xFF3E4552);
  static const n900 = Color(0xFF262C36);
  static const n950 = Color(0xFF161A21);
  static const n1000 = Color(0xFF0B0E14);
  static const white = Color(0xFFFFFFFF);

  static const brand400 = Color(0xFF6BA5FF);
  static const brand600 = Color(0xFF0B63E5);
  static const brand700 = Color(0xFF0A4FB5);
  static const brand800 = Color(0xFF8FBBFF);
  static const brandTintLight = Color(0xFFE7F0FE);
  static const brandTintDark = Color(0xFF16233A);

  static const red600 = Color(0xFFD92D20);
  static const red400 = Color(0xFFF97066);
  static const redTintLight = Color(0xFFFEF0EF);
  static const redTintDark = Color(0xFF2C1614);

  static const green600 = Color(0xFF0E7C3A);
  static const green400 = Color(0xFF4ADE80);
  static const amber600 = Color(0xFFB54708);
  static const amber400 = Color(0xFFFDB022);
}

class WaveColors extends ThemeExtension<WaveColors> {
  const WaveColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.videoSurface,
    required this.scrim,
    required this.onScrim,
    required this.shadow,
    required this.divider,
    required this.borderInput,
    required this.borderFocus,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textInverse,
    required this.accent,
    required this.accentPressed,
    required this.accentSubtle,
    required this.onAccent,
    required this.error,
    required this.onError,
    required this.errorSubtle,
    required this.success,
    required this.warning,
    required this.price,
    required this.priceDiscount,
    required this.priceStrikethrough,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.shadowResting,
    required this.shadowRaised,
    required this.shadowFloating,
  });

  factory WaveColors.light() {
    const shadowC = Color(0x1A161A21);
    return const WaveColors(
      background: _Raw.n50,
      surface: _Raw.white,
      surfaceRaised: _Raw.white,
      surfaceSunken: _Raw.n100,
      videoSurface: _Raw.n1000,
      scrim: Color(0x7A0B0E14),
      onScrim: _Raw.n25,
      shadow: shadowC,
      divider: _Raw.n200,
      borderInput: _Raw.n500,
      borderFocus: _Raw.brand600,
      textPrimary: _Raw.n950,
      textSecondary: _Raw.n700,
      textTertiary: _Raw.n500,
      textDisabled: _Raw.n400,
      textInverse: _Raw.white,
      accent: _Raw.brand600,
      accentPressed: _Raw.brand700,
      accentSubtle: _Raw.brandTintLight,
      onAccent: _Raw.white,
      error: _Raw.red600,
      onError: _Raw.white,
      errorSubtle: _Raw.redTintLight,
      success: _Raw.green600,
      warning: _Raw.amber600,
      price: _Raw.n950,
      priceDiscount: _Raw.red600,
      priceStrikethrough: _Raw.n500,
      skeletonBase: _Raw.n100,
      skeletonHighlight: _Raw.white,
      shadowResting: [BoxShadow(color: shadowC, blurRadius: 4, offset: Offset(0, 2))],
      shadowRaised: [BoxShadow(color: shadowC, blurRadius: 8, offset: Offset(0, 4))],
      shadowFloating: [BoxShadow(color: shadowC, blurRadius: 16, offset: Offset(0, 8))],
    );
  }

  factory WaveColors.dark() {
    const shadowC = Color(0x66000000);
    return const WaveColors(
      background: _Raw.n1000,
      surface: _Raw.n950,
      surfaceRaised: _Raw.n900,
      surfaceSunken: Color(0xFF070910),
      videoSurface: _Raw.n1000,
      scrim: Color(0xB30B0E14),
      onScrim: _Raw.n25,
      shadow: shadowC,
      divider: _Raw.n800,
      borderInput: _Raw.n600,
      borderFocus: _Raw.brand400,
      textPrimary: _Raw.n25,
      textSecondary: _Raw.n400,
      textTertiary: _Raw.n500,
      textDisabled: _Raw.n600,
      textInverse: _Raw.n950,
      accent: _Raw.brand400,
      accentPressed: _Raw.brand800,
      accentSubtle: _Raw.brandTintDark,
      onAccent: _Raw.n1000,
      error: _Raw.red400,
      onError: _Raw.n1000,
      errorSubtle: _Raw.redTintDark,
      success: _Raw.green400,
      warning: _Raw.amber400,
      price: _Raw.n25,
      priceDiscount: _Raw.red400,
      priceStrikethrough: _Raw.n500,
      skeletonBase: _Raw.n900,
      skeletonHighlight: _Raw.n800,
      shadowResting: [BoxShadow(color: shadowC, blurRadius: 4, offset: Offset(0, 2))],
      shadowRaised: [BoxShadow(color: shadowC, blurRadius: 8, offset: Offset(0, 4))],
      shadowFloating: [BoxShadow(color: shadowC, blurRadius: 16, offset: Offset(0, 8))],
    );
  }

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color videoSurface;
  final Color scrim;
  final Color onScrim;
  final Color shadow;
  final Color divider;
  final Color borderInput;
  final Color borderFocus;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textInverse;
  final Color accent;
  final Color accentPressed;
  final Color accentSubtle;
  final Color onAccent;
  final Color error;
  final Color onError;
  final Color errorSubtle;
  final Color success;
  final Color warning;
  final Color price;
  final Color priceDiscount;
  final Color priceStrikethrough;
  
  final Color skeletonBase;
  final Color skeletonHighlight;
  final List<BoxShadow> shadowResting;
  final List<BoxShadow> shadowRaised;
  final List<BoxShadow> shadowFloating;

  @Deprecated('Legacy bridge. Use accent. Removed when P16 completes.')
  Color get primary => accent;
  @Deprecated('Legacy bridge. Use borderInput. Removed when P16 completes.')
  Color get border => borderInput;
  @Deprecated('Legacy bridge. Use accent. Removed when P16 completes.')
  Color get accentInteractive => accent;
  @Deprecated('Legacy bridge. Use brand600. Removed when P16 completes.')
  Color get info => _Raw.brand600;

  // ignore: prefer_constructors_over_static_methods
  static WaveColors of(BuildContext context) {
    final ext = Theme.of(context).extension<WaveColors>();
    assert(ext != null, 'WaveColors missing. Wrap in AppTheme.');
    return ext ?? WaveColors.light();
  }

  @override
  WaveColors copyWith({
    Color? background, Color? surface, Color? surfaceRaised, Color? surfaceSunken,
    Color? videoSurface, Color? scrim, Color? onScrim, Color? shadow, Color? divider, 
    Color? borderInput, Color? borderFocus, Color? textPrimary, Color? textSecondary,
    Color? textTertiary, Color? textDisabled, Color? textInverse,
    Color? accent, Color? accentPressed, Color? accentSubtle, Color? onAccent,
    Color? error, Color? onError, Color? errorSubtle, Color? success,
    Color? warning, Color? price, Color? priceDiscount, Color? priceStrikethrough,
    Color? skeletonBase, Color? skeletonHighlight,
    List<BoxShadow>? shadowResting, List<BoxShadow>? shadowRaised, List<BoxShadow>? shadowFloating,
  }) {
    return WaveColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      videoSurface: videoSurface ?? this.videoSurface,
      scrim: scrim ?? this.scrim,
      onScrim: onScrim ?? this.onScrim,
      shadow: shadow ?? this.shadow,
      divider: divider ?? this.divider,
      borderInput: borderInput ?? this.borderInput,
      borderFocus: borderFocus ?? this.borderFocus,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      onAccent: onAccent ?? this.onAccent,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorSubtle: errorSubtle ?? this.errorSubtle,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      price: price ?? this.price,
      priceDiscount: priceDiscount ?? this.priceDiscount,
      priceStrikethrough: priceStrikethrough ?? this.priceStrikethrough,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      shadowResting: shadowResting ?? this.shadowResting,
      shadowRaised: shadowRaised ?? this.shadowRaised,
      shadowFloating: shadowFloating ?? this.shadowFloating,
    );
  }

  @override
  WaveColors lerp(covariant WaveColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return WaveColors(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      videoSurface: c(videoSurface, other.videoSurface),
      scrim: c(scrim, other.scrim),
      onScrim: c(onScrim, other.onScrim),
      shadow: c(shadow, other.shadow),
      divider: c(divider, other.divider),
      borderInput: c(borderInput, other.borderInput),
      borderFocus: c(borderFocus, other.borderFocus),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textDisabled: c(textDisabled, other.textDisabled),
      textInverse: c(textInverse, other.textInverse),
      accent: c(accent, other.accent),
      accentPressed: c(accentPressed, other.accentPressed),
      accentSubtle: c(accentSubtle, other.accentSubtle),
      onAccent: c(onAccent, other.onAccent),
      error: c(error, other.error),
      onError: c(onError, other.onError),
      errorSubtle: c(errorSubtle, other.errorSubtle),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      price: c(price, other.price),
      priceDiscount: c(priceDiscount, other.priceDiscount),
      priceStrikethrough: c(priceStrikethrough, other.priceStrikethrough),
      skeletonBase: c(skeletonBase, other.skeletonBase),
      skeletonHighlight: c(skeletonHighlight, other.skeletonHighlight),
      shadowResting: BoxShadow.lerpList(shadowResting, other.shadowResting, t)!,
      shadowRaised: BoxShadow.lerpList(shadowRaised, other.shadowRaised, t)!,
      shadowFloating: BoxShadow.lerpList(shadowFloating, other.shadowFloating, t)!,
    );
  }
}
