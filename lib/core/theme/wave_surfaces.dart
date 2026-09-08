import 'package:flutter/material.dart';

abstract final class _RadiiRaw {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double xl = 28;
  static const double full = 999;
}

class WaveSurfaces extends ThemeExtension<WaveSurfaces> {
  const WaveSurfaces({
    required this.radiusChip,
    required this.radiusButton,
    required this.radiusCard,
    required this.radiusSheet,
    required this.radiusFull,
  });

  factory WaveSurfaces.standard() => const WaveSurfaces(
        radiusChip: _RadiiRaw.xs,
        radiusButton: _RadiiRaw.sm,
        radiusCard: _RadiiRaw.md,
        radiusSheet: _RadiiRaw.xl,
        radiusFull: _RadiiRaw.full,
      );
  
  final double radiusChip;
  final double radiusButton;
  final double radiusCard;
  final double radiusSheet;
  final double radiusFull;

  // --- LEGACY BRIDGE ---
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  List<BoxShadow> get resting => const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))];
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  List<BoxShadow> get raised => const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))];
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  List<BoxShadow> get floating => const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))];
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  int get blurSigma => 12;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  int get blurSigmaLowEnd => 6;
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  Color get glassFill => const Color(0x33FFFFFF);
  
  @Deprecated('Legacy bridge. Removed when P16 completes.')
  Color get glassBorder => const Color(0x33FFFFFF);
  
  // ignore: prefer_constructors_over_static_methods
  static WaveSurfaces of(BuildContext context) {
    final ext = Theme.of(context).extension<WaveSurfaces>();
    assert(ext != null, 'WaveSurfaces missing.');
    return ext ?? WaveSurfaces.standard();
  }

  @override
  WaveSurfaces copyWith({
    double? radiusChip,
    double? radiusButton,
    double? radiusCard,
    double? radiusSheet,
    double? radiusFull,
  }) {
    return WaveSurfaces(
      radiusChip: radiusChip ?? this.radiusChip,
      radiusButton: radiusButton ?? this.radiusButton,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusSheet: radiusSheet ?? this.radiusSheet,
      radiusFull: radiusFull ?? this.radiusFull,
    );
  }

  @override
  WaveSurfaces lerp(covariant WaveSurfaces? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
