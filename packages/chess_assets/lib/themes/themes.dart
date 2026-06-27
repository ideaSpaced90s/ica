import 'package:flutter/material.dart';

class ChessTheme {
  final String name;
  final Color lightSquare;
  final Color darkSquare;
  final Color boardBorder;
  final Color activeHighlight;
  final Color whitePiecePrimary;
  final Color whitePieceSecondary;
  final Color blackPiecePrimary;
  final Color blackPieceSecondary;

  const ChessTheme({
    required this.name,
    required this.lightSquare,
    required this.darkSquare,
    required this.boardBorder,
    required this.activeHighlight,
    required this.whitePiecePrimary,
    required this.whitePieceSecondary,
    required this.blackPiecePrimary,
    required this.blackPieceSecondary,
  });
}

class ChessThemes {
  static const classicWood = ChessTheme(
    name: 'Wood',
    lightSquare: Color(0xFFE5C198), // Maple
    darkSquare: Color(0xFF8B4513),  // Mahogany
    boardBorder: Color(0xFF5C2E00),
    activeHighlight: Color(0x66FFFF00),
    whitePiecePrimary: Color(0xFFFFF0D4),
    whitePieceSecondary: Color(0xFF8B4513),
    blackPiecePrimary: Color(0xFF3B2415),
    blackPieceSecondary: Color(0xFF1A0F09),
  );


  static const retro8Bit = ChessTheme(
    name: 'Retro 8-Bit',
    lightSquare: Color(0xFFDCDCDC), // Low contrast cream
    darkSquare: Color(0xFF8FBC8F),  // Low contrast green
    boardBorder: Color(0xFF2F4F4F),
    activeHighlight: Color(0x66FFD700),
    whitePiecePrimary: Color(0xFFFFFFFF),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFF000000),
    blackPieceSecondary: Color(0xFFFFFFFF),
  );

  static const minimalistChalk = ChessTheme(
    name: 'Minimalist Chalk',
    lightSquare: Color(0xFFFAFAFA), // Matte white
    darkSquare: Color(0xFF36454F),  // Soft charcoal grey
    boardBorder: Color(0xFF000000),
    activeHighlight: Color(0x33000000),
    whitePiecePrimary: Color(0xFFFFFFFF),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFF36454F),
    blackPieceSecondary: Color(0xFFFAFAFA),
  );

  static const glassMorphic = ChessTheme(
    name: 'bnw',
    lightSquare: Color(0x88FFFFFF), // Translucent white
    darkSquare: Color(0x88000000),  // Translucent black
    boardBorder: Color(0x44FFFFFF),
    activeHighlight: Color(0x6600FFFF),
    whitePiecePrimary: Color(0xE6FFFFFF),
    whitePieceSecondary: Color(0x33000000),
    blackPiecePrimary: Color(0xE6000000),
    blackPieceSecondary: Color(0x33FFFFFF),
  );


  static const spacetimeVoid = ChessTheme(
    name: 'Spacetime Void',
    lightSquare: Color(0xFF101015), // Void black
    darkSquare: Color(0xFF05050A),  // Deep space
    boardBorder: Color(0xFFFFFFFF), // Starry matrix lines
    activeHighlight: Color(0x664B0082),
    whitePiecePrimary: Color(0xFFE6E6FA),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFF4B0082),
    blackPieceSecondary: Color(0xFFFFFFFF),
  );

  static const animalFriends = ChessTheme(
    name: 'Animal Friends',
    lightSquare: Color(0xFFE0F7FA), // Soft sky blue
    darkSquare: Color(0xFF81C784),  // Soft grass green
    boardBorder: Color(0xFF5D4037), // Soft wood brown
    activeHighlight: Color(0x66FFF176),
    whitePiecePrimary: Color(0xFFFFF9C4), // Soft cream yellow
    whitePieceSecondary: Color(0xFFF57C00), // Orange outline
    blackPiecePrimary: Color(0xFFFF7043), // Cute coral orange
    blackPieceSecondary: Color(0xFFFFF9C4), // Cream details
  );

  static const championshipClassic = ChessTheme(
    name: 'Champions',
    lightSquare: Color(0xFFFFFFE0), // Standard FIDE white
    darkSquare: Color(0xFF228B22),  // Standard FIDE green
    boardBorder: Color(0xFF006400),
    activeHighlight: Color(0x66FFFF00),
    whitePiecePrimary: Color(0xFFFFFFFF),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFF000000),
    blackPieceSecondary: Color(0xFFFFFFFF),
  );

  static const steampunk = ChessTheme(
    name: 'Steampunk',
    lightSquare: Color(0xFFB87333), // Burnished copper
    darkSquare: Color(0xFF8B8000),  // Brass
    boardBorder: Color(0xFF5C4033),
    activeHighlight: Color(0x66FFFFFF),
    whitePiecePrimary: Color(0xFFCD7F32),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFF3E2723),
    blackPieceSecondary: Color(0xFFCD7F32),
  );


  static const synthwave80s = ChessTheme(
    name: 'Synthwave 80s',
    lightSquare: Color(0xFFFF7E67), // Sunset gradient approx
    darkSquare: Color(0xFF2B00FF),  // Deep blue
    boardBorder: Color(0xFFFF00E5), // Hot pink
    activeHighlight: Color(0x6600FFFF),
    whitePiecePrimary: Color(0xFF00FFFF),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFFFF00E5),
    blackPieceSecondary: Color(0xFFFFFFFF),
  );


  static const monochromeSlate = ChessTheme(
    name: 'Monochrome Slate',
    lightSquare: Color(0xFFF5F5F5), // Stark white
    darkSquare: Color(0xFF0F0F0F),  // Pure onyx
    boardBorder: Color(0xFF808080),
    activeHighlight: Color(0x66808080),
    whitePiecePrimary: Color(0xFFFFFFFF),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFF000000),
    blackPieceSecondary: Color(0xFFFFFFFF),
  );

  static const underwaterAbyss = ChessTheme(
    name: 'Underwater Abyss',
    lightSquare: Color(0xFF000080), // Deep navy
    darkSquare: Color(0xFF000033),  // Abyss blue
    boardBorder: Color(0xFFFF7F50), // Coral highlights
    activeHighlight: Color(0x6600FFFF),
    whitePiecePrimary: Color(0xFF40E0D0),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFFFF7F50),
    blackPieceSecondary: Color(0xFF000000),
  );

  static const fairytaleCastle = ChessTheme(
    name: 'Castleworld',
    lightSquare: Color(0xFFE8E2D3), // Warm Ivory
    darkSquare: Color(0xFF1F1F1F),  // Deep Charcoal Black
    boardBorder: Color(0xFF121212), // Deep border frame
    activeHighlight: Color(0x88FFD700), // Glowing Gold highlight
    whitePiecePrimary: Color(0xFFFFD700), // Gold
    whitePieceSecondary: Color(0xFFFFFFFF), // White accents
    blackPiecePrimary: Color(0xFF000000), // Black
    blackPieceSecondary: Color(0xFFFFD700), // Gold accents
  );

  static const magmaVolcanic = ChessTheme(
    name: 'Magma / Volcanic',
    lightSquare: Color(0xFF2C2C2C), // Dark volcanic rock
    darkSquare: Color(0xFF1A1A1A),  // Darker rock
    boardBorder: Color(0xFFFF4500), // Glowing lava seams
    activeHighlight: Color(0x66FFA500),
    whitePiecePrimary: Color(0xFFFF4500),
    whitePieceSecondary: Color(0xFF000000),
    blackPiecePrimary: Color(0xFF8B0000),
    blackPieceSecondary: Color(0xFFFF4500),
  );

  static const List<ChessTheme> all = [
    classicWood,
    glassMorphic,
    championshipClassic,
    fairytaleCastle,
  ];
}
