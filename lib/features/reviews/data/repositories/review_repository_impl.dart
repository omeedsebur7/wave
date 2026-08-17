import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/reviews/domain/entities/review.dart';
import 'package:wave/features/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._db, this._auth, this._analytics);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final AnalyticsService _analytics;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<Result<List<Review>>> forProduct(
    String productId, {
    int limit = 20,
  }) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('product_id', isEqualTo: productId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return Success([
        for (final doc in snap.docs)
          Review(
            id: doc.id,
            productId: doc.get('product_id') as String,
            orderId: doc.get('order_id') as String,
            authorId: doc.get('author_id') as String,
            rating: (doc.get('rating') as num).toInt(),
            text: doc.data()['text'] as String?,
            createdAt:
                (doc.data()['created_at'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
            editedAt: (doc.data()['edited_at'] as Timestamp?)?.toDate(),
          ),
      ]);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<RatingSummary>> summaryForProduct(String productId) async {
    try {
      // The distribution comes from a materialised map on the product document,
      // written by a Cloud Function on each review. Counting 800 review docs on
      // every product page open would be both slow and expensive.
      final doc = await _db.collection('products').doc(productId).get();
      final data = doc.data();
      if (data == null) return const Success(RatingSummary.empty);

      final raw = data['rating_distribution'] as Map<String, dynamic>? ?? {};
      return Success(
        RatingSummary(
          average: (data['rating_avg'] as num?)?.toDouble() ?? 0,
          distribution: {
            for (var star = 1; star <= 5; star++)
              star: (raw['$star'] as num?)?.toInt() ?? 0,
          },
        ),
      );
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<void>> submitProductReview({
    required String productId,
    required String orderId,
    required int rating,
    String? text,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Sign in to review', reason: FailureReason.signInToReview),
      );
    }
    if (rating < 1 || rating > 5) {
      return const Err(
        ServerFailure(
          'Rating must be between 1 and 5',
          reason: FailureReason.ratingOutOfRange,
        ),
      );
    }

    final eligible = await _verifyDeliveredOrder(orderId, productId: productId);
    if (eligible != null) return Err(eligible);

    try {
      // Deterministic id: order + product. A second submission for the same
      // purchase overwrites rather than double-counting, which is also what
      // makes the "one review per order" rule enforceable.
      await _db.collection('reviews').doc('${orderId}_$productId').set({
        'product_id': productId,
        'order_id': orderId,
        'author_id': uid,
        'rating': rating,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      await _analytics.log(
        AnalyticsEvents.reviewSubmitted,
        params: {
          AnalyticsParams.productId: productId,
          'rating': rating,
          'has_text': text != null && text.trim().isNotEmpty,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapWriteError(e));
    }
  }

  @override
  Future<Result<void>> submitSellerRating({
    required String sellerId,
    required String orderId,
    required int rating,
    String? text,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Sign in to rate', reason: FailureReason.signInToRate),
      );
    }

    final eligible = await _verifyDeliveredOrder(orderId);
    if (eligible != null) return Err(eligible);

    try {
      // Document id IS the order id — that is the one-rating-per-order
      // guarantee, expressed in the data model rather than in a check that
      // could be raced.
      await _db.collection('seller_ratings').doc(orderId).set({
        'seller_id': sellerId,
        'order_id': orderId,
        'author_id': uid,
        'rating': rating,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      await _db.collection('orders').doc(orderId).update({
        'has_been_rated': true,
      });

      await _analytics.log(
        AnalyticsEvents.sellerRatingSubmitted,
        params: {
          AnalyticsParams.sellerId: sellerId,
          AnalyticsParams.orderId: orderId,
          'rating': rating,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(_mapWriteError(e));
    }
  }

  @override
  Future<Result<void>> editReview({
    required String reviewId,
    required int rating,
    String? text,
  }) async {
    try {
      await _db.collection('reviews').doc(reviewId).update({
        'rating': rating,
        if (text != null) 'text': text.trim(),
        'edited_at': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Err(
          PermissionFailure(
            'The 48-hour window to edit this review has closed.',
          FailureReason.editWindowClosed,
          ),
        );
      }
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  /// Returns null when eligible, or the reason not to be.
  Future<Failure?> _verifyDeliveredOrder(
    String orderId, {
    String? productId,
  }) async {
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      final data = doc.data();
      if (data == null) {
      return const NotFoundFailure(
        'Order not found',
        FailureReason.orderNotFound,
      );
    }

      if (data['buyer_id'] != _uid) {
        return const PermissionFailure(
        'This is not your order',
        FailureReason.notYourOrder,
      );
      }
      if (data['status'] != OrderInternalStatus.delivered.name) {
        return const PermissionFailure(
          'You can rate this once the order has been delivered.',
        FailureReason.rateAfterDelivery,
        );
      }
      if (productId != null) {
        final ids = [
          for (final id in (data['product_ids'] as List? ?? [])) id as String,
        ];
        if (!ids.contains(productId)) {
          return const PermissionFailure(
            'That item was not part of this order.',
        FailureReason.itemNotInOrder,
          );
        }
      }
      return null;
    } on FirebaseException catch (e) {
      return ServerFailure(e.message ?? 'Error', code: e.code);
    }
  }

  Failure _mapWriteError(FirebaseException e) => switch (e.code) {
        'permission-denied' => const PermissionFailure(
            'Only buyers who received this order can rate it.',
          FailureReason.rateBuyersOnly,
          ),
        'already-exists' =>
          const ServerFailure(
          'You have already rated this order.',
          reason: FailureReason.alreadyRated,
        ),
        _ => ServerFailure(
            e.message ?? 'Could not submit',
            code: e.code,
            reason: FailureReason.reviewSubmitFailed,
          ),
      };
}
