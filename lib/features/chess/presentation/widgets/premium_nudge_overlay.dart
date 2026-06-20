import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mobile_navigation_shell.dart';
import '../../services/chess_sound_service.dart';
import '../../application/store_provider.dart';
import '../../application/chess_provider.dart';

class PremiumNudgeOverlay extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onDismiss;
  final bool isFullScreen;

  const PremiumNudgeOverlay({
    super.key,
    required this.title,
    required this.description,
    this.onDismiss,
    this.isFullScreen = false,
  });

  static void show(BuildContext context, WidgetRef ref, {String? title, String? description, VoidCallback? onDismiss}) {
    final storeState = ref.read(storeProvider);
    if (storeState.isPremium) {
      if (onDismiss != null) onDismiss();
      return; // Never show to premium users
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Premium Nudge',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: PremiumNudgeOverlay(
            title: title ?? 'IDEASPACE PREMIUM',
            description: description ?? 'Unlock unlimited games, expert coaching, and premium custom themes.',
            onDismiss: onDismiss,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1E1E2E), // Deep space blue/black
        Color(0xFF2D1F38), // Deep purple
        Color(0xFF1F122B), // Obsidian
      ],
    );

    return Scaffold(
      backgroundColor: isFullScreen ? const Color(0xFF1E1E2E) : Colors.transparent,
      body: Consumer(
        builder: (context, ref, child) {
          final columnContent = Padding(
            padding: EdgeInsets.fromLTRB(24, isFullScreen ? 64 : 40, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Crown Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD700), // Gold
                        Color(0xFFFFA500), // Amber
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Title
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Divider
                Divider(color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: 16),

                // Benefits list
                _buildBenefitItem('♾️', 'Unlimited Rated & Arena games'),
                _buildBenefitItem('🧩', 'Unlimited Tactical Chess Puzzles'),
                _buildBenefitItem('🎓', 'Unlimited Guidance from Chanakya AI'),
                _buildBenefitItem('🎨', 'All Premium Custom Board Themes Unlocked'),
                _buildBenefitItem('🏆', 'Exclusive Premium Profile Badge'),

                const SizedBox(height: 28),

                // Primary Upgrade Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD700), // Gold
                          Color(0xFFFFA500), // Amber
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        if (!isFullScreen) {
                          Navigator.pop(context); // Close overlay
                        }
                        ref.read(mobileNavIndexProvider.notifier).state = 10; // Navigate to Store (Index 10)
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'UPGRADE NOW',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1E1E2E),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                if (!isFullScreen) ...[
                  const SizedBox(height: 16),

                  // Bottom Dismiss Text Button ("Maybe Later")
                  TextButton(
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      Navigator.pop(context);
                      if (onDismiss != null) onDismiss!();
                    },
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );

          if (isFullScreen) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: mainGradient,
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: columnContent,
                  ),
                ),
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    gradient: mainGradient,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Top Right Close 'X' Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                            onPressed: () {
                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                              Navigator.pop(context);
                              if (onDismiss != null) onDismiss!();
                            },
                          ),
                        ),
                      ),
                      columnContent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
