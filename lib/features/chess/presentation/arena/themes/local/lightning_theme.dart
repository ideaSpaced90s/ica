import 'dart:math';
import 'package:flutter/material.dart';
import '../../../shared/themes/animation_group.dart';
import '../../../shared/animations/signature_move_style.dart';
import '../../../shared/animations/piece_motion_profile.dart';
import '../global/sprite_chess_theme.dart';

class LightningChessTheme extends SpriteChessTheme {
  const LightningChessTheme()
      : super(
          id: 'sprite_lightning',
          name: 'Lightning',
          individualPiecesFolder: 'assets/pieces/lightening-webP',
          pieceExtension: 'webp',
          lightSquare: const Color(0xDCFAEBD7),
          darkSquare: const Color(0xDC0A1128),
          frameColor: const Color(0xFF00E5FF),
        );

  @override
  AnimationGroup get animationGroup => AnimationGroup.c;

  @override
  SignatureMoveStyle? get signatureMoveStyle => const LightningModernSignature();

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      color: const Color(0xFF020617),
      child: CustomPaint(
        painter: LightningBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const EnergySelectionRing();
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return ElectricBurstEffect(position: position, onComplete: onComplete);
  }

  @override
  Widget? buildAmbientOverlay(BuildContext context) {
    return const StaticDischargeAmbient();
  }

  @override
  PieceMotionProfile getPieceMotionProfile(String pieceCode) {
    final type = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    switch (type) {
      case 'Q':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 420),
          moveCurve: Curves.easeInOutCubic,
        );
      case 'N':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 420),
          moveCurve: Curves.easeInOutQuad,
        );
      case 'R':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 360),
          moveCurve: Curves.easeOutCubic,
        );
      case 'B':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 380),
          moveCurve: Curves.easeOutCubic,
        );
      case 'K':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 400),
          moveCurve: Curves.easeInOutQuad,
        );
      case 'P':
      default:
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 280),
          moveCurve: Curves.easeOutCubic,
        );
    }
  }
}

class LightningBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(1337);

    // Draw stormy cloud layers
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = size.width * 0.4 + random.nextDouble() * size.width * 0.2;
      
      final cloudPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.15),
            const Color(0xFF020617).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
        
      canvas.drawCircle(Offset(x, y), radius, cloudPaint);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final side = random.nextInt(4);
      double startX = 0, startY = 0;
      double endX = 0, endY = 0;

      if (side == 0) {
        startX = random.nextDouble() * size.width;
        startY = 0;
        endX = startX + (-50 + random.nextDouble() * 100);
        endY = size.height * 0.25;
      } else if (side == 1) {
        startX = size.width;
        startY = random.nextDouble() * size.height;
        endX = size.width - (size.width * 0.25);
        endY = startY + (-50 + random.nextDouble() * 100);
      } else if (side == 2) {
        startX = random.nextDouble() * size.width;
        startY = size.height;
        endX = startX + (-50 + random.nextDouble() * 100);
        endY = size.height - (size.height * 0.25);
      } else {
        startX = 0;
        startY = random.nextDouble() * size.height;
        endX = size.width * 0.25;
        endY = startY + (-50 + random.nextDouble() * 100);
      }

      _drawFractalLightning(canvas, paint, startX, startY, endX, endY, random);
    }
  }

  void _drawFractalLightning(Canvas canvas, Paint paint, double x1, double y1, double x2, double y2, Random random) {
    final path = Path()..moveTo(x1, y1);
    final segments = 6;
    
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final targetX = x1 + (x2 - x1) * t;
      final targetY = y1 + (y2 - y1) * t;
      final jitterX = (-12.0 + random.nextDouble() * 24.0) * (1.0 - t * 0.5);
      final jitterY = (-12.0 + random.nextDouble() * 24.0) * (1.0 - t * 0.5);
      path.lineTo(targetX + jitterX, targetY + jitterY);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LightningBackgroundPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 1. Static Discharge Ambient Overlay
// ────────────────────────────────────────────────────────────────────────
class StaticDischargeAmbient extends StatefulWidget {
  const StaticDischargeAmbient({super.key});

  @override
  State<StaticDischargeAmbient> createState() => _StaticDischargeAmbientState();
}

class _StaticDischargeAmbientState extends State<StaticDischargeAmbient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ArcData> _arcs = [];
  final Random _random = Random();
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(_onAnimationTick)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!mounted || _lastSize == Size.zero) return;

    bool changed = false;
    if (_random.nextDouble() > 0.97) {
      final start = Offset(
        _random.nextDouble() * _lastSize.width,
        _random.nextDouble() * _lastSize.height,
      );
      final end = start + Offset(
        (_random.nextDouble() - 0.5) * _lastSize.width * 0.25,
        (_random.nextDouble() - 0.5) * _lastSize.height * 0.25,
      );
      _arcs.add(_ArcData(start: start, end: end, startTime: DateTime.now()));
      changed = true;
    }

    final now = DateTime.now();
    final initialLength = _arcs.length;
    _arcs.removeWhere((arc) => now.difference(arc.startTime).inMilliseconds > 150);
    if (_arcs.length != initialLength) {
      changed = true;
    }

    if (_arcs.isNotEmpty) {
      changed = true;
    }

    if (changed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
          return CustomPaint(
            painter: _StaticArcPainter(arcs: List.from(_arcs)),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ArcData {
  final Offset start;
  final Offset end;
  final DateTime startTime;

  _ArcData({required this.start, required this.end, required this.startTime});
}

class _StaticArcPainter extends CustomPainter {
  final List<_ArcData> arcs;
  _StaticArcPainter({required this.arcs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0FFFF).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    final random = Random();
    for (final arc in arcs) {
      final path = Path()..moveTo(arc.start.dx, arc.start.dy);
      final segments = 5;

      for (int i = 1; i <= segments; i++) {
        final t = i / segments;
        final lerped = Offset.lerp(arc.start, arc.end, t)!;
        final jitter = Offset(
          (random.nextDouble() - 0.5) * 15,
          (random.nextDouble() - 0.5) * 15,
        );
        path.lineTo(lerped.dx + jitter.dx, lerped.dy + jitter.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticArcPainter oldDelegate) => true;
}

// ────────────────────────────────────────────────────────────────────────
// 2. Electric Capture Burst Effect
// ────────────────────────────────────────────────────────────────────────
class ElectricBurstEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const ElectricBurstEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ElectricBurstEffect> createState() => _ElectricBurstEffectState();
}

class _ElectricBurstEffectState extends State<ElectricBurstEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ElectricBurstPainter(
            center: widget.position,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ElectricBurstPainter extends CustomPainter {
  final Offset center;
  final double progress;

  _ElectricBurstPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    final paint = Paint()
      ..color = const Color(0xFF00BFFF).withValues(alpha: 1.0 - progress)
      ..strokeWidth = 2.0 * (1.0 - progress)
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (random.nextDouble() * 0.2);
      final length = 20.0 + random.nextDouble() * 30.0 * (1.0 + progress);

      final path = Path()..moveTo(center.dx, center.dy);
      final segments = 4;
      for (int j = 1; j <= segments; j++) {
        final t = j / segments;
        final r = length * t;
        final next = Offset(
          center.dx + cos(angle) * r,
          center.dy + sin(angle) * r,
        );
        final jitter = Offset(
          (random.nextDouble() - 0.5) * 10,
          (random.nextDouble() - 0.5) * 10,
        );
        path.lineTo(next.dx + jitter.dx, next.dy + jitter.dy);
      }
      canvas.drawPath(path, paint);
    }

    final flashPaint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10 * (1.0 - progress), flashPaint);
  }

  @override
  bool shouldRepaint(covariant _ElectricBurstPainter oldDelegate) => true;
}

// ────────────────────────────────────────────────────────────────────────
// 3. Energy Selection Ring
// ────────────────────────────────────────────────────────────────────────
class EnergySelectionRing extends StatefulWidget {
  const EnergySelectionRing({super.key});

  @override
  State<EnergySelectionRing> createState() => _EnergySelectionRingState();
}

class _EnergySelectionRingState extends State<EnergySelectionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
        return IgnorePointer(
          child: CustomPaint(
            painter: EnergySurgePainter(
              animationValue: _controller.value,
              color: const Color(0xFF00E5FF),
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class EnergySurgePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  EnergySurgePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42);

    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - animationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final radius = (size.width * 0.3) +
          (size.width * 0.6 * ((animationValue + i * 0.2) % 1.0));
      final jitter = (random.nextDouble() - 0.5) * 5.0;
      canvas.drawCircle(center, radius + jitter, paint);
    }

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final angle = (animationValue * 2 * pi) + (i * pi / 2);
      final r1 = size.width * 0.3;
      final r2 = size.width * 0.45;

      canvas.drawLine(
        Offset(center.dx + cos(angle) * r1, center.dy + sin(angle) * r1),
        Offset(
          center.dx + cos(angle + 0.2) * r2,
          center.dy + sin(angle + 0.2) * r2,
        ),
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(EnergySurgePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
