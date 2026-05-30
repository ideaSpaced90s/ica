import 'dart:async';
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

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoFinished = false;
  bool _hasTransitioned = false;
  late Future<void> _servicesInitFuture;
  Timer? _fallbackTimer;

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
      duration: const Duration(milliseconds: 3500), // Nominal duration
    );

    _progressAnimation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    )..addListener(() {
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
      'assets/splash/splash_video.mp4',
    );

    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // Calculate progress duration: video duration minus 500ms
        final videoDuration = _videoController!.value.duration;
        final targetDuration = videoDuration - const Duration(milliseconds: 500);
        
        // Ensure duration is positive and reasonable (fallback to 1s if video is extremely short)
        _progressController.duration = targetDuration > const Duration(milliseconds: 500)
            ? targetDuration
            : const Duration(milliseconds: 1000);

        _videoController!.play();
        _progressController.forward();
      }
    }).catchError((error) {
      debugPrint('Splash video initialization error: $error');
      if (mounted) {
        setState(() {
          _isVideoFinished = true;
        });
        _progressController.forward();
        _checkTransition();
      }
    });

    _videoController!.addListener(_videoListener);

    // Safety fallback: transition to loading screen if video player hangs (10s timeout)
    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_hasTransitioned) {
        debugPrint('Splash video fallback triggered due to timeout.');
        setState(() {
          _isVideoFinished = true;
        });
        _progressController.forward(); // Ensure progress completes
        _checkTransition();
      }
    });
  }

  void _videoListener() {
    if (_videoController == null) return;
    final value = _videoController!.value;
    if (value.isInitialized &&
        value.position >= value.duration &&
        !_isVideoFinished) {
      setState(() {
        _isVideoFinished = true;
      });
      _checkTransition();
    }
  }

  void _checkTransition() {
    if (_hasTransitioned) return;

    final isVideoDone = _isVideoFinished || (_videoController != null && _videoController!.value.hasError);
    final isProgressDone = _progressController.isCompleted;

    if (isVideoDone && isProgressDone) {
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
    _fallbackTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7EF), // Cream off-white to match the app icon
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Player Background (if initialized)
          if (_isVideoInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            // Fallback background during initialization
            Container(color: const Color(0xFFF7F7EF)),

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

