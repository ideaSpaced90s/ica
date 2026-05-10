import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

class WalnutPiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;

  WalnutPiecePainter({required this.type, required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final ivoryWhite = const Color(0xFFFDFDFD);
    final ivoryCloud = const Color(0xFFEAEAEA);
    final walnutLight = const Color(0xFF5A4030);
    final walnutDark = const Color(0xFF3E2718);

    final Color primaryColor = isWhite ? ivoryWhite : walnutLight;
    final Color secondaryColor = isWhite ? ivoryCloud : walnutDark;

    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: isWhite ? 0.45 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, secondaryColor, secondaryColor],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Offset.zero & size);

    final Path path = _getSimplifiedStauntonPath(type, size);

    // 1. Subtle piece base shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 + 2, size.height * 0.9 + 2),
        width: size.width * 0.6,
        height: size.height * 0.1,
      ),
      shadowPaint,
    );

    // 2. Main shape
    canvas.drawPath(path, fillPaint);
    
    // 3. Highlight edge for 3D feel
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isWhite ? 0.3 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, highlightPaint);
    canvas.restore();

    // 4. Border
    canvas.drawPath(path, borderPaint);
  }

  Path _getSimplifiedStauntonPath(chess_lib.PieceType type, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    switch (type) {
      case chess_lib.PieceType.PAWN:
        path.moveTo(midX, h * 0.25);
        path.addOval(Rect.fromCircle(center: Offset(midX, h * 0.35), radius: w * 0.12));
        path.moveTo(midX - w * 0.15, h * 0.45);
        path.quadraticBezierTo(midX, h * 0.5, midX + w * 0.15, h * 0.45);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.85);
        path.close();
        break;
      case chess_lib.PieceType.KNIGHT:
        path.moveTo(midX - w * 0.05, h * 0.2);
        path.lineTo(midX + w * 0.2, h * 0.3);
        path.lineTo(midX + w * 0.1, h * 0.5);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.2, h * 0.4);
        path.close();
        break;
      case chess_lib.PieceType.BISHOP:
        path.moveTo(midX, h * 0.15);
        path.lineTo(midX + w * 0.18, h * 0.45);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.18, h * 0.45);
        path.close();
        // Miter slot
        break;
      case chess_lib.PieceType.ROOK:
        path.moveTo(midX - w * 0.2, h * 0.25);
        path.lineTo(midX + w * 0.2, h * 0.25);
        path.lineTo(midX + w * 0.2, h * 0.35);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.2, h * 0.35);
        path.close();
        break;
      case chess_lib.PieceType.QUEEN:
        path.moveTo(midX, h * 0.1);
        path.lineTo(midX + w * 0.25, h * 0.3);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.3);
        path.close();
        break;
      case chess_lib.PieceType.KING:
        path.moveTo(midX - w * 0.1, h * 0.05);
        path.lineTo(midX + w * 0.1, h * 0.05);
        path.lineTo(midX + w * 0.1, h * 0.2);
        path.lineTo(midX + w * 0.25, h * 0.2);
        path.lineTo(midX + w * 0.35, h * 0.85);
        path.lineTo(midX - w * 0.35, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.2);
        path.lineTo(midX - w * 0.1, h * 0.2);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(WalnutPiecePainter oldDelegate) => false;
}
