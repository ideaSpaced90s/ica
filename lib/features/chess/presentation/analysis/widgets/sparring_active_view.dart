import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../application/practice_lab_provider.dart';
import '../../../application/study_lab_provider.dart';
import '../../../application/chess_provider.dart';
import '../../../services/chess_sound_service.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../analysis_board.dart';
import 'practice_lab_board.dart';
import 'practice_mode_panel.dart';

/// The full-screen sparring "live game" view shown once a session is active.
/// Contains:
///  - Bot (left) vs You (right) header row with thinking indicators
///  - Chess board with eval bar
///  - Navigation + Stop controls
///  - Move list
class SparringActiveView extends ConsumerWidget {
  final BoxConstraints constraints;

  const SparringActiveView({super.key, required this.constraints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practiceState = ref.watch(practiceLabProvider);
    final isLandscape = constraints.maxWidth > constraints.maxHeight;

    if (isLandscape) {
      return _LandscapeSparringActiveView(
        constraints: constraints,
        practiceState: practiceState,
      );
    }
    return _PortraitSparringActiveView(
      constraints: constraints,
      practiceState: practiceState,
    );
  }
}

// ─────────────────────────────────────────────────────
//  Portrait layout
// ─────────────────────────────────────────────────────
class _PortraitSparringActiveView extends ConsumerWidget {
  final BoxConstraints constraints;
  final PracticeLabState practiceState;

  const _PortraitSparringActiveView({
    required this.constraints,
    required this.practiceState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardSize = constraints.maxWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Combined header (Bot on left, You on right, opposite ends in same line) ──
        _CombinedSparringHeader(practiceState: practiceState),
        const SizedBox(height: 4),
        // ── Board ─────────────────────────────────────────────────
        _SparringBoardWithEval(
          practiceState: practiceState,
          maxWidth: boardSize,
        ),
        const SizedBox(height: 8),
        // ── Navigation controls ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: _SparringNavBar(practiceState: practiceState),
        ),
        // ── Move list ─────────────────────────────────────────────
        const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 12.0),
            child: _MoveListCard(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  Landscape layout
// ─────────────────────────────────────────────────────
class _LandscapeSparringActiveView extends ConsumerWidget {
  final BoxConstraints constraints;
  final PracticeLabState practiceState;

  const _LandscapeSparringActiveView({
    required this.constraints,
    required this.practiceState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardSize = math.min(
      constraints.maxWidth * 0.55,
      constraints.maxHeight - 110,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: Board column ────────────────────────────────
          Expanded(
            flex: 11,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SparringBoardWithEval(
                  practiceState: practiceState,
                  maxWidth: boardSize,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: boardSize,
                  child: _SparringNavBar(practiceState: practiceState),
                ),
              ],
            ),
          ),
          // ── Divider ──────────────────────────────────────────
          Container(
            width: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
          ),
          // ── Right: Info column ───────────────────────────────
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CombinedSparringHeader(practiceState: practiceState),
                const SizedBox(height: 8),
                const Expanded(child: _MoveListCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Board + Eval Bar
// ─────────────────────────────────────────────────────
class _SparringBoardWithEval extends StatelessWidget {
  final PracticeLabState practiceState;
  final double maxWidth;

  const _SparringBoardWithEval({
    required this.practiceState,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    const double evalBarWidth = 6.0;
    const double evalBarPadding = 4.0;
    final double actualBoardSize = maxWidth - evalBarWidth - evalBarPadding;
    final isMobile = MediaQuery.of(context).size.width <= 800;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvalBar(
            evalScore: practiceState.evalScore,
            isMate: practiceState.isMate,
            mateIn: practiceState.mateIn,
            isEngineOn: true,
            isFlipped: practiceState.isBoardFlipped,
            height: actualBoardSize,
            width: evalBarWidth,
          ),
          const SizedBox(width: evalBarPadding),
          Stack(
            alignment: Alignment.center,
            children: [
              PracticeLabBoard(boardSize: actualBoardSize),
              // Game-over overlay
              if (practiceState.isGameOver && practiceState.gameConclusion != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: isMobile
                        ? BorderRadius.zero
                        : BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              practiceState.gameConclusion!,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Combined Player / Bot header row
//  Bot on the left, player (You) on the right.
//  Thinking indicators show inside the row next to respective players.
// ─────────────────────────────────────────────────────
class _CombinedSparringHeader extends ConsumerWidget {
  final PracticeLabState practiceState;

  const _CombinedSparringHeader({required this.practiceState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWhiteToMove = !practiceState.fen.contains(' b ');
    final isBotTurn = isWhiteToMove != practiceState.isPlayerWhite;
    final isBotThinking = practiceState.isEngineThinking;
    final isPlayerThinking = !isBotTurn && !practiceState.isEngineThinking && !practiceState.isGameOver && practiceState.isSessionActive;

    final botTimerActive = !practiceState.isGameOver && isBotTurn;
    final youTimerActive = !practiceState.isGameOver && !isBotTurn;
    final botTime = practiceState.isPlayerWhite
        ? practiceState.blackTimeLeft
        : practiceState.whiteTimeLeft;
    final youTime = practiceState.isPlayerWhite
        ? practiceState.whiteTimeLeft
        : practiceState.blackTimeLeft;

    final botIsWhite = !practiceState.isPlayerWhite;
    final botColorDot = botIsWhite ? Colors.white : Colors.black;
    final youColorDot = practiceState.isPlayerWhite ? Colors.white : Colors.black;

    Widget botAvatar = CircleAvatar(
      radius: 14,
      backgroundColor: ScholarlyTheme.panelBase.withValues(alpha: 0.6),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 16,
        color: ScholarlyTheme.accentBlue,
      ),
    );
    botAvatar = ModernThinkingAvatar(
      isThinking: isBotThinking,
      child: botAvatar,
    );

    Widget youAvatar = CircleAvatar(
      radius: 14,
      backgroundColor: ScholarlyTheme.panelBase.withValues(alpha: 0.6),
      child: const Icon(
        Icons.person_outline,
        size: 16,
        color: ScholarlyTheme.textPrimary,
      ),
    );

    Widget buildColorDot(Color color) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: color == Colors.white ? Colors.grey.shade400 : Colors.transparent,
            width: 1,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // ── LEFT SIDE: BOT ──
          botAvatar,
          const SizedBox(width: 8),
          buildColorDot(botColorDot),
          const SizedBox(width: 6),
          Text(
            'Bot',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 12,
            child: isBotThinking
                ? const Center(child: WavingDotsIndicator())
                : const SizedBox.shrink(),
          ),
          if (practiceState.showTimer) ...[
            const SizedBox(width: 4),
            _TimerBadge(isActive: botTimerActive, timeLeft: botTime),
          ],

          const Spacer(),

          // ── RIGHT SIDE: YOU ──
          if (practiceState.showTimer) ...[
            _TimerBadge(isActive: youTimerActive, timeLeft: youTime),
            const SizedBox(width: 4),
          ],
          SizedBox(
            width: 36,
            height: 12,
            child: isPlayerThinking
                ? const Center(child: WavingDotsIndicator())
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Text(
            'You',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          buildColorDot(youColorDot),
          const SizedBox(width: 8),
          youAvatar,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Navigation + Stop control bar
// ─────────────────────────────────────────────────────
class _SparringNavBar extends ConsumerWidget {
  final PracticeLabState practiceState;

  const _SparringNavBar({required this.practiceState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(practiceLabProvider.notifier);
    final sound = ref.read(chessSoundServiceProvider);

    final canStepBack = practiceState.moveHistory.isNotEmpty &&
        (practiceState.viewingMoveIndex == null ||
            practiceState.viewingMoveIndex! > -1);
    final canStepForward = practiceState.viewingMoveIndex != null;
    final canGoToStart = practiceState.moveHistory.isNotEmpty &&
        practiceState.viewingMoveIndex != -1;
    final canGoToEnd = practiceState.viewingMoveIndex != null;
    final canUndo = practiceState.moveHistory.length >= 2 &&
        !practiceState.isEngineThinking &&
        practiceState.viewingMoveIndex == null;

    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadius: 12,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavBtn(
              tooltip: 'Go to Start',
              icon: Icons.first_page_rounded,
              enabled: canGoToStart,
              onTap: () {
                notifier.navigateToMove(-1);
                sound.playSfx(SoundEffect.uiNavigate);
              },
            ),
            const SizedBox(width: 4),
            _NavBtn(
              tooltip: 'Step Backward',
              icon: Icons.chevron_left_rounded,
              enabled: canStepBack,
              onTap: () {
                notifier.stepBackward();
                sound.playSfx(SoundEffect.uiNavigate);
              },
            ),
            const SizedBox(width: 4),
            _NavBtn(
              tooltip: 'Step Forward',
              icon: Icons.chevron_right_rounded,
              enabled: canStepForward,
              onTap: () {
                notifier.stepForward();
                sound.playSfx(SoundEffect.uiNavigate);
              },
            ),
            const SizedBox(width: 4),
            _NavBtn(
              tooltip: 'Go to End',
              icon: Icons.last_page_rounded,
              enabled: canGoToEnd,
              onTap: () {
                notifier.navigateToMove(null);
                sound.playSfx(SoundEffect.uiNavigate);
              },
            ),
            const SizedBox(width: 4),
            _NavBtn(
              tooltip: 'Undo',
              icon: Icons.undo_rounded,
              enabled: canUndo,
              onTap: () => notifier.undo(),
            ),
            const SizedBox(width: 8),
            // Stop Sparring
            _StopBtn(practiceState: practiceState),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: enabled
                ? const Color(0xFF29B6F6).withValues(alpha: 0.15)
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF29B6F6).withValues(alpha: 0.4)
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? const Color(0xFF29B6F6)
                : ScholarlyTheme.textMuted.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _StopBtn extends ConsumerWidget {
  final PracticeLabState practiceState;

  const _StopBtn({required this.practiceState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Stop Sparring',
      child: GestureDetector(
        onTap: () {
          final studyFen = ref.read(studyLabProvider).activeFen;
          ref.read(practiceLabProvider.notifier).endSession(studyFen);
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.redAccent.withValues(alpha: 0.15),
            border:
                Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.stop_circle_rounded,
            size: 20,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Move list card
// ─────────────────────────────────────────────────────
class _MoveListCard extends ConsumerWidget {
  const _MoveListCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practiceState = ref.watch(practiceLabProvider);
    final sanHistory = practiceState.sanHistory;
    final viewingIndex = practiceState.viewingMoveIndex;
    final notifier = ref.read(practiceLabProvider.notifier);

    return JuicyGlassCard(
      padding: const EdgeInsets.all(10),
      borderRadius: 16,
      child: sanHistory.isEmpty
          ? Center(
              child: Text(
                'No moves yet',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: (sanHistory.length / 2).ceil(),
              itemBuilder: (context, pairIndex) {
                final whiteIdx = pairIndex * 2;
                final blackIdx = whiteIdx + 1;
                final whiteMove =
                    whiteIdx < sanHistory.length ? sanHistory[whiteIdx] : null;
                final blackMove =
                    blackIdx < sanHistory.length ? sanHistory[blackIdx] : null;
                final moveNum = pairIndex + 1;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    children: [
                      // Move number
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$moveNum.',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // White move chip
                      if (whiteMove != null)
                        _MoveChip(
                          san: whiteMove,
                          moveIndex: whiteIdx,
                          isSelected: viewingIndex == whiteIdx,
                          isLive: viewingIndex == null && whiteIdx == sanHistory.length - 1,
                          onTap: () => notifier.navigateToMove(whiteIdx),
                        ),
                      const SizedBox(width: 4),
                      // Black move chip
                      if (blackMove != null)
                        _MoveChip(
                          san: blackMove,
                          moveIndex: blackIdx,
                          isSelected: viewingIndex == blackIdx,
                          isLive: viewingIndex == null && blackIdx == sanHistory.length - 1,
                          onTap: () => notifier.navigateToMove(blackIdx),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  final String san;
  final int moveIndex;
  final bool isSelected;
  final bool isLive;
  final VoidCallback onTap;

  const _MoveChip({
    required this.san,
    required this.moveIndex,
    required this.isSelected,
    required this.isLive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? ScholarlyTheme.accentBlue.withValues(alpha: 0.2)
              : (isLive
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.08)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? ScholarlyTheme.accentBlue.withValues(alpha: 0.7)
                : (isLive
                    ? ScholarlyTheme.accentBlue.withValues(alpha: 0.35)
                    : Colors.transparent),
          ),
        ),
        child: Text(
          san,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: isSelected || isLive ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? ScholarlyTheme.accentBlue
                : ScholarlyTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Timer badge
// ─────────────────────────────────────────────────────
class _TimerBadge extends StatelessWidget {
  final bool isActive;
  final Duration timeLeft;

  const _TimerBadge({required this.isActive, required this.timeLeft});

  String _fmt(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d < const Duration(minutes: 1)) {
      final tenths = ((d.inMilliseconds % 1000) ~/ 100).toString();
      return '$minutes:$seconds.$tenths';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.alarm_rounded,
            size: 12,
            color: isActive
                ? ScholarlyTheme.accentBlue
                : ScholarlyTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          _fmt(timeLeft),
          style: GoogleFonts.jetBrainsMono(
            color: isActive
                ? ScholarlyTheme.accentBlue
                : ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
