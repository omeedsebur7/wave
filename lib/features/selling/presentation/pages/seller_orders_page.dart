import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/location/presentation/widgets/delivery_location_card.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/selling/domain/repositories/seller_order_repository.dart';
import 'package:wave/features/selling/presentation/bloc/seller_orders_bloc.dart';
import 'package:wave/features/selling/presentation/order_action_text.dart';

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
            // FIXED: Replaced standard CircularProgressIndicator with WaveStateView
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()),
              content: SizedBox.shrink(),
            );
          }

          return Column(
            children: [
              _FilterBar(state: state),
              Expanded(
                child: state.visible.isEmpty
                    ? _EmptyFor(filter: state.filter)
                    : ListView.separated(
                        padding: const EdgeInsetsDirectional.all(WaveSpacing.x16), // FIXED
                        itemCount: state.visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: WaveSpacing.x12), // FIXED
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
      height: WaveSpacing.x64, // FIXED: Used a valid token instead of raw 56
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: WaveSpacing.x16, 
          vertical: WaveSpacing.x8,
        ), // FIXED
        children: [
          for (final filter in SellerOrderFilter.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: WaveSpacing.x8), // FIXED
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
                      const SizedBox(width: WaveSpacing.x8), // FIXED
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: WaveSpacing.x8, // FIXED
                          vertical: 2, // FIXED
                        ),
                        decoration: BoxDecoration(
                          color: context.waveColors.primary,
                          borderRadius: BorderRadius.circular(WaveSpacing.x8), // FIXED
                        ),
                        child: Text(
                          '${state.needsActionCount}',
                          style: context.texts.caption.copyWith( // FIXED
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
      padding: const EdgeInsetsDirectional.all(WaveSpacing.x16), // FIXED
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.substring(0, 6).toUpperCase()}',
                style: context.texts.caption, // FIXED
              ),
              Text(
                context.money(order.totalMinor, order.currency),
                style: context.texts.title, // FIXED
              ),
            ],
          ),
          const SizedBox(height: WaveSpacing.x8), // FIXED

          for (final item in order.items)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x4), // FIXED
              child: Text(
                context.l10n.quantityTimesTitle(item.quantity, item.title),
                style: context.texts.body, // FIXED
              ),
            ),

          const SizedBox(height: WaveSpacing.x8), // FIXED
          Row(
            children: [
              Icon(Icons.circle, size: WaveSpacing.x8, color: _statusColour(context)), // FIXED
              const SizedBox(width: WaveSpacing.x8), // FIXED
              Text(
                _statusLabel(context, order.internalStatus),
                style: context.texts.caption
                    .copyWith(color: _statusColour(context)), // FIXED
              ),
            ],
          ),

          if (order.stage == CustomerOrderStage.confirmed) ...[
            const SizedBox(height: WaveSpacing.x8), // FIXED
            Text(
              context.l10n.buyerCanStillCancel,
              style: context.texts.caption, // FIXED
            ),
          ],

          if (!OrderTransitions.isTerminal(order.internalStatus)) ...[
            const SizedBox(height: WaveSpacing.x16), // FIXED
            DeliveryLocationCard(location: order.deliveryLocation),
          ],

          if (!OrderTransitions.isTerminal(order.internalStatus)) ...[
            const SizedBox(height: WaveSpacing.x16), // FIXED
            Row(
              children: [
                if (primaryNext != null)
                  Expanded(
                    child: WaveButton( // FIXED: FilledButton -> WaveButton
                      expand: true,
                      isLoading: isUpdating, // FIXED: Removed manual spinner
                      label: orderActionLabel(context, primaryNext),
                      onPressed: isUpdating
                          ? null
                          : () => context
                              .read<SellerOrdersBloc>()
                              .add(SellerOrderAdvanced(order, primaryNext)),
                    ),
                  ),
                if (otherOptions.isNotEmpty) ...[
                  const SizedBox(width: WaveSpacing.x8), // FIXED
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

  // FIXED: Replaced standard AlertDialog with WaveSheet (physics-based signature move)
  Future<void> _confirmIfDestructive(
    BuildContext context,
    OrderInternalStatus to,
  ) async {
    final bloc = context.read<SellerOrdersBloc>();

    if (to != OrderInternalStatus.cancelled) {
      bloc.add(SellerOrderAdvanced(order, to));
      return;
    }

    final confirmed = await WaveSheet.show<bool>(
      context: context,
      title: context.l10n.cancelThisOrderQ,
      builder: (context) => Text(
        context.l10n.cancelOrderSellerBody,
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

  static String _statusLabel(BuildContext context, OrderInternalStatus s) =>
      switch (s) {
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
