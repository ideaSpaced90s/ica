import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../data/saved_game.dart';
import '../scholarly_theme.dart';

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
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final shortId = widget.game.id.length >= 4
        ? widget.game.id.substring(0, 4)
        : widget.game.id;
    final title =
        (widget.game.customName != null && widget.game.customName!.isNotEmpty)
        ? widget.game.customName!
        : 'untitled$shortId';

    return Container(
      decoration: ScholarlyTheme.modernDecoration(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Mini Board Preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ScholarlyTheme.panelStroke),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: MiniBoardPreview(fen: widget.game.fen),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              color: ScholarlyTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onToggleFavorite,
                          child: Icon(
                            widget.game.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: widget.game.isFavorite
                                ? ScholarlyTheme.accentYellow
                                : ScholarlyTheme.textMuted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(widget.game.savedAt),
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _buildTimeBadge(
                            'W',
                            Duration(milliseconds: widget.game.whiteTimeLeftMs),
                          ),
                          const SizedBox(width: 8),
                          _buildTimeBadge(
                            'B',
                            Duration(milliseconds: widget.game.blackTimeLeftMs),
                          ),
                          const SizedBox(width: 8),
                          _buildModeBadge(widget.game.isRatedMode),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_rounded, size: 18),
                        color: ScholarlyTheme.accentBlue,
                        onPressed: widget.onExport,
                        tooltip: 'Export / Share',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        color: ScholarlyTheme.accentBlue,
                        onPressed: () => _showRenameDialog(context, title),
                        tooltip: 'Rename',
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
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
        color: isRated ? Colors.amber.withValues(alpha: 0.15) : ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRated ? Colors.amber : ScholarlyTheme.panelStroke,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRated ? Icons.emoji_events_rounded : Icons.spa_rounded,
            size: 10,
            color: isRated ? Colors.amber : ScholarlyTheme.textSubtle,
          ),
          const SizedBox(width: 4),
          Text(
            isRated ? 'RATED' : 'CASUAL',
            style: GoogleFonts.jetBrainsMono(
              color: isRated ? Colors.amber : ScholarlyTheme.textSubtle,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: Text('Rename Game'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter custom name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onRename(controller.text);
              Navigator.pop(context);
            },
            child: Text('Save'),
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
