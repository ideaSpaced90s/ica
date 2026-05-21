import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scholarly_theme.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/game_controls.dart';
import 'widgets/ambient_scaffold.dart';
import 'dashboard_page.dart';

class AboutUsPage extends ConsumerStatefulWidget {
  const AboutUsPage({super.key});

  @override
  ConsumerState<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends ConsumerState<AboutUsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        exitToDashboardWithSidebar(context, ref);
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        drawer: const GlobalSidebar(),
        blob1Color: const Color(0xFFDBEAFE), // Soft Blue
        blob2Color: const Color(0xFFFCE7F3), // Soft Pink
        blob3Color: const Color(0xFFF3E8FF), // Soft Purple
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 64),
                Text(
                  'ABOUT US',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kingslayer Chess Academy & Lab',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: ScholarlyTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),

                // Hero Card - Branded Core
                JuicyGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      // Styled App Logo Container
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ScholarlyTheme.accentBlue,
                              const Color(0xFF5B21B6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'KINGSLAYER CHESS',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ScholarlyTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ScholarlyTheme.accentGold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'v1.0.0 ACADEMIC PREMIUM',
                          style: GoogleFonts.jetBrainsMono(
                            color: ScholarlyTheme.accentGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bridging Intuition & Calculation',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kingslayer is engineered as an advanced tactical sandbox for serious students of the royal game. We combine the mathematical precision of neural-network chess models with cognitive visualization methods to help players transition from rote calculation to powerful, intuitive grandmaster sight.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ScholarlyTheme.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Section 2: Educational Pillars
                Text(
                  'ACADEMIC PILLARS',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Pillar 1: Cognitive
                _buildPillarCard(
                  icon: Icons.psychology_rounded,
                  title: 'Cognitive Visualization',
                  description: 'High-fidelity visual indicators are not merely aesthetic; they are designed to strengthen pattern recognition. Our liquid evaluation bar, pulsing clock urgency warnings, and interactive board feedback visually anchor critical tactical themes in working memory.',
                ),
                const SizedBox(height: 12),

                // Pillar 2: Persona Simulation
                _buildPillarCard(
                  icon: Icons.android_rounded,
                  title: 'Persona-Driven AI Simulation',
                  description: 'Playing against rigid engines is pedagogically ineffective. Kingslayer simulates real-world competitive styles through customized Stockfish profiles, teaching students how to counter aggressive attackers, solid endgames, and creative defensive tacticians.',
                ),
                const SizedBox(height: 12),

                // Pillar 3: Feedback Loop
                _buildPillarCard(
                  icon: Icons.insights_rounded,
                  title: 'Rigorous Training Loops',
                  description: 'A dedicated student progresses through disciplined practice. By merging targeted thematic chapter puzzles with ELO-scaled competitive arenas, Kingslayer provides a rigorous training cycle with zero analytical distractions.',
                ),
                const SizedBox(height: 28),

                // Section 3: Technical Specifications
                Text(
                  'ENGINE & SYSTEM SPECIFICATIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                JuicyGlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSpecRow('Neural AI Evaluator', 'Fully offline Stockfish NNUE engine integrations.'),
                      const Divider(height: 16, color: Colors.white24),
                      _buildSpecRow('Visual Assessment', 'Dynamic liquid scale with color-coded critical thresholds.'),
                      const Divider(height: 16, color: Colors.white24),
                      _buildSpecRow('Temporal Precision', 'Monospaced digital clock feedback with urgency tracking.'),
                      const Divider(height: 16, color: Colors.white24),
                      _buildSpecRow('Curriculum Depth', 'Targeted lesson modules, hand-picked puzzles, and ELO-scaled arenas.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Footer credits
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Designed & Developed by',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ScholarlyTheme.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The Kingslayer Creative Lab & AI Team',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating 3-bar drawer menu button (fixed at top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: ActionIconButton(
              icon: Icons.menu_rounded,
              size: 24,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
      ),
    ), // End of AmbientScaffold
   ); // End of PopScope
  }

  Widget _buildPillarCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: ScholarlyTheme.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: ScholarlyTheme.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.arrow_right_rounded,
          color: ScholarlyTheme.accentGold,
          size: 20,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ScholarlyTheme.textPrimary,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: ScholarlyTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
