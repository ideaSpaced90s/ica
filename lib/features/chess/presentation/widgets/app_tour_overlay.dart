import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import '../../application/onboarding_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../mobile_navigation_shell.dart';

/// App Feature Tour overlay — 4 stops covering Academy, Puzzles, Analysis Lab, and Navigation.
/// Navigates to the relevant tab for each step and spotlights the page body area.
/// After completion (or skip), hands off to the Dashboard Tour.
class AppTourOverlay extends ConsumerStatefulWidget {
  const AppTourOverlay({super.key});

  @override
  ConsumerState<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends ConsumerState<AppTourOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Offset _targetPosition = Offset.zero;
  Size _targetSize = Size.zero;
  int _lastStep = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Returns the GlobalKey for each step's target widget
  GlobalKey? _getActiveKey(int step) {
    switch (step) {
      case 0:
        return arenaPageKey;
      case 1:
        return academyPageKey;
      case 2:
        return puzzlePageKey;
      case 3:
        return analysisPageKey;
      case 4:
        return drawerMenuButtonKey;
      default:
        return null;
    }
  }

  // Tab index to navigate to for each step
  int _getTabIndex(int step) {
    switch (step) {
      case 0:
        return 1; // Arena
      case 1:
        return 2; // Academy
      case 2:
        return 3; // Puzzles
      case 3:
        return 4; // Analysis Lab
      case 4:
        return 0; // Dashboard (to show menu button)
      default:
        return 0;
    }
  }

  void _updateTargetLayout(int step) {
    final key = _getActiveKey(step);
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final pos = renderBox.localToGlobal(Offset.zero);
        final sz = renderBox.size;
        
        // A coordinate of 10000+ or negative (when offscreen/inactive) is clearly not sane yet.
        final isSane = pos.dy >= -100 && pos.dy < 10000;
        
        if (isSane) {
          if (pos != _targetPosition || sz != _targetSize) {
            setState(() {
              _targetPosition = pos;
              _targetSize = sz;
            });
          }
        } else {
          // If the position is not sane (e.g. inactive tab or transitioning), retry shortly.
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!mounted) return;
            _updateTargetLayout(step);
          });
        }
      } else {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (!mounted) return;
          _updateTargetLayout(step);
        });
      }
    });
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'BATTLEGROUND & ARENA';
      case 1:
        return 'THE ACADEMY';
      case 2:
        return 'TACTICAL DRILLS';
      case 3:
        return 'ANALYSIS LAB';
      case 4:
        return 'NAVIGATION';
      default:
        return '';
    }
  }

  String _getDialogueText(int step) {
    switch (step) {
      case 0:
        return 'Welcome to the Arenas! Choose from Bullet, Blitz, or Rapid modes here to play real-time chess games against players or bots and test your skills.';
      case 1:
        return 'This is the Academy — load up any custom position to practice your endgames or ask for advice. It is a powerful workspace for tactical learning.';
      case 2:
        return 'Train your tactical eye with custom puzzles. Solve challenges based on real-game scenarios to sharpen your pattern recognition.';
      case 3:
        return 'Review your own matches or analyze specific chess openings here. It is a clean PGN board editor built for deep strategic review.';
      case 4:
        return 'Tap the menu button at the top-left to access your full player profile, match history, and the complete Chess Academy settings.';
      default:
        return '';
    }
  }

  void _handleNext(int step) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    final notifier = ref.read(appTourStepProvider.notifier);

    if (step < 4) {
      // Navigate to the next step's tab before advancing
      final nextTab = _getTabIndex(step + 1);
      ref.read(mobileNavIndexProvider.notifier).state = nextTab;
      notifier.nextStep(ref);
    } else {
      // Last step — complete tour and hand off to Dashboard Tour
      ref.read(mobileNavIndexProvider.notifier).state = 0;
      notifier.nextStep(ref);
    }
  }

  Future<void> _handleSkip() async {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ScholarlyTheme.backgroundStart,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: ScholarlyTheme.accentBlue,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Do you want to skip important guided tour of chess moves?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: ScholarlyTheme.panelStroke,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Yes',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(mobileNavIndexProvider.notifier).state = 0;
      ref.read(appTourStepProvider.notifier).cancelTour();
      ref.read(dashboardTourStepProvider.notifier).skipTour();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(appTourStepProvider);
    if (step == null) return const SizedBox.shrink();

    // Navigate to tab and recalculate layout on step change
    if (step != _lastStep) {
      _lastStep = step;
      _targetPosition = Offset.zero;
      _targetSize = Size.zero;
      // Ensure tab navigation happened before measuring
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTargetLayout(step);
      });
    } else if (_targetPosition == Offset.zero) {
      _updateTargetLayout(step);
    }

    final screenHeight = MediaQuery.of(context).size.height;
    
    // Check if the measured target position is actually on-screen and valid
    final isPositionSane = _targetSize != Size.zero &&
        _targetPosition.dy >= -100 &&
        _targetPosition.dy < screenHeight + 100;

    double? cardTop;
    double? cardBottom;

    if (!isPositionSane) {
      // Center the dialogue card if target layout is not ready or is offscreen
      cardTop = (screenHeight - 240) / 2;
      cardBottom = null;
    } else {
      final isTargetInUpperHalf = _targetPosition.dy < (screenHeight / 2);
      if (isTargetInUpperHalf) {
        cardTop = _targetPosition.dy + _targetSize.height + 24;
        cardBottom = null;
      } else {
        cardTop = null;
        cardBottom = (screenHeight - _targetPosition.dy) + 24;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Spotlight background overlay (only draw spotlight cutout if target layout is sane)
          if (isPositionSane)
            Positioned.fill(
              child: CustomPaint(
                painter: _AppTourSpotlightPainter(
                  position: _targetPosition,
                  size: _targetSize,
                  padding: step == 4 ? 6 : 12,
                  borderRadius: step == 4 ? 28 : 20,
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),

          // Block all taps outside the dialogue card
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),

          // Dynamic Chanakya Dialogue Card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 20,
            right: 20,
            top: cardTop,
            bottom: cardBottom,
            child: _buildDialogueCard(step),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueCard(int step) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: ScholarlyTheme.glassPanelDecoration(radius: 20).copyWith(
            color: const Color(0xFF1E293B).withValues(alpha: 0.96),
            border: Border.all(
              color: ScholarlyTheme.accentBlue.withValues(
                alpha: 0.3 + 0.2 * _pulseController.value,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: avatar + name + step counter
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/persona/gm_chanakya.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GM CHANAKYA',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      _getStepTitle(step),
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${step + 1} / 5',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white30,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step progress dots
          Row(
            children: List.generate(5, (i) {
              final isActive = i == step;
              final isPast = i < step;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive
                        ? ScholarlyTheme.accentBlue
                        : isPast
                            ? ScholarlyTheme.accentBlue.withValues(alpha: 0.4)
                            : Colors.white12,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Chanakya dialogue
          Text(
            _getDialogueText(step),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _handleSkip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white38,
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _handleNext(step),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  step == 4 ? 'Finish' : 'Next',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw a dark overlay with a rectangular spotlight cutout.
class _AppTourSpotlightPainter extends CustomPainter {
  final Offset position;
  final Size size;
  final double padding;
  final double borderRadius;

  _AppTourSpotlightPainter({
    required this.position,
    required this.size,
    required this.padding,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.72);

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx - padding,
          position.dy - padding,
          size.width + padding * 2,
          size.height + padding * 2,
        ),
        Radius.circular(borderRadius),
      ));

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AppTourSpotlightPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.size != size ||
        oldDelegate.padding != padding ||
        oldDelegate.borderRadius != borderRadius;
  }
}
