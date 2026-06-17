import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ArenaPieceEffectsWrapper
//
// Wraps the chess piece widget in a Stack with three layers:
//   [back layer]  ← orbiting elements that pass BEHIND the piece (z ≤ 0)
//   [piece]       ← the chess piece itself
//   [front layer] ← orbiting elements that pass IN FRONT of the piece (z > 0)
//
// This layering creates a genuine 3-D orbital illusion using 2-D Flutter.
// ─────────────────────────────────────────────────────────────────────────────
class ArenaPieceEffectsWrapper extends StatefulWidget {
  final Widget child;
  final bool isThreatened;
  final bool isDominating;

  const ArenaPieceEffectsWrapper({
    super.key,
    required this.child,
    required this.isThreatened,
    required this.isDominating,
  });

  @override
  State<ArenaPieceEffectsWrapper> createState() =>
      _ArenaPieceEffectsWrapperState();
}

class _ArenaPieceEffectsWrapperState extends State<ArenaPieceEffectsWrapper>
    with TickerProviderStateMixin {
  // Threat star: 2.8 s full orbit
  late final AnimationController _threatCtrl;
  // Dominating fire: 2.2 s full orbit, slightly faster for urgency
  late final AnimationController _dominCtrl;

  @override
  void initState() {
    super.initState();
    _threatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _dominCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _updateControllers();
  }

  @override
  void didUpdateWidget(ArenaPieceEffectsWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThreatened != oldWidget.isThreatened ||
        widget.isDominating != oldWidget.isDominating) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    if (widget.isThreatened) {
      if (!_threatCtrl.isAnimating) _threatCtrl.repeat();
    } else {
      _threatCtrl.stop();
    }
    if (widget.isDominating) {
      if (!_dominCtrl.isAnimating) _dominCtrl.repeat();
    } else {
      _dominCtrl.stop();
    }
  }

  @override
  void dispose() {
    _threatCtrl.dispose();
    _dominCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isThreatened || widget.isDominating;

    if (!active) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([_threatCtrl, _dominCtrl]),
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Back layer: elements passing behind the piece ──────────────
            if (widget.isThreatened)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ThreatOrbitPainter(
                    progress: _threatCtrl.value,
                    frontPass: false,
                  ),
                ),
              ),
            if (widget.isDominating)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DominatingFirePainter(
                    progress: _dominCtrl.value,
                    frontPass: false,
                  ),
                ),
              ),

            // ── Chess piece itself ─────────────────────────────────────────
            widget.child,

            // ── Front layer: elements passing in front of the piece ────────
            if (widget.isThreatened)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ThreatOrbitPainter(
                    progress: _threatCtrl.value,
                    frontPass: true,
                  ),
                ),
              ),
            if (widget.isDominating)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DominatingFirePainter(
                    progress: _dominCtrl.value,
                    frontPass: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ThreatOrbitPainter
//
// Draws the red shooting-star that orbits the forehead of a threatened piece.
//
// 3-D geometry (tilted circle):
//   The orbit lies in a plane tilted –20° from the horizontal (xz-plane).
//   The orbit centre is at (cx, headY) where headY ≈ 25 % from the top.
//   Radius R ≈ 22 % of the tile size.
//
//   For angle θ:
//     x = cx + R·cos(θ)
//     y = headY − R·sin(θ)·sin(tilt)    ← tilt projects the y component
//     z =        R·sin(θ)·cos(tilt)     ← depth (positive = towards viewer)
//
//   frontPass=true  → only draw when z > 0 (in front of piece)
//   frontPass=false → only draw when z ≤ 0 (behind piece)
// ─────────────────────────────────────────────────────────────────────────────
class _ThreatOrbitPainter extends CustomPainter {
  final double progress;
  final bool frontPass;

  static const _tilt = 22.0 * math.pi / 180.0; // 22° tilt
  static const _trailCount = 28;
  static const Color _headColor = Colors.redAccent;

  const _ThreatOrbitPainter({required this.progress, required this.frontPass});

  /// Returns the (x, y, z) of a point at orbit angle [theta].
  static ({double x, double y, double z}) _orbit(
    double theta,
    double cx,
    double headY,
    double R,
  ) {
    final sinT = math.sin(theta);
    final cosT = math.cos(theta);
    return (
      x: cx + R * cosT,
      y: headY - R * sinT * math.sin(_tilt),
      z: R * sinT * math.cos(_tilt),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final headY = size.height * 0.25; // forehead position
    final R = size.width * 0.22;

    // Current head angle (full circle per loop)
    final theta0 = progress * 2 * math.pi;

    // Build and draw the comet trail (newest → oldest)
    for (int i = 0; i < _trailCount; i++) {
      // Each trail point is slightly behind the head in angle
      final trailFrac = i / _trailCount;
      final trailSpan = 1.0 * math.pi; // half-orbit trail length
      final theta = theta0 - trailFrac * trailSpan;

      final p = _orbit(theta, cx, headY, R);

      // Depth filter: only draw on the correct layer
      if (frontPass && p.z <= 0) continue;
      if (!frontPass && p.z > 0) continue;

      final alpha = (1.0 - trailFrac).clamp(0.0, 1.0);
      final radius = (3.5 - trailFrac * 2.8).clamp(0.4, 3.5);

      // Scale brightness by depth for a very subtle 3-D cue
      final depthFade = ((p.z / R + 1.0) * 0.5).clamp(0.3, 1.0);

      final paint = Paint()
        ..color = _headColor.withValues(alpha: alpha * 0.92 * depthFade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.0 + trailFrac * 2.5);

      canvas.drawCircle(Offset(p.x, p.y), radius, paint);
    }

    // Draw the bright star head on the correct layer
    final head = _orbit(theta0, cx, headY, R);
    if ((frontPass && head.z > 0) || (!frontPass && head.z <= 0)) {
      // Pulsing size
      final pulse = (math.sin(progress * math.pi * 14) + 1) / 2;
      final headR = 2.2 + pulse * 1.8;
      final glowR = 5.0 + pulse * 3.0;

      // Glow
      canvas.drawCircle(
        Offset(head.x, head.y),
        glowR,
        Paint()
          ..color = _headColor.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowR),
      );
      // White hot core
      canvas.drawCircle(
        Offset(head.x, head.y),
        headR,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_ThreatOrbitPainter old) =>
      old.progress != progress || old.frontPass != frontPass;
}

// ─────────────────────────────────────────────────────────────────────────────
// _DominatingFirePainter
//
// Draws 3 staggered blazing fire heads that orbit the forehead in a tilted
// plane, leaving upward-drifting fire particle trails behind them.
//
// The orbit geometry is the same tilted-circle math as _ThreatOrbitPainter
// but with a steeper tilt (30°) and a slightly smaller radius (18 %).
// Fire particle colours cycle white → yellow → orange → deep red → transparent.
// ─────────────────────────────────────────────────────────────────────────────
class _DominatingFirePainter extends CustomPainter {
  final double progress;
  final bool frontPass;

  static const _tilt = 30.0 * math.pi / 180.0;
  static const _fireHeads = 3;
  static const _trailCount = 22;

  // Fire colour gradient: white-hot core → yellow → orange → red → gone
  static const List<Color> _fireGradient = [
    Color(0xFFFFFFFF), // white
    Color(0xFFFFEE44), // yellow
    Color(0xFFFF8800), // orange
    Color(0xFFDD2200), // deep red
    Color(0x00AA0000), // transparent
  ];

  const _DominatingFirePainter({
    required this.progress,
    required this.frontPass,
  });

  static ({double x, double y, double z}) _orbit(
    double theta,
    double cx,
    double headY,
    double R,
  ) {
    final sinT = math.sin(theta);
    final cosT = math.cos(theta);
    return (
      x: cx + R * cosT,
      y: headY - R * sinT * math.sin(_tilt),
      z: R * sinT * math.cos(_tilt),
    );
  }

  Color _fireColor(double t) {
    // t in [0, 1]: 0 = head, 1 = tail (fully faded)
    final scaled = t * (_fireGradient.length - 1);
    final idx = scaled.floor().clamp(0, _fireGradient.length - 2);
    final frac = scaled - idx;
    return Color.lerp(_fireGradient[idx], _fireGradient[idx + 1], frac)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final headY = size.height * 0.25;
    final R = size.width * 0.18;

    for (int h = 0; h < _fireHeads; h++) {
      final headOffset = h / _fireHeads; // stagger fire heads evenly
      final theta0 = (progress + headOffset) * 2 * math.pi;

      final trailAngleSpan = 0.9 * math.pi; // how long the tail is (in radians)

      for (int i = 0; i < _trailCount; i++) {
        final trailFrac = i / _trailCount;
        final theta = theta0 - trailFrac * trailAngleSpan;

        final p = _orbit(theta, cx, headY, R);

        if (frontPass && p.z <= 0) continue;
        if (!frontPass && p.z > 0) continue;

        // Upward drift: older particles rise slightly
        final yDrift = trailFrac * size.height * 0.04;
        final px = p.x;
        final py = p.y - yDrift;

        final color = _fireColor(trailFrac);
        if (color.a == 0) continue;

        final particleR = (3.8 - trailFrac * 3.2).clamp(0.3, 3.8);
        final blurSigma = (1.5 + trailFrac * 3.0).clamp(1.0, 5.0);

        // Depth cue: slightly dimmer behind the piece
        final depthFade = ((p.z / R + 1.0) * 0.5).clamp(0.35, 1.0);

        canvas.drawCircle(
          Offset(px, py),
          particleR,
          Paint()
            ..color = color.withValues(alpha: color.a / 255 * depthFade)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
        );
      }

      // Fire head glow — on the correct layer
      final head = _orbit(theta0, cx, headY, R);
      if ((frontPass && head.z > 0) || (!frontPass && head.z <= 0)) {
        final pulse = (math.sin((progress + headOffset) * math.pi * 12) + 1) / 2;
        final coreR = 2.0 + pulse * 1.5;
        final outerR = 5.5 + pulse * 3.5;

        // Outer orange glow
        canvas.drawCircle(
          Offset(head.x, head.y),
          outerR,
          Paint()
            ..color = const Color(0xFFFF6600).withValues(alpha: 0.6)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, outerR),
        );
        // Inner yellow-white core
        canvas.drawCircle(
          Offset(head.x, head.y),
          coreR,
          Paint()
            ..color = const Color(0xFFFFFFDD)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DominatingFirePainter old) =>
      old.progress != progress || old.frontPass != frontPass;
}

// ─────────────────────────────────────────────────────────────────────────────
// ArenaOrbitingStarAnimation (kept for backward compatibility with hint blinks)
// ─────────────────────────────────────────────────────────────────────────────
class ArenaOrbitingStarAnimation extends StatefulWidget {
  final Color color;
  final bool isActive;
  final bool isCircle;

  const ArenaOrbitingStarAnimation({
    super.key,
    required this.color,
    required this.isActive,
    this.isCircle = false,
  });

  @override
  State<ArenaOrbitingStarAnimation> createState() =>
      _ArenaOrbitingStarAnimationState();
}

class _ArenaOrbitingStarAnimationState
    extends State<ArenaOrbitingStarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(ArenaOrbitingStarAnimation oldWidget) {
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
          painter: _ArenaOrbitingStarPainter(
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

class _ArenaOrbitingStarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isCircle;

  _ArenaOrbitingStarPainter({
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
  bool shouldRepaint(covariant _ArenaOrbitingStarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
