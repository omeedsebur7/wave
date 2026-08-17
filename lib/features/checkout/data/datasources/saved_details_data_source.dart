import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/checkout/domain/entities/delivery_address.dart';
import 'package:wave/features/checkout/domain/entities/payment_method.dart';

/// Reads and writes the buyer's saved addresses and payment methods.
///
/// Both live under `users/{uid}/…` so Security Rules can express "only you" in
/// one line, and so an account deletion cascade picks them up automatically
/// rather than needing a separate sweep.
class SavedDetailsDataSource {
  SavedDetailsDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _collection(String name) {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection(name);
  }

  Future<Result<List<DeliveryAddress>>> addresses() async {
    final col = _collection('addresses');
    if (col == null) return const Success([]);

    try {
      final snap = await col.orderBy('is_default', descending: true).get();
      return Success([
        for (final doc in snap.docs)
          DeliveryAddress(
            id: doc.id,
            recipientName: doc.data()['recipient_name'] as String? ?? '',
            phoneNumber: doc.data()['phone_number'] as String? ?? '',
            city: doc.data()['city'] as String? ?? '',
            addressLine: doc.data()['address_line'] as String? ?? '',
            landmark: doc.data()['landmark'] as String?,
            notes: doc.data()['notes'] as String?,
            isDefault: doc.data()['is_default'] as bool? ?? false,
          ),
      ]);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  Future<Result<DeliveryAddress>> saveAddress(DeliveryAddress address) async {
    final col = _collection('addresses');
    if (col == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }

    try {
      final existing = await col.limit(1).get();
      // The first address a person adds becomes their default, so the next
      // checkout is genuinely one tap rather than one tap plus a picker.
      final isFirst = existing.docs.isEmpty;

      final ref = col.doc();
      await ref.set({
        'recipient_name': address.recipientName,
        'phone_number': address.phoneNumber,
        'city': address.city,
        'address_line': address.addressLine,
        if (address.landmark != null) 'landmark': address.landmark,
        if (address.notes != null) 'notes': address.notes,
        'is_default': isFirst || address.isDefault,
        'created_at': FieldValue.serverTimestamp(),
      });

      return Success(
        DeliveryAddress(
          id: ref.id,
          recipientName: address.recipientName,
          phoneNumber: address.phoneNumber,
          city: address.city,
          addressLine: address.addressLine,
          landmark: address.landmark,
          notes: address.notes,
          isDefault: isFirst || address.isDefault,
        ),
      );
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  Future<Result<List<PaymentMethod>>> paymentMethods() async {
    final col = _collection('payment_methods');
    if (col == null) return const Success([]);

    try {
      final snap = await col.get();
      return Success([
        for (final doc in snap.docs)
          PaymentMethod(
            id: doc.id,
            rail: PaymentRail.values.firstWhere(
              (r) => r.name == doc.data()['rail'],
              orElse: () => PaymentRail.cashOnDelivery,
            ),
            displayLabel: doc.data()['display_label'] as String?,
            // Only ever the last four. Full card data lives with the provider
            // and never touches Firestore or the device.
            lastFour: doc.data()['last_four'] as String?,
            isDefault: doc.data()['is_default'] as bool? ?? false,
          ),
      ]);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  /// Which rails are live in this market.
  ///
  /// Phase 1 is cash-only by explicit product decision, not by default. Online
  /// rails (ZainCash and anything added after it) are paused rather than
  /// deleted — the adapter code, the webhook, and the provider tests all stay
  /// in the tree, because ripping them out would mean rebuilding the payment
  /// abstraction from scratch when Phase 2 turns one back on. Only the thing
  /// that DECIDES which rail a buyer sees changes.
  ///
  /// [PaymentRail.phase1EnabledRails] is the enforcement, and it is
  /// deliberately NOT sourced from `config/payments`. A Remote Config-style
  /// document is exactly the kind of thing a dashboard typo or a stale cache
  /// re-enables by accident, and "we accidentally took an online payment
  /// during the cash-only phase" is a far worse failure than "we shipped a
  /// build without reading a config flag first". The one-line change to leave
  /// Phase 1 is in code, reviewed, and shipped — not toggled at runtime.
  Future<Set<PaymentRail>> availableRails() async {
    return PaymentRail.phase1EnabledRails;
  }
}
