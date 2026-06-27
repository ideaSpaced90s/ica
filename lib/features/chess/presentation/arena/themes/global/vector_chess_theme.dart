import 'package:flutter/material.dart';
import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../../shared/themes/chess_theme.dart';
import '../../../shared/themes/animation_group.dart';
import '../../effects/group_b_effects.dart';
import 'dart:math' as math;



class VectorChessTheme extends ChessTheme {
  final assets_lib.ChessTheme packageTheme;

  const VectorChessTheme({
    required super.id,
    required super.name,
    required this.packageTheme,
  });

  @override
  Color get lightSquare {
    if (id == 'vector_wood') {
      return const Color(0xFFEAD8C3); // Lighter, creamy maple/oak color for better contrast
    }
    return packageTheme.lightSquare;
  }

  @override
  Color get darkSquare {
    if (id == 'vector_wood') {
      return const Color(0xFFAC7C54); // Light brown wood color
    }
    return packageTheme.darkSquare;
  }

  @override
  Color get lightCoordinateColor => packageTheme.darkSquare.withValues(alpha: 0.8);

  @override
  Color get darkCoordinateColor => packageTheme.lightSquare.withValues(alpha: 0.8);

  @override
  Color get frameColor => packageTheme.boardBorder;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.5),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    if (id == 'vector_wood') {
      return WoodMosaicPainter(
        isLight: isLight,
        baseColor: isLight ? lightSquare : darkSquare,
      );
    }
    return null;
  }

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    if (id == 'vector_wood') {
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
      final assetPath = 'assets/pieces/persia/${colorStr}_$typeStr.png';
      final isPawn = type.toUpperCase() == 'P';

      final pieceWidget = AspectRatio(
        aspectRatio: 1.0,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );

      if (!isPawn) {
        return Transform.scale(
          scale: 1.2,
          child: pieceWidget,
        );
      }
      return pieceWidget;
    }

    if (id == 'vector_glass' || id == 'vector_championship' || id == 'rated_bnw') {
      final rowIndex = isWhite ? 0 : 1;
      int colIndex;
      switch (type.toUpperCase()) {
        case 'K':
          colIndex = 0;
          break;
        case 'Q':
          colIndex = 1;
          break;
        case 'B':
          colIndex = 2;
          break;
        case 'N':
          colIndex = 3;
          break;
        case 'R':
          colIndex = 4;
          break;
        case 'P':
        default:
          colIndex = 5;
          break;
      }

      return AspectRatio(
        aspectRatio: 1,
        child: ClipRect(
          child: FractionallySizedBox(
            widthFactor: 6.0,
            heightFactor: 2.0,
            alignment: Alignment(
              (colIndex * 2.0 / 5.0) - 1.0,
              (rowIndex * 2.0 / 1.0) - 1.0,
            ),
            child: Image.asset(
              'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
    }

    final pieceType = _mapPieceType(type);
    final pieceColor = isWhite ? assets_lib.ChessPieceColor.white : assets_lib.ChessPieceColor.black;

    return assets_lib.ChessPieceWidget(
      type: pieceType,
      color: pieceColor,
      theme: packageTheme,
      size: 48.0,
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return Center(
      child: Container(
        width: isEnemy ? 38 : 12,
        height: isEnemy ? 38 : 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy
              ? Colors.transparent
              : packageTheme.activeHighlight,
          border: isEnemy
              ? Border.all(color: packageTheme.activeHighlight, width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  AnimationGroup get animationGroup {
    if (id == 'vector_glass' || id == 'vector_championship') {
      return AnimationGroup.a;
    }
    return AnimationGroup.b; // e.g. vector_wood
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    if (animationGroup == AnimationGroup.a) {
      return DefaultSelectionRing(color: packageTheme.activeHighlight);
    }
    return GroupBSelectionPulse(color: packageTheme.activeHighlight);
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    if (animationGroup == AnimationGroup.a) {
      return null;
    }
    return GroupBCaptureFlash(position: position, onComplete: onComplete);
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: packageTheme.activeHighlight.withValues(alpha: opacity),
      ),
    );
  }

  assets_lib.ChessPieceType _mapPieceType(String type) {
    switch (type.toUpperCase()) {
      case 'K': return assets_lib.ChessPieceType.king;
      case 'Q': return assets_lib.ChessPieceType.queen;
      case 'R': return assets_lib.ChessPieceType.rook;
      case 'B': return assets_lib.ChessPieceType.bishop;
      case 'N': return assets_lib.ChessPieceType.knight;
      case 'P':
      default:
        return assets_lib.ChessPieceType.pawn;
    }
  }
}

class WoodMosaicPainter extends CustomPainter {
  final bool isLight;
  final Color baseColor;

  WoodMosaicPainter({required this.isLight, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final Paint paint = Paint()..color = baseColor;
    canvas.drawRect(rect, paint);

    final random = math.Random(isLight ? 777 : 888);

    final bool isVertical = !isLight;
    final int plankCount = 4;
    final double step = size.width / plankCount;

    for (int i = 0; i < plankCount; i++) {
      Rect plankRect;
      if (isVertical) {
        plankRect = Rect.fromLTWH(i * step, 0, step, size.height);
      } else {
        plankRect = Rect.fromLTWH(0, i * step, size.width, step);
      }

      final double toneShift = (random.nextDouble() - 0.5) * 0.08;
      final plankColor = _shiftColor(baseColor, toneShift);

      final plankPaint = Paint()..color = plankColor;
      canvas.drawRect(plankRect, plankPaint);

      _drawWoodGrain(canvas, plankRect, isVertical, random, plankColor);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Dark shadow groove
      borderPaint.color = Colors.black.withValues(alpha: 0.15);
      if (isVertical) {
        canvas.drawLine(plankRect.topRight, plankRect.bottomRight, borderPaint);
      } else {
        canvas.drawLine(plankRect.bottomLeft, plankRect.bottomRight, borderPaint);
      }

      // Light highlight groove
      borderPaint.color = Colors.white.withValues(alpha: 0.15);
      if (isVertical) {
        canvas.drawLine(plankRect.topLeft, plankRect.bottomLeft, borderPaint);
      } else {
        canvas.drawLine(plankRect.topLeft, plankRect.topRight, borderPaint);
      }
    }

    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dark bevel
    bevelPaint.color = Colors.black.withValues(alpha: 0.2);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, bevelPaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, bevelPaint);

    // Light bevel
    bevelPaint.color = Colors.white.withValues(alpha: 0.25);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, bevelPaint);
    canvas.drawLine(rect.topLeft, rect.topRight, bevelPaint);
  }

  Color _shiftColor(Color color, double shift) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + shift).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  void _drawWoodGrain(Canvas canvas, Rect rect, bool isVertical, math.Random random, Color base) {
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final int grainCount = 3 + random.nextInt(3);
    for (int j = 0; j < grainCount; j++) {
      grainPaint.color = Colors.black.withValues(alpha: 0.04 + random.nextDouble() * 0.05);

      final path = Path();
      if (isVertical) {
        final double startX = rect.left + random.nextDouble() * rect.width;
        final double endX = rect.left + random.nextDouble() * rect.width;
        final double controlX = rect.left + random.nextDouble() * rect.width;

        path.moveTo(startX, rect.top);
        path.quadraticBezierTo(controlX, rect.top + rect.height / 2, endX, rect.bottom);
      } else {
        final double startY = rect.top + random.nextDouble() * rect.height;
        final double endY = rect.top + random.nextDouble() * rect.height;
        final double controlY = rect.top + random.nextDouble() * rect.height;

        path.moveTo(rect.left, startY);
        path.quadraticBezierTo(rect.left + rect.width / 2, controlY, rect.right, endY);
      }
      canvas.drawPath(path, grainPaint);
    }

    if (random.nextDouble() < 0.25) {
      final knotPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.black.withValues(alpha: 0.05);

      final double knotX = rect.left + random.nextDouble() * rect.width;
      final double knotY = rect.top + random.nextDouble() * rect.height;
      final double rx = 2.0 + random.nextDouble() * 5.0;
      final double ry = 1.0 + random.nextDouble() * 2.0;

      canvas.save();
      canvas.translate(knotX, knotY);
      canvas.rotate(isVertical ? 0 : math.pi / 2);
      canvas.drawOval(Rect.fromLTWH(-rx, -ry, rx * 2, ry * 2), knotPaint);
      canvas.drawOval(Rect.fromLTWH(-rx * 0.6, -ry * 0.6, rx * 1.2, ry * 1.2), knotPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

