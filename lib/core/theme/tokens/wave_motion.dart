import 'package:flutter/material.dart';

/// Motion system driving all animations, transitions, and interactions (§P7).
class WaveMotion extends ThemeExtension<WaveMotion> {
  const WaveMotion({
    required this.emphasizedOvershoot,
    required this.sheetSpringMass,
    required this.sheetSpringStiffness,
    required this.sheetSpringDamping,
    this.instant = const Duration(milliseconds: 100),
    this.fast = const Duration(milliseconds: 180),
    this.base = const Duration(milliseconds: 240),
    this.slow = const Duration(milliseconds: 320),
    this.deliberate = const Duration(milliseconds: 480),
    this.shimmerLoop = const Duration(milliseconds: 1400),
    this.skeletonDelay = const Duration(milliseconds: 250),
    this.emphasized = const Cubic(0.2, 0, 0, 1),
    this.standard = Curves.easeInOutCubic,
    this.decelerate = Curves.easeOutCubic,
    // گەڕێنرایەوە بۆ بەها ڕاستەقینەکەی خۆی لەبری easeInCubic
    this.accelerate = const Cubic(0.4, 0, 1, 1), 
    this.press = Curves.easeOutCubic,
  });

  factory WaveMotion.standard() => const WaveMotion(
        emphasizedOvershoot: Cubic(0.22, 1.18, 0.36, 1),
        sheetSpringMass: 1,
        sheetSpringStiffness: 420,
        sheetSpringDamping: 34,
      );

  // Durations Scale
  final Duration instant;
  final Duration fast;
  final Duration base;
  final Duration slow;
  final Duration deliberate;
  final Duration shimmerLoop;
  final Duration skeletonDelay;

  // Curves & Spring Parameters (The Signature DNA)
  final Curve emphasized;
  final Curve emphasizedOvershoot;
  
  final double sheetSpringMass;
  final double sheetSpringStiffness;
  final double sheetSpringDamping;

  /// Gesture-driven dismissal. Carries velocity; a cubic cannot.
  SpringDescription get sheetSpring => SpringDescription(
        mass: sheetSpringMass,
        stiffness: sheetSpringStiffness,
        damping: sheetSpringDamping,
      );

  final Curve standard;
  final Curve decelerate;
  final Curve accelerate;
  final Curve press;

  /// Globally disables animations if device requests reduced motion
  static Duration resolve(BuildContext context, Duration baseDuration) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return baseDuration;
  }

  // ignore: prefer_constructors_over_static_methods
  static WaveMotion of(BuildContext context) {
    return Theme.of(context).extension<WaveMotion>() ?? WaveMotion.standard();
  }

  @override
  WaveMotion copyWith({
    Duration? instant,
    Duration? fast,
    Duration? base,
    Duration? slow,
    Duration? deliberate,
    Duration? shimmerLoop,
    Duration? skeletonDelay,
    Curve? emphasized,
    Curve? emphasizedOvershoot,
    double? sheetSpringMass,
    double? sheetSpringStiffness,
    double? sheetSpringDamping,
    Curve? standard,
    Curve? decelerate,
    Curve? accelerate,
    Curve? press,
  }) {
    return WaveMotion(
      instant: instant ?? this.instant,
      fast: fast ?? this.fast,
      base: base ?? this.base,
      slow: slow ?? this.slow,
      deliberate: deliberate ?? this.deliberate,
      shimmerLoop: shimmerLoop ?? this.shimmerLoop,
      skeletonDelay: skeletonDelay ?? this.skeletonDelay,
      emphasized: emphasized ?? this.emphasized,
      emphasizedOvershoot: emphasizedOvershoot ?? this.emphasizedOvershoot,
      sheetSpringMass: sheetSpringMass ?? this.sheetSpringMass,
      sheetSpringStiffness: sheetSpringStiffness ?? this.sheetSpringStiffness,
      sheetSpringDamping: sheetSpringDamping ?? this.sheetSpringDamping,
      standard: standard ?? this.standard,
      decelerate: decelerate ?? this.decelerate,
      accelerate: accelerate ?? this.accelerate,
      press: press ?? this.press,
    );
  }

  @override
  WaveMotion lerp(covariant ThemeExtension<WaveMotion>? other, double t) {
    if (other is! WaveMotion) return this;
    return WaveMotion(
      instant: Duration(
        milliseconds: (instant.inMilliseconds +
                (other.instant.inMilliseconds - instant.inMilliseconds) * t)
            .round(),
      ),
      fast: Duration(
        milliseconds: (fast.inMilliseconds +
                (other.fast.inMilliseconds - fast.inMilliseconds) * t)
            .round(),
      ),
      base: Duration(
        milliseconds: (base.inMilliseconds +
                (other.base.inMilliseconds - base.inMilliseconds) * t)
            .round(),
      ),
      slow: Duration(
        milliseconds: (slow.inMilliseconds +
                (other.slow.inMilliseconds - slow.inMilliseconds) * t)
            .round(),
      ),
      deliberate: Duration(
        milliseconds: (deliberate.inMilliseconds +
                (other.deliberate.inMilliseconds - deliberate.inMilliseconds) * t)
            .round(),
      ),
      shimmerLoop: Duration(
        milliseconds: (shimmerLoop.inMilliseconds +
                (other.shimmerLoop.inMilliseconds - shimmerLoop.inMilliseconds) * t)
            .round(),
      ),
      skeletonDelay: Duration(
        milliseconds: (skeletonDelay.inMilliseconds +
                (other.skeletonDelay.inMilliseconds - skeletonDelay.inMilliseconds) * t)
            .round(),
      ),
      emphasized: t < 0.5 ? emphasized : other.emphasized,
      emphasizedOvershoot: t < 0.5 ? emphasizedOvershoot : other.emphasizedOvershoot,
      sheetSpringMass: t < 0.5 ? sheetSpringMass : other.sheetSpringMass,
      sheetSpringStiffness: t < 0.5 ? sheetSpringStiffness : other.sheetSpringStiffness,
      sheetSpringDamping: t < 0.5 ? sheetSpringDamping : other.sheetSpringDamping,
      standard: t < 0.5 ? standard : other.standard,
      decelerate: t < 0.5 ? decelerate : other.decelerate,
      accelerate: t < 0.5 ? accelerate : other.accelerate,
      press: t < 0.5 ? press : other.press,
    );
  }
}
