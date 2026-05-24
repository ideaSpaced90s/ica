import 'dart:math';
import 'package:flutter/material.dart';

class StaticDischargeOverlay extends StatefulWidget {
  const StaticDischargeOverlay({super.key});

  @override
  State<StaticDischargeOverlay> createState() => _StaticDischargeOverlayState();
}

class _StaticDischargeOverlayState extends State<StaticDischargeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ArcData> _arcs = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_random.nextDouble() > 0.96) {
            _triggerArc();
          }
          return CustomPaint(
            painter: _StaticArcPainter(arcs: _arcs),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  void _triggerArc() {
    final start = Offset(
      _random.nextDouble() * 400,
      _random.nextDouble() * 400,
    );
    final end =
        start +
        Offset(
          (_random.nextDouble() - 0.5) * 100,
          (_random.nextDouble() - 0.5) * 100,
        );
    final arc = _ArcData(start: start, end: end, startTime: DateTime.now());
    setState(() => _arcs.add(arc));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _arcs.remove(arc));
    });
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

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
      duration: const Duration(milliseconds: 400),
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 50,
      top: widget.position.dy - 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ElectricBurstPainter(progress: _controller.value),
            size: const Size(100, 100),
          );
        },
      ),
    );
  }
}

class _ElectricBurstPainter extends CustomPainter {
  final double progress;
  _ElectricBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = const Color(0xFF00BFFF).withValues(alpha: (1.0 - progress))
      ..strokeWidth = 2.0 * (1.0 - progress)
      ..style = PaintingStyle.stroke;

    // Expanding lightning fractal burst
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

    // Central flash
    final flashPaint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10 * (1.0 - progress), flashPaint);
  }

  @override
  bool shouldRepaint(_ElectricBurstPainter oldDelegate) => true;
}
