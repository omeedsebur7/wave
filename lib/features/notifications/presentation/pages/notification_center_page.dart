import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/notifications/data/repositories/notification_repository.dart';
import 'package:wave/features/notifications/domain/entities/app_notification.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final _repo = getIt<NotificationRepository>();

  Future<void> _open(AppNotification notification) async {
    if (!notification.read) {
      await _repo.markRead(notification.id);
    }
    if (!mounted) return;
    if (notification.deepLink != null) {
      unawaited(context.push(notification.deepLink!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: context.l10n.notificationSettings,
            onPressed: () => context.push(Routes.notificationPrefs),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _repo.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return WaveErrorView(
              title: context.l10n.notificationsNotLoaded,
              message: context.l10n.errorNoConnectionBody,
            );
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return WaveErrorView.empty(
              title: context.l10n.nothingNew,
              message: context.l10n.nothingNewBody,
              icon: Icons.notifications_none,
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1), // FIXED
            itemBuilder: (context, i) {
              final n = notifications[i];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colourFor(context, n.channel)
                      .withValues(alpha: 0.12),
                  child: Icon(
                    _iconFor(n.channel),
                    size: WaveSpacing.x20, // FIXED
                    color: _colourFor(context, n.channel),
                  ),
                ),
                title: Text(
                  n.title,
                  style: context.texts.body.copyWith( // FIXED: bodyMedium -> body
                    fontWeight: n.read ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.caption, // FIXED: bodySmall -> caption
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_relative(context, n.createdAt),
                        style: context.texts.caption,), // FIXED
                    if (!n.read) ...[
                      const SizedBox(height: WaveSpacing.x4), // FIXED
                      Icon(Icons.circle, size: WaveSpacing.x8, color: c.primary), // FIXED
                    ],
                  ],
                ),
                onTap: () => _open(n),
              );
            },
          );
        },
      ),
    );
  }

  static IconData _iconFor(NotificationChannel channel) => switch (channel) {
        NotificationChannel.orders => Icons.local_shipping_outlined,
        NotificationChannel.chat => Icons.chat_bubble_outline,
        NotificationChannel.social => Icons.favorite_border,
        NotificationChannel.marketing => Icons.campaign_outlined,
      };

  static Color _colourFor(BuildContext context, NotificationChannel channel) {
    final c = context.waveColors;
    return switch (channel) {
      NotificationChannel.orders => c.success,
      NotificationChannel.chat => c.primary,
      NotificationChannel.social => c.error,
      NotificationChannel.marketing => c.info,
    };
  }

  static String _relative(BuildContext context, DateTime when) {
    final diff = DateTime.now().difference(when);
    final l10n = context.l10n;
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inHours < 1) return l10n.timeMinutesShort(diff.inMinutes);
    if (diff.inDays < 1) return l10n.timeHoursShort(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysShort(diff.inDays);
    return l10n.timeWeeksShort((diff.inDays / 7).floor());
  }
}
