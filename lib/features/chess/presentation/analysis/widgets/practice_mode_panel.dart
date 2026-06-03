import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../application/study_lab_provider.dart';
import '../../../application/practice_lab_provider.dart';
import '../../scholarly_theme.dart';
import '../analysis_board.dart';
import 'practice_lab_board.dart';

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

    final isGameOver = practiceState.isGameOver;
    if (isGameOver && !_wasGameOver) {
      _wasGameOver = true;
      _checkmateTimer?.cancel();
      _checkmateTimer = Timer(const Duration(seconds: 5), () {
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
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;
          final boardSize = (availableWidth - 36).clamp(100.0, 420.0);

          // Calculate total height needed. Total fixed is ~250px.
          final minNeededHeight = boardSize + 250;
          final useSpacers = availableHeight > minNeededHeight;

          Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              if (useSpacers) const Spacer(),

              // Opponent Header Row
              Row(
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
                ],
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
                                      'Checkmate',
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
              Row(
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
                ],
              ),

              if (useSpacers) const Spacer(),
              const SizedBox(height: 8),

              // Move List (always rendered with fixed height to prevent layout shifts)
              SizedBox(
                height: 36,
                child: practiceState.sanHistory.isNotEmpty
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: _buildMoveChips(practiceState.sanHistory),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),

              // Bottom control buttons
              Row(
                children: [
                  // Step Backward
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: ScholarlyTheme.textPrimary,
                    onPressed: (practiceState.moveHistory.isEmpty || practiceState.viewingMoveIndex == -1)
                        ? null
                        : () => ref.read(practiceLabProvider.notifier).stepBackward(),
                  ),
                  
                  // Step Forward
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: ScholarlyTheme.textPrimary,
                    onPressed: practiceState.viewingMoveIndex == null
                        ? null
                        : () => ref.read(practiceLabProvider.notifier).stepForward(),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Takeback / Undo
                  if (practiceState.viewingMoveIndex == null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ScholarlyTheme.panelBase,
                          foregroundColor: ScholarlyTheme.textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: ScholarlyTheme.panelStroke),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text('UNDO', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                        onPressed: practiceState.moveHistory.length < 2 || practiceState.isEngineThinking
                            ? null
                            : () => ref.read(practiceLabProvider.notifier).undo(),
                      ),
                    ),
                    
                  // If viewing history, show "LIVE GAME" button
                  if (practiceState.viewingMoveIndex != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                          foregroundColor: ScholarlyTheme.accentBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: ScholarlyTheme.accentBlue),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: Text('LIVE GAME', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                        onPressed: () => ref.read(practiceLabProvider.notifier).navigateToMove(null),
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Exit Game (replaces Resign)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                      label: Text('EXIT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () {
                        ref.read(practiceLabProvider.notifier).endSession(studyState.activeFen);
                      },
                    ),
                  ),
                ],
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
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;
          final boardSize = (availableWidth - 36).clamp(100.0, 420.0);

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
              Row(
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
              const SizedBox(height: 12),

              // Board Row (EvalBar + Board)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EvalBar(
                    evalScore: null,
                    isMate: false,
                    mateIn: null,
                    isEngineOn: false,
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
              const SizedBox(height: 16),

              // Play Side Selector Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPlayerWhite = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isPlayerWhite
                              ? ScholarlyTheme.accentBlue.withValues(alpha: 0.12)
                              : ScholarlyTheme.panelBase,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPlayerWhite ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.white,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'WHITE',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _isPlayerWhite ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPlayerWhite = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isPlayerWhite
                              ? ScholarlyTheme.accentBlue.withValues(alpha: 0.12)
                              : ScholarlyTheme.panelBase,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isPlayerWhite ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'BLACK',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: !_isPlayerWhite ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

              // Play Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      ScholarlyTheme.accentBlue,
                      Color(0xFF3B82F6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    'START SPARRING',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
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

class ThinkingDotsAnimation extends StatefulWidget {
  const ThinkingDotsAnimation({super.key});

  @override
  State<ThinkingDotsAnimation> createState() => _ThinkingDotsAnimationState();
}

class _ThinkingDotsAnimationState extends State<ThinkingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      width: 20,
      height: 20,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final row = index ~/ 3;
          final col = index % 3;
          final delay = (row + col) * 0.15;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = (_controller.value - delay) % 1.0;
              final double opacity = (math.sin(progress * 2 * math.pi) + 1.0) / 2.0;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScholarlyTheme.textPrimary.withValues(alpha: 0.15 + 0.85 * opacity),
                ),
              );
            },
          );
        },
      ),
    );
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
