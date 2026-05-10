import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../application/chess_provider.dart';
import '../scholarly_theme.dart';
import '../chess_piece_widget.dart';

class PromotionOverlay extends ConsumerWidget {
  const PromotionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chessState = ref.watch(chessProvider);
    if (!chessState.isPromoting) return const SizedBox.shrink();

    final isWhite = chessState.game.turn == chess_lib.Color.WHITE;
    final colorPrefix = isWhite ? 'w' : 'b';

    return Stack(
      children: [
        // Blurred Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Prevent taps from passing through
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5), // Subtle blur for Win98
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),

        // Selection Menu
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: ScholarlyTheme.modernDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Bar
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PromotionOption(
                        pieceCode: '${colorPrefix}Q',
                        onSelected: () => ref
                            .read(chessProvider.notifier)
                            .completePromotion('q'),
                      ),
                      const SizedBox(width: 8),
                      _PromotionOption(
                        pieceCode: '${colorPrefix}N',
                        onSelected: () => ref
                            .read(chessProvider.notifier)
                            .completePromotion('n'),
                      ),
                      const SizedBox(width: 8),
                      _PromotionOption(
                        pieceCode: '${colorPrefix}R',
                        onSelected: () => ref
                            .read(chessProvider.notifier)
                            .completePromotion('r'),
                      ),
                      const SizedBox(width: 8),
                      _PromotionOption(
                        pieceCode: '${colorPrefix}B',
                        onSelected: () => ref
                            .read(chessProvider.notifier)
                            .completePromotion('b'),
                      ),
                    ],
                  ),
                ),
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

  const _PromotionOption({
    required this.pieceCode,
    required this.onSelected,
  });

  @override
  State<_PromotionOption> createState() => _PromotionOptionState();
}

class _PromotionOptionState extends State<_PromotionOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelected,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 54,
          height: 54,
          decoration: ScholarlyTheme.modernDecoration().copyWith(
            color: _isHovered ? ScholarlyTheme.accentBlueSoft : ScholarlyTheme.panelBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: ChessPieceWidget(
            squareName: 'none', 
            pieceCode: widget.pieceCode,
          ),
        ),
      ),
    );
  }
}
