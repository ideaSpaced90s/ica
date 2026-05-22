import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import '../../application/onboarding_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';

class DashboardTourOverlay extends ConsumerStatefulWidget {
  const DashboardTourOverlay({super.key});

  @override
  ConsumerState<DashboardTourOverlay> createState() => _DashboardTourOverlayState();
}

class _DashboardTourOverlayState extends ConsumerState<DashboardTourOverlay>
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

  GlobalKey? _getActiveKey(int step) {
    switch (step) {
      case 0:
        return profileCardKey;
      case 1:
        return arenaGridKey;
      case 2:
        return drawerMenuButtonKey;
      default:
        return null;
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
          // If the position is not sane (e.g. transitioning or unrendered), retry shortly.
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!mounted) return;
            _updateTargetLayout(step);
          });
        }
      } else {
        // If not laid out yet, check again soon
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          _updateTargetLayout(step);
        });
      }
    });
  }

  String _getDialogueText(int step) {
    switch (step) {
      case 0:
        return 'This is your player profile — it shows your ELO rating, winning streaks, and performance over time. Check it regularly to track how you\'re improving.';
      case 1:
        return 'These are the Arenas. Pick a time control — Bullet, Blitz, or Rapid — and play. Each one tests a different part of your game, so try them all.';
      case 2:
        return 'The menu button on the top-left gets you to every part of the app — Tutorial, Academy, Puzzles, Archives. One tap and you\'re there.';
      default:
        return '';
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'YOUR MASTER PROFILE';
      case 1:
        return 'THE ARENAS';
      case 2:
        return 'THE ACADEMY NAVIGATION';
      default:
        return '';
    }
  }

  Future<void> _handleSkip() async {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    ref.read(dashboardTourStepProvider.notifier).skipTour();
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(dashboardTourStepProvider);
    if (step == null) return const SizedBox.shrink();

    // Trigger recalculation if step changes
    if (step != _lastStep) {
      _lastStep = step;
      _targetPosition = Offset.zero;
      _targetSize = Size.zero;
      _updateTargetLayout(step);
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
                painter: SpotlightPainter(
                  position: _targetPosition,
                  size: _targetSize,
                  padding: 8,
                  borderRadius: step == 2 ? 24 : 16,
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),

          // Interactivity blocker (prevents clicking outside the dialogue boxes)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Do nothing to block clicks
              },
            ),
          ),

          // Dynamic Dialogue Card from GM Chanakya
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 20,
            right: 20,
            top: cardTop,
            bottom: cardBottom,
            child: _buildChanakyaDialogueCard(step),
          ),
        ],
      ),
    );
  }

  Widget _buildChanakyaDialogueCard(int step) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: ScholarlyTheme.glassPanelDecoration(radius: 20).copyWith(
            color: const Color(0xFF1E293B).withValues(alpha: 0.95),
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
                '${step + 1} / 3',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white30,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                onPressed: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                  ref.read(dashboardTourStepProvider.notifier).nextStep();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  step == 2 ? 'Finish' : 'Next',
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

class SpotlightPainter extends CustomPainter {
  final Offset position;
  final Size size;
  final double padding;
  final double borderRadius;

  SpotlightPainter({
    required this.position,
    required this.size,
    required this.padding,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7);

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
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.size != size ||
        oldDelegate.padding != padding ||
        oldDelegate.borderRadius != borderRadius;
  }
}
