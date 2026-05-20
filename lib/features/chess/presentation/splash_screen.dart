import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'dashboard_page.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_flow_backdrop.dart';

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
  late AnimationController _pulseController;
  double _loadingValue = 0;

  @override
  void initState() {
    super.initState();
    // Enforce Portrait for the Splash Screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Nominal duration
    );

    _progressAnimation =
        Tween<double>(begin: 0, end: 100).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeInOutCubic,
          ),
        )..addListener(() {
          setState(() {
            _loadingValue = _progressAnimation.value;
          });
        });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _initFlow();
  }

  Future<void> _initFlow() async {
    await Future.delayed(Duration.zero);
    final startTime = DateTime.now();
    // debugPrint('SplashScreen: Starting _initFlow...');
    final notifier = ref.read(chessProvider.notifier);

    // 1. Start services initialization in parallel
    // debugPrint('SplashScreen: Triggering background service init...');
    final initFuture = _initServices(notifier);

    // 2. Start a smooth progress animation
    _progressController.forward();

    // 3. Wait for actual services to load
    // debugPrint('SplashScreen: Waiting for background services...');
    await initFuture;
    // debugPrint('SplashScreen: Background services completed.');

    // 4. Enforce a small minimum time (e.g. 1.2s) for branding
    final elapsed = DateTime.now().difference(startTime);
    const minTime = Duration(milliseconds: 1200);
    if (elapsed < minTime) {
      await Future.delayed(minTime - elapsed);
    }

    // 5. Complete the progress bar quickly if not already done
    if (_progressController.value < 1.0) {
      await _progressController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    if (mounted) {
      // Keep Main App portrait locked
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      if (!mounted) return;

      // debugPrint('SplashScreen: Navigating to MainPage.');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  Future<void> _initServices(ChessNotifier notifier) async {
    try {
      await notifier.ensureGameServicesStarted();
    } catch (e) {
      debugPrint('Service Init error: $e');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Dark Navy for immersive icon blending
      body: _buildStaticPhase(),
    );
  }

  Widget _buildStaticPhase() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ambient animated background glow
        AmbientFlowBackdrop(
          backgroundColor: const Color(0xFF0F172A),
          blob1Color: const Color(0xFF1E3A8A).withValues(alpha: 0.15), // Deep navy
          blob2Color: const Color(0xFF312E81).withValues(alpha: 0.15), // Deep indigo
          blob3Color: const Color(0xFF4C1D95).withValues(alpha: 0.12), // Deep purple
          overlayColor: Colors.black.withValues(alpha: 0.25),
        ),

        // Background Logo (Centered and maximized) moved 20% up
        Align(
          alignment: const Alignment(0, -0.4),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing radial glow ring behind logo
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.72,
                      height: MediaQuery.of(context).size.width * 0.72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.03 + 0.04 * _pulseController.value),
                            blurRadius: 45 + 15 * _pulseController.value,
                            spreadRadius: 8 + 12 * _pulseController.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 60),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: ScholarlyTheme.shadowColor.withValues(alpha: 0.15),
                        blurRadius: 50,
                        spreadRadius: 2,
                        offset: const Offset(0, 25),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20), // Subtle rounding
                    child: Image.asset(
                      'assets/splash/splash.png',
                      height: MediaQuery.of(context).size.height * 0.52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main Content
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
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 240,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
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
                color: Colors.white38,
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
                  color: Colors.white70,
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
            color: Colors.white24,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
