import 'package:flutter/material.dart';
import 'chess_theme.dart';
import '../animations/piece_motion_profile.dart';

class ClassicTheme extends ChessTheme {
  const ClassicTheme() : super(id: 'classic', name: 'Classic');

  static const PieceMotionProfile classicPawn = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 320),
    moveCurve: Curves.easeOutCubic,
    verticalArcFactor: 0.0,
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.010,
    hasBreathingSelection: true,
    selectionBreathScale: 0.012,
    breathingPeriod: Duration(milliseconds: 1200),
    levitationHeight: 3.0,
    isInfantry: true,
  );

  static const PieceMotionProfile classicKnight = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 320),
    moveCurve: Curves.easeOutCubic,
    verticalArcFactor: 0.2,
    midRotationDeg: 2.5,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.0,
    hasBreathingSelection: true,
    selectionBreathScale: 0.015,
    breathingPeriod: Duration(milliseconds: 1100),
    levitationHeight: 4.0,
    isInfantry: false,
  );

  static const PieceMotionProfile classicBishop = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 280),
    moveCurve: Curves.easeOutCubic,
    verticalArcFactor: 0.0,
    midRotationDeg: 0.0,
    hasGhostTrail: true,
    isTeleport: false,
    landingCompression: 0.0,
    hasBreathingSelection: true,
    selectionBreathScale: 0.010,
    breathingPeriod: Duration(milliseconds: 1500),
    levitationHeight: 4.5,
    isInfantry: false,
  );

  static const PieceMotionProfile classicRook = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 300),
    moveCurve: Curves.easeOutCubic,
    verticalArcFactor: 0.0,
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.005,
    hasBreathingSelection: true,
    selectionBreathScale: 0.008,
    breathingPeriod: Duration(milliseconds: 1400),
    levitationHeight: 2.5,
    isInfantry: false,
  );

  static const PieceMotionProfile classicQueen = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 1600),
    moveCurve: Curves.linear,
    verticalArcFactor: 0.0,
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: true,
    landingCompression: 0.0,
    hasBreathingSelection: true,
    selectionBreathScale: 0.018,
    breathingPeriod: Duration(milliseconds: 1000),
    levitationHeight: 4.0,
    isInfantry: false,
  );

  static const PieceMotionProfile classicKing = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 350),
    moveCurve: Curves.easeOutCubic,
    verticalArcFactor: 0.02,
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.005,
    hasBreathingSelection: true,
    selectionBreathScale: 0.020,
    breathingPeriod: Duration(milliseconds: 1300),
    levitationHeight: 2.0,
    isInfantry: false,
  );

  @override
  PieceMotionProfile getPieceMotionProfile(String pieceCode) {
    final type = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    switch (type) {
      case 'K':
        return classicKing;
      case 'Q':
        return classicQueen;
      case 'R':
        return classicRook;
      case 'B':
        return classicBishop;
      case 'N':
        return classicKnight;
      case 'P':
        return classicPawn;
      default:
        return classicPawn;
    }
  }

  @override
  Color get lightSquare => const Color(0xFFE8D1B5);

  @override
  Color get darkSquare => const Color(0xFFB58863);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF8B4513);

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
            'assets/board/ideaspaceclassicchesssprite2.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
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
              : const Color(0xFF0D6EFD).withValues(alpha: 0.75),
          border: isEnemy
              ? Border.all(color: const Color(0xFF0D6EFD), width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const SizedBox.shrink();
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
