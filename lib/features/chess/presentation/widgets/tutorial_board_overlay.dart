import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/tutorial_lesson.dart';
import '../scholarly_theme.dart';

class TutorialBoardOverlayPainter extends CustomPainter {
  final TutorialOverlayEffect effect;
  final List<String> highlightSquares;
  final List<String> animatePathSquares;
  final String? glowSquare;
  final String? dangerZone;
  final double animationProgress;
  final bool isFlipped;

  TutorialBoardOverlayPainter({
    required this.effect,
    this.highlightSquares = const [],
    this.animatePathSquares = const [],
    this.glowSquare,
    this.dangerZone,
    required this.animationProgress,
    this.isFlipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double sqSize = size.width / 8;

    // 1. Render Basic Selection Highlights
    for (final sq in highlightSquares) {
      _drawSquareGlow(canvas, sq, sqSize, ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.4));
    }

    if (glowSquare != null) {
      _drawSquareGlow(canvas, glowSquare!, sqSize, ScholarlyTheme.accentYellow.withValues(alpha: 0.6));
    }

    if (dangerZone != null) {
      _drawSquareGlow(canvas, dangerZone!, sqSize, Colors.redAccent.withValues(alpha: 0.5));
    }

    // 2. Render Specialized Tutorial Graphical Overlays
    switch (effect) {
      case TutorialOverlayEffect.none:
        break;
      case TutorialOverlayEffect.glowSquare:
        if (highlightSquares.isNotEmpty) {
          final center = _getSquareCenter(highlightSquares.first, sqSize);
          final paint = Paint()
            ..color = ScholarlyTheme.accentBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0;
          final radius = (sqSize / 2.2) + (math.sin(animationProgress * math.pi * 2) * 2);
          canvas.drawCircle(center, radius, paint);
        }
        break;
      case TutorialOverlayEffect.animatePath:
        if (animatePathSquares.length >= 2) {
          _drawAnimatedArrow(canvas, animatePathSquares, sqSize);
        }
        break;
      case TutorialOverlayEffect.dangerZone:
        for (final sq in highlightSquares) {
          _drawSquareBorder(canvas, sq, sqSize, Colors.redAccent, strokeWidth: 3.0);
        }
        break;
      case TutorialOverlayEffect.knightLPath:
        if (highlightSquares.isNotEmpty) {
          final startSq = highlightSquares.first;
          // Example static target for L demo: two up, one right
          final p1 = _getSquareCenter(startSq, sqSize);
          // Calculate theoretical L offsets based on board layout
          final c1 = _coordinate(startSq);
          if (c1 != null) {
            final midSq = _toSquareName(c1.file, math.max(0, math.min(7, c1.rank + 2)));
            final endSq = _toSquareName(math.max(0, math.min(7, c1.file + 1)), math.max(0, math.min(7, c1.rank + 2)));
            final p2 = _getSquareCenter(midSq, sqSize);
            final p3 = _getSquareCenter(endSq, sqSize);

            final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy);
            final paint = Paint()
              ..color = Colors.deepOrangeAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.0
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round;
            canvas.drawPath(path, paint);
            canvas.drawCircle(p3, 6.0, Paint()..color = Colors.deepOrangeAccent);
          }
        }
        break;
      case TutorialOverlayEffect.bishopDiagonals:
        if (highlightSquares.isNotEmpty) {
          final startSq = highlightSquares.first;
          final c = _coordinate(startSq);
          if (c != null) {
            final center = _getSquareCenter(startSq, sqSize);
            final paint = Paint()
              ..color = Colors.purpleAccent.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0;
            // Draw diagonal visual transit axes
            canvas.drawLine(Offset(center.dx - sqSize * 3, center.dy + sqSize * 3), Offset(center.dx + sqSize * 3, center.dy - sqSize * 3), paint);
            canvas.drawLine(Offset(center.dx - sqSize * 3, center.dy - sqSize * 3), Offset(center.dx + sqSize * 3, center.dy + sqSize * 3), paint);
          }
        }
        break;
      case TutorialOverlayEffect.rookLanes:
        if (highlightSquares.isNotEmpty) {
          final startSq = highlightSquares.first;
          final center = _getSquareCenter(startSq, sqSize);
          final paint = Paint()
            ..color = ScholarlyTheme.accentBlue.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0;
          // Draw orthogonal visual targeting axes
          canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);
          canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
        }
        break;
      case TutorialOverlayEffect.checkPulse:
        if (highlightSquares.isNotEmpty) {
          final center = _getSquareCenter(highlightSquares.first, sqSize);
          final maxRadius = sqSize * 0.8;
          final currentRadius = maxRadius * animationProgress;
          final alpha = (1.0 - animationProgress).clamp(0.0, 1.0);
          final paint = Paint()
            ..color = Colors.redAccent.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0;
          canvas.drawCircle(center, currentRadius, paint);
          // Highlight perimeter ring permanently
          _drawSquareBorder(canvas, highlightSquares.first, sqSize, Colors.redAccent, strokeWidth: 2.0);
        }
        break;
      case TutorialOverlayEffect.castlingPath:
        if (highlightSquares.length >= 2) {
          final pKing = _getSquareCenter(highlightSquares[0], sqSize);
          final pRook = _getSquareCenter(highlightSquares.last, sqSize);
          final paint = Paint()
            ..color = Colors.teal
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(pKing, pRook, paint);
          canvas.drawCircle(pKing, 5.0, Paint()..color = Colors.teal);
          canvas.drawCircle(pRook, 5.0, Paint()..color = Colors.teal);
        }
        break;
      case TutorialOverlayEffect.enPassantArrow:
        if (highlightSquares.length >= 2) {
          final pSource = _getSquareCenter(highlightSquares[0], sqSize);
          final pTarget = _getSquareCenter(highlightSquares[1], sqSize);
          _drawArrow(canvas, pSource, pTarget, Colors.deepPurpleAccent, strokeWidth: 4.0);
        }
        break;
    }
  }

  void _drawSquareGlow(Canvas canvas, String sqName, double sqSize, Color color) {
    final rect = _getSquareRect(sqName, sqSize);
    if (rect != null) {
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }
  }

  void _drawSquareBorder(Canvas canvas, String sqName, double sqSize, Color color, {double strokeWidth = 2.0}) {
    final rect = _getSquareRect(sqName, sqSize);
    if (rect != null) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRect(rect.deflate(strokeWidth / 2), paint);
    }
  }

  void _drawAnimatedArrow(Canvas canvas, List<String> squares, double sqSize) {
    if (squares.length < 2) return;
    final start = _getSquareCenter(squares.first, sqSize);
    final end = _getSquareCenter(squares.last, sqSize);

    // Calculate partial progression distance for continuous trace path rendering
    final totalVector = end - start;
    final currentPoint = start + (totalVector * animationProgress);

    final paint = Paint()
      ..color = ScholarlyTheme.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, currentPoint, paint);

    // Render arrowhead if movement transit path completes above visible threshold
    if (animationProgress > 0.8) {
      _drawArrowHead(canvas, start, currentPoint, ScholarlyTheme.accentBlue);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color, {double strokeWidth = 3.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    _drawArrowHead(canvas, start, end, color);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Color color) {
    const double arrowSize = 12.0;
    const double arrowAngle = math.pi / 6; // 30 degrees

    final double angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final Offset p1 = Offset(end.dx - arrowSize * math.cos(angle - arrowAngle), end.dy - arrowSize * math.sin(angle - arrowAngle));
    final Offset p2 = Offset(end.dx - arrowSize * math.cos(angle + arrowAngle), end.dy - arrowSize * math.sin(angle + arrowAngle));

    final path = Path()..moveTo(end.dx, end.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  Rect? _getSquareRect(String sqName, double sqSize) {
    final c = _coordinate(sqName);
    if (c == null) return null;
    final fileIdx = isFlipped ? 7 - c.file : c.file;
    final rankIdx = isFlipped ? c.rank : 7 - c.rank;
    return Rect.fromLTWH(fileIdx * sqSize, rankIdx * sqSize, sqSize, sqSize);
  }

  Offset _getSquareCenter(String sqName, double sqSize) {
    final rect = _getSquareRect(sqName, sqSize);
    return rect?.center ?? Offset.zero;
  }

  _Coord? _coordinate(String sqName) {
    if (sqName.length < 2) return null;
    final fileChar = sqName.codeUnitAt(0);
    final rankChar = sqName.codeUnitAt(1);
    final file = fileChar - 'a'.codeUnitAt(0);
    final rank = rankChar - '1'.codeUnitAt(0);
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return _Coord(file, rank);
  }

  String _toSquareName(int file, int rank) {
    final f = String.fromCharCode('a'.codeUnitAt(0) + file);
    final r = String.fromCharCode('1'.codeUnitAt(0) + rank);
    return '$f$r';
  }

  @override
  bool shouldRepaint(covariant TutorialBoardOverlayPainter oldDelegate) {
    return oldDelegate.effect != effect ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.glowSquare != glowSquare ||
        oldDelegate.dangerZone != dangerZone ||
        oldDelegate.isFlipped != isFlipped;
  }
}

class _Coord {
  final int file;
  final int rank;
  const _Coord(this.file, this.rank);
}
