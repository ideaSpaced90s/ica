import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../../../domain/models/ai_avatar.dart';
import '../widgets/about_us_widgets.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        AnimatedEntryCard(
          index: 0,
          child: JuicyGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            borderRadius: 24,
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/splash/light_knight.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Color(0xFF5B21B6)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Chess Academy',
                    maxLines: 1,
                    style: GoogleFonts.pirataOne(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Learn Chess Intently',
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'IdeaSpace Chess Academy is engineered as an advanced tactical sandbox for serious students of the royal game. We combine the mathematical precision of neural-network chess models with cognitive visualization methods to help players transition from rote calculation to powerful, intuitive grandmaster sight.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: ScholarlyTheme.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedEntryCard(
          index: 1,
          child: _buildPillarSection(),
        ),
        const SizedBox(height: 24),
        const AnimatedEntryCard(
          index: 2,
          child: PersonaSection(),
        ),
        const SizedBox(height: 24),
        AnimatedEntryCard(
          index: 3,
          child: _buildThemeChips(),
        ),
        const SizedBox(height: 24),
        AnimatedEntryCard(
          index: 4,
          child: _buildQuickStats(),
        ),
      ],
    );
  }

  Widget _buildPillarSection() {
    return Column(
      children: [
        _buildPillarCard(
          icon: Icons.psychology_rounded,
          title: 'Cognitive Visualization',
          description: 'High-fidelity visual indicators are designed to strengthen pattern recognition. Liquid evaluation bars and pulse clocks visually anchor tactical themes in working memory.',
        ),
        const SizedBox(height: 10),
        _buildPillarCard(
          icon: Icons.android_rounded,
          title: 'Persona-Driven AI Simulation',
          description: 'Simulates real-world competitive styles through custom Stockfish profiles, coaching you against attackers, endgames, and defensive specialists.',
        ),
        const SizedBox(height: 10),
        _buildPillarCard(
          icon: Icons.insights_rounded,
          title: 'Rigorous Training Loops',
          description: 'Progress through daily assignments, puzzle calibration streaks, and arena matches designed to eliminate calculation blindspots.',
        ),
      ],
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.indigo,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ScholarlyTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChips() {
    final themes = [
      'Classic', 'Scholar', 'B&W/Glass', 'Champions', 'Forest', 'Copper',
      'Calligraphy/Ink', 'Overgrown', 'Wood', 'Ivory', 'Steampunk', 'Seasons',
      'Sand', 'Timber', 'Platinum', 'Fairytale', 'Shadow', 'Royal', 'Bubblegum',
      'Silver & Gold', 'Marble', 'Desert', 'Plasma', 'Lightning', 'Diamonds', 'Arc'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            '26 VISUAL BOARD THEMES',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.indigo,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: themes.map((theme) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Text(
                theme,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('20', 'AI Personas'),
              _buildStatItem('26', 'Themes'),
              _buildStatItem('6', 'Analytics'),
              _buildStatItem('12', 'Modes'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'All computations run locally on-device.',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: ScholarlyTheme.textSubtle,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: ScholarlyTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class PersonaSection extends StatefulWidget {
  const PersonaSection({super.key});

  @override
  State<PersonaSection> createState() => _PersonaSectionState();
}

class _PersonaSectionState extends State<PersonaSection> {
  late PersonaMini _selectedPersona;

  final List<PersonaMini> _personas = [
    const PersonaMini(
      name: 'Chanakya',
      imagePath: 'assets/persona/gm_chanakya.png',
      color: ScholarlyTheme.accentBlue,
      title: 'The Chess Mentor AI',
      description: 'The academy director and mentor. Chanakya analyzes your previous games and dynamically alters his heuristic algorithms to target your diagnosed tactical and spatial weaknesses, providing real-time feedback.',
      trait: 'Heuristic Mentoring & Cognitive Targeting',
      strength: '400 - 3200 ELO (Adaptive)',
    ),
    ...AiAvatar.avatars.map((a) => PersonaMini(
      name: a.name,
      imagePath: a.imagePath,
      color: a.color,
      title: a.title,
      description: a.playingStyle,
      trait: _getPersonaTrait(a.name),
      strength: '${a.fideRatingRange} ELO',
    )),
  ];

  static String _getPersonaTrait(String name) {
    switch (name) {
      case 'Sparky': return 'Frequent Blunders & Random Play';
      case 'Pawzy': return 'Pawn Storm Obsession';
      case 'Timorous': return 'Passive Retreats & Extreme Defense';
      case 'Rookie': return 'Immediate Undefended Piece Captures';
      case 'Scholar': return 'Early Scholar\'s Mate Tactics';
      case 'Molly': return 'Closed Files & Iron Pawn Walls';
      case 'Berkserker': return 'Reckless Attacking & Early Sacrifices';
      case 'Blaire': return 'Rapid King-side Tactical Assault';
      case 'Python': return 'Subtle Maneuvers & Positional Squeezes';
      case 'Gambit': return 'Chaos Inducement & Material Imbalance';
      case 'Trapper': return 'Tricky Openings & Poisoned Pawns';
      case 'Assassin': return 'Relentless King Hunting';
      case 'Vala': return 'Sharp Tactical Vision & Piece Punishment';
      case 'Magician': return 'Imaginative Attacks & Brilliant Sacrifices';
      case 'Sentinel': return 'Subtle Positional Traps';
      case 'Murphy': return 'Rapid Coordinated Sea-Storm Attacks';
      case 'Titan': return 'Flawless Endgame & Constant Pressure';
      case 'Alien': return 'Unintuitive Algorithmic Moves';
      case 'Champ': return 'Universal Flawless Play';
      case 'King': return 'Apex Computational Engine';
      default: return 'Dynamic Chess Simulation';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedPersona = _personas.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '20 AI COMPANIONS & MENTORS',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap a profile icon to inspect traits and strengths',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          children: _personas.map((persona) {
            final isSelected = _selectedPersona.name == persona.name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPersona = persona;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  transform: isSelected ? Matrix4.diagonal3Values(1.1, 1.1, 1.0) : Matrix4.identity(),
                  child: SizedBox(
                    width: 65,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? persona.color : persona.color.withValues(alpha: 0.3),
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: persona.color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipOval(
                            child: buildAvatarImage(
                              persona.imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          persona.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? persona.color : ScholarlyTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: JuicyGlassCard(
              key: ValueKey(_selectedPersona.name),
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedPersona.color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: buildAvatarImage(
                            _selectedPersona.imagePath,
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
                              _selectedPersona.name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: ScholarlyTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedPersona.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedPersona.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.psychology_rounded,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PRIMARY TRAIT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPersona.trait,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: ScholarlyTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: _selectedPersona.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'STRENGTH',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: _selectedPersona.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPersona.strength,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: ScholarlyTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 14),
                  Text(
                    _selectedPersona.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: ScholarlyTheme.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PersonaMini {
  final String name;
  final String imagePath;
  final Color color;
  final String title;
  final String description;
  final String trait;
  final String strength;

  const PersonaMini({
    required this.name,
    required this.imagePath,
    required this.color,
    required this.title,
    required this.description,
    required this.trait,
    required this.strength,
  });
}
