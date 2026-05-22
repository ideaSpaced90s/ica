import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_scaffold.dart';

/// A beautiful placeholder page for Academy Settings, designed with cohesive glassmorphism.
class AcademySettingsPage extends ConsumerWidget {
  const AcademySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AmbientScaffold(
      blob1Color: const Color(0xFFF1F5F9), // Soft parchment
      blob2Color: const Color(0xFFFEF3C7), // Warm amber glow
      blob3Color: const Color(0xFFECFDF5), // Scholar emerald
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Space
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 24),
              ),

              // Back Button & Page Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: ScholarlyTheme.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACADEMY SETTINGS',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // Glass Placeholder Box
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: JuicyGlassCard(
                    padding: const EdgeInsets.all(32),
                    borderRadius: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 40,
                            color: ScholarlyTheme.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Academy Settings',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The grand archives are being cataloged. Personalized study tracks, training drill customized limits, and engine difficulty settings are being prepared by the collective.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.5,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: ScholarlyTheme.accentBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Return to Academy',
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.accentBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
