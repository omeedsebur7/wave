import 'package:flutter/material.dart';

/// Primitive spacing tokens and semantic component heights (§P1).
/// Based on a strict 4px/8px rhythm. No magic numbers allowed.
class WaveSpacing extends ThemeExtension<WaveSpacing> {
  const WaveSpacing();

  // Primitive Spacing (8px rhythm)
  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x64 = 64;

  // Semantic Component Heights (§P3)
  static const double controlSm = 36;
  static const double controlMd = 44;
  static const double controlLg = 52;

  // Minimum interactive tap target size
  static const double minTapTarget = 48;

  @override
  ThemeExtension<WaveSpacing> copyWith() => this;

  @override
  ThemeExtension<WaveSpacing> lerp(ThemeExtension<WaveSpacing>? other, double t) => this;
}
