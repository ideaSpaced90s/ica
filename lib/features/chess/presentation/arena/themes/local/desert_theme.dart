import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../../shared/themes/animation_group.dart';
import '../../../shared/animations/signature_move_style.dart';
import '../../../shared/animations/piece_motion_profile.dart';
import '../global/sprite_chess_theme.dart';
import '../../effects/desert_piece_painter.dart';

class DesertChessTheme extends SpriteChessTheme {
    const DesertChessTheme()
      : super(
          id: 'sprite_desert',
          name: 'Desert',
          individualPiecesFolder: null,
          lightSquare: const Color(0xFFFAF9F6), // White sand
          darkSquare: const Color(0xFFD2B48C),  // Light desert brown
          frameColor: const Color(0xFFC5A07A),  // Harmonious sandy wood frame
        );

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return SandTexturePainter(
      isLight: isLight,
      baseColor: isLight ? lightSquare : darkSquare,
    );
  }

  @override
  AnimationGroup get animationGroup => AnimationGroup.c;

  @override
  SignatureMoveStyle? get signatureMoveStyle => const SandModernSignature();

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE2B477), // Warm sky amber
            Color(0xFFC68B45), // Golden sand
            Color(0xFF8C531F), // Dark clay base
          ],
        ),
      ),
      child: CustomPaint(
        painter: DesertBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const QuicksandSelectionRing();
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return SandBurstEffect(position: position, onComplete: onComplete);
  }

  @override
  Widget? buildAmbientOverlay(BuildContext context) {
    return const SandDriftAmbient();
  }

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    chess_lib.PieceType pType;
    switch (type.toUpperCase()) {
      case 'K': pType = chess_lib.PieceType.KING; break;
      case 'Q': pType = chess_lib.PieceType.QUEEN; break;
      case 'R': pType = chess_lib.PieceType.ROOK; break;
      case 'B': pType = chess_lib.PieceType.BISHOP; break;
      case 'N': pType = chess_lib.PieceType.KNIGHT; break;
      case 'P':
      default:
        pType = chess_lib.PieceType.PAWN;
        break;
    }
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: DesertPiecePainter(
          type: pType,
          isWhite: isWhite,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }


  @override
  PieceMotionProfile getPieceMotionProfile(String pieceCode) {
    final type = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    switch (type) {
      case 'Q':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 1200),
          moveCurve: Curves.easeInOutCubic,
        );
      case 'N':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 1100),
          moveCurve: Curves.easeInOutQuad,
        );
      case 'R':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 1000),
          moveCurve: Curves.easeOutCubic,
        );
      case 'B':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 950),
          moveCurve: Curves.easeOutCubic,
        );
      case 'K':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 1100),
          moveCurve: Curves.easeInOutQuad,
        );
      case 'P':
      default:
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 800),
          moveCurve: Curves.easeOutCubic,
        );
    }
  }
}

// ────────────────────────────────────────────────────────────────────────
// 1. Desert Background Painter (Dunes)
// ────────────────────────────────────────────────────────────────────────
class DesertBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dunePaint = Paint()..style = PaintingStyle.fill;

    // Far Dune
    final pathFar = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.45,
        size.width * 0.8,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.67,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    dunePaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFC68B45).withValues(alpha: 0.6),
        const Color(0xFF8C531F).withValues(alpha: 0.8),
      ],
    ).createShader(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6));
    canvas.drawPath(pathFar, dunePaint);

    // Near Dune
    final pathNear = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.88,
        size.width * 0.65,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.68,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    dunePaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE2B477).withValues(alpha: 0.8),
        const Color(0xFF704015),
      ],
    ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    canvas.drawPath(pathNear, dunePaint);
  }

  @override
  bool shouldRepaint(covariant DesertBackgroundPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 2. Quicksand Selection Ring
// ────────────────────────────────────────────────────────────────────────
class QuicksandSelectionRing extends StatefulWidget {
  const QuicksandSelectionRing({super.key});

  @override
  State<QuicksandSelectionRing> createState() => _QuicksandSelectionRingState();
}

class _QuicksandSelectionRingState extends State<QuicksandSelectionRing>
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
        return IgnorePointer(
          child: CustomPaint(
            painter: _QuicksandSelectionRingPainter(
              animationValue: _controller.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _QuicksandSelectionRingPainter extends CustomPainter {
  final double animationValue;
  _QuicksandSelectionRingPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.45;
    
    // Golden sand color
    const sandColor = Color(0xFFD4AF37);

    // Swirling rings that shrink and spin
    final ringPaint = Paint()
      ..color = sandColor.withValues(alpha: (1.0 - animationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final t = (animationValue + i * 0.33) % 1.0;
      final radius = maxRadius * (1.0 - t * 0.8);
      final opacity = sin(t * pi);
      ringPaint.color = sandColor.withValues(alpha: opacity * 0.6);
      canvas.drawCircle(center, radius, ringPaint);
    }

    // Inward spiral arms
    final spiralPaint = Paint()
      ..color = sandColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final baseAngle = (animationValue * 2 * pi) + (i * pi / 2);
      final path = Path();
      
      for (int step = 0; step <= 10; step++) {
        final t = step / 10;
        final angle = baseAngle + t * pi * 0.5;
        final radius = maxRadius * (1.0 - t * 0.8);
        final x = center.dx + cos(angle) * radius;
        final y = center.dy + sin(angle) * radius;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, spiralPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuicksandSelectionRingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ────────────────────────────────────────────────────────────────────────
// 3. Sand Burst Capture Effect
// ────────────────────────────────────────────────────────────────────────
class SandBurstEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const SandBurstEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<SandBurstEffect> createState() => _SandBurstEffectState();
}

class _SandBurstEffectState extends State<SandBurstEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_SandParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final random = Random();
    _particles = [];

    Color pickColor() {
      final val = random.nextDouble();
      if (val < 0.45) {
        return const Color(0xFFFAF9F6); // White sand
      } else if (val < 0.8) {
        return const Color(0xFFB46A42); // Terracotta clay
      } else {
        return const Color(0xFFD4AF37); // Sand gold
      }
    }

    // 1. Generate Head Particles (Sphere)
    for (int i = 0; i < 20; i++) {
      final r = random.nextDouble() * 10.0;
      final angle = random.nextDouble() * 2 * pi;
      _particles.add(_SandParticle(
        startX: cos(angle) * r,
        startY: -16.0 + sin(angle) * r,
        vx: (random.nextDouble() - 0.5) * 15.0,
        vy: 8.0 + random.nextDouble() * 18.0,
        size: 1.2 + random.nextDouble() * 1.8,
        color: pickColor(),
      ));
    }

    // 2. Generate Body Particles (Collar and trunk)
    for (int i = 0; i < 35; i++) {
      final double hFactor = random.nextDouble();
      final double y = -8.0 + hFactor * 16.0;
      final double maxW = 12.0 - hFactor * 4.0;
      final double x = (random.nextDouble() - 0.5) * 2 * maxW;
      _particles.add(_SandParticle(
        startX: x,
        startY: y,
        vx: (random.nextDouble() - 0.5) * 15.0,
        vy: 12.0 + random.nextDouble() * 22.0,
        size: 1.2 + random.nextDouble() * 1.8,
        color: pickColor(),
      ));
    }

    // 3. Generate Base Particles (Oval foot)
    for (int i = 0; i < 20; i++) {
      final rX = random.nextDouble() * 15.0;
      final rY = random.nextDouble() * 4.0;
      final angle = random.nextDouble() * 2 * pi;
      _particles.add(_SandParticle(
        startX: cos(angle) * rX,
        startY: 10.0 + sin(angle) * rY,
        vx: (random.nextDouble() - 0.5) * 15.0,
        vy: 16.0 + random.nextDouble() * 24.0,
        size: 1.2 + random.nextDouble() * 1.8,
        color: pickColor(),
      ));
    }

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
          painter: _SandBurstPainter(
            center: widget.position,
            progress: _controller.value,
            particles: _particles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SandParticle {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double size;
  final Color color;

  _SandParticle({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

class _SandBurstPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final List<_SandParticle> particles;

  _SandBurstPainter({
    required this.center,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;

    for (final p in particles) {
      // Collapse downward with gravity acceleration and minor horizontal sway
      final dx = p.startX + p.vx * t;
      final dy = p.startY + p.vy * t + 35.0 * t * t;
      final pos = center + Offset(dx, dy);

      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Particle sizes decay slightly as they crumble
      canvas.drawCircle(pos, p.size * (1.0 - t * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SandBurstPainter oldDelegate) => true;
}

// ────────────────────────────────────────────────────────────────────────
// 4. Sand Drift Ambient Overlay
// ────────────────────────────────────────────────────────────────────────
class SandDriftAmbient extends StatefulWidget {
  const SandDriftAmbient({super.key});

  @override
  State<SandDriftAmbient> createState() => _SandDriftAmbientState();
}

class _SandDriftAmbientState extends State<SandDriftAmbient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_DriftGrain> _grains = [];
  final Random _random = Random();
  Size _lastSize = Size.zero;
  _Tumbleweed? _tumbleweed;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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

    // Initialize grains if empty
    if (_grains.isEmpty) {
      for (int i = 0; i < 30; i++) {
        _grains.add(_createRandomGrain(initial: true));
      }
    }

    // Move grains
    setState(() {
      for (int i = 0; i < _grains.length; i++) {
        final grain = _grains[i];
        final newX = grain.x - grain.speedX;
        final newY = grain.y + grain.speedY;

        // Reset if off-screen
        if (newX < -10 || newY > _lastSize.height + 10) {
          _grains[i] = _createRandomGrain(initial: false);
        } else {
          _grains[i] = grain.copyWith(x: newX, y: newY);
        }
      }

      // Move tumbleweed if active
      if (_tumbleweed != null) {
        final t = _tumbleweed!;
        t.x -= t.speedX;
        t.rotation += t.speedX / t.radius;
        // Bouncing motion using absolute sine wave
        final bounce = sin(t.x / 18.0).abs() * 20.0;
        t.y = t.startY - bounce;

        if (t.x < -t.radius * 2) {
          _tumbleweed = null;
        }
      } else {
        // Spawn tumbleweed occasionally
        if (_random.nextDouble() > 0.996) {
          final radius = 16.0 + _random.nextDouble() * 10.0;
          final startY = _lastSize.height * 0.35 + _random.nextDouble() * _lastSize.height * 0.4;
          _tumbleweed = _Tumbleweed(
            x: _lastSize.width + radius * 2,
            y: startY,
            radius: radius,
            rotation: 0.0,
            speedX: 1.5 + _random.nextDouble() * 2.0,
            startY: startY,
          );
        }
      }
    });
  }

  _DriftGrain _createRandomGrain({required bool initial}) {
    final x = initial
        ? _random.nextDouble() * _lastSize.width
        : _lastSize.width + 10.0;
    final y = initial
        ? _random.nextDouble() * _lastSize.height
        : _random.nextDouble() * _lastSize.height * 0.7;

    return _DriftGrain(
      x: x,
      y: y,
      speedX: 0.5 + _random.nextDouble() * 1.5,
      speedY: 0.2 + _random.nextDouble() * 0.8,
      size: 1.0 + _random.nextDouble() * 2.0,
      opacity: 0.15 + _random.nextDouble() * 0.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
          return CustomPaint(
            painter: _SandDriftPainter(
              grains: _grains,
              tumbleweed: _tumbleweed,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Tumbleweed {
  double x;
  double y;
  double radius;
  double rotation;
  final double speedX;
  final double startY;

  _Tumbleweed({
    required this.x,
    required this.y,
    required this.radius,
    required this.rotation,
    required this.speedX,
    required this.startY,
  });
}

class _DriftGrain {
  final double x;
  final double y;
  final double speedX;
  final double speedY;
  final double size;
  final double opacity;

  _DriftGrain({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
  });

  _DriftGrain copyWith({double? x, double? y}) {
    return _DriftGrain(
      x: x ?? this.x,
      y: y ?? this.y,
      speedX: speedX,
      speedY: speedY,
      size: size,
      opacity: opacity,
    );
  }
}

class _SandDriftPainter extends CustomPainter {
  final List<_DriftGrain> grains;
  final _Tumbleweed? tumbleweed;
  _SandDriftPainter({required this.grains, this.tumbleweed});

  @override
  void paint(Canvas canvas, Size size) {
    const grainColor = Color(0xFFD4AF37);

    // 1. Draw sand grains
    for (final grain in grains) {
      final paint = Paint()
        ..color = grainColor.withValues(alpha: grain.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(grain.x, grain.y), grain.size, paint);
    }

    // 2. Draw rolling tumbleweed
    if (tumbleweed != null) {
      final t = tumbleweed!;
      canvas.save();
      canvas.translate(t.x, t.y);
      canvas.rotate(t.rotation);

      final branchPaint = Paint()
        ..color = const Color(0xFF805A36).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final double r = t.radius;
      
      // Main boundary
      canvas.drawCircle(Offset.zero, r, branchPaint);

      // Tangled branch loops
      final random = Random(42);
      for (int i = 0; i < 6; i++) {
        final double rx = r * (0.65 + random.nextDouble() * 0.35);
        final double ry = r * (0.45 + random.nextDouble() * 0.35);
        final double angle = random.nextDouble() * 2 * pi;

        canvas.save();
        canvas.rotate(angle);
        canvas.drawOval(Rect.fromLTRB(-rx, -ry, rx, ry), branchPaint);
        canvas.restore();
      }

      // Straight jagged lines
      for (int i = 0; i < 4; i++) {
        final double x1 = (random.nextDouble() - 0.5) * 1.8 * r;
        final double y1 = (random.nextDouble() - 0.5) * 1.8 * r;
        final double x2 = (random.nextDouble() - 0.5) * 1.8 * r;
        final double y2 = (random.nextDouble() - 0.5) * 1.8 * r;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), branchPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SandDriftPainter oldDelegate) => true;
}

// ────────────────────────────────────────────────────────────────────────
// 5. Sand Texture Painter (Grainy Tiles)
// ────────────────────────────────────────────────────────────────────────
class SandTexturePainter extends CustomPainter {
  final bool isLight;
  final Color baseColor;

  SandTexturePainter({required this.isLight, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..color = baseColor;
    canvas.drawRect(rect, paint);

    // Static seeded Random to prevent grain flickering
    final rand = Random(isLight ? 2222 : 4444);
    
    for (int i = 0; i < 40; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      final radius = 0.6 + rand.nextDouble() * 1.2;

      final isDarker = rand.nextBool();
      final Color grainColor;
      if (isDarker) {
        grainColor = Colors.black.withValues(alpha: 0.05 + rand.nextDouble() * 0.04);
      } else {
        grainColor = Colors.white.withValues(alpha: 0.07 + rand.nextDouble() * 0.07);
      }

      final grainPaint = Paint()
        ..color = grainColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), radius, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SandTexturePainter oldDelegate) {
    return oldDelegate.isLight != isLight || oldDelegate.baseColor != baseColor;
  }
}
