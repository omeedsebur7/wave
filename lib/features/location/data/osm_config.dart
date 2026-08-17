import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// OpenStreetMap tile configuration.
///
/// ## Read this before shipping
///
/// The default below points at `tile.openstreetmap.org`, which is run on
/// donated hardware for testing and light personal use. The OSMF Tile Usage
/// Policy **prohibits** apps distributing substantial traffic to it, and they
/// enforce by blocking the User-Agent — so the failure mode is not a bill, it is
/// every map in the app going blank at once, for everyone, with no warning.
///
/// Before launch, set [tileUrlTemplate] to a provider you have an account with.
/// MapTiler, Stadia Maps, Thunderforest and Geoapify all serve OSM data and all
/// have free tiers that comfortably cover a launch. Self-hosting is also viable
/// and cheaper at volume.
///
/// ## Attribution is a licence term, not a nicety
///
/// OSM data is ODbL. Displaying it obliges you to credit OpenStreetMap
/// contributors visibly. [OsmAttribution] is therefore part of [WaveMap] rather
/// than something a screen opts into — a map that can be built without the
/// credit is a map somebody eventually builds without it.
abstract final class OsmConfig {
  /// Overridden at build time:
  ///
  ///     --dart-define=TILE_URL=https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=YOURKEY
  static const tileUrlTemplate = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Required by the tile usage policy, and the thing providers block on.
  /// Must be your real application id.
  static const userAgentPackageName = String.fromEnvironment(
    'TILE_USER_AGENT',
    defaultValue: 'app.wave.marketplace',
  );

  static bool get usingSharedOsmTiles =>
      tileUrlTemplate.contains('tile.openstreetmap.org');

  /// Shouts in a release build still pointing at the shared tile server.
  ///
  /// The failure mode is unusually bad: OSM enforces its usage policy by
  /// blocking the User-Agent, so every map in the app goes blank at once, for
  /// everyone, with no gradual degradation and no warning. Discovering that
  /// from user reports is discovering it late.
  ///
  /// Logged rather than thrown. A release build refusing to start over a tile
  /// URL would be a worse failure than the one it is warning about.
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

  /// Iraq, roughly centred. Used when there is nothing better to centre on.
  ///
  /// A world view would make the first interaction "pinch in from space", which
  /// on a slow connection means loading a dozen tiles nobody wanted.
  static const fallbackCentre = (lat: 33.3152, lng: 44.3661);
  static const fallbackZoom = 5.5;

  /// Close enough to distinguish buildings. Anything tighter and a hand-placed
  /// pin implies precision the person cannot actually see.
  static const pinZoom = 17.0;

  /// Below this, tiles get sparse for much of this region and the map stops
  /// being useful for placing a pin.
  static const maxZoom = 18.0;
  static const minZoom = 3.0;
}

/// The map widget, with attribution attached.
///
/// Everything that renders tiles goes through here so the credit cannot be
/// omitted by accident.
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
                  // Rotation is off deliberately. A map accidentally spun 30°
                  // while pinching is disorienting, and nothing here needs it.
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: OsmConfig.tileUrlTemplate,
              userAgentPackageName: OsmConfig.userAgentPackageName,
              maxZoom: OsmConfig.maxZoom,
              // Tiles are cached by the HTTP layer. Retaining a parent tile
              // while a child loads avoids the grey checkerboard that makes a
              // slow connection look like a broken map.
              keepBuffer: 3,
            ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
        const Positioned(bottom: 0, left: 0, right: 0, child: OsmAttribution()),
      ],
    );
  }
}

/// © OpenStreetMap contributors.
///
/// A licence obligation under ODbL, tappable because the licence expects the
/// credit to lead somewhere.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: Colors.black.withValues(alpha: 0.55),
          child: const Text(
            '© OpenStreetMap',
            style: TextStyle(fontSize: 10, color: Colors.white),
            // Never translated: it is an attribution to a named project, and
            // the licence expects the credit to be recognisable.
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
