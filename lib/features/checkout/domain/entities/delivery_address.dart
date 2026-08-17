import 'package:equatable/equatable.dart';

/// A delivery address.
///
/// Deliberately loose about structure. Address formats vary enormously, and in
/// much of Iraq and the Kurdistan Region a precise street address is less
/// useful to a courier than a landmark plus a phone call — so [landmark] is a
/// first-class field rather than an afterthought, and nothing here is required
/// beyond what a courier genuinely needs.
class DeliveryAddress extends Equatable {
  const DeliveryAddress({
    required this.id,
    required this.recipientName,
    required this.phoneNumber,
    required this.city,
    required this.addressLine,
    this.landmark,
    this.notes,
    this.isDefault = false,
  });

  final String id;
  final String recipientName;

  /// May differ from the account's verified number — you can send something to
  /// someone else.
  final String phoneNumber;

  final String city;
  final String addressLine;

  /// "Opposite the blue mosque", "above the pharmacy". Often the field that
  /// actually gets the parcel delivered.
  final String? landmark;

  final String? notes;
  final bool isDefault;

  String get summary => [
        addressLine,
        if (landmark != null && landmark!.isNotEmpty) landmark,
        city,
      ].join(', ');

  @override
  List<Object?> get props => [id, recipientName, addressLine, city, isDefault];
}
