import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
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
              padding: const EdgeInsetsDirectional.all(WaveSpacing.x12), // FIXED
              color: c.surface,
              child: Row(
                children: [
                  Icon(Icons.sell_outlined, size: WaveSpacing.x16, color: c.textSecondary),
                  const SizedBox(width: WaveSpacing.x8), // FIXED
                  Expanded(
                    child: Text(
                      context.l10n.aboutAListing,
                      style: context.texts.caption, // FIXED
                    ),
                  ),
                  WaveButton( // FIXED: TextButton -> WaveButton
                    variant: WaveButtonVariant.tertiary,
                    size: WaveButtonSize.sm,
                    label: context.l10n.view,
                    onPressed: () => context.push(
                      Routes.productDetailPath(widget.aboutProductId!),
                    ),
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
                      padding: const EdgeInsetsDirectional.all(WaveSpacing.x32), // FIXED
                      child: Text(
                        context.l10n.chatEmptyPrompt,
                        style: context.texts.caption, // FIXED
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsetsDirectional.all(WaveSpacing.x16), // FIXED
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
        margin: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x8), // FIXED
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: WaveSpacing.x12, 
          vertical: WaveSpacing.x8,
        ), // FIXED
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
          border: isMine ? null : Border.all(color: c.border),
        ),
        child: Opacity(
          opacity: pending ? 0.6 : 1,
          child: Text(
            message.text,
            style: context.texts.body.copyWith( // FIXED: bodyMedium -> body
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
      padding: const EdgeInsetsDirectional.fromSTEB(
        WaveSpacing.x12, 
        WaveSpacing.x8, 
        WaveSpacing.x12, 
        WaveSpacing.x8,
      ), // FIXED
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
                hint: context.l10n.message,
              ),
            ),
            const SizedBox(width: WaveSpacing.x8),
            WaveButton( // FIXED: IconButton.filled -> WaveButton icon variant
              variant: WaveButtonVariant.icon,
              size: WaveButtonSize.sm,
              icon: Icons.send,
              label: context.l10n.send,
              onPressed: enabled ? onSend : null,
            ),
          ],
        ),
      ),
    );
  }
}
