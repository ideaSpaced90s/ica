import 'dart:math';
import 'package:flutter/material.dart';

class LiquidBoardPainter extends CustomPainter {
  final double animationValue;
  final bool isLight;

  LiquidBoardPainter({required this.animationValue, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Shifting Liquid Gradient
    final gradient = LinearGradient(
      colors: isLight
          ? [
              const Color(0xFF7FFFD4),
              const Color(0xFF40E0D0),
            ] // Aqua to Turquoise
          : [const Color(0xFF004D40), const Color(0xFF00251A)], // Deep Teal
      begin: Alignment(
        cos(animationValue * 2 * pi) * 0.5 - 0.5,
        sin(animationValue * 2 * pi) * 0.5 - 0.5,
      ),
      end: Alignment(
        cos(animationValue * 2 * pi + pi) * 0.5 + 0.5,
        sin(animationValue * 2 * pi + pi) * 0.5 + 0.5,
      ),
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Subtle additive highlights for "water" feel
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isLight ? 0.05 : 0.02)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 3; i++) {
      final offset = Offset(
        size.width * (0.3 + 0.4 * cos(animationValue * 2 * pi + i)),
        size.height * (0.3 + 0.4 * sin(animationValue * 2 * pi + i)),
      );
      canvas.drawCircle(offset, size.width * 0.4, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(LiquidBoardPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class RippleMoveIndicator extends StatefulWidget {
  const RippleMoveIndicator({super.key});

  @override
  State<RippleMoveIndicator> createState() => _RippleMoveIndicatorState();
}

class _RippleMoveIndicatorState extends State<RippleMoveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Opacity(
                opacity: (1.0 - ((_controller.value + i / 3) % 1.0)).clamp(
                  0.0,
                  1.0,
                ),
                child: Container(
                  width: 30.0 * ((_controller.value + i / 3) % 1.0),
                  height: 30.0 * ((_controller.value + i / 3) % 1.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class LiquidSplashEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const LiquidSplashEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<LiquidSplashEffect> createState() => _LiquidSplashEffectState();
}

class _LiquidSplashEffectState extends State<LiquidSplashEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _droplets = List.generate(8, (index) {
    final angle = index * pi / 4;
    return Offset(cos(angle), sin(angle));
  });

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward().then((_) => widget.onComplete());
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var droplet in _droplets)
                Positioned(
                  left: droplet.dx * progress * 60 - 4,
                  top: droplet.dy * progress * 60 - 4,
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Container(
                      width: 8 * (1.0 - progress),
                      height: 8 * (1.0 - progress),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F7FA),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
