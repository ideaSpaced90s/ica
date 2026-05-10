import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'main_page.dart';
import 'scholarly_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _loadingValue = 0;

  @override
  void initState() {
    super.initState();
    // Enforce Portrait for the Splash Screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    )..addListener(() {
        setState(() {
          _loadingValue = _progressAnimation.value;
        });
      });

    _initFlow();
  }

  Future<void> _initFlow() async {
    debugPrint('SplashScreen: Starting _initFlow...');
    final notifier = ref.read(chessProvider.notifier);
    
    // Start services initialization in the background
    debugPrint('SplashScreen: Triggering background service init...');
    final initFuture = _initServices(notifier);

    // Static Image & Loading
    debugPrint('SplashScreen: Starting 10s progress animation.');
    final animationFuture = _progressController.forward();
    
    debugPrint('SplashScreen: Waiting for background services...');
    await initFuture;
    debugPrint('SplashScreen: Background services completed.');

    // Wait for the gimmick animation to finish if it hasn't already
    debugPrint('SplashScreen: Ensuring progress reaches 100%...');
    await animationFuture;
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      debugPrint('SplashScreen: Reverting to landscape orientation.');
      // Revert to Landscape mode for the Main App
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      if (!mounted) return;
      
      debugPrint('SplashScreen: Navigating to MainPage.');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainPage(),
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
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: _buildStaticPhase(),
    );
  }

  Widget _buildStaticPhase() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Logo (Centered and maximized) moved 20% up
        Align(
          alignment: const Alignment(0, -0.4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Image.asset(
              'assets/splash/splash.png',
              height: MediaQuery.of(context).size.height * 0.65, // Maximized size
              fit: BoxFit.contain,
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
          style: GoogleFonts.silkscreen(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _loadingValue / 100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
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
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            Image.asset(
              'assets/splash/ideaspace.png',
              height: 18,
              errorBuilder: (context, error, stackTrace) => const Text('ideaspace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'v1.0.0',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
