import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/models/ai_avatar.dart';
import 'scholarly_theme.dart';
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
                const SizedBox(height: 16),

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
                        'IDEASPACE CHESS ACADEMY',
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
                        'IdeaSpace Chess Academy is engineered as an advanced tactical sandbox for serious students of the royal game. We combine the mathematical precision of neural-network chess models with cognitive visualization methods to help players transition from rote calculation to powerful, intuitive grandmaster sight.',
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

                CollapsibleSection(
                  title: 'ACADEMIC PILLARS',
                  initiallyExpanded: false,
                  child: Column(
                    children: [
                      _buildPillarCard(
                        icon: Icons.psychology_rounded,
                        title: 'Cognitive Visualization',
                        description: 'High-fidelity visual indicators are not merely aesthetic; they are designed to strengthen pattern recognition. Our liquid evaluation bar, pulsing clock urgency warnings, and interactive board feedback visually anchor critical tactical themes in working memory.',
                      ),
                      const SizedBox(height: 12),
                      _buildPillarCard(
                        icon: Icons.android_rounded,
                        title: 'Persona-Driven AI Simulation',
                        description: 'Playing against rigid engines is pedagogically ineffective. IdeaSpace Chess Academy simulates real-world competitive styles through customized Stockfish profiles, teaching students how to counter aggressive attackers, solid endgames, and creative defensive tacticians.',
                      ),
                      const SizedBox(height: 12),
                      _buildPillarCard(
                        icon: Icons.insights_rounded,
                        title: 'Rigorous Training Loops',
                        description: 'A dedicated student progresses through disciplined practice. By merging targeted thematic chapter puzzles with ELO-scaled competitive arenas, IdeaSpace Chess Academy provides a rigorous training cycle with zero analytical distractions.',
                      ),
                    ],
                  ),
                ),

                CollapsibleSection(
                  title: 'PERSONAS',
                  initiallyExpanded: false,
                  child: _buildPersonaTable(),
                ),

                CollapsibleSection(
                  title: 'ENGINE SYSTEM & SPECIFICATIONS',
                  initiallyExpanded: false,
                  child: JuicyGlassCard(
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
                ),
                CollapsibleSection(
                  title: 'DASHBOARD LOGIC',
                  initiallyExpanded: false,
                  child: JuicyGlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMathSectionHeader('1. ELO RATING TRANSITION SYSTEM'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'Your Elo rating measures your relative chess skill. When you play a rated game, the system '
                          'calculates your probability of winning (Expected Score) and updates your rating based on '
                          'how much you outperform or underperform that expectation.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          '                      1\n'
                          'Expected Score = ───────────────────────────────────────────────\n'
                          '                  1 + 10^((Rating of Opponent - Your Rating) / 400)\n\n'
                          'New Rating = Old Rating + K × (Actual Score - Expected Score) + Streak Bonus'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          'Explanation of the Variables:\n'
                          '• Expected Score (Se): This is a value between 0% (0.0) and 100% (1.0). If you play against GM Chanakya or Kingslayer who are rated much higher than you, the system expects you to lose, resulting in a very low Se (e.g. 10%). If you win or draw despite that, your rating will jump significantly!\n'
                          '• Scaling Constant (400): In standard chess math, a rating difference of 400 points means the stronger player is expected to score 10 times more points than the weaker player.\n'
                          '• Sensitivity Factor (K): This controls how fast your rating adapts. We use K = 40 for your first 10 provisional games to help you find your skill bracket quickly, and K = 20 thereafter for stable progression.\n'
                          '• S_actual: The actual outcome of the match, where a Win = 1.0, Draw = 0.5, and Loss/Resignation/Timeout = 0.0.\n'
                          '• Streak Bonus (S_bonus): To reward consistent excellence, maintaining an active winning streak of 3 or more games automatically grants a bonus of +5 Elo points for each consecutive victory.'
                        ),
                        const SizedBox(height: 24),
                        _buildMathSectionHeader('CALIBRATION PHASE — FIRST 10 RATED MATCHES'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'Every player begins their journey at an ELO rating of 400. The first 10 rated matches are your '
                          'Calibration Phase — a rapid placement period designed to quickly position you in the correct skill '
                          'bracket before stable rating progression begins.\n\n'
                          'During calibration, the K-factor is set to 40 (double the stable rate of 20). This amplifies both '
                          'wins and losses, allowing the system to converge on your true skill level in as few games as possible. '
                          'Once 10 matches are complete, K drops to 20 for steady, reliable rating growth.\n\n'
                          'While you are in the Calibration Phase, a gold badge on your dashboard home card will show how many '
                          'matches remain to complete your placement.'
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Starting ELO = 400   (ELO floor = 400; rating never drops below this)\n\n'
                          'Calibration K-Factor (Matches 1–10) : K = 40\n'
                          'Stable K-Factor (Match 11+)         : K = 20\n\n'
                          'Max ELO swing per calibration game (K=40, equal opponents):\n'
                          '  Win  : +20 ELO   (40 × (1.0 - 0.5))\n'
                          '  Loss : -20 ELO   (40 × (0.0 - 0.5))   → floored at 400\n'
                          '  Draw :   0 ELO   (40 × (0.5 - 0.5))\n\n'
                          'Max ELO swing per stable game (K=20, equal opponents):\n'
                          '  Win  : +10 ELO\n'
                          '  Loss : -10 ELO\n'
                          '  Draw :   0 ELO'
                        ),
                        const SizedBox(height: 24),
                        
                        _buildMathSectionHeader('2. CUMULATIVE MATERIAL DOMINANCE'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'A normal score only tells you who won, not how dominant they were. The Dominance Index (DOM) '
                          'quantifies your average material advantage at the end of rated matches, reflecting your average tactical superiority.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Material Margin = (Sum of Your Piece Values) - (Sum of Opponent Piece Values)\n\n'
                          '                     (Previous Dominance × N) + Material Margin\n'
                          'Average Dominance = ───────────────────────────────────────────────\n'
                          '                                         N + 1\n\n'
                          '                      (Bullet DOM × Bullet Games) + (Blitz DOM × Blitz Games) + (Rapid DOM × Rapid Games)\n'
                          'Overall Dominance = ─────────────────────────────────────────────────────────────────────────────────────────────\n'
                          '                                               Total Rated Games Played'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          'How it is calculated:\n'
                          '• We count the remaining pieces on the board at game completion and sum their relative values: Pawn = 1.0, Knight/Bishop = 3.0, Rook = 5.0, Queen = 9.0. (Kings have infinite value but are excluded from this relative calculation).\n'
                          '• Material Margin (M): Your material advantage. If you end the match with more pieces than your opponent, M is positive; if you have fewer, it is negative.\n'
                          '• Average Dominance: The running average of this final margin over N total games played in that specific arena speed category (Bullet, Blitz, or Rapid).\n'
                          '• Overall Dominance: The consolidated dominance shown on the dashboard\'s Master Card. It is the weighted average of your dominance across all time controls based on the number of matches played in each speed control.'
                        ),
                        const SizedBox(height: 24),

                        _buildMathSectionHeader('3. TACTICAL PERSONA POLAR MAPPING'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'The Radar Chart takes your raw statistics and normalizes them onto a scale from 0.0 (lowest) '
                          'to 1.0 (highest) to visualize your unique playing style:',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          '                              Average Dominance + 5\n'
                          'Attack (ATK) = [Clamped to] ─────────────────────────\n'
                          '                                       10\n\n'
                          '                            Peak Rating - 400\n'
                          'Power (POW) = [Clamped to] ───────────────────\n'
                          '                                  2000\n\n'
                          '                      Chess 960 Matches Played\n'
                          'Versatility (VER) = ────────────────────────────\n'
                          '                        Total Matches Played\n\n'
                          '                     Rated Victories (Wins)\n'
                          'Intensity (INT) = ────────────────────────────\n'
                          '                      Total Matches Played'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          'Interpretation of style coordinates:\n'
                          '• Attack (ATK): Derived from your average dominance (DOM_avg) across all speed controls. Having an average dominance of +5.0 or more yields a maximum score of 1.0, indicating highly aggressive play.\n'
                          '• Power (POW): Normalizes your peak rating achieved (Elo_max) on a scale from 400 to 2400. Reaching 2400+ rating earns a perfect 1.0.\n'
                          '• Versatility (VER): The proportion of Chess 960 games played. It tracks your adaptability when standard opening theory is stripped away.\n'
                          '• Intensity (INT): Your overall rated win rate (Wins / total rated games). Winning 100% of your matches yields 1.0.'
                        ),
                        const SizedBox(height: 24),

                        _buildMathSectionHeader('4. THEORY REPERTOIRE MASTERY'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'To evaluate your opening repertoire, we classify the first 10 plies (5 full moves) '
                          'against common opening schemas. We measure your performance using your win rate and '
                          'overall repertoire diversity.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          '                       Wins_op + 0.5 × Draws_op\n'
                          'Opening Win Rate = ───────────────────────────────── × 100%\n'
                          '                                Games_op\n\n'
                          '                                 H_op\n'
                          'Repertoire Depth Index (RDI) = ───────────────────────── × 100%\n'
                          '                                log(Catalog Size)'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          'Explanation of the Variables:\n'
                          '• Wins_op / Draws_op: The quantity of victories and draws you achieved using a specific classified opening sequence.\n'
                          '• Games_op: The total number of rated games played with this specific opening line.\n'
                          '• RDI: Measures how balanced and diverse your opening repertoire is. It is calculated by taking the Shannon Entropy (H_op) of your play rates across all classified openings and dividing by the logarithm of the total openings catalog size.'
                        ),
                        const SizedBox(height: 24),

                        _buildMathSectionHeader('5. ENDGAME CONVERSION & SURVIVAL'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'We define the endgame as the phase of the game where the total remaining non-pawn material '
                          'points on the board falls to 12 or less (Queen = 9, Rook = 5, Bishop = 3, Knight = 3). '
                          'The Endgame Performance Index (EPI) evaluates your conversion efficiency (winning when ahead) '
                          'and your defensive survival (saving equal or disadvantageous positions).',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'M_non_pawn = 9 × (Q_white + Q_black) + 5 × (R_white + R_black) + 3 × (B_white + B_black + N_white + N_black)\n\n'
                          'Endgame Transition: M_non_pawn ≤ 12\n\n'
                          '                                     Σ (Score_k × Complexity_k)\n'
                          'Endgame Performance Index (EPI) = ────────────────────────────── × 100%\n'
                          '                                           Σ Complexity_k'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          'How endgame metrics are calculated:\n'
                          '• Score_k: The outcome of game k, where Win = 1.0, Draw = 0.5, and Loss = 0.0.\n'
                          '• Complexity_k: A difficulty coefficient weighting factor based on the final material balance of that endgame. It scales to: 2.0 when converting a material advantage (to penalize losses heavily); 1.5 when defending a material disadvantage (to reward wins/draws highly); and 1.0 for equal material positions.\n'
                          '• Conversion Efficiency: The raw win rate in endgames where you had a positive material advantage.\n'
                          '• Defensive Save Rate: The rate at which you successfully Drew or Won endgames where you had a negative material balance.'
                        ),
                        const SizedBox(height: 24),
                        
                        _buildMathSectionHeader('6. SCOTOMA VISUAL BLIND SPOT ALGORITHMS'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'A Scotoma (from the Greek "skotos", meaning darkness) is a visual blind spot. In IdeaSpace Chess Academy, the '
                          'Scotoma Diagnostic Engine analyzes the move logs of your rated games in a native Rust core to '
                          'compute your vulnerability indices across 8 distinct visual and psychological axes.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Diagonal Retreat (DGB) Vector: |x2 - x1| = |y2 - y1| ≥ 3  AND  y2 < y1 (White) / y2 > y1 (Black)\n'
                          'Horizontal Swing (HRZ) Vector: y1 = y2  AND  |x2 - x1| ≥ 3 (Rook/Queen moves)\n'
                          'Knight Flank (KNF) Check: Knight moves where x1 ∈ {0,7} OR x2 ∈ {0,7} (A or H files)\n'
                          'Tunnel Vision (TNL) Check: |x_threat - mean(x_recent)| ≥ 4 (Opposite side threat)\n'
                          'Time Panic (TMP) Decay: Flagged if moves are played with remaining time < 45 seconds'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          'How visual blind spot metrics are computed in Rust:\n'
                          '• We reconstruct your rated matches move-by-move. If a game is lost, we scan the final 8 plies (where critical blunders cluster) for tactical themes.\n'
                          '• Diagonal retreats and horizontal swings are detected by coordinate deltas. If you lose to an opponent\'s retreating bishop move or horizontal rook swing, your scotoma score for that theme increases.\n'
                          '• Pinned Pieces (PIN): Rust temporarily removes a piece to verify if it is pinned to the King/Queen. If you move a pinned piece or fail to see a pin, your PIN scotoma increases.\n'
                          '• King Safety (KSB): Flagged if you allow a checkmate or ignore checking lines in the final moves.\n'
                          '• Overlooked Intermezzo (INT): Evaluates if you play a capture expecting a standard recapture, but the opponent plays an intermediate threat (Zwischenzug) that collapses your line.'
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                CollapsibleSection(
                  title: 'PUZZLE',
                  initiallyExpanded: false,
                  child: JuicyGlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMathSectionHeader('1. DYNAMIC DEFICIT ALLOCATION'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'Rather than serving arbitrary tactical scenarios, the academy training loops dynamically adapt to your style. '
                          'By parsing your Arena game logs, the system builds a vulnerability vector V tracking calculation deficits across '
                          'eight geometric axes. If your peak vulnerability exceeds the activation threshold (0.30), the training engine '
                          'allocates puzzles matching your dominant blind spot. Otherwise, it defaults to a balanced, general training mix.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Vector V = { V   , V   , V   , V   , V   , V   , V   , V    }\n'
                          '              dgb   hrz   knf   tmp   grd   tnl   pin   ksb\n\n'
                          '                  ┌ argmax(V)    if max(V) > 0.30\n'
                          'Training Focus = ─┤\n'
                          '                  └ Balanced     otherwise'
                        ),
                        const SizedBox(height: 24),
                        
                        _buildMathSectionHeader('2. COMPLEXITY TIERS & SKILL CALIBRATION'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'To ensure effective training, complexity calibration maps tactical puzzles to your current strength tier. '
                          'The database filters candidate puzzles using your rating (R) to target your calculation limits.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          '                       ┌ Tier 1 (Tactical Fundamentals)      if R < 1200\n'
                          'Complexity Tier (T) = ─┼ Tier 2 (Intermediate Calculation)   if 1200 ≤ R ≤ 1800\n'
                          '                       └ Tier 3 (Advanced Sight Masterclass) if R > 1800'
                        ),
                        const SizedBox(height: 24),

                        _buildMathSectionHeader('3. COGNITIVE-VISUAL SPATIAL CHANNELS'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'Each training channel filters tactical coordinates to systematically rebuild your board vision and eliminate calculation gaps:',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Diagonal Retreat (DGB) : |x  - x | = |y  - y | ≥ 3  AND  y  < y  (White) / y  > y  (Black)\n'
                          '                          2    1      2    1              2    1              2    1\n\n'
                          'Horizontal Sweep (HRZ) : y  = y   AND  |x  - x | ≥ 3\n'
                          '                          1    2         2    1\n\n'
                          'Knight Vision (KNF)    : x  ∈ {0, 7}  OR  x  ∈ {0, 7} (Outer files A & H)\n'
                          '                          1                2\n\n'
                          'Board-Wide Vision (TNL): |x       - mean(x      )| ≥ 4\n'
                          '                           threat        recent\n\n'
                          'Pressure Cooker (TMP)  : Remaining game time < 45 seconds'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          '• Poisoned Apple (GRD): Trains players to override material greed bias and check for tactical traps and sacrifices.\n'
                          '• Unpinning the Mind (PIN): Reinforces tactical pin detection and geometry validation lines.\n'
                          '• King Radar (KSB): Sharpens checkmate warning signs and king defense calculations.'
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                CollapsibleSection(
                  title: 'ACADEMY INTELLIGENCE',
                  initiallyExpanded: false,
                  child: JuicyGlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMathSectionHeader('1. ADAPTIVE HEURISTIC SCORE'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'In the Academy, GM Chanakya does not simply play the absolute best engine move. '
                          'Instead, he filters and weights Stockfish candidates to challenge your specific cognitive '
                          'blindspots (scotomas) and dynamically adapt to your playstyle.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Heuristic Score = Engine Evaluation + Jitter + ∑ Scotoma Bonuses + ∑ Playstyle Counter-Steer\n\n'
                          'Chanakya Play Choice = argmax(Heuristic Score(Move))'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          'By maximizing this adaptive scoring function, Chanakya plays moves that are both '
                          'strategically sound and specifically calibrated to exploit and train your tactical deficits.'
                        ),
                        const SizedBox(height: 24),

                        _buildMathSectionHeader('2. DYNAMIC OPENING JITTER & DECAY'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'To mimic human intuition and keep games varied, Chanakya applies a deterministic '
                          'opening variety jitter. However, when the game enters critical moments, Chanakya drops '
                          'all variance to play with perfect tactical calculation precision.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Jitter = base_jitter(FEN, Move) × Jitter Scale\n\n'
                          '               ┌ (24 - Half-Moves) / 24   if Half-Moves < 24 AND Tight Fight is False\n'
                          'Jitter Scale = ─┤\n'
                          '               └ 0.0                      otherwise\n\n'
                          'Tight Fight = (Absolute Evaluation ≤ 1.50) AND (Half-Moves ≥ 20)'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          '• base_jitter: A pseudo-random value between -1.0 and +1.0, seeded on the FEN and UCI move string to remain stable within the session.\n'
                          '• Jitter Scale: Decays linearly to 0.0 over the first 24 half-moves (12 full moves) of the game.\n'
                          '• Tight Fight: If the absolute evaluation margin is close (within 1.5 centipawns) and the game is in the middle-game (20+ half-moves), Chanakya disables all jitter (Scale = 0.0) to avoid handing over the win due to random variance.'
                        ),
                        const SizedBox(height: 24),

                        _buildMathSectionHeader('3. COGNITIVE SCOTOMA TARGET WEIGHTS'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'If your vulnerability profile (V) for a specific tactical theme is active (V > 0.20), '
                          'Chanakya scales up candidate moves that feature that theme, challenging you to see through the blindspot.',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Diagonal Retreat (DGB) Bonus  = V_dgb × 2.50    (For Bishop/Queen retreats ≥ 3 squares)\n'
                          'Horizontal Swing (HRZ) Bonus  = V_hrz × 2.00    (For Rook/Queen swings ≥ 3 squares)\n'
                          'Knight Fork (KNF) Bonus       = V_knf × 3.00    (Attacking 2+ high-value target pieces)\n'
                          'Pinned Pieces (PIN) Bonus     = V_pin × 2.00    (Attacking pinned piece; +1.50 if pinning)\n'
                          'King Safety (KSB) Bonus       = V_ksb × 2.50    (For checks; checkmate is forced with +99.0)\n'
                          'Material Greed (GRD) Bonus    = V_grd × 1.80    (Captures with safe-looking eval drop ≤ 2.50)'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          '• V_theme: Your historical vulnerability coefficient (0.0 to 1.0) derived by the diagnostic engine in Rust.\n'
                          '• Calculation Check: Before making a move, Chanakya runs a mini-sandbox simulation using the Shakmaty chess library to check if candidate moves meet geometric and tactical conditions (e.g. counting valuable targets after a knight jump to verify a fork, or removing pieces to verify absolute pins).'
                        ),
                        const SizedBox(height: 24),

                        _buildMathSectionHeader('4. PLAYSTYLE COUNTER-STEERING'),
                        const SizedBox(height: 10),
                        _buildMathText(
                          'Chanakya analyzes your aggression score (A) from the tactical radar map and '
                          'shapes his own strategy to force you out of your comfort zone:',
                        ),
                        const SizedBox(height: 12),
                        _buildMathFormula(
                          'Solid Defense (A > 0.60)   = ΔMobility × 0.15 × (A - 0.60) × 2.50\n'
                          '                             + minor piece exchange bonus (+1.50)\n'
                          '                             + tactical retreat bonus (+0.80)\n\n'
                          'Aggressive Attack (A < 0.40) = (0.40 - A) × 3.00 (applied to checking lines)\n'
                          '                             + open-file rook/queen activation (+1.50)\n'
                          '                             + advanced pawn push bonus (+1.20)'
                        ),
                        const SizedBox(height: 12),
                        _buildMathText(
                          '• Countering Aggressors: Against aggressive players, Chanakya plays solid defensive squeeze-out chess. He gets bonuses for restricting your pieces\' legal mobility (ΔMobility), trading off minor pieces to reduce your attacking force, and playing consolidating retreats.\n'
                          '• Countering Passifiers: Against passive, defensive players, Chanakya plays sharp attacking chess. He prioritizes check-giving lines, rook/queen activation on open files, and advancing pawns deep into your territory to create imbalances.'
                        ),
                      ],
                    ),
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
                      Image.asset(
                        'assets/splash/ideaspace.png',
                        height: 14,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'The IdeaSpace Chess Academy Team',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildMathSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: ScholarlyTheme.accentBlue,
      ),
    );
  }

  Widget _buildMathText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: ScholarlyTheme.textMuted,
        height: 1.4,
      ),
    );
  }

  Widget _buildMathFormula(String formula) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Text(
          formula,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            height: 1.5,
          ),
        ),
      ),
    );
  }


  Widget _buildPersonaTable() {
    final items = [
      const _PersonaMatrixItem(
        name: 'GM Chanakya',
        depth: '-',
        eloRange: 'Mentor',
        style: '100% human chess mentor. Believes humanity can beat chess machines. Plays with highest intellectual intuition as an ex-grandmaster.',
        imagePath: 'assets/persona/gm_chanakya.png',
        color: ScholarlyTheme.accentBlue,
      ),
      ...AiAvatar.avatars.reversed.map((a) => _PersonaMatrixItem(
            name: a.name,
            depth: 'Depth ${a.depth}',
            eloRange: a.fideRatingRange,
            style: a.playingStyle,
            imagePath: a.imagePath,
            color: a.color,
          )),
    ];

    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: JuicyGlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.color.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Engine Depth: ${item.depth}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.accentGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ScholarlyTheme.accentGold.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.eloRange,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 12),
                Text(
                  item.style,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: ScholarlyTheme.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.40),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: widget.child,
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _PersonaMatrixItem {
  final String name;
  final String depth;
  final String eloRange;
  final String style;
  final String imagePath;
  final Color color;

  const _PersonaMatrixItem({
    required this.name,
    required this.depth,
    required this.eloRange,
    required this.style,
    required this.imagePath,
    required this.color,
  });
}
