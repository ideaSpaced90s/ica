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

  void _triggerTypewriter(String text) {
    if (text != _targetText) {
      _targetText = text;
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
        return const Color(0xFF059669);
      case MentorMood.correction:
        return const Color(0xFFD97706);
      case MentorMood.celebration:
        return ScholarlyTheme.realGold;
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

    // Reactive sync: detect dialogue changes and trigger typewriter after build
    final nextText = state.lastMentorDialogue ?? state.currentStep.dialogue;
    if (nextText != _targetText) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerTypewriter(nextText));
    }

    final moodColor = _getMoodColor(state.mentorMood);

    final showSubtitles = state.progress.settings.showSubtitles;
    if (!showSubtitles) {
      return const SizedBox.shrink();
    }

    final isActionableStep = state.currentStep.type == TutorialStepType.dialogue ||
                             state.currentStep.type == TutorialStepType.demonstrate ||
                             state.currentStep.type == TutorialStepType.celebration;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: ScholarlyTheme.modernDecoration().copyWith(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: moodColor.withValues(alpha: 0.20 + (_glowController.value * 0.12)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ScholarlyTheme.shadowColor.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(moodColor, state),
              _buildDialogue(moodColor),
            ],
          ),
        ),

        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: isActionableStep
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: _buildActionButton(moodColor, state, notifier),
                )
              : _buildInstructionBar(moodColor, state),
        ),
      ],
    );
  }

  Widget _buildHeader(Color moodColor, TutorialState state) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: moodColor.withValues(alpha: 0.35 + (_glowController.value * 0.25)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: moodColor.withValues(alpha: 0.12 + (_glowController.value * 0.12)),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/persona/gm_chanakya.png'),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'GM CHANAKYA',
                    style: GoogleFonts.inter(
                      color: moodColor,
                  fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: moodColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: moodColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                state.currentLesson.title,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDialogue(Color moodColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 50),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isTyping ? _completeTypingInstantly : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _displayedText,
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                  if (_isTyping)
                    TextSpan(
                      text: ' |',
                      style: GoogleFonts.inter(
                        color: moodColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(Color moodColor, TutorialState state, TutorialNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isTyping ? _completeTypingInstantly : () => notifier.advanceStep(),
        style: ElevatedButton.styleFrom(
          backgroundColor: moodColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(_isTyping ? Icons.fast_forward_rounded : Icons.arrow_forward_rounded, size: 16),
        label: Text(
          _isTyping ? 'Skip' : (state.currentStep.type == TutorialStepType.celebration ? 'Finish' : 'Next'),
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildInstructionBar(Color moodColor, TutorialState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      decoration: BoxDecoration(
        color: moodColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: moodColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            state.currentStep.type == TutorialStepType.awaitMove
                ? Icons.pan_tool_rounded
                : Icons.touch_app_rounded,
            size: 16,
            color: moodColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.isAnimating 
                ? 'Processing...' 
                : (state.currentStep.type == TutorialStepType.awaitMove
                    ? 'Action Required: Execute the move described above.'
                    : 'Target identification: Tap the correct square.'),
              style: GoogleFonts.inter(
                color: moodColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
