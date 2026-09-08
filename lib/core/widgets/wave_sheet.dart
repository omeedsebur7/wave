import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_motion.dart';

/// The one sheet. P3: one drag handle, one radius, one padding rule.
///
/// Presentation is a static method rather than a widget, because a sheet is
/// a route, and routing it through here means no feature can reach for a raw
/// showModalBottomSheet and invent its own chrome.
abstract final class WaveSheet {
  /// [dismissible] false blocks scrim-tap, drag-down, and the system back
  /// gesture — for decisions that must be answered, like a declined payment.
  /// Use it sparingly: a sheet that traps the user is a last resort.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
    bool dismissible = true,
    Widget? footer,
    bool fullHeight = false,
  }) {
    final m = context.motion;
    final c = context.waveColors;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      // TURNED OFF: We disabled the native linear drag so our custom Spring
      // simulation takes complete control of the gesture physics (§3.1).
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: c.scrim,
      sheetAnimationStyle: AnimationStyle(
        curve: m.emphasized,
        duration: WaveMotion.resolve(context, m.slow),
        reverseCurve: m.accelerate,
        reverseDuration: WaveMotion.resolve(context, m.base),
      ),
      builder: (context) => _WaveSheetShell(
        title: title,
        dismissible: dismissible,
        footer: footer,
        fullHeight: fullHeight,
        child: Builder(builder: builder),
      ),
    );
  }
}

class _WaveSheetShell extends StatefulWidget {
  const _WaveSheetShell({
    required this.title,
    required this.dismissible,
    required this.footer,
    required this.fullHeight,
    required this.child,
  });

  final String title;
  final bool dismissible;
  final Widget? footer;
  final bool fullHeight;
  final Widget child;

  @override
  State<_WaveSheetShell> createState() => _WaveSheetShellState();
}

class _WaveSheetShellState extends State<_WaveSheetShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _physicsController =
      AnimationController(vsync: this);
  double _dragOffset = 0;
  final GlobalKey _sheetKey = GlobalKey();

  @override
  void dispose() {
    _physicsController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(double delta) {
    if (!widget.dismissible) return;
    // The spring resists being dragged upward past its origin (Rubber-banding).
    if (_dragOffset + delta < 0) {
      _dragOffset = _dragOffset + (delta * 0.1); 
    } else {
      _dragOffset += delta;
    }
    setState(() {});
  }

  void _handleDragEnd(double velocity) {
    if (!widget.dismissible) return;
    final box =
        _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    final sheetHeight =
        box?.size.height ?? MediaQuery.sizeOf(context).height;

    final isFlingDown = velocity > 400; // pixels per sec
    final isDraggedFar = _dragOffset > sheetHeight * 0.35;

    if (isFlingDown || isDraggedFar) {
      _springOutAndPop(velocity: velocity, sheetHeight: sheetHeight);
    } else {
      // Settles back to open state via Physics
      final spring = context.motion.sheetSpring;
      final sim = SpringSimulation(spring, _dragOffset, 0, velocity);

      _physicsController.animateWith(sim);
    }
  }

  void _springOutAndPop({double velocity = 1500.0, double? sheetHeight}) {
    if (!widget.dismissible) return;
    final height = sheetHeight ??
        (_sheetKey.currentContext?.findRenderObject() as RenderBox?)
            ?.size
            .height ??
        MediaQuery.sizeOf(context).height;

    final spring = context.motion.sheetSpring;
    final sim = SpringSimulation(spring, _dragOffset, height, velocity);

    _physicsController.animateWith(sim).whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void initState() {
    super.initState();
    _physicsController.addListener(() {
      setState(() {
        _dragOffset = _physicsController.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;
    final radius = context.surfaces.radiusSheet;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).top -
        s.x48;

    return Transform.translate(
      // Connects the visual translation directly to the Physics engine
      offset: Offset(0, _dragOffset < 0 ? _dragOffset : _dragOffset),
      child: PopScope(
        canPop: widget.dismissible,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              minHeight: widget.fullHeight ? maxHeight : 0,
            ),
            child: DecoratedBox(
              key: _sheetKey,
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
                boxShadow: c.shadowFloating,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SIGNATURE MOVE: The grab area drives the spring physics
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) =>
                          _handleDragUpdate(details.primaryDelta!),
                      onVerticalDragEnd: (details) =>
                          _handleDragEnd(details.primaryVelocity!),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.dismissible) const _DragHandle(),
                          _Header(
                            title: widget.title,
                            dismissible: widget.dismissible,
                            onClose: _springOutAndPop,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          s.x16,
                          s.x8,
                          s.x16,
                          widget.footer == null ? s.x24 : s.x16,
                        ),
                        child: widget.child,
                      ),
                    ),
                    if (widget.footer != null) _Footer(child: widget.footer!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: s.x12, bottom: s.x8),
        child: Container(
          width: s.x40,
          height: s.x4,
          decoration: BoxDecoration(
            color: c.divider,
            borderRadius: BorderRadius.circular(context.surfaces.radiusFull),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.dismissible,
    required this.onClose,
  });

  final String title;
  final bool dismissible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.texts;
    final s = context.spacing;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(s.x16, s.x8, s.x8, s.x8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: t.title),
            ),
          ),
          if (dismissible)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose, // Uses the physics animation instead of basic pop
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.all(s.x16),
          child: child,
        ),
      ),
    );
  }
}
