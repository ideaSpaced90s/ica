import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrbitingStarAnimation extends StatefulWidget {
  final Color color;
  final bool isActive;

  const OrbitingStarAnimation({
    super.key,
    required this.color,
    required this.isActive,
  });

  @override
  State<OrbitingStarAnimation> createState() => _OrbitingStarAnimationState();
}

class _OrbitingStarAnimationState extends State<OrbitingStarAnimation>
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
  void didUpdateWidget(OrbitingStarAnimation oldWidget) {
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
          painter: _OrbitingStarPainter(
            progress: _controller.value,
            color: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _OrbitingStarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitingStarPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Slightly inset the path to stay within square bounds
    final pathRect = rect.deflate(2.0);
    
    // Calculate position along the square perimeter
    // Perimeter length is 4 * side
    final totalLength = pathRect.width * 4;
    final currentPos = progress * totalLength;
    
    Offset getPos(double distance) {
      // Normalize distance to [0, totalLength)
      double d = distance % totalLength;
      if (d < 0) d += totalLength;
      
      final w = pathRect.width;
      final h = pathRect.height;
      
      if (d < w) {
        // Top edge (left to right)
        return Offset(pathRect.left + d, pathRect.top);
      } else if (d < w + h) {
        // Right edge (top to bottom)
        return Offset(pathRect.right, pathRect.top + (d - w));
      } else if (d < 2 * w + h) {
        // Bottom edge (right to left)
        return Offset(pathRect.right - (d - (w + h)), pathRect.bottom);
      } else {
        // Left edge (bottom to top)
        return Offset(pathRect.left, pathRect.bottom - (d - (2 * w + h)));
      }
    }

    // Calculate a pulsating factor based on progress
    final pulse = (math.sin(progress * math.pi * 16) + 1) / 2; // 0.0 to 1.0, 8 pulses per orbit
    final headRadius = 2.5 + (pulse * 2.0); // 2.5 to 4.5
    final glowRadius = 5.0 + (pulse * 3.0); // 5.0 to 8.0

    // Draw the tail (gradient/particles along the path)
    const trailPoints = 25; // More particles for smoother tail
    const trailLength = 45.0; // Slightly longer tail
    
    for (int i = 0; i < trailPoints; i++) {
        final double pointAlpha = (1.0 - (i / trailPoints)).clamp(0.0, 1.0);
        final double offset = (i / trailPoints) * trailLength;
        
        // Add slight random-looking jitter to the tail for "magic dust" effect
        // varying slightly by offset to keep it stable per position
        final jitterX = math.sin(currentPos - offset) * 1.5 * (i / trailPoints);
        final jitterY = math.cos(currentPos - offset) * 1.5 * (i / trailPoints);
        final basePos = getPos(currentPos - offset);
        final position = Offset(basePos.dx + jitterX, basePos.dy + jitterY);
        
        final paint = Paint()
          ..color = color.withValues(alpha: pointAlpha * 0.9) // slightly brighter
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, (1.0 + i * 0.4));
        
        canvas.drawCircle(position, (3.5 - (i / trailPoints) * 2.5), paint);
    }
    
    // Draw the head (brightest point)
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
  bool shouldRepaint(covariant _OrbitingStarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
