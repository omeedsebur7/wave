import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/core/theme/app_theme.dart';

enum WaveButtonVariant { primary, secondary, tertiary, destructive, icon }

enum WaveButtonSize { sm, md, lg }

class WaveButton extends StatelessWidget {
  const WaveButton({
    required this.label,
    required this.onPressed,
    this.variant = WaveButtonVariant.primary,
    this.size = WaveButtonSize.lg,
    this.isLoading = false,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final WaveButtonVariant variant;
  final WaveButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final sur = context.surfaces;
    final m = context.motion;

    final height = switch (size) {
      WaveButtonSize.sm => s.controlSm,
      WaveButtonSize.md => s.controlMd,
      WaveButtonSize.lg => s.controlLg,
    };

    final (Color bg, Color fg, BorderSide? side) = switch (variant) {
      WaveButtonVariant.primary => (c.accent, c.onAccent, null),
      WaveButtonVariant.secondary => (
          Colors.transparent,
          c.textPrimary,
          BorderSide(color: c.borderInput),
        ),
      WaveButtonVariant.tertiary => (Colors.transparent, c.accent, null),
      WaveButtonVariant.destructive => (c.error, c.onError, null),
      WaveButtonVariant.icon => (Colors.transparent, c.textPrimary, null),
    };

    final enabled = onPressed != null && !isLoading;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(expand ? double.infinity : s.x64, height),
      ),
      tapTargetSize: MaterialTapTargetSize.padded, 
      padding: WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(horizontal: s.x20),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? bg == Colors.transparent
                ? bg
                : bg.withValues(alpha: 0.38)
            : states.contains(WidgetState.pressed) && bg == c.accent
                ? c.accentPressed
                : bg,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? c.textDisabled : fg,
      ),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      side: side == null ? null : WidgetStatePropertyAll(side),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(t.label),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sur.radiusButton),
        ),
      ),
      animationDuration: m.fast,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: TextButton(
          style: style,
          onPressed: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                }
              : null,
          child: _Content(
            label: label,
            icon: icon,
            isLoading: isLoading,
            foreground: fg,
            isIconOnly: variant == WaveButtonVariant.icon && label.isEmpty,
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.foreground,
    this.isIconOnly = false,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color foreground;
  final bool isIconOnly;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: isLoading ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: s.x20),
                if (!isIconOnly) SizedBox(width: s.x8),
              ],
              if (!isIconOnly)
                Flexible(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
        if (isLoading)
          SizedBox(
            width: s.x20,
            height: s.x20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          ),
      ],
    );
  }
}
