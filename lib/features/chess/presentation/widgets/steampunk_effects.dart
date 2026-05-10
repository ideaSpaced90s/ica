import 'dart:math' as math;
import 'package:flutter/material.dart';

class SteamParticleOverlay extends StatefulWidget {
  const SteamParticleOverlay({super.key});

  @override
  State<SteamParticleOverlay> createState() => _SteamParticleOverlayState();
}

class _SteamParticleOverlayState extends State<SteamParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SteamCloud> _clouds = List.generate(12, (_) => _SteamCloud());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
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
          painter: _SteamPainter(_clouds, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SteamCloud {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 30 + 20;
  double speed = math.Random().nextDouble() * 0.1 + 0.05;
  double drift = math.Random().nextDouble() * 0.2 - 0.1;
  double opacity = math.Random().nextDouble() * 0.2 + 0.1;
}

class _SteamPainter extends CustomPainter {
  final List<_SteamCloud> clouds;
  final double animationValue;

  _SteamPainter(this.clouds, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var c in clouds) {
      final dx = size.width * ((c.x + animationValue * c.drift) % 1.0);
      final dy = size.height * ((c.y - animationValue * c.speed) % 1.0);
      
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: c.opacity * (1.0 - (dy / size.height)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
      
      canvas.drawCircle(Offset(dx, dy), c.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter oldDelegate) => true;
}

class MetalShatterEffect extends StatefulWidget {
    final Offset position;
    final bool isWhite;
    final VoidCallback onComplete;

    const MetalShatterEffect({
        super.key,
        required this.position,
        required this.isWhite,
        required this.onComplete,
    });

    @override
    State<MetalShatterEffect> createState() => _MetalShatterEffectState();
}

class _MetalShatterEffectState extends State<MetalShatterEffect>
    with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late final List<_MetalShard> _shards;

    @override
    void initState() {
        super.initState();
        _shards = List.generate(12, (_) => _MetalShard());
        _controller = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 1000))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) widget.onComplete();
          });
        _controller.forward();
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
                    painter: _MetalShatterPainter(_shards, _controller.value, widget.position, widget.isWhite),
                    size: Size.infinite,
                );
            },
        );
    }
}

class _MetalShard {
    double angle = math.Random().nextDouble() * 2 * math.pi;
    double dist = math.Random().nextDouble() * 120 + 40;
    double size = math.Random().nextDouble() * 8 + 4;
}

class _MetalShatterPainter extends CustomPainter {
    final List<_MetalShard> shards;
    final double progress;
    final Offset center;
    final bool isWhite;

    _MetalShatterPainter(this.shards, this.progress, this.center, this.isWhite);

    @override
    void paint(Canvas canvas, Size size) {
        if (progress >= 1.0) return;
        
        final paint = Paint()
          ..color = (isWhite ? const Color(0xFFDAA520) : const Color(0xFF424242)).withValues(alpha: 1.0 - progress)
          ..style = PaintingStyle.fill;
        
        for (var shard in shards) {
            final t = Curves.easeOutCubic.transform(progress);
            final dx = center.dx + math.cos(shard.angle) * shard.dist * t;
            final dy = center.dy + math.sin(shard.angle) * shard.dist * t;
            
            canvas.drawRect(Rect.fromCenter(center: Offset(dx, dy), width: shard.size, height: shard.size), paint);
        }
    }

    @override
    bool shouldRepaint(covariant _MetalShatterPainter oldDelegate) => true;
}

class GearMoveIndicator extends StatefulWidget {
  const GearMoveIndicator({super.key});

  @override
  State<GearMoveIndicator> createState() => _GearMoveIndicatorState();
}

class _GearMoveIndicatorState extends State<GearMoveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
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
        return Center(
          child: Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: CustomPaint(
              size: const Size(20, 20),
              painter: _GearIndicatorPainter(),
            ),
          ),
        );
      },
    );
  }
}

class _GearIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    final Path gear = Path();
    final r = size.width / 2;
    const teeth = 8;
    for (int i = 0; i < teeth * 2; i++) {
        final rad = (i % 2 == 0) ? r : r * 1.25;
        final angle = (i / (teeth * 2)) * 2 * math.pi;
        if (i == 0) {
          gear.moveTo(math.cos(angle) * rad, math.sin(angle) * rad);
        } else {
          gear.lineTo(math.cos(angle) * rad, math.sin(angle) * rad);
        }
    }
    gear.close();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.drawPath(gear, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GearIndicatorPainter oldDelegate) => false;
}

class SteamPuffAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  const SteamPuffAnimation({super.key, required this.onComplete});

  @override
  State<SteamPuffAnimation> createState() => _SteamPuffAnimationState();
}

class _SteamPuffAnimationState extends State<SteamPuffAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });
    _controller.forward();
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
        final progress = _controller.value;
        return CustomPaint(
          painter: _SteamPuffPainter(progress),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SteamPuffPainter extends CustomPainter {
  final double progress;
  _SteamPuffPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - progress) * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    
    canvas.drawCircle(center - Offset(0, progress * 40), 10 + progress * 20, paint);
    canvas.drawCircle(center - Offset(15, progress * 30), 8 + progress * 15, paint);
    canvas.drawCircle(center - Offset(-15, progress * 30), 8 + progress * 15, paint);
  }

  @override
  bool shouldRepaint(covariant _SteamPuffPainter oldDelegate) => true;
}

class GearSquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final r = size.width * 0.4;
    final center = size.center(Offset.zero);
    
    canvas.drawCircle(center, r, paint);
    // Draw 4 gears around corners
    for (int i = 0; i < 4; i++) {
        final angle = (i / 4) * 2 * math.pi;
        canvas.drawCircle(center + Offset(math.cos(angle) * r, math.sin(angle) * r), r * 0.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GearSquarePainter oldDelegate) => false;
}
