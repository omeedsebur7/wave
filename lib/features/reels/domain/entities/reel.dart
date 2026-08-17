import 'package:equatable/equatable.dart';

class Reel extends Equatable {
  const Reel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.bunnyVideoId,
    required this.thumbnailUrl,
    required this.caption,
    required this.createdAt,
    required this.durationSeconds,
    this.authorAvatarUrl,
    this.linkedProductId,
    this.linkedProductPriceMinor,
    this.linkedProductCurrency,
    this.likeCount = 0,
    this.viewCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.rankScore = 0,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;

  /// Bunny Stream video GUID. Never a raw playback URL — URLs are signed
  /// per-request and short-lived (§6).
  final String bunnyVideoId;
  final String thumbnailUrl;
  final String caption;
  final DateTime createdAt;

  /// Hard 60s cap enforced client-side at upload (§4).
  final int durationSeconds;

  /// Set only by the Reel's original publisher (§4, §5.1). Its presence is
  /// exactly what makes the Buy Now button appear.
  final String? linkedProductId;

  /// The linked product's price, denormalised onto the Reel.
  ///
  /// Carried here so the Buy Now button can show a figure without a second read
  /// per Reel — the feed renders three at a time and prefetches more, so a read
  /// per card would multiply the cost of scrolling.
  ///
  /// This is a DISPLAY value and may be up to one sync behind. The quick
  /// checkout sheet re-reads the product, and `placeOrder` recomputes from the
  /// product document again, so nothing is ever charged from this number. A
  /// trigger keeps it current on every price change.
  final int? linkedProductPriceMinor;
  final String? linkedProductCurrency;

  /// Materialised from the shard sum by a scheduled function — the feed reads
  /// this, never the shards directly.
  final int likeCount;
  final int viewCount;
  final int commentCount;

  final bool likedByMe;
  final bool savedByMe;

  /// Feed ranking heuristic (§4): recency decay + engagement + follow boost,
  /// computed server-side on a schedule.
  final double rankScore;

  bool get hasLinkedProduct => linkedProductId != null;

  /// Whether there is a price worth putting on the button.
  ///
  /// A button reading "Buy Now — " with nothing after it is worse than one
  /// reading "Buy Now", so the price is shown only when both halves are
  /// present.
  bool get hasDisplayPrice =>
      linkedProductPriceMinor != null && linkedProductCurrency != null;

  Reel copyWith({
    int? likeCount,
    bool? likedByMe,
    bool? savedByMe,
    int? viewCount,
  }) =>
      Reel(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        bunnyVideoId: bunnyVideoId,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        createdAt: createdAt,
        durationSeconds: durationSeconds,
        linkedProductId: linkedProductId,
        linkedProductPriceMinor: linkedProductPriceMinor,
        linkedProductCurrency: linkedProductCurrency,
        likeCount: likeCount ?? this.likeCount,
        viewCount: viewCount ?? this.viewCount,
        commentCount: commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
        savedByMe: savedByMe ?? this.savedByMe,
        rankScore: rankScore,
      );

  @override
  List<Object?> get props => [id, likeCount, likedByMe, savedByMe, viewCount];
}

/// One page of feed results plus the cursor needed to fetch the next.
class ReelPage extends Equatable {
  const ReelPage({
    required this.reels,
    required this.cursor,
    required this.hasMore,
  });

  final List<Reel> reels;

  /// Opaque to the domain layer — it's a Firestore DocumentSnapshot under the
  /// hood, but nothing above the data layer needs to know that.
  final Object? cursor;
  final bool hasMore;

  @override
  List<Object?> get props => [reels, hasMore];
}
