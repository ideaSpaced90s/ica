import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/themes/chess_theme.dart';
import '../scholarly_theme.dart';
import '../../application/store_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';

class PreviewPiece {
  final String id;
  final String type;
  final bool isWhite;
  String square;

  PreviewPiece({
    required this.id,
    required this.type,
    required this.isWhite,
    required this.square,
  });
}

class ThemePreviewDialog extends ConsumerStatefulWidget {
  final ChessTheme theme;
  final bool isFree;
  final bool isOwned;
  final bool isSelected;
  final StoreNotifier storeNotifier;
  final dynamic chessNotifier;

  const ThemePreviewDialog({
    super.key,
    required this.theme,
    required this.isFree,
    required this.isOwned,
    required this.isSelected,
    required this.storeNotifier,
    required this.chessNotifier,
  });

  @override
  ConsumerState<ThemePreviewDialog> createState() => _ThemePreviewDialogState();
}

class _ThemePreviewDialogState extends ConsumerState<ThemePreviewDialog> {
  late List<PreviewPiece> _pieces;
  late Timer _animationTimer;
  int _currentMoveIndex = 0;
  String _logText = "";

  static const List<List<String>> _previewMoves = [
    ['e2', 'e4'],
    ['e7', 'e5'],
    ['g1', 'f3'],
    ['b8', 'c6'],
    ['f1', 'b5'],
  ];

  static const List<String> _moveLogs = [
    "",
    "1. e4",
    "1. e4 e5",
    "1. e4 e5  2. Nf3",
    "1. e4 e5  2. Nf3 Nc6",
    "1. e4 e5  2. Nf3 Nc6  3. Bb5",
  ];

  @override
  void initState() {
    super.initState();
    _pieces = _createInitialPieces();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (mounted) {
        _playNextMove();
      }
    });
  }

  @override
  void dispose() {
    _animationTimer.cancel();
    super.dispose();
  }

  List<PreviewPiece> _createInitialPieces() {
    final list = <PreviewPiece>[];
    
    // White Pieces
    list.add(PreviewPiece(id: 'wR1', type: 'R', isWhite: true, square: 'a1'));
    list.add(PreviewPiece(id: 'wN1', type: 'N', isWhite: true, square: 'b1'));
    list.add(PreviewPiece(id: 'wB1', type: 'B', isWhite: true, square: 'c1'));
    list.add(PreviewPiece(id: 'wQ',  type: 'Q', isWhite: true, square: 'd1'));
    list.add(PreviewPiece(id: 'wK',  type: 'K', isWhite: true, square: 'e1'));
    list.add(PreviewPiece(id: 'wB2', type: 'B', isWhite: true, square: 'f1'));
    list.add(PreviewPiece(id: 'wN2', type: 'N', isWhite: true, square: 'g1'));
    list.add(PreviewPiece(id: 'wR2', type: 'R', isWhite: true, square: 'h1'));
    for (int i = 0; i < 8; i++) {
      final file = String.fromCharCode(97 + i);
      list.add(PreviewPiece(id: 'wP$i', type: 'P', isWhite: true, square: '${file}2'));
    }

    // Black Pieces
    list.add(PreviewPiece(id: 'bR1', type: 'R', isWhite: false, square: 'a8'));
    list.add(PreviewPiece(id: 'bN1', type: 'N', isWhite: false, square: 'b8'));
    list.add(PreviewPiece(id: 'bB1', type: 'B', isWhite: false, square: 'c8'));
    list.add(PreviewPiece(id: 'bQ',  type: 'Q', isWhite: false, square: 'd8'));
    list.add(PreviewPiece(id: 'bK',  type: 'K', isWhite: false, square: 'e8'));
    list.add(PreviewPiece(id: 'bB2', type: 'B', isWhite: false, square: 'f8'));
    list.add(PreviewPiece(id: 'bN2', type: 'N', isWhite: false, square: 'g8'));
    list.add(PreviewPiece(id: 'bR2', type: 'R', isWhite: false, square: 'h8'));
    for (int i = 0; i < 8; i++) {
      final file = String.fromCharCode(97 + i);
      list.add(PreviewPiece(id: 'bP$i', type: 'P', isWhite: false, square: '${file}7'));
    }

    return list;
  }

  void _playNextMove() {
    if (_currentMoveIndex >= _previewMoves.length) {
      setState(() {
        _pieces = _createInitialPieces();
        _currentMoveIndex = 0;
        _logText = "";
      });
      return;
    }

    final move = _previewMoves[_currentMoveIndex];
    final from = move[0];
    final to = move[1];

    setState(() {
      _pieces.removeWhere((p) => p.square == to);

      final movingPieceIndex = _pieces.indexWhere((p) => p.square == from);
      if (movingPieceIndex != -1) {
        _pieces[movingPieceIndex].square = to;
      }

      _currentMoveIndex++;
      _logText = _moveLogs[_currentMoveIndex];
    });

    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.move);
  }

  Offset _getSquarePosition(String square, double squareSize) {
    final file = square.codeUnitAt(0) - 97;
    final rank = 8 - int.parse(square.substring(1));
    return Offset(file * squareSize, rank * squareSize);
  }

  void _confirmPurchase(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Confirm Purchase',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
          ),
          content: Text(
            'Would you like to buy the premium theme "${widget.theme.name}" for ₹49 (Simulated)? It will be unlocked permanently.',
            style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close confirm dialog
                Navigator.pop(context); // close preview dialog
                widget.storeNotifier.purchaseBoardTheme(widget.theme.id);
                widget.chessNotifier.setBoardTheme(widget.theme.id);
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚡ Purchased and applied ${widget.theme.name} theme!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Buy Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 750;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 40, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 760 : 400,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth.clamp(160.0, 280.0);
        final double squareSize = boardSize / 8;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(showCloseButton: true),
            const SizedBox(height: 20),
            Center(child: _buildChessboard(boardSize, squareSize)),
            const SizedBox(height: 16),
            _buildMoveLogsTicker(),
            const SizedBox(height: 24),
            _buildFooterActions(),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    const double boardSize = 380.0;
    const double squareSize = boardSize / 8;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Large Board & Move Ticker
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChessboard(boardSize, squareSize),
            const SizedBox(height: 16),
            SizedBox(
              width: boardSize,
              child: _buildMoveLogsTicker(),
            ),
          ],
        ),
        const SizedBox(width: 28),
        // Right Column: Title, Badge, Description, Spacer, Buttons
        Expanded(
          child: SizedBox(
            height: boardSize + 16 + 40, // Match the height of the left column (boardSize + spacing + ticker)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(showCloseButton: true),
                const SizedBox(height: 24),
                Expanded(
                  child: Text(
                    'Preview the stunning animations and premium styling of the "${widget.theme.name}" theme. Click "BUY" to unlock it forever, or "APPLY" if you already own it.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                ),
                _buildFooterActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool showCloseButton}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.theme.name,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isFree
                      ? Colors.green.withValues(alpha: 0.1)
                      : ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.isFree ? '🆓 FREE THEME' : '👑 PREMIUM THEME',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.isFree ? Colors.green.shade700 : ScholarlyTheme.accentBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showCloseButton)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: ScholarlyTheme.textMuted),
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              Navigator.pop(context);
            },
          ),
      ],
    );
  }

  Widget _buildChessboard(double boardSize, double squareSize) {
    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Squares Grid / Custom Painters
            if (widget.theme.boardImagePath != null)
              Positioned.fill(
                child: Image.asset(
                  widget.theme.boardImagePath!,
                  fit: BoxFit.cover,
                ),
              )
            else
              for (int r = 0; r < 8; r++)
                for (int c = 0; c < 8; c++)
                  Positioned(
                    left: c * squareSize,
                    top: r * squareSize,
                    width: squareSize,
                    height: squareSize,
                    child: Container(
                      color: (r + c) % 2 == 0
                          ? widget.theme.lightSquare
                          : widget.theme.darkSquare,
                      child: widget.theme.getSquarePainter((r + c) % 2 == 0, 0.0) != null
                          ? CustomPaint(
                              painter: widget.theme.getSquarePainter((r + c) % 2 == 0, 0.0),
                            )
                          : null,
                    ),
                  ),

            // Rank Coordinates (left edge)
            for (int r = 0; r < 8; r++)
              Positioned(
                left: 2,
                top: r * squareSize + 2,
                child: Text(
                  '${8 - r}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: r % 2 == 0
                        ? widget.theme.darkCoordinateColor
                        : widget.theme.lightCoordinateColor,
                  ),
                ),
              ),

            // File Coordinates (bottom edge)
            for (int c = 0; c < 8; c++)
              Positioned(
                left: (c + 1) * squareSize - 8,
                top: 8 * squareSize - 10,
                child: Text(
                  String.fromCharCode(97 + c),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: c % 2 == 0
                        ? widget.theme.lightCoordinateColor
                        : widget.theme.darkCoordinateColor,
                  ),
                ),
              ),

            // Pieces Layer (AnimatedPositioned)
            for (final piece in _pieces)
              (() {
                final pos = _getSquarePosition(piece.square, squareSize);
                return AnimatedPositioned(
                  key: ValueKey(piece.id),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  left: pos.dx,
                  top: pos.dy,
                  width: squareSize,
                  height: squareSize,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: widget.theme.buildPiece(
                      context,
                      piece.type,
                      piece.isWhite,
                      false,
                      0.0,
                    ),
                  ),
                );
              }()),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveLogsTicker() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _logText.isEmpty ? "Setting up board..." : _logText,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Dismiss',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              if (widget.isSelected) {
                // Already applied, do nothing
              } else if (widget.isOwned) {
                // Apply and close dialog
                widget.chessNotifier.setBoardTheme(widget.theme.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎨 Applied ${widget.theme.name} theme!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: ScholarlyTheme.accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                // Show purchase confirmation
                _confirmPurchase(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isSelected
                  ? Colors.grey.shade400
                  : (widget.isOwned ? ScholarlyTheme.accentBlue : Colors.amber.shade700),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              widget.isSelected ? 'APPLIED' : (widget.isOwned ? 'APPLY' : 'BUY ₹49'),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
