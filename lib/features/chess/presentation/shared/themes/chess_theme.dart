import 'package:flutter/material.dart';
import '../animations/piece_motion_profile.dart';

abstract class ChessTheme {
  final String id;
  final String name;

  const ChessTheme({required this.id, required this.name});

  Color get lightSquare;
  Color get darkSquare;

  Color get lightCoordinateColor;
  Color get darkCoordinateColor;

  // Frame/Border color for the whole board
  Color get frameColor => Colors.transparent;

  // Custom board image path if any
  String? get boardImagePath => null;

  // Background effects/overlays
  Widget buildBackground(BuildContext context, bool animationsEnabled);

  // Check state effects
  Widget buildCheckEffect(BuildContext context);

  // Individual square decoration/painter
  CustomPainter? getSquarePainter(bool isLight, double animationValue);

  // Piece rendering
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  );

  // Move hint rendering (legal moves)
  Widget buildMoveHint(BuildContext context, bool isEnemy);

  // Selection indicator (the ring/effect around the selected square)
  Widget buildSelectionEffect(BuildContext context, double animationValue);

  // Last move highlight
  Widget buildLastMoveHighlight(BuildContext context, double opacity);

  // Animation/FX Capability flags
  bool get hasInteractionFeedback => true;
  bool get hasSystemIndicators => true;
  bool get hasSFX => true;
  bool get isInstantMovements => false;

  // Standard/flat glide motion profile for non-signature themes
  static const PieceMotionProfile standardPieceMotionProfile = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 300),
    moveCurve: Curves.easeOutCubic,
    verticalArcFactor: 0.0,
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.0,
    hasBreathingSelection: false,
    selectionBreathScale: 0.0,
    breathingPeriod: Duration(milliseconds: 1000),
    levitationHeight: 0.0,
    isInfantry: false,
  );

  // Piece motion profile (affects animation styles).
  // Standard themes return the flat glide standardPieceMotionProfile.
  PieceMotionProfile getPieceMotionProfile(String pieceCode) {
    return standardPieceMotionProfile;
  }

  // Border radius for squares (if any)
  BorderRadius? get squareBorderRadius => null;

  // Border for squares (if any)
  Border? getSquareBorder(bool isSelected, bool isDragHover) => null;
}
