import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AmbientFlowBackdrop extends StatefulWidget {
  final Color blob1Color;
  final Color blob2Color;
  final Color blob3Color;
  final Color backgroundColor;
  final Color? overlayColor;

  const AmbientFlowBackdrop({
    super.key,
    this.blob1Color = const Color(0xFFDBEAFE), // Default: soft blue
    this.blob2Color = const Color(0xFFFEF3C7), // Default: soft amber
    this.blob3Color = const Color(0xFFF3E8FF), // Default: soft purple
    this.backgroundColor = const Color(0xFFF8F9FA),
    this.overlayColor,
  });

  @override
  State<AmbientFlowBackdrop> createState() => _AmbientFlowBackdropState();
}

class _AmbientFlowBackdropState extends State<AmbientFlowBackdrop>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    // Use different durations to avoid synchronized repetition
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base background color matching scholarly theme backgroundStart
        Container(
          color: widget.backgroundColor,
        ),
        // Blob 1: Soft Indigo/Blue
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            final angle = _controller1.value * 2 * pi;
            // Orbit around center-left
            final dx = size.width * 0.2 + cos(angle) * 80;
            final dy = size.height * 0.3 + sin(angle) * 120;
            return Positioned(
              left: dx - 180,
              top: dy - 180,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.blob1Color,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Blob 2: Soft Amber/Yellow
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            final angle = _controller2.value * 2 * pi;
            // Orbit around center-right
            final dx = size.width * 0.8 + sin(angle) * 100;
            final dy = size.height * 0.6 + cos(angle) * 140;
            return Positioned(
              left: dx - 200,
              top: dy - 200,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.blob2Color,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Blob 3: Soft Lavender/Pink
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            final angle = _controller3.value * 2 * pi;
            // Orbit around center-bottom
            final dx = size.width * 0.4 + cos(angle) * 120;
            final dy = size.height * 0.85 + sin(angle) * 70;
            return Positioned(
              left: dx - 160,
              top: dy - 160,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.blob3Color,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Blur Filter to merge them into a smooth liquid gradient
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              color: widget.overlayColor ?? Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}
