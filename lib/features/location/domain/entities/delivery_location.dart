import 'package:equatable/equatable.dart';

/// A point on a map, plus the things a courier actually needs.
///
/// Coordinates alone do not deliver a parcel here. Addresses in much of this
/// market are not postal-addressable in the way a geocoder expects — deliveries
/// are found by landmark and a phone call, which is why [note] sits alongside
/// the pin rather than being optional decoration.
///
/// [accuracyMetres] is carried because a pin dropped from a device GPS fix is a
/// different kind of claim from one a person placed by hand. A courier looking
/// at "±800m" knows to phone first.
class DeliveryLocation extends Equatable {
  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.setBy,
    this.note,
    this.accuracyMetres,
    this.capturedAt,
  });

  final double latitude;
  final double longitude;

  /// How the pin got where it is.
  final LocationSource setBy;

  /// Landmark, floor, gate colour — whatever gets someone to the door.
  final String? note;

  /// Radius of confidence for a device fix, in metres. Null for a hand-placed
  /// pin, where the concept does not apply.
  final double? accuracyMetres;

  final DateTime? capturedAt;

  /// Whether the coordinates are physically possible.
  ///
  /// Checked because a malformed pair reaching a courier's map app sends them
  /// somewhere real and wrong, rather than failing visibly.
  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      // 0,0 is in the Atlantic. It is almost always an uninitialised value
      // rather than a delivery address, and treating it as valid would send a
      // courier to Null Island.
      !(latitude == 0 && longitude == 0);

  /// A fix this vague is worse than none: it tells the courier nothing and
  /// looks authoritative on a map.
  bool get isTooVague => (accuracyMetres ?? 0) > 2000;

  /// Six decimal places is about 11cm — far beyond what any delivery needs, and
  /// beyond what should be written down about where somebody lives. Rounding
  /// here is a privacy decision, not a formatting one.
  ({double lat, double lng}) get rounded => (
        lat: double.parse(latitude.toStringAsFixed(5)),
        lng: double.parse(longitude.toStringAsFixed(5)),
      );

  /// Opens in whatever map app the courier has. `geo:` is the Android
  /// intent scheme; iOS falls back to a universal link at the call site.
  String get geoUri => 'geo:${rounded.lat},${rounded.lng}'
      '?q=${rounded.lat},${rounded.lng}';

  Map<String, dynamic> toJson() => {
        'lat': rounded.lat,
        'lng': rounded.lng,
        'set_by': setBy.name,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
        if (accuracyMetres != null) 'accuracy_m': accuracyMetres,
      };

  static DeliveryLocation? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final location = DeliveryLocation(
      latitude: lat,
      longitude: lng,
      setBy: LocationSource.values.firstWhere(
        (s) => s.name == json['set_by'],
        orElse: () => LocationSource.pin,
      ),
      note: json['note'] as String?,
      accuracyMetres: (json['accuracy_m'] as num?)?.toDouble(),
    );

    // A stored pair that is out of range is corrupt, not merely odd. Returning
    // null makes the seller's UI say "no location" instead of pointing at the
    // Atlantic.
    return location.isValid ? location : null;
  }

  // FIXED: Explicitly clears nullable fields to avoid the `?? this.x` trap.
  DeliveryLocation copyWith({
    double? latitude,
    double? longitude,
    LocationSource? setBy,
    String? note,
    bool clearNote = false,
    double? accuracyMetres,
    bool clearAccuracy = false,
  }) =>
      DeliveryLocation(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        setBy: setBy ?? this.setBy,
        note: clearNote ? null : (note ?? this.note),
        accuracyMetres: clearAccuracy ? null : (accuracyMetres ?? this.accuracyMetres),
        capturedAt: capturedAt,
      );

  // FIXED: Incomplete equality check resolved.
  @override
  List<Object?> get props => [
        latitude, 
        longitude, 
        setBy, 
        note, 
        accuracyMetres, 
        capturedAt,
      ];
}

enum LocationSource {
  /// The device reported it.
  gps,

  /// The buyer dragged the map. Usually more accurate than GPS indoors, and the
  /// only option when someone is ordering for delivery somewhere they are not.
  pin,

  /// Re-used from a previous order.
  saved,
}
