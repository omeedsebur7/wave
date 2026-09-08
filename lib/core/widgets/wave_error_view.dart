import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';

class WaveErrorView extends StatelessWidget {
  const WaveErrorView({
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.cloud_off,
    super.key,
  }) : _isEmpty = false;

  const WaveErrorView.empty({
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.explore_outlined,
    super.key,
  }) : _isEmpty = true;

  final bool _isEmpty;

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(WaveSpacing.x32), // FIXED
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: WaveSpacing.x40, color: c.textSecondary), // FIXED
            const SizedBox(height: WaveSpacing.x16), // FIXED
            Text(title, style: context.texts.title, // FIXED
                textAlign: TextAlign.center,),
            const SizedBox(height: WaveSpacing.x8), // FIXED
            Text(message, style: context.texts.caption, // FIXED
                textAlign: TextAlign.center,),
            if (onRetry != null) ...[
              const SizedBox(height: WaveSpacing.x20), // FIXED
              WaveButton( // FIXED: FilledButton -> WaveButton
                onPressed: onRetry,
                label: retryLabel ??
                    (_isEmpty ? context.l10n.getStarted : context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
