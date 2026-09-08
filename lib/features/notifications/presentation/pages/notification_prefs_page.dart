import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/features/notifications/data/repositories/notification_repository.dart';
import 'package:wave/features/notifications/domain/entities/app_notification.dart';

class NotificationPrefsPage extends StatefulWidget {
  const NotificationPrefsPage({super.key});

  @override
  State<NotificationPrefsPage> createState() => _NotificationPrefsPageState();
}

class _NotificationPrefsPageState extends State<NotificationPrefsPage> {
  final _repo = getIt<NotificationRepository>();

  Map<NotificationChannel, bool>? _prefs;
  final _saving = <NotificationChannel>{};

  static String _channelLabel(BuildContext context, NotificationChannel c) =>
      switch (c) {
        NotificationChannel.orders => context.l10n.notifOrders,
        NotificationChannel.chat => context.l10n.notifChat,
        NotificationChannel.social => context.l10n.notifSocial,
        NotificationChannel.marketing => context.l10n.notifMarketing,
      };

  static String _channelSubtitle(BuildContext context, NotificationChannel c) =>
      switch (c) {
        NotificationChannel.orders => context.l10n.notifOrdersBody,
        NotificationChannel.chat => context.l10n.notifChatBody,
        NotificationChannel.social => context.l10n.notifSocialBody,
        NotificationChannel.marketing => context.l10n.notifMarketingBody,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await _repo.preferences();
    if (mounted) setState(() => _prefs = prefs);
  }

  Future<void> _toggle(NotificationChannel channel, bool value) async {
    setState(() {
      _prefs![channel] = value;
      _saving.add(channel);
    });

    final result = await _repo.setPreference(channel, enabled: value);
    if (!mounted) return;

    result.fold(
      (f) {
        setState(() {
          _prefs![channel] = !value; 
          _saving.remove(channel);
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureText(context, f))));
      },
      (_) => setState(() => _saving.remove(channel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notifications)),
      body: prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final channel in NotificationChannel.values)
                  SwitchListTile(
                    value: prefs[channel]!,
                    onChanged: _saving.contains(channel)
                        ? null
                        : (v) => _toggle(channel, v),
                    title: Text(_channelLabel(context, channel),
                        style: context.texts.label,), // FIXED
                    subtitle: Text(
                      _channelSubtitle(context, channel),
                      style: context.texts.caption, // FIXED
                    ),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(WaveSpacing.x20), // FIXED
                  child: Text(
                    context.l10n.notifOrdersOffWarning,
                    style: context.texts.caption, // FIXED
                  ),
                ),
              ],
            ),
    );
  }
}
