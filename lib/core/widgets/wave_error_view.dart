import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';

/// Failure and empty states get direction, not mood. Say what happened and
/// what to do about it; an empty screen is an invitation to act.
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

  /// An empty state is an invitation to act, not a failure report, so its
  /// default action reads differently.
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: c.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: context.texts.titleMedium,
                textAlign: TextAlign.center,),
            const SizedBox(height: 8),
            Text(message, style: context.texts.bodySmall,
                textAlign: TextAlign.center,),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: Text(
                  retryLabel ??
                      (_isEmpty ? context.l10n.getStarted : context.l10n.retry),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
