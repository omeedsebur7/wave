import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';

enum RatingTarget { product, seller }

/// The rating prompt (§5.2).
///
/// Only ever opened from a delivered order — one rating per order, and the
/// prompt never surfaces before delivery. That constraint is what makes the
/// trust tiers mean anything: a rating that could be left without a completed
/// purchase is a rating a seller can manufacture.
Future<int?> showRatingSheet(
  BuildContext context, {
  required RatingTarget target,
  required String targetName,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RatingSheet(target: target, targetName: targetName),
  );
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.target, required this.targetName});
  final RatingTarget target;
  final String targetName;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Takes a context because the seller's or product's name is interpolated
  /// into translated copy — and word order around a name differs by language,
  /// which is exactly why this belongs in the ARB rather than built by
  /// concatenation here.
  String _prompt(BuildContext context) => switch (widget.target) {
        RatingTarget.product =>
          context.l10n.ratePromptProduct(widget.targetName),
        RatingTarget.seller =>
          context.l10n.ratePromptSeller(widget.targetName),
      };

  /// Naming what each star means reduces the everything-is-5-stars compression
  /// that makes a rating system useless for ranking.
  String _ratingLabel(BuildContext context) => switch (_rating) {
        1 => context.l10n.ratingBad,
        2 => context.l10n.ratingNotGreat,
        3 => context.l10n.ratingFine,
        4 => context.l10n.ratingGood,
        5 => context.l10n.ratingExcellent,
        _ => context.l10n.tapAStar,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_prompt(context), style: context.texts.headlineMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = i);
                  },
                  iconSize: 40,
                  // Pluralised through the ARB rather than an `s` suffix:
                  // Arabic has more plural categories than two, and Kurdish
                  // pluralises differently again.
                  tooltip: context.l10n.starCount(i),
                  icon: Icon(
                    _rating >= i ? Icons.star : Icons.star_border,
                    color: c.accentInteractive,
                  ),
                ),
            ],
          ),
          Center(
            child: Text(_ratingLabel(context),
                style: context.texts.bodySmall,),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: context.l10n.addANote,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.editWindowNote,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0
                  ? null
                  : () => Navigator.pop(context, _rating),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(WaveSurfaces.radiusChip),
                ),
              ),
              child: Text(context.l10n.submitRating),
            ),
          ),
        ],
      ),
    );
  }
}
