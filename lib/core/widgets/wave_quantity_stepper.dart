import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_typography.dart';
import 'package:wave/l10n/generated/app_localizations.dart';

/// P13's quantity stepper.
///
/// Bounds are enforced here, not by the caller: a stepper that can exceed
/// stock is a checkout failure moved later in the funnel.
class WaveQuantityStepper extends StatelessWidget {
  const WaveQuantityStepper({
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 1,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final l = AppLocalizations.of(context);

    void step(int delta) {
      final next = (value + delta).clamp(min, max);
      if (next != value) {
        HapticFeedback.selectionClick();
        onChanged(next);
      }
    }

    return Semantics(
      // Announced as one adjustable control rather than three separate nodes.
      value: '$value',
      increasedValue: '${(value + 1).clamp(min, max)}',
      decreasedValue: '${(value - 1).clamp(min, max)}',
      onIncrease: value < max ? () => step(1) : null,
      onDecrease: value > min ? () => step(-1) : null,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: c.borderInput),
            borderRadius: BorderRadius.circular(context.surfaces.radiusButton),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove,
                tooltip: l.quantityDecrease,
                onPressed: value > min ? () => step(-1) : null,
              ),
              // Fixed width plus tabular figures: the row must not resize
              // when 9 becomes 10.
              SizedBox(
                width: s.x40,
                child: Text(
                  WaveIsolate.number('$value'),
                  textAlign: TextAlign.center,
                  style: t.bodyStrong.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                tooltip: l.quantityIncrease,
                onPressed: value < max ? () => step(1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return SizedBox(
      width: s.minTapTarget,
      height: s.controlMd,
      child: IconButton(
        icon: Icon(icon, size: s.x20),
        color: c.textPrimary,
        disabledColor: c.textDisabled,
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
