import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/features/location/data/osm_config.dart';
import 'package:wave/features/location/data/saved_location_store.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

/// Where the buyer says to deliver.
///
/// The pin is fixed to the centre of the screen and the map moves underneath
/// it. That is the opposite of dragging a marker, and it is deliberate: a
/// dragged marker spends the whole gesture under the user's thumb, so they
/// cannot see the thing they are aiming at. A fixed pin keeps the target
/// visible and turns placement into panning, which phones are good at.
///
/// Opened from Buy Now. Note the tension with §5.1's one-tap claim — a map
/// between the tap and the order is real friction on the app's core path. It is
/// mitigated by pre-centring on the last confirmed location, so a repeat buyer
/// confirms rather than searches, but it is friction and worth measuring: the
/// funnel already separates `buy_now_tapped` from `purchase_completed`, and
/// this screen now sits between them.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    this.initial,
    this.confirmLabel,
    super.key,
  });

  /// Pre-centres the map. Usually the buyer's last confirmed delivery point.
  final DeliveryLocation? initial;

  /// Overrides the confirm button, so the same screen can serve "set delivery
  /// location" and "place order" without pretending to be two screens.
  final String? confirmLabel;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _controller = MapController();
  final _note = TextEditingController();

  late ({double lat, double lng}) _centre;
  double? _accuracy;
  LocationSource _source = LocationSource.pin;
  bool _locating = false;
  String? _locateError;

  /// True while the map is settling. The confirm button stays live — blocking
  /// it mid-gesture would make the screen feel stuck — but the coordinate
  /// readout is hidden, because a number changing forty times a second is
  /// noise pretending to be information.
  

  @override
  void initState() {
    super.initState();

    final saved = widget.initial ?? getIt<SavedLocationStore>().last();
    if (saved != null) {
      _centre = (lat: saved.latitude, lng: saved.longitude);
      _source = LocationSource.saved;
      _note.text = saved.note ?? '';
    } else {
      _centre = OsmConfig.fallbackCentre;
      // No saved point, so try the device immediately. Someone who opened this
      // from Buy Now wants to be somewhere useful, not looking at all of Iraq.
      unawaited(_useMyLocation(silent: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    setState(() {
      _locating = true;
      _locateError = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Not an error state. Placing a pin by hand is a first-class way to use
        // this screen — plenty of people are ordering to an address they are
        // not standing in — so a refusal just means the map stays where it is.
        setState(() {
          _locating = false;
          _locateError = silent ? null : context.l10n.locationPermissionDenied;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Bounded so the button cannot spin indefinitely indoors. Ten seconds
          // of nothing means the fix is not coming.
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      setState(() {
        _centre = (lat: position.latitude, lng: position.longitude);
        _accuracy = position.accuracy;
        _source = LocationSource.gps;
        _locating = false;
      });
      _controller.move(
        LatLng(position.latitude, position.longitude),
        OsmConfig.pinZoom,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locateError = silent ? null : context.l10n.locationUnavailable;
      });
    }
  }

  DeliveryLocation get _current => DeliveryLocation(
        latitude: _centre.lat,
        longitude: _centre.lng,
        setBy: _source,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        // Only meaningful for a device fix. Once the map has been panned, the
        // GPS accuracy describes where the phone was, not where the pin is.
        accuracyMetres: _source == LocationSource.gps ? _accuracy : null,
        capturedAt: DateTime.now(),
      );

  Future<void> _confirm() async {
    final location = _current;
    if (!location.isValid) return;

    // Remembered so the next order opens on this point rather than on Iraq.
    await getIt<SavedLocationStore>().save(location);

    if (!mounted) return;
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final location = _current;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.setDeliveryLocation)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                WaveMap(
                  controller: _controller,
                  initialCentre: _centre,
                  initialZoom: widget.initial == null &&
                          _source == LocationSource.pin
                      ? OsmConfig.fallbackZoom
                      : OsmConfig.pinZoom,
                  onPositionChanged: (camera, hasGesture) {
                    if (!hasGesture) return;
                    setState(() {
                      _centre = (
                        lat: camera.center.latitude,
                        lng: camera.center.longitude,
                      );
                      // Panning makes it a hand-placed pin, whatever it was
                      // before. Keeping `gps` here would attach a device
                      // accuracy figure to a point the device never reported.
                      _source = LocationSource.pin;
                      _accuracy = null;
                      
                    });
                  },
                ),

                // The fixed pin. Offset upward by half its height so the point
                // of the pin sits on the map centre rather than its middle —
                // otherwise every location is placed slightly north of where
                // the user aimed.
                IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Icon(
                      Icons.location_on,
                      size: 44,
                      color: c.primary,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                PositionedDirectional(
                  end: 12,
                  bottom: 28,
                  child: FloatingActionButton.small(
                    heroTag: 'locate',
                    onPressed: _locating ? null : _useMyLocation,
                    tooltip: context.l10n.useMyLocation,
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 20),
                  ),
                ),

                if (OsmConfig.usingSharedOsmTiles)
                  // Debug-visible only. A silent dependency on donated
                  // infrastructure is how an app ships pointing at it.
                  const PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: _DevWarning(
                      text: 'Using shared OSM tiles — set TILE_URL before '
                          'release',
                    ),
                  ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.dragMapToSetPin,
                    style: context.texts.bodySmall,),

                if (location.isTooVague) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: c.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.locationTooVague,
                          style: context.texts.bodySmall
                              ?.copyWith(color: c.warning),
                        ),
                      ),
                    ],
                  ),
                ],

                if (_locateError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _locateError!,
                    style: context.texts.bodySmall?.copyWith(color: c.warning),
                  ),
                ],

                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLength: 140,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: context.l10n.deliveryNote,
                    hintText: context.l10n.deliveryNoteHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 4),
                // Says why the note matters. Couriers here find addresses by
                // landmark and a phone call far more often than by coordinates.
                Text(context.l10n.deliveryNoteWhy,
                    style: context.texts.bodySmall,),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: location.isValid ? _confirm : null,
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: Text(
                      widget.confirmLabel ?? context.l10n.confirmLocation,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DevWarning extends StatelessWidget {
  const _DevWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Release builds strip this: `assert` runs only in debug, so the branch
    // folds away and the warning cannot leak into a store build.
    var visible = false;
    assert(
      () {
        visible = true;
        return true;
      }(),
      // The message is never shown — this assert can never actually FAIL,
      // since the closure always returns true; its only job is to run
      // debug-only code via assert's short-circuiting. prefer_asserts_with_
      // message still wants a string, so this one documents what the assert
      // is really for rather than describing a failure condition that does
      // not exist.
      'debug-only: flips `visible` so this dev warning renders in debug '
      'builds and is compiled out of release ones',
    );
    if (!visible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.black),
      ),
    );
  }
}
