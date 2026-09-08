import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/idempotency.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/checkout/data/datasources/saved_details_data_source.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';
import 'package:wave/features/orders/data/models/order_dto.dart';
import 'package:wave/features/orders/domain/entities/order.dart';


class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl(this._auth, this._db, this._functions, this._saved);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final SavedDetailsDataSource _saved;

  @override
  Future<Result<CheckoutReadiness>> readiness() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return const Success(
        CheckoutReadiness(
          isGuest: true,
          hasVerifiedPhone: false,
          hasSavedAddress: false,
          hasPaymentMethod: false,
        ),
      );
    }

    try {
      final profile = await _db.collection('users').doc(user.uid).get();
      final data = profile.data() ?? {};

      // Trust the server flag, not user.phoneNumber. A phone number can be
      // present on the auth record without our OTP flow having completed, and
      // this flag is written by the verification Cloud Function only.
      final phoneVerified = data['phone_verified'] as bool? ?? false;

      final addresses =
          await _db.collection('users').doc(user.uid).collection('addresses')
              .limit(1).get();
      final methods =
          await _db.collection('users').doc(user.uid).collection('payment_methods')
              .limit(1).get();

      return Success(
        CheckoutReadiness(
          isGuest: false,
          hasVerifiedPhone: phoneVerified,
          hasSavedAddress: addresses.docs.isNotEmpty,
          hasPaymentMethod: methods.docs.isNotEmpty,
        ),
      );
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<({String? addressId, String? paymentMethodId})>>
      defaultSelections() async {
    final addresses = await _saved.addresses();
    final methods = await _saved.paymentMethods();

    // First saved, not "most recently used": ordering by recency would make a
    // one-tap purchase send to whichever address someone last typed, which is
    // exactly the surprise a one-tap flow cannot afford. The list is ordered by
    // creation, so the first is the one they set up deliberately.
    return Success((
      addressId: addresses.valueOrNull?.firstOrNull?.id,
      paymentMethodId: methods.valueOrNull?.firstOrNull?.id,
    ),);
  }

  @override
  Future<Result<Order>> placeOrder({
    required IdempotencyKey idempotencyKey,
    required List<OrderItem> items,
    required String addressId,
    required String paymentMethodId,
    String? sourceReelId,
    String? promoCode,
    DeliveryLocation? deliveryLocation,
  }) async {
    // Re-check the gate server-side too — this is defence in depth. The client
    // check is for UX; the function's check is the one that counts.
    final gate = await readiness();
    final blocked = gate.fold(
      (f) => f,
      (r) => r.gate == CheckoutGate.needsPhoneVerification
          ? const PhoneVerificationRequiredFailure()
          : null,
    );
    if (blocked != null) return Err(blocked);

    try {
      // دەرهێنانی مۆرکی ئامێرەکە پێش ناردنی ئۆردەرەکە بۆ دۆزینەوەی ساختەکاری
      String? deviceId;
      try {
        deviceId = await FirebaseMessaging.instance.getToken();
      } catch (_) {
        // ئەگەر ئامێرەکە پشتگیری نۆتیفیکەیشنی نەدەکرد یان کێشەیەک هەبوو، ڕێگە مەدە ئۆردەرەکە بوەستێت
        deviceId = 'unknown_device';
      }

      final result = await _functions
          .httpsCallable('placeOrder')
          .call<Map<String, dynamic>>({
        // The whole idempotency contract in one field.
        'idempotencyKey': idempotencyKey.value,
        'items': [
          for (final i in items)
            {'productId': i.productId, 'quantity': i.quantity},
        ],
        'addressId': addressId,
        'paymentMethodId': paymentMethodId,
        'sourceReelId': sourceReelId,
        'promoCode': promoCode,
        'deviceId': deviceId, // <--- لێرەدا دەینێرین بۆ سێرڤەرەکە!
        if (deliveryLocation != null)
          'deliveryLocation': deliveryLocation.toJson(),
      });

      return Success(OrderDto.fromJson(result.data).toDomain());
    } on FirebaseFunctionsException catch (e) {
      return Err(
        switch (e.code) {
          'failed-precondition' => const PhoneVerificationRequiredFailure(),
          'resource-exhausted' =>
            const RateLimitedFailure(
              'Too many attempts. Wait a moment.',
              reason: FailureReason.checkoutThrottled,
            ),
          'out-of-range' => const OutOfStockFailure(),
          _ => ServerFailure(
              e.message ?? 'Order failed',
              code: e.code,
              reason: FailureReason.orderFailed,
            ),
        },
      );
    }
  }
}
