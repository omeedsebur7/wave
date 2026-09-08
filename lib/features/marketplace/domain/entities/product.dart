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

  final int priceMinor;
  final String currency;

  final List<String> imageUrls;
  final int stock;
  final DateTime createdAt;

  final TrustTier sellerTier;
  final bool sellerKycVerified;

  final double ratingAvg;
  final int ratingCount;
  final int soldCount;
  final String? category;

  final bool negotiationEnabled;

  final String? linkedReelId;

  bool get inStock => stock > 0;

  bool get isLowStock => stock > 0 && stock <= 5;

  String get primaryImage => imageUrls.isEmpty ? '' : imageUrls.first;

  // FIXED: Added ALL missing fields to props to prevent state comparison bugs (§9)
  @override
  List<Object?> get props => [
        id,
        sellerId,
        sellerName,
        title,
        description,
        priceMinor,
        currency,
        imageUrls,
        stock,
        createdAt,
        sellerTier,
        sellerKycVerified,
        ratingAvg,
        ratingCount,
        soldCount,
        category,
        negotiationEnabled,
        linkedReelId,
      ];
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

enum ProductSort {
  newest,
  priceLowToHigh,
  priceHighToLow,
  topRated,
}
