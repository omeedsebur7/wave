import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/features/comments/domain/entities/comment.dart';
import 'package:wave/features/comments/domain/repositories/comment_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';

/// Comment thread for a Reel (§4).
///
/// A sheet rather than a route, for the same reason Buy Now is: pushing a page
/// tears down the video and loses the user's place in the feed. The Reel keeps
/// playing behind this.
Future<void> showCommentsSheet(
  BuildContext context, {
  required String reelId,
  required int commentCount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommentsSheet(reelId: reelId, commentCount: commentCount),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.reelId, required this.commentCount});

  final String reelId;
  final int commentCount;

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

    // Clear immediately — Firestore's local write already puts the comment in
    // the stream in a pending state, so waiting for the server before clearing
    // makes the app feel broken on a slow connection.
    _composer.clear();
    FocusScope.of(context).unfocus();
    setState(() => _posting = true);

    final result = await _repo.post(reelId: widget.reelId, text: text);
    if (!mounted) return;
    setState(() => _posting = false);

    result.fold(
      (f) {
        // Give the text back rather than losing what they typed.
        _composer.text = text;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureText(context, f))));
      },
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(WaveSurfaces.radiusSheet),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.commentCount == 0
                  ? context.l10n.comments
                  : context.l10n.commentsCount(widget.commentCount),
              style: context.texts.titleMedium,
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: c.border),

            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: _repo.watch(widget.reelId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data ?? const <Comment>[];
                  if (comments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.l10n.noCommentsYet,
                                style: context.texts.titleMedium,),
                            const SizedBox(height: 6),
                            Text(
                              // Naming the useful behaviour gets more of it
                              // than a generic "say something".
                              context.l10n.noCommentsBody,
                              style: context.texts.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
      // A queued comment is visibly different from a posted one, without
      // needing a status icon on every row.
      opacity: comment.isPending ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: c.border,
              child: Text(
                comment.authorName.isEmpty
                    ? '?'
                    : comment.authorName[0].toUpperCase(),
                style: context.texts.bodySmall,
              ),
            ),
            const SizedBox(width: 10),
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
                          style: context.texts.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (comment.isFromSeller) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.l10n.seller,
                            style: context.texts.bodySmall?.copyWith(
                              color: c.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(comment.text, style: context.texts.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  onPressed: comment.isPending ? null : onLike,
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
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
                      style: context.texts.bodySmall,),
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
      // 16 on the leading edge, 8 on the trailing: the send button sits at the
      // end and carries its own touch padding. Asymmetric, so it has to be
      // directional — as plain `left`/`right` the wide side landed next to the
      // button in Arabic and Kurdish and the field lost its breathing room.
      padding: EdgeInsetsDirectional.only(
        start: 16,
        end: 8,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
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
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: context.l10n.addAComment,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send, size: 18),
              tooltip: context.l10n.postComment,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ),
    );
  }
}
