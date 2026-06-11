import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedCheckWidget extends StatefulWidget {
  final bool isCompleted;
  final bool animate; // true = play full animation, false = static state
  final double size;

  const AnimatedCheckWidget({
    super.key,
    required this.isCompleted,
    this.animate = false,
    this.size = 32.0,
  });

  @override
  State<AnimatedCheckWidget> createState() => _AnimatedCheckWidgetState();
}

class _AnimatedCheckWidgetState extends State<AnimatedCheckWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;
  late Animation<double> _strokeAnimation;
  late Animation<double> _burstAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
    ));

    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
    ));

    _strokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
    ));

    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
    ));

    if (widget.animate && widget.isCompleted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCheckWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCompleted) {
      // Static incomplete: empty circle outline
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 2.0,
          ),
        ),
      );
    }

    if (!widget.animate) {
      // Static completed: filled circle with checkmark
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green,
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: widget.size * 0.65,
        ),
      );
    }

    // Animated checkmark
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double scale = _scaleAnimation.value;
        final double colorProgress = _colorAnimation.value;
        final Color circleColor = Color.lerp(
          Colors.white.withValues(alpha: 0.1),
          Colors.green,
          colorProgress,
        )!;

        return Transform.scale(
          scale: scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Particles burst
              Positioned.fill(
                child: CustomPaint(
                  painter: ParticlesPainter(
                    progress: _burstAnimation.value,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              // Circle and checkmark
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 1.0 - colorProgress),
                    width: 2.0 * (1.0 - colorProgress),
                  ),
                ),
                child: CustomPaint(
                  painter: CheckmarkPainter(
                    progress: _strokeAnimation.value,
                    color: Colors.white,
                    strokeWidth: widget.size * 0.09,
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

class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.27, size.height * 0.54)
      ..lineTo(size.width * 0.45, size.height * 0.72)
      ..lineTo(size.width * 0.75, size.height * 0.35);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extract = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class ParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final double maxRadius = size.width * 0.95;
    final double currentRadius = maxRadius * progress;
    final double opacity = 1.0 - progress;
    final Paint paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final double dotRadius = 2.0 * (1.0 - progress * 0.5);

    for (int i = 0; i < 6; i++) {
      final double angle = (i * 60) * 3.1415926535 / 180.0;
      final double dx = size.width / 2 + currentRadius * math.cos(angle);
      final double dy = size.height / 2 + currentRadius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
