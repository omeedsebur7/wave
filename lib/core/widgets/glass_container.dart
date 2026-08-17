import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';

enum GlassElevation { resting, raised, floating }

/// The glassmorphism primitive (§3.4). Blur 20px, 12px fallback on low-end
/// devices, white fill at 8–12% (light) / 4–6% (dark), 1px white border at
/// ~19%.
///
/// `GlassElevation.floating` is the only tier that carries the accent glow, and
/// it's rationed on purpose — FAB, active product card, 3D viewer. Everywhere
/// else the glow stops reading as a signature and starts reading as noise.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    this.elevation = GlassElevation.resting,
    this.radius = WaveSurfaces.radiusCard,
    this.padding = const EdgeInsets.all(16),
    this.lowEndDevice = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final GlassElevation elevation;
  final double radius;
  final EdgeInsets padding;

  /// Set from a device-capability check at startup; drops blur 20 → 12.
  final bool lowEndDevice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    final sigma = lowEndDevice ? s.blurSigmaLowEnd : s.blurSigma;
    final shadows = switch (elevation) {
      GlassElevation.resting => s.resting,
      GlassElevation.raised => s.raised,
      GlassElevation.floating => s.floating,
    };

    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Material(
            color: s.glassFill,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: s.glassBorder),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
