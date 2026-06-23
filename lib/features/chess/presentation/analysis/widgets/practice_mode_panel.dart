import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../application/study_lab_provider.dart';
import '../../../application/practice_lab_provider.dart';
import '../../../application/chess_provider.dart';
import '../../../services/chess_sound_service.dart';
import '../../scholarly_theme.dart';
import '../analysis_board.dart';
import 'practice_lab_board.dart';
import '../../widgets/neural_connectivity_mesh.dart';

class PracticeModePanel extends ConsumerStatefulWidget {
  const PracticeModePanel({super.key});

  @override
  ConsumerState<PracticeModePanel> createState() => _PracticeModePanelState();
}

class _PracticeModePanelState extends ConsumerState<PracticeModePanel> {
  bool _isPlayerWhite = true;
  double _difficultyStop = 3.0; // Defaults to Stop 3 (Club Player - Level 12)
  Timer? _checkmateTimer;
  bool _showCheckmateOverlay = false;
  bool _wasGameOver = false;

  @override
  void dispose() {
    _checkmateTimer?.cancel();
    super.dispose();
  }

  int _getSkillFromStop(double stop) {
    if (stop == 1) return 3;
    if (stop == 2) return 7;
    if (stop == 3) return 12;
    if (stop == 4) return 17;
    return 20;
  }

  String _getSkillNameFromStop(double stop) {
    if (stop == 1) return 'Beginner (Level 3)';
    if (stop == 2) return 'Casual (Level 7)';
    if (stop == 3) return 'Club Player (Level 12)';
    if (stop == 4) return 'Advanced (Level 17)';
    return 'Master (Level 20)';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((d.inMilliseconds % 1000) ~/ 100).toString();
    if (d < const Duration(minutes: 1)) {
      return '$minutes:$seconds.$tenths';
    }
    return '$minutes:$seconds';
  }

  Widget _buildClockStatusButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 42,
      height: 24,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive 
                ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) 
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive 
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.6) 
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(WidgetRef ref, PracticeLabState practiceState, Duration? base, Duration? inc, String label) {
    final bool isCustom = base == null || inc == null;
    bool isActive = false;
    
    if (practiceState.showTimer) {
      if (isCustom) {
        isActive = 
            !(practiceState.baseTimeDuration == const Duration(minutes: 1) && practiceState.incrementDuration == const Duration(seconds: 0)) &&
            !(practiceState.baseTimeDuration == const Duration(minutes: 3) && practiceState.incrementDuration == const Duration(seconds: 2)) &&
            !(practiceState.baseTimeDuration == const Duration(minutes: 5) && practiceState.incrementDuration == const Duration(seconds: 0)) &&
            !(practiceState.baseTimeDuration == const Duration(minutes: 10) && practiceState.incrementDuration == const Duration(seconds: 0)) &&
            !(practiceState.baseTimeDuration == const Duration(minutes: 15) && practiceState.incrementDuration == const Duration(seconds: 10)) &&
            !(practiceState.baseTimeDuration == const Duration(minutes: 30) && practiceState.incrementDuration == const Duration(seconds: 0));
      } else {
        isActive = practiceState.baseTimeDuration == base && practiceState.incrementDuration == inc;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: GestureDetector(
        onTap: () {
          if (isCustom) {
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
            ref.read(practiceLabProvider.notifier).toggleTimer(true);
          } else {
            ref.read(practiceLabProvider.notifier).setTimerPreset(base, inc);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive 
                ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) 
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive 
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.6) 
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              isCustom && isActive 
                  ? '${practiceState.baseTimeDuration.inMinutes}m${practiceState.incrementDuration.inSeconds > 0 ? "+${practiceState.incrementDuration.inSeconds}" : ""}'
                  : label,
              style: GoogleFonts.outfit(
                color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBadge({required bool isTimerActive, required Duration timeLeft}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.alarm_rounded,
          size: 12,
          color: isTimerActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(timeLeft),
          style: GoogleFonts.jetBrainsMono(
            color: isTimerActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSettingsCard(PracticeLabState practiceState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alarm_rounded,
                size: 16,
                color: ScholarlyTheme.accentBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'TIME CONTROL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              _buildClockStatusButton(
                label: 'ON',
                isActive: practiceState.showTimer,
                onTap: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ref.read(practiceLabProvider.notifier).toggleTimer(true);
                },
              ),
              const SizedBox(width: 4),
              _buildClockStatusButton(
                label: 'OFF',
                isActive: !practiceState.showTimer,
                onTap: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ref.read(practiceLabProvider.notifier).toggleTimer(false);
                },
              ),
            ],
          ),
          if (practiceState.showTimer) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PRESETS:',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: ScholarlyTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Active: ${practiceState.baseTimeDuration.inMinutes}m${practiceState.incrementDuration.inSeconds > 0 ? "+${practiceState.incrementDuration.inSeconds}" : ""}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: ScholarlyTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPresetChip(ref, practiceState, const Duration(minutes: 1), const Duration(seconds: 0), "1m"),
                  _buildPresetChip(ref, practiceState, const Duration(minutes: 3), const Duration(seconds: 2), "3+2"),
                  _buildPresetChip(ref, practiceState, const Duration(minutes: 5), const Duration(seconds: 0), "5m"),
                  _buildPresetChip(ref, practiceState, const Duration(minutes: 10), const Duration(seconds: 0), "10m"),
                  _buildPresetChip(ref, practiceState, const Duration(minutes: 15), const Duration(seconds: 10), "15+10"),
                  _buildPresetChip(ref, practiceState, const Duration(minutes: 30), const Duration(seconds: 0), "30m"),
                  _buildPresetChip(ref, practiceState, null, null, "Custom..."),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CUSTOM BASE TIME:',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: ScholarlyTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${practiceState.baseTimeDuration.inMinutes} min',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: ScholarlyTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: ScholarlyTheme.accentBlue,
                inactiveTrackColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
                thumbColor: ScholarlyTheme.accentBlue,
                overlayColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: practiceState.baseTimeDuration.inMinutes.toDouble().clamp(0.0, 60.0),
                min: 0,
                max: 60,
                divisions: 60,
                onChanged: (val) {
                  final newMin = val.round();
                  ref.read(practiceLabProvider.notifier).setCustomBaseTime(Duration(minutes: newMin));
                },
                onChangeEnd: (val) {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CUSTOM INCREMENT:',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: ScholarlyTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '+${practiceState.incrementDuration.inSeconds} sec',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: ScholarlyTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: ScholarlyTheme.accentBlue,
                inactiveTrackColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
                thumbColor: ScholarlyTheme.accentBlue,
                overlayColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: practiceState.incrementDuration.inSeconds.toDouble().clamp(0.0, 60.0),
                min: 0,
                max: 60,
                divisions: 60,
                onChanged: (val) {
                  final newInc = val.round();
                  ref.read(practiceLabProvider.notifier).setCustomIncrement(Duration(seconds: newInc));
                },
                onChangeEnd: (val) {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactSideButton({
    required String label,
    required bool isSelected,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? ScholarlyTheme.accentBlue.withValues(alpha: 0.12)
              : ScholarlyTheme.panelBase,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              color: iconColor,
              size: 14,
              shadows: iconColor == Colors.white
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                      )
                    ]
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartSparringButton(StudyLabState studyState) {
    return Center(
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              ScholarlyTheme.accentBlue,
              Color(0xFF3B82F6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 16),
          label: Text(
            'START SPARRING',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
          ),
          onPressed: () {
            final skill = _getSkillFromStop(_difficultyStop);
            ref.read(practiceLabProvider.notifier).startSession(
              studyState.activeFen,
              _isPlayerWhite,
              skill,
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildMoveChips(List<String> sanHistory) {
    final chips = <Widget>[];
    for (var i = 0; i < sanHistory.length; i += 2) {
      final moveNum = (i ~/ 2) + 1;
      final whiteMove = sanHistory[i];
      final blackMove = (i + 1 < sanHistory.length) ? sanHistory[i + 1] : '';
      final text = '$moveNum. $whiteMove${blackMove.isNotEmpty ? '  $blackMove' : ''}';
      chips.add(
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ScholarlyTheme.panelStroke),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
        ),
      );
    }
    return chips;
  }

  Widget _buildLandscapePlaySession(
    PracticeLabState practiceState,
    StudyLabState studyState,
    BoxConstraints constraints,
  ) {
    final boardSize = math.min(
      (constraints.maxWidth * 0.55) - 36,
      constraints.maxHeight - 24,
    ).clamp(100.0, 520.0);

    final isWhiteToMove = !practiceState.fen.contains(' b ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT COLUMN: Board Area
          Expanded(
            flex: 11,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: boardSize + 18,
                  child: Column(
                    children: [
                      // Opponent Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: Row(
                          children: [
                            ModernThinkingAvatar(
                              isThinking: practiceState.isEngineThinking,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: ScholarlyTheme.panelBase,
                                child: const Icon(Icons.smart_toy_outlined, size: 16, color: ScholarlyTheme.accentBlue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getSkillNameFromStop(_difficultyStop),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: ScholarlyTheme.textPrimary,
                              ),
                            ),
                            if (practiceState.isEngineThinking) ...[
                              const SizedBox(width: 12),
                              const WavingDotsIndicator(),
                            ],
                            const Spacer(),
                            if (practiceState.showTimer)
                              _buildTimerBadge(
                                isTimerActive: !practiceState.isGameOver && (isWhiteToMove != practiceState.isPlayerWhite),
                                timeLeft: practiceState.isPlayerWhite ? practiceState.blackTimeLeft : practiceState.whiteTimeLeft,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Board Row (EvalBar + Board)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EvalBar(
                            evalScore: practiceState.evalScore,
                            isMate: practiceState.isMate,
                            mateIn: practiceState.mateIn,
                            isEngineOn: true,
                            isFlipped: practiceState.isBoardFlipped,
                            height: boardSize,
                          ),
                          const SizedBox(width: 12),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              PracticeLabBoard(boardSize: boardSize),
                              if (practiceState.isGameOver && _showCheckmateOverlay)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              practiceState.gameConclusion ?? 'Game Over',
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
                      const SizedBox(height: 8),

                      // Player Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: ScholarlyTheme.panelBase,
                              child: const Icon(Icons.person_outline, size: 16, color: ScholarlyTheme.textPrimary),
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
                            const Spacer(),
                            if (practiceState.showTimer)
                              _buildTimerBadge(
                                isTimerActive: !practiceState.isGameOver && (isWhiteToMove == practiceState.isPlayerWhite),
                                timeLeft: practiceState.isPlayerWhite ? practiceState.whiteTimeLeft : practiceState.blackTimeLeft,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // SEPARATOR
          Container(
            width: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
          ),

          // RIGHT COLUMN: Sidebar / Controls
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Move List (takes remaining space)
                Expanded(
                  child: Center(
                    child: practiceState.sanHistory.isNotEmpty
                        ? ListView(
                            scrollDirection: Axis.vertical,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 8.0,
                                children: _buildMoveChips(practiceState.sanHistory),
                              ),
                            ],
                          )
                        : Text(
                            'No moves played yet.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ScholarlyTheme.textMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CompactActionButton(
                      tooltip: 'Step Backward',
                      activeColor: ScholarlyTheme.textPrimary,
                      onTap: (practiceState.moveHistory.isEmpty || practiceState.viewingMoveIndex == -1)
                          ? null
                          : () => ref.read(practiceLabProvider.notifier).stepBackward(),
                      child: const Icon(Icons.chevron_left_rounded),
                    ),
                    const SizedBox(width: 12),
                    _CompactActionButton(
                      tooltip: 'Step Forward',
                      activeColor: ScholarlyTheme.textPrimary,
                      onTap: practiceState.viewingMoveIndex == null
                          ? null
                          : () => ref.read(practiceLabProvider.notifier).stepForward(),
                      child: const Icon(Icons.chevron_right_rounded),
                    ),
                    const SizedBox(width: 12),
                    if (practiceState.viewingMoveIndex == null)
                      _CompactActionButton(
                        tooltip: 'Undo Move',
                        activeColor: ScholarlyTheme.textPrimary,
                        onTap: practiceState.moveHistory.length < 2 || practiceState.isEngineThinking
                            ? null
                            : () => ref.read(practiceLabProvider.notifier).undo(),
                        child: const Icon(Icons.undo_rounded),
                      )
                    else
                      _CompactActionButton(
                        tooltip: 'Live Game',
                        activeColor: ScholarlyTheme.accentBlue,
                        onTap: () => ref.read(practiceLabProvider.notifier).navigateToMove(null),
                        child: const Icon(Icons.play_arrow_rounded),
                      ),
                    const SizedBox(width: 12),
                    _CompactActionButton(
                      tooltip: 'Stop Sparring',
                      activeColor: Colors.redAccent,
                      onTap: () {
                        final studyState = ref.read(studyLabProvider);
                        ref.read(practiceLabProvider.notifier).endSession(studyState.activeFen);
                      },
                      child: const Icon(Icons.stop_circle_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLobby(
    StudyLabState studyState,
    PracticeLabState practiceState,
    BoxConstraints constraints,
  ) {
    final boardSize = math.min(
      (constraints.maxWidth * 0.55) - 36,
      constraints.maxHeight - 24,
    ).clamp(100.0, 520.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT COLUMN: Board Area
          Expanded(
            flex: 11,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Board Row (EvalBar + Board)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EvalBar(
                      evalScore: null,
                      isMate: false,
                      mateIn: null,
                      isEngineOn: true,
                      isFlipped: !_isPlayerWhite,
                      height: boardSize,
                    ),
                    const SizedBox(width: 12),
                    PracticeLabBoard(
                      boardSize: boardSize,
                      isFlippedOverride: !_isPlayerWhite,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // SEPARATOR
          Container(
            width: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
          ),

          // RIGHT COLUMN: Configuration Area
          Expanded(
            flex: 9,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play Side Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCompactSideButton(
                        label: 'WHITE',
                        isSelected: _isPlayerWhite,
                        iconColor: Colors.white,
                        onTap: () => setState(() => _isPlayerWhite = true),
                      ),
                      const SizedBox(width: 16),
                      _buildCompactSideButton(
                        label: 'BLACK',
                        isSelected: !_isPlayerWhite,
                        iconColor: Colors.black,
                        onTap: () => setState(() => _isPlayerWhite = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Difficulty Slider Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ENGINE DIFFICULTY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _getSkillNameFromStop(_difficultyStop).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: ScholarlyTheme.accentBlue,
                      inactiveTrackColor: ScholarlyTheme.panelStroke,
                      thumbColor: ScholarlyTheme.accentBlue,
                      overlayColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                      valueIndicatorColor: ScholarlyTheme.accentBlue,
                      showValueIndicator: ShowValueIndicator.onDrag,
                    ),
                    child: Slider(
                      value: _difficultyStop,
                      min: 1.0,
                      max: 5.0,
                      divisions: 4,
                      label: _getSkillNameFromStop(_difficultyStop),
                      onChanged: (val) {
                        setState(() => _difficultyStop = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimerSettingsCard(practiceState),
                  const SizedBox(height: 16),

                  // Play Button
                  _buildStartSparringButton(studyState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyLabProvider);
    final practiceState = ref.watch(practiceLabProvider);

    final isGameOver = practiceState.isGameOver;
    if (isGameOver && !_wasGameOver) {
      _wasGameOver = true;
      _checkmateTimer?.cancel();
      final isTimeout = practiceState.gameConclusion?.contains('time') ?? false;
      final delay = isTimeout ? const Duration(milliseconds: 500) : const Duration(seconds: 5);
      _checkmateTimer = Timer(delay, () {
        if (mounted) {
          setState(() {
            _showCheckmateOverlay = true;
          });
        }
      });
    } else if (!isGameOver && _wasGameOver) {
      _wasGameOver = false;
      _checkmateTimer?.cancel();
      _showCheckmateOverlay = false;
    }

    if (practiceState.isSessionActive) {
      // PLAY SESSION VIEW
      return LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          if (isLandscape) {
            return _buildLandscapePlaySession(practiceState, studyState, constraints);
          }

          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;

          // Edge-to-edge calculation
          const double evalBarWidth = 6.0;
          const double evalBarPadding = 4.0;
          final boardSize = availableWidth - evalBarWidth - evalBarPadding;

          // Calculate total height needed. Total fixed is ~250px.
          final minNeededHeight = boardSize + 250;
          final useSpacers = availableHeight > minNeededHeight;

          final isWhiteToMove = !practiceState.fen.contains(' b ');

          Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              if (useSpacers) const Spacer(),

              // Opponent Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    ModernThinkingAvatar(
                      isThinking: practiceState.isEngineThinking,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: ScholarlyTheme.panelBase,
                        child: const Icon(Icons.smart_toy_outlined, size: 16, color: ScholarlyTheme.accentBlue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getSkillNameFromStop(_difficultyStop),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                    if (practiceState.isEngineThinking) ...[
                      const SizedBox(width: 12),
                      const WavingDotsIndicator(),
                    ],
                    const Spacer(),
                    if (practiceState.showTimer)
                      _buildTimerBadge(
                        isTimerActive: !practiceState.isGameOver && (isWhiteToMove != practiceState.isPlayerWhite),
                        timeLeft: practiceState.isPlayerWhite ? practiceState.blackTimeLeft : practiceState.whiteTimeLeft,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Board Row (EvalBar + Board)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EvalBar(
                    evalScore: practiceState.evalScore,
                    isMate: practiceState.isMate,
                    mateIn: practiceState.mateIn,
                    isEngineOn: true,
                    isFlipped: practiceState.isBoardFlipped,
                    height: boardSize,
                    width: evalBarWidth,
                  ),
                  const SizedBox(width: evalBarPadding),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      PracticeLabBoard(boardSize: boardSize),
                      if (practiceState.isGameOver && _showCheckmateOverlay)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      practiceState.gameConclusion ?? 'Game Over',
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
              const SizedBox(height: 12),

              // Player Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: ScholarlyTheme.panelBase,
                      child: const Icon(Icons.person_outline, size: 16, color: ScholarlyTheme.textPrimary),
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
                    const Spacer(),
                    if (practiceState.showTimer)
                      _buildTimerBadge(
                        isTimerActive: !practiceState.isGameOver && (isWhiteToMove == practiceState.isPlayerWhite),
                        timeLeft: practiceState.isPlayerWhite ? practiceState.whiteTimeLeft : practiceState.blackTimeLeft,
                      ),
                  ],
                ),
              ),

              if (useSpacers) const Spacer(),
              const SizedBox(height: 8),

              // Move List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: SizedBox(
                  height: 36,
                  child: practiceState.sanHistory.isNotEmpty
                      ? ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: _buildMoveChips(practiceState.sanHistory),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),

              // Bottom control buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CompactActionButton(
                      tooltip: 'Step Backward',
                      activeColor: ScholarlyTheme.textPrimary,
                      onTap: (practiceState.moveHistory.isEmpty || practiceState.viewingMoveIndex == -1)
                          ? null
                          : () => ref.read(practiceLabProvider.notifier).stepBackward(),
                      child: const Icon(Icons.chevron_left_rounded),
                    ),
                    const SizedBox(width: 12),
                    _CompactActionButton(
                      tooltip: 'Step Forward',
                      activeColor: ScholarlyTheme.textPrimary,
                      onTap: practiceState.viewingMoveIndex == null
                          ? null
                          : () => ref.read(practiceLabProvider.notifier).stepForward(),
                      child: const Icon(Icons.chevron_right_rounded),
                    ),
                    const SizedBox(width: 12),
                    if (practiceState.viewingMoveIndex == null)
                      _CompactActionButton(
                        tooltip: 'Undo Move',
                        activeColor: ScholarlyTheme.textPrimary,
                        onTap: practiceState.moveHistory.length < 2 || practiceState.isEngineThinking
                            ? null
                            : () => ref.read(practiceLabProvider.notifier).undo(),
                        child: const Icon(Icons.undo_rounded),
                      )
                    else
                      _CompactActionButton(
                        tooltip: 'Live Game',
                        activeColor: ScholarlyTheme.accentBlue,
                        onTap: () => ref.read(practiceLabProvider.notifier).navigateToMove(null),
                        child: const Icon(Icons.play_arrow_rounded),
                      ),
                    const SizedBox(width: 12),
                    _CompactActionButton(
                      tooltip: 'Stop Sparring',
                      activeColor: Colors.redAccent,
                      onTap: () {
                        final studyState = ref.read(studyLabProvider);
                        ref.read(practiceLabProvider.notifier).endSession(studyState.activeFen);
                      },
                      child: const Icon(Icons.stop_circle_rounded),
                    ),
                  ],
                ),
              ),

              if (useSpacers) const Spacer(),
            ],
          );

          if (useSpacers) {
            return content;
          } else {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            );
          }
        },
      );
    } else {
      // LOBBY VIEW
      return LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          if (isLandscape) {
            return _buildLandscapeLobby(studyState, practiceState, constraints);
          }

          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;
          const double evalBarWidth = 6.0;
          const double evalBarPadding = 4.0;
          final boardSize = availableWidth - evalBarWidth - evalBarPadding;

          // Calculate total height needed. Total fixed is ~280px.
          final minNeededHeight = boardSize + 280;
          final useSpacers = availableHeight > minNeededHeight;

          Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              if (useSpacers) const Spacer(),

              // Opponent Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: ScholarlyTheme.panelBase,
                      child: const Icon(Icons.sports_esports_outlined, size: 16, color: ScholarlyTheme.accentBlue),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sparring Lobby',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Board Row (Board with eval bar in lobby to avoid layout shift)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EvalBar(
                    evalScore: null,
                    isMate: false,
                    mateIn: null,
                    isEngineOn: true,
                    isFlipped: !_isPlayerWhite,
                    height: boardSize,
                    width: evalBarWidth,
                  ),
                  const SizedBox(width: evalBarPadding),
                  PracticeLabBoard(
                    boardSize: boardSize,
                    isFlippedOverride: !_isPlayerWhite,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Play Side Selector Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactSideButton(
                      label: 'WHITE',
                      isSelected: _isPlayerWhite,
                      iconColor: Colors.white,
                      onTap: () => setState(() => _isPlayerWhite = true),
                    ),
                    const SizedBox(width: 16),
                    _buildCompactSideButton(
                      label: 'BLACK',
                      isSelected: !_isPlayerWhite,
                      iconColor: Colors.black,
                      onTap: () => setState(() => _isPlayerWhite = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Difficulty Slider Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENGINE DIFFICULTY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      _getSkillNameFromStop(_difficultyStop).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: ScholarlyTheme.accentBlue,
                    inactiveTrackColor: ScholarlyTheme.panelStroke,
                    thumbColor: ScholarlyTheme.accentBlue,
                    overlayColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                    valueIndicatorColor: ScholarlyTheme.accentBlue,
                    showValueIndicator: ShowValueIndicator.onDrag,
                  ),
                  child: Slider(
                    value: _difficultyStop,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: _getSkillNameFromStop(_difficultyStop),
                    onChanged: (val) {
                      setState(() => _difficultyStop = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTimerSettingsCard(practiceState),
              const SizedBox(height: 16),

              // Play Button
              _buildStartSparringButton(studyState),

              if (useSpacers) const Spacer(),
            ],
          );

          if (useSpacers) {
            return content;
          } else {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            );
          }
        },
      );
    }
  }
}

class ThinkingDotsAnimation extends StatelessWidget {
  const ThinkingDotsAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return const NeuralConnectivityMesh();
  }
}

class ModernThinkingAvatar extends StatefulWidget {
  final bool isThinking;
  final Widget child;

  const ModernThinkingAvatar({
    super.key,
    required this.isThinking,
    required this.child,
  });

  @override
  State<ModernThinkingAvatar> createState() => _ModernThinkingAvatarState();
}

class _ModernThinkingAvatarState extends State<ModernThinkingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isThinking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ModernThinkingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isThinking && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double pulse = widget.isThinking ? _controller.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isThinking
                ? [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3 + 0.3 * pulse),
                      blurRadius: 6 + 6 * pulse,
                      spreadRadius: 1 + 3 * pulse,
                    )
                  ]
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class WavingDotsIndicator extends StatefulWidget {
  const WavingDotsIndicator({super.key});

  @override
  State<WavingDotsIndicator> createState() => _WavingDotsIndicatorState();
}

class _WavingDotsIndicatorState extends State<WavingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final progress = (_controller.value - delay) % 1.0;
              final double offset = math.sin(progress * 2 * math.pi) * 3;
              return Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ScholarlyTheme.accentBlue,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;
  final Color activeColor;

  const _CompactActionButton({
    required this.child,
    required this.tooltip,
    this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    final Color color = isEnabled ? activeColor : ScholarlyTheme.textMuted.withValues(alpha: 0.35);
    final Color borderColor = isEnabled ? ScholarlyTheme.panelStroke.withValues(alpha: 0.5) : ScholarlyTheme.panelStroke.withValues(alpha: 0.2);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isEnabled ? Colors.black.withValues(alpha: 0.03) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  size: 20,
                  color: color,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
