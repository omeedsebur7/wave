import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/location/data/osm_config.dart';
import 'package:wave/features/location/data/saved_location_store.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    this.initial,
    this.confirmLabel,
    super.key,
  });

  final DeliveryLocation? initial;
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
  
  bool _isSaving = false;

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
        setState(() {
          _locating = false;
          _locateError = silent ? null : context.l10n.locationPermissionDenied;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
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
        accuracyMetres: _source == LocationSource.gps ? _accuracy : null,
        capturedAt: DateTime.now(),
      );

  Future<void> _confirm() async {
    if (_isSaving) return;
    
    final location = _current;
    if (!location.isValid) return;

    setState(() => _isSaving = true);
    
    try {
      await getIt<SavedLocationStore>().save(location);
      if (!mounted) return;
      Navigator.of(context).pop(location);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                      _source = LocationSource.pin;
                      _accuracy = null;
                    });
                  },
                ),

                IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, -WaveSpacing.x20),
                    child: Icon(
                      Icons.location_on,
                      size: WaveSpacing.x40,
                      color: c.primary,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                PositionedDirectional(
                  end: WaveSpacing.x12,
                  bottom: WaveSpacing.x32,
                  child: FloatingActionButton.small(
                    heroTag: 'locate',
                    onPressed: _locating ? null : _useMyLocation,
                    tooltip: context.l10n.useMyLocation,
                    child: _locating
                        ? const SizedBox(
                            width: WaveSpacing.x20,
                            height: WaveSpacing.x20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: WaveSpacing.x20),
                  ),
                ),

                if (OsmConfig.usingSharedOsmTiles)
                  const PositionedDirectional(
                    top: WaveSpacing.x8,
                    start: WaveSpacing.x8,
                    child: _DevWarning(
                      text: 'Using shared OSM tiles — set TILE_URL before release',
                    ),
                  ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsetsDirectional.only(
              start: WaveSpacing.x20,
              end: WaveSpacing.x20,
              top: WaveSpacing.x16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + WaveSpacing.x20,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.dragMapToSetPin, style: context.texts.caption),

                if (location.isTooVague) ...[
                  const SizedBox(height: WaveSpacing.x8),
                  Row(
                    children: [
                      Icon(Icons.error_outline, size: WaveSpacing.x16, color: c.warning),
                      const SizedBox(width: WaveSpacing.x8),
                      Expanded(
                        child: Text(
                          context.l10n.locationTooVague,
                          style: context.texts.caption.copyWith(color: c.warning),
                        ),
                      ),
                    ],
                  ),
                ],

                if (_locateError != null) ...[
                  const SizedBox(height: WaveSpacing.x8),
                  Text(
                    _locateError!,
                    style: context.texts.caption.copyWith(color: c.warning),
                  ),
                ],

                const SizedBox(height: WaveSpacing.x12),
                
                WaveTextField(
                  label: context.l10n.deliveryNote,
                  hint: context.l10n.deliveryNoteHint,
                  controller: _note,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
                
                const SizedBox(height: WaveSpacing.x4),
                Text(context.l10n.deliveryNoteWhy, style: context.texts.caption),

                const SizedBox(height: WaveSpacing.x16),
                WaveButton(
                  label: widget.confirmLabel ?? context.l10n.confirmLocation,
                  expand: true,
                  isLoading: _isSaving,
                  onPressed: location.isValid && !_isSaving ? _confirm : null,
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
    var visible = false;
    assert(
      () {
        visible = true;
        return true;
      }(),
      'debug-only: flips `visible` so this dev warning renders in debug builds',
    );
    if (!visible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: WaveSpacing.x8,
        vertical: WaveSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: context.waveColors.warning,
        borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
      ),
      child: Text(
        text,
        style: context.texts.caption.copyWith(color: context.waveColors.surface), // FIXED: Replaced onWarning with surface
      ),
    );
  }
}
