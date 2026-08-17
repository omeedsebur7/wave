import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/features/reviews/domain/entities/review.dart';

/// Review list with the rating distribution bar.
///
/// The distribution is shown, not just the average: a 4.0 made of all-4s and a
/// 4.0 made of half 5s and half 3s are very different products, and hiding that
/// behind one number is the kind of thing that erodes trust in ratings
/// generally.
class ReviewList extends StatelessWidget {
  const ReviewList({
    required this.reviews,
    required this.average,
    required this.distribution,
    super.key,
  });

  final List<Review> reviews;
  final double average;

  /// Star value (1–5) to count.
  final Map<int, int> distribution;

  int get total => distribution.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.noReviewsYet, style: context.texts.titleMedium),
            const SizedBox(height: 4),
            Text(
              context.l10n.reviewVerifiedOnly,
              style: context.texts.bodySmall,
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
                    style: context.texts.displayLarge,),
                _Stars(value: average),
                Text(context.l10n.reviewsCount(total),
                    style: context.texts.bodySmall,),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  for (var star = 5; star >= 1; star--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star', style: context.texts.bodySmall),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (distribution[star] ?? 0) / total,
                                minHeight: 6,
                                backgroundColor: c.border,
                                valueColor:
                                    AlwaysStoppedAnimation(c.accentInteractive),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 28,
                            child: Text(
                              context.number(distribution[star] ?? 0),
                              style: context.texts.bodySmall,
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
        const SizedBox(height: 20),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stars(value: review.rating.toDouble(), size: 14),
              const SizedBox(width: 8),
              // Every review carries this badge because every review is gated
              // on a delivered order — it's a statement about the system, not
              // a distinction between reviews.
              Icon(Icons.verified_outlined, size: 14, color: c.success),
              const SizedBox(width: 4),
              Text(
                context.l10n.verifiedPurchase,
                style: context.texts.bodySmall?.copyWith(color: c.success),
              ),
              if (review.editedAt != null) ...[
                const SizedBox(width: 8),
                Text(context.l10n.reviewEdited, style: context.texts.bodySmall),
              ],
            ],
          ),
          if (review.text != null && review.text!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.text!, style: context.texts.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.size = 16});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    return Semantics(
      // One decimal place, formatted for the locale: an Arabic reader gets
      // Arabic-Indic digits and an Arabic decimal separator, which a raw
      // toStringAsFixed cannot produce.
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
