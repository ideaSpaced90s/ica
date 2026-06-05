import 'package:flutter/material.dart';
import 'piece_motion_profile.dart';

/// Micro-settle animation played on the target square immediately after a
/// piece lands. Produces a brief scale compression then spring-back.
///
/// Duration: ≤ 100ms
/// Cost: 1 AnimationController, 2 Transform.scale calls
class LandingFeedback extends StatefulWidget {
  /// The chess square where the piece just landed (e.g. 'e4').
  final String squareName;

  /// Motion profile of the piece that landed, determines compression amount.
  final PieceMotionProfile profile;

  /// Size of a single board square in logical pixels.
  final double squareSize;

  /// Board coordinate system helpers.
  final int squareRow;
  final int squareCol;
  final bool isFlipped;
  final bool isCritical;

  /// Fires when the settle animation is fully complete.
  final VoidCallback onComplete;

  const LandingFeedback({
    super.key,
    required this.squareName,
    required this.profile,
    required this.squareSize,
    required this.squareRow,
    required this.squareCol,
    required this.isFlipped,
    this.isCritical = false,
    required this.onComplete,
  });

  @override
  State<LandingFeedback> createState() => _LandingFeedbackState();
}

class _LandingFeedbackState extends State<LandingFeedback>
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
          duration: widget.isCritical
              ? const Duration(milliseconds: 180)
              : const Duration(milliseconds: 90),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onComplete();
          }
        });

    // Scale: compress briefly then spring back to 1.0
    // Goes: 1.0 → (1.0 - compression) → 1.0 using a custom sequence
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.0 - _compression,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0 - _compression,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    // Optional square highlight flash — opacity only, no color
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: widget.isCritical ? 0.22 : 0.12,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: widget.isCritical ? 0.22 : 0.12,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  double get _compression {
    if (widget.isCritical) {
      return 0.025;
    }
    return 0.015;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Position centered on the landing square
    final col = widget.isFlipped ? 7 - widget.squareCol : widget.squareCol;
    final row = widget.isFlipped ? 7 - widget.squareRow : widget.squareRow;
    final left = col * widget.squareSize;
    final top = row * widget.squareSize;

    return Positioned(
      left: left,
      top: top,
      width: widget.squareSize,
      height: widget.squareSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // Square pressure effect (tile depression)
              Center(
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: widget.squareSize - 2, // slight margin for tile feel
                    height: widget.squareSize - 2,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: _opacityAnim.value * 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: _opacityAnim.value * 0.3,
                          ),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Optional square highlight flash
              Opacity(
                opacity: _opacityAnim.value * 0.5,
                child: Container(color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Parses a chess square name ('e4', 'a1', etc.) into row/col indices (0-based,
/// from White's perspective with rank 8 = row 0).
({int row, int col}) squareToRowCol(String square) {
  final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final row = 8 - int.parse(square[1]);
  return (row: row, col: col);
}
