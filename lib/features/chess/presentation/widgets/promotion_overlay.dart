import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            padding: const EdgeInsets.all(4), // Win98 menu padding
            decoration: ScholarlyTheme.win98Decoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: ScholarlyTheme.accentGold, // Navy blue in Win98
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CHOOSE ASCENSION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tahoma',
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
        child: Container(
          width: 54,
          height: 54,
          decoration: ScholarlyTheme.win98Decoration(sunken: _isHovered),
          padding: const EdgeInsets.all(4),
          child: ChessPieceWidget(
            squareName: 'none', 
            pieceCode: widget.pieceCode,
          ),
        ),
      ),
    );
  }
}
