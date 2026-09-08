import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/core/theme/tokens/wave_colors.dart';
import 'package:wave/core/theme/tokens/wave_motion.dart';
import 'package:wave/core/theme/tokens/wave_spacing.dart';
import 'package:wave/core/theme/tokens/wave_typography.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/theme/wave_trust_colors.dart';

abstract final class AppTheme {
  static ThemeData light(Locale locale) => _build(
        Brightness.light,
        WaveColors.light(),
        WaveTrustColors.light(),
        WaveSurfaces.standard(),
        locale,
      );

  static ThemeData dark(Locale locale) => _build(
        Brightness.dark,
        WaveColors.dark(),
        WaveTrustColors.dark(),
        WaveSurfaces.standard(),
        locale,
      );

  static ThemeData _build(
    Brightness brightness,
    WaveColors c,
    WaveTrustColors trust,
    WaveSurfaces surfaces,
    Locale locale,
  ) {
    final typography =
        WaveTextStyles.forLocale(locale, c.textPrimary, c.textSecondary);
    final spacing = WaveSpacing.standard();
    final motion = WaveMotion.standard();
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.onAccent,
        secondary: c.accent,
        onSecondary: c.onAccent,
        tertiary: c.accent,
        onTertiary: c.onAccent,
        error: c.error,
        onError: c.onError,
        surface: c.surface,
        onSurface: c.textPrimary,
        outline: c.borderInput,
        surfaceTint: Colors.transparent,
        onSurfaceVariant: c.textSecondary,
        outlineVariant: c.divider,
        surfaceContainerLowest: c.background,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surfaceRaised,
        surfaceContainerHigh: c.surfaceRaised,
        surfaceContainerHighest: c.surfaceRaised,
        inverseSurface: c.textPrimary,
        onInverseSurface: c.surface,
        shadow: c.shadow,
        scrim: c.scrim,
      ),

      textTheme: typography.toTextTheme(),
      dividerColor: c.divider,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: c.shadow,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.textPrimary, size: spacing.x24),
        titleTextStyle: typography.title,
      ),

      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: 1,
        space: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: typography.body.copyWith(color: c.textTertiary),
        labelStyle: typography.body.copyWith(color: c.textSecondary),
        errorStyle: typography.caption.copyWith(color: c.error),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.x16,
          vertical: spacing.x12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusButton),
          borderSide: BorderSide(color: c.borderInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusButton),
          borderSide: BorderSide(color: c.borderInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusButton),
          borderSide: BorderSide(color: c.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusButton),
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusButton),
          borderSide: BorderSide(color: c.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusButton),
          borderSide: BorderSide(color: c.divider),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(spacing.x64, spacing.controlLg),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(surfaces.radiusButton),
          ),
          textStyle: typography.label,
          animationDuration: motion.fast,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(spacing.minTapTarget, spacing.minTapTarget),
        ),
      ),

      // The sort chips sit on the landing screen and were running on Material
      // defaults: their radius, selected colour and label style all came from
      // outside the design system.
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.accentSubtle,
        disabledColor: c.surfaceSunken,
        labelStyle: typography.label.copyWith(color: c.textSecondary),
        secondaryLabelStyle: typography.label.copyWith(color: c.accent),
        side: BorderSide(color: c.divider),
        showCheckmark: false,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.x12,
          vertical: spacing.x8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusFull),
        ),
      ),

      // WaveButton's loading spinner and every pull-to-refresh indicator.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceSunken,
        circularTrackColor: c.surfaceSunken,
      ),

      // Every icon-only control carries a tooltip for a11y, so this is a more
      // visible surface than it looks.
      tooltipTheme: TooltipThemeData(
        textStyle: typography.caption.copyWith(color: c.surface),
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: BorderRadius.circular(surfaces.radiusChip),
        ),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.x8,
          vertical: spacing.x4,
        ),
      ),

      // WaveButton drives all four variants through TextButton + ButtonStyle,
      // so this only affects raw TextButtons in unmigrated code — which is
      // exactly where an un-tokenised default would go unnoticed.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: typography.label,
          minimumSize: Size(spacing.x64, spacing.controlMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(surfaces.radiusButton),
          ),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised, // چاککردنی ئەو مەرجەی کە دووبارە بووبووەوە
        elevation: isLight ? 16 : 0,
        shadowColor: c.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(surfaces.radiusSheet),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: isLight ? c.surface : c.surfaceRaised,
        elevation: isLight ? 4 : 0,
        shadowColor: c.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: typography.body.copyWith(color: c.surface),
        actionTextColor: c.accent,
        elevation: 0,
        insetPadding: EdgeInsets.all(spacing.x16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusButton),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      extensions: [c, trust, surfaces, spacing, motion, typography],
    );
  }
}

extension WaveThemeX on BuildContext {
  WaveColors get waveColors => WaveColors.of(this);
  WaveTrustColors get trustColors => WaveTrustColors.of(this);
  WaveSurfaces get surfaces => WaveSurfaces.of(this);
  WaveSpacing get spacing => WaveSpacing.of(this);
  WaveMotion get motion => WaveMotion.of(this);
  WaveTextStyles get texts => WaveTextStyles.of(this);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
