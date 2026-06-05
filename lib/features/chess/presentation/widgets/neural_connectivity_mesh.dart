import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../scholarly_theme.dart';

class NeuralConnectivityMesh extends StatefulWidget {
  final double size;
  final Color? color;

  const NeuralConnectivityMesh({
    super.key,
    this.size = 28.0,
    this.color,
  });

  @override
  State<NeuralConnectivityMesh> createState() => _NeuralConnectivityMeshState();
}

class _NeuralConnectivityMeshState extends State<NeuralConnectivityMesh>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? ScholarlyTheme.accentBlue;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _NeuralMeshPainter(
              progress: _controller.value,
              color: themeColor,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class _NeuralMeshPainter extends CustomPainter {
  final double progress;
  final Color color;

  _NeuralMeshPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double angle = progress * 2.0 * math.pi;

    // Define 5 nodes that drift inside a normalized (-1 to 1) coordinate system
    // using different trig functions to create organic, non-linear movement.
    final List<Offset> nodes = [
      Offset(
        w * 0.5 + w * 0.28 * math.sin(angle),
        h * 0.5 + h * 0.28 * math.cos(angle * 1.5),
      ),
      Offset(
        w * 0.5 + w * 0.32 * math.cos(angle * 1.2 + 1.0),
        h * 0.5 + h * 0.25 * math.sin(angle * 0.8 + 0.5),
      ),
      Offset(
        w * 0.5 + w * 0.25 * math.sin(angle * 0.9 - 1.5),
        h * 0.5 + h * 0.30 * math.cos(angle * 1.1 + 2.0),
      ),
      Offset(
        w * 0.5 + w * 0.30 * math.cos(angle * 1.4 + 2.5),
        h * 0.5 + h * 0.28 * math.sin(angle * 1.6 - 1.0),
      ),
      Offset(
        w * 0.5 + w * 0.22 * math.sin(angle * 2.0 + 3.0),
        h * 0.5 + h * 0.22 * math.cos(angle * 0.7 + 1.2),
      ),
    ];

    // 1. Draw connections
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glowLinePaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final double dist = (nodes[i] - nodes[j]).distance;
        final double maxDistance = w * 0.75;
        
        if (dist < maxDistance) {
          // Fade line opacity based on distance
          final double opacityFactor = (1.0 - (dist / maxDistance)).clamp(0.0, 1.0);
          
          linePaint.color = color.withValues(alpha: 0.22 * opacityFactor);
          glowLinePaint.color = color.withValues(alpha: 0.08 * opacityFactor);

          canvas.drawLine(nodes[i], nodes[j], glowLinePaint);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // 2. Draw nodes (dots and glows)
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < nodes.length; i++) {
      // Draw outer soft glow
      canvas.drawCircle(nodes[i], 3.5, glowPaint);
      // Draw inner core dot
      canvas.drawCircle(nodes[i], 1.8, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralMeshPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
