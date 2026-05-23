import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final items = const [
      _PersonaMatrixItem(
        name: 'GM Chanakya',
        brand: 'Crafty',
        depth: 'Full Power',
        eloRange: 'Mentor',
        style: 'Wisdom/mentor style, maximum precision, classic intuition.',
        icon: Icons.school_rounded,
        color: ScholarlyTheme.accentBlue,
      ),
      _PersonaMatrixItem(
        name: 'Kingslayer',
        brand: 'Stockfish',
        depth: 'Depth 22',
        eloRange: '2850 - 3200+',
        style: 'Ultimate absolute computational perfection.',
        icon: Icons.diamond_rounded,
        color: Color(0xFFE0E0E0),
      ),
      _PersonaMatrixItem(
        name: 'Titan',
        brand: 'Crafty',
        depth: 'Depth 18',
        eloRange: '2500 - 2700',
        style: 'Grandmaster precision, relentless positional pressure.',
        icon: Icons.psychology_rounded,
        color: Color(0xFFFFD54F),
      ),
      _PersonaMatrixItem(
        name: 'Morphy',
        brand: 'Stockfish',
        depth: 'Depth 15',
        eloRange: '2200 - 2400',
        style: 'Classical elegance, open lines, rapid piece coordination.',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFE57373),
      ),
      _PersonaMatrixItem(
        name: 'Sentinel',
        brand: 'Crafty',
        depth: 'Depth 12',
        eloRange: '1900 - 2100',
        style: 'Positional trap specialist, superb prophylaxis.',
        icon: Icons.gpp_good_rounded,
        color: Color(0xFF7986CB),
      ),
      _PersonaMatrixItem(
        name: 'Vanguard',
        brand: 'Stockfish',
        depth: 'Depth 10',
        eloRange: '1700 - 1850',
        style: 'Sharp tactical vision, uncoordinated piece punisher.',
        icon: Icons.track_changes_rounded,
        color: Color(0xFF4DB6AC),
      ),
      _PersonaMatrixItem(
        name: 'Gambit',
        brand: 'Stockfish',
        depth: 'Depth 7',
        eloRange: '1500 - 1650',
        style: 'Chaos lover, tactical sacrifices, material imbalances.',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFBA68C8),
      ),
      _PersonaMatrixItem(
        name: 'Blitzer',
        brand: 'Crafty',
        depth: 'Depth 5',
        eloRange: '1300 - 1450',
        style: 'Highly tactical, rapid attacker targeting the king.',
        icon: Icons.bolt_rounded,
        color: Color(0xFFFFB74D),
      ),
      _PersonaMatrixItem(
        name: 'Stonewall',
        brand: 'Stockfish',
        depth: 'Depth 4',
        eloRange: '1100 - 1250',
        style: 'Locked pawn chains, ultra-conservative, closed files.',
        icon: Icons.shield_rounded,
        color: Color(0xFF90A4AE),
      ),
      _PersonaMatrixItem(
        name: 'Rook-ie',
        brand: 'Stockfish',
        depth: 'Depth 3',
        eloRange: '950 - 1050',
        style: 'Capturing undefended pieces immediately without recapture risk assessment.',
        icon: Icons.castle_rounded,
        color: Color(0xFF64B5F6),
      ),
      _PersonaMatrixItem(
        name: 'Pawnzy',
        brand: 'Crafty',
        depth: 'Depth 2',
        eloRange: '800 - 950',
        style: 'Erratic novice, pawn-heavy movements.',
        icon: Icons.cruelty_free_rounded,
        color: Color(0xFF81C784),
      ),
      _PersonaMatrixItem(
        name: 'Sparky',
        brand: 'Crafty',
        depth: 'Depth 1',
        eloRange: '400 - 500',
        style: 'Absolute beginner, frequent blunders, random pushes.',
        icon: Icons.child_care_rounded,
        color: Color(0xFFA1887F),
      ),
    ];

    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: 24,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          constraints: const BoxConstraints(minWidth: 800),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(160), // Name
              1: FixedColumnWidth(130), // Engine Brand
              2: FixedColumnWidth(120), // Engine Depth
              3: FixedColumnWidth(120), // Elo Range
              4: FixedColumnWidth(270), // Playing Style
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white24, width: 1.5),
                  ),
                ),
                children: [
                  _buildHeaderCell('PERSONA'),
                  _buildHeaderCell('ENGINE BRAND'),
                  _buildHeaderCell('ENGINE DEPTH'),
                  _buildHeaderCell('ELO RANGE'),
                  _buildHeaderCell('TACTICAL PLAYSTYLE'),
                ],
              ),
              ...items.map((item) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white12, width: 1),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(item.icon, color: item.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: ScholarlyTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: _buildEngineChip(item.brand),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(
                        item.depth,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(
                        item.eloRange,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentGold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(
                        item.style,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: ScholarlyTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: ScholarlyTheme.textSubtle,
        ),
      ),
    );
  }

  Widget _buildEngineChip(String brand) {
    final isCrafty = brand == 'Crafty';
    final color = isCrafty ? ScholarlyTheme.accentGold : ScholarlyTheme.accentBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        brand,
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
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
  final String brand;
  final String depth;
  final String eloRange;
  final String style;
  final IconData icon;
  final Color color;

  const _PersonaMatrixItem({
    required this.name,
    required this.brand,
    required this.depth,
    required this.eloRange,
    required this.style,
    required this.icon,
    required this.color,
  });
}
