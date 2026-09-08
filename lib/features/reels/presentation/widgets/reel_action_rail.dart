import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/presentation/bloc/reels_feed_bloc.dart';

class ReelActionRail extends StatelessWidget {
  const ReelActionRail({required this.reel, super.key});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReelsFeedBloc>();
    final c = context.waveColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: reel.likedByMe ? Icons.favorite : Icons.favorite_border,
          color: reel.likedByMe ? c.error : c.onScrim, // FIXED: Colors.white to onScrim
          label: _compact(context, reel.likeCount),
          semanticLabel: context.l10n.like,
          onTap: () {
            HapticFeedback.lightImpact();
            bloc.add(ReelLikeToggled(reel.id));
          },
        ),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          color: c.onScrim, // FIXED
          label: _compact(context, reel.commentCount),
          semanticLabel: context.l10n.comments,
          onTap: () => _openComments(context),
        ),
        _ActionButton(
          icon: reel.savedByMe ? Icons.bookmark : Icons.bookmark_border,
          color: c.onScrim, // FIXED
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
          color: c.onScrim, // FIXED
          label: context.l10n.share,
          semanticLabel: context.l10n.shareThisReel,
          onTap: () => Share.share(
            '${reel.caption.isEmpty ? reel.authorName : reel.caption}\n'
            'https://wave.app${Routes.reelDetailPath(reel.id)}',
          ),
        ),
        _ActionButton(
          icon: Icons.flag_outlined,
          color: c.onScrim, // FIXED
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

  static String _compact(BuildContext context, int n) => context.compact(n);
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    required this.color,
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
        padding: const EdgeInsetsDirectional.symmetric(vertical: WaveSpacing.x8), // FIXED
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(24), // FIXED
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // FIXED
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _c,
                  child: Icon(widget.icon, color: widget.color, size: 28), // FIXED
                ),
                const SizedBox(height: 2), // FIXED
                ExcludeSemantics(
                  child: Text(
                    widget.label,
                    style: context.texts.caption // FIXED
                        .copyWith(color: widget.color, fontSize: 11), 
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
