import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/dates.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/location/presentation/widgets/delivery_location_card.dart';
import 'package:wave/features/orders/data/receipt_service.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/orders/domain/repositories/order_repository.dart';
import 'package:wave/features/orders/presentation/receipt_strings.dart';
import 'package:wave/features/orders/presentation/widgets/order_tracker.dart';
import 'package:wave/features/reviews/domain/repositories/review_repository.dart';
import 'package:wave/features/reviews/presentation/widgets/rating_sheet.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<OrderRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.orderNumber(orderId.substring(0, 6).toUpperCase()),
        ),
      ),
      body: StreamBuilder<Order?>(
        stream: repo.watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // FIXED: Replaced CircularProgressIndicator with WaveStateView
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()), 
              content: SizedBox.shrink(),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return WaveErrorView(
              title: context.l10n.orderNotFound,
              message: context.l10n.orderNotFoundBody,
              icon: Icons.receipt_long_outlined,
            );
          }

          return _OrderDetailView(order: order);
        },
      ),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return ListView(
      padding: const EdgeInsetsDirectional.all(WaveSpacing.x20),
      children: [
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: WaveSpacing.x24, 
            horizontal: WaveSpacing.x16,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
          ),
          child: Column(
            children: [
              OrderTracker(stage: order.stage),
              const SizedBox(height: WaveSpacing.x16),
              Text(
                _stageExplanation(context, order),
                style: context.texts.caption, // FIXED: bodySmall to caption
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: WaveSpacing.x24),
        DeliveryLocationCard(location: order.deliveryLocation),
        const SizedBox(height: WaveSpacing.x24),

        Text(context.l10n.items, style: context.texts.title), // FIXED: titleMedium to title
        const SizedBox(height: WaveSpacing.x12),

        for (final item in order.items)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: context.texts.body), // FIXED
                      Text(
                        context.l10n.quantityTimesTitle(
                          item.quantity,
                          context.money(item.unitPriceMinor, order.currency),
                        ),
                        style: context.texts.caption, // FIXED
                      ),
                    ],
                  ),
                ),
                Text(
                  context.money(item.lineTotalMinor, order.currency),
                  style: context.texts.body, // FIXED
                ),
              ],
            ),
          ),

        const Divider(height: WaveSpacing.x32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.totalPaid, style: context.texts.title), // FIXED
            Text(
              context.money(order.totalMinor, order.currency),
              style: context.texts.title, // FIXED
            ),
          ],
        ),

        const SizedBox(height: WaveSpacing.x8),
        Text(
          context.l10n.orderedOn(_formatDate(context, order.createdAt)),
          style: context.texts.caption, // FIXED
        ),

        const SizedBox(height: WaveSpacing.x32),

        if (order.canCancel)
          WaveButton(
            variant: WaveButtonVariant.destructive,
            expand: true,
            label: context.l10n.cancelThisOrder,
            onPressed: () => _confirmCancel(context),
          ),

        if (order.canBeRated) ...[
          Text(context.l10n.howDidItGo, style: context.texts.title), // FIXED
          const SizedBox(height: WaveSpacing.x4),
          Text(
            context.l10n.ratingHelpsNextBuyer,
            style: context.texts.caption, // FIXED
          ),
          const SizedBox(height: WaveSpacing.x12),
          WaveButton(
            expand: true,
            label: context.l10n.rateThisOrder,
            onPressed: () => _rate(context),
          ),
        ],

        const SizedBox(height: WaveSpacing.x12),
        WaveButton(
          variant: WaveButtonVariant.tertiary,
          icon: Icons.receipt_outlined,
          label: context.l10n.receipt,
          onPressed: () => _shareReceipt(context),
        ),

        const SizedBox(height: WaveSpacing.x40),
      ],
    );
  }

  static String _stageExplanation(BuildContext context, Order order) {
    if (order.stage == CustomerOrderStage.confirmed) {
      switch (order.internalStatus) {
        case OrderInternalStatus.pendingPayment:
        case OrderInternalStatus.paymentProcessing:
          return context.l10n.stagePendingPaymentBody;
        case OrderInternalStatus.paymentFailed:
          return context.l10n.stagePaymentFailedBody;
        case OrderInternalStatus.confirmed:
        case OrderInternalStatus.packed:
        case OrderInternalStatus.handedToCourier:
        case OrderInternalStatus.outForDelivery:
        case OrderInternalStatus.delivered:
        case OrderInternalStatus.cancelled:
          break;
        case OrderInternalStatus.refunded:
          break;
      }
    }

    return switch (order.stage) {
        CustomerOrderStage.confirmed => context.l10n.stageConfirmedBody,
        CustomerOrderStage.onTheWay => context.l10n.stageOnTheWayBody,
        CustomerOrderStage.delivered => context.l10n.stageDeliveredBody,
        CustomerOrderStage.cancelled => context.l10n.stageCancelledBody,
      };
  }

  static String _formatDate(BuildContext context, DateTime d) =>
      Dates.short(context, d);

  Future<void> _shareReceipt(BuildContext context) async {
    final strings = receiptStringsFor(context, order);
    final bytes = await const ReceiptService().generate(
      order: order,
      sellerName: context.l10n.seller,
      strings: strings,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'wave-receipt-${order.id.substring(0, 6)}.pdf',
    );
  }

  // FIXED: Replaced AlertDialog with our signature WaveSheet physics!
  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await WaveSheet.show<bool>(
      context: context,
      title: context.l10n.cancelThisOrderQ,
      builder: (context) => Text(
        context.l10n.cancelOrderBuyerBody,
        style: context.texts.body,
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WaveButton(
            variant: WaveButtonVariant.destructive,
            expand: true,
            label: context.l10n.cancelOrder,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: WaveSpacing.x8),
          WaveButton(
            variant: WaveButtonVariant.tertiary,
            expand: true,
            label: context.l10n.keepIt,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await getIt<OrderRepository>().cancel(order.id);
    if (!context.mounted) return;

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(context, f)))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.orderCancelled)),
      ),
    );
  }

  Future<void> _rate(BuildContext context) async {
    final rating = await showRatingSheet(
      context,
      target: RatingTarget.seller,
      targetName: context.l10n.thisSeller,
    );
    if (rating == null || !context.mounted) return;

    final result = await getIt<ReviewRepository>().submitSellerRating(
      sellerId: order.sellerId,
      orderId: order.id,
      rating: rating,
    );
    if (!context.mounted) return;

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(context, f)))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ratingSubmitted)),
      ),
    );
  }
}
