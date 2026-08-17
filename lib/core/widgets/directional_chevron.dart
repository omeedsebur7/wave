import 'package:flutter/material.dart';

/// A chevron that points the way the text runs.
///
/// `Icons.chevron_right` does not flip in an RTL layout. Flutter mirrors
/// padding, alignment and row order automatically, so a hardcoded right-facing
/// chevron ends up pointing back towards the start of the line — at the very
/// list rows where it is meant to mean "forward, into this". Five screens had
/// one.
///
/// Flutter's own `IconData` carries a `matchTextDirection` flag, but the
/// `Icons` constants do not set it, so the choice has to be made here from the
/// ambient directionality.
class DirectionalChevron extends StatelessWidget {
  const DirectionalChevron({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left
            : Icons.chevron_right,
        size: size,
        color: color,
      );
}
