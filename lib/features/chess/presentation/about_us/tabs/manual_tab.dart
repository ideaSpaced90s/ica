import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../widgets/about_us_widgets.dart';

class ManualTab extends StatelessWidget {
  const ManualTab({super.key});

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
        'description': 'A zero-pressure analytical arena. Test new strategies against the native Kingslayer 1.0 engine with support for on-board evaluation meters and robot simulation modes.',
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
          'Set custom Kingslayer 1.0 engine processing limits from 100ms to 3000ms.',
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
      {
        'icon': Icons.privacy_tip_rounded,
        'title': '🔒 Privacy Policy',
        'description': 'IdeaSpace Chess Academy is committed to protecting your privacy. This policy outlines how we collect, use, and secure your personal and gameplay data, in full compliance with the Google Play Developer Policies.',
        'bullets': [
          'Data Collection: When using Google Sign-In, we collect your name, email, and profile picture to identify your account. Anonymous mode requires no personal info.',
          'Gameplay & Progress: We store your chess ratings (ELO), game history, tactical analytics, completed assignments, and custom preferences.',
          'Data Security & Sync: Your user profile and data are secured with Firebase Cloud services or stored locally. All transit data uses secure SSL/TLS encryption.',
          'Third-Party & Ads: We do not sell, trade, or share user data with third-party advertising companies. There are no tracking SDKs or ad displays.',
          'Your Rights & Contact: You have full control. You can request account deletion or data exports by emailing our support team at apps@ideaspaceapps.store.',
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: manualItems.length,
      itemBuilder: (context, index) {
        final item = manualItems[index];
        return AnimatedEntryCard(
          index: index,
          child: ManualPageCard(
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

class ManualPageCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;
  final Color themeColor;

  const ManualPageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
    required this.themeColor,
  });

  @override
  State<ManualPageCard> createState() => _ManualPageCardState();
}

class _ManualPageCardState extends State<ManualPageCard> {
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
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
