import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../application/chess_provider.dart';
import '../application/tutorial_provider.dart';
import 'mobile_navigation_shell.dart';
import 'sign_in_page.dart';
import 'scholarly_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<double> _lottieProgress;
  late AnimationController _shimmerController;
  double _loadingValue = 0;

  bool _hasTransitioned = false;
  late Future<void> _servicesInitFuture;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Fallback duration
    );

    final curvedAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressAnimation = Tween<double>(begin: 0, end: 100).animate(curvedAnimation)
      ..addListener(() {
        setState(() {
          _loadingValue = _progressAnimation.value;
        });
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _checkTransition();
        }
      });

    // Stop Lottie at 0.75 progress (frame 90, where the full icon builds and settles,
    // rather than continuing into the exit/erasure animation phase)
    _lottieProgress = Tween<double>(begin: 0.0, end: 0.75).animate(curvedAnimation);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 1. Start services initialization in parallel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(chessProvider.notifier);
        _servicesInitFuture = _initServices(notifier);
      }
    });

    // 2. Safety fallback: transition to next screen if loading hangs (8s timeout)
    _fallbackTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_hasTransitioned) {
        debugPrint('Splash Lottie: Fallback triggered due to timeout.');
        _progressController.duration = const Duration(milliseconds: 1000);
        _progressController.forward();
        _checkTransition();
      }
    });
  }

  void _checkTransition() {
    if (_hasTransitioned) return;

    if (_progressController.isCompleted) {
      _hasTransitioned = true;
      _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for the background services initialization to finish
    try {
      await _servicesInitFuture;
    } catch (e) {
      debugPrint('Service Init error in loading flow: $e');
    }

    if (mounted) {
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      if (isMobile) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      if (!mounted) return;

      final repo = ref.read(tutorialProgressRepositoryProvider);
      final isGoogleSignedIn = repo.getIsGoogleSignedIn();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => isGoogleSignedIn
              ? const MobileNavigationShell()
              : const SignInPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  Future<void> _initServices(ChessNotifier notifier) async {
    // Defer chess engine startup to when the user actually enters arena/battleground/analysis
    await Future.delayed(Duration.zero);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EA), // Cream off-white to match the Lottie background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Centered Lottie Splash Animation (stops at full icon build completion)
          Center(
            child: SizedBox(
              width: 320,
              height: 340,
              child: Lottie.asset(
                'assets/splash/splash_animation.json',
                controller: _lottieProgress,
                onLoaded: (composition) {
                  if (mounted && !_progressController.isAnimating && !_progressController.isCompleted) {
                    // Slow down the build build to 3.0 seconds (as requested by user)
                    _progressController.duration = const Duration(milliseconds: 3000);
                    _progressController.forward();
                  }
                },
              ),
            ),
          ),

          // 2. Overlays: Loading Bar & Footer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildLoadingIndicator(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_loadingValue.toInt()}%',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569), // Dark slate grey for readability
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 240,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0), // Light slate track
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _loadingValue / 100,
            child: Container(
              decoration: BoxDecoration(
                color: ScholarlyTheme.accentBlue,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  final barWidth = 240 * (_loadingValue / 100);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Stack(
                      children: [
                        const SizedBox.expand(),
                        // Shimmer sweep overlay
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.4,
                            child: Transform.translate(
                              offset: Offset(
                                barWidth * (_shimmerController.value * 2.5 - 1.25),
                                0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.45),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'powered by ',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B), // Slate grey
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            Image.asset(
              'assets/splash/ideaspace.png',
              height: 16,
              errorBuilder: (context, error, stackTrace) => Text(
                'ideaspace',
                style: GoogleFonts.inter(
                  color: const Color(0xFF334155), // Dark slate
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'v1.0.0',
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8), // Muted slate
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

