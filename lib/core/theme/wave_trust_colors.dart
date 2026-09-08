import 'package:flutter/material.dart';

/// Tier metallics, contrast-tuned.
///
/// Metallics are the hardest colours to make accessible — silver is light by
/// definition, so a silver that clears 3:1 on white reads as steel rather
/// than chrome. That trade is deliberate: the badge carries an icon and a
/// text label (WCAG 1.4.1), so hue is not doing the semantic work and can
/// afford to be darkened.
///
/// Ratios in comments are computed against the surface each tier sits on
/// (light #FFFFFF, dark #161A21). The contract test is the source of truth.
abstract final class _TrustRaw {
  // Light — on #FFFFFF
  static const bronzeLight = Color(0xFFA36B4E);    // ~4.40:1
  static const silverLight = Color(0xFF78849B);    // ~3.77:1
  static const goldLight = Color(0xFFB07207);      // ~4.00:1
  static const platinumLight = Color(0xFF35657D);  // ~6.34:1

  // Dark — on #161A21, and still ≥3:1 on surfaceRaised #262C36
  static const bronzeDark = Color(0xFFB0764A);     // ~4.60:1
  static const silverDark = Color(0xFFA8B3C4);     // ~8.23:1
  static const goldDark = Color(0xFFE0A345);       // ~7.89:1
  static const platinumDark = Color(0xFF9FD3E8);   // ~10.76:1
}

/// Trust-tier badge palette (§3.7).
///
/// Deliberately a separate extension from WaveColors so nobody reaches for
/// `success` when they mean `platinum`, or `warning` when they mean `gold`.
///
/// Gold sits in the same amber family as the `warning` semantic colour — no
/// palette avoids that, gold is yellow. It is kept deeper and more saturated
/// than warning, and badges never rely on colour alone: every tier renders
/// as icon + text label. See TrustBadge.
@immutable
class WaveTrustColors extends ThemeExtension<WaveTrustColors> {
  const WaveTrustColors({
    required this.bronze,
    required this.silver,
    required this.gold,
    required this.platinum,
  });

  factory WaveTrustColors.light() => const WaveTrustColors(
        bronze: _TrustRaw.bronzeLight,
        silver: _TrustRaw.silverLight,
        gold: _TrustRaw.goldLight,
        platinum: _TrustRaw.platinumLight,
      );

  factory WaveTrustColors.dark() => const WaveTrustColors(
        bronze: _TrustRaw.bronzeDark,
        silver: _TrustRaw.silverDark,
        gold: _TrustRaw.goldDark,
        platinum: _TrustRaw.platinumDark,
      );

  final Color bronze;
  final Color silver;
  final Color gold;
  final Color platinum;

  // ignore: prefer_constructors_over_static_methods
  static WaveTrustColors of(BuildContext context)  {
    final ext = Theme.of(context).extension<WaveTrustColors>();
    assert(ext != null, 'WaveTrustColors missing. Wrap in AppTheme.');
    return ext ?? WaveTrustColors.light();
  }

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
  WaveTrustColors lerp(covariant WaveTrustColors? other, double t) {
    if (other == null) return this;
    return WaveTrustColors(
      bronze: Color.lerp(bronze, other.bronze, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      platinum: Color.lerp(platinum, other.platinum, t)!,
    );
  }
}
