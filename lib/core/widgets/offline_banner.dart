import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/network/connectivity_service.dart';
import 'package:wave/core/theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

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
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: s.x16, 
              vertical: s.x12, // FIXED
            ),
            color: c.warning.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: s.x16, color: c.warning), // FIXED
                SizedBox(width: s.x8),
                Expanded(
                  child: Text(
                    context.l10n.offlineBannerBody,
                    style: context.texts.caption.copyWith(color: c.warning),
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
