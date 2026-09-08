import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/features/checkout/presentation/widgets/quick_checkout_sheet.dart';
import 'package:wave/features/reels/data/buy_now_tracker.dart';

class BuyNowButton extends StatelessWidget {
  const BuyNowButton({
    required this.reelId,
    required this.productId,
    this.sellerId,
    this.priceMinor,
    this.currency,
    this.negotiationEnabled = false,
    super.key,
  });

  final String reelId;
  final String productId;
  final String? sellerId;

  final int? priceMinor;
  final String? currency;

  final bool negotiationEnabled;

  @override
  Widget build(BuildContext context) {
    // FIXED: Replaced standard FilledButton.icon with WaveButton
    final primary = WaveButton(
      icon: Icons.bolt,
      label: priceMinor != null && currency != null
          ? context.l10n.buyNowWithPrice(context.money(priceMinor!, currency!))
          : context.l10n.buyNow,
      onPressed: () {
        getIt<BuyNowTracker>().recordTap(
          reelId: reelId,
          productId: productId,
          sellerId: sellerId,
        );
        showQuickCheckoutSheet(
          context,
          productId: productId,
          sourceReelId: reelId,
        );
      },
    );

    if (!negotiationEnabled) return primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        primary,
        const SizedBox(width: WaveSpacing.x8), // FIXED
        WaveButton( // FIXED: Replaced TextButton with WaveButton tertiary
          variant: WaveButtonVariant.tertiary,
          label: context.l10n.makeAnOffer,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.offersComingSoon)),
          ),
        ),
      ],
    );
  }
}
