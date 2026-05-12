import 'package:flutter/material.dart';

class PuzzlePiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;

  PuzzlePiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final width = size.width;
    final height = size.height;

    // Lego Colors: Plastic Red for Black, Plastic White for White
    final pieceColor = isWhite
        ? const Color(0xFFF5F5F5)
        : const Color(0xFFD32F2F);
    final shadowColor = isWhite
        ? const Color(0xFFBDBDBD)
        : const Color(0xFF8B0000);
    final highlightColor = isWhite ? Colors.white : const Color(0xFFFF5252);

    final paint = Paint()
      ..color = pieceColor
      ..style = PaintingStyle.fill;
    final sPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;
    final hPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;

    canvas.save();
    // Lifting effect for selection
    if (isHighlighted) {
      canvas.translate(0, -height * 0.05);
    }

    switch (type) {
      case 'K':
        _drawKing(canvas, center, width, paint, sPaint, hPaint);
        break;
      case 'Q':
        _drawQueen(canvas, center, width, paint, sPaint, hPaint);
        break;
      case 'B':
        _drawBishop(canvas, center, width, paint, sPaint, hPaint);
        break;
      case 'N':
        _drawKnight(canvas, center, width, paint, sPaint, hPaint);
        break;
      case 'R':
        _drawRook(canvas, center, width, paint, sPaint, hPaint);
        break;
      default:
        _drawPawn(canvas, center, width, paint, sPaint, hPaint);
    }

    canvas.restore();
  }

  void _drawStud(
    Canvas canvas,
    Offset pos,
    double radius,
    Paint fill,
    Paint highlight,
  ) {
    canvas.drawCircle(pos, radius, fill);
    // Stud highlight (inner circle)
    canvas.drawCircle(
      pos - Offset(radius * 0.2, radius * 0.2),
      radius * 0.5,
      Paint()..color = highlight.color.withValues(alpha: 0.3),
    );
  }

  void _drawBlock(
    Canvas canvas,
    Rect rect,
    double radius,
    Paint fill,
    Paint shadow,
    Paint highlight,
  ) {
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    // Main body
    canvas.drawRRect(rRect, fill);
    // Suble 3D shading
    final shadowPath = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()..color = shadow.color.withValues(alpha: 0.2),
    );
    // Top highlight
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 2),
      Paint()..color = highlight.color.withValues(alpha: 0.4),
    );
  }

  void _drawKing(
    Canvas canvas,
    Offset center,
    double w,
    Paint f,
    Paint s,
    Paint h,
  ) {
    // Base block
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, w * 0.1),
        width: w * 0.7,
        height: w * 0.6,
      ),
      4,
      f,
      s,
      h,
    );
    // Upper block
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, -w * 0.2),
        width: w * 0.5,
        height: w * 0.3,
      ),
      2,
      f,
      s,
      h,
    );
    // Cross / Top
    _drawStud(canvas, center + Offset(0, -w * 0.4), w * 0.1, f, h);
    _drawStud(canvas, center + Offset(w * 0.15, -w * 0.2), w * 0.08, f, h);
    _drawStud(canvas, center + Offset(-w * 0.15, -w * 0.2), w * 0.08, f, h);
  }

  void _drawQueen(
    Canvas canvas,
    Offset center,
    double w,
    Paint f,
    Paint s,
    Paint h,
  ) {
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, w * 0.15),
        width: w * 0.7,
        height: w * 0.5,
      ),
      4,
      f,
      s,
      h,
    );
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, -w * 0.1),
        width: w * 0.55,
        height: w * 0.4,
      ),
      2,
      f,
      s,
      h,
    );
    // Studs around
    for (int i = 0; i < 5; i++) {
      final x = (i - 2) * w * 0.12;
      _drawStud(canvas, center + Offset(x, -w * 0.35), w * 0.07, f, h);
    }
  }

  void _drawBishop(
    Canvas canvas,
    Offset center,
    double w,
    Paint f,
    Paint s,
    Paint h,
  ) {
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, w * 0.2),
        width: w * 0.6,
        height: w * 0.45,
      ),
      4,
      f,
      s,
      h,
    );
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, -w * 0.15),
        width: w * 0.4,
        height: w * 0.5,
      ),
      20,
      f,
      s,
      h,
    ); // Rounded
    _drawStud(canvas, center + Offset(0, -w * 0.45), w * 0.08, f, h);
  }

  void _drawKnight(
    Canvas canvas,
    Offset center,
    double w,
    Paint f,
    Paint s,
    Paint h,
  ) {
    // Base
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, w * 0.25),
        width: w * 0.6,
        height: w * 0.3,
      ),
      2,
      f,
      s,
      h,
    );
    // Neck
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(-w * 0.1, 0),
        width: w * 0.3,
        height: w * 0.6,
      ),
      2,
      f,
      s,
      h,
    );
    // Head
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(w * 0.1, -w * 0.2),
        width: w * 0.5,
        height: w * 0.3,
      ),
      2,
      f,
      s,
      h,
    );
    _drawStud(canvas, center + Offset(0, -w * 0.4), w * 0.08, f, h);
    _drawStud(canvas, center + Offset(w * 0.2, -w * 0.4), w * 0.08, f, h);
  }

  void _drawRook(
    Canvas canvas,
    Offset center,
    double w,
    Paint f,
    Paint s,
    Paint h,
  ) {
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, w * 0.1),
        width: w * 0.6,
        height: w * 0.7,
      ),
      2,
      f,
      s,
      h,
    );
    // Top battlements (studs)
    _drawStud(canvas, center + Offset(-w * 0.2, -w * 0.4), w * 0.1, f, h);
    _drawStud(canvas, center + Offset(w * 0.2, -w * 0.4), w * 0.1, f, h);
    _drawStud(
      canvas,
      center + Offset(-w * 0.2, -w * 0.1),
      w * 0.05,
      h,
      h,
    ); // Highlight
  }

  void _drawPawn(
    Canvas canvas,
    Offset center,
    double w,
    Paint f,
    Paint s,
    Paint h,
  ) {
    _drawBlock(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, w * 0.2),
        width: w * 0.5,
        height: w * 0.5,
      ),
      2,
      f,
      s,
      h,
    );
    _drawStud(canvas, center + Offset(0, -w * 0.15), w * 0.12, f, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
