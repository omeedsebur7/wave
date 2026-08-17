import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

/// Trust-tier badge (§3.7).
///
/// Hard rule: this widget ALWAYS renders an icon plus a text label alongside
/// the colour. Never a bare colour swatch. Two reasons — WCAG 1.4.1, and the
/// fact that Gold necessarily shares the amber family with the `warning`
/// semantic colour, so a colour-only badge could genuinely be misread as a
/// stock or payment warning. The label removes that ambiguity entirely.
class TrustBadge extends StatelessWidget {
  const TrustBadge({
    required this.tier,
    this.compact = false,
    this.isKycVerified = false,
    super.key,
  });

  final TrustTier tier;

  /// Compact drops the label to an icon + tooltip for tight card corners —
  /// the semantic label is still exposed to screen readers.
  final bool compact;

  /// A manually/KYC-verified seller shows the existing `success` token, which
  /// §3.2 already defines as covering "verified seller". Separate axis from
  /// the rating-driven tier.
  final bool isKycVerified;

  Color _color(BuildContext context) {
    final t = context.trustColors;
    return switch (tier) {
      TrustTier.bronze => t.bronze,
      TrustTier.silver => t.silver,
      TrustTier.gold => t.gold,
      TrustTier.platinum => t.platinum,
      TrustTier.newSeller => context.waveColors.border,
    };
  }

  IconData get _icon => switch (tier) {
        TrustTier.bronze => Icons.workspace_premium_outlined,
        TrustTier.silver => Icons.workspace_premium,
        TrustTier.gold => Icons.military_tech,
        TrustTier.platinum => Icons.verified,
        TrustTier.newSeller => Icons.person_outline,
      };

  String _label(BuildContext context) => switch (tier) {
        TrustTier.bronze => context.l10n.trustBronze,
        TrustTier.silver => context.l10n.trustSilver,
        TrustTier.gold => context.l10n.trustGold,
        TrustTier.platinum => context.l10n.trustPlatinum,
        TrustTier.newSeller => context.l10n.trustNewSeller,
      };

  @override
  Widget build(BuildContext context) {
    final color = isKycVerified && !tier.hasBadge
        ? context.waveColors.success
        : _color(context);
    final label = isKycVerified && !tier.hasBadge
        ? context.l10n.trustVerifiedSeller
        : _label(context);

    return Semantics(
      label: label,
      container: true,
      child: Tooltip(
        message: label,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 14, color: color),
              if (!compact) ...[
                const SizedBox(width: 6),
                // ExcludeSemantics because the Semantics wrapper above already
                // announces the label — otherwise a screen reader says it twice.
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: context.texts.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
