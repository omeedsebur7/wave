import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/selling/domain/entities/seller_stats.dart';

/// Assembles the seller dashboard.
///
/// Reads from Firestore rather than the Analytics API on purpose. Firebase
/// Analytics is sampled, delayed by hours, and cannot be queried per-seller
/// from a client — so the funnel counters are materialised onto the Reel and
/// order documents by the same functions that already maintain the other
/// aggregates. Analytics remains the tool for product-wide questions; this
/// screen answers one seller's question about their own numbers.
class SellerStatsRepository {
  SellerStatsRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Future<Result<SellerStats>> load({int periodDays = 30}) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }

    final since = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: periodDays)),
    );

    try {
      // Four independent reads, run together. Serialising them would make a
      // dashboard that already needs several round-trips feel slow for no
      // reason.
      final results = await Future.wait([
        _db
            .collection('reels')
            .where('author_id', isEqualTo: uid)
            .where('status', isEqualTo: 'published')
            .orderBy('views_count', descending: true)
            .limit(10)
            .get(),
        _db
            .collection('orders')
            .where('seller_id', isEqualTo: uid)
            .where('created_at', isGreaterThan: since)
            .get(),
        _db.collection('users').doc(uid).get(),
        // 'confirmed' and 'packed' only. An unpaid order is not waiting on the
        // seller, and counting it here would contradict the queue.
        _db
            .collection('orders')
            .where('seller_id', isEqualTo: uid)
            .where('status', whereIn: ['confirmed', 'packed'])
            .count()
            .get(),
      ]);

      final reels = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final orders = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final profile = results[2] as DocumentSnapshot<Map<String, dynamic>>;
      final awaiting = results[3] as AggregateQuerySnapshot;

      var views = 0;
      var taps = 0;
      final topReels = <ReelPerformance>[];

      for (final doc in reels.docs) {
        final data = doc.data();
        views += (data['views_count'] as num?)?.toInt() ?? 0;
        taps += (data['buy_now_taps'] as num?)?.toInt() ?? 0;

        topReels.add(
          ReelPerformance(
            reelId: doc.id,
            caption: data['caption'] as String? ?? '',
            thumbnailUrl: data['thumbnail_url'] as String? ?? '',
            views: (data['views_count'] as num?)?.toInt() ?? 0,
            buyNowTaps: (data['buy_now_taps'] as num?)?.toInt() ?? 0,
            orders: (data['orders_count'] as num?)?.toInt() ?? 0,
            hasLinkedProduct: data['linked_product_id'] != null,
          ),
        );
      }

      // Revenue counts delivered orders only. Counting confirmed-but-undelivered
      // money as earned would show a seller a number they cannot rely on, and
      // that drops when a buyer cancels.
      var revenue = 0;
      var placed = 0;
      var currency = 'IQD';

      for (final doc in orders.docs) {
        final data = doc.data();
        placed += 1;
        currency = data['currency'] as String? ?? currency;
        if (data['status'] == OrderInternalStatus.delivered.name) {
          revenue += (data['total_minor'] as num?)?.toInt() ?? 0;
        }
      }

      return Success(
        SellerStats(
          periodDays: periodDays,
          reelViews: views,
          buyNowTaps: taps,
          ordersPlaced: placed,
          revenueMinor: revenue,
          currency: currency,
          ordersAwaitingAction: awaiting.count ?? 0,
          avgRating: (profile.data()?['avg_rating'] as num?)?.toDouble() ?? 0,
          ratingCount: (profile.data()?['rating_count'] as num?)?.toInt() ?? 0,
          topReels: topReels,
        ),
      );
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not load your stats',
          code: e.code,
          reason: FailureReason.statsLoadFailed,
        ),
      );
    }
  }
}
