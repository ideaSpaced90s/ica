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
      'I am GM Chanakya. I have spent decades mastering every facet of this game — the openings, the endgames, the tactics no one sees coming.\n\nHere, I will guide you through the Foundations. Nine chapters. Every rule you need to own this board.\n\nAfter that, the remaining chapters are yours to conquer on your own terms. I will be watching.';
  int _charIndex = 0;
  bool _isTyping = true;
  bool _introComplete = false;

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

  void _skipGuide() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);

    ref.read(isOnboardingProvider.notifier).state = false;
    ref.read(showWelcomeDialogProvider.notifier).state = false;

    final repo = ref.read(tutorialProgressRepositoryProvider);
    if (repo.getIsGoogleSignedIn()) {
      unawaited(repo.setWelcomeGuideSeen(true));
    }

    ref.read(mobileNavIndexProvider.notifier).state = 0;
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
                  TextButton.icon(
                    onPressed: _skipGuide,
                    style: TextButton.styleFrom(
                      foregroundColor: ScholarlyTheme.textMuted,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'Skip Tutorial',
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
                // Invisible full text to reserve layout space and prevent container size jumps
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
                // Visible animated typing text
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
          const SizedBox(height: 10),
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
              onPressed: _beginTraining,
              style: ElevatedButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                'Begin Training',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Covers Foundations — 9 chapters',
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
