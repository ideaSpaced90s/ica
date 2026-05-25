import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import 'ambient_flow_backdrop.dart';
import '../../application/chess_provider.dart';
import '../../application/onboarding_provider.dart';
import '../../application/tutorial_provider.dart';
import '../../presentation/mobile_navigation_shell.dart';
import '../../services/chess_sound_service.dart';


class WelcomeGuidePage extends ConsumerStatefulWidget {
  const WelcomeGuidePage({super.key});

  @override
  ConsumerState<WelcomeGuidePage> createState() => _WelcomeGuidePageState();
}

class _WelcomeGuidePageState extends ConsumerState<WelcomeGuidePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  String _displayedText = '';
  final String _introText =
      'Welcome to the Academy. I\'m GM Chanakya - I\'ll be coaching you through your chess training here.\n\nBefore we get started, tell me where you\'re at right now:';
  int _charIndex = 0;
  bool _isTyping = true;

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
      Future.delayed(const Duration(milliseconds: 15), _typeText);
    } else {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _skipTypewriter() {
    setState(() {
      _isTyping = false;
      _displayedText = _introText;
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _isTyping = false;
    super.dispose();
  }

  void _selectLevel(String level) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);

    final guidedLevel = switch (level) {
      'Intermediate' => GuidedTutorialLevel.intermediate,
      'Advanced' => GuidedTutorialLevel.advanced,
      _ => GuidedTutorialLevel.basic,
    };

    OnboardingService(ref).startGuidedTour(guidedLevel);
  }

  void _skipGuide() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);

    ref.read(isOnboardingProvider.notifier).state = false;
    ref.read(showWelcomeDialogProvider.notifier).state = false;

    // Mark as seen if Google user, else Guest gets it next time too
    final repo = ref.read(tutorialProgressRepositoryProvider);
    if (repo.getIsGoogleSignedIn()) {
      unawaited(repo.setWelcomeGuideSeen(true));
    }

    // Direct user to Dashboard (tab index 0)
    ref.read(mobileNavIndexProvider.notifier).state = 0;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Background Glow
          const AmbientFlowBackdrop(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const Spacer(),
                  // Chanakya bubble
                  _buildChanakyaBubble(),
                  const SizedBox(height: 24),
                  // Choices
                  _buildChoicesSection(),
                  const Spacer(),
                  // Centered Skip button at the bottom
                  TextButton.icon(
                    onPressed: _skipGuide,
                    style: TextButton.styleFrom(
                      foregroundColor: ScholarlyTheme.textMuted,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
            color: Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: ScholarlyTheme.accentBlue.withValues(
                alpha: 0.3 + 0.2 * _glowController.value,
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
                width: 44,
                height: 44,
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
                  Text(
                    'GM CHANAKYA',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.accentBlue,
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
            child: Text(
              _displayedText + (_isTyping ? ' |' : ''),
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildChoiceCard(
          index: 0,
          level: 'Basic',
          title: 'NEOPHYTE',
          desc: 'Start at Chapter 1 and build every rule from the board up.',
          accentColor: const Color(0xFF059669),
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          index: 1,
          level: 'Intermediate',
          title: 'TACTICIAN',
          desc: 'Start at Chapter 10 with check, mate, special rules, and tactics.',
          accentColor: ScholarlyTheme.accentBlue,
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          index: 2,
          level: 'Advanced',
          title: 'SCHOLAR',
          desc: 'Start at Chapter 24 for openings, mating technique, and endgames.',
          accentColor: const Color(0xFFD97706),
        ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required int index,
    required String level,
    required String title,
    required String desc,
    required Color accentColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 150),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1.0 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.white.withValues(alpha: 0.8),
            child: InkWell(
              onTap: () => _selectLevel(level),
              splashColor: accentColor.withValues(alpha: 0.15),
              highlightColor: accentColor.withValues(alpha: 0.05),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ScholarlyTheme.panelStroke.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: GoogleFonts.inter(
                              color: ScholarlyTheme.textPrimary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: accentColor.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
