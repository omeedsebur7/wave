import 'package:flutter/material.dart';

@immutable
class WaveSpacing extends ThemeExtension<WaveSpacing> {
  const WaveSpacing({
    required this.x2,
    required this.x4,
    required this.x8,
    required this.x12,
    required this.x16,
    required this.x20,
    required this.x24,
    required this.x32,
    required this.x40,
    required this.x48,
    required this.x64,
    required this.controlSm,
    required this.controlMd,
    required this.controlLg,
    required this.minTapTarget,
  });

  factory WaveSpacing.standard() => const WaveSpacing(
        x2: 2,
        x4: 4,
        x8: 8,
        x12: 12,
        x16: 16,
        x20: 20,
        x24: 24,
        x32: 32,
        x40: 40,
        x48: 48,
        x64: 64,
        controlSm: 36,
        controlMd: 44,
        controlLg: 52,
        minTapTarget: 48,
      );

  final double x2;
  final double x4;
  final double x8;
  final double x12;
  final double x16;
  final double x20;
  final double x24;
  final double x32;
  final double x40;
  final double x48;
  final double x64;

  final double controlSm;
  final double controlMd;
  final double controlLg;
  final double minTapTarget;

  // ignore: prefer_constructors_over_static_methods
  static WaveSpacing of(BuildContext context) {
    final ext = Theme.of(context).extension<WaveSpacing>();
    assert(ext != null, 'WaveSpacing missing. Wrap in AppTheme.');
    return ext ?? WaveSpacing.standard();
  }

  @override
  WaveSpacing copyWith({
    double? x2, double? x4, double? x8, double? x12, double? x16,
    double? x20, double? x24, double? x32, double? x40, double? x48, double? x64,
    double? controlSm, double? controlMd, double? controlLg, double? minTapTarget,
  }) {
    return WaveSpacing(
      x2: x2 ?? this.x2,
      x4: x4 ?? this.x4,
      x8: x8 ?? this.x8,
      x12: x12 ?? this.x12,
      x16: x16 ?? this.x16,
      x20: x20 ?? this.x20,
      x24: x24 ?? this.x24,
      x32: x32 ?? this.x32,
      x40: x40 ?? this.x40,
      x48: x48 ?? this.x48,
      x64: x64 ?? this.x64,
      controlSm: controlSm ?? this.controlSm,
      controlMd: controlMd ?? this.controlMd,
      controlLg: controlLg ?? this.controlLg,
      minTapTarget: minTapTarget ?? this.minTapTarget,
    );
  }

  @override
  WaveSpacing lerp(covariant WaveSpacing? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
