import 'package:equatable/equatable.dart';

/// What a seller actually needs to know.
///
/// Deliberately narrow. §6 collects both Bunny per-video analytics and the
/// Firebase Buy-Now funnel, which together could produce dozens of numbers —
/// and a dashboard of dozens of numbers is one nobody reads. These are the
/// figures that change what a seller does next.
class SellerStats extends Equatable {
  const SellerStats({
    required this.periodDays,
    this.reelViews = 0,
    this.buyNowTaps = 0,
    this.ordersPlaced = 0,
    this.revenueMinor = 0,
    this.currency = 'IQD',
    this.ordersAwaitingAction = 0,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.topReels = const [],
  });

  final int periodDays;

  final int reelViews;
  final int buyNowTaps;
  final int ordersPlaced;
  final int revenueMinor;
  final String currency;

  /// Surfaced first, because it is the only number that is also a task.
  final int ordersAwaitingAction;

  final double avgRating;
  final int ratingCount;
  final List<ReelPerformance> topReels;

  /// Views that turned into a Buy Now tap. The first half of the funnel: is the
  /// Reel making anyone *want* the thing?
  double get tapThroughRate => reelViews == 0 ? 0 : buyNowTaps / reelViews;

  /// Taps that turned into an order. The second half: having wanted it, did
  /// anything stop them?
  ///
  /// Splitting the funnel here matters because the two failures need opposite
  /// fixes. A low tap-through means the Reel is not selling the product. A high
  /// tap-through with low completion means the checkout is losing people who
  /// had already decided to buy — usually price, stock, or the verification
  /// gate on a first order.
  double get tapToOrderRate => buyNowTaps == 0 ? 0 : ordersPlaced / buyNowTaps;

  /// End to end. Kept alongside the two halves rather than instead of them.
  double get overallConversion => reelViews == 0 ? 0 : ordersPlaced / reelViews;

  bool get hasEnoughDataToJudge => reelViews >= 100;

  @override
  List<Object?> get props => [
        periodDays,
        reelViews,
        buyNowTaps,
        ordersPlaced,
        revenueMinor,
        ordersAwaitingAction,
      ];
}

class ReelPerformance extends Equatable {
  const ReelPerformance({
    required this.reelId,
    required this.caption,
    required this.thumbnailUrl,
    this.views = 0,
    this.buyNowTaps = 0,
    this.orders = 0,
    this.hasLinkedProduct = false,
  });

  final String reelId;
  final String caption;
  final String thumbnailUrl;
  final int views;
  final int buyNowTaps;
  final int orders;
  final bool hasLinkedProduct;

  double get conversion => views == 0 ? 0 : orders / views;

  /// A well-watched Reel with nothing to buy is the single most actionable
  /// finding this screen can surface — the fix is one tap and the audience
  /// already exists.
  bool get isWastedAudience => !hasLinkedProduct && views >= 500;

  @override
  List<Object?> get props => [reelId, views, buyNowTaps, orders];
}
