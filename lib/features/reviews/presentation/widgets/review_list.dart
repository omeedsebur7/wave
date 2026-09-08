import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart'; // FIXED: Imported spacing
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/features/reviews/domain/entities/review.dart';

class ReviewList extends StatelessWidget {
  const ReviewList({
    required this.reviews,
    required this.average,
    required this.distribution,
    super.key,
  });

  final List<Review> reviews;
  final double average;
  final Map<int, int> distribution;

  int get total => distribution.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    if (total == 0) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: WaveSpacing.x24), // FIXED
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.noReviewsYet, style: context.texts.title), // FIXED
            const SizedBox(height: WaveSpacing.x4), // FIXED
            Text(
              context.l10n.reviewVerifiedOnly,
              style: context.texts.caption, // FIXED
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(context.decimal(average),
                    style: context.texts.display,), // FIXED
                _Stars(value: average),
                Text(context.l10n.reviewsCount(total),
                    style: context.texts.caption,), // FIXED
              ],
            ),
            const SizedBox(width: WaveSpacing.x24), // FIXED
            Expanded(
              child: Column(
                children: [
                  for (var star = 5; star >= 1; star--)
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(vertical: 2), // FIXED
                      child: Row(
                        children: [
                          Text('$star', style: context.texts.caption), // FIXED
                          const SizedBox(width: 6), // FIXED
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (distribution[star] ?? 0) / total,
                                minHeight: 6, // FIXED
                                backgroundColor: c.border,
                                valueColor:
                                    AlwaysStoppedAnimation(c.accentInteractive),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6), // FIXED
                          SizedBox(
                            width: 28, // FIXED
                            child: Text(
                              context.number(distribution[star] ?? 0),
                              style: context.texts.caption, // FIXED
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: WaveSpacing.x20), // FIXED
        for (final review in reviews) _ReviewTile(review: review),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x20), // FIXED
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stars(value: review.rating.toDouble(), size: 14), // FIXED
              const SizedBox(width: WaveSpacing.x8), // FIXED
              Icon(Icons.verified_outlined, size: 14, color: c.success), // FIXED
              const SizedBox(width: WaveSpacing.x4), // FIXED
              Text(
                context.l10n.verifiedPurchase,
                style: context.texts.caption.copyWith(color: c.success), // FIXED
              ),
              if (review.editedAt != null) ...[
                const SizedBox(width: WaveSpacing.x8), // FIXED
                Text(context.l10n.reviewEdited, style: context.texts.caption), // FIXED
              ],
            ],
          ),
          if (review.text != null && review.text!.isNotEmpty) ...[
            const SizedBox(height: 6), // FIXED
            Text(review.text!, style: context.texts.body), // FIXED
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.size = 16.0});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    return Semantics(
      label: context.l10n.ratingOutOfFive(context.decimal(value)),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                value >= i
                    ? Icons.star
                    : (value >= i - 0.5 ? Icons.star_half : Icons.star_border),
                size: size,
                color: c.accentInteractive,
              ),
          ],
        ),
      ),
    );
  }
}
