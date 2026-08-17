import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

class ProductDto {
  const ProductDto(this.id, this.json);

  factory ProductDto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ProductDto(doc.id, doc.data() ?? const {});

  final String id;
  final Map<String, dynamic> json;

  Product toDomain() => Product(
        id: id,
        sellerId: json['seller_id'] as String? ?? '',
        sellerName: json['seller_name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'IQD',
        imageUrls: [
          for (final u in (json['image_urls'] as List? ?? [])) u as String,
        ],
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        createdAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        sellerTier: _tier(json['seller_tier'] as String?),
        sellerKycVerified: json['seller_kyc_verified'] as bool? ?? false,
        ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
        soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
        category: json['category'] as String?,
        negotiationEnabled: json['negotiation_enabled'] as bool? ?? false,
        linkedReelId: json['linked_reel_id'] as String?,
      );

  /// An unknown tier from a newer backend degrades to "no badge" rather than
  /// crashing an older client. Showing nothing is always safe; guessing is not.
  static TrustTier _tier(String? raw) => TrustTier.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => TrustTier.newSeller,
      );
}
