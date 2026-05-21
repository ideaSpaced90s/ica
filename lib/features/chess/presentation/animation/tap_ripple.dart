import 'package:flutter/material.dart';

/// An upgraded click-echo animation.
///
/// Standard mode (arcadeMode = false): scale + fade only (120ms).
/// Arcade mode (arcadeMode = true):
///   - Wider scale spread (0.6 → 1.6)
///   - Blue-tinted outer ring
///   - Center flash dot
///   - Duration: 200ms
class TapRipple extends StatefulWidget {
  /// Position of the tapped square in board-local coordinates (top-left corner).
  final Offset position;

  /// Size of one board square in logical pixels.
  final double squareSize;

  /// Whether arcade-mode ripple style is active.
  final bool arcadeMode;

  /// Fires when the ripple animation completes.
  final VoidCallback onComplete;

  const TapRipple({
    super.key,
    required this.position,
    required this.squareSize,
    required this.onComplete,
    this.arcadeMode = false,
  });

  @override
  State<TapRipple> createState() => _TapRippleState();
}

class _TapRippleState extends State<TapRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  // Arcade extras
  late Animation<double> _outerScaleAnim;
  late Animation<double> _outerOpacityAnim;

  @override
  void initState() {
    super.initState();
    final dur = widget.arcadeMode
        ? const Duration(milliseconds: 200)
        : const Duration(milliseconds: 120);

    _controller = AnimationController(vsync: this, duration: dur)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    if (widget.arcadeMode) {
      // Inner ring: 0.6 → 1.4, white
      _scaleAnim = Tween<double>(begin: 0.6, end: 1.4).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _opacityAnim = Tween<double>(begin: 0.32, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );
      // Outer ring: 0.4 → 1.7, blue tint (starts slightly later)
      _outerScaleAnim = Tween<double>(begin: 0.4, end: 1.7).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
        ),
      );
      _outerOpacityAnim = Tween<double>(begin: 0.45, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.1, 1.0, curve: Curves.easeIn),
        ),
      );
    } else {
      // Classic behaviour
      _scaleAnim = Tween<double>(begin: 0.85, end: 1.35).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _opacityAnim = Tween<double>(begin: 0.28, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );
      _outerScaleAnim = const AlwaysStoppedAnimation(0.0);
      _outerOpacityAnim = const AlwaysStoppedAnimation(0.0);
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sq = widget.squareSize;
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      width: sq,
      height: sq,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer blue ring (arcade only)
                if (widget.arcadeMode)
                  Transform.scale(
                    scale: _outerScaleAnim.value,
                    child: Container(
                      width: sq * 0.78,
                      height: sq * 0.78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(
                            alpha: _outerOpacityAnim.value,
                          ),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                // Inner white ring (both modes)
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: sq * 0.72,
                    height: sq * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: _opacityAnim.value),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Center flash dot (arcade only)
                if (widget.arcadeMode)
                  Builder(
                    builder: (context) {
                      final t = _controller.value;
                      // Flash: appears 0→12% of duration then fades by 60%
                      double flashOpacity;
                      if (t < 0.12) {
                        flashOpacity = t / 0.12 * 0.7;
                      } else {
                        flashOpacity =
                            (1.0 - (t - 0.12) / 0.48).clamp(0.0, 0.7);
                      }
                      return Container(
                        width: sq * 0.14,
                        height: sq * 0.14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF93C5FD)
                              .withValues(alpha: flashOpacity),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: flashOpacity * 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
