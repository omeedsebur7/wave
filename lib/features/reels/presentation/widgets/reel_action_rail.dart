import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/presentation/bloc/reels_feed_bloc.dart';

/// Like / comment / save / share / report rail.
///
/// Micro-interactions here are scale + haptic (§3.5) — deliberately subtle.
/// The bold motion in this app is reserved for the publish sheet and the 3D
/// reveal.
class ReelActionRail extends StatelessWidget {
  const ReelActionRail({required this.reel, super.key});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReelsFeedBloc>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: reel.likedByMe ? Icons.favorite : Icons.favorite_border,
          color: reel.likedByMe ? context.waveColors.error : Colors.white,
          label: _compact(context, reel.likeCount),
          semanticLabel: context.l10n.like,
          onTap: () {
            HapticFeedback.lightImpact();
            bloc.add(ReelLikeToggled(reel.id));
          },
        ),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: _compact(context, reel.commentCount),
          semanticLabel: context.l10n.comments,
          onTap: () => _openComments(context),
        ),
        _ActionButton(
          icon: reel.savedByMe ? Icons.bookmark : Icons.bookmark_border,
          label: context.l10n.save,
          semanticLabel:
              reel.savedByMe ? context.l10n.remove : context.l10n.save,
          onTap: () {
            HapticFeedback.lightImpact();
            bloc.add(ReelSaveToggled(reel.id));
          },
        ),
        _ActionButton(
          icon: Icons.ios_share,
          label: context.l10n.share,
          semanticLabel: context.l10n.shareThisReel,
          onTap: () => Share.share(
            // A deep link, so the recipient lands on this Reel rather than the
            // app's front page (§5.2). Sharing a Reel that sells something is
            // the cheapest distribution this app has, and it only works if the
            // link resolves to the Reel.
            '${reel.caption.isEmpty ? reel.authorName : reel.caption}\n'
            'https://wave.app${Routes.reelDetailPath(reel.id)}',
          ),
        ),
        _ActionButton(
          icon: Icons.flag_outlined,
          label: context.l10n.report,
          semanticLabel: context.l10n.reportThisReel,
          onTap: () => _openReport(context),
        ),
      ],
    );
  }

  void _openComments(BuildContext context) => showCommentsSheet(
        context,
        reelId: reel.id,
        commentCount: reel.commentCount,
      );

  void _openReport(BuildContext context) => showReportSheet(
        context,
        targetType: ReportTargetType.reel,
        targetId: reel.id,
      );

  /// 1200 -> 1.2K. Long counts push the rail off a narrow screen.
  ///
  /// Delegated to `intl` rather than hand-rolled, because the suffix is
  /// language-specific: this returned a Latin `K` in Arabic and Kurdish.
  static String _compact(BuildContext context, int n) => context.compact(n);
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final Color color;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0.85,
    value: 1,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Reduced motion: skip the bounce, keep the action.
    if (!MediaQuery.disableAnimationsOf(context)) {
      _c.reverse().then((_) => _c.forward());
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _c,
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(height: 2),
                ExcludeSemantics(
                  child: Text(
                    widget.label,
                    style: context.texts.bodySmall
                        ?.copyWith(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
