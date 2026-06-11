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

    return AnimatedBuilder(
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
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(moodColor, state),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: isActionableStep ? 44 : 0, // leave space so text is not covered by floating button
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: _buildDialogue(moodColor),
                ),
              ),
              if (!isActionableStep) ...[
                const SizedBox(height: 6),
                _buildInstructionBar(moodColor, state),
              ],
            ],
          ),
          if (isActionableStep)
            Positioned(
              right: 0,
              bottom: 0,
              child: _buildActionButton(moodColor, state, notifier),
            ),
        ],
      ),
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
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isTyping ? _completeTypingInstantly : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
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
    final isAwaitMove = state.currentStep.type == TutorialStepType.awaitMove;
    final isCorrection = state.mentorMood == MentorMood.correction;
    final showTryAgain = isCorrection && isAwaitMove && !state.isAnimating;

    final label = state.isAnimating
        ? 'Processing move...'
        : showTryAgain
            ? 'Try Again ↑'
            : isAwaitMove
                ? 'Make your move on the board above.'
                : 'Tap the highlighted square.';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: moodColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: moodColor.withValues(alpha: 0.18), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(
            showTryAgain ? Icons.refresh_rounded : (isAwaitMove ? Icons.touch_app_outlined : Icons.radio_button_checked_rounded),
            size: 15,
            color: moodColor.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: showTryAgain
                ? AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.4 + (_glowController.value * 0.6),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            color: moodColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );
                    },
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      color: moodColor.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
