import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_colors.dart';
import 'package:wave/core/theme/wave_colors.dart' show WaveColors;
import 'package:wave/core/widgets/trust_badge.dart' show TrustBadge;

/// Trust-tier badge palette (§3.7).
///
/// Deliberately a separate extension from [WaveColors] so nobody reaches for
/// `success` when they mean `platinum`, or `warning` when they mean `gold`.
///
/// Gold sits in the same amber family as the `warning` semantic colour — no
/// palette avoids that, gold is yellow. It is kept deeper and more saturated
/// than warning, and badges never rely on colour alone: every tier renders as
/// icon + text label (WCAG 1.4.1). See [TrustBadge].
@immutable
class WaveTrustColors extends ThemeExtension<WaveTrustColors> {
  const WaveTrustColors({
    required this.bronze,
    required this.silver,
    required this.gold,
    required this.platinum,
  });

  factory WaveTrustColors.light() => const WaveTrustColors(
        bronze: AppColorTokens.lightTrustBronze,
        silver: AppColorTokens.lightTrustSilver,
        gold: AppColorTokens.lightTrustGold,
        platinum: AppColorTokens.lightTrustPlatinum,
      );

  factory WaveTrustColors.dark() => const WaveTrustColors(
        bronze: AppColorTokens.darkTrustBronze,
        silver: AppColorTokens.darkTrustSilver,
        gold: AppColorTokens.darkTrustGold,
        platinum: AppColorTokens.darkTrustPlatinum,
      );

  final Color bronze;
  final Color silver;
  final Color gold;
  final Color platinum;

  @override
  WaveTrustColors copyWith({
    Color? bronze,
    Color? silver,
    Color? gold,
    Color? platinum,
  }) {
    return WaveTrustColors(
      bronze: bronze ?? this.bronze,
      silver: silver ?? this.silver,
      gold: gold ?? this.gold,
      platinum: platinum ?? this.platinum,
    );
  }

  @override
  WaveTrustColors lerp(ThemeExtension<WaveTrustColors>? other, double t) {
    if (other is! WaveTrustColors) return this;
    return WaveTrustColors(
      bronze: Color.lerp(bronze, other.bronze, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      platinum: Color.lerp(platinum, other.platinum, t)!,
    );
  }
}
