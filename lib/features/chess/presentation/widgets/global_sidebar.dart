import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../../application/chess_provider.dart';
import '../academy_page.dart';
import '../settings_page.dart';
import '../tutorial_page.dart';
import '../dashboard_page.dart';
import '../history_page.dart';




class GlobalSidebar extends ConsumerWidget {
  const GlobalSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Stack(
        children: [
          // Blurry Glass Background
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.panelBase.withValues(alpha: 0.7),
                    border: const Border(
                      right: BorderSide(
                        color: ScholarlyTheme.panelStroke,
                        width: 1,
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
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DashboardPage()),
                          );
                        },
                      ),
                      const Divider(height: 24, color: ScholarlyTheme.panelStroke),
                      _SidebarItem(
                        icon: Icons.grid_view_rounded,
                        label: 'UnRated Arena',
                        isSelected: !state.isRatedMode && !state.isAcademyActive && !state.isPuzzleMode,
                        onTap: () async {
                          Navigator.pop(context);
                          await notifier.setRatedMode(false);
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.emoji_events_rounded,
                        label: 'Rated Arena',
                        isSelected: state.isRatedMode && !state.isAcademyActive && !state.isPuzzleMode,
                        onTap: () async {
                          Navigator.pop(context);
                          await notifier.setRatedMode(true);
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.history_rounded,
                        label: 'Analysis',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HistoryPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _SidebarItem(
                        icon: Icons.school_rounded,
                        label: 'Academy',
                        isSelected: state.isAcademyActive && !state.isPuzzleMode,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const AcademyPage()),
                          );
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.extension_rounded,
                        label: 'Puzzles',
                        isSelected: state.isPuzzleMode,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AcademyPage(startInPuzzleMode: true),
                            ),
                          );
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.menu_book_rounded,
                        label: 'Tutorial',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const TutorialPage()),
                          );
                        },
                      ),
                      const Divider(height: 24, color: ScholarlyTheme.panelStroke),
                      _SidebarItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                          );
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
        'v1.0.0 • Alpha Build',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: ScholarlyTheme.textSubtle,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? ScholarlyTheme.accentBlueSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
