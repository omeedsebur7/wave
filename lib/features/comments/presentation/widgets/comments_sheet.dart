import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/error/failure_to_state.dart'; 
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_sign_in_sheet.dart'; 
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/comments/domain/entities/comment.dart';
import 'package:wave/features/comments/domain/repositories/comment_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';

Future<void> showCommentsSheet(
  BuildContext context, {
  required String reelId,
  required int commentCount,
}) {
  // FIXED: Replaced custom ModalBottomSheet with our physics-driven WaveSheet
  return WaveSheet.show<void>(
    context: context,
    title: commentCount == 0
        ? context.l10n.comments
        : context.l10n.commentsCount(commentCount),
    builder: (_) => _CommentsSheet(reelId: reelId),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.reelId});

  final String reelId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _composer = TextEditingController();
  final _repo = getIt<CommentRepository>();
  bool _posting = false;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _posting) return;

    _composer.clear();
    FocusScope.of(context).unfocus();
    setState(() => _posting = true);

    final result = await _repo.post(reelId: widget.reelId, text: text);
    if (!mounted) return;
    setState(() => _posting = false);

    result.fold(
      (f) {
        if (isSignInPrompt(f.reason)) {
          WaveSignInSheet.show(
            context: context,
            onSuccess: () {
              _composer.text = text;
              _post(); 
            },
          );
          return;
        }

        _composer.text = text;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureText(context, f))));
      },
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75, // Ensures consistent scrollable height inside WaveSheet
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _repo.watch(widget.reelId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // FIXED: Replaced standard indicator with WaveStateView
                  return const WaveStateView(
                    state: WaveLoading(SizedBox.shrink()), 
                    content: SizedBox.shrink(),
                  );
                }

                final comments = snapshot.data ?? const <Comment>[];
                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(WaveSpacing.x32), // FIXED
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.l10n.noCommentsYet,
                              style: context.texts.title,), // FIXED
                          const SizedBox(height: WaveSpacing.x8), // FIXED
                          Text(
                            context.l10n.noCommentsBody,
                            style: context.texts.caption, // FIXED
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: WaveSpacing.x16,
                    vertical: WaveSpacing.x12,
                  ), // FIXED
                  itemCount: comments.length,
                  itemBuilder: (context, i) => _CommentTile(
                    comment: comments[i],
                    onLike: () {
                      HapticFeedback.selectionClick();
                      _repo.toggleLike(
                        reelId: widget.reelId,
                        commentId: comments[i].id,
                        liked: !comments[i].likedByMe,
                      );
                    },
                    onReport: () => showReportSheet(
                      context,
                      targetType: ReportTargetType.comment,
                      targetId: comments[i].id,
                    ),
                  ),
                );
              },
            ),
          ),

          _Composer(
            controller: _composer,
            enabled: !_posting,
            onSend: _post,
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReport,
  });

  final Comment comment;
  final VoidCallback onLike;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Opacity(
      opacity: comment.isPending ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x16), // FIXED
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16, // FIXED
              backgroundColor: c.border,
              child: Text(
                comment.authorName.isEmpty
                    ? '?'
                    : comment.authorName[0].toUpperCase(),
                style: context.texts.caption, // FIXED
              ),
            ),
            const SizedBox(width: WaveSpacing.x12), // FIXED
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.authorName.isEmpty
                              ? context.l10n.someone
                              : comment.authorName,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.caption.copyWith( // FIXED
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (comment.isFromSeller) ...[
                        const SizedBox(width: WaveSpacing.x8), // FIXED
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: WaveSpacing.x8, // FIXED
                            vertical: 2, // FIXED
                          ),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6), // FIXED
                          ),
                          child: Text(
                            context.l10n.seller,
                            style: context.texts.caption.copyWith( // FIXED
                              color: c.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2), // FIXED
                  Text(comment.text, style: context.texts.body), // FIXED
                ],
              ),
            ),
            const SizedBox(width: WaveSpacing.x8), // FIXED
            Column(
              children: [
                IconButton(
                  onPressed: comment.isPending ? null : onLike,
                  iconSize: 16, // FIXED
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40), // FIXED
                  tooltip: comment.likedByMe
                      ? context.l10n.unlike
                      : context.l10n.like,
                  icon: Icon(
                    comment.likedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: comment.likedByMe ? c.error : c.textSecondary,
                  ),
                ),
                if (comment.likeCount > 0)
                  Text(context.number(comment.likeCount),
                      style: context.texts.caption,), // FIXED
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      padding: EdgeInsetsDirectional.only(
        start: WaveSpacing.x16, // FIXED
        end: WaveSpacing.x8, // FIXED
        top: WaveSpacing.x8, // FIXED
        bottom: MediaQuery.viewInsetsOf(context).bottom + WaveSpacing.x8, // FIXED
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: WaveTextField( // FIXED: TextField -> WaveTextField
                controller: controller,
                maxLines: 4,
                hint: context.l10n.addAComment,
              ),
            ),
            const SizedBox(width: WaveSpacing.x8), // FIXED
            WaveButton( // FIXED: IconButton.filled -> WaveButton icon variant
              variant: WaveButtonVariant.icon,
              size: WaveButtonSize.sm,
              icon: Icons.send,
              label: context.l10n.postComment,
              onPressed: enabled ? onSend : null,
            ),
          ],
        ),
      ),
    );
  }
}
