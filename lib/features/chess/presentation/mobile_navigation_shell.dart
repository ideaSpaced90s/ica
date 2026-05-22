import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/chess_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';

import 'dashboard_page.dart';
import 'main_page.dart';
import 'academy_page.dart';
import 'puzzle_page.dart';
import 'study_lab_page.dart';
import 'history_page.dart';

import 'unrated_settings_page.dart';
import 'tutorial_page.dart';
import 'about_us_page.dart';

// Provides the current active mobile tab index.
final mobileNavIndexProvider = StateProvider<int>((ref) => 0);

class MobileNavigationShell extends ConsumerWidget {
  const MobileNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mobileNavIndexProvider);
    final state = ref.watch(chessProvider);

    // IndexedStack children
    final List<Widget> pages = [
      const DashboardPage(),
      const MainPage(), // Handles both Rated and Unrated based on state.isRatedMode
      const AcademyPage(),
      const PuzzlePage(),
      const StudyLabPage(),
      const HistoryPage(),
      const TutorialPage(),
      const AboutUsPage(),
      const UnratedSettingsPage(),
    ];

    // Determine logical title based on active tab
    String getTitle() {
      switch (currentIndex) {
        case 0:
          return 'DASHBOARD';
        case 1:
          return state.isRatedMode ? 'RATED ARENA' : 'UNRATED ARENA';
        case 2:
          return 'ACADEMY';
        case 3:
          return 'PUZZLES';
        case 4:
          return 'STUDY LAB';
        case 5:
          return 'HISTORY';
        case 6:
          return 'TUTORIAL';
        case 7:
          return 'ABOUT US';
        case 8:
          return 'SETTINGS';
        default:
          return 'KINGSLAYER';
      }
    }

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        centerTitle: true,
        title: Text(
          getTitle(),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/board/appicon.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
      drawer: const _MobileSidebarDrawer(),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
    );
  }
}

class _MobileSidebarDrawer extends ConsumerWidget {
  const _MobileSidebarDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mobileNavIndexProvider);
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
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
                  label: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () {
                    _navigate(ref, context, 0);
                  },
                ),
                _DrawerTile(
                  label: 'Unrated Arena',
                  icon: Icons.sports_esports_rounded,
                  isSelected: currentIndex == 1 && !state.isRatedMode,
                  onTap: () {
                    notifier.setRatedMode(false);
                    _navigate(ref, context, 1);
                  },
                ),
                _DrawerTile(
                  label: 'Rated Arena',
                  icon: Icons.emoji_events_rounded,
                  isSelected: currentIndex == 1 && state.isRatedMode,
                  onTap: () {
                    notifier.setRatedMode(true);
                    _navigate(ref, context, 1);
                  },
                ),
                _DrawerTile(
                  label: 'Academy',
                  icon: Icons.school_rounded,
                  isSelected: currentIndex == 2,
                  onTap: () {
                    _navigate(ref, context, 2);
                  },
                ),
                _DrawerTile(
                  label: 'Puzzles',
                  icon: Icons.extension_rounded,
                  isSelected: currentIndex == 3,
                  onTap: () {
                    _navigate(ref, context, 3);
                  },
                ),
                _DrawerTile(
                  label: 'Study Lab',
                  icon: Icons.science_rounded,
                  isSelected: currentIndex == 4,
                  onTap: () {
                    _navigate(ref, context, 4);
                  },
                ),
                _DrawerTile(
                  label: 'History',
                  icon: Icons.history_rounded,
                  isSelected: currentIndex == 5,
                  onTap: () {
                    _navigate(ref, context, 5);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(color: Color(0x22FFFFFF), height: 1),
                ),
                _DrawerTile(
                  label: 'Tutorial',
                  icon: Icons.menu_book_rounded,
                  isSelected: currentIndex == 6,
                  onTap: () {
                    _navigate(ref, context, 6);
                  },
                ),
                _DrawerTile(
                  label: 'About Us',
                  icon: Icons.info_outline_rounded,
                  isSelected: currentIndex == 7,
                  onTap: () {
                    _navigate(ref, context, 7);
                  },
                ),
                _DrawerTile(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  isSelected: currentIndex == 8,
                  onTap: () {
                    _navigate(ref, context, 8);
                  },
                ),
              ],
            ),
          ),
          
          // Drawer Footer with branding and version
          _buildFooter(),
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
        color: Color(0xFF1E1E2C),
        border: Border(
          bottom: BorderSide(
            color: Color(0x11FFFFFF),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/board/appicon.png',
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
                  'KINGSLAYER',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Master Chess',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF13192B),
        border: Border(
          top: BorderSide(color: Color(0x11FFFFFF), width: 1.0),
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
                  color: Colors.white38,
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
                    color: Colors.white70,
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
              color: Colors.white24,
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
        selectedTileColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
        tileColor: Colors.transparent,
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? ScholarlyTheme.accentBlue : Colors.white60,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
