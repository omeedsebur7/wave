import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/cart/domain/entities/cart.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cart)),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final cart = state.cart;

          if (cart.isEmpty) {
            return WaveErrorView.empty(
              title: context.l10n.cartEmpty,
              message: context.l10n.cartEmptyBody,
              icon: Icons.shopping_bag_outlined,
              retryLabel: context.l10n.browseTheMarket,
              onRetry: () => context.go(Routes.marketplace),
            );
          }

          return Column(
            children: [
              if (cart.hasMultipleSellers)
                _Banner(
                  icon: Icons.info_outline,
                  color: c.info,
                  text: context.l10n.cartMultiSellerWarning,
                ),

              if (cart.problemLines.isNotEmpty)
                _Banner(
                  icon: Icons.warning_amber_outlined,
                  color: c.warning,
                  text: context.l10n.cartStockWarning,
                ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, i) => _CartRow(line: cart.lines[i]),
                ),
              ),

              _Summary(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final bloc = context.read<CartBloc>();
    final p = line.product;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
          child: CachedNetworkImage(
            imageUrl: p.primaryImage,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 72,
              height: 72,
              color: c.border,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium,),
              const SizedBox(height: 4),
              Text(context.money(p.priceMinor, p.currency),
                  style: context.texts.titleMedium,),

              if (!p.inStock)
                Text(context.l10n.soldOut,
                    style: context.texts.bodySmall?.copyWith(color: c.error),)
              else if (line.exceedsStock)
                Text(context.l10n.lowStockCount(p.stock),
                    style: context.texts.bodySmall?.copyWith(color: c.warning),),

              const SizedBox(height: 8),
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    semanticLabel: context.l10n.decreaseQuantity,
                    onTap: () => bloc.add(
                      CartQuantityChanged(p.id, line.quantity - 1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(context.number(line.quantity),
                        style: context.texts.labelMedium,),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    semanticLabel: context.l10n.increaseQuantity,
                    onTap: line.quantity >= p.stock
                        ? null
                        : () => bloc.add(
                              CartQuantityChanged(p.id, line.quantity + 1),
                            ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => bloc.add(CartItemRemoved(p.id)),
                    child: Text(context.l10n.remove),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      tooltip: semanticLabel,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.itemsCount(cart.itemCount),
                    style: context.texts.bodySmall,),
                Text(
                  context.money(cart.totalMinor, cart.currency),
                  style: context.texts.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.l10n.deliveryArrangedNote,
                style: context.texts.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cart.canCheckout
                    ? () => context.push(Routes.checkout)
                    : null,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(context.l10n.checkout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
