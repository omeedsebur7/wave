import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

class TrustBadge extends StatelessWidget {
  const TrustBadge({
    required this.tier,
    this.compact = false,
    this.isKycVerified = false,
    super.key,
  });

  final TrustTier tier;
  final bool compact;
  final bool isKycVerified;

  Color _color(BuildContext context) {
    final t = context.trustColors;
    return switch (tier) {
      TrustTier.bronze => t.bronze,
      TrustTier.silver => t.silver,
      TrustTier.gold => t.gold,
      TrustTier.platinum => t.platinum,
      TrustTier.newSeller => context.waveColors.textTertiary,
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
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;

    final color = isKycVerified && !tier.hasBadge
        ? c.success
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
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: compact ? s.x8 : s.x12,
            vertical: s.x4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: s.x16, color: color),
              if (!compact) ...[
                SizedBox(width: s.x4),
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: t.caption.copyWith(
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
