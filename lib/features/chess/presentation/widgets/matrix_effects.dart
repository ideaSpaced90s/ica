import 'dart:math';
import 'package:flutter/material.dart';

class MatrixFallingCodeOverlay extends StatefulWidget {
  const MatrixFallingCodeOverlay({super.key});

  @override
  State<MatrixFallingCodeOverlay> createState() => _MatrixFallingCodeOverlayState();
}

class _MatrixFallingCodeOverlayState extends State<MatrixFallingCodeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_CodeColumn> _columns = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    // Initialize random columns
    for (int i = 0; i < 20; i++) {
      _columns.add(_CodeColumn(
        speed: 1.0 + _random.nextDouble() * 2.0,
        x: _random.nextDouble(),
        chars: List.generate(
            15, (_) => String.fromCharCode(0x30A0 + _random.nextInt(96))),
        delay: _random.nextDouble(),
      ));
    }
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
          return CustomPaint(
            painter: _MatrixCodePainter(
                columns: _columns, animationValue: _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _CodeColumn {
  final double speed;
  final double x;
  final double delay;
  final List<String> chars;

  _CodeColumn(
      {required this.speed,
      required this.x,
      required this.chars,
      required this.delay});
}

class _MatrixCodePainter extends CustomPainter {
  final List<_CodeColumn> columns;
  final double animationValue;

  _MatrixCodePainter({required this.columns, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final col in columns) {
      final x = col.x * size.width;
      final totalOffset = (animationValue + col.delay) * col.speed * size.height;
      
      for (int i = 0; i < col.chars.length; i++) {
        final y = (totalOffset + i * 20) % (size.height + 300) - 150;
        if (y < -20 || y > size.height) continue;

        // Fade tail
        final opacity = (1.0 - (i / col.chars.length)).clamp(0.0, 1.0) * 0.15;
        final color = i == 0 ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: opacity);

        textPainter.text = TextSpan(
          text: col.chars[i],
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
            shadows: i == 0 ? [const Shadow(color: Colors.white, blurRadius: 4)] : [],
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ScanlineOverlay extends StatefulWidget {
  const ScanlineOverlay({super.key});

  @override
  State<ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<ScanlineOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
          return CustomPaint(
            painter: _ScanlinePainter(progress: _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class MatrixGlitchCapture extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const MatrixGlitchCapture({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<MatrixGlitchCapture> createState() => _MatrixGlitchCaptureState();
}

class _MatrixGlitchCaptureState extends State<MatrixGlitchCapture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 40,
      top: widget.position.dy - 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GlitchPainter(progress: _controller.value),
            size: const Size(80, 80),
          );
        },
      ),
    );
  }
}

class _GlitchPainter extends CustomPainter {
  final double progress;
  _GlitchPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - progress))
      ..style = PaintingStyle.fill;

    // Break up into small green digital blocks
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final blockWidth = 2.0 + random.nextDouble() * 10.0;
      final blockHeight = 1.0 + random.nextDouble() * 4.0;
      
      // Blow out from center
      final dx = (x - size.width/2) * progress * 2;
      final dy = (y - size.height/2) * progress * 2;

      canvas.drawRect(
        Rect.fromLTWH(x + dx, y + dy, blockWidth, blockHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchPainter oldDelegate) => true;
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  _ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    // Moving horizontal scanline
    final y = progress * size.height;
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    
    // Very subtle flicker layer
    if (Random().nextDouble() > 0.98) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withValues(alpha: 0.01),
      );
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => true;
}

class MatrixCheckRedPulse extends StatefulWidget {
  const MatrixCheckRedPulse({super.key});

  @override
  State<MatrixCheckRedPulse> createState() => _MatrixCheckRedPulseState();
}

class _MatrixCheckRedPulseState extends State<MatrixCheckRedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
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
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.3 * _controller.value),
              width: 4 * _controller.value,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.1 * _controller.value),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
        );
      },
    );
  }
}
