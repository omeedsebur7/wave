import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/features/checkout/presentation/widgets/quick_checkout_sheet.dart';
import 'package:wave/features/reels/data/buy_now_tracker.dart';

/// "ئێستا بیکڕە" — Buy Now (§5.1).
///
/// Only rendered when the Reel's publisher has linked a product. Tapping opens
/// a bottom sheet, never a full-page navigation: pushing a route would tear
/// down the video and lose the user's place in the feed, which is precisely
/// the friction this feature exists to remove.
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

  /// Denormalised from the linked product so the feed needs no extra read.
  ///
  /// Display only, and possibly one sync stale. The sheet re-reads the product
  /// and `placeOrder` recomputes again, so this figure never sets a charge.
  final int? priceMinor;
  final String? currency;

  /// When the linked product has bidding turned on (P2), Buy Now stays the
  /// primary action and "Make an Offer" sits beside it as a smaller secondary.
  final bool negotiationEnabled;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    final primary = FilledButton.icon(
      onPressed: () {
        // Recorded before the sheet opens, not after it completes. A tap is a
        // tap whether or not it becomes a sale — measuring only completed
        // purchases would hide the drop-off this metric exists to expose.
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
      icon: const Icon(Icons.bolt, size: 20),
      // The price goes on the button, not just in the sheet.
      //
      // It is the single most useful thing to know before tapping: someone
      // scrolling can decide whether they are interested without opening
      // anything, and a tap that opens a sheet only to reveal an unaffordable
      // price is a wasted tap for them and a false signal in the funnel.
      //
      // Falls back to the bare label when the price is missing rather than
      // rendering "Buy Now — ", because half a sentence reads as a bug.
      label: Text(
        priceMinor != null && currency != null
            ? context.l10n.buyNowWithPrice(context.money(priceMinor!, currency!))
            : context.l10n.buyNow,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
        ),
      ),
    );

    if (!negotiationEnabled) return primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        primary,
        const SizedBox(width: 8),
        TextButton(
          // Negotiation is Phase 2 (§5.2). The affordance exists because the
          // brief specifies where it sits relative to Buy Now, but tapping it
          // says so plainly rather than doing nothing — a dead button is worse
          // than an honest one.
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.offersComingSoon)),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
          ),
          child: Text(context.l10n.makeAnOffer),
        ),
      ],
    );
  }
}
