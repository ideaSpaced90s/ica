import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    Color activeAccent;
    switch (_activeTabIndex) {
      case 0:
        activeAccent = Colors.indigo;
        break;
      case 1:
        activeAccent = const Color(0xFF10B981);
        break;
      case 2:
        activeAccent = Colors.purple;
        break;
      case 3:
        activeAccent = Colors.amber.shade700;
        break;
      default:
        activeAccent = Colors.blue;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        exitToDashboardWithSidebar(context, ref);
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: activeAccent.withValues(alpha: 0.1),
        blob2Color: const Color(0xFFFCE7F3), // Soft Pink
        blob3Color: const Color(0xFFF3E8FF), // Soft Purple
        body: SafeArea(
          child: Column(
            children: [
              // Pill Tab Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _TabSelector(
                  selectedIndex: _activeTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _activeTabIndex = index;
                    });
                  },
                ),
              ),

              // Scrollable Content Area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildTabContent(_activeTabIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _OverviewTab(key: const ValueKey('overview'));
      case 1:
        return _ManualTab(key: const ValueKey('manual'));
      case 2:
        return _TechStackTab(key: const ValueKey('techstack'));
      case 3:
        return _ContactTab(key: const ValueKey('contact'), launchUrlCallback: _launchUrl);
      default:
        return const SizedBox();
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $urlString'),
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }
}

class _TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _TabSelector({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'title': 'Overview', 'icon': Icons.school_rounded},
      {'title': 'Manual', 'icon': Icons.menu_book_rounded},
      {'title': 'Tech Stack', 'icon': Icons.settings_suggest_rounded},
      {'title': 'Contact', 'icon': Icons.mail_rounded},
    ];

    return JuicyGlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          final tab = tabs[index];

          Color activeColor;
          switch (index) {
            case 0:
              activeColor = Colors.indigo;
              break;
            case 1:
              activeColor = const Color(0xFF10B981);
              break;
            case 2:
              activeColor = Colors.purple;
              break;
            case 3:
              activeColor = Colors.amber.shade700;
              break;
            default:
              activeColor = Colors.blue;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? activeColor.withValues(alpha: 0.3) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 20,
                      color: isSelected ? activeColor : ScholarlyTheme.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['title'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? activeColor : ScholarlyTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedEntryCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedEntryCard({
    required this.child,
    required this.index,
  });

  @override
  State<_AnimatedEntryCard> createState() => _AnimatedEntryCardState();
}

class _AnimatedEntryCardState extends State<_AnimatedEntryCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        _AnimatedEntryCard(
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
                      'assets/splash/appicon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
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
                    'IDEASPACE CHESS ACADEMY',
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Accelerating Tactical Vision & Chess Playing Strength',
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 13,
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
        _AnimatedEntryCard(
          index: 1,
          child: _buildPillarSection(),
        ),
        const SizedBox(height: 24),
        const _AnimatedEntryCard(
          index: 2,
          child: _PersonaSection(),
        ),
        const SizedBox(height: 24),
        _AnimatedEntryCard(
          index: 3,
          child: _buildThemeChips(),
        ),
        const SizedBox(height: 24),
        _AnimatedEntryCard(
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
      'Classic', 'Scholar', 'BnW/Glass', 'Champions', 'Forest', 'Copper',
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

class _ManualTab extends StatelessWidget {
  const _ManualTab({super.key});

  @override
  Widget build(BuildContext context) {
    final manualItems = [
      {
        'icon': Icons.space_dashboard_rounded,
        'title': '🏠 Dashboard',
        'description': 'Your personal chess cockpit. Tracks live ELO rating progress, tactical dominance indexes, and coordinates opening/endgame mastery metrics via a visual multi-axis radar chart.',
        'bullets': [
          'Track your current rating and view your first 10 placement matches progress.',
          'Analyze your playstyle coordinates (Power, Attack, Versatility, Intensity) instantly.',
          'Launch recommended daily assignments and challenges directly.',
        ],
      },
      {
        'icon': Icons.assignment_turned_in_rounded,
        'title': '📋 Assignment',
        'description': 'Targeted exercises curated by GM Chanakya. Serves custom puzzle sequences and specialized board conversion setups designed to patch cognitive gaps.',
        'bullets': [
          'Receive structured training recommendations every 24 hours.',
          'Unlock performance tokens and ELO points by passing challenge thresholds.',
          'Work under active coach mentoring and interactive visual hints.',
        ],
      },
      {
        'icon': Icons.sports_esports_rounded,
        'title': '⚔️ Arena',
        'description': 'Our primary tournament lobby. Matches you against 20 custom AI opponents calibrated from 400 to 3200+ FIDE ELO. Supports Chess 960 and variable time formats.',
        'bullets': [
          'Select your opponent profile, rating difficulty, color, and timer rules.',
          'Compete in Chess 960 to bypass memorized openings and test core calculation.',
          'Secure win streaks to unlock extra ELO boosts and rating badges.',
        ],
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': '🏟️ Battleground',
        'description': 'A zero-pressure analytical arena. Test new strategies against the native Stockfish engine with support for on-board evaluation meters and robot simulation modes.',
        'bullets': [
          'Analyze mid-game board dynamics using the liquid centipawn evaluation bar.',
          'Activate Robot Mode to command engine-versus-engine play dynamically.',
          'Request on-demand move feedback from the cloud-based High Council.',
        ],
      },
      {
        'icon': Icons.school_rounded,
        'title': '🏫 Academy',
        'description': 'Interactive play with our mentor AI. Instead of playing pure engine moves, Chanakya dynamically alters his heuristic algorithms to target your diagnosed blindspots.',
        'bullets': [
          'Experience a playstyle designed to exploit your weaknesses.',
          'Receive inline critiques and advice directly from your virtual coach.',
          'Practice counter-steering lines to break defensive or passive playing habits.',
        ],
      },
      {
        'icon': Icons.extension_rounded,
        'title': '🧩 Puzzles',
        'description': 'Tactical drills sorted by visual channel. Serves specific geometric patterns (diagonal retreats, knight flanks, pins) corresponding to your largest blindspots.',
        'bullets': [
          'Train with custom puzzles generated from actual blunder states.',
          'Progress through 3 complexity difficulty tiers matched to your rank.',
          'Build tactical accuracy streaks to unlock custom store cosmetics.',
        ],
      },
      {
        'icon': Icons.science_rounded,
        'title': '🔬 Analysis',
        'description': 'An offline workspace for board dissection. Features PGN game loading, FEN state edits, custom move branches, and multi-line engine recommendations.',
        'bullets': [
          'Load, export, and manage your custom PGN and FEN databases.',
          'Analyze complex middlegame positions with up to 3 candidate lines.',
          'Annotate boards and map out long-range variations manually.',
        ],
      },
      {
        'icon': Icons.history_rounded,
        'title': '📚 Archive',
        'description': 'Your personal library of games. Replay previous rated and academy games move-by-move under dynamic cinematic animations and checkmate replays.',
        'bullets': [
          'Browse and filter your local database of historical rated matches.',
          'Identify turning points and critical blunders flagged by Rust core scripts.',
          'Observe move dynamics using the integrated cinema controller dashboard.',
        ],
      },
      {
        'icon': Icons.menu_book_rounded,
        'title': '📖 Tutorial',
        'description': 'Structured beginner-to-advanced syllabus. Features lessons in basic piece geometry, tactical elements, pawn structures, and theoretical endgame conversions.',
        'bullets': [
          'Complete lesson chapters categorized across Initiate, Scholar, and Master tiers.',
          'Test spatial comprehension using interactive mid-lesson check boards.',
          'Study detailed opening schemas and conversion patterns offline.',
        ],
      },
      {
        'icon': Icons.settings_rounded,
        'title': '⚙️ Settings',
        'description': 'Full client configurations. Control native engine thread bounds, background volume mixers, board visual templates, and move confirmation boxes.',
        'bullets': [
          'Set custom Stockfish processing limits from 100ms to 3000ms.',
          'Customize your interface by selecting from 26 board themes and piece sets.',
          'Toggle tactile vibrations and visual clock safety warning flashes.',
        ],
      },
      {
        'icon': Icons.storefront_rounded,
        'title': '🛒 Store',
        'description': 'Visual market. Spend earned performance tokens to unlock premium board sets, thematic sounds, and piece collections.',
        'bullets': [
          'Earn tokens by completing daily assignments and solving puzzles.',
          'Preview prospective board themes interactively in the showcase area.',
          'Zero microtransactions — all items unlocked solely via gameplay milestones.',
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: manualItems.length,
      itemBuilder: (context, index) {
        final item = manualItems[index];
        return _AnimatedEntryCard(
          index: index,
          child: _ManualPageCard(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            description: item['description'] as String,
            bullets: item['bullets'] as List<String>,
            themeColor: const Color(0xFF10B981),
          ),
        );
      },
    );
  }
}

class _ManualPageCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;
  final Color themeColor;

  const _ManualPageCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
    required this.themeColor,
  });

  @override
  State<_ManualPageCard> createState() => _ManualPageCardState();
}

class _ManualPageCardState extends State<_ManualPageCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: JuicyGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.themeColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.themeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Colors.white12, height: 16),
                    Text(
                      widget.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: ScholarlyTheme.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HOW TO USE IT:',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: widget.themeColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.bullets.map((bullet) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                size: 14,
                                color: widget.themeColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: ScholarlyTheme.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechStackTab extends StatelessWidget {
  const _TechStackTab({super.key});

  @override
  Widget build(BuildContext context) {
    final techStackItems = [
      {
        'icon': Icons.phone_android_rounded,
        'category': 'UI FRAMEWORK',
        'technology': 'Flutter (Dart)',
        'description': 'Empowers the presentation layer with dynamic fluid layouts, customized UI canvas rendering, and smooth state updates.',
      },
      {
        'icon': Icons.bubble_chart_rounded,
        'category': 'STATE ENGINE',
        'technology': 'Riverpod',
        'description': 'Handles application state lifecycle, event dispatching, and engine process bridges with compile-time type safety.',
      },
      {
        'icon': Icons.memory_rounded,
        'category': 'LOCAL CHESS ENGINE',
        'technology': 'Stockfish 18 (Native FFI)',
        'description': 'Runs locally via an ARMv8 optimized C++ binary (`libstockfish.so`) interacting via non-blocking standard I/O pipes.',
      },
      {
        'icon': Icons.settings_suggest_rounded,
        'category': 'BARE-METAL CORE',
        'technology': 'Rust & Shakmaty',
        'description': 'Executes instant move generation, threat checks, and diagnostic scotomas on 64-bit CPU masks via `flutter_rust_bridge`.',
      },
      {
        'icon': Icons.font_download_rounded,
        'category': 'TYPOGRAPHY',
        'technology': 'Google Fonts',
        'description': 'Loads high-contrast typography (Outfit, Inter, JetBrains Mono, Pirata One) to secure academic visual polish.',
      },
      {
        'icon': Icons.animation_rounded,
        'category': 'MOTION FRAMEWORK',
        'technology': 'Flutter Animation System',
        'description': 'Drives 6 custom piece movement profiles, cinematic board camera drifts, landing settle bounces, and selected breathing.',
      },
      {
        'icon': Icons.storage_rounded,
        'category': 'PERSISTENCE',
        'technology': 'SharedPreferences',
        'description': 'Secures persistent client profiles, active theme parameters, audio volumes, and offline user settings.',
      },
      {
        'icon': Icons.devices_rounded,
        'category': 'PLATFORMS',
        'technology': 'Android & Windows',
        'description': 'Multi-platform support optimized for low-latency native execution and efficient thread schedules.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: techStackItems.length,
      itemBuilder: (context, index) {
        final item = techStackItems[index];
        return _AnimatedEntryCard(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _TechChipCard(
              icon: item['icon'] as IconData,
              category: item['category'] as String,
              technology: item['technology'] as String,
              description: item['description'] as String,
              themeColor: Colors.purple,
            ),
          ),
        );
      },
    );
  }
}

class _TechChipCard extends StatelessWidget {
  final IconData icon;
  final String category;
  final String technology;
  final String description;
  final Color themeColor;

  const _TechChipCard({
    required this.icon,
    required this.category,
    required this.technology,
    required this.description,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: themeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            technology,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: ScholarlyTheme.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  final ValueChanged<String> launchUrlCallback;

  const _ContactTab({
    super.key,
    required this.launchUrlCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        _AnimatedEntryCard(
          index: 0,
          child: JuicyGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            borderRadius: 24,
            child: Column(
              children: [
                // Branded Icon / Logo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.shade700.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.alternate_email_rounded,
                      size: 32,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'GET IN TOUCH',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We would love to hear your feedback, suggestions, or cooperation ideas. Reach out to the IdeaSpace team directly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: ScholarlyTheme.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 24),

                // Website Button
                _buildContactButton(
                  icon: Icons.language_rounded,
                  label: 'Official Website',
                  value: 'ideaspaceapps.store',
                  onTap: () => launchUrlCallback('https://ideaspaceapps.store'),
                  themeColor: Colors.amber.shade700,
                ),
                const SizedBox(height: 12),

                // Email Button
                _buildContactButton(
                  icon: Icons.email_rounded,
                  label: 'Support Email',
                  value: 'apps@ideaspaceapps.store',
                  onTap: () => launchUrlCallback('mailto:apps@ideaspaceapps.store'),
                  themeColor: Colors.amber.shade700,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Version Badge
        _AnimatedEntryCard(
          index: 1,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'VERSION 1.0.0 (RELEASE)',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.amber.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Footer Logo
        _AnimatedEntryCard(
          index: 2,
          child: Center(
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
                const SizedBox(height: 6),
                Image.asset(
                  'assets/splash/ideaspace.png',
                  height: 16,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'The IdeaSpace Chess Academy Team',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color themeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: themeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: ScholarlyTheme.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonaSection extends StatefulWidget {
  const _PersonaSection();

  @override
  State<_PersonaSection> createState() => _PersonaSectionState();
}

class _PersonaSectionState extends State<_PersonaSection> {
  late _PersonaMini _selectedPersona;

  final List<_PersonaMini> _personas = [
    const _PersonaMini(
      name: 'Chanakya',
      imagePath: 'assets/persona/gm_chanakya.png',
      color: ScholarlyTheme.accentBlue,
      title: 'The Chess Mentor AI',
      description: 'The academy director and mentor. Chanakya analyzes your previous games and dynamically alters his heuristic algorithms to target your diagnosed tactical and spatial weaknesses, providing real-time feedback.',
      trait: 'Heuristic Mentoring & Cognitive Targeting',
      strength: '400 - 3200 ELO (Adaptive)',
    ),
    ...AiAvatar.avatars.map((a) => _PersonaMini(
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
      case 'Pawnzy': return 'Pawn Storm Obsession';
      case 'Coward': return 'Passive Retreats & Extreme Defense';
      case 'Rookie': return 'Immediate Undefended Piece Captures';
      case 'Scholar': return 'Early Scholar\'s Mate Tactics';
      case 'Molly': return 'Closed Files & Iron Pawn Walls';
      case 'Berserker': return 'Reckless Attacking & Early Sacrifices';
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
        
        // Wrap representing the grid of personas
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
        
        // Detail panel
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
                  
                  // Trait & Strength Section
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
                  
                  // Description/Playing Style
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

class _PersonaMini {
  final String name;
  final String imagePath;
  final Color color;
  final String title;
  final String description;
  final String trait;
  final String strength;

  const _PersonaMini({
    required this.name,
    required this.imagePath,
    required this.color,
    required this.title,
    required this.description,
    required this.trait,
    required this.strength,
  });
}
