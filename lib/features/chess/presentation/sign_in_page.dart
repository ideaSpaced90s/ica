import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'scholarly_theme.dart';
import 'widgets/ambient_flow_backdrop.dart';
import 'widgets/ambient_scaffold.dart';
import 'mobile_navigation_shell.dart';
import '../services/chess_sound_service.dart';
import '../application/chess_provider.dart';
import '../application/tutorial_provider.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeInController;
  late AnimationController _glowController;
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Connecting to Google Secure Gate...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    
    setState(() {
      _loadingMessage = 'Enrolling Strategist into the Academy...';
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final repo = ref.read(tutorialProgressRepositoryProvider);
    await repo.setIsGoogleSignedIn(true);

    _navigateToNext();
  }

  Future<void> _handleGuestSignIn() async {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Initializing Temporary Guest Session...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final repo = ref.read(tutorialProgressRepositoryProvider);
    await repo.setIsGoogleSignedIn(false);
    // Guest gets the onboarding every time they launch
    await repo.setWelcomeGuideSeen(false);

    _navigateToNext();
  }

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MobileNavigationShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7EF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Background Glow
          AmbientFlowBackdrop(
            backgroundColor: const Color(0xFFF7F7EF),
            blob1Color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
            blob2Color: const Color(0xFFFEE2E2).withValues(alpha: 0.4),
            blob3Color: const Color(0xFFF3E8FF).withValues(alpha: 0.45),
            overlayColor: Colors.white.withValues(alpha: 0.35),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: FadeTransition(
                  opacity: _fadeInController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Title
                      _buildLogoSection(),
                      const SizedBox(height: 36),

                      // Sign In Card
                      if (_isLoading)
                        _buildLoadingCard()
                      else
                        _buildOptionsCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue
                        .withValues(alpha: 0.1 + 0.1 * _glowController.value),
                    blurRadius: 25 + 10 * _glowController.value,
                    spreadRadius: 4 + 4 * _glowController.value,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Image.asset(
            'assets/splash/appicon.png',
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'THE ACADEMY',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reclaim human strategic mastery over the machines.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: ScholarlyTheme.textMuted,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    return JuicyGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      borderColor: Colors.white.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ENROLLMENT PORTAL',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.accentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Google Sign In Button
          ElevatedButton(
            onPressed: _handleGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ScholarlyTheme.textPrimary,
              elevation: 2,
              shadowColor: Colors.black12,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                  height: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sign In with Google',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Guest Sign In Button
          OutlinedButton(
            onPressed: _handleGuestSignIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: ScholarlyTheme.accentBlue,
              side: BorderSide(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.4),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Play as Guest',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '* Guest mode will reset and replay the Induction Guide on every startup.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textSubtle,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return JuicyGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 4.5,
              valueColor: AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentBlue),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _loadingMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Securing strategic parameters...',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
