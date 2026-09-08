import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/network/connectivity_service.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

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
            padding: const EdgeInsetsDirectional.symmetric( // FIXED
              horizontal: WaveSpacing.x16, 
              vertical: WaveSpacing.x12, 
            ),
            color: c.warning.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: WaveSpacing.x16, color: c.warning), // FIXED
                const SizedBox(width: WaveSpacing.x8), // FIXED
                Expanded(
                  child: Text(
                    context.l10n.offlineBannerBody,
                    style: context.texts.caption.copyWith(color: c.warning), // FIXED
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
