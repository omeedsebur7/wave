import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_motion.dart';
import 'package:wave/core/theme/wave_hero_tags.dart';
import 'package:wave/design_system/components/wave_price.dart';
import 'package:wave/design_system/components/wave_ugc_text.dart';

/// The one product card.
///
/// There were two: this, and `features/marketplace/presentation/widgets/
/// product_card.dart`, which is what the grids actually rendered. The skeleton
/// mirrored THIS one, so the load-to-content swap shifted layout in the app's
/// busiest grid — the exact thing P4 exists to prevent. The favourite
/// affordance below is what the feature card had and this one lacked; with it
/// present, the feature card can be deleted.
class WaveProductCard extends StatefulWidget {
  const WaveProductCard({
    required this.productId,
    required this.imageUrl,
    required this.title,
    required this.priceMinor,
    this.originalPriceMinor,
    this.heroScope = 'main',
    this.isFavourite,
    this.onFavouriteToggle,
    this.onTap,
    super.key,
  });

  final String productId;
  final String imageUrl;
  final String title;
  final int priceMinor;
  final int? originalPriceMinor;
  final String heroScope;

  /// Null hides the heart entirely — the cart and the recommendation rails
  /// have no business showing one.
  final bool? isFavourite;
  final VoidCallback? onFavouriteToggle;
  final VoidCallback? onTap;

  /// Exact rendered height for a card of [width].
  ///
  /// The grids were passing `childAspectRatio: 0.62`, which is a guess. At 375
  /// wide that gives a 267pt cell for a card that needs about 309 — a silent
  /// overflow at default text scale, worse at 1.3x. Height is a property of
  /// the card, so the card computes it and the page asks.
  ///
  /// Scales with the user's text size, because the title and price do.
  static double heightFor(BuildContext context, double width) {
    final t = context.texts;
    final s = context.spacing;
    final scaler = MediaQuery.textScalerOf(context);

    final titleLine =
        scaler.scale(t.body.fontSize ?? 15) * (t.body.height ?? 1.6);
    final priceLine =
        scaler.scale(t.price.fontSize ?? 16) * (t.price.height ?? 1.4);

    return width * 5 / 4 // locked 4:5 image
        + s.x12 * 2 // vertical padding
        + titleLine * 2 // title box, always two lines
        + s.x8 // gap
        + priceLine;
  }

  /// Height of the fixed two-line title box. Shared with the skeleton so the
  /// two cannot drift.
  static double titleBoxHeight(BuildContext context) {
    final t = context.texts;
    final scaler = MediaQuery.textScalerOf(context);
    return scaler.scale(t.body.fontSize ?? 15) * (t.body.height ?? 1.6) * 2;
  }

  @override
  State<WaveProductCard> createState() => _WaveProductCardState();
}

class _WaveProductCardState extends State<WaveProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final m = context.motion;
    final radius = BorderRadius.circular(context.surfaces.radiusCard);

    // Decode at display size. Full-resolution decode is the memory pressure
    // P12 exists to prevent on mid-range Android.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetWidth = (MediaQuery.sizeOf(context).width / 2 * dpr).round();

    return Semantics(
      button: true,
      label: '${widget.title}, ${WavePrice.format(widget.priceMinor)}',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: WaveMotion.resolve(context, m.fast),
            curve: m.press,
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: radius,
                  boxShadow: c.shadowResting,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: radius.topLeft),
                          child: AspectRatio(
                            aspectRatio: 4 / 5,
                            child: Hero(
                              tag: WaveHeroTags.productImage(
                                widget.productId,
                                scope: widget.heroScope,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: targetWidth,
                                fadeInDuration:
                                    WaveMotion.resolve(context, m.base),
                                placeholder: (_, __) =>
                                    ColoredBox(color: c.skeletonBase),
                                errorWidget: (_, __, ___) => ColoredBox(
                                  color: c.surfaceSunken,
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: c.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.isFavourite != null)
                          PositionedDirectional(
                            top: s.x4,
                            end: s.x4,
                            child: _FavouriteButton(
                              isFavourite: widget.isFavourite!,
                              onPressed: widget.onFavouriteToggle,
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.all(s.x12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fixed box, always two lines tall. A one-line title
                          // making a shorter card is a layout shift in a grid
                          // and a jagged edge in a horizontal rail.
                          SizedBox(
                            height: WaveProductCard.titleBoxHeight(context),
                            width: double.infinity,
                            child: WaveUgcText(
                              widget.title,
                              style: t.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: s.x8),
                          WavePrice(
                            amountMinor: widget.priceMinor,
                            originalAmountMinor: widget.originalPriceMinor,
                            size: WavePriceSize.sm,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sits over arbitrary product photography, so it carries its own ground.
class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.isFavourite, required this.onPressed});

  final bool isFavourite;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;
    final m = context.motion;

    return Semantics(
      button: true,
      selected: isFavourite,
      child: Material(
        color: c.scrim,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: SizedBox(
            width: s.minTapTarget,
            height: s.minTapTarget,
            // Optimistic by construction: the parent flips isFavourite before
            // the round trip, and this animates the change rather than waiting
            // for it.
            child: AnimatedSwitcher(
              duration: WaveMotion.resolve(context, m.fast),
              switchInCurve: m.emphasized,
              child: Icon(
                isFavourite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isFavourite),
                size: s.x20,
                color: isFavourite ? c.error : c.onScrim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
