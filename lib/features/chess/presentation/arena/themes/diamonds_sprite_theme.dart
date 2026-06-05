import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/themes/animation_group.dart';
import '../../shared/animations/signature_move_style.dart';
import 'sprite_chess_theme.dart';

class DiamondsSpriteTheme extends SpriteChessTheme {
  const DiamondsSpriteTheme()
      : super(
          id: 'sprite_diamonds',
          name: 'Diamonds',
          individualPiecesFolder: 'assets/pieces/diamonds-webP',
          pieceExtension: 'webp',
          lightSquare: const Color(0xFFE0F7FA),
          darkSquare: const Color(0xFF006064),
          frameColor: const Color(0xFF80DEEA),
        );

  @override
  AnimationGroup get animationGroup => AnimationGroup.c;

  @override
  SignatureMoveStyle? get signatureMoveStyle => const CrystalTrail();

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const RefractionSelectionRing();
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return ShardBurstCapture(position: position, onComplete: onComplete);
  }

  @override
  Widget? buildAmbientOverlay(BuildContext context) {
    return const CrystalShimmerAmbient();
  }
}

// ────────────────────────────────────────────────────────────────────────
// 1. Crystal Shimmer Ambient Overlay
// ────────────────────────────────────────────────────────────────────────
class CrystalShimmerAmbient extends StatefulWidget {
  const CrystalShimmerAmbient({super.key});

  @override
  State<CrystalShimmerAmbient> createState() => _CrystalShimmerAmbientState();
}

class _CrystalShimmerAmbientState extends State<CrystalShimmerAmbient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_ShimmerGlint> _glints = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      if (_glints.length < 5) {
        final squareIndex = _random.nextInt(64);
        final row = squareIndex ~/ 8;
        final col = squareIndex % 8;
        final startTime = DateTime.now();
        setState(() {
          _glints.add(_ShimmerGlint(
            row: row,
            col: col,
            startTime: startTime,
            duration: const Duration(milliseconds: 300),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    _glints.removeWhere((g) => now.difference(g.startTime) > g.duration);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CrystalShimmerPainter(glints: List.from(_glints)),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ShimmerGlint {
  final int row;
  final int col;
  final DateTime startTime;
  final Duration duration;

  _ShimmerGlint({
    required this.row,
    required this.col,
    required this.startTime,
    required this.duration,
  });

  double getProgress() {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    return (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}

class _CrystalShimmerPainter extends CustomPainter {
  final List<_ShimmerGlint> glints;

  _CrystalShimmerPainter({required this.glints});

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    for (final glint in glints) {
      final progress = glint.getProgress();
      final double opacity = progress < 0.5 ? progress / 0.5 : (1.0 - progress) / 0.5;
      final x = glint.col * squareSize + squareSize / 2;
      final y = glint.row * squareSize + squareSize / 2;
      
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;
      
      final path = Path();
      final flareSize = squareSize * 0.4 * progress;
      path.moveTo(x, y - flareSize);
      path.lineTo(x + flareSize * 0.2, y - flareSize * 0.2);
      path.lineTo(x + flareSize, y);
      path.lineTo(x + flareSize * 0.2, y + flareSize * 0.2);
      path.lineTo(x, y + flareSize);
      path.lineTo(x - flareSize * 0.2, y + flareSize * 0.2);
      path.lineTo(x - flareSize, y);
      path.lineTo(x - flareSize * 0.2, y - flareSize * 0.2);
      path.close();
      
      canvas.drawPath(path, paint);
      
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.cyan.withValues(alpha: opacity * 0.25),
            Colors.cyan.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: flareSize));
      canvas.drawCircle(Offset(x, y), flareSize, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrystalShimmerPainter oldDelegate) {
    return true;
  }
}

// ────────────────────────────────────────────────────────────────────────
// 2. Crystal Shard Burst Capture Effect
// ────────────────────────────────────────────────────────────────────────
class ShardBurstCapture extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  const ShardBurstCapture({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ShardBurstCapture> createState() => _ShardBurstCaptureState();
}

class _ShardBurstCaptureState extends State<ShardBurstCapture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ShardParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final random = Random();
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + random.nextDouble() * (pi / 8) - (pi / 16);
      final speed = 80.0 + random.nextDouble() * 70.0;
      final size = 6.0 + random.nextDouble() * 6.0;
      final rotationSpeed = (random.nextDouble() * 4 - 2) * pi;
      _particles.add(_ShardParticle(
        angle: angle,
        speed: speed,
        size: size,
        rotationSpeed: rotationSpeed,
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
          painter: _ShardBurstPainter(
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

class _ShardParticle {
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;

  _ShardParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
  });
}

class _ShardBurstPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final List<_ShardParticle> particles;

  _ShardBurstPainter({
    required this.center,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 1.0 - progress;
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.fill;
    
    final whitePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.9)
      ..style = PaintingStyle.fill;

    for (final p in particles) {
      final distance = p.speed * progress;
      final px = center.dx + cos(p.angle) * distance;
      final py = center.dy + sin(p.angle) * distance;
      
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotationSpeed * progress);
      
      final path = Path();
      path.moveTo(0, -p.size);
      path.lineTo(p.size * 0.6, 0);
      path.lineTo(0, p.size);
      path.lineTo(-p.size * 0.6, 0);
      path.close();
      
      canvas.drawPath(path, paint);
      
      final corePath = Path();
      corePath.moveTo(0, -p.size * 0.4);
      corePath.lineTo(p.size * 0.24, 0);
      corePath.lineTo(0, p.size * 0.4);
      corePath.lineTo(-p.size * 0.24, 0);
      corePath.close();
      canvas.drawPath(corePath, whitePaint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ShardBurstPainter oldDelegate) {
    return true;
  }
}

// ────────────────────────────────────────────────────────────────────────
// 3. Refraction Selection Ring
// ────────────────────────────────────────────────────────────────────────
class RefractionSelectionRing extends StatefulWidget {
  const RefractionSelectionRing({super.key});

  @override
  State<RefractionSelectionRing> createState() => _RefractionSelectionRingState();
}

class _RefractionSelectionRingState extends State<RefractionSelectionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
            painter: _RefractionSelectionPainter(progress: _controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _RefractionSelectionPainter extends CustomPainter {
  final double progress;

  _RefractionSelectionPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = 3.0;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: const [
          Colors.cyan,
          Colors.blue,
          Colors.purple,
          Colors.pink,
          Colors.cyan,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(progress * 2 * pi),
      ).createShader(rect);

    canvas.drawRect(rect.deflate(strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _RefractionSelectionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
