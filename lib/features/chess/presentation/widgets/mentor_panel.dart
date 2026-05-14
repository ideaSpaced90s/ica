import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/tutorial_provider.dart';
import '../../domain/models/tutorial_lesson.dart';
import '../scholarly_theme.dart';

class TutorialMentorPanel extends ConsumerStatefulWidget {
  const TutorialMentorPanel({super.key});

  @override
  ConsumerState<TutorialMentorPanel> createState() => _TutorialMentorPanelState();
}

class _TutorialMentorPanelState extends ConsumerState<TutorialMentorPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  String _displayedText = '';
  String _targetText = '';
  int _charIndex = 0;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncText();
  }

  @override
  void didUpdateWidget(TutorialMentorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncText();
  }

  void _syncText() {
    final state = ref.watch(tutorialProvider);
    final nextText = state.lastMentorDialogue ?? state.currentStep.dialogue;
    if (nextText != _targetText) {
      _targetText = nextText;
      _startTypewriter();
    }
  }

  void _startTypewriter() {
    final skipAnim = ref.read(tutorialProvider).progress.settings.skipAnimations;
    if (skipAnim) {
      setState(() {
        _displayedText = _targetText;
        _isTyping = false;
      });
      return;
    }

    setState(() {
      _charIndex = 0;
      _displayedText = '';
      _isTyping = true;
    });

    _typeNextChar();
  }

  void _typeNextChar() {
    if (!mounted || !_isTyping) return;

    if (_charIndex < _targetText.length) {
      setState(() {
        _charIndex++;
        _displayedText = _targetText.substring(0, _charIndex);
      });
      // Accelerated pacing to maintain high engagement speed
      Future.delayed(const Duration(milliseconds: 16), _typeNextChar);
    } else {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _completeTypingInstantly() {
    setState(() {
      _isTyping = false;
      _displayedText = _targetText;
      _charIndex = _targetText.length;
    });
  }

  Color _getMoodColor(MentorMood mood) {
    switch (mood) {
      case MentorMood.calm:
        return ScholarlyTheme.accentBlue;
      case MentorMood.encouraging:
        return Colors.greenAccent;
      case MentorMood.correction:
        return Colors.orangeAccent;
      case MentorMood.celebration:
        return ScholarlyTheme.accentGold;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _isTyping = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);
    final notifier = ref.read(tutorialProvider.notifier);
    final moodColor = _getMoodColor(state.mentorMood);

    final showSubtitles = state.progress.settings.showSubtitles;
    if (!showSubtitles) {
      // If voice-only or compact preferences enabled, streamline profile layout
      return const SizedBox.shrink();
    }

    final isActionableStep = state.currentStep.type == TutorialStepType.dialogue ||
                             state.currentStep.type == TutorialStepType.demonstrate ||
                             state.currentStep.type == TutorialStepType.celebration;

    return Container(
      decoration: ScholarlyTheme.glassPanelDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header identity strip
          Row(
            children: [
              // Mood-pulsing portrait container
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: moodColor.withValues(alpha: 0.5 + (_glowController.value * 0.5)),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: moodColor.withValues(alpha: 0.2 + (_glowController.value * 0.3)),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage('assets/persona/gm_bard.png'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GM BARD',
                      style: GoogleFonts.inter(
                        color: moodColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.currentLesson.title,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Dialogue text canvas
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isTyping ? _completeTypingInstantly : null,
              child: SingleChildScrollView(
                child: Text(
                  _displayedText,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Actionable prompt indicator or manual instruction bar
          if (isActionableStep)
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed: _isTyping ? _completeTypingInstantly : () => notifier.advanceStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: moodColor.withValues(alpha: 0.2),
                  foregroundColor: moodColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: moodColor.withValues(alpha: 0.5)),
                ),
                icon: Icon(_isTyping ? Icons.fast_forward_rounded : Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  _isTyping ? 'Skip' : (state.currentStep.type == TutorialStepType.celebration ? 'Finish' : 'Next'),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            // Instructional guidance bar detailing awaited board targets
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: ScholarlyTheme.backgroundStart.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    state.currentStep.type == TutorialStepType.awaitMove
                        ? Icons.pan_tool_rounded // Dragging action
                        : Icons.touch_app_rounded, // Tapping action
                    size: 14,
                    color: ScholarlyTheme.accentYellow,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.currentStep.type == TutorialStepType.awaitMove
                          ? 'Make the requested move on the board'
                          : 'Tap the correct square on the board',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.accentYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
