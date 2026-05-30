import 'dart:math' as math;
import 'package:flutter/material.dart';

class AcademyOrbitingStarAnimation extends StatefulWidget {
  final Color color;
  final bool isActive;
  final bool isCircle;

  const AcademyOrbitingStarAnimation({
    super.key,
    required this.color,
    required this.isActive,
    this.isCircle = false,
  });

  @override
  State<AcademyOrbitingStarAnimation> createState() => _AcademyOrbitingStarAnimationState();
}

class _AcademyOrbitingStarAnimationState extends State<AcademyOrbitingStarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AcademyOrbitingStarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AcademyOrbitingStarPainter(
            progress: _controller.value,
            color: widget.color,
            isCircle: widget.isCircle,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AcademyOrbitingStarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isCircle;

  _AcademyOrbitingStarPainter({
    required this.progress,
    required this.color,
    required this.isCircle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pathRect = rect.deflate(2.0);

    final totalLength = isCircle
        ? (2 * math.pi * (pathRect.width / 2))
        : (pathRect.width * 4);
    final currentPos = progress * totalLength;

    Offset getPos(double distance) {
      if (isCircle) {
        final center = pathRect.center;
        final radius = pathRect.width / 2;
        final p = distance / totalLength;
        final angle = -math.pi / 2 + p * 2 * math.pi;
        return Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
      } else {
        double d = distance % totalLength;
        if (d < 0) d += totalLength;

        final w = pathRect.width;
        final h = pathRect.height;

        if (d < w) {
          return Offset(pathRect.left + d, pathRect.top);
        } else if (d < w + h) {
          return Offset(pathRect.right, pathRect.top + (d - w));
        } else if (d < 2 * w + h) {
          return Offset(pathRect.right - (d - (w + h)), pathRect.bottom);
        } else {
          return Offset(pathRect.left, pathRect.bottom - (d - (2 * w + h)));
        }
      }
    }

    final pulse = (math.sin(progress * math.pi * 16) + 1) / 2;
    final headRadius = 2.5 + (pulse * 2.0);
    final glowRadius = 5.0 + (pulse * 3.0);

    const trailPoints = 25;
    const trailLength = 45.0;

    for (int i = 0; i < trailPoints; i++) {
      final double pointAlpha = (1.0 - (i / trailPoints)).clamp(0.0, 1.0);
      final double offset = (i / trailPoints) * trailLength;

      final jitterX = math.sin(currentPos - offset) * 1.5 * (i / trailPoints);
      final jitterY = math.cos(currentPos - offset) * 1.5 * (i / trailPoints);
      final basePos = getPos(currentPos - offset);
      final position = Offset(basePos.dx + jitterX, basePos.dy + jitterY);

      final paint = Paint()
        ..color = color.withValues(alpha: pointAlpha * 0.9)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (1.0 + i * 0.4));

      canvas.drawCircle(position, (3.5 - (i / trailPoints) * 2.5), paint);
    }

    final headPos = getPos(currentPos);
    final headPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(headPos, headRadius, headPaint);

    final glowPaint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
    canvas.drawCircle(headPos, glowRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _AcademyOrbitingStarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class AcademySquareGlow extends StatefulWidget {
  final Color color;

  const AcademySquareGlow({super.key, required this.color});

  @override
  State<AcademySquareGlow> createState() => _AcademySquareGlowState();
}

class _AcademySquareGlowState extends State<AcademySquareGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
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
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * (1.0 - _controller.value)),
                blurRadius: 20 * _controller.value,
                spreadRadius: 10 * _controller.value,
              ),
            ],
            border: Border.all(
              color: widget.color.withValues(alpha: 0.8 * (1.0 - _controller.value)),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
