import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:wave/features/orders/presentation/widgets/order_tracker.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrdersBloc>()..add(const OrdersSubscribed()),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.yourOrders)),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (a, b) => a.failure != b.failure && b.failure != null,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureText(context, state.failure!)))),
        builder: (context, state) {
          if (state.status == OrdersStatus.loading) {
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()), 
              content: SizedBox.shrink(),
            );
          }

          if (state.status == OrdersStatus.failure && state.orders.isEmpty) {
            return WaveErrorView(
              title: context.l10n.ordersNotLoaded,
              message: context.l10n.errorNoConnectionBody,
              onRetry: () =>
                  context.read<OrdersBloc>().add(const OrdersSubscribed()),
            );
          }

          if (state.orders.isEmpty) {
            return WaveErrorView.empty(
              title: context.l10n.noOrdersYet,
              message: context.l10n.noOrdersBody,
              icon: Icons.receipt_long_outlined,
              retryLabel: context.l10n.browseTheMarket,
              onRetry: () => context.go(Routes.marketplace),
            );
          }

          return ListView.separated(
            padding: const EdgeInsetsDirectional.all(WaveSpacing.x16),
            itemCount: state.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: WaveSpacing.x12),
            itemBuilder: (context, i) => _OrderCard(order: state.orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return InkWell(
      onTap: () => context.push(Routes.orderDetailPath(order.id)),
      borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
      child: Container(
        padding: const EdgeInsetsDirectional.all(WaveSpacing.x16),
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
            const SizedBox(height: WaveSpacing.x8),
            Text(
              order.items.isEmpty
                  ? context.l10n.orderFallbackTitle
                  : order.items.first.title +
                      (order.items.length > 1
                          ? context.l10n.andNMore(order.items.length - 1)
                          : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.body, // FIXED
            ),
            const SizedBox(height: WaveSpacing.x16),
            OrderTracker(stage: order.stage),
            if (order.canBeRated) ...[
              const SizedBox(height: WaveSpacing.x16),
              WaveButton( // FIXED: FilledButton.tonal to WaveButton
                variant: WaveButtonVariant.secondary,
                expand: true,
                label: context.l10n.rateThisOrder,
                onPressed: () => context.push(Routes.orderDetailPath(order.id)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
