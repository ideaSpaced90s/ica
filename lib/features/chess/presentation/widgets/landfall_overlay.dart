import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/assignment_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';

class LandfallOverlay extends ConsumerStatefulWidget {
  final int islandIndex;

  const LandfallOverlay({
    super.key,
    required this.islandIndex,
  });

  @override
  ConsumerState<LandfallOverlay> createState() => _LandfallOverlayState();
}

class _LandfallOverlayState extends ConsumerState<LandfallOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _entranceController.forward();

    // Play victory sound effect when overlay appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.victory);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getIslandColor(int index) {
    switch (index) {
      case 0: return const Color(0xFF059669); // Forest Green
      case 1: return const Color(0xFF0284C7); // Ocean Blue
      case 2: return const Color(0xFF7C3AED); // Royal Purple
      case 3: return const Color(0xFF0056B3); // Deep Cobalt
      case 4: return const Color(0xFFD97706); // Burnt Amber
      case 5: return const Color(0xFF0F766E); // Slate Teal
      case 6: return const Color(0xFF6B21A8); // Dark Plum
      case 7: return const Color(0xFF991B1B); // Deep Crimson
      default: return Colors.blue;
    }
  }

  IconData _getIslandIcon(int index) {
    switch (index) {
      case 0: return Icons.person_rounded; // pawn / player
      case 1: return Icons.extension_rounded; // puzzles / tactics
      case 2: return Icons.explore_rounded; // explorer / knight
      case 3: return Icons.fort_rounded; // fortress / rook
      case 4: return Icons.auto_awesome_rounded; // bishop / magic
      case 5: return Icons.gavel_rounded; // warlord / king
      case 6: return Icons.workspace_premium_rounded; // grandmaster
      case 7: return Icons.military_tech_rounded; // kingslayer
      default: return Icons.circle;
    }
  }

  String _getChanakyaQuote(int index, String islandName) {
    switch (index) {
      case 0:
        return "Welcome to $islandName Island. A true soldier knows that even the smallest piece can determine the fate of the realm. Let's build your foundations.";
      case 1:
        return "You have landed on $islandName Island. The journey of calculation begins. Watch your pawn structures and keep your pieces active.";
      case 2:
        return "Landfall on $islandName Island! A tactician strikes when the iron is hot. Keep an eye out for Knight forks and diagonal retreats.";
      case 3:
        return "Welcome to $islandName Island. Deep calculation and foresight will be your weapons here. Do not let tunnel vision cloud your judgment.";
      case 4:
        return "Landed on $islandName Island. Here we query every move and challenge every greed. Stay calm under time panic, and do not fall for easy bait.";
      case 5:
        return "You are now on $islandName Island. Combos across the entire board will test your vision. Coordinate your forces like a true commander.";
      case 6:
        return "Welcome to $islandName Island! You have reached the elite class. The air is thin here, and mistakes are costly. Master your scotomas fully.";
      case 7:
        return "Behold! $islandName Island. You have crossed the 2250 ELO threshold. You stand at the gates of the ultimate challenge. Prepare to face the machine itself.";
      default:
        return "Congratulations on reaching a new island! Continue your strategic training, and together we will defeat the machine threat.";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.islandIndex < 0 || widget.islandIndex >= islandTiers.length) {
      return const SizedBox.shrink();
    }
    final tier = islandTiers[widget.islandIndex];
    final islandColor = _getIslandColor(widget.islandIndex);
    final islandIcon = _getIslandIcon(widget.islandIndex);

    return Positioned.fill(
      child: Stack(
        children: [
          // Blurred Darkened Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
              ),
            ),
          ),

          // Central Card content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.88,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate-800
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: islandColor.withValues(alpha: 0.4),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: islandColor.withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtitle
                      Text(
                        'NEW LANDFALL DISCOVERED',
                        style: GoogleFonts.outfit(
                          color: islandColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Floating Chess Piece Icon with Pulse Effect
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final double pulseScale = 1.0 + (_pulseController.value * 0.08);
                          return Transform.scale(
                            scale: pulseScale,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: islandColor.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: islandColor.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: islandColor.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                islandIcon,
                                size: 52,
                                color: islandColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Island Name
                      Text(
                        '${tier.name} Island',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // ELO Range Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.islandIndex == 7
                              ? 'Rating 2250+ ELO'
                              : 'Rating ${tier.minElo} - ${tier.maxElo} ELO',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Divider
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 24),

                      // GM Chanakya Mentor Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              image: const DecorationImage(
                                image: AssetImage('assets/persona/gm_chanakya.webp'),
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
                                  style: GoogleFonts.outfit(
                                    color: ScholarlyTheme.accentBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getChanakyaQuote(widget.islandIndex, tier.name),
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Dismiss / Set Sail Action Button
                      InkWell(
                        onTap: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                          ref.read(assignmentProvider.notifier).clearLandfallOverlay();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                islandColor,
                                islandColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: islandColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'SET SAIL',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
