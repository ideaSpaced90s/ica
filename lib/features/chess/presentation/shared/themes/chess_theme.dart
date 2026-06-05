import 'package:flutter/material.dart';
import '../animations/piece_motion_profile.dart';
import '../animations/signature_move_style.dart';
import 'animation_group.dart';

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
  Widget buildSelectionRing(BuildContext context);

  // Last move highlight
  Widget buildLastMoveHighlight(BuildContext context, double opacity);

  // Animation/FX Capability flags
  bool get hasSFX => true;
  bool get hasSystemIndicators => true;

  // Which group this theme belongs to (drives animation tier logic)
  AnimationGroup get animationGroup => AnimationGroup.b;

  // Theme-specific capture particle effect. Groups B/C/D implement this.
  // Return null to suppress (Group A).
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) => null;

  // Continuous ambient overlay drawn behind pieces. Groups C/D only.
  // Return null for no ambient.
  Widget? buildAmbientOverlay(BuildContext context) => null;

  // Signature move style for this theme. Group C only.
  // null = standard glide (no signature layer).
  SignatureMoveStyle? get signatureMoveStyle => null;

  // Piece motion profile (affects animation styles).
  PieceMotionProfile getPieceMotionProfile(String pieceCode) {
    return PieceMotionProfile.forCode(pieceCode);
  }

  // Border radius for squares (if any)
  BorderRadius? get squareBorderRadius => null;

  // Border for squares (if any)
  Border? getSquareBorder(bool isSelected, bool isDragHover) => null;
}
