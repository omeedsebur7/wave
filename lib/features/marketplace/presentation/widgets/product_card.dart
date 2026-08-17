import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_skeleton.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.isFavourite,
    required this.onTap,
    required this.onFavouriteToggle,
    super.key,
  });

  final Product product;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onFavouriteToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Semantics(
      button: true,
      // Assembled from localized parts rather than interpolated English. A
      // screen reader announcing "out of stock" in English to an Arabic user
      // is the one string in this widget they cannot see to work around.
      label: [
        context.l10n.productCardSemantic(
          product.title,
          context.money(product.priceMinor, product.currency),
        ),
        if (product.isLowStock) context.l10n.lowStockShort,
        if (!product.inStock) context.l10n.outOfStock,
      ].join(', '),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(WaveSurfaces.radiusCard),
                      child: CachedNetworkImage(
                        imageUrl: product.primaryImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const WaveSkeleton(
                          width: double.infinity,
                          height: double.infinity,
                          radius: WaveSurfaces.radiusCard,
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: c.border,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    if (!product.inStock)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius:
                              BorderRadius.circular(WaveSurfaces.radiusCard),
                        ),
                        // Not const: the label is a runtime lookup. The inner
                        // TextStyle still is.
                        child: Center(
                          child: Text(
                            context.l10n.outOfStock,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onFavouriteToggle,
                          iconSize: 20,
                          constraints:
                              const BoxConstraints(minWidth: 48, minHeight: 48),
                          icon: Icon(
                            isFavourite ? Icons.favorite : Icons.favorite_border,
                            color: isFavourite ? c.error : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                context.money(product.priceMinor, product.currency),
                style: context.texts.titleMedium,
              ),

              if (product.isLowStock) ...[
                const SizedBox(height: 2),
                Text(
                  context.l10n.lowStockCount(product.stock),
                  style: context.texts.bodySmall?.copyWith(color: c.warning),
                ),
              ],

              const SizedBox(height: 6),
              // The trust badge on the card is the whole point of the tier
              // system: it lets a buyer judge a stranger before they tap.
              Row(
                children: [
                  if (product.sellerTier.hasBadge || product.sellerKycVerified)
                    TrustBadge(
                      tier: product.sellerTier,
                      isKycVerified: product.sellerKycVerified,
                      compact: true,
                    ),
                  if (product.ratingCount > 0) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.star, size: 13, color: c.textSecondary),
                    const SizedBox(width: 2),
                    Text(
                      context.decimal(product.ratingAvg),
                      style: context.texts.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
