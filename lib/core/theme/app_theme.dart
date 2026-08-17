import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/core/theme/wave_colors.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/theme/wave_trust_colors.dart';
import 'package:wave/core/theme/wave_typography.dart';

/// Builds the two themes from the token extensions. Nothing here invents a
/// colour — every value traces back to §3.2 / §3.7.
abstract final class AppTheme {
  static ThemeData light(Locale locale) {
    final c = WaveColors.light();
    final trust = WaveTrustColors.light();
    final surfaces = WaveSurfaces.light(c.accentGlow);
    return _build(Brightness.light, c, trust, surfaces, locale);
  }

  static ThemeData dark(Locale locale) {
    final c = WaveColors.dark();
    final trust = WaveTrustColors.dark();
    final surfaces = WaveSurfaces.dark(c.accentGlow);
    return _build(Brightness.dark, c, trust, surfaces, locale);
  }

  static ThemeData _build(
    Brightness brightness,
    WaveColors c,
    WaveTrustColors trust,
    WaveSurfaces surfaces,
    Locale locale,
  ) {
    final text = WaveTypography.textTheme(c.textPrimary, c.textSecondary, locale);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: brightness == Brightness.light
            ? AppColorsOn.onDark
            : AppColorsOn.onLight,
        secondary: c.accentInteractive,
        onSecondary: AppColorsOn.onDark,
        error: c.error,
        onError: AppColorsOn.onDark,
        surface: c.surface,
        onSurface: c.textPrimary,
        outline: c.border,
      ),
      textTheme: text,
      fontFamily: WaveFonts.bodyFor(locale),
      dividerColor: c.border,
      // Minimum 48x48dp touch targets everywhere (§3.5).
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
          ),
          textStyle: text.labelMedium,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WaveSurfaces.radiusSheet),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
          side: BorderSide(color: c.border),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [c, trust, surfaces],
    );
  }
}

/// The only two "raw" colours in the system: pure black/white used as
/// foreground on a filled button. Both are contrast-checked against the
/// primary tokens they sit on.
abstract final class AppColorsOn {
  static const onDark = Color(0xFFFFFFFF);
  static const onLight = Color(0xFF0B0F19);
}

/// Ergonomic accessors so widgets read `context.waveColors.primary` rather
/// than the full `Theme.of(context).extension<...>()!` incantation.
extension WaveThemeX on BuildContext {
  WaveColors get waveColors => Theme.of(this).extension<WaveColors>()!;
  WaveTrustColors get trustColors =>
      Theme.of(this).extension<WaveTrustColors>()!;
  WaveSurfaces get surfaces => Theme.of(this).extension<WaveSurfaces>()!;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
