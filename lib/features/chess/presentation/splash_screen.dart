import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../application/chess_provider.dart';
import '../application/tutorial_provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';
import 'mobile_navigation_shell.dart';
import 'sign_in_page.dart';
import 'widgets/notification_prompt_page.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoShimmerAnimation;
  late Animation<double> _shadowOpacityAnimation;
  late Animation<double> _shimmerOpacityAnimation;
  late Animation<double> _floatAnimation;
  double _loadingValue = 0;

  bool _hasTransitioned = false;
  late Future<void> _servicesInitFuture;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _logoShimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeInOut),
      ),
    );

    _shadowOpacityAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeIn),
      ),
    );

    _shimmerOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 25,
      ),
    ]).animate(_progressController);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 1. Start services initialization in parallel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(chessProvider.notifier);
        _servicesInitFuture = _initServices(notifier);
        _progressController.forward();
      }
    });

    // 2. Safety fallback: transition to next screen if loading hangs (8s timeout)
    _fallbackTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_hasTransitioned) {
        debugPrint('Splash loading fallback triggered due to timeout.');
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
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      if (!mounted) return;

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // Attempt silent login via Google on startup
        try {
          final authService = ref.read(authServiceProvider);
          final credential = await authService.signInWithGoogleSilently();
          if (credential != null) {
            user = credential.user;
          }
        } catch (e) {
          debugPrint('Silent Google sign-in failed: $e');
        }
      }

      final hasSession = user != null;

      if (hasSession) {
        // Trigger silent restore from Cloud Sync on startup (capped at 3 seconds)
        try {
          await ref
              .read(cloudSyncProvider.notifier)
              .restore()
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Startup Cloud Sync restore sync timed out or failed: $e');
        }
      }

      if (!mounted) return;

      // Build the real destination widget once (shared by both paths below).
      final Widget destination =
          hasSession ? const MobileNavigationShell() : const SignInPage();

      // Helper that pushes the real destination with the standard fade transition.
      void pushDestination([BuildContext? routeContext]) {
        final targetContext = routeContext ?? (mounted ? context : null);
        if (targetContext == null) return;
        Navigator.of(targetContext).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => destination,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }

      // Check whether the notification prompt should be shown before the main
      // app shell. This happens on Android only, on the very first launch
      // (before the user has ever been prompted).
      final repo = ref.read(tutorialProgressRepositoryProvider);
      final progress = await repo.loadProgress();
      final chessState = ref.read(chessProvider);
      final isGuest = user == null || user.isAnonymous;
      final hasCompletedChapter8 = progress.completedChapters.contains(8);
      final needsNotifPrompt = (isGuest ? !hasCompletedChapter8 : !repo.hasPromptedNotification()) &&
          !chessState.isNotificationsEnabled;

      if (needsNotifPrompt) {
        // Push the notification prompt as a standalone full-screen route.
        // It will call onDismissed() when the user taps either action,
        // which then pushes the real destination.
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NotificationPromptPage(onDismissed: pushDestination),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } else {
        pushDestination();
      }
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
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Solid white background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Centered static app icon and title
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 320,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Drop Shadow Settle & Float Sync (using ImageFiltered with light_knight.png)
                      AnimatedBuilder(
                        animation: Listenable.merge([_progressController, _floatController]),
                        builder: (context, child) {
                          final floatVal = _floatAnimation.value;
                          final baseOpacity = _shadowOpacityAnimation.value;
                          final baseScale = _logoScaleAnimation.value;

                          // Shadow becomes wider and softer when icon is higher (floatVal is negative)
                          final shadowScaleX = baseScale * (1.0 - (floatVal / 80.0));
                          final shadowScaleY = baseScale * (1.0 - (floatVal / 80.0)) * 0.18; // Flatten Y-scale
                          final shadowOpacity = baseOpacity * (1.0 + (floatVal / 40.0));

                          return Transform(
                            transform: Matrix4.translationValues(0.0, 120.0, 0.0) // Position directly below the knight
                              ..scaleByDouble(shadowScaleX, shadowScaleY, 1.0, 1.0),
                            alignment: Alignment.center,
                            child: Opacity(
                              opacity: shadowOpacity.clamp(0.0, 1.0),
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 3.0),
                                child: Image.asset(
                                  'assets/splash/light_knight.png',
                                  color: Colors.black.withValues(alpha: 0.18),
                                  fit: BoxFit.contain,
                                  width: 220,
                                  height: 220,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // 2. 2D Scale/Fade Entrance & Floating Logo Layer
                      AnimatedBuilder(
                        animation: Listenable.merge([_progressController, _floatController]),
                        builder: (context, child) {
                          final scaleVal = _logoScaleAnimation.value;
                          final opacityVal = _logoOpacityAnimation.value;
                          final shimmerVal = _logoShimmerAnimation.value;
                          final floatVal = _floatAnimation.value;
                          final shimmerOpacity = _shimmerOpacityAnimation.value;

                          return Opacity(
                            opacity: opacityVal,
                            child: Transform.translate(
                              offset: Offset(0, floatVal * scaleVal), // Float only relative to entrance scale
                              child: Transform.scale(
                                scale: scaleVal,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Base App Icon
                                    Image.asset(
                                      'assets/splash/light_knight.png',
                                      fit: BoxFit.contain,
                                      width: 220,
                                      height: 220,
                                    ),
                                    // Metallic Shine Sweep Overlay (Only visible when active to avoid central fade/glow)
                                    Opacity(
                                      opacity: shimmerOpacity,
                                      child: ShaderMask(
                                        blendMode: BlendMode.srcIn,
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            begin: Alignment(-1.5 + shimmerVal, -1.5 + shimmerVal),
                                            end: Alignment(1.5 + shimmerVal, 1.5 + shimmerVal),
                                            colors: [
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.65), // Narrow bright highlight
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                            stops: const [
                                              0.45,
                                              0.5,
                                              0.55,
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: Image.asset(
                                          'assets/splash/light_knight.png',
                                          fit: BoxFit.contain,
                                          width: 220,
                                          height: 220,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  'Chess Academy',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                _buildLoadingIndicator(),
              ],
            ),
          ),

          // 2. Footer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
            color: const Color(0xFFC3A555), // Premium gold text color
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
                color: const Color(0xFFC3A555), // Gold progress indicator
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC3A555).withValues(alpha: 0.35),
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
                  color: const Color(0xFF334155), // Dark slate fallback text
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

