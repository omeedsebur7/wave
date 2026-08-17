import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/dates.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/location/presentation/widgets/delivery_location_card.dart';
import 'package:wave/features/orders/data/receipt_service.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/orders/domain/repositories/order_repository.dart';
import 'package:wave/features/orders/presentation/receipt_strings.dart';
import 'package:wave/features/orders/presentation/widgets/order_tracker.dart';
import 'package:wave/features/reviews/domain/repositories/review_repository.dart';
import 'package:wave/features/reviews/presentation/widgets/rating_sheet.dart';

/// Single order (§5.2): the 3-step tracker, a digital receipt, cancellation
/// while still in Confirmed, and the seller-rating prompt once delivered.
///
/// Streamed rather than fetched once. An order's status changes while someone
/// is looking at it, and making them pull-to-refresh to find out whether it
/// shipped is exactly the friction the simplified tracker exists to remove.
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
            return const Center(child: CircularProgressIndicator());
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
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
          ),
          child: Column(
            children: [
              OrderTracker(stage: order.stage),
              const SizedBox(height: 16),
              Text(
                _stageExplanation(context, order),
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        // Shown to the buyer too. Someone who mis-set a pin needs to be able
        // to see that before the courier does.
        DeliveryLocationCard(location: order.deliveryLocation),
        const SizedBox(height: 24),

        Text(context.l10n.items, style: context.texts.titleMedium),
        const SizedBox(height: 12),

        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: context.texts.bodyMedium),
                      Text(
                        context.l10n.quantityTimesTitle(
                          item.quantity,
                          context.money(item.unitPriceMinor, order.currency),
                        ),
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  context.money(item.lineTotalMinor, order.currency),
                  style: context.texts.bodyMedium,
                ),
              ],
            ),
          ),

        const Divider(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.totalPaid, style: context.texts.titleMedium),
            Text(
              context.money(order.totalMinor, order.currency),
              style: context.texts.titleMedium,
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(
          context.l10n.orderedOn(_formatDate(context, order.createdAt)),
          style: context.texts.bodySmall,
        ),

        const SizedBox(height: 32),

        if (order.canCancel)
          OutlinedButton(
            onPressed: () => _confirmCancel(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.error,
              side: BorderSide(color: c.error.withValues(alpha: 0.5)),
              minimumSize: const Size(0, 52),
            ),
            child: Text(context.l10n.cancelThisOrder),
          ),

        if (order.canBeRated) ...[
          Text(context.l10n.howDidItGo, style: context.texts.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.l10n.ratingHelpsNextBuyer,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _rate(context),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: Text(context.l10n.rateThisOrder),
          ),
        ],

        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _shareReceipt(context),
          icon: const Icon(Icons.receipt_outlined, size: 18),
          label: Text(context.l10n.receipt),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  /// One plain sentence per stage. The tracker shows where the order is; this
  /// says what that means and what happens next, which is the actual question
  /// behind "where's my order".
  /// The explanation under the tracker.
  ///
  /// Still three customer-facing steps (§5.2) — a fourth would undo the
  /// simplification the whole tracker exists for. But an online-payment order
  /// sits at `pendingPayment` until the provider webhook lands, and telling that
  /// buyer "the seller has your order and is getting it ready" is simply false.
  /// The step stays the same; the sentence under it does not.
  static String _stageExplanation(BuildContext context, Order order) {
    if (order.stage == CustomerOrderStage.confirmed) {
      switch (order.internalStatus) {
        case OrderInternalStatus.pendingPayment:
        case OrderInternalStatus.paymentProcessing:
          return context.l10n.stagePendingPaymentBody;
        case OrderInternalStatus.paymentFailed:
          return context.l10n.stagePaymentFailedBody;
        default:
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
      // The order carries no seller display name, so the receipt labels the
      // party generically. Localized rather than left as the English word.
      sellerName: context.l10n.seller,
      strings: strings,
    );
    // The platform share sheet, so the receipt can go to email, a chat, a
    // printer or a file — whichever the person actually needs.
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'wave-receipt-${order.id.substring(0, 6)}.pdf',
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelThisOrderQ),
        content: Text(context.l10n.cancelOrderBuyerBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.keepIt),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.waveColors.error,
            ),
            child: Text(context.l10n.cancelOrder),
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
