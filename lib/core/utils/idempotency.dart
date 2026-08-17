import 'package:uuid/uuid.dart';

/// Client-generated idempotency keys (§5.2 — Idempotent Payment & Order
/// Writes).
///
/// The key is generated ONCE when the user opens checkout, not when they tap
/// Pay. That distinction is the whole point: if the tap fails and they retry,
/// or the app is killed mid-request and the webhook redelivers, the same key
/// arrives at the Cloud Function and the second write is deduplicated instead
/// of double-charging.
class IdempotencyKey {
  IdempotencyKey._(this.value);

  factory IdempotencyKey.generate() => IdempotencyKey._(const Uuid().v4());

  factory IdempotencyKey.fromStored(String stored) =>
      IdempotencyKey._(stored);

  final String value;

  @override
  String toString() => value;
}
