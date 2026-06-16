import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../application/chess_provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';
import 'mobile_navigation_shell.dart';
import 'sign_in_page.dart';

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

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => hasSession
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
                  child: Image.asset(
                    'assets/splash/appicon.png',
                    fit: BoxFit.contain,
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

