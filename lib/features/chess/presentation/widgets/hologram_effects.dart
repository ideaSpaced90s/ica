import 'dart:math';
import 'package:flutter/material.dart';

class HoloScanlineOverlay extends StatefulWidget {
  const HoloScanlineOverlay({super.key});

  @override
  State<HoloScanlineOverlay> createState() => _HoloScanlineOverlayState();
}

class _HoloScanlineOverlayState extends State<HoloScanlineOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        final isGlitching = _random.nextDouble() > 0.98;
        return Stack(
          children: [
            // Floating scanline pulse
            Positioned.fill(
              child: CustomPaint(
                painter: ScanlinePainter(
                  pos: _scanController.value,
                  isGlitching: isGlitching,
                ),
              ),
            ),
            // Subtle noise grain
            if (_random.nextDouble() > 0.3)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.02,
                  child: Image.network(
                    'https://media.giphy.com/media/oEI9uWUicT3hu/giphy.gif',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ScanlinePainter extends CustomPainter {
  final double pos;
  final bool isGlitching;

  ScanlinePainter({required this.pos, required this.isGlitching});

  @override
  void paint(Canvas canvas, Size size) {
    final cyanGlow = const Color(0xFF22D3EE);
    
    // Main horizontal scanline
    final double y = size.height * pos;
    final Paint linePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          cyanGlow.withValues(alpha: 0.2),
          cyanGlow.withValues(alpha: 0.4),
          cyanGlow.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));
    
    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), linePaint);
    
    // Flickering static if glitching
    if (isGlitching) {
      final Random random = Random();
      final Paint glitchPaint = Paint()
        ..color = cyanGlow.withValues(alpha: 0.3)
        ..strokeWidth = 1.0;
        
      for (int i = 0; i < 5; i++) {
          final double gy = random.nextDouble() * size.height;
          canvas.drawLine(Offset(0, gy), Offset(size.width, gy), glitchPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ScanlinePainter oldDelegate) => true;
}

class HoloPixelDissolveEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const HoloPixelDissolveEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<HoloPixelDissolveEffect> createState() => _HoloPixelDissolveEffectState();
}

class _HoloPixelDissolveEffectState extends State<HoloPixelDissolveEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    
    final random = Random();
    for (int i = 0; i < 30; i++) {
        _particles.add(Particle(
          offset: widget.position,
          vx: (random.nextDouble() - 0.5) * 4.0,
          vy: (random.nextDouble() - 1.5) * 3.0,
          size: 2.0 + random.nextDouble() * 3.0,
          color: random.nextBool() ? const Color(0xFF22D3EE) : const Color(0xFFA78BFA),
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
      builder: (context, _) {
        return CustomPaint(
          painter: DissolvePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  final Color color;
  Offset offset;
  final double vx, vy;
  final double size;

  Particle({required this.color, required this.offset, required this.vx, required this.vy, required this.size});
}

class DissolvePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  DissolvePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
        
      final currentPos = Offset(
        p.offset.dx + p.vx * progress * 50,
        p.offset.dy + p.vy * progress * 50,
      );
      
      canvas.drawRect(Rect.fromLTWH(currentPos.dx, currentPos.dy, p.size, p.size), paint);
    }
  }

  @override
  bool shouldRepaint(DissolvePainter oldDelegate) => true;
}
