import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:wave/features/chat/domain/entities/conversation.dart';
import 'package:wave/features/chat/presentation/pages/chat_thread_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<ChatRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navChat)),
      body: StreamBuilder<List<Conversation>>(
        stream: repo.watchConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data ?? const <Conversation>[];
          if (conversations.isEmpty) {
            return WaveErrorView.empty(
              title: context.l10n.noMessagesYet,
              message: context.l10n.noMessagesBody,
              icon: Icons.chat_bubble_outline,
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final conv = conversations[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    conv.otherUserName.isEmpty
                        ? '?'
                        : conv.otherUserName[0].toUpperCase(),
                  ),
                ),
                title: Text(
                    conv.otherUserName.isEmpty
                        ? context.l10n.someone
                        : conv.otherUserName,
                    style: context.texts.labelMedium,),
                subtitle: Text(
                  conv.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall,
                ),
                trailing: conv.unreadCount == 0
                    ? null
                    : Badge(label: Text(context.number(conv.unreadCount))),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatThreadPage(
                      conversationId: conv.id,
                      otherUserId: conv.participantIds.firstWhere(
                        (id) => id != conv.otherUserName,
                        orElse: () => '',
                      ),
                      otherUserName: conv.otherUserName,
                      aboutProductId: conv.aboutProductId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
