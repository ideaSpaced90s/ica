import 'dart:math';
import 'package:flutter/material.dart';
import '../scholarly_theme.dart';

class SidebarDynamicBg extends StatefulWidget {
  const SidebarDynamicBg({super.key});

  @override
  State<SidebarDynamicBg> createState() => _SidebarDynamicBgState();
}

class _SidebarDynamicBgState extends State<SidebarDynamicBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Very slow duration (18 seconds per full cycle) for a subtle, soothing motion
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Solid base matching ScholarlyTheme backgroundStart
        Container(
          color: ScholarlyTheme.backgroundStart,
        ),
        // Flowing shadow waves on top
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: SidebarWavePainter(_controller.value),
            );
          },
        ),
      ],
    );
  }
}

class SidebarWavePainter extends CustomPainter {
  final double t;

  SidebarWavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Wave 1: Soft Cool Slate Shadow (Mid-low layer)
    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFF1F5F9).withValues(alpha: 0.0),
          const Color(0xFFE2E8F0).withValues(alpha: 0.4),
          const Color(0xFFF1F5F9).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path1 = Path();
    path1.moveTo(0, h * 0.4);
    for (double x = 0; x <= w; x++) {
      // Staggered sine/cosine combinations for organic movement
      final y = h * 0.4 +
          sin((x / w * 2 * pi) + (t * 2 * pi)) * 30 +
          cos((x / w * pi) - (t * pi)) * 12;
      path1.lineTo(x, y);
    }
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Wave 2: Extremely Soft Accent Blue Shadow (Lower layer)
    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFDBEAFE).withValues(alpha: 0.0),
          const Color(0xFFBFDBFE).withValues(alpha: 0.18),
          const Color(0xFFDBEAFE).withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path2 = Path();
    path2.moveTo(0, h * 0.6);
    for (double x = 0; x <= w; x++) {
      final y = h * 0.6 +
          cos((x / w * 2 * pi) - (t * 2 * pi * 1.1)) * 35 +
          sin((x / w * 1.5 * pi) + (t * pi)) * 18;
      path2.lineTo(x, y);
    }
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Wave 3: Subtle Amber/Gold glow (Near-bottom layer)
    final paint3 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFEF3C7).withValues(alpha: 0.0),
          const Color(0xFFFDE68A).withValues(alpha: 0.08),
          const Color(0xFFFEF3C7).withValues(alpha: 0.0),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path3 = Path();
    path3.moveTo(0, h * 0.78);
    for (double x = 0; x <= w; x++) {
      final y = h * 0.78 +
          sin((x / w * 2 * pi) + (t * 2 * pi * 0.9) + 1.2) * 25 +
          cos((x / w * pi) + (t * 2 * pi)) * 15;
      path3.lineTo(x, y);
    }
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant SidebarWavePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
