import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';

class SuspendedBanner extends StatelessWidget {
  const SuspendedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(WaveSpacing.x16), // FIXED
      color: c.error.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, size: WaveSpacing.x20, color: c.error), // FIXED
              const SizedBox(width: WaveSpacing.x8), // FIXED
              Expanded(
                child: Text(
                  context.l10n.accountSuspended,
                  style: context.texts.label.copyWith(color: c.error), // FIXED
                ),
              ),
            ],
          ),
          const SizedBox(height: WaveSpacing.x8), // FIXED
          Text(
            context.l10n.accountSuspendedBody,
            style: context.texts.caption, // FIXED
          ),
          const SizedBox(height: WaveSpacing.x8), // FIXED
          WaveButton( // FIXED: TextButton -> WaveButton
            variant: WaveButtonVariant.tertiary,
            size: WaveButtonSize.sm,
            label: context.l10n.readContentPolicy,
            onPressed: () => context.push(Routes.legalPath('content-policy')),
          ),
        ],
      ),
    );
  }
}
