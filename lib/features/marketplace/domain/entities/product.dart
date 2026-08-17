import 'package:equatable/equatable.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.priceMinor,
    required this.currency,
    required this.imageUrls,
    required this.stock,
    required this.createdAt,
    this.sellerTier = TrustTier.newSeller,
    this.sellerKycVerified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.soldCount = 0,
    this.category,
    this.negotiationEnabled = false,
    this.linkedReelId,
  });

  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;

  /// Minor units in an int, always. Currency in a double is how you end up
  /// charging someone 24999.999999 IQD.
  final int priceMinor;
  final String currency;

  final List<String> imageUrls;
  final int stock;
  final DateTime createdAt;

  /// Denormalised onto the product so a grid of 20 products doesn't need 20
  /// extra reads of the seller profile just to draw the badges.
  final TrustTier sellerTier;
  final bool sellerKycVerified;

  final double ratingAvg;
  final int ratingCount;
  final int soldCount;
  final String? category;

  /// P2 — bidding. The flag lives in the model now so the Buy Now sheet can
  /// render its secondary action without a schema migration later.
  final bool negotiationEnabled;

  final String? linkedReelId;

  bool get inStock => stock > 0;

  /// The threshold the low-stock warning colour keys off. Deliberately a
  /// business rule in one place rather than `stock < 5` scattered across
  /// three widgets.
  bool get isLowStock => stock > 0 && stock <= 5;

  String get primaryImage => imageUrls.isEmpty ? '' : imageUrls.first;

  @override
  List<Object?> get props => [id, priceMinor, stock, ratingAvg, ratingCount];
}

class ProductPage extends Equatable {
  const ProductPage({
    required this.products,
    required this.cursor,
    required this.hasMore,
  });

  final List<Product> products;
  final Object? cursor;
  final bool hasMore;

  @override
  List<Object?> get props => [products, hasMore];
}

/// Sort options exposed in the Marketplace. Kept small on purpose — every
/// option needs its own composite index, and an index costs storage on every
/// write forever.
///
/// Deliberately carries no `label`. An enum constant cannot reach a
/// `BuildContext`, so a label defined here is guaranteed to be the one string on
/// the screen that never translates — the same structural mistake already found
/// and removed from `ReportReason`, `SellerOrderFilter`, `NotificationChannel`
/// and `PaymentRail`. Resolved at render by `productSortLabel`.
enum ProductSort {
  newest,
  priceLowToHigh,
  priceHighToLow,
  topRated,
}
