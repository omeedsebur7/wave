import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/features/location/data/osm_config.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

/// The buyer's pin, as the seller sees it.
class DeliveryLocationCard extends StatelessWidget {
  const DeliveryLocationCard({required this.location, super.key});

  final DeliveryLocation? location;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final pin = location;

    if (pin == null) {
      return Row(
        children: [
          Icon(Icons.location_off_outlined, size: WaveSpacing.x16, color: c.textSecondary),
          const SizedBox(width: WaveSpacing.x8),
          Text(context.l10n.noLocationSet, style: context.texts.caption),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.deliveryLocation, style: context.texts.label),
        const SizedBox(height: WaveSpacing.x8),

        ClipRRect(
          borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
          child: SizedBox(
            height: WaveSpacing.x64 * 2 + WaveSpacing.x12, // ~140 equivalent using tokens
            child: Stack(
              children: [
                WaveMap(
                  controller: MapController(),
                  initialCentre: (lat: pin.latitude, lng: pin.longitude),
                  interactive: false,
                  markers: [
                    Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: WaveSpacing.x40,
                      height: WaveSpacing.x40,
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_on, size: WaveSpacing.x40, color: c.primary),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: () => _openInMaps(context, pin)),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (pin.isTooVague) ...[
          const SizedBox(height: WaveSpacing.x8),
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, size: WaveSpacing.x16, color: c.warning),
              const SizedBox(width: WaveSpacing.x8),
              Expanded(
                child: Text(
                  context.l10n.approximateFix,
                  style: context.texts.caption.copyWith(color: c.warning),
                ),
              ),
            ],
          ),
        ],

        if (pin.note != null) ...[
          const SizedBox(height: WaveSpacing.x8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.push_pin_outlined, size: WaveSpacing.x16, color: c.textSecondary),
              const SizedBox(width: WaveSpacing.x8),
              Expanded(
                child: SelectableText(
                  pin.note!,
                  style: context.texts.body,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: WaveSpacing.x8),
        Row(
          children: [
            WaveButton(
              variant: WaveButtonVariant.tertiary,
              size: WaveButtonSize.sm,
              onPressed: () => _openInMaps(context, pin),
              icon: Icons.map_outlined,
              label: context.l10n.openInMaps,
            ),
            const Spacer(),
            WaveButton(
              variant: WaveButtonVariant.icon,
              size: WaveButtonSize.sm,
              icon: Icons.copy,
              label: context.l10n.copy, // Semantic text
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: '${pin.rounded.lat},${pin.rounded.lng}'),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.copied)),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openInMaps(BuildContext context, DeliveryLocation pin) async {
    final lat = pin.rounded.lat;
    final lng = pin.rounded.lng;

    final candidates = <Uri>[
      if (!kIsWeb && Platform.isAndroid) Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
    ];

    for (final uri in candidates) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    }

    if (!context.mounted) return;
    await Clipboard.setData(ClipboardData(text: '$lat,$lng'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }
}
