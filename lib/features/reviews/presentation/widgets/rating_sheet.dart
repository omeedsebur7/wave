import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';

enum RatingTarget { product, seller }

Future<int?> showRatingSheet(
  BuildContext context, {
  required RatingTarget target,
  required String targetName,
}) {
  final prompt = target == RatingTarget.product
      ? context.l10n.ratePromptProduct(targetName)
      : context.l10n.ratePromptSeller(targetName);

  // FIXED: Replaced standard showModalBottomSheet with WaveSheet
  return WaveSheet.show<int>(
    context: context,
    title: prompt,
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

  String _ratingLabel(BuildContext context) => switch (_rating) {
        1 => context.l10n.ratingBad,
        2 => context.l10n.ratingNotGreat,
        3 => context.l10n.ratingFine,
        4 => context.l10n.ratingGood,
        5 => context.l10n.ratingExcellent,
        _ => context.l10n.tapAStar,
      };

  void _submit(BuildContext context) {
    if (_rating == 0) return;
    Navigator.pop(context, _rating);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _rating = i);
                },
                iconSize: WaveSpacing.x40, // FIXED
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
              style: context.texts.caption,), // FIXED
        ),
        const SizedBox(height: WaveSpacing.x16), // FIXED
        WaveTextField( // FIXED: TextField -> WaveTextField
          controller: _text,
          maxLines: 3,
          hint: context.l10n.addANote,
          inputFormatters: [
            LengthLimitingTextInputFormatter(500),
          ],
        ),
        const SizedBox(height: WaveSpacing.x8), // FIXED
        Text(
          context.l10n.editWindowNote,
          style: context.texts.caption, // FIXED
        ),
        const SizedBox(height: WaveSpacing.x16), // FIXED
        SizedBox(
          width: double.infinity,
          child: WaveButton( // FIXED: FilledButton -> WaveButton
            expand: true,
            label: context.l10n.submitRating,
            onPressed: _rating == 0
                ? null
                : () => _submit(context),
          ),
        ),
      ],
    );
  }
}
