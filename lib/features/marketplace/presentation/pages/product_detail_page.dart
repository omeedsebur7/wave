import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_to_state.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_motion.dart';
import 'package:wave/core/theme/wave_hero_tags.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_quantity_stepper.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_hero.dart';
import 'package:wave/design_system/components/wave_price.dart';
import 'package:wave/design_system/components/wave_skeletons.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/design_system/components/wave_ugc_text.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/presentation/bloc/product_detail_bloc.dart';
import 'package:wave/l10n/generated/app_localizations.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    required this.productId,
    this.preloaded,
    this.heroScope = 'main',
    super.key,
  });

  final String productId;
  final Product? preloaded;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductDetailBloc>()
        ..add(ProductDetailRequested(productId, preloaded: preloaded)),
      child: _ProductDetailView(productId: productId, heroScope: heroScope),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({required this.productId, required this.heroScope});

  final String productId;
  final String heroScope;

  void _retry(BuildContext context) =>
      context.read<ProductDetailBloc>().add(ProductDetailRequested(productId));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      builder: (context, state) {
        final product = state.product;
        final view = _map(context, state);

        return Scaffold(
          backgroundColor: context.waveColors.background,
          body: WaveStateView(
            state: view,
            content: product == null
                ? const SizedBox.shrink()
                : _Body(
                    product: product,
                    productId: productId,
                    heroScope: heroScope,
                  ),
          ),
          bottomNavigationBar: view is WaveContent && product != null
              ? _StickyCta(product: product)
              : null,
        );
      },
    );
  }

  WaveState _map(BuildContext context, ProductDetailState s) {
    final failure = s.failure;

    if (s.status == ProductDetailStatus.failure && failure != null) {
      final kind = waveFailureKind(failure);
      return WaveFailure(
        kind,
        onRetry: isRetryable(kind) ? () => _retry(context) : null,
      );
    }

    if (s.product == null) {
      return WaveLoading(WaveSkeletons.productDetail(context));
    }

    return const WaveContent();
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.product,
    required this.productId,
    required this.heroScope,
  });

  final Product product;
  final String productId;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final t = context.texts;
    final s = context.spacing;
    final l = AppLocalizations.of(context);

    return CustomScrollView(
      slivers: [
        _PdpAppBar(
          product: product,
          productId: productId,
          heroScope: heroScope,
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.all(s.x16),
          sliver: SliverList.list(
            children: [
              WaveUgcText(product.title, style: t.headline),
              SizedBox(height: s.x8),
              WavePrice(amountMinor: product.priceMinor),
              SizedBox(height: s.x8),
              StockLine(product: product),
              SizedBox(height: s.x24),
              _SellerBlock(product: product),
              SizedBox(height: s.x24),
              Text(l.pdpDescription, style: t.title),
              SizedBox(height: s.x8),
              WaveUgcText(product.description, style: t.body),
              SizedBox(height: s.x32),
            ],
          ),
        ),
      ],
    );
  }
}

class StockLine extends StatelessWidget {
  const StockLine({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final l = AppLocalizations.of(context);

    final (IconData icon, String text, Color color) = switch (product) {
      _ when !product.inStock => (
          Icons.remove_shopping_cart_outlined,
          l.stockOut,
          c.error,
        ),
      _ when product.isLowStock => (
          Icons.local_fire_department_outlined,
          l.stockLow(product.stock),
          c.warning,
        ),
      _ => (Icons.check_circle_outline, l.stockIn, c.success),
    };

    return Row(
      children: [
        Icon(icon, size: s.x16, color: color),
        SizedBox(width: s.x4),
        Text(text, style: t.caption.copyWith(color: color)),
      ],
    );
  }
}

class QuantitySheet extends StatelessWidget {
  const QuantitySheet({
    required this.product,
    required this.quantity,
    super.key,
  });

  final Product product;
  final ValueNotifier<int> quantity;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final l = AppLocalizations.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: quantity,
      builder: (context, qty, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          WaveUgcText(
            product.title,
            style: t.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: s.x8),
          StockLine(product: product),
          SizedBox(height: s.x24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.quantityLabel, style: t.bodyStrong),
              WaveQuantityStepper(
                value: qty,
                max: product.stock,
                onChanged: (v) => quantity.value = v,
              ),
            ],
          ),
          SizedBox(height: s.x24),
          Divider(color: c.divider),
          SizedBox(height: s.x16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.subtotal, style: t.body),
              WavePrice(amountMinor: product.priceMinor * qty),
            ],
          ),
        ],
      ),
    );
  }
}

class _StickyCta extends StatelessWidget {
  const _StickyCta({required this.product});

  final Product product;

  Future<void> _openQuantitySheet(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final cart = context.read<CartBloc>();
    final quantity = ValueNotifier<int>(1);

    try {
      final chosen = await WaveSheet.show<int>(
        context: context,
        title: l.quantityTitle,
        builder: (_) => QuantitySheet(product: product, quantity: quantity),
        footer: ValueListenableBuilder<int>(
          valueListenable: quantity,
          builder: (sheetContext, qty, _) => WaveButton(
            label: l.pdpAddToCart,
            expand: true,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(sheetContext).pop(qty);
            },
          ),
        ),
      );

      if (chosen == null) return;
      cart.add(CartItemAdded(product, quantity: chosen));
    } finally {
      quantity.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;
    final l = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(s.x16, s.x12, s.x16, s.x12),
          child: WaveButton(
            label: product.inStock ? l.pdpAddToCart : l.stockOut,
            expand: true,
            onPressed:
                product.inStock ? () => _openQuantitySheet(context) : null,
          ),
        ),
      ),
    );
  }
}

class _PdpAppBar extends StatelessWidget {
  const _PdpAppBar({
    required this.product,
    required this.productId,
    required this.heroScope,
  });

  final Product product;
  final String productId;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final l = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final expanded = width * 5 / 4;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expanded,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _ScrimIconButton(
        icon: Icons.arrow_back,
        tooltip: l.commonBack,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsed = MediaQuery.paddingOf(context).top + kToolbarHeight;
          final range = expanded - collapsed;
          final t01 = range <= 0
              ? 1.0
              : (1 - (constraints.maxHeight - collapsed) / range)
                  .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _Gallery(
                product: product,
                productId: productId,
                heroScope: heroScope,
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: Curves.easeIn.transform(t01),
                  child: ColoredBox(color: c.surface),
                ),
              ),
              if (t01 > 0.5)
                PositionedDirectional( // FIXED: Replaced Positioned with PositionedDirectional (§9)
                  bottom: 0,
                  start: 0,
                  end: 0,
                  height: collapsed,
                  child: Opacity(
                    opacity: ((t01 - 0.5) * 2).clamp(0.0, 1.0),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: context.spacing.x64,
                          end: context.spacing.x16,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: WaveUgcText(
                            product.title,
                            style: t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScrimIconButton extends StatelessWidget {
  const _ScrimIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: s.x4),
      child: Material(
        color: c.scrim,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: Icon(icon),
          color: c.onScrim,
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.product,
    required this.productId,
    required this.heroScope,
  });

  final Product product;
  final String productId;
  final String heroScope;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;
    final l = AppLocalizations.of(context);
    final images = widget.product.imageUrls;

    if (images.isEmpty) {
      return ColoredBox(
        color: c.surfaceSunken,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: s.x48,
          color: c.textTertiary,
        ),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final target = (MediaQuery.sizeOf(context).width * dpr).round();

    return RepaintBoundary(
      child: Semantics(
        label: l.pdpImageGallery(_index + 1, images.length),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final image = CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  memCacheWidth: target,
                  fadeInDuration:
                      WaveMotion.resolve(context, context.motion.base),
                  placeholder: (_, __) => ColoredBox(color: c.skeletonBase),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: c.surfaceSunken,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: c.textTertiary,
                    ),
                  ),
                );

                return i == 0
                    ? WaveHero(
                        tag: WaveHeroTags.productImage(
                          widget.productId,
                          scope: widget.heroScope,
                        ),
                        fromRadius: context.surfaces.radiusCard,
                        toRadius: 0,
                        child: image,
                      )
                    : image;
              },
            ),
            if (images.length > 1)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(bottom: s.x16),
                  child: _Dots(count: images.length, index: _index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: WaveMotion.resolve(context, context.motion.fast),
            curve: context.motion.standard,
            margin: EdgeInsetsDirectional.symmetric(horizontal: s.x2),
            width: active ? s.x16 : s.x8,
            height: s.x8,
            decoration: BoxDecoration(
              color: active ? c.onScrim : c.onScrim.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(context.surfaces.radiusFull),
            ),
          );
        }),
      ),
    );
  }
}

class _SellerBlock extends StatelessWidget {
  const _SellerBlock({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final l = AppLocalizations.of(context);
    final name = product.sellerName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
        boxShadow: c.shadowResting,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(s.x12),
        child: Row(
          children: [
            Container(
              width: s.x40,
              height: s.x40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSubtle,
                shape: BoxShape.circle,
              ),
              child: Text(
                name.isEmpty ? '?' : name.characters.first,
                style: t.label.copyWith(color: c.accent),
              ),
            ),
            SizedBox(width: s.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.pdpSoldBy, style: t.caption),
                  SizedBox(height: s.x2),
                  WaveUgcText(
                    name,
                    style: t.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: s.x4),
                  TrustBadge(
                    tier: product.sellerTier,
                    isKycVerified: product.sellerKycVerified,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
