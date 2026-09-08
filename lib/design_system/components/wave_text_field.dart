import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

/// Standardized Text Field Component (§P3, §P9).
class WaveTextField extends StatelessWidget {
  const WaveTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.forceLtr = false, 
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool forceLtr; 

  @override
  Widget build(BuildContext context) {
    final colors = context.waveColors;

    return Semantics(
      label: label ?? hint,
      textField: true,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        enabled: enabled,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        textDirection: forceLtr ? TextDirection.ltr : null,
        cursorColor: colors.primary,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: colors.textSecondary, size: WaveSpacing.x20)
              : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
