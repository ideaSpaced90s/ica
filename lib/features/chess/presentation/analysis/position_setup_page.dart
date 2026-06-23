import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../application/chess_provider.dart';
import '../../application/study_lab_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import 'themes/analysis_classic_theme.dart';

class BoardEditorTab extends ConsumerStatefulWidget {
  final VoidCallback onApply;

  const BoardEditorTab({
    super.key,
    required this.onApply,
  });

  @override
  ConsumerState<BoardEditorTab> createState() => _BoardEditorTabState();
}

class _BoardEditorTabState extends ConsumerState<BoardEditorTab> {
  // Current board state for setup (represented as 8x8 map)
  final Map<String, String> _boardPieces = {};

  // Selected piece from palette (e.g. 'wP', 'wR', 'bP', 'bR', etc. or 'trash')
  String _selectedPaletteItem = 'wP';

  bool _isWhiteToMove = true;
  bool _wkCastling = true;
  bool _wqCastling = true;
  bool _bkCastling = true;
  bool _bqCastling = true;

  String _enPassant = '-';
  int _halfMoves = 0;
  final int _fullMoves = 1;

  @override
  void initState() {
    super.initState();
    final activeFen = ref.read(studyLabProvider).activeFen;
    _loadFenToBoardPieces(activeFen);
  }

  void _resetToDefaultPosition() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    final chess = chess_lib.Chess();
    _loadFenToBoardPieces(chess.fen);
  }

  void _clearBoard() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      _boardPieces.clear();
      _wkCastling = false;
      _wqCastling = false;
      _bkCastling = false;
      _bqCastling = false;
      _enPassant = '-';
      _halfMoves = 0;
    });
  }

  void _loadFenToBoardPieces(String fen) {
    final chess = chess_lib.Chess.fromFEN(fen);
    setState(() {
      _boardPieces.clear();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          final sq = _getSquareName(r, c);
          final piece = chess.get(sq);
          if (piece != null) {
            final side = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
            final code = '$side${piece.type.toString().toUpperCase()}';
            _boardPieces[sq] = code;
          }
        }
      }
      _isWhiteToMove = chess.turn == chess_lib.Color.WHITE;
      _wkCastling = chess.fen.contains('K');
      _wqCastling = chess.fen.contains('Q');
      _bkCastling = chess.fen.contains('k');
      _bqCastling = chess.fen.contains('q');
      
      final parts = fen.split(' ');
      if (parts.length >= 4) {
        _enPassant = parts[3];
      }
      if (parts.length >= 5) {
        _halfMoves = int.tryParse(parts[4]) ?? 0;
      }
    });
  }

  String _getSquareName(int row, int col) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];
    return '${files[col]}${ranks[row]}';
  }

  String _generateFen() {
    final buffer = StringBuffer();
    // 1. Board representation
    for (var r = 0; r < 8; r++) {
      var emptyCount = 0;
      for (var c = 0; c < 8; c++) {
        final sq = _getSquareName(r, c);
        final piece = _boardPieces[sq];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          final side = piece[0];
          final type = piece[1];
          buffer.write(side == 'w' ? type.toUpperCase() : type.toLowerCase());
        }
      }
      if (emptyCount > 0) {
        buffer.write(emptyCount);
      }
      if (r < 7) {
        buffer.write('/');
      }
    }

    // 2. Active color
    buffer.write(_isWhiteToMove ? ' w ' : ' b ');

    // 3. Castling rights
    var castlingStr = '';
    if (_wkCastling) castlingStr += 'K';
    if (_wqCastling) castlingStr += 'Q';
    if (_bkCastling) castlingStr += 'k';
    if (_bqCastling) castlingStr += 'q';
    buffer.write(castlingStr.isEmpty ? '-' : castlingStr);

    // 4. En passant
    buffer.write(' $_enPassant');

    // 5. Halfmove / Fullmove clock
    buffer.write(' $_halfMoves $_fullMoves');

    return buffer.toString();
  }

  void _handleSquareTap(String sq) {
    setState(() {
      final existing = _boardPieces[sq];
      if (_selectedPaletteItem == 'trash') {
        if (existing != null) {
          _boardPieces.remove(sq);
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.illegal);
          if (ref.read(chessProvider).isHapticsEnabled) {
            ref.read(chessHapticsServiceProvider).errorFeedback();
          }
        }
      } else {
        if (existing == _selectedPaletteItem) {
          _boardPieces.remove(sq); // Tap again to remove
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.illegal);
          if (ref.read(chessProvider).isHapticsEnabled) {
            ref.read(chessHapticsServiceProvider).errorFeedback();
          }
        } else {
          _boardPieces[sq] = _selectedPaletteItem;
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
          if (ref.read(chessProvider).isHapticsEnabled) {
            ref.read(chessHapticsServiceProvider).selection();
          }
        }
      }
    });
  }

  void _saveSetup() {
    final fen = _generateFen();
    final validation = chess_lib.Chess.validate_fen(fen);
    final isValid = validation['valid'] as bool;

    if (!isValid) {
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.illegal);
      if (ref.read(chessProvider).isHapticsEnabled) {
        ref.read(chessHapticsServiceProvider).errorFeedback();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid Board State: ${validation['error']}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
        ),
        title: Text(
          'Update Board State?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will clear all moves and custom variations in the analysis board. Do you want to proceed?',
          style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              Navigator.pop(context);
              ref.read(studyLabProvider.notifier).loadPositionSetup(fen);
              widget.onApply();
            },
            style: FilledButton.styleFrom(
              backgroundColor: ScholarlyTheme.accentBlue,
            ),
            child: Text(
              'Proceed',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiecePalette(WidgetRef ref) {
    const theme = AnalysisClassicTheme();

    final pieces = [
      'wK', 'wQ', 'wR', 'wB', 'wN', 'wP',
      'bK', 'bQ', 'bR', 'bB', 'bN', 'bP',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            'PIECE PALETTE',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
              color: ScholarlyTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
               ...pieces.map((p) {
                final isSelected = _selectedPaletteItem == p;
                final isWhite = p.startsWith('w');
                final type = p.substring(1);
                return GestureDetector(
                  onTap: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    setState(() => _selectedPaletteItem = p);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) : ScholarlyTheme.panelBase,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: theme.buildPiece(context, type, isWhite, false, 0),
                  ),
                );
              }),

              // Trash Eraser button
              GestureDetector(
                onTap: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  setState(() => _selectedPaletteItem = 'trash');
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedPaletteItem == 'trash' ? Colors.red.withValues(alpha: 0.15) : ScholarlyTheme.panelBase,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedPaletteItem == 'trash' ? Colors.redAccent : ScholarlyTheme.panelStroke,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: _selectedPaletteItem == 'trash' ? Colors.redAccent : ScholarlyTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChessboard(double boardSize, AnalysisClassicTheme theme) {
    final isMobile = MediaQuery.of(context).size.width <= 800;
    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
        boxShadow: isMobile ? null : ScholarlyTheme.boardShadow,
      ),
      child: Stack(
        children: [
          // Board theme background
          ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
            child: theme.buildBackground(context, true),
          ),
          // Grid of squares
          ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                final row = index ~/ 8;
                final col = index % 8;
                final isLight = (row + col) % 2 == 0;
                final sq = _getSquareName(row, col);
                final piece = _boardPieces[sq];

                return GestureDetector(
                  onTap: () => _handleSquareTap(sq),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLight ? theme.lightSquare : theme.darkSquare,
                    ),
                    child: Stack(
                      children: [
                        if (theme.getSquarePainter(isLight, 0) != null)
                          CustomPaint(
                            painter: theme.getSquarePainter(isLight, 0.0),
                            size: Size.infinite,
                          ),
                        if (piece != null)
                          Center(
                            child: theme.buildPiece(
                              context,
                              piece.substring(1),
                              piece.startsWith('w'),
                              false,
                              0,
                            ),
                          ),
                        // Coordinate label corner
                        Positioned(
                          top: 2,
                          left: 4,
                          child: Text(
                            sq,
                            style: GoogleFonts.inter(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: isLight 
                                  ? ScholarlyTheme.textMuted 
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SETTINGS',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
              color: ScholarlyTheme.textMuted,
            ),
          ),
          const Divider(color: ScholarlyTheme.panelStroke),
          
          // Side to Move Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Side to Move:',
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
              ),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('White'),
                    selected: _isWhiteToMove,
                    selectedColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                    onSelected: (val) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      setState(() => _isWhiteToMove = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Black'),
                    selected: !_isWhiteToMove,
                    selectedColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                    onSelected: (val) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      setState(() => _isWhiteToMove = false);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Castling Rights
          Text(
            'Castling Rights:',
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _wkCastling,
                    onChanged: (val) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                      setState(() => _wkCastling = val ?? false);
                    },
                  ),
                  Text('White Kingside (O-O)', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _wqCastling,
                    onChanged: (val) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                      setState(() => _wqCastling = val ?? false);
                    },
                  ),
                  Text('White Queenside (O-O-O)', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _bkCastling,
                    onChanged: (val) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                      setState(() => _bkCastling = val ?? false);
                    },
                  ),
                  Text('Black Kingside (o-o)', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _bqCastling,
                    onChanged: (val) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                      setState(() => _bqCastling = val ?? false);
                    },
                  ),
                  Text('Black Queenside (o-o-o)', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear Board', style: TextStyle(fontSize: 12)),
                onPressed: _clearBoard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScholarlyTheme.textMuted,
                  side: const BorderSide(color: ScholarlyTheme.panelStroke),
                ),
                icon: const Icon(Icons.settings_backup_restore, size: 16),
                label: const Text('Reset Start', style: TextStyle(fontSize: 12)),
                onPressed: _resetToDefaultPosition,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: ScholarlyTheme.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.check, size: 20),
          label: const Text(
            'Apply Setup to Board',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: _saveSetup,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const theme = AnalysisClassicTheme();

    // Compute board width
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth > 800
        ? (screenWidth > 500 ? 400.0 : screenWidth - 32).clamp(280.0, 480.0)
        : screenWidth; // Edge-to-edge for mobile viewports

    if (screenWidth > 800) {
      // Landscape: Board on the left (fixed), controls on the right (scrollable)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Chessboard
            SizedBox(
              width: boardSize,
              child: Center(
                child: _buildChessboard(boardSize, theme),
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Editing Tools (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPiecePalette(ref),
                    const SizedBox(height: 16),
                    _buildSettingsPanel(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Portrait: Board on top (fixed), controls below (scrollable)
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildChessboard(boardSize, theme),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    _buildPiecePalette(ref),
                    const SizedBox(height: 16),
                    _buildSettingsPanel(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 100), // Spacing for bottom navbar
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
