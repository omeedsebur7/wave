import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/network/connectivity_service.dart';
import 'package:wave/core/theme/app_theme.dart';

/// Offline indicator (§6).
///
/// Firestore queues writes while offline and replays them on reconnect, which is
/// the right behaviour and also the reason this banner has to exist: without it,
/// tapping "place order" while offline looks like it worked. The write is real
/// and pending, but nothing has reached a seller, and someone who does not know
/// that will wait for a delivery that was never confirmed.
///
/// So the copy names the consequence rather than the state. "No connection" tells
/// the user something they can already guess from their signal bars; "changes
/// will sync when you're back" tells them what is actually true of the tap they
/// just made.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return StreamBuilder<ConnectionQuality>(
      stream: getIt<ConnectivityService>().onChanged,
      builder: (context, snapshot) {
        final quality = snapshot.data;
        if (quality != ConnectionQuality.offline) {
          return const SizedBox.shrink();
        }

        return Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: c.warning.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: c.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.offlineBannerBody,
                    style: context.texts.bodySmall?.copyWith(color: c.warning),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
