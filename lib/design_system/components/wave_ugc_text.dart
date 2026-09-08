import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Block-level user-generated text: product titles, seller names, descriptions.
class WaveUgcText extends StatelessWidget {
  const WaveUgcText(
    this.text, {
    required this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final dir = Bidi.detectRtlDirectionality(text)
        ? ui.TextDirection.rtl
        : ui.TextDirection.ltr;

    return Text(
      text,
      style: style,
      textDirection: dir,
      textAlign: TextAlign.start,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
