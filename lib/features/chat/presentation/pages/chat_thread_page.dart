import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wave/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:wave/features/chat/domain/entities/conversation.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.aboutProductId,
    super.key,
  });

  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? aboutProductId;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _composer = TextEditingController();
  final _repo = getIt<ChatRepository>();
  bool _sending = false;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;

    // Clear the field immediately. Firestore's offline queue already holds the
    // write, so the message appears in the list right away in a `sending`
    // state — waiting for the server before clearing makes the app feel broken
    // on a slow connection.
    _composer.clear();
    setState(() => _sending = true);

    final result = await _repo.send(
      conversationId: widget.conversationId,
      otherUserId: widget.otherUserId,
      text: text,
      otherUserName: widget.otherUserName,
      aboutProductId: widget.aboutProductId,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    result.fold(
      (f) {
        // Put the text back rather than losing what they typed.
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
    // Read from AuthBloc rather than passed in: a thread opened from a deep
    // link has no caller to supply it, and a wrong id here silently flips every
    // bubble to the wrong side.
    final currentUserId =
        context.select((AuthBloc bloc) => bloc.state.user?.uid) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: context.l10n.reportOrBlock,
            onPressed: () => showReportSheet(
              context,
              targetType: ReportTargetType.message,
              targetId: widget.conversationId,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.aboutProductId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: c.surface,
              child: Row(
                children: [
                  Icon(Icons.sell_outlined, size: 18, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.aboutAListing,
                      style: context.texts.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      Routes.productDetailPath(widget.aboutProductId!),
                    ),
                    child: Text(context.l10n.view),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _repo.watchMessages(widget.conversationId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <Message>[];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        context.l10n.chatEmptyPrompt,
                        style: context.texts.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Reversed so new messages appear at the bottom without having
                // to scroll a list that is still loading.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _Bubble(
                    message: messages[i],
                    isMine: messages[i].senderId == currentUserId,
                  ),
                );
              },
            ),
          ),

          _Composer(
            controller: _composer,
            onSend: _send,
            enabled: !_sending,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final pending = message.status == MessageStatus.sending;

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
          border: isMine ? null : Border.all(color: c.border),
        ),
        // Faded while queued, so an unsent message is visibly different from a
        // delivered one without needing a status icon on every bubble.
        child: Opacity(
          opacity: pending ? 0.6 : 1,
          child: Text(
            message.text,
            style: context.texts.bodyMedium?.copyWith(
              color: isMine ? Colors.white : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: context.l10n.message,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send, size: 20),
              tooltip: context.l10n.send,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ),
    );
  }
}
