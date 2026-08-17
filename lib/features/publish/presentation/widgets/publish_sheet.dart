import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/widgets/directional_chevron.dart';

/// The publish sheet (§4).
///
/// One of the two places the brief reserves the boldest motion for (the other
/// being the 3D model reveal), so the entrance is a shade slower and more
/// deliberate than a standard sheet — this is the app's centre of gravity.
Future<void> showPublishSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PublishSheet(),
  );
}

class _PublishSheet extends StatelessWidget {
  const _PublishSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(WaveSurfaces.radiusSheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _Option(
              icon: Icons.videocam,
              title: context.l10n.uploadAReel,
              subtitle: context.l10n.uploadAReelBody,
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.uploadReel);
              },
            ),
            const SizedBox(height: 12),
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
        ),
      ),
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
      borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
              ),
              child: Icon(icon, color: c.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.texts.bodySmall),
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
