import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/widgets/directional_chevron.dart';
import 'package:wave/core/widgets/wave_sheet.dart';

/// The publish sheet (§4).
/// FIXED: Replaced standard showModalBottomSheet with our signature WaveSheet physics!
Future<void> showPublishSheet(BuildContext context) {
  return WaveSheet.show<void>(
    context: context,
    title: context.l10n.publish, // Added standard title required by WaveSheet
    builder: (context) => const _PublishSheet(),
  );
}

class _PublishSheet extends StatelessWidget {
  const _PublishSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Option(
          icon: Icons.videocam,
          title: context.l10n.uploadAReel,
          subtitle: context.l10n.uploadAReelBody,
          onTap: () {
            Navigator.pop(context);
            context.push(Routes.uploadReel);
          },
        ),
        const SizedBox(height: WaveSpacing.x12),
        _Option(
          icon: Icons.sell_outlined,
          title: context.l10n.listAProduct,
          subtitle: context.l10n.listAProductBody,
          onTap: () {
            Navigator.pop(context);
            context.push(Routes.listProduct);
          },
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(WaveSpacing.x12), // FIXED
        child: Row(
          children: [
            Container(
              width: WaveSpacing.x48,
              height: WaveSpacing.x48,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
              ),
              child: Icon(icon, color: c.primary),
            ),
            const SizedBox(width: WaveSpacing.x16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.title), // FIXED
                  const SizedBox(height: WaveSpacing.x4), // FIXED
                  Text(subtitle, style: context.texts.caption), // FIXED
                ],
              ),
            ),
            DirectionalChevron(color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
