import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/features/location/data/osm_config.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

/// The buyer's pin, as the seller sees it.
///
/// Shown on the seller's order card, not just the buyer's. A delivery location
/// that only the person who set it can see is a location that has not been
/// delivered anywhere.
///
/// The preview is deliberately non-interactive. A seller scrolling a queue of
/// orders should not have a map stealing every vertical drag that passes over
/// it — tapping opens their real map app, which is where they were going to
/// navigate from anyway.
class DeliveryLocationCard extends StatelessWidget {
  const DeliveryLocationCard({required this.location, super.key});

  final DeliveryLocation? location;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final pin = location;

    if (pin == null) {
      // Says so plainly rather than hiding the section. An order with no pin
      // needs a phone call, and a seller who does not know that will assume
      // the app lost it.
      return Row(
        children: [
          Icon(Icons.location_off_outlined, size: 16, color: c.textSecondary),
          const SizedBox(width: 8),
          Text(context.l10n.noLocationSet, style: context.texts.bodySmall),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.deliveryLocation, style: context.texts.labelMedium),
        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
          child: SizedBox(
            height: 140,
            child: Stack(
              children: [
                WaveMap(
                  controller: MapController(),
                  initialCentre: (lat: pin.latitude, lng: pin.longitude),
                  interactive: false,
                  markers: [
                    Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 40,
                      height: 40,
                      // Anchored at the bottom so the point of the pin sits on
                      // the coordinate rather than its centre.
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_on, size: 40, color: c.primary),
                    ),
                  ],
                ),
                // Catches taps before the map does, so the whole preview is one
                // target rather than a surface that swallows gestures.
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, size: 16, color: c.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  // A ±2km fix on a map looks as confident as a ±5m one. Saying
                  // so is the difference between a courier phoning ahead and a
                  // courier driving to the wrong street first.
                  context.l10n.approximateFix,
                  style: context.texts.bodySmall?.copyWith(color: c.warning),
                ),
              ),
            ],
          ),
        ],

        if (pin.note != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.push_pin_outlined, size: 16, color: c.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  pin.note!,
                  style: context.texts.bodyMedium,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _openInMaps(context, pin),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(context.l10n.openInMaps),
            ),
            const Spacer(),
            IconButton(
              // Copying the pair is the fallback when no map app is installed,
              // and the thing a seller pastes into a courier's WhatsApp.
              tooltip: context.l10n.copy,
              icon: const Icon(Icons.copy, size: 18),
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

  /// Hands off to whatever the seller already uses.
  ///
  /// Deliberately not an in-app navigator. Couriers here use Google Maps or
  /// Waze with local traffic data and voice guidance in the right language;
  /// rebuilding a worse version of that inside a marketplace app would be a
  /// Phase 2 mistake, not a Phase 1 feature.
  Future<void> _openInMaps(BuildContext context, DeliveryLocation pin) async {
    final lat = pin.rounded.lat;
    final lng = pin.rounded.lng;

    // `geo:` is the Android intent scheme and opens the user's default map app.
    // iOS does not register it, so it falls through to a universal link — which
    // Google Maps claims if installed and Apple Maps handles otherwise.
    final candidates = <Uri>[
      if (!kIsWeb && Platform.isAndroid) Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
    ];

    for (final uri in candidates) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    }

    if (!context.mounted) return;
    // Every handoff failed, which on a device with no map app is possible.
    // The coordinates go to the clipboard so the seller still has something.
    await Clipboard.setData(ClipboardData(text: '$lat,$lng'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }
}
