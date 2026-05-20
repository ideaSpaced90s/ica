import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../main_page.dart';
import '../academy_page.dart';
import '../settings_page.dart';
import '../rated_settings_page.dart';
import '../tutorial_page.dart';
import '../dashboard_page.dart';
import '../history_page.dart';
import '../about_us_page.dart';
import 'ambient_flow_backdrop.dart';




class GlobalSidebar extends ConsumerWidget {
  const GlobalSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    final isDashboard = context.findAncestorWidgetOfExactType<DashboardPage>() != null;
    final isMain = context.findAncestorWidgetOfExactType<MainPage>() != null;
    final isAnalysis = context.findAncestorWidgetOfExactType<HistoryPage>() != null;
    final isAcademy = context.findAncestorWidgetOfExactType<AcademyPage>() != null && state.isAcademyActive && !state.isPuzzleMode;
    final isPuzzles = context.findAncestorWidgetOfExactType<AcademyPage>() != null && state.isPuzzleMode;
    final isTutorial = context.findAncestorWidgetOfExactType<TutorialPage>() != null;
    final isSettings = context.findAncestorWidgetOfExactType<SettingsPage>() != null;
    final isAbout = context.findAncestorWidgetOfExactType<AboutUsPage>() != null;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Stack(
        children: [
          // Ambient aurora glow background
          const Positioned.fill(
            child: AmbientFlowBackdrop(
              blob1Color: Color(0xFFDBEAFE), // Soft Blue
              blob2Color: Color(0xFFFEF3C7), // Soft Amber
              blob3Color: Color(0xFFF3E8FF), // Soft Purple
            ),
          ),
          // Blurry Glass Background
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.40),
                    border: const Border(
                      right: BorderSide(
                        color: Colors.white54,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _SidebarItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isSelected: isDashboard,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isDashboard) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const DashboardPage()),
                            );
                          }
                        },
                      ),
                      const Divider(height: 24, color: ScholarlyTheme.panelStroke),
                      _SidebarItem(
                        icon: Icons.grid_view_rounded,
                        label: 'UnRated Arena',
                        isSelected: isMain && !state.isRatedMode && !state.isAcademyActive && !state.isPuzzleMode,
                        onTap: () async {
                          Navigator.pop(context);
                          await notifier.setRatedMode(false);
                          if (context.mounted && !isMain) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const MainPage()),
                            );
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.emoji_events_rounded,
                        label: 'Rated Arena',
                        isSelected: isMain && state.isRatedMode && !state.isAcademyActive && !state.isPuzzleMode,
                        onTap: () async {
                          Navigator.pop(context);
                          await notifier.setRatedMode(true);
                          if (context.mounted && !isMain) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const MainPage()),
                            );
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.history_rounded,
                        label: 'History',
                        isSelected: isAnalysis,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isAnalysis) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const HistoryPage()),
                            );
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.school_rounded,
                        label: 'Academy',
                        isSelected: isAcademy,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isAcademy || state.isPuzzleMode) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AcademyPage()),
                            );
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.extension_rounded,
                        label: 'Puzzles',
                        isSelected: isPuzzles,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isPuzzles || !state.isPuzzleMode) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AcademyPage(startInPuzzleMode: true),
                              ),
                            );
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.menu_book_rounded,
                        label: 'Tutorial',
                        isSelected: isTutorial,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isTutorial) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const TutorialPage()),
                            );
                          }
                        },
                      ),
                      const Divider(height: 24, color: ScholarlyTheme.panelStroke),
                      _SidebarItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        isSelected: isSettings,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isSettings) {
                            if (state.isRatedMode) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RatedSettingsPage()),
                              );
                            } else if (state.isAcademyActive || state.isPuzzleMode) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const SettingsPage(isAcademyMode: true)),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const SettingsPage()),
                              );
                            }
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About Us',
                        isSelected: isAbout,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isAbout) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AboutUsPage()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/board/appicon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'KINGSLAYER: CHESS',
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Text(
        'v1.0.0 • KINGSLAYER ©',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: ScholarlyTheme.textSubtle,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SidebarItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? ScholarlyTheme.accentBlue.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? ScholarlyTheme.accentBlue.withValues(alpha: 0.25) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          ListTile(
            onTap: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
              onTap();
            },
            leading: Icon(
              icon,
              color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary.withValues(alpha: 0.7),
              size: 22,
            ),
            title: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (isSelected)
            Positioned(
              left: 4,
              top: 14,
              bottom: 14,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlue,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(1, 0),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
