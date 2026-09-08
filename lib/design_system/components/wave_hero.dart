import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';

class WaveHero extends StatelessWidget {
  const WaveHero({
    required this.tag,
    required this.fromRadius,
    required this.toRadius,
    required this.child,
    super.key,
  });

  final String tag;
  final double fromRadius;
  final double toRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = context.motion;

    return Hero(
      tag: tag,
      createRectTween: (begin, end) =>
          MaterialRectArcTween(begin: begin, end: end),
      flightShuttleBuilder: (context, animation, direction, fromCtx, toCtx) {
        final forward = direction == HeroFlightDirection.push;
        final from = forward ? fromRadius : toRadius;
        final to = forward ? toRadius : fromRadius;

        final curved = CurvedAnimation(parent: animation, curve: m.emphasized);

        return AnimatedBuilder(
          animation: curved,
          builder: (context, _) => ClipRRect(
            borderRadius: BorderRadius.circular(
              lerpDouble(from, to, curved.value)!,
            ),
            child: forward ? toCtx.widget : fromCtx.widget,
          ),
        );
      },
      child: child,
    );
  }
}
