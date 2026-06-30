import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/chess_provider.dart';
import '../application/battleground_provider.dart';
import '../application/arena_provider.dart';
import '../application/study_lab_provider.dart';
import '../services/chess_sound_service.dart';
import '../services/analytics_service.dart';
import 'scholarly_theme.dart';

import 'dashboard_page.dart';
import 'arena/arena_page.dart';
import 'battleground/battleground_page.dart';
import 'academy/academy_page.dart';
import 'puzzles/puzzles_page.dart';
import 'analysis/analysis_page.dart';
import 'history_page.dart';
import 'assignment/assignment_page.dart';
import '../application/assignment_provider.dart';
import '../domain/models/assignment_state.dart';
import 'tutorial_page.dart';
import 'about_us_page.dart';
import 'settings_page.dart';
import 'store/store_page.dart';
import 'account_page.dart';
import 'achievements_page.dart';


import 'widgets/welcome_guide_page.dart';
import 'widgets/sidebar_dynamic_bg.dart';
import 'widgets/hover_scale_effect.dart';
import '../application/onboarding_provider.dart';
import 'shared/page_transition_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';


import '../application/navigation_provider.dart';
import '../application/update_provider.dart';
import 'widgets/update_check_tile.dart' show PulsingDotIndicator;
export '../application/navigation_provider.dart';


class MobileNavigationShell extends ConsumerStatefulWidget {
  const MobileNavigationShell({super.key});

  @override
  ConsumerState<MobileNavigationShell> createState() => _MobileNavigationShellState();
}

class _MobileNavigationShellState extends ConsumerState<MobileNavigationShell> {
  DailyTask? _completedTaskBanner;
  late DateTime _lastTabChangeTime;

  @override
  void initState() {
    super.initState();
    _lastTabChangeTime = DateTime.now();
    
    // Log the initial tab view (usually index 0, Dashboard) after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialIndex = ref.read(mobileNavIndexProvider);
      ref.read(analyticsServiceProvider).logScreenView(
        screenName: _getTabName(initialIndex),
      );
    });
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Arena';
      case 2:
        return 'Battleground';
      case 3:
        return 'Academy';
      case 4:
        return 'Puzzles';
      case 5:
        return 'Analysis';
      case 6:
        return 'Archive';
      case 7:
        return 'Tutorial';
      case 8:
        return 'About Us';
      case 9:
        return 'Settings';
      case 10:
        return 'Store';
      case 11:
        return 'Assignment';
      case 12:
        return 'Account';
      case 13:
        return 'Achievements';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to tab changes to log screen views and duration spent on previous tab
    ref.listen<int>(mobileNavIndexProvider, (previous, next) {
      final now = DateTime.now();
      final duration = now.difference(_lastTabChangeTime);
      _lastTabChangeTime = now;

      // Log duration of previous section
      if (previous != null) {
        final previousTabName = _getTabName(previous);
        ref.read(analyticsServiceProvider).logTimeSpent(
          sectionName: previousTabName.toLowerCase(),
          durationSeconds: duration.inSeconds,
        );
      }

      // Log screen view of next section
      final nextTabName = _getTabName(next);
      ref.read(analyticsServiceProvider).logScreenView(
        screenName: nextTabName,
      );
    });

    final currentIndex = ref.watch(mobileNavIndexProvider);
    final bgState = ref.watch(battlegroundProvider);
    final isBgMatchActive = currentIndex == 2 && bgState.activeRatedMatchId != null;

    final academyState = ref.watch(chessProvider);
    final isAcademyMatchActive = currentIndex == 3 && academyState.recentMoves.isNotEmpty && !academyState.game.gameOver;
    final isDrawerDisabled = isBgMatchActive || isAcademyMatchActive;

    // Listen to assignment provider for task completion
    ref.listen<AssignmentState>(assignmentProvider, (previous, next) {
      if (next.newlyCompletedTaskIndex >= 0 &&
          (previous == null || previous.newlyCompletedTaskIndex != next.newlyCompletedTaskIndex)) {
        if (currentIndex != 11) { // If not on Assignment Page
          setState(() {
            _completedTaskBanner = next.dailyTasks[next.newlyCompletedTaskIndex];
          });
        }
      }
    });

    // Mute background music when in Battleground (2)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isMuted = currentIndex == 2;
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
      const StorePage(),
      const AssignmentPage(),
      const AccountPage(),
      const AchievementsPage(),
    ];

    // Determine logical title based on active tab
    String getTitle() {
      switch (currentIndex) {
        case 0:
          return 'DASHBOARD';
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
        case 10:
          return 'STORE';
        case 11:
          return 'ASSIGNMENT';
        case 12:
          return 'ACCOUNT';
        case 13:
          return 'ACHIEVEMENTS';
        default:
          return 'IDEASPACE CHESS ACADEMY';
      }
    }

    final showWelcome = ref.watch(showWelcomeDialogProvider);

    Widget result = Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      drawerEnableOpenDragGesture: !isDrawerDisabled,
      appBar: AppBar(
        backgroundColor: ScholarlyTheme.backgroundStart,
        elevation: 0,
        centerTitle: true,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: Text(
            getTitle(),
            key: ValueKey<int>(currentIndex),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: ScholarlyTheme.textPrimary,
            ),
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
                final isMatchActive = isBattleground && bgState.activeRatedMatchId != null;
                
                if (isMatchActive) {
                  final resigned = await showRatedExitDialog(context);
                  if (resigned == true) {
                    await ref.read(battlegroundProvider.notifier).resignRatedGame();
                    if (context.mounted) {
                      exitToDashboardWithSidebar(context, ref);
                    }
                  }
                } else if (isAcademyMatchActive) {
                  final confirm = await showAcademyExitDialog(context, hasActiveMatch: true);
                  if (confirm == true) {
                    if (context.mounted) {
                      await ref.read(chessProvider.notifier).initializeAcademySession();
                      if (context.mounted) {
                        exitToDashboardWithSidebar(context, ref);
                      }
                    }
                  }
                } else if (currentIndex == 5) {
                  final studyState = ref.read(studyLabProvider);
                  if (studyState.isDirty && studyState.nodes.isNotEmpty) {
                    _showUnsavedChangesOnMenuClick(context);
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                } else if (currentIndex == 7) {
                  // Tutorial page: show the GM Chanakya exit prompt when mid-lesson.
                  // showTutorialExitPrompt returns false if on chapter select / completion overlay,
                  // in which case we fall through to open the drawer normally.
                  final tutorialHandled = await showTutorialExitPrompt(context, ref);
                  if (!tutorialHandled && context.mounted) {
                    Scaffold.of(context).openDrawer();
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
      body: Stack(
        children: [
          IndexedStack(
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
          const IgnorePointer(
            child: PageTransitionOverlay(),
          ),
          if (_completedTaskBanner != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: JuicyCompletionBanner(
                task: _completedTaskBanner!,
                onDismiss: () {
                  setState(() {
                    _completedTaskBanner = null;
                  });
                  ref.read(assignmentProvider.notifier).clearCompletionAnimation();
                },
              ),
            ),
        ],
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

    final overrides = ref.watch(backButtonOverridesProvider);
    final activeOverride = overrides[currentIndex];

    result = PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (activeOverride != null) {
          final handled = await activeOverride();
          if (handled) return;
        }
        if (!context.mounted) return;
        if (currentIndex != 0) {
          exitToDashboardWithSidebar(context, ref);
        } else {
          final exitApp = await showExitAppConfirmationDialog(context);
          if (exitApp == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: result,
    );

    return result;
  }

  Future<void> _showUnsavedChangesOnMenuClick(
    BuildContext context,
  ) async {
    final notifier = ref.read(studyLabProvider.notifier);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.6), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unsaved Changes',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your research has unsaved changes. Would you like to save before you leave?',
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, height: 1.5),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Stay',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    notifier.clearDirty();
                    Navigator.pop(ctx);
                    Scaffold.of(context).openDrawer();
                  },
                  child: Text(
                    'Discard',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}

class _MobileSidebarDrawer extends ConsumerWidget {
  const _MobileSidebarDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mobileNavIndexProvider);
    final assignmentState = ref.watch(assignmentProvider);
    final pendingCount = assignmentState.dailyTasks.where((task) => !task.isCompleted).length;
    final hasUpdate = ref.watch(updateProvider).hasUpdateBadge;

    return Drawer(
      backgroundColor: Colors.transparent,
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
      child: Stack(
        children: [
          const SidebarDynamicBg(),
          Column(
            children: [
              // Elegant Drawer Header
              _buildHeader(context),
          
          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                // Top Group: Dashboard
                _DrawerTile(
                  label: 'Dashboard',
                  icon: Icons.space_dashboard_rounded,
                  isSelected: currentIndex == 0,
                  index: 0,
                  onTap: () {
                    _navigate(ref, context, 0);
                  },
                ),
                _DrawerTile(
                  label: 'Assignment',
                  icon: Icons.assignment_turned_in_rounded,
                  isSelected: currentIndex == 11,
                  index: 1,
                  trailing: pendingCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    _navigate(ref, context, 11);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                // Upper Group
                _DrawerTile(
                  label: 'Arena',
                  icon: Icons.sports_esports_rounded,
                  isSelected: currentIndex == 1,
                  index: 2,
                  onTap: () {
                    _navigate(ref, context, 1);
                  },
                ),
                _DrawerTile(
                  label: 'Battleground',
                  icon: Icons.emoji_events_rounded,
                  isSelected: currentIndex == 2,
                  index: 3,
                  onTap: () {
                    _navigate(ref, context, 2);
                  },
                ),
                _DrawerTile(
                  label: 'Academy',
                  icon: Icons.school_rounded,
                  isSelected: currentIndex == 3,
                  index: 4,
                  onTap: () {
                    _navigate(ref, context, 3);
                  },
                ),
                _DrawerTile(
                  label: 'Puzzles',
                  icon: Icons.extension_rounded,
                  isSelected: currentIndex == 4,
                  index: 5,
                  onTap: () {
                    _navigate(ref, context, 4);
                  },
                ),
                _DrawerTile(
                  label: 'Analysis',
                  icon: Icons.science_rounded,
                  isSelected: currentIndex == 5,
                  index: 6,
                  onTap: () {
                    _navigate(ref, context, 5);
                  },
                ),
                _DrawerTile(
                  label: 'Archive',
                  icon: Icons.history_rounded,
                  isSelected: currentIndex == 6,
                  index: 7,
                  onTap: () {
                    _navigate(ref, context, 6);
                  },
                ),
                _DrawerTile(
                  label: 'Tutorial',
                  icon: Icons.menu_book_rounded,
                  isSelected: currentIndex == 7,
                  index: 8,
                  onTap: () {
                    _navigate(ref, context, 7);
                  },
                ),
                _DrawerTile(
                  label: 'Achievements',
                  icon: Icons.military_tech_rounded,
                  isSelected: currentIndex == 13,
                  index: 13,
                  onTap: () {
                    _navigate(ref, context, 13);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                // Settings, Store, About Us Group
                 _DrawerTile(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  isSelected: currentIndex == 9,
                  index: 9,
                  trailing: hasUpdate ? const PulsingDotIndicator(color: Colors.redAccent) : null,
                  onTap: () {
                    _navigate(ref, context, 9);
                  },
                ),
                _DrawerTile(
                  label: 'Account',
                  icon: Icons.manage_accounts_rounded,
                  isSelected: currentIndex == 12,
                  index: 10,
                  onTap: () {
                    _navigate(ref, context, 12);
                  },
                ),
                _DrawerTile(
                  label: 'Store',
                  icon: Icons.storefront_rounded,
                  isSelected: currentIndex == 10,
                  index: 11,
                  onTap: () {
                    _navigate(ref, context, 10);
                  },
                ),
                _DrawerTile(
                  label: 'About Us',
                  icon: Icons.info_outline_rounded,
                  isSelected: currentIndex == 8,
                  index: 12,
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 12,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ICA',
                    style: GoogleFonts.pirataOne(
                      fontSize: 34, // Slightly enlarged to look bold and clean in Pirata One
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ideaspace Chess Academy',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const _FloatingAppIcon(size: 86),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.transparent,
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
                height: 27,
                errorBuilder: (context, error, stackTrace) => Text(
                  'ideaspace',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.18',
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

    // If navigating away from the Academy tab, reset the academy session so a new class starts when they return
    if (currentIndex == 3 && index != 3) {
      ref.read(chessProvider.notifier).initializeAcademySession();
    }

    // If navigating away from the Analysis tab, check for unsaved changes
    if (currentIndex == 5 && index != 5) {
      final studyState = ref.read(studyLabProvider);
      if (studyState.isDirty && studyState.nodes.isNotEmpty) {
        _showUnsavedChangesOnNavigate(ref, context, index);
        return;
      }
    }

    ref.read(mobileNavIndexProvider.notifier).state = index;
    Navigator.of(context).pop(); // Close drawer
  }

  Future<void> _showUnsavedChangesOnNavigate(
    WidgetRef ref,
    BuildContext context,
    int destinationIndex,
  ) async {
    final notifier = ref.read(studyLabProvider.notifier);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.6), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unsaved Changes',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your research has unsaved changes. Would you like to save before you leave?',
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, height: 1.5),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Stay',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    notifier.clearDirty();
                    Navigator.pop(ctx);
                    // Perform the navigation
                    ref.read(mobileNavIndexProvider.notifier).state = destinationIndex;
                    Navigator.of(context).pop(); // Close drawer
                  },
                  child: Text(
                    'Discard',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}

class _DrawerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final Widget? trailing;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.index,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: HoverScaleEffect(
        scale: 1.02, // Subtle scale for sidebar tabs
        child: ListTile(
          dense: false,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -1.5),
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
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
            ),
          ),
          trailing: trailing,
        ),
      ),
    )
    .animate(delay: (index * 28).ms)
    .fadeIn(duration: 160.ms)
    .slideX(begin: -0.04, end: 0.0, duration: 160.ms, curve: Curves.easeOut)
    .animate(key: ValueKey(isSelected))
    .scale(
      begin: const Offset(0.96, 0.96),
      end: const Offset(1.0, 1.0),
      duration: 180.ms,
      curve: Curves.easeOutBack,
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

Future<bool?> showExitAppConfirmationDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelBase,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context, true),
                customBorder: const CircleBorder(),
                splashColor: Colors.redAccent.withValues(alpha: 0.2),
                highlightColor: Colors.redAccent.withValues(alpha: 0.1),
                child: Ink(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.25),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: Colors.redAccent,
                      size: 58,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'EXIT',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: ScholarlyTheme.textPrimary,
                fontSize: 16,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Floating app icon with drop-shadow animation — mirrors the splash screen effect.
class _FloatingAppIcon extends StatefulWidget {
  const _FloatingAppIcon({required this.size});
  final double size;

  @override
  State<_FloatingAppIcon> createState() => _FloatingAppIconState();
}

class _FloatingAppIconState extends State<_FloatingAppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatVal = _floatAnimation.value; // -6 to +6
        // When icon floats UP (floatVal < 0): shadow is smaller & lighter
        // When icon floats DOWN (floatVal > 0): shadow is wider & darker
        final shadowWidth = (s * 0.65 - floatVal * 1.8).clamp(s * 0.30, s * 0.75);
        final shadowOpacity = (0.28 - floatVal / (s * 1.8)).clamp(0.10, 0.38);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Knight floating in its own fixed-height slot
            SizedBox(
              width: s,
              height: s,
              child: Transform.translate(
                offset: Offset(0, floatVal),
                child: Image.asset(
                  'assets/splash/appicon_foreground.png',
                  width: s,
                  height: s,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Shadow sits BELOW the knight — no overlap
            SizedBox(
              height: 10,
              child: Center(
                child: Opacity(
                  opacity: shadowOpacity,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 3),
                    child: Container(
                      width: shadowWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
