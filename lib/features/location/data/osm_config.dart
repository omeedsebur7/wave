import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

abstract final class OsmConfig {
  static const tileUrlTemplate = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const userAgentPackageName = String.fromEnvironment(
    'TILE_USER_AGENT',
    defaultValue: 'app.wave.marketplace',
  );

  static bool get usingSharedOsmTiles =>
      tileUrlTemplate.contains('tile.openstreetmap.org');

  static void warnIfMisconfigured() {
    if (kReleaseMode && usingSharedOsmTiles) {
      debugPrint(
        'WAVE: release build is using OpenStreetMap shared tiles. '
        'Set --dart-define=TILE_URL to a provider you are entitled to use '
        'before shipping — see README step 15.',
      );
      FirebaseCrashlytics.instance.log('osm_shared_tiles_in_release');
    }
  }

  static const fallbackCentre = (lat: 33.3152, lng: 44.3661);
  static const fallbackZoom = 5.5;
  static const pinZoom = 17.0;
  static const maxZoom = 18.0;
  static const minZoom = 3.0;
}

class WaveMap extends StatelessWidget {
  const WaveMap({
    required this.controller,
    required this.initialCentre,
    this.initialZoom = OsmConfig.pinZoom,
    this.onPositionChanged,
    this.markers = const [],
    this.interactive = true,
    super.key,
  });

  final MapController controller;
  final ({double lat, double lng}) initialCentre;
  final double initialZoom;

  // ignore: avoid_positional_boolean_parameters
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;

  final List<Marker> markers;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: LatLng(initialCentre.lat, initialCentre.lng),
            initialZoom: initialZoom,
            minZoom: OsmConfig.minZoom,
            maxZoom: OsmConfig.maxZoom,
            onPositionChanged: onPositionChanged,
            interactionOptions: InteractionOptions(
              flags: interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: OsmConfig.tileUrlTemplate,
              userAgentPackageName: OsmConfig.userAgentPackageName,
              maxZoom: OsmConfig.maxZoom,
              keepBuffer: 3,
            ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
        const PositionedDirectional( // FIXED: Replaced standard Positioned
          bottom: 0, 
          start: 0, 
          end: 0, 
          child: OsmAttribution(),
        ),
      ],
    );
  }
}

class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: WaveSpacing.x8, 
            vertical: WaveSpacing.x4,
          ),
          color: c.scrim, 
          child: Text(
            '© OpenStreetMap',
            style: context.texts.caption.copyWith(color: c.textInverse),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
