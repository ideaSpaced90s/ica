import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'dashboard_page.dart';
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

    _initFlow();
  }

  Future<void> _initFlow() async {
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
        // Ambient background glow
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                  ScholarlyTheme.backgroundStart.withValues(alpha: 0),
                ],
              ),
            ),
          ),
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
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: ScholarlyTheme.shadowColor.withValues(alpha: 0.12),
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
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _loadingValue / 100,
            child: Container(
              decoration: BoxDecoration(
                color: ScholarlyTheme.accentBlue,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
