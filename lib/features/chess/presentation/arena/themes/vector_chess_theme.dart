import 'package:flutter/material.dart';
import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../shared/themes/chess_theme.dart';
import '../effects/walnut_piece_painter.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../shared/themes/animation_group.dart';
import '../effects/group_b_effects.dart';
import 'dart:math';


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
      return const Color(0xFF6B4527); // Darker rich walnut/rosewood color that contrasts with the mahogany outlines
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
  CustomPainter? getSquarePainter(bool isLight, double animationValue) => null;

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {

    if (id == 'vector_egyptian') {
      chess_lib.PieceType pType;
      switch (type.toUpperCase()) {
        case 'K':
          pType = chess_lib.PieceType.KING;
          break;
        case 'Q':
          pType = chess_lib.PieceType.QUEEN;
          break;
        case 'R':
          pType = chess_lib.PieceType.ROOK;
          break;
        case 'B':
          pType = chess_lib.PieceType.BISHOP;
          break;
        case 'N':
          pType = chess_lib.PieceType.KNIGHT;
          break;
        case 'P':
        default:
          pType = chess_lib.PieceType.PAWN;
          break;
      }
      return AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: WalnutPiecePainter(
            type: pType,
            isWhite: isWhite,
            isHighlighted: isHighlighted,
          ),
        ),
      );
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
    if (id == 'vector_egyptian') {
      return AnimationGroup.d;
    }
    return AnimationGroup.b; // e.g. vector_wood
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    if (animationGroup == AnimationGroup.a) {
      return DefaultSelectionRing(color: packageTheme.activeHighlight);
    } else if (id == 'vector_egyptian') {
      return DuneSelectionRing(color: packageTheme.activeHighlight);
    }
    return GroupBSelectionPulse(color: packageTheme.activeHighlight);
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    if (animationGroup == AnimationGroup.a) {
      return null;
    } else if (id == 'vector_egyptian') {
      return SandGrainCapture(position: position, onComplete: onComplete);
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

class DuneSelectionRing extends StatefulWidget {
  final Color color;
  const DuneSelectionRing({super.key, required this.color});

  @override
  State<DuneSelectionRing> createState() => _DuneSelectionRingState();
}

class _DuneSelectionRingState extends State<DuneSelectionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
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
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.color,
                    width: 2.5,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SandGrainCapture extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  const SandGrainCapture({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<SandGrainCapture> createState() => _SandGrainCaptureState();
}

class _SandGrainCaptureState extends State<SandGrainCapture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SandGrain> _grains = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final random = Random();
    for (int i = 0; i < 10; i++) {
      final angle = -pi / 6 - random.nextDouble() * 2 * pi / 3;
      final speed = 40.0 + random.nextDouble() * 50.0;
      final size = 1.5 + random.nextDouble() * 2.0;
      _grains.add(_SandGrain(
        angle: angle,
        speed: speed,
        size: size,
        color: random.nextBool()
            ? const Color(0xFFD2B48C)
            : const Color(0xFFEDC9AF),
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
      builder: (context, child) {
        return CustomPaint(
          painter: _SandGrainPainter(
            center: widget.position,
            progress: _controller.value,
            grains: _grains,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SandGrain {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _SandGrain({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _SandGrainPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final List<_SandGrain> grains;

  _SandGrainPainter({
    required this.center,
    required this.progress,
    required this.grains,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 1.0 - progress;

    for (final g in grains) {
      final x = center.dx + cos(g.angle) * g.speed * progress;
      final y = center.dy + sin(g.angle) * g.speed * progress + 120.0 * progress * progress;

      final paint = Paint()
        ..color = g.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), g.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SandGrainPainter oldDelegate) {
    return true;
  }
}

