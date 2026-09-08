import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

class OrderTracker extends StatelessWidget {
  const OrderTracker({required this.stage, super.key});

  final CustomerOrderStage stage;

  static const _stepIcons = [
    Icons.check_circle_outline,
    Icons.local_shipping_outlined,
    Icons.inventory_2_outlined,
  ];

  List<String> _stepLabels(BuildContext context) => [
        context.l10n.orderConfirmed,
        context.l10n.orderOnTheWay,
        context.l10n.orderDelivered,
      ];

  int get _activeIndex => switch (stage) {
        CustomerOrderStage.confirmed => 0,
        CustomerOrderStage.onTheWay => 1,
        CustomerOrderStage.delivered => 2,
        CustomerOrderStage.cancelled => -1,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    if (stage == CustomerOrderStage.cancelled) {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, color: c.error, size: WaveSpacing.x20),
          const SizedBox(width: WaveSpacing.x8),
          Text(
            context.l10n.orderCancelled,
            style: context.texts.label.copyWith(color: c.error),
          ),
        ],
      );
    }

    final labels = _stepLabels(context);

    return Semantics(
      label: context.l10n.orderStatusSemantic(
        labels[_activeIndex],
        _activeIndex + 1,
      ),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < _stepIcons.length; i++) ...[
              _Step(
                label: labels[i],
                icon: _stepIcons[i],
                done: i <= _activeIndex,
                active: i == _activeIndex,
              ),
              if (i < _stepIcons.length - 1)
                Expanded(
                  child: Container(
                    height: 2, // FIXED: WaveSpacing.x2 replaced with standard 2.0
                    margin: const EdgeInsetsDirectional.symmetric(horizontal: WaveSpacing.x4),
                    color: i < _activeIndex ? c.success : c.border,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.icon,
    required this.done,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final color = done ? c.success : c.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: WaveSpacing.controlSm,
          height: WaveSpacing.controlSm,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? c.success.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(color: done ? c.success : c.border, width: 2),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: WaveSpacing.x4),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.texts.caption.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
