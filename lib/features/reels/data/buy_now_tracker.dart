import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';

/// Records a Buy Now tap (§5.1).
///
/// Deliberately writes in two places, because they answer different questions
/// and neither substitutes for the other:
///
/// - **Firebase Analytics** completes the funnel event chain, which is what
///   joins against orders for product-wide analysis.
/// - **A Firestore document** is what the seller's own dashboard can query.
///   Analytics is sampled, delayed by hours, and cannot be queried per-seller
///   from a client, so a seller asking "how is my Reel doing" needs the second
///   copy.
///
/// One document per tap, appended to a subcollection rather than incrementing
/// a field — a popular Reel would blow the one-write-per-second ceiling on a
/// single document, exactly as like counts would. A scheduled function sums
/// them.
class BuyNowTracker {
  BuyNowTracker(this._db, this._auth, this._analytics);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final AnalyticsService _analytics;

  Future<void> recordTap({
    required String reelId,
    required String productId,
    String? sellerId,
  }) async {
    unawaited(
      _analytics.log(
        AnalyticsEvents.buyNowTapped,
        params: {
          AnalyticsParams.reelId: reelId,
          AnalyticsParams.productId: productId,
          if (sellerId != null) AnalyticsParams.sellerId: sellerId,
        },
      ),
    );

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('reels')
          .doc(reelId)
          .collection('buy_now_taps')
          .add({
        'user_id': uid,
        'product_id': productId,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // A dropped tap record is not worth interrupting a purchase for. The
      // analytics event above still fired, so the product-wide funnel is
      // intact even when the per-seller copy is not.
    }
  }

  Future<void> recordSheetOpened({required String productId}) =>
      _analytics.log(
        AnalyticsEvents.quickCheckoutOpened,
        params: {AnalyticsParams.productId: productId},
      );
}
