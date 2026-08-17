import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';

/// What the server said about a code.
class PromoOutcome {
  const PromoOutcome({
    required this.valid,
    required this.discountMinor,
    this.reason,
  });

  final bool valid;
  final int discountMinor;
  final String? reason;

  /// Maps the server's reason to something the buyer can act on.
  ///
  /// `not-found`, `inactive` and `exhausted` all arrive as `invalid` — the
  /// server collapses them deliberately, because telling someone a code exists
  /// but is spent is far more use to a guesser than telling them it never
  /// existed.
  CartMessage get message => switch (reason) {
        'expired' => CartMessage.promoExpired,
        'already-used' => CartMessage.promoUsed,
        'below-minimum' => CartMessage.promoBelowMinimum,
        _ => CartMessage.promoInvalid,
      };
}

/// Checks a promo code before the order is placed.
///
/// The client cannot read `promo_codes` — Firestore's read permission covers
/// `list`, so granting it would hand any signed-in account every code in the
/// system. This goes through a callable instead, which can be rate-limited.
class PromoRepository {
  PromoRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<Result<PromoOutcome>> validate({
    required String code,
    required int subtotalMinor,
    required String sellerId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('validatePromoCode')
          .call<Map<String, dynamic>>({
        'code': code,
        'subtotalMinor': subtotalMinor,
        'sellerId': sellerId,
      });

      return Success(
        PromoOutcome(
          valid: result.data['valid'] as bool? ?? false,
          discountMinor: (result.data['discountMinor'] as num?)?.toInt() ?? 0,
          reason: result.data['reason'] as String?,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      return Err(
        e.code == 'resource-exhausted'
            ? RateLimitedFailure(
                e.message ?? 'Too many attempts',
                reason: FailureReason.promoThrottled,
              )
            : ServerFailure(
                e.message ?? 'Could not check that code',
                code: e.code,
                reason: FailureReason.promoCheckFailed,
              ),
      );
    }
  }
}
