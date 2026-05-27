import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../application/chess_provider.dart';
import '../application/tutorial_provider.dart';
import 'mobile_navigation_shell.dart';
import 'sign_in_page.dart';
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

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoFinished = false;
  late Future<void> _servicesInitFuture;

  @override
  void initState() {
    super.initState();
    // Enforce Portrait for the Splash Screen (or allow landscape)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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

    // 1. Start services initialization in parallel during video playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(chessProvider.notifier);
        _servicesInitFuture = _initServices(notifier);
      }
    });

    // 2. Initialize and play splash video
    _initVideo();
  }

  void _initVideo() {
    _videoController = VideoPlayerController.asset(
      'assets/splash/ideaspace_chess_splash_screen.mp4',
    );

    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
      }
    }).catchError((error) {
      debugPrint('Splash video initialization error: $error');
      _startLoadingFlow();
    });

    _videoController!.addListener(_videoListener);

    // Safety fallback: transition to loading screen if video player hangs (8s timeout)
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_isVideoFinished) {
        debugPrint('Splash video fallback triggered due to timeout.');
        _startLoadingFlow();
      }
    });
  }

  void _videoListener() {
    if (_videoController == null) return;
    final value = _videoController!.value;
    if (value.isInitialized &&
        value.position >= value.duration &&
        !_isVideoFinished) {
      _startLoadingFlow();
    }
  }

  void _startLoadingFlow() {
    if (_isVideoFinished) return;
    setState(() {
      _isVideoFinished = true;
    });
    _videoController?.removeListener(_videoListener);
    _runLoadingScreenFlow();
  }

  Future<void> _runLoadingScreenFlow() async {
    final startTime = DateTime.now();

    // Start progress animation
    _progressController.forward();

    // Wait for the background services initialization to finish
    try {
      await _servicesInitFuture;
    } catch (e) {
      debugPrint('Service Init error in loading flow: $e');
    }

    // Enforce a small minimum time (e.g. 1.2s) for branding
    final elapsed = DateTime.now().difference(startTime);
    const minTime = Duration(milliseconds: 1200);
    if (elapsed < minTime) {
      await Future.delayed(minTime - elapsed);
    }

    // Complete the progress bar quickly if not already done
    if (_progressController.value < 1.0) {
      await _progressController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    if (mounted) {
      // Allow Landscape
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

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
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7EF), // Cream off-white to match the app icon
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: _buildCurrentPhase(),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    if (!_isVideoFinished) {
      if (_isVideoInitialized && _videoController != null) {
        return Container(
          key: const ValueKey('video_phase'),
          color: const Color(0xFFF7F7EF), // Cream off-white background matching the video/app theme
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      } else {
        return Container(
          key: const ValueKey('video_init_phase'),
          color: const Color(0xFFF7F7EF), // Cream off-white background during initialization
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0D6EFD), // Contrasting theme blue indicator
            ),
          ),
        );
      }
    } else {
      return Container(
        key: const ValueKey('static_phase'),
        color: const Color(0xFFF7F7EF),
        child: _buildStaticPhase(),
      );
    }
  }

  Widget _buildStaticPhase() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ambient animated background glow
        AmbientFlowBackdrop(
          backgroundColor: const Color(0xFFF7F7EF),
          blob1Color: const Color(0xFFDBEAFE).withValues(alpha: 0.5), // Soft pastel blue
          blob2Color: const Color(0xFFFEE2E2).withValues(alpha: 0.4), // Soft pastel pink
          blob3Color: const Color(0xFFF3E8FF).withValues(alpha: 0.45), // Soft pastel lavender
          overlayColor: Colors.white.withValues(alpha: 0.35),
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
                      width: MediaQuery.of(context).size.width * 0.60,
                      height: MediaQuery.of(context).size.width * 0.60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D6EFD).withValues(alpha: 0.05 + 0.05 * _pulseController.value),
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
                  child: Image.asset(
                    'assets/splash/appicon.png',
                    height: MediaQuery.of(context).size.height * 0.416, // Reduced by 20% (0.52 * 0.8)
                    fit: BoxFit.contain,
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
