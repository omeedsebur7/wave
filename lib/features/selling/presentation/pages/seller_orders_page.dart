import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/location/presentation/widgets/delivery_location_card.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/selling/domain/repositories/seller_order_repository.dart';
import 'package:wave/features/selling/presentation/bloc/seller_orders_bloc.dart';
import 'package:wave/features/selling/presentation/order_action_text.dart';

/// The seller's order queue.
///
/// Opens on "To do" because that is the only reason a seller opens this screen.
/// Completed orders are two taps away; the ones waiting on them are zero.
class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SellerOrdersBloc>()..add(const SellerOrdersSubscribed()),
      child: const _SellerOrdersView(),
    );
  }
}

class _SellerOrdersView extends StatelessWidget {
  const _SellerOrdersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ordersToFulfil)),
      body: BlocConsumer<SellerOrdersBloc, SellerOrdersState>(
        listenWhen: (a, b) => a.failure != b.failure && b.failure != null,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureText(context, state.failure!)))),
        builder: (context, state) {
          if (state.status == SellerOrdersStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _FilterBar(state: state),
              Expanded(
                child: state.visible.isEmpty
                    ? _EmptyFor(filter: state.filter)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _SellerOrderCard(
                          order: state.visible[i],
                          isUpdating:
                              state.updatingId == state.visible[i].id,
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state});

  final SellerOrdersState state;

  static String _labelFor(BuildContext context, SellerOrderFilter filter) =>
      switch (filter) {
        SellerOrderFilter.needsAction => context.l10n.filterToDo,
        SellerOrderFilter.inTransit => context.l10n.filterOnTheWay,
        SellerOrderFilter.completed => context.l10n.filterCompleted,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final filter in SellerOrderFilter.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: state.filter == filter,
                onSelected: (_) => context
                    .read<SellerOrdersBloc>()
                    .add(SellerOrderFilterChanged(filter)),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_labelFor(context, filter)),
                    if (filter == SellerOrderFilter.needsAction &&
                        state.needsActionCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.waveColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${state.needsActionCount}',
                          style: context.texts.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({required this.order, required this.isUpdating});

  final Order order;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final primaryNext = OrderTransitions.primaryNext(order.internalStatus);
    final otherOptions = [
      for (final s in OrderTransitions.nextFrom(order.internalStatus))
        if (s != primaryNext) s,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.substring(0, 6).toUpperCase()}',
                style: context.texts.bodySmall,
              ),
              Text(
                context.money(order.totalMinor, order.currency),
                style: context.texts.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),

          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                context.l10n.quantityTimesTitle(item.quantity, item.title),
                style: context.texts.bodyMedium,
              ),
            ),

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: _statusColour(context)),
              const SizedBox(width: 6),
              Text(
                _statusLabel(context, order.internalStatus),
                style: context.texts.bodySmall
                    ?.copyWith(color: _statusColour(context)),
              ),
            ],
          ),

          if (order.stage == CustomerOrderStage.confirmed) ...[
            const SizedBox(height: 8),
            Text(
              // Tells the seller what the buyer can still do, so a cancellation
              // is not a surprise.
              context.l10n.buyerCanStillCancel,
              style: context.texts.bodySmall,
            ),
          ],

          // The buyer's pin. Above the action buttons rather than below,
          // because "where is this going" is the question a seller answers
          // before deciding whether they can fulfil it at all.
          //
          // Hidden once the order is finished: a delivered order's map is
          // clutter, and a cancelled one's is a home address with no reason to
          // still be on screen.
          if (!OrderTransitions.isTerminal(order.internalStatus)) ...[
            const SizedBox(height: 16),
            DeliveryLocationCard(location: order.deliveryLocation),
          ],

          if (!OrderTransitions.isTerminal(order.internalStatus)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (primaryNext != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: isUpdating
                          ? null
                          : () => context
                              .read<SellerOrdersBloc>()
                              .add(SellerOrderAdvanced(order, primaryNext)),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(orderActionLabel(context, primaryNext)),
                    ),
                  ),
                if (otherOptions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<OrderInternalStatus>(
                    enabled: !isUpdating,
                    tooltip: context.l10n.otherActions,
                    icon: const Icon(Icons.more_vert),
                    onSelected: (to) => _confirmIfDestructive(context, to),
                    itemBuilder: (context) => [
                      for (final option in otherOptions)
                        PopupMenuItem(
                          value: option,
                          child: Text(orderActionLabel(context, option)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmIfDestructive(
    BuildContext context,
    OrderInternalStatus to,
  ) async {
    final bloc = context.read<SellerOrdersBloc>();

    if (to != OrderInternalStatus.cancelled) {
      bloc.add(SellerOrderAdvanced(order, to));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelThisOrderQ),
        content: Text(context.l10n.cancelOrderSellerBody),
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

    if (confirmed ?? false) {
      bloc.add(SellerOrderAdvanced(order, to));
    }
  }

  Color _statusColour(BuildContext context) {
    final c = context.waveColors;
    return switch (order.stage) {
      CustomerOrderStage.confirmed => c.warning,
      CustomerOrderStage.onTheWay => c.info,
      CustomerOrderStage.delivered => c.success,
      CustomerOrderStage.cancelled => c.error,
    };
  }

  /// The seller sees the FULL internal status, unlike the buyer's 3 stages —
  /// they are the one who needs to know the difference between packed and
  /// handed to a courier.
  ///
  /// Takes a context because these are seller-facing copy, not debug output.
  /// They were bare English literals until now, on a screen sellers use more
  /// than any other — and the hardcoded-string check missed them because it
  /// only looked at widget parameters, not bare returns from a `switch`.
  static String _statusLabel(BuildContext context, OrderInternalStatus s) =>
      switch (s) {
        // The three payment states are unreachable in Phase 1 (cash-only, so
        // placeOrder confirms immediately) but kept and translated, because an
        // untranslated branch is what ships when Phase 2 makes it reachable.
        OrderInternalStatus.pendingPayment =>
          context.l10n.statusPendingPayment,
        OrderInternalStatus.paymentProcessing =>
          context.l10n.statusPaymentProcessing,
        OrderInternalStatus.paymentFailed => context.l10n.statusPaymentFailed,
        OrderInternalStatus.confirmed => context.l10n.statusNeedsPacking,
        OrderInternalStatus.packed => context.l10n.statusPacked,
        OrderInternalStatus.handedToCourier => context.l10n.statusWithCourier,
        OrderInternalStatus.outForDelivery =>
          context.l10n.statusOutForDelivery,
        OrderInternalStatus.delivered => context.l10n.statusDelivered,
        OrderInternalStatus.cancelled => context.l10n.statusCancelled,
        OrderInternalStatus.refunded => context.l10n.statusRefunded,
      };
}

class _EmptyFor extends StatelessWidget {
  const _EmptyFor({required this.filter});

  final SellerOrderFilter filter;

  @override
  Widget build(BuildContext context) => switch (filter) {
        SellerOrderFilter.needsAction => WaveErrorView.empty(
            title: context.l10n.nothingWaitingOnYou,
            message: context.l10n.nothingWaitingBody,
            icon: Icons.inventory_2_outlined,
          ),
        SellerOrderFilter.inTransit => WaveErrorView.empty(
            title: context.l10n.nothingInTransit,
            message: context.l10n.nothingInTransitBody,
            icon: Icons.local_shipping_outlined,
          ),
        SellerOrderFilter.completed => WaveErrorView.empty(
            title: context.l10n.noCompletedOrders,
            message: context.l10n.noCompletedOrdersBody,
            icon: Icons.done_all,
          ),
      };
}
