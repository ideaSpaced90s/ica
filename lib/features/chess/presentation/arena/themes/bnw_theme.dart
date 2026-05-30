import 'package:flutter/material.dart';
import 'vector_chess_theme.dart';
import '../../shared/animations/piece_motion_profile.dart';

class BnwChessTheme extends VectorChessTheme {
  const BnwChessTheme({
    required super.id,
    required super.name,
    required super.packageTheme,
  });

  static const PieceMotionProfile bnwPawn = PieceMotionProfile(
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

  static const PieceMotionProfile bnwKnight = PieceMotionProfile(
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

  static const PieceMotionProfile bnwBishop = PieceMotionProfile(
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

  static const PieceMotionProfile bnwRook = PieceMotionProfile(
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

  static const PieceMotionProfile bnwQueen = PieceMotionProfile(
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

  static const PieceMotionProfile bnwKing = PieceMotionProfile(
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
        return bnwKing;
      case 'Q':
        return bnwQueen;
      case 'R':
        return bnwRook;
      case 'B':
        return bnwBishop;
      case 'N':
        return bnwKnight;
      case 'P':
        return bnwPawn;
      default:
        return bnwPawn;
    }
  }
}
