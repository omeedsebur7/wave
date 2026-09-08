import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_typography.dart';

enum WavePriceSize { sm, md }

class WavePrice extends StatelessWidget {
  const WavePrice({
    required this.amountMinor,
    this.originalAmountMinor,
    this.size = WavePriceSize.md,
    super.key,
  });

  final int amountMinor;
  final int? originalAmountMinor;
  final WavePriceSize size;

  static const _minorExponent = 3;

  static final _fmt = NumberFormat('#,##0', 'en');

  static String format(int minor) =>
      _fmt.format(minor ~/ _pow10(_minorExponent));

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final discounted = originalAmountMinor != null;

    final amount = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          WaveIsolate.number(format(amountMinor)),
          // FIXED: Removed raw fontSize: 14 and replaced with standard label token
          style: (size == WavePriceSize.md ? t.price : t.label)
              .copyWith(color: discounted ? c.priceDiscount : c.price),
        ),
        SizedBox(width: s.x4),
        Text('د.ع', style: t.label.copyWith(color: c.textSecondary)),
      ],
    );

    if (!discounted) return amount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        amount,
        SizedBox(width: s.x8),
        Text(
          WaveIsolate.number(format(originalAmountMinor!)),
          style: t.priceStruck.copyWith(color: c.priceStrikethrough),
        ),
      ],
    );
  }
}
