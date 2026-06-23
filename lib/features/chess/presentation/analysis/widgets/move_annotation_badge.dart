import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/study_lab_provider.dart';

class MoveAnnotationBadge extends StatefulWidget {
  final MoveAnnotation annotation;
  
  const MoveAnnotationBadge({
    super.key,
    required this.annotation,
  });

  @override
  State<MoveAnnotationBadge> createState() => _MoveAnnotationBadgeState();
}

class _MoveAnnotationBadgeState extends State<MoveAnnotationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Subtle shake animation sequence for Blunders (??)
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -3.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -3.0, end: 3.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 3.0, end: -2.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -2.0, end: 2.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 2.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(MoveAnnotationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.annotation != widget.annotation) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.annotation == MoveAnnotation.none) {
      return const SizedBox.shrink();
    }

    final color = widget.annotation.color;
    final glyph = widget.annotation.glyph;
    final isBrilliant = widget.annotation == MoveAnnotation.brilliant;
    final isBlunder = widget.annotation == MoveAnnotation.blunder;

    Widget badgeContent = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
          if (isBrilliant)
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: Text(
          glyph,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: glyph.length > 1 ? 8 : 10,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );

    // Brilliant moves pulse/glow
    if (isBrilliant) {
      badgeContent = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulseVal = math.sin(_controller.value * math.pi * 2);
          final scaleFactor = 1.0 + 0.08 * pulseVal;
          return Transform.scale(
            scale: scaleFactor,
            child: child,
          );
        },
        child: badgeContent,
      );
    }

    // Apply scale and shake transitions
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double offset = 0.0;
        if (isBlunder && _controller.value > 0.5) {
          offset = _shakeAnimation.value;
        }

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: badgeContent,
    );
  }
}
