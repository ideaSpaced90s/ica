import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/widgets/chess_piece_widget.dart';
import 'sprite_chess_theme.dart';

class ArcChessTheme extends SpriteChessTheme {
  const ArcChessTheme()
      : super(
          id: 'sprite_arc',
          name: 'Arc',
          individualPiecesFolder: 'assets/pieces/arc-webP',
          pieceExtension: 'webp',
          boardImagePath: 'assets/board/arc.png',
          lightSquare: const Color(0xFFE4DAC3), // Warm antique ivory
          darkSquare: const Color(0xFF1C343A),  // Deep teal
          frameColor: const Color(0xFFC3A555),  // Gold trim
        );

  // Per-piece blink speed multipliers against the 2-second animation cycle
  static const Map<String, double> _speeds = {
    'pawn': 1.4,
    'knight': 1.8,
    'bishop': 0.9,
    'rook': 0.7,
    'queen': 1.1,
    'king': 0.5,
  };

  // Fixed per-piece-type base phase offset to keep them out of sync
  static const Map<String, double> _typePhase = {
    'pawn': 0.00,
    'knight': 0.17,
    'bishop': 0.33,
    'rook': 0.51,
    'queen': 0.67,
    'king': 0.83,
  };

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    final colorStr = isWhite ? 'light' : 'dark';
    
    // Resolve piece type string
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

    final speed = _speeds[typeStr] ?? 1.0;
    final typeOff = _typePhase[typeStr] ?? 0.0;

    // Retrieve square name from parent context if possible to introduce positional phase offset
    double squareOff = 0.0;
    try {
      final widget = context.widget;
      if (widget is ChessPieceWidget) {
        final sq = widget.squareName;
        if (sq.length >= 2) {
          squareOff = ((sq.codeUnitAt(0) * 7 + sq.codeUnitAt(1) * 13) % 100) / 100.0;
        }
      }
    } catch (_) {}

    // Non-linear blink curve: sin(t)^8
    // T represents progress through the periodic pulse
    final t = (animationValue * speed + typeOff + squareOff) % 1.0;
    
    // sin^8 is narrow, keeping it in frame 0 (dark) for ~85% of time and spiking quickly
    final rawCurve = math.pow(math.sin(t * math.pi), 8).toDouble();

    // Map the curve value to webP animation frame indices (0, 1, 2)
    int frameIndex = 0;
    if (rawCurve >= 0.65) {
      frameIndex = 2; // Peak glow
    } else if (rawCurve >= 0.25) {
      frameIndex = 1; // Mid glow
    } else {
      frameIndex = 0; // Base/dim/off
    }

    final assetPath = '$individualPiecesFolder/${colorStr}_${typeStr}_$frameIndex.$pieceExtension';

    return AspectRatio(
      aspectRatio: 1.0,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
