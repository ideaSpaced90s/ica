import 'package:flutter/material.dart';

class EvaluationBar extends StatefulWidget {
  final double fillFraction; // 0.0 (black dominating) to 1.0 (white dominating)

  const EvaluationBar({super.key, required this.fillFraction});

  @override
  State<EvaluationBar> createState() => _EvaluationBarState();
}

class _EvaluationBarState extends State<EvaluationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;
  double _previousFill = 0.5;

  @override
  void initState() {
    super.initState();
    _previousFill = widget.fillFraction;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fillAnimation = Tween<double>(
      begin: widget.fillFraction,
      end: widget.fillFraction,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(EvaluationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillFraction != widget.fillFraction) {
      _fillAnimation = Tween<double>(
        begin: _previousFill,
        end: widget.fillFraction,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
      _previousFill = widget.fillFraction;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBarColor(double fill) {
    if (fill > 0.62) return const Color(0xFF34D399); // Green advantage
    if (fill < 0.38) return const Color(0xFFFC8181); // Red disadvantage
    return const Color(0xFF93C5FD); // Blue / balanced
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, _) {
        final fill = _fillAnimation.value.clamp(0.0, 1.0);
        final barColor = _getBarColor(fill);
        const barHeight = 32.0;
        final fillHeight = barHeight * fill;

        return Container(
          width: 5,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFDDE3EC),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.antiAlias,
            children: [
              // Fill gradient
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 5,
                  height: fillHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        barColor,
                        barColor.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                ),
              ),
              // Glow cap at the divider line
              Positioned(
                bottom: (fillHeight - 1.5).clamp(0.0, barHeight - 3),
                child: Container(
                  width: 5,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: barColor,
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.85),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
