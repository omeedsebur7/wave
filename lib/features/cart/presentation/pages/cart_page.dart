import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/features/cart/domain/entities/cart.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

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
                  padding: EdgeInsetsDirectional.all(s.x16),
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, __) => Divider(height: s.x24),
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
    final s = context.spacing;

    return Container(
      width: double.infinity,
      margin: EdgeInsetsDirectional.fromSTEB(
          s.x16, s.x12, s.x16, 0,), // FIXED: 0 to 0.0
      padding: EdgeInsetsDirectional.all(s.x12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color), // FIXED: 18 to 18.0
          SizedBox(width: s.x8),
          Expanded(
            child: Text(
              text,
              style: context.texts.caption.copyWith(color: color), 
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
    final s = context.spacing;
    final bloc = context.read<CartBloc>();
    final p = line.product;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
          child: CachedNetworkImage(
            imageUrl: p.primaryImage,
            width: s.x64 + s.x8, 
            height: s.x64 + s.x8,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: s.x64 + s.x8,
              height: s.x64 + s.x8,
              color: c.border,
            ),
          ),
        ),
        SizedBox(width: s.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: context.texts.body,),
              SizedBox(height: s.x4),
              Text(context.money(p.priceMinor, p.currency),
                  style: context.texts.title,),

              if (!p.inStock)
                Text(context.l10n.soldOut,
                    style: context.texts.caption.copyWith(color: c.error),) 
              else if (line.exceedsStock)
                Text(context.l10n.lowStockCount(p.stock),
                    style: context.texts.caption.copyWith(color: c.warning),), 

              SizedBox(height: s.x8),
              Row(
                children: [
                  WaveButton(
                    variant: WaveButtonVariant.icon,
                    size: WaveButtonSize.sm,
                    icon: Icons.remove,
                    label: context.l10n.decreaseQuantity,
                    onPressed: () => bloc.add(
                      CartQuantityChanged(p.id, line.quantity - 1),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: s.x12),
                    child: Text(context.number(line.quantity),
                        style: context.texts.label,), 
                  ),
                  WaveButton(
                    variant: WaveButtonVariant.icon,
                    size: WaveButtonSize.sm,
                    icon: Icons.add,
                    label: context.l10n.increaseQuantity,
                    onPressed: line.quantity >= p.stock
                        ? null
                        : () => bloc.add(
                              CartQuantityChanged(p.id, line.quantity + 1),
                            ),
                  ),
                  const Spacer(),
                  WaveButton( 
                    variant: WaveButtonVariant.tertiary,
                    size: WaveButtonSize.sm,
                    label: context.l10n.remove,
                    onPressed: () => bloc.add(CartItemRemoved(p.id)),
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

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        s.x16, 
        s.x16, 
        s.x16, 
        s.x24,
      ),
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
                    style: context.texts.caption,), 
                Text(
                  context.money(cart.totalMinor, cart.currency),
                  style: context.texts.headline, 
                ),
              ],
            ),
            SizedBox(height: s.x4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.l10n.deliveryArrangedNote,
                style: context.texts.caption, 
              ),
            ),
            SizedBox(height: s.x12),
            SizedBox(
              width: double.infinity,
              child: WaveButton( 
                label: context.l10n.checkout,
                expand: true,
                onPressed: cart.canCheckout
                    ? () => context.push(Routes.checkout)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
