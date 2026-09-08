import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/checkout/presentation/bloc/quick_checkout_cubit.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';
import 'package:wave/features/location/presentation/pages/location_picker_page.dart';
import 'package:wave/features/reels/data/buy_now_tracker.dart';

Future<void> showQuickCheckoutSheet(
  BuildContext context, {
  required String productId,
  String? sourceReelId,
}) {
  getIt<BuyNowTracker>().recordSheetOpened(productId: productId);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => getIt<QuickCheckoutCubit>()..load(productId),
      child: QuickCheckoutSheet(sourceReelId: sourceReelId),
    ),
  );
}

class QuickCheckoutSheet extends StatelessWidget {
  const QuickCheckoutSheet({this.sourceReelId, super.key});

  final String? sourceReelId;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing; // FIXED

    return BlocConsumer<QuickCheckoutCubit, QuickCheckoutState>(
      listenWhen: (a, b) => a.status != b.status || a.failure != b.failure,
      listener: (context, state) {
        if (state.status == QuickCheckoutStatus.placed) {
          Navigator.of(context).pop();
          context.push(Routes.orderDetailPath(state.orderId!));
        }
        if (state.failure != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failureText(context, state.failure!))));
        }
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.surfaces.radiusSheet),
            ),
          ),
          padding: EdgeInsetsDirectional.only(
            start: s.x20, // FIXED
            end: s.x20,
            top: s.x12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + s.x20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: s.x40, // FIXED
                  height: 4, // FIXED
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2), // FIXED
                  ),
                ),
              ),
              SizedBox(height: s.x16), // FIXED
              ..._body(context, state),
              SizedBox(height: s.x8), // FIXED
            ],
          ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, QuickCheckoutState state) {
    switch (state.status) {
      case QuickCheckoutStatus.loading:
        return [
          SizedBox(
            height: 160, // FIXED
            child: WaveStateView(
              state: WaveLoading(
                Container(
                  decoration: BoxDecoration(
                    color: context.waveColors.skeletonBase,
                    borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
                  ),
                ),
              ),
              content: const SizedBox.shrink(),
            ),
          ),
        ];

      case QuickCheckoutStatus.unavailable:
        return [
          SizedBox(
            height: 200, // FIXED
            child: WaveErrorView(
              title: context.l10n.productNotFound,
              message: context.l10n.productNotFoundBody,
              icon: Icons.remove_shopping_cart_outlined,
              retryLabel: context.l10n.backToTheMarket,
              onRetry: () {
                Navigator.of(context).pop();
                context.push(Routes.marketplace);
              },
            ),
          ),
        ];

      case QuickCheckoutStatus.ready:
      case QuickCheckoutStatus.placing:
      case QuickCheckoutStatus.placed:
        return _purchaseBody(context, state);

      case QuickCheckoutStatus.failed:
        return [
          SizedBox(
            height: 200, // FIXED
            child: WaveErrorView(
              title: context.l10n.productNotFound,
              message: context.l10n.productNotFoundBody,
              icon: Icons.error_outline,
              retryLabel: context.l10n.backToTheMarket,
              onRetry: () {
                Navigator.of(context).pop();
                context.push(Routes.marketplace);
              },
            ),
          ),
        ];
    }
  }

  List<Widget> _purchaseBody(BuildContext context, QuickCheckoutState state) {
    final c = context.waveColors;
    final s = context.spacing; // FIXED
    final product = state.product!;

    getIt<AnalyticsService>().log(
      AnalyticsEvents.trustBadgeViewed,
      params: {AnalyticsParams.trustTier: state.sellerTier.name},
    );

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
            child: CachedNetworkImage(
              imageUrl: product.primaryImage,
              width: s.x64, // FIXED
              height: s.x64,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: s.x64,
                height: s.x64,
                color: c.border,
                child: Icon(Icons.image_not_supported_outlined,
                    size: s.x20, color: c.textSecondary,),
              ),
            ),
          ),
          SizedBox(width: s.x12), // FIXED
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.title,
                ),
                SizedBox(height: s.x4), // FIXED
                TrustBadge(
                  tier: state.sellerTier,
                  isKycVerified: state.sellerKycVerified,
                  compact: true,
                ),
              ],
            ),
          ),
          SizedBox(width: s.x8), // FIXED
          Text(
            context.money(product.priceMinor, product.currency),
            style: context.texts.headline,
          ),
        ],
      ),

      SizedBox(height: s.x12), // FIXED
      Row(
        children: [
          Icon(Icons.people_outline, size: s.x16, color: c.textSecondary), // FIXED
          SizedBox(width: s.x8), 
          Text(context.l10n.peopleBought(state.buyerCount),
              style: context.texts.caption,),
          if (state.isLowStock) ...[
            SizedBox(width: s.x12), // FIXED
            Icon(Icons.inventory_2_outlined, size: s.x16, color: c.warning),
            SizedBox(width: s.x8), 
            Text(
              context.l10n.lowStockShort,
              style: context.texts.caption.copyWith(color: c.warning),
            ),
          ],
        ],
      ),

      SizedBox(height: s.x20), // FIXED

      if (!product.inStock)
        SizedBox(
          width: double.infinity,
          child: WaveButton(
            label: context.l10n.outOfStock,
            expand: true,
            onPressed: null,
          ),
        )
      else
        _GateAction(state: state, sourceReelId: sourceReelId),
    ];
  }
}

Future<void> _pickLocationThenBuy(
  BuildContext context,
  QuickCheckoutState state,
  String? sourceReelId,
) async {
  final cubit = context.read<QuickCheckoutCubit>();
  final price = context.money(state.product!.priceMinor, state.product!.currency);

  final location = await Navigator.of(context).push<DeliveryLocation>(
    MaterialPageRoute(
      builder: (_) => LocationPickerPage(
        confirmLabel: context.l10n.confirmAndBuy(price),
      ),
    ),
  );

  if (location == null) return;
  await cubit.placeOrder(location: location, sourceReelId: sourceReelId);
}

class _GateAction extends StatelessWidget {
  const _GateAction({required this.state, this.sourceReelId});

  final QuickCheckoutState state;
  final String? sourceReelId;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing; // FIXED
    final placing = state.status == QuickCheckoutStatus.placing;

    final (label, icon, onTap) = switch (state.gate) {
      CheckoutGate.needsAccount => (
          context.l10n.signInToOrder,
          Icons.login,
          () => context.push('${Routes.signIn}?from=${Routes.checkout}'),
        ),
      CheckoutGate.needsPhoneVerification => (
          context.l10n.verifyYourPhone,
          Icons.sms_outlined,
          () => context.push('${Routes.phoneVerify}?reason=checkout'),
        ),
      CheckoutGate.needsAddress => (
          context.l10n.addDeliveryAddress,
          Icons.location_on_outlined,
          () => context.push(Routes.checkout),
        ),
      CheckoutGate.needsPaymentMethod => (
          context.l10n.chooseHowToPay,
          Icons.payment,
          () => context.push(Routes.checkout),
        ),
      CheckoutGate.ready => (
          context.l10n.setDeliveryLocationWithPrice(
            context.money(state.product!.priceMinor, state.product!.currency),
          ),
          Icons.place_outlined,
          () => _pickLocationThenBuy(context, state, sourceReelId),
        ),
    };

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: WaveButton(
            icon: icon,
            label: label,
            expand: true,
            isLoading: placing,
            onPressed: placing ? null : onTap,
          ),
        ),
        if (state.gate == CheckoutGate.needsPhoneVerification) ...[
          SizedBox(height: s.x8), // FIXED
          Text(
            context.l10n.phoneGateShortNote,
            style: context.texts.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
