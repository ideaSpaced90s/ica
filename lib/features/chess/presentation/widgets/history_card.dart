import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../data/saved_game.dart';
import '../scholarly_theme.dart';
import 'ambient_scaffold.dart';

class HistoryCard extends StatefulWidget {
  final SavedGameEntry game;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final Function(String) onRename;
  final VoidCallback onExport;

  const HistoryCard({
    super.key,
    required this.game,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onRename,
    required this.onExport,
  });

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final shortId = widget.game.id.length >= 4
        ? widget.game.id.substring(0, 4)
        : widget.game.id;
    final String title;
    if (widget.game.isRatedMode) {
      title = (widget.game.customName != null && widget.game.customName!.isNotEmpty)
          ? widget.game.customName!
          : 'Rated Game $shortId';
    } else {
      title = (widget.game.customName != null &&
              widget.game.customName!.isNotEmpty &&
              widget.game.customName != 'Arena Game')
          ? widget.game.customName!
          : 'Unrated ID: ${widget.game.id}';
    }

    Color resultColor = ScholarlyTheme.panelStroke;
    if (widget.game.result == 'W') resultColor = const Color(0xFF10B981);
    if (widget.game.result == 'L') resultColor = const Color(0xFFEF4444);

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutBack,
      child: JuicyGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        backgroundColor: widget.game.isRatedMode
            ? ScholarlyTheme.realGold.withValues(alpha: 0.08)
            : const Color(0xFF0D9488).withValues(alpha: 0.08),
        borderColor: widget.game.isRatedMode
            ? ScholarlyTheme.realGold.withValues(alpha: 0.25)
            : const Color(0xFF0D9488).withValues(alpha: 0.25),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _scale = 0.98),
                onTapUp: (_) => setState(() => _scale = 1.0),
                onTapCancel: () => setState(() => _scale = 1.0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Mini Board Preview with colored border
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: resultColor.withValues(alpha: 0.65),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: resultColor.withValues(alpha: 0.12),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.8),
                          child: MiniBoardPreview(fen: widget.game.fen),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(widget.game.savedAt),
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildTimeBadge(
                                  'W',
                                  Duration(milliseconds: widget.game.whiteTimeLeftMs),
                                ),
                                _buildTimeBadge(
                                  'B',
                                  Duration(milliseconds: widget.game.blackTimeLeftMs),
                                ),
                                _buildModeBadge(widget.game.isRatedMode),
                                if (widget.game.result != null)
                                  _buildResultBadge(widget.game.result!),
                                if (widget.game.isLockedForAnalysis)
                                  _buildLockedBadge(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Only star button on the right side - completely outside the InkWell
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggleFavorite,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Icon(
                  widget.game.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: widget.game.isFavorite
                      ? ScholarlyTheme.accentYellow
                      : ScholarlyTheme.textMuted,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(String label, Duration duration) {
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ScholarlyTheme.panelStroke),
      ),
      child: Text(
        '$label: $mins:${secs.toString().padLeft(2, '0')}',
        style: GoogleFonts.jetBrainsMono(
          color: ScholarlyTheme.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildModeBadge(bool isRated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRated ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) : ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRated ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRated ? Icons.emoji_events_rounded : Icons.spa_rounded,
            size: 10,
            color: isRated ? ScholarlyTheme.accentBlue : ScholarlyTheme.textSubtle,
          ),
          const SizedBox(width: 4),
          Text(
            isRated ? 'RATED' : 'CASUAL',
            style: GoogleFonts.jetBrainsMono(
              color: isRated ? ScholarlyTheme.accentBlue : ScholarlyTheme.textSubtle,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBadge(String result) {
    Color color;
    String text;
    Color glowColor;
    switch (result) {
      case 'W':
        color = const Color(0xFF10B981); // Emerald
        glowColor = const Color(0xFF10B981).withValues(alpha: 0.25);
        text = 'Won W';
        break;
      case 'L':
        color = const Color(0xFFEF4444); // Rose
        glowColor = const Color(0xFFEF4444).withValues(alpha: 0.25);
        text = 'Lost L';
        break;
      case 'D':
      default:
        color = const Color(0xFF6B7280); // Slate
        glowColor = const Color(0xFF6B7280).withValues(alpha: 0.12);
        text = 'Draw D';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLockedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_rounded,
            size: 10,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 4),
          Text(
            'LOCKED',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class MiniBoardPreview extends StatelessWidget {
  final String fen;

  const MiniBoardPreview({super.key, required this.fen});

  @override
  Widget build(BuildContext context) {
    final chess = chess_lib.Chess.fromFEN(fen);
    return LayoutBuilder(
      builder: (context, constraints) {
        final squareSize = constraints.maxWidth / 8;
        return Column(
          children: List.generate(8, (rank) {
            return Row(
              children: List.generate(8, (file) {
                final isLight = (rank + file) % 2 == 0;
                final squareIndex = (7 - rank) * 8 + file;
                final piece = chess.get(
                  chess_lib.Chess.SQUARES.keys.elementAt(squareIndex),
                );

                return Container(
                  width: squareSize,
                  height: squareSize,
                  color: isLight
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  child: piece == null
                      ? null
                      : Center(
                          child: Text(
                            _getPieceSymbol(piece),
                            style: TextStyle(
                              fontSize: squareSize * 0.8,
                              color: piece.color == chess_lib.Color.WHITE
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                );
              }),
            );
          }),
        );
      },
    );
  }

  String _getPieceSymbol(chess_lib.Piece piece) {
    switch (piece.type) {
      case chess_lib.PieceType.PAWN:
        return '♟';
      case chess_lib.PieceType.KNIGHT:
        return '♞';
      case chess_lib.PieceType.BISHOP:
        return '♝';
      case chess_lib.PieceType.ROOK:
        return '♜';
      case chess_lib.PieceType.QUEEN:
        return '♛';
      case chess_lib.PieceType.KING:
        return '♚';
      default:
        return '';
    }
  }
}
