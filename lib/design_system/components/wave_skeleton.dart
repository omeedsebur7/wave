import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';

class WaveShimmerScope extends StatefulWidget {
  const WaveShimmerScope({required this.child, super.key});

  final Widget child;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ShimmerClock>()
      ?.animation;

  @override
  State<WaveShimmerScope> createState() => _WaveShimmerScopeState();
}

class _WaveShimmerScopeState extends State<WaveShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.motion.shimmerLoop;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerClock(animation: _controller, child: widget.child);
}

class _ShimmerClock extends InheritedWidget {
  const _ShimmerClock({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ShimmerClock old) => animation != old.animation;
}

class WaveSkeleton extends StatelessWidget {
  const WaveSkeleton({
    required this.width,
    required this.height,
    this.radius,
    super.key,
  });

  const WaveSkeleton.line({required this.height, this.radius, super.key})
      : width = double.infinity;

  final double width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final clock = WaveShimmerScope.maybeOf(context);
    final r = radius ?? context.surfaces.radiusChip;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(width, height),
          painter: _ShimmerPainter(
            progress: clock ?? const AlwaysStoppedAnimation(0),
            animate: clock != null,
            base: c.skeletonBase,
            highlight: c.skeletonHighlight,
            radius: r,
            // تێبینییەکەی پێداچوونەوەکارەکە بۆ ئاڕاستەی زمانی کوردی و عەرەبی
            isRtl: Directionality.of(context) == TextDirection.rtl,
          ),
          child: SizedBox(width: width, height: height),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.progress,
    required this.animate,
    required this.base,
    required this.highlight,
    required this.radius,
    required this.isRtl,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final bool animate;
  final Color base;
  final Color highlight;
  final double radius;
  final bool isRtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    if (!animate) {
      canvas.drawRRect(rrect, Paint()..color = base);
      return;
    }

    final t = progress.value;
    final band = size.width * 0.6;
    
    // ئاڕاستەی جولەی شیمەرەکە پێچەوانە دەکرێتەوە ئەگەر زمانەکە کوردی بێت
    final x = isRtl 
        ? size.width + band - t * (size.width + band * 2) 
        : -band + t * (size.width + band * 2);

    final shader = LinearGradient(
      colors: [base, highlight, base],
      stops: const [0.35, 0.5, 0.65],
    ).createShader(Rect.fromLTWH(x - band, 0, band * 2, size.height));

    canvas.drawRRect(rrect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      base != old.base ||
      highlight != old.highlight ||
      radius != old.radius ||
      animate != old.animate ||
      isRtl != old.isRtl;
}
