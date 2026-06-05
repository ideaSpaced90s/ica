import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/widgets/chess_piece_widget.dart';
import '../../shared/themes/animation_group.dart';
import '../../shared/animations/signature_move_style.dart';
import 'sprite_chess_theme.dart';

class ArcChessTheme extends SpriteChessTheme {
  const ArcChessTheme()
      : super(
          id: 'sprite_arc',
          name: 'Arc',
          individualPiecesFolder: 'assets/pieces/arc-webP',
          pieceExtension: 'webp',
          lightSquare: const Color(0xFFE4DAC3),
          darkSquare: const Color(0xFF1C343A),
          frameColor: const Color(0xFFC3A555),
        );

  @override
  AnimationGroup get animationGroup => AnimationGroup.c;

  @override
  SignatureMoveStyle? get signatureMoveStyle => const OrbitalPulseTrail();

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      color: const Color(0xFF0F1E22),
      child: CustomPaint(
        painter: ArcBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const OrbitalSelectionRing();
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return OrbitalCapture(position: position, onComplete: onComplete);
  }

  static const Map<String, double> _speeds = {
    'pawn': 1.4,
    'knight': 1.8,
    'bishop': 0.9,
    'rook': 0.7,
    'queen': 1.1,
    'king': 0.5,
  };

  static const Map<String, double> _typePhase = {
    'pawn': 0.00,
    'knight': 0.17,
    'bishop': 0.33,
    'rook': 0.51,
    'queen': 0.67,
    'king': 0.83,
  };

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    final colorStr = isWhite ? 'light' : 'dark';
    
    String typeStr;
    switch (type.toUpperCase()) {
      case 'K':
        typeStr = 'king';
        break;
      case 'Q':
        typeStr = 'queen';
        break;
      case 'B':
        typeStr = 'bishop';
        break;
      case 'N':
        typeStr = 'knight';
        break;
      case 'R':
        typeStr = 'rook';
        break;
      case 'P':
      default:
        typeStr = 'pawn';
        break;
    }

    final speed = _speeds[typeStr] ?? 1.0;
    final typeOff = _typePhase[typeStr] ?? 0.0;

    double squareOff = 0.0;
    try {
      final widget = context.widget;
      if (widget is ChessPieceWidget) {
        final sq = widget.squareName;
        if (sq.length >= 2) {
          squareOff = ((sq.codeUnitAt(0) * 7 + sq.codeUnitAt(1) * 13) % 100) / 100.0;
        }
      }
    } catch (_) {}

    final t = (animationValue * speed + typeOff + squareOff) % 1.0;
    final rawCurve = math.pow(math.sin(t * math.pi), 8).toDouble();

    int frameIndex = 0;
    if (rawCurve >= 0.65) {
      frameIndex = 2;
    } else if (rawCurve >= 0.25) {
      frameIndex = 1;
    } else {
      frameIndex = 0;
    }

    final assetPath = '$individualPiecesFolder/${colorStr}_${typeStr}_$frameIndex.$pieceExtension';

    return AspectRatio(
      aspectRatio: 1.0,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class ArcBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFC3A555).withValues(alpha: 0.08)
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    
    canvas.drawCircle(center, size.width * 0.15, paint);
    canvas.drawCircle(center, size.width * 0.32, paint);
    canvas.drawCircle(center, size.width * 0.45, paint);
    
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);

    final tickLen = size.width * 0.04;
    canvas.drawLine(Offset(tickLen, tickLen), Offset(tickLen * 2, tickLen), paint);
    canvas.drawLine(Offset(tickLen, tickLen), Offset(tickLen, tickLen * 2), paint);
    
    canvas.drawLine(Offset(size.width - tickLen, tickLen), Offset(size.width - tickLen * 2, tickLen), paint);
    canvas.drawLine(Offset(size.width - tickLen, tickLen), Offset(size.width - tickLen, tickLen * 2), paint);

    canvas.drawLine(Offset(tickLen, size.height - tickLen), Offset(tickLen * 2, size.height - tickLen), paint);
    canvas.drawLine(Offset(tickLen, size.height - tickLen), Offset(tickLen, size.height - tickLen * 2), paint);

    canvas.drawLine(Offset(size.width - tickLen, size.height - tickLen), Offset(size.width - tickLen * 2, size.height - tickLen), paint);
    canvas.drawLine(Offset(size.width - tickLen, size.height - tickLen), Offset(size.width - tickLen, size.height - tickLen * 2), paint);
  }

  @override
  bool shouldRepaint(covariant ArcBackgroundPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 1. Orbital Selection Ring
// ────────────────────────────────────────────────────────────────────────
class OrbitalSelectionRing extends StatefulWidget {
  const OrbitalSelectionRing({super.key});

  @override
  State<OrbitalSelectionRing> createState() => _OrbitalSelectionRingState();
}

class _OrbitalSelectionRingState extends State<OrbitalSelectionRing>
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
            painter: _OrbitalSelectionPainter(progress: _controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _OrbitalSelectionPainter extends CustomPainter {
  final double progress;

  _OrbitalSelectionPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    
    final paint = Paint()
      ..color = const Color(0xFFC3A555)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final startAngle = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi * 0.6,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + math.pi,
      math.pi * 0.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalSelectionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ────────────────────────────────────────────────────────────────────────
// 2. Orbital Capture Effect
// ────────────────────────────────────────────────────────────────────────
class OrbitalCapture extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const OrbitalCapture({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<OrbitalCapture> createState() => _OrbitalCaptureState();
}

class _OrbitalCaptureState extends State<OrbitalCapture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
          painter: _OrbitalCapturePainter(
            center: widget.position,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _OrbitalCapturePainter extends CustomPainter {
  final Offset center;
  final double progress;

  _OrbitalCapturePainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    final maxRadius = squareSize * 1.5;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = const Color(0xFFC3A555).withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1.0 - progress);

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.15) % 1.0;
      final radius = maxRadius * ringProgress;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalCapturePainter oldDelegate) {
    return true;
  }
}
