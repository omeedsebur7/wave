import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_product_card.dart';
import 'package:wave/design_system/components/wave_skeleton.dart';

/// Screen-specific skeletons.
///
/// P4's requirement is dimension accuracy: if the layout shifts when data
/// arrives, the skeleton is wrong. That cannot be a generic factory, so each
/// one mirrors a specific composition and has to be updated alongside it.
///
/// Widths are fractions rather than pixel values. Partly because
/// `lib/design_system/` is an enforced lint zone with no raw dimensions
/// allowed, and partly because a fraction of the card is the right unit — a
/// hardcoded 90pt price bar is wrong on every screen width except the one it
/// was measured on.
abstract final class WaveSkeletons {
  /// Mirrors [WaveProductCard] exactly: same 4:5 image, same padding, same
  /// fixed two-line title box, same price line.
  ///
  /// The two must be changed together. They were not: this mirrored the design
  /// system card while the grids rendered a different one, so the swap shifted
  /// layout in the busiest grid in the app.
  static Widget productCard(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final scaler = MediaQuery.textScalerOf(context);
    final radius = BorderRadius.circular(context.surfaces.radiusCard);

    // Glyph height, not line height: a bar the full height of the line box
    // reads as heavier than the text it stands in for.
    final bodyGlyph = scaler.scale(t.body.fontSize ?? 15);
    final priceGlyph = scaler.scale(t.price.fontSize ?? 16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: radius,
        // Matched to the real card. Shadows take no layout space, so this is
        // about the swap being invisible rather than about dimensions.
        boxShadow: c.shadowResting,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: radius.topLeft),
            child: const AspectRatio(
              aspectRatio: 4 / 5,
              child: WaveSkeleton.line(height: double.infinity, radius: 0),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.all(s.x12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: WaveProductCard.titleBoxHeight(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      WaveSkeleton.line(height: bodyGlyph),
                      // Second line partial, the way a real wrapped title is.
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        alignment: AlignmentDirectional.centerStart,
                        child: WaveSkeleton.line(height: bodyGlyph),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: s.x8),
                FractionallySizedBox(
                  widthFactor: 0.5,
                  alignment: AlignmentDirectional.centerStart,
                  child: WaveSkeleton.line(height: priceGlyph),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mirrors the PDP.
  ///
  /// Provisional until verified: toggle between loading and content on device
  /// and watch for shift. That is the actual pass criterion for P4, not the
  /// shape of the code.
  static Widget productDetail(BuildContext context) {
    final t = context.texts;
    final s = context.spacing;
    final scaler = MediaQuery.textScalerOf(context);

    final headlineGlyph = scaler.scale(t.headline.fontSize ?? 24);
    final titleGlyph = scaler.scale(t.title.fontSize ?? 18);
    final bodyGlyph = scaler.scale(t.body.fontSize ?? 15);
    final priceGlyph = scaler.scale(t.price.fontSize ?? 16);

    Widget bar(double factor, double height) => FractionallySizedBox(
          widthFactor: factor,
          alignment: AlignmentDirectional.centerStart,
          child: WaveSkeleton.line(height: height),
        );

    return SingleChildScrollView(
      // The skeleton must not scroll — it is a placeholder, not content.
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Matches _PdpAppBar's expandedHeight, which locks the card's 4:5
          // ratio so the Hero lands on a rect of the source's shape.
          const AspectRatio(
            aspectRatio: 4 / 5,
            child: WaveSkeleton.line(height: double.infinity, radius: 0),
          ),
          Padding(
            padding: EdgeInsetsDirectional.all(s.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(1, headlineGlyph),
                SizedBox(height: s.x4),
                bar(0.55, headlineGlyph),
                SizedBox(height: s.x12),
                bar(0.4, priceGlyph),
                SizedBox(height: s.x8),
                bar(0.3, bodyGlyph),
                SizedBox(height: s.x24),
                // Seller block.
                WaveSkeleton.line(
                  height: s.x64,
                  radius: context.surfaces.radiusCard,
                ),
                SizedBox(height: s.x24),
                bar(0.35, titleGlyph),
                SizedBox(height: s.x12),
                bar(1, bodyGlyph),
                SizedBox(height: s.x8),
                bar(1, bodyGlyph),
                SizedBox(height: s.x8),
                bar(0.7, bodyGlyph),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
