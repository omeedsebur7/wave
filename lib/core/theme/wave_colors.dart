import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_colors.dart';

/// Single source of truth for semantic colour, per §3.1.
///
/// Every screen and 3D surface reads from this extension, so a token change
/// propagates everywhere at once. `Theme.of(context).extension<WaveColors>()!`
/// or, more conveniently, `context.waveColors`.
@immutable
class WaveColors extends ThemeExtension<WaveColors> {
  const WaveColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.accentGlow,
    required this.accentInteractive,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.border,
  });

  factory WaveColors.light() => const WaveColors(
        background: AppColorTokens.lightBackground,
        surface: AppColorTokens.lightSurface,
        textPrimary: AppColorTokens.lightTextPrimary,
        textSecondary: AppColorTokens.lightTextSecondary,
        primary: AppColorTokens.lightPrimary,
        accentGlow: AppColorTokens.lightAccentGlow,
        accentInteractive: AppColorTokens.lightAccentInteractive,
        success: AppColorTokens.lightSuccess,
        warning: AppColorTokens.lightWarning,
        error: AppColorTokens.lightError,
        info: AppColorTokens.lightInfo,
        border: AppColorTokens.lightBorder,
      );

  /// Dark mode's accent is text-safe, so glow and interactive collapse to one
  /// token. Keeping both fields means call sites don't branch on brightness.
  factory WaveColors.dark() => const WaveColors(
        background: AppColorTokens.darkBackground,
        surface: AppColorTokens.darkSurface,
        textPrimary: AppColorTokens.darkTextPrimary,
        textSecondary: AppColorTokens.darkTextSecondary,
        primary: AppColorTokens.darkPrimary,
        accentGlow: AppColorTokens.darkAccent,
        accentInteractive: AppColorTokens.darkAccent,
        success: AppColorTokens.darkSuccess,
        warning: AppColorTokens.darkWarning,
        error: AppColorTokens.darkError,
        info: AppColorTokens.darkInfo,
        border: AppColorTokens.darkBorder,
      );

  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;

  /// Decorative only in light mode. Do not place text or tap targets on it.
  final Color accentGlow;

  /// Use this whenever the accent touches text, an icon, or something tappable.
  final Color accentInteractive;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color border;

  @override
  WaveColors copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? accentGlow,
    Color? accentInteractive,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? border,
  }) {
    return WaveColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      accentGlow: accentGlow ?? this.accentGlow,
      accentInteractive: accentInteractive ?? this.accentInteractive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      border: border ?? this.border,
    );
  }

  @override
  WaveColors lerp(ThemeExtension<WaveColors>? other, double t) {
    if (other is! WaveColors) return this;
    return WaveColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      accentInteractive:
          Color.lerp(accentInteractive, other.accentInteractive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
