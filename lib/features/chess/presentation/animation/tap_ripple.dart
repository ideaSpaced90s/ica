import 'package:flutter/material.dart';

/// A lightweight click echo animation — scale + fade only.
/// Duration: 120ms. No color, no blur, no particles.
///
/// Triggered from _handleSquareTap in chess_board.dart on any tap.
class TapRipple extends StatefulWidget {
  /// Position of the tapped square in board-local coordinates (top-left corner).
  final Offset position;

  /// Size of one board square in logical pixels.
  final double squareSize;

  /// Fires when the ripple animation completes.
  final VoidCallback onComplete;

  const TapRipple({
    super.key,
    required this.position,
    required this.squareSize,
    required this.onComplete,
  });

  @override
  State<TapRipple> createState() => _TapRippleState();
}

class _TapRippleState extends State<TapRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 120),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onComplete();
          }
        });

    // Scale: 0.85 → 1.35 (starts slightly compressed, expands outward)
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Opacity: 0.28 → 0.0 (quick fade)
    _opacityAnim = Tween<double>(
      begin: 0.28,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      width: widget.squareSize,
      height: widget.squareSize,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Center(
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: widget.squareSize * 0.72,
                  height: widget.squareSize * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: _opacityAnim.value),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
