import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';

/// Shimmer placeholder (§3.5) — feeds, product grids and the 3D viewer never
/// show a blank screen or a bare spinner on first paint.
///
/// Respects reduced motion: when the user has asked the system to cut
/// animation, this falls back to a static block rather than pulsing.
class WaveSkeleton extends StatefulWidget {
  const WaveSkeleton({
    required this.width,
    required this.height,
    this.radius = WaveSurfaces.radiusChip,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<WaveSkeleton> createState() => _WaveSkeletonState();
}

class _WaveSkeletonState extends State<WaveSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
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
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final base = c.border;
    final highlight = Color.lerp(c.border, c.surface, 0.6)!;

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: _controller.isAnimating
                  ? LinearGradient(
                      begin: Alignment(-1 + t * 2, 0),
                      end: Alignment(1 + t * 2, 0),
                      colors: [base, highlight, base],
                    )
                  : null,
              color: _controller.isAnimating ? null : base,
            ),
          );
        },
      ),
    );
  }
}

/// Product-grid skeleton, sized to match the real card so the layout doesn't
/// jump when content lands.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WaveSkeleton(width: double.infinity, height: 160,
            radius: WaveSurfaces.radiusCard,),
        SizedBox(height: 8),
        WaveSkeleton(width: 140, height: 14),
        SizedBox(height: 6),
        WaveSkeleton(width: 80, height: 14),
      ],
    );
  }
}
