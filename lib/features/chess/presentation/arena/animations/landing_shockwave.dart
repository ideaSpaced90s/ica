import 'package:flutter/material.dart';

/// Expanding shockwave ring shown on piece landing in Arcade Mode.
///
/// Positioned over the destination square; starts at 30% of squareSize
/// and expands to 110%, fading from opacity 0.6 → 0.
/// Duration: 280ms, Curves.easeOut.
class LandingShockwave extends StatefulWidget {
  final double squareSize;
  final int squareRow;
  final int squareCol;
  final bool isFlipped;
  final VoidCallback onComplete;

  const LandingShockwave({
    super.key,
    required this.squareSize,
    required this.squareRow,
    required this.squareCol,
    required this.isFlipped,
    required this.onComplete,
  });

  @override
  State<LandingShockwave> createState() => _LandingShockwaveState();
}

class _LandingShockwaveState extends State<LandingShockwave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _scaleAnim = Tween<double>(begin: 0.30, end: 1.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnim = Tween<double>(begin: 0.60, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.isFlipped ? 7 - widget.squareCol : widget.squareCol;
    final row = widget.isFlipped ? 7 - widget.squareRow : widget.squareRow;
    final left = col * widget.squareSize;
    final top = row * widget.squareSize;
    final sq = widget.squareSize;

    return Positioned(
      left: left,
      top: top,
      width: sq,
      height: sq,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final ringSize = sq * _scaleAnim.value;
            final offset = (sq - ringSize) / 2;
            return Stack(
              children: [
                // Outer glow ring
                Positioned(
                  left: offset,
                  top: offset,
                  child: Opacity(
                    opacity: (_opacityAnim.value * 0.5).clamp(0.0, 1.0),
                    child: Container(
                      width: ringSize,
                      height: ringSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 5.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x663B82F6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner crisp ring
                Positioned(
                  left: offset,
                  top: offset,
                  child: Opacity(
                    opacity: _opacityAnim.value.clamp(0.0, 1.0),
                    child: Container(
                      width: ringSize,
                      height: ringSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF60A5FA),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
