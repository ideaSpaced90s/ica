import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../shared/themes/chess_theme.dart';
import '../../../shared/widgets/chess_piece_widget.dart';
import '../../effects/group_b_effects.dart';
import '../../../shared/themes/animation_group.dart';

class SpriteChessTheme extends ChessTheme {
  final String? spritePath;
  final String? individualPiecesFolder;
  final String pieceExtension;
  @override
  String? get boardImagePath => null;
  @override
  final Color lightSquare;
  @override
  final Color darkSquare;
  @override
  final Color frameColor;

  const SpriteChessTheme({
    required super.id,
    required super.name,
    this.spritePath,
    this.individualPiecesFolder,
    this.pieceExtension = 'png',
    required this.lightSquare,
    required this.darkSquare,
    required this.frameColor,
  });

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    if (id == 'sprite_marble') {
      return MarbleMosaicPainter(
        isLight: isLight,
        baseColor: isLight ? lightSquare : darkSquare,
      );
    }
    if (id == 'sprite_timber') {
      return TimberMosaicPainter(
        isLight: isLight,
        baseColor: isLight ? lightSquare : darkSquare,
      );
    }
    if (id == 'sprite_copper') {
      return CopperScratchesPainter(
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
    final isPawn = type.toUpperCase() == 'P';
    if (individualPiecesFolder != null) {
      final colorStr = id == 'sprite_fairytale'
          ? (isWhite ? 'white' : 'black')
          : (isWhite ? 'light' : 'dark');
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
          typeStr = id == 'sprite_fairytale' ? 'pawn_hammer' : 'pawn';
          break;
      }
      int variantIndex = 0;
      try {
        final widget = context.widget;
        if (widget is ChessPieceWidget) {
          final square = widget.squareName;
          if (square.length >= 2) {
            variantIndex = (square.codeUnitAt(0) + square.codeUnitAt(1)) % 3;
          }
        }
      } catch (_) {}

      final assetPath = pieceExtension == 'webp'
          ? '$individualPiecesFolder/${colorStr}_${typeStr}_$variantIndex.$pieceExtension'
          : '$individualPiecesFolder/${colorStr}_$typeStr.$pieceExtension';

      final image = Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
      final shouldOutlineDarkTimber = id == 'sprite_timber' && !isWhite;

      final pieceWidget = AspectRatio(
        aspectRatio: 1.0,
        child: shouldOutlineDarkTimber
            ? Stack(
                fit: StackFit.expand,
                children: [
                  for (final offset in const [
                    Offset(-1.2, 0),
                    Offset(1.2, 0),
                    Offset(0, -1.2),
                    Offset(0, 1.2),
                  ])
                    Transform.translate(
                      offset: offset,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          const Color(0xFFFFF1D2).withValues(alpha: 0.72),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  image,
                ],
              )
            : image,
      );

      if (id == 'sprite_persia' && !isPawn) {
        return Transform.scale(
          scale: 1.2,
          child: pieceWidget,
        );
      }
      const pawnScaleThemes = {
        'sprite_marble',
        'sprite_seasons',
        'sprite_plasma',
        'sprite_lightning',
        'sprite_diamonds',
        'sprite_overgrown',
        'sprite_copper',
        'sprite_ivory',
        'sprite_timber',
        'sprite_royal',
        'sprite_bubblegum',
        'sprite_goldsilver',
        'sprite_desert',
      };
      if (pawnScaleThemes.contains(id) && isPawn) {
        return Transform.scale(
          scale: 0.8,
          child: pieceWidget,
        );
      }
      return pieceWidget;
    }

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
        colIndex = 5;
        break;
      default:
        colIndex = 5;
    }

    final pieceWidget = AspectRatio(
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
            spritePath ?? '',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );

    if (id == 'sprite_persia' && !isPawn) {
      return Transform.scale(
        scale: 1.2,
        child: pieceWidget,
      );
    }
    const pawnScaleThemes = {
      'sprite_marble',
      'sprite_seasons',
      'sprite_plasma',
      'sprite_lightning',
      'sprite_diamonds',
      'sprite_overgrown',
      'sprite_copper',
      'sprite_ivory',
      'sprite_timber',
      'sprite_royal',
      'sprite_bubblegum',
      'sprite_goldsilver',
      'sprite_desert',
    };
    if (pawnScaleThemes.contains(id) && isPawn) {
      return Transform.scale(
        scale: 0.8,
        child: pieceWidget,
      );
    }
    return pieceWidget;
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
              : const Color(0xFF0D6EFD).withValues(alpha: 0.75),
          border: isEnemy
              ? Border.all(color: const Color(0xFF0D6EFD), width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  AnimationGroup get animationGroup => AnimationGroup.b;

  @override
  Widget buildSelectionRing(BuildContext context) {
    return GroupBSelectionPulse(color: frameColor);
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return GroupBCaptureFlash(position: position, onComplete: onComplete);
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0056B3).withValues(alpha: opacity),
      ),
    );
  }
}

class MarbleMosaicPainter extends CustomPainter {
  final bool isLight;
  final Color baseColor;

  MarbleMosaicPainter({required this.isLight, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final Paint paint = Paint()..color = baseColor;
    canvas.drawRect(rect, paint);

    final random = math.Random(isLight ? 1111 : 2222);

    final double h = size.height / 3;
    final List<Rect> bricks = [
      // Row 0
      Rect.fromLTWH(0, 0, size.width * 0.3, h),
      Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, h),
      Rect.fromLTWH(size.width * 0.7, 0, size.width * 0.3, h),

      // Row 1
      Rect.fromLTWH(0, h, size.width * 0.5, h),
      Rect.fromLTWH(size.width * 0.5, h, size.width * 0.5, h),

      // Row 2
      Rect.fromLTWH(0, h * 2, size.width * 0.2, h),
      Rect.fromLTWH(size.width * 0.2, h * 2, size.width * 0.5, h),
      Rect.fromLTWH(size.width * 0.7, h * 2, size.width * 0.3, h),
    ];

    for (final brickRect in bricks) {
      final double toneShift = (random.nextDouble() - 0.5) * 0.06;
      final brickColor = _shiftColor(baseColor, toneShift);

      final brickPaint = Paint()..color = brickColor;
      canvas.drawRect(brickRect, brickPaint);

      _drawMarbleVeins(canvas, brickRect, random);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Dark shadow joint
      borderPaint.color = Colors.black.withValues(alpha: 0.12);
      canvas.drawLine(brickRect.bottomLeft, brickRect.bottomRight, borderPaint);
      canvas.drawLine(brickRect.topRight, brickRect.bottomRight, borderPaint);

      // Light highlight joint
      borderPaint.color = Colors.white.withValues(alpha: 0.18);
      canvas.drawLine(brickRect.topLeft, brickRect.bottomLeft, borderPaint);
      canvas.drawLine(brickRect.topLeft, brickRect.topRight, borderPaint);
    }

    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    bevelPaint.color = Colors.black.withValues(alpha: 0.15);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, bevelPaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, bevelPaint);

    bevelPaint.color = Colors.white.withValues(alpha: 0.2);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, bevelPaint);
    canvas.drawLine(rect.topLeft, rect.topRight, bevelPaint);
  }

  Color _shiftColor(Color color, double shift) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + shift).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  void _drawMarbleVeins(Canvas canvas, Rect rect, math.Random random) {
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 + random.nextDouble() * 0.8;

    final int veinCount = 2 + random.nextInt(3);
    for (int j = 0; j < veinCount; j++) {
      final baseAlpha = 0.05 + random.nextDouble() * 0.08;
      veinPaint.color = isLight
          ? (random.nextBool()
              ? const Color(0xFF8B7355).withValues(alpha: baseAlpha) // Gold/Beige vein
              : const Color(0xFF4A4A4A).withValues(alpha: baseAlpha)) // Grey vein
          : Colors.white.withValues(alpha: baseAlpha * 1.5); // White highlight vein

      final path = Path();
      
      final double startX = rect.left + random.nextDouble() * rect.width;
      final double startY = rect.top + (random.nextBool() ? 0 : rect.height);
      final double endX = rect.left + random.nextDouble() * rect.width;
      final double endY = rect.top + (startY == rect.top ? rect.height : 0);

      path.moveTo(startX, startY);
      
      final int midPoints = 2 + random.nextInt(3);
      double lastX = startX;
      double lastY = startY;
      for (int k = 1; k <= midPoints; k++) {
        final t = k / (midPoints + 1);
        final targetX = startX + (endX - startX) * t;
        final targetY = startY + (endY - startY) * t;
        
        final double offset = (random.nextDouble() - 0.5) * 5.0;
        final double nextX = targetX + offset;
        final double nextY = targetY - offset;

        path.quadraticBezierTo(
          (lastX + nextX) / 2,
          (lastY + nextY) / 2,
          nextX,
          nextY,
        );
        lastX = nextX;
        lastY = nextY;
      }
      path.lineTo(endX, endY);
      canvas.drawPath(path, veinPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TimberMosaicPainter extends CustomPainter {
  final bool isLight;
  final Color baseColor;

  TimberMosaicPainter({required this.isLight, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final Paint paint = Paint()..color = baseColor;
    canvas.drawRect(rect, paint);

    final random = math.Random(isLight ? 3333 : 4444);

    final double w = size.width;
    final double h = size.height;

    final double halfW = w / 2;
    final double halfH = h / 2;
    final double stripH = halfH / 3;
    final double stripW = halfW / 3;

    final List<_WoodStrip> strips = [];

    // Q1: Top-Left (Horizontal strips)
    for (int i = 0; i < 3; i++) {
      strips.add(_WoodStrip(
        rect: Rect.fromLTWH(0, i * stripH, halfW, stripH),
        isHorizontal: true,
      ));
    }

    // Q2: Top-Right (Vertical strips)
    for (int i = 0; i < 3; i++) {
      strips.add(_WoodStrip(
        rect: Rect.fromLTWH(halfW + i * stripW, 0, stripW, halfH),
        isHorizontal: false,
      ));
    }

    // Q3: Bottom-Left (Vertical strips)
    for (int i = 0; i < 3; i++) {
      strips.add(_WoodStrip(
        rect: Rect.fromLTWH(i * stripW, halfH, stripW, halfH),
        isHorizontal: false,
      ));
    }

    // Q4: Bottom-Right (Horizontal strips)
    for (int i = 0; i < 3; i++) {
      strips.add(_WoodStrip(
        rect: Rect.fromLTWH(halfW, halfH + i * stripH, halfW, stripH),
        isHorizontal: true,
      ));
    }

    for (final strip in strips) {
      final double toneShift = (random.nextDouble() - 0.5) * 0.08;
      final stripColor = _shiftColor(baseColor, toneShift);

      final stripPaint = Paint()..color = stripColor;
      canvas.drawRect(strip.rect, stripPaint);

      _drawWoodGrains(canvas, strip.rect, strip.isHorizontal, random, stripColor);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      borderPaint.color = Colors.black.withValues(alpha: 0.15);
      canvas.drawLine(strip.rect.bottomLeft, strip.rect.bottomRight, borderPaint);
      canvas.drawLine(strip.rect.topRight, strip.rect.bottomRight, borderPaint);

      borderPaint.color = Colors.white.withValues(alpha: 0.2);
      canvas.drawLine(strip.rect.topLeft, strip.rect.bottomLeft, borderPaint);
      canvas.drawLine(strip.rect.topLeft, strip.rect.topRight, borderPaint);
    }

    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    bevelPaint.color = Colors.black.withValues(alpha: 0.2);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, bevelPaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, bevelPaint);

    bevelPaint.color = Colors.white.withValues(alpha: 0.25);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, bevelPaint);
    canvas.drawLine(rect.topLeft, rect.topRight, bevelPaint);
  }

  Color _shiftColor(Color color, double shift) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + shift).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  void _drawWoodGrains(Canvas canvas, Rect rect, bool isHorizontal, math.Random random, Color baseColor) {
    final int lineCount = 3 + random.nextInt(3);

    final darkGrainColor = Color.lerp(baseColor, Colors.black, 0.3)!.withValues(alpha: 0.18);
    final lightGrainColor = Color.lerp(baseColor, Colors.white, 0.2)!.withValues(alpha: 0.12);

    for (int i = 0; i < lineCount; i++) {
      final isDarkLine = random.nextBool();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 + random.nextDouble() * 1.0
        ..color = isDarkLine ? darkGrainColor : lightGrainColor;

      final path = Path();

      if (isHorizontal) {
        final double startY = rect.top + random.nextDouble() * rect.height;
        final double endY = rect.top + random.nextDouble() * rect.height;

        path.moveTo(rect.left, startY);

        final double midX1 = rect.left + rect.width * 0.33;
        final double midY1 = startY + (random.nextDouble() - 0.5) * (rect.height * 0.4);

        final double midX2 = rect.left + rect.width * 0.66;
        final double midY2 = endY + (random.nextDouble() - 0.5) * (rect.height * 0.4);

        path.cubicTo(
          midX1, midY1.clamp(rect.top, rect.bottom),
          midX2, midY2.clamp(rect.top, rect.bottom),
          rect.right, endY,
        );
      } else {
        final double startX = rect.left + random.nextDouble() * rect.width;
        final double endX = rect.left + random.nextDouble() * rect.width;

        path.moveTo(startX, rect.top);

        final double midY1 = rect.top + rect.height * 0.33;
        final double midX1 = startX + (random.nextDouble() - 0.5) * (rect.width * 0.4);

        final double midY2 = rect.top + rect.height * 0.66;
        final double midX2 = endX + (random.nextDouble() - 0.5) * (rect.width * 0.4);

        path.cubicTo(
          midX1.clamp(rect.left, rect.right), midY1,
          midX2.clamp(rect.left, rect.right), midY2,
          endX, rect.bottom,
        );
      }
      canvas.drawPath(path, paint);
    }

    if (random.nextDouble() < 0.2) {
      final knotColor = Color.lerp(baseColor, Colors.black, 0.4)!.withValues(alpha: 0.15);
      final knotPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = knotColor;

      final double knotX = rect.left + rect.width * (0.25 + random.nextDouble() * 0.5);
      final double knotY = rect.top + rect.height * (0.25 + random.nextDouble() * 0.5);

      final double radiusX = (rect.width * 0.08).clamp(2.0, 6.0);
      final double radiusY = (rect.height * 0.08).clamp(2.0, 6.0);

      canvas.drawOval(Rect.fromCenter(center: Offset(knotX, knotY), width: radiusX * 2, height: radiusY * 2), knotPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(knotX, knotY), width: radiusX * 1.2, height: radiusY * 1.2), knotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WoodStrip {
  final Rect rect;
  final bool isHorizontal;

  _WoodStrip({required this.rect, required this.isHorizontal});
}

class CopperScratchesPainter extends CustomPainter {
  final bool isLight;
  final Color baseColor;

  CopperScratchesPainter({required this.isLight, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final Color highlightColor = Color.lerp(baseColor, Colors.white, 0.15)!;
    final Color shadowColor = Color.lerp(baseColor, Colors.black, 0.2)!;

    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          highlightColor,
          baseColor,
          shadowColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);

    final random = math.Random(isLight ? 7777 : 8888);
    final double w = size.width;
    final double h = size.height;

    final int microScratchCount = 40 + random.nextInt(20);
    final darkScratchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final lightScratchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final darkScratchColor = Color.lerp(baseColor, Colors.black, 0.45)!.withValues(alpha: 0.18);
    final lightScratchColor = Color.lerp(baseColor, Colors.white, 0.5)!.withValues(alpha: 0.25);

    for (int i = 0; i < microScratchCount; i++) {
      final double startX = random.nextDouble() * w;
      final double startY = random.nextDouble() * h;

      final double length = w * (0.15 + random.nextDouble() * 0.35);
      final double angle = (random.nextDouble() - 0.5) * 0.15;

      final double endX = startX + length;
      final double endY = startY + length * math.sin(angle);

      darkScratchPaint.color = darkScratchColor;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), darkScratchPaint);

      lightScratchPaint.color = lightScratchColor;
      canvas.drawLine(Offset(startX, startY + 0.6), Offset(endX, endY + 0.6), lightScratchPaint);
    }

    final int majorScratchCount = 3 + random.nextInt(4);
    for (int i = 0; i < majorScratchCount; i++) {
      final double startX = random.nextDouble() * w;
      final double startY = random.nextDouble() * h;
      final double endX = random.nextDouble() * w;
      final double endY = random.nextDouble() * h;

      final path = Path()..moveTo(startX, startY);

      final double midX = (startX + endX) / 2 + (random.nextDouble() - 0.5) * 8.0;
      final double midY = (startY + endY) / 2 + (random.nextDouble() - 0.5) * 8.0;
      path.quadraticBezierTo(midX, midY, endX, endY);

      final double strokeW = 0.6 + random.nextDouble() * 0.8;

      final majorDarkPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = Color.lerp(baseColor, Colors.black, 0.65)!.withValues(alpha: 0.22);
      canvas.drawPath(path, majorDarkPaint);

      final highlightPath = Path()..moveTo(startX + 0.8, startY + 0.8);
      highlightPath.quadraticBezierTo(midX + 0.8, midY + 0.8, endX + 0.8, endY + 0.8);

      final majorLightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = Color.lerp(baseColor, Colors.white, 0.6)!.withValues(alpha: 0.28);
      canvas.drawPath(highlightPath, majorLightPaint);
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    borderPaint.color = Colors.black.withValues(alpha: 0.15);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderPaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, borderPaint);

    borderPaint.color = Colors.white.withValues(alpha: 0.22);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, borderPaint);
    canvas.drawLine(rect.topLeft, rect.topRight, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
