import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_motion.dart';

abstract final class WavePages {
  static Page<T> sharedAxis<T>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    final m = context.motion;

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: WaveMotion.resolve(context, m.base),
      reverseTransitionDuration: WaveMotion.resolve(context, m.fast),
      transitionsBuilder: (context, animation, secondary, child) {
        final dir = Directionality.of(context);
        final sign = dir == TextDirection.rtl ? -1 : 1;

        final enter = Tween<Offset>(
          begin: Offset(0.25 * sign, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: m.emphasized));

        final exit = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(-0.12 * sign, 0),
        ).animate(CurvedAnimation(parent: secondary, curve: m.emphasized));

        return SlideTransition(
          position: exit,
          child: SlideTransition(
            position: enter,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
    );
  }

  static Page<T> fadeThrough<T>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    final m = context.motion;

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: WaveMotion.resolve(context, m.base),
      reverseTransitionDuration: WaveMotion.resolve(context, m.fast),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.35, 1, curve: Curves.easeOut),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(
              CurvedAnimation(parent: animation, curve: m.emphasized),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
