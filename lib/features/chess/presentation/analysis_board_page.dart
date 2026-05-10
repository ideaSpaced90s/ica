import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'evaluation_bar.dart';
import 'widgets/board_stage.dart';
import 'widgets/ui_effects.dart';

class AnalysisBoardPage extends ConsumerStatefulWidget {
  const AnalysisBoardPage({super.key});

  @override
  ConsumerState<AnalysisBoardPage> createState() => _AnalysisBoardPageState();
}

class _AnalysisBoardPageState extends ConsumerState<AnalysisBoardPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ScholarlyTheme.backgroundGradient),
        child: Stack(
          children: [
            // Shared background effects
            Positioned(
              top: -80,
              left: -50,
              child: GlowOrb(
                size: 240,
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.14),
              ),
            ),
            _buildLayout(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, ChessState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        _buildTopEvaluationMarkers(state),
        const SizedBox(height: 4),
        Expanded(
          child: Column(
            children: [
              // Chessboard Stage with Vertical Eval Bar
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: BoardStage(),
                      ),
                      const SizedBox(width: 4),
                      EvaluationBar(
                        evaluation: state.currentEvaluation,
                        orientation: Axis.vertical,
                        isFlipped: state.isBoardFlipped,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Move List (PGN)
              Expanded(
                flex: 2,
                child: _buildMoveList(state),
              ),
            ],
          ),
        ),
        _buildBottomActionBar(state),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KINGSLAYER',
                style: GoogleFonts.silkscreen(
                  color: ScholarlyTheme.textPrimary.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                height: 2,
                width: 40,
                color: ScholarlyTheme.accentGold.withValues(alpha: 0.6),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'powered by ',
                style: TextStyle(
                  color: ScholarlyTheme.textMuted.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              Image.asset(
                'assets/splash/ideaspace.png',
                height: 16,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'ideaspace', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopEvaluationMarkers(ChessState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _evalMarker(state.currentEvaluation, true),
          const SizedBox(width: 12),
          _evalMarker(state.previousEvaluation, false),
        ],
      ),
    );
  }

  Widget _evalMarker(double eval, bool isMain) {
    final sign = eval >= 0 ? '+' : '';
    return Text(
      '$sign${eval.toStringAsFixed(1)}',
      style: GoogleFonts.shareTechMono(
        color: isMain ? ScholarlyTheme.textPrimary : ScholarlyTheme.textMuted,
        fontSize: isMain ? 14 : 12,
        fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMoveList(ChessState state) {
    final moves = state.recentMoves;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: (moves.length / 2).ceil(),
        itemBuilder: (context, index) {
          final moveIndex = index * 2;
          final whiteMove = moves[moveIndex];
          final blackMove = (moveIndex + 1 < moves.length) ? moves[moveIndex + 1] : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: ScholarlyTheme.textMuted, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: _MoveTile(
                    move: whiteMove, 
                    isSelected: state.viewingMoveIndex == moveIndex,
                    onTap: () => ref.read(chessProvider.notifier).jumpToMove(moveIndex),
                    eval: state.viewingMoveIndex == moveIndex ? state.currentEvaluation : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: blackMove != null 
                    ? _MoveTile(
                        move: blackMove, 
                        isSelected: state.viewingMoveIndex == moveIndex + 1,
                        onTap: () => ref.read(chessProvider.notifier).jumpToMove(moveIndex + 1),
                        eval: state.viewingMoveIndex == moveIndex + 1 ? state.currentEvaluation : null,
                      )
                    : const SizedBox(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar(ChessState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ScholarlyTheme.textPrimary, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: ScholarlyTheme.textPrimary),
            onPressed: () => _showAnalysisMenu(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ScholarlyTheme.panelBase.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.memory_rounded, color: ScholarlyTheme.accentBlue, size: 16),
                const SizedBox(width: 6),
                Text(
                  'SF 16',
                  style: GoogleFonts.shareTechMono(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page_rounded, color: ScholarlyTheme.textPrimary, size: 28),
                onPressed: () => ref.read(chessProvider.notifier).goToStart(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: ScholarlyTheme.textPrimary, size: 32),
                onPressed: () => ref.read(chessProvider.notifier).stepMove(-1),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: ScholarlyTheme.textPrimary, size: 32),
                onPressed: () => ref.read(chessProvider.notifier).stepMove(1),
              ),
              IconButton(
                icon: const Icon(Icons.last_page_rounded, color: ScholarlyTheme.textPrimary, size: 28),
                onPressed: () => ref.read(chessProvider.notifier).goToEnd(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnalysisMenu(BuildContext context) {
    final state = ref.watch(chessProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                state.isAnalysisMode ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                state.isAnalysisMode ? 'Stop engine' : 'Start engine',
                () {
                  ref.read(chessProvider.notifier).toggleEngine();
                  Navigator.pop(context);
                },
              ),
              _buildMenuItem(Icons.track_changes_rounded, 'Show threat', () {
                ref.read(chessProvider.notifier).showThreats();
                Navigator.pop(context);
              }),
              _buildMenuItem(Icons.flip_camera_android_rounded, 'Flip board', () {
                ref.read(chessProvider.notifier).toggleBoardOrientation();
                Navigator.pop(context);
              }),
              _buildMenuItem(Icons.warning_amber_rounded, 'Review white mistakes', () {}),
              _buildMenuItem(Icons.warning_amber_rounded, 'Review black mistakes', () {}),
              _buildMenuItem(Icons.edit_note_rounded, 'Board editor', () {}),
              _buildMenuItem(Icons.play_circle_outline_rounded, 'Continue from here', () {}),
              _buildMenuItem(Icons.ios_share_rounded, 'Share & export', () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ScholarlyTheme.accentGold, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: ScholarlyTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

class _MoveTile extends StatelessWidget {
  final String move;
  final bool isSelected;
  final VoidCallback onTap;
  final double? eval;

  const _MoveTile({
    required this.move, 
    required this.isSelected, 
    required this.onTap,
    this.eval,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? ScholarlyTheme.panelBase : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected 
            ? Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3))
            : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                move,
                style: TextStyle(
                  color: isSelected ? ScholarlyTheme.textPrimary : ScholarlyTheme.textPrimary.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (eval != null)
              Text(
                '${eval! >= 0 ? '+' : ''}${eval!.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
