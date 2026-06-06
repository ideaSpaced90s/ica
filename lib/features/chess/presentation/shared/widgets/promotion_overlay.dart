import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../../application/chess_provider.dart';
import '../../scholarly_theme.dart';
import 'chess_piece_widget.dart';
import '../themes/chess_theme.dart';

/// Shared pawn-promotion ("Choose Ascension") overlay.
///
/// By default reads from [chessProvider] — suitable for Academy, Puzzles, and
/// the main Chess mode. For Arena and Battleground, pass the optional override
/// parameters so the overlay reflects that mode's own promotion state and
/// routes the selection callback to the correct notifier.
class PromotionOverlay extends ConsumerWidget {
  final ChessTheme? theme;

  /// Override: whether the promotion modal should be visible.
  /// If null, falls back to `chessProvider.isPromoting`.
  final bool? isPromotingOverride;

  /// Override: whether the promoting pawn is white.
  /// If null, falls back to `chessProvider.game.turn == WHITE`.
  final bool? isWhiteOverride;

  /// Override: called with the chosen promotion piece letter ('q','n','r','b').
  /// If null, calls `chessProvider.notifier.completePromotion`.
  final void Function(String piece)? onCompleteOverride;

  /// Override: called when the player taps the backdrop to cancel promotion.
  /// If null and no override is provided, backdrop tap is a no-op (original
  /// behaviour — chessProvider has no cancel path).
  final VoidCallback? onCancelOverride;

  const PromotionOverlay({
    super.key,
    this.theme,
    this.isPromotingOverride,
    this.isWhiteOverride,
    this.onCompleteOverride,
    this.onCancelOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve whether we are in promotion state.
    final isPromoting = isPromotingOverride ?? ref.watch(chessProvider).isPromoting;
    if (!isPromoting) return const SizedBox.shrink();

    // Resolve promoting side colour.
    final isWhite = isWhiteOverride ??
        (ref.watch(chessProvider).game.turn == chess_lib.Color.WHITE);
    final colorPrefix = isWhite ? 'w' : 'b';

    // Resolve callbacks.
    void handleComplete(String piece) {
      if (onCompleteOverride != null) {
        onCompleteOverride!(piece);
      } else {
        ref.read(chessProvider.notifier).completePromotion(piece);
      }
    }

    void handleCancel() {
      if (onCancelOverride != null) {
        onCancelOverride!();
      }
      // If no cancel override provided, backdrop is inert (default behaviour).
    }

    return Stack(
      children: [
        // ── Backdrop — blur + dim ─────────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: handleCancel,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.40)),
            ),
          ),
        ),

        // ── Selection Card ────────────────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: ScholarlyTheme.modernDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.backgroundStart,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CHOOSE ASCENSION',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Piece options row
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PromotionOption(
                        pieceCode: '${colorPrefix}Q',
                        theme: theme,
                        onSelected: () => handleComplete('q'),
                      ),
                      const SizedBox(width: 8),
                      _PromotionOption(
                        pieceCode: '${colorPrefix}N',
                        theme: theme,
                        onSelected: () => handleComplete('n'),
                      ),
                      const SizedBox(width: 8),
                      _PromotionOption(
                        pieceCode: '${colorPrefix}R',
                        theme: theme,
                        onSelected: () => handleComplete('r'),
                      ),
                      const SizedBox(width: 8),
                      _PromotionOption(
                        pieceCode: '${colorPrefix}B',
                        theme: theme,
                        onSelected: () => handleComplete('b'),
                      ),
                    ],
                  ),
                ),

                // Cancel hint (only shown when a cancel path exists)
                if (onCancelOverride != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: handleCancel,
                    child: Text(
                      'TAP OUTSIDE TO CANCEL',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotionOption extends StatefulWidget {
  final String pieceCode;
  final VoidCallback onSelected;
  final ChessTheme? theme;

  const _PromotionOption({
    required this.pieceCode,
    required this.onSelected,
    this.theme,
  });

  @override
  State<_PromotionOption> createState() => _PromotionOptionState();
}

class _PromotionOptionState extends State<_PromotionOption> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelected,
      // Touch-press feedback: track tap-down / tap-up for mobile
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 54,
          height: 54,
          decoration: ScholarlyTheme.modernDecoration().copyWith(
            color: _isPressed
                ? ScholarlyTheme.accentBlue.withValues(alpha: 0.25)
                : _isHovered
                    ? ScholarlyTheme.accentBlueSoft
                    : ScholarlyTheme.panelBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (_isPressed || _isHovered)
                  ? ScholarlyTheme.accentBlue
                  : ScholarlyTheme.panelStroke,
              width: _isPressed ? 2.0 : 1.0,
            ),
          ),
          transform: _isPressed
              ? Matrix4.diagonal3Values(0.92, 0.92, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: ChessPieceWidget(
            squareName: 'none',
            pieceCode: widget.pieceCode,
            theme: widget.theme,
          ),
        ),
      ),
    );
  }
}
