import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import 'ambient_flow_backdrop.dart';
import '../../application/chess_provider.dart';
import '../../application/onboarding_provider.dart';
import '../../services/chess_sound_service.dart';

class WelcomeGuidePage extends ConsumerStatefulWidget {
  const WelcomeGuidePage({super.key});

  @override
  ConsumerState<WelcomeGuidePage> createState() => _WelcomeGuidePageState();
}

class _WelcomeGuidePageState extends ConsumerState<WelcomeGuidePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  static const List<String> _introSteps = [
    'I am GM Chanakya. I have spent decades mastering every facet of this game: openings, endgames, and tactics no one sees coming.',
    'The secret is deliberate self-grind with stronger minds. My AI avatars recreate human-style weaknesses so you can learn to see patterns, pressure, and mistakes.',
    'They help expose your chess scotomas: the blind spots your mind skips over. Once you can see them, I can assign the right drills to correct them.',
    'Here, I will guide you through the Foundation chapters on basic chess moves and rules. You need to own every rule.',
    'Repeat the tutorials as many times as you need. Let us begin with the most basic training.',
  ];

  String _displayedText = '';
  int _stepIndex = 0;
  int _charIndex = 0;
  bool _isTyping = true;
  bool _introComplete = false;

  String get _introText => _introSteps[_stepIndex];
  bool get _isLastStep => _stepIndex == _introSteps.length - 1;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _typeText();
  }

  void _typeText() {
    if (!mounted || !_isTyping) return;
    if (_charIndex < _introText.length) {
      setState(() {
        _charIndex++;
        _displayedText = _introText.substring(0, _charIndex);
      });
      Future.delayed(const Duration(milliseconds: 14), _typeText);
    } else {
      setState(() {
        _isTyping = false;
        _introComplete = true;
      });
    }
  }

  void _skipTypewriter() {
    setState(() {
      _isTyping = false;
      _introComplete = true;
      _displayedText = _introText;
    });
  }

  void _nextStep() {
    if (!_introComplete) return;
    if (_isLastStep) {
      _beginTraining();
      return;
    }

    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
    setState(() {
      _stepIndex++;
      _charIndex = 0;
      _displayedText = '';
      _isTyping = true;
      _introComplete = false;
    });
    _typeText();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _isTyping = false;
    super.dispose();
  }

  void _beginTraining() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
    OnboardingService(ref).startGuidedTour(GuidedTutorialLevel.foundations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientFlowBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const Spacer(),
                  _buildChanakyaBubble(),
                  const SizedBox(height: 24),
                  IgnorePointer(
                    ignoring: !_introComplete,
                    child: _buildActions(),
                  ),
                  const Spacer(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChanakyaBubble() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: ScholarlyTheme.glassPanelDecoration(radius: 20).copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: ScholarlyTheme.accentBlue.withValues(
                alpha: 0.25 + 0.18 * _glowController.value,
              ),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/persona/gm_chanakya.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumGradientText(
                    'GM CHANAKYA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Supreme Chess Mentor',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isTyping ? _skipTypewriter : null,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.0,
                  child: Text(
                    _introText,
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ),
                Text(
                  _displayedText + (_isTyping ? ' |' : ''),
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_stepIndex + 1) / _introSteps.length,
                    minHeight: 4,
                    backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                    valueColor: const AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentBlue),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_stepIndex + 1}/${_introSteps.length}',
                style: GoogleFonts.jetBrainsMono(
                  color: ScholarlyTheme.textSubtle,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _isTyping ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              'Tap to read faster',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textSubtle,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _introComplete ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1.0 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(
                _isLastStep ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                size: 20,
              ),
              label: Text(
                _isLastStep ? 'Begin Training' : 'Continue',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Covers Foundations: 9 chapters',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
