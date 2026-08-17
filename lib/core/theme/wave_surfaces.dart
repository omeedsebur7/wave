import 'package:flutter/material.dart';

/// Glassmorphism / 3D surface tokens from §3.4.
///
/// The glow is deliberately rationed — FABs, the active product card, and the
/// 3D viewer only. Applied to every card it stops being a signature and
/// becomes noise.
@immutable
class WaveSurfaces extends ThemeExtension<WaveSurfaces> {
  const WaveSurfaces({
    required this.blurSigma,
    required this.blurSigmaLowEnd,
    required this.glassFill,
    required this.glassBorder,
    required this.glowColor,
    required this.isDark,
  });

  factory WaveSurfaces.light(Color glow) => WaveSurfaces(
        blurSigma: 20,
        blurSigmaLowEnd: 12,
        glassFill: Colors.white.withValues(alpha: 0.10), // 8–12%
        glassBorder: Colors.white.withValues(alpha: 0.19), // 18–20%
        glowColor: glow,
        isDark: false,
      );

  factory WaveSurfaces.dark(Color glow) => WaveSurfaces(
        blurSigma: 20,
        blurSigmaLowEnd: 12,
        glassFill: Colors.white.withValues(alpha: 0.05), // 4–6%
        glassBorder: Colors.white.withValues(alpha: 0.19),
        glowColor: glow,
        isDark: true,
      );

  final double blurSigma;
  final double blurSigmaLowEnd;
  final Color glassFill;
  final Color glassBorder;
  final Color glowColor;
  final bool isDark;

  // Corner radius scale: chips / cards / sheets.
  static const radiusChip = 12.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 24.0;

  /// Elevation tier 1 — resting. Cards at rest in a grid.
  List<BoxShadow> get resting => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Elevation tier 2 — raised. Selected cards, sheets, dialogs.
  List<BoxShadow> get raised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.10),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Elevation tier 3 — floating. FAB, active product card, 3D viewer.
  /// This is the only tier that carries the accent glow.
  List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: glowColor.withValues(alpha: 0.30), // 25–35%
          blurRadius: 32, // 24–40px
          spreadRadius: -4,
        ),
      ];

  @override
  WaveSurfaces copyWith({
    double? blurSigma,
    double? blurSigmaLowEnd,
    Color? glassFill,
    Color? glassBorder,
    Color? glowColor,
    bool? isDark,
  }) {
    return WaveSurfaces(
      blurSigma: blurSigma ?? this.blurSigma,
      blurSigmaLowEnd: blurSigmaLowEnd ?? this.blurSigmaLowEnd,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glowColor: glowColor ?? this.glowColor,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  WaveSurfaces lerp(ThemeExtension<WaveSurfaces>? other, double t) {
    if (other is! WaveSurfaces) return this;
    return WaveSurfaces(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      blurSigmaLowEnd: lerpDouble(blurSigmaLowEnd, other.blurSigmaLowEnd, t),
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
