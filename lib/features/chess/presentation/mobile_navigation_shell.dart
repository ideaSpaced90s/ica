import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/chess_provider.dart';
import '../application/battleground_provider.dart';
import '../application/arena_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';

import 'dashboard_page.dart';
import 'arena/arena_page.dart';
import 'battleground/battleground_page.dart';
import 'academy/academy_page.dart';
import 'puzzles/puzzles_page.dart';
import 'analysis/analysis_page.dart';
import 'history_page.dart';

import 'tutorial_page.dart';
import 'about_us_page.dart';
import 'settings_page.dart';

import 'widgets/welcome_guide_page.dart';
import '../application/onboarding_provider.dart';


// Provides the current active mobile tab index.
final mobileNavIndexProvider = StateProvider<int>((ref) => 0);

class MobileNavigationShell extends ConsumerWidget {
  const MobileNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mobileNavIndexProvider);

    // Mute background music when in Arena (1), Battleground (2), Academy (3), or Puzzles (4)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isMuted = currentIndex == 1 || currentIndex == 2 || currentIndex == 3 || currentIndex == 4;
      ref.read(chessSoundServiceProvider).setMutedTabState(isMuted);
    });

    // IndexedStack children
    final List<Widget> pages = [
      const DashboardPage(),
      const ArenaPage(),
      const BattlegroundPage(),
      const AcademyPage(),
      const PuzzlesPage(),
      const AnalysisPage(),
      const HistoryPage(),
      const TutorialPage(),
      const AboutUsPage(),
      const SettingsPage(),
    ];

    // Determine logical title based on active tab
    String getTitle() {
      switch (currentIndex) {
        case 0:
          return 'HOME';
        case 1:
          return 'ARENA';
        case 2:
          return 'BATTLEGROUND';
        case 3:
          return 'ACADEMY';
        case 4:
          return 'PUZZLES';
        case 5:
          return 'ANALYSIS';
        case 6:
          return 'ARCHIVE';
        case 7:
          return 'TUTORIAL';
        case 8:
          return 'ABOUT US';
        case 9:
          return 'SETTINGS';
        default:
          return 'IDEASPACE CHESS ACADEMY';
      }
    }

    final showWelcome = ref.watch(showWelcomeDialogProvider);

    Widget result = Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      appBar: AppBar(
        backgroundColor: ScholarlyTheme.backgroundStart,
        elevation: 0,
        centerTitle: true,
        title: Text(
          getTitle(),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: ScholarlyTheme.textPrimary),
              onPressed: () async {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                
                if (currentIndex == 1) {
                  final arenaState = ref.read(arenaProvider);
                  if (arenaState.recentMoves.isNotEmpty && !arenaState.game.gameOver && !arenaState.isPaused) {
                    ref.read(arenaProvider.notifier).togglePause();
                  }
                }

                final isBattleground = currentIndex == 2;
                final bgState = ref.read(battlegroundProvider);
                final isMatchActive = isBattleground && bgState.recentMoves.isNotEmpty && !bgState.game.gameOver;
                
                if (isMatchActive) {
                  final resigned = await showRatedExitDialog(context);
                  if (resigned == true) {
                    await ref.read(battlegroundProvider.notifier).resignRatedGame();
                    if (context.mounted) {
                      exitToDashboardWithSidebar(context, ref);
                    }
                  }
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/splash/ideaspace.png',
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
      drawer: const _MobileSidebarDrawer(),
      body: IndexedStack(
        index: currentIndex,
        children: List.generate(pages.length, (index) {
          return LazyIndexedStackChild(
            isActive: currentIndex == index,
            child: TickerMode(
              enabled: currentIndex == index,
              child: pages[index],
            ),
          );
        }),
      ),
    );

    if (showWelcome) {
      result = Stack(
        children: [
          result,
          const WelcomeGuidePage(),
        ],
      );
    }

    return result;
  }
}

class _MobileSidebarDrawer extends ConsumerWidget {
  const _MobileSidebarDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mobileNavIndexProvider);

    return Drawer(
      backgroundColor: ScholarlyTheme.backgroundStart,
      surfaceTintColor: Colors.transparent,
      elevation: 16.0,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Elegant Drawer Header
          _buildHeader(context),
          
          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _DrawerTile(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () {
                    _navigate(ref, context, 0);
                  },
                ),
                _DrawerTile(
                  label: 'Arena',
                  icon: Icons.sports_esports_rounded,
                  isSelected: currentIndex == 1,
                  onTap: () {
                    _navigate(ref, context, 1);
                  },
                ),
                _DrawerTile(
                  label: 'Battleground',
                  icon: Icons.emoji_events_rounded,
                  isSelected: currentIndex == 2,
                  onTap: () {
                    _navigate(ref, context, 2);
                  },
                ),
                _DrawerTile(
                  label: 'Academy',
                  icon: Icons.school_rounded,
                  isSelected: currentIndex == 3,
                  onTap: () {
                    _navigate(ref, context, 3);
                  },
                ),
                _DrawerTile(
                  label: 'Puzzles',
                  icon: Icons.extension_rounded,
                  isSelected: currentIndex == 4,
                  onTap: () {
                    _navigate(ref, context, 4);
                  },
                ),
                _DrawerTile(
                  label: 'Analysis',
                  icon: Icons.science_rounded,
                  isSelected: currentIndex == 5,
                  onTap: () {
                    _navigate(ref, context, 5);
                  },
                ),
                _DrawerTile(
                  label: 'Archive',
                  icon: Icons.history_rounded,
                  isSelected: currentIndex == 6,
                  onTap: () {
                    _navigate(ref, context, 6);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                _DrawerTile(
                  label: 'Tutorial',
                  icon: Icons.menu_book_rounded,
                  isSelected: currentIndex == 7,
                  onTap: () {
                    _navigate(ref, context, 7);
                  },
                ),
                _DrawerTile(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  isSelected: currentIndex == 9,
                  onTap: () {
                    _navigate(ref, context, 9);
                  },
                ),
                _DrawerTile(
                  label: 'About Us',
                  icon: Icons.info_outline_rounded,
                  isSelected: currentIndex == 8,
                  onTap: () {
                    _navigate(ref, context, 8);
                  },
                ),
              ],
            ),
          ),
          
          // Drawer Footer with branding and version
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/splash/appicon.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ScholarlyTheme.accentBlue,
              ),
              child: const Icon(Icons.circle, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IDEASPACE CHESS ACADEMY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'powered by ',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Image.asset(
                'assets/splash/ideaspace.png',
                height: 12,
                errorBuilder: (context, error, stackTrace) => Text(
                  'ideaspace',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(WidgetRef ref, BuildContext context, int index) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
    final currentIndex = ref.read(mobileNavIndexProvider);
    if (currentIndex == 1 && index != 1) {
      final arenaState = ref.read(arenaProvider);
      if (arenaState.recentMoves.isNotEmpty && !arenaState.game.gameOver && !arenaState.isPaused) {
        ref.read(arenaProvider.notifier).togglePause();
      }
    }
    ref.read(mobileNavIndexProvider.notifier).state = index;
    Navigator.of(context).pop(); // Close drawer
  }
}

class _DrawerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        selected: isSelected,
        selectedTileColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.12),
        tileColor: Colors.transparent,
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class LazyIndexedStackChild extends StatefulWidget {
  const LazyIndexedStackChild({
    super.key,
    required this.isActive,
    required this.child,
  });

  final bool isActive;
  final Widget child;

  @override
  State<LazyIndexedStackChild> createState() => _LazyIndexedStackChildState();
}

class _LazyIndexedStackChildState extends State<LazyIndexedStackChild> {
  bool _initialized = false;

  @override
  void didUpdateWidget(covariant LazyIndexedStackChild oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_initialized) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized || widget.isActive) {
      _initialized = true;
      return widget.child;
    }
    return const SizedBox.shrink();
  }
}
