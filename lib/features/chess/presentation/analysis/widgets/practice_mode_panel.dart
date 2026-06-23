import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../application/study_lab_provider.dart';
import '../../../application/practice_lab_provider.dart';
import '../../../application/chess_provider.dart';
import '../../../services/chess_sound_service.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../../widgets/neural_connectivity_mesh.dart';

class PracticeModePanel extends ConsumerStatefulWidget {
  const PracticeModePanel({super.key});

  @override
  ConsumerState<PracticeModePanel> createState() => _PracticeModePanelState();
}

class _PracticeModePanelState extends ConsumerState<PracticeModePanel> {
  bool _isPlayerWhite = true;

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
      width: 38,
      height: 20,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: isActive 
                ? const LinearGradient(
                    colors: [
                      Color(0xFF0D6EFD),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive 
                ? null
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive 
                  ? const Color(0xFF0D6EFD).withValues(alpha: 0.8) 
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.2),
              width: 0.75,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : ScholarlyTheme.textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            gradient: isActive 
                ? const LinearGradient(
                    colors: [
                      Color(0xFF0D6EFD),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive 
                ? null 
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive 
                  ? const Color(0xFF0D6EFD).withValues(alpha: 0.8) 
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
              width: 0.75,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              isCustom && isActive 
                  ? '${practiceState.baseTimeDuration.inMinutes}m${practiceState.incrementDuration.inSeconds > 0 ? "+${practiceState.incrementDuration.inSeconds}" : ""}'
                  : label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : ScholarlyTheme.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
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
              height: 22,
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
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0D6EFD),
                    Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : ScholarlyTheme.panelStroke.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF0D6EFD).withValues(alpha: 0.8) 
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
            width: 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF0D6EFD).withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? Colors.white.withValues(alpha: 0.6) 
                      : (iconColor == Colors.white ? Colors.grey.shade400 : Colors.transparent),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.circle,
                color: iconColor,
                size: 10,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 9.5,
                color: isSelected ? Colors.white : ScholarlyTheme.textMuted,
                letterSpacing: 0.5,
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
        width: 150,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0D6EFD), // accentBlue
              Color(0xFF1E40AF), // Deep royal blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D6EFD).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 14),
          label: Text(
            'START SPARRING',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, 
              fontSize: 9.5, 
              letterSpacing: 0.8,
            ),
          ),
          onPressed: () {
            ref.read(practiceLabProvider.notifier).startSession(
              studyState.activeFen,
              _isPlayerWhite,
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

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyLabProvider);
    final practiceState = ref.watch(practiceLabProvider);

    if (practiceState.isSessionActive) {
      // PLAY SESSION VIEW CONTROLS (WITHOUT BOARD)
      final isWhiteToMove = !practiceState.fen.contains(' b ');

      return JuicyGlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Single Header Row (Bot vs You)
            Row(
              children: [
                // ── LEFT SIDE: BOT ──
                ModernThinkingAvatar(
                  isThinking: practiceState.isEngineThinking,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: ScholarlyTheme.panelBase,
                    child: const Icon(Icons.smart_toy_outlined, size: 16, color: ScholarlyTheme.accentBlue),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !practiceState.isPlayerWhite ? Colors.white : Colors.black,
                    border: Border.all(
                      color: !practiceState.isPlayerWhite ? Colors.grey.shade400 : Colors.transparent,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Bot',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  height: 12,
                  child: practiceState.isEngineThinking
                      ? const Center(child: WavingDotsIndicator())
                      : const SizedBox.shrink(),
                ),
                if (practiceState.showTimer) ...[
                  const SizedBox(width: 4),
                  _buildTimerBadge(
                    isTimerActive: !practiceState.isGameOver && (isWhiteToMove != practiceState.isPlayerWhite),
                    timeLeft: practiceState.isPlayerWhite ? practiceState.blackTimeLeft : practiceState.whiteTimeLeft,
                  ),
                ],

                const Spacer(),

                // ── RIGHT SIDE: YOU ──
                if (practiceState.showTimer) ...[
                  _buildTimerBadge(
                    isTimerActive: !practiceState.isGameOver && (isWhiteToMove == practiceState.isPlayerWhite),
                    timeLeft: practiceState.isPlayerWhite ? practiceState.whiteTimeLeft : practiceState.blackTimeLeft,
                  ),
                  const SizedBox(width: 4),
                ],
                SizedBox(
                  width: 36,
                  height: 12,
                  child: ((isWhiteToMove == practiceState.isPlayerWhite) && !practiceState.isEngineThinking && !practiceState.isGameOver && practiceState.isSessionActive)
                      ? const Center(child: WavingDotsIndicator())
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Text(
                  'You',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: practiceState.isPlayerWhite ? Colors.white : Colors.black,
                    border: Border.all(
                      color: practiceState.isPlayerWhite ? Colors.grey.shade400 : Colors.transparent,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: ScholarlyTheme.panelBase,
                  child: const Icon(Icons.person_outline, size: 16, color: ScholarlyTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Move List
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
          ],
        ),
      );
    } else {
      // LOBBY VIEW CONTROLS (WITHOUT BOARD)
      return JuicyGlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              _buildTimerSettingsCard(practiceState),
              const SizedBox(height: 16),
              // Play Button
              _buildStartSparringButton(studyState),
            ],
          ),
        ),
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

