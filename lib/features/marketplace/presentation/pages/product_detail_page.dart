import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/directional_chevron.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/core/widgets/wave_skeleton.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/presentation/bloc/product_detail_bloc.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:wave/features/reviews/presentation/widgets/review_list.dart';

/// Product detail.
///
/// The static pre-rendered image is the real default at launch, not a fallback
/// (§3.6). model_viewer_plus is Phase 2 — turning it on before a pipeline
/// exists that produces usable .glb assets would ship an empty viewer, which is
/// worse than a good photograph.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.productId, this.preloaded, super.key});

  final String productId;

  /// Handed over by the grid when available, so the page paints instantly
  /// rather than flashing a skeleton for data the previous screen already had.
  final Product? preloaded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductDetailBloc>()
        ..add(ProductDetailRequested(productId, preloaded: preloaded)),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      builder: (context, state) {
        final product = state.product;

        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: state.status == ProductDetailStatus.failure
                ? WaveErrorView(
                    title: context.l10n.productNotFound,
                    message: context.l10n.productNotFoundBody,
                    icon: Icons.remove_shopping_cart_outlined,
                    retryLabel: context.l10n.backToTheMarket,
                    onRetry: () => context.go(Routes.marketplace),
                  )
                : const _DetailSkeleton(),
          );
        }

        return _Loaded(state: state, product: product);
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.product});

  final ProductDetailState state;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: context.l10n.shareThisItem,
                onPressed: () => Share.share(
                  // A deep link, so the recipient lands on the product rather
                  // than the app's front page (§5.2).
                  '${product.title} on WAVE\n'
                  'https://wave.app${Routes.productDetailPath(product.id)}',
                  subject: product.title,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: context.l10n.reportThisListing,
                onPressed: () => showReportSheet(
                  context,
                  targetType: ReportTargetType.product,
                  targetId: product.id,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrls.isEmpty
                  ? ColoredBox(color: c.border)
                  : PageView.builder(
                      itemCount: product.imageUrls.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: product.imageUrls[i],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => ColoredBox(color: c.border),
                      ),
                    ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                Text(product.title, style: context.texts.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  context.money(product.priceMinor, product.currency),
                  style: context.texts.displayLarge,
                ),
                const SizedBox(height: 8),

                if (!product.inStock)
                  _StockLine(text: context.l10n.outOfStock, color: c.error)
                else if (product.isLowStock)
                  _StockLine(
                    text: context.l10n.lowStockCount(product.stock),
                    color: c.warning,
                  )
                else
                  _StockLine(text: context.l10n.inStock, color: c.success),

                const SizedBox(height: 20),

                // The seller card sits above the description on purpose: who
                // you are buying from is the question a buyer is actually
                // asking on this screen.
                InkWell(
                  onTap: () =>
                      context.push(Routes.sellerProfilePath(product.sellerId)),
                  borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.border),
                      borderRadius:
                          BorderRadius.circular(WaveSurfaces.radiusCard),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: c.border,
                          child: Text(
                            product.sellerName.isEmpty
                                ? '?'
                                : product.sellerName[0].toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.sellerName,
                                style: context.texts.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              TrustBadge(
                                tier: product.sellerTier,
                                isKycVerified: product.sellerKycVerified,
                              ),
                            ],
                          ),
                        ),
                        DirectionalChevron(color: c.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(context.l10n.aboutThisItem,
                    style: context.texts.titleMedium,),
                const SizedBox(height: 8),
                Text(product.description, style: context.texts.bodyMedium),

                const SizedBox(height: 32),
                Text(context.l10n.reviews, style: context.texts.titleMedium),
                const SizedBox(height: 8),
                ReviewList(
                  reviews: state.reviews,
                  average: state.summary.average,
                  distribution: state.summary.distribution,
                ),

                const SizedBox(height: 96),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: product.inStock
                      ? () => _addToCart(context, showConfirmation: true)
                      : null,
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(context.l10n.addToCart),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: product.inStock
                      ? () {
                          _addToCart(context, showConfirmation: false);
                          context.push(Routes.checkout);
                        }
                      : null,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(context.l10n.buyNow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, {required bool showConfirmation}) {
    context.read<CartBloc>().add(CartItemAdded(product));
    if (!showConfirmation) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.addedToCart),
        action: SnackBarAction(
          label: context.l10n.viewCart,
          onPressed: () => context.push(Routes.cart),
        ),
      ),
    );
  }
}

class _StockLine extends StatelessWidget {
  const _StockLine({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(text, style: context.texts.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        WaveSkeleton(width: double.infinity, height: 320, radius: 0),
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaveSkeleton(width: 220, height: 24),
              SizedBox(height: 12),
              WaveSkeleton(width: 140, height: 32),
              SizedBox(height: 24),
              WaveSkeleton(width: double.infinity, height: 72,
                  radius: WaveSurfaces.radiusCard,),
            ],
          ),
        ),
      ],
    );
  }
}
