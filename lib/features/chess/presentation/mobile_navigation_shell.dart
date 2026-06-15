import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/chess_provider.dart';
import '../application/battleground_provider.dart';
import '../application/arena_provider.dart';
import '../application/study_lab_provider.dart';
import '../services/chess_sound_service.dart';
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
import '../services/notification_service.dart';

import 'tutorial_page.dart';
import 'about_us_page.dart';
import 'settings_page.dart';
import 'store/store_page.dart';
import 'account_page.dart';

import 'widgets/welcome_guide_page.dart';
import 'widgets/sidebar_dynamic_bg.dart';
import 'widgets/hover_scale_effect.dart';
import '../application/onboarding_provider.dart';


// Provides the current active mobile tab index.
final mobileNavIndexProvider = StateProvider<int>((ref) => 0);

class MobileNavigationShell extends ConsumerWidget {
  const MobileNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    NotificationService.onNotificationClicked = (index) {
      ref.read(mobileNavIndexProvider.notifier).state = index;
    };

    final currentIndex = ref.watch(mobileNavIndexProvider);
    final bgState = ref.watch(battlegroundProvider);
    final isBgMatchActive = currentIndex == 2 && bgState.activeRatedMatchId != null;

    final academyState = ref.watch(chessProvider);
    final isAcademyMatchActive = currentIndex == 3 && academyState.recentMoves.isNotEmpty && !academyState.game.gameOver;
    final isDrawerDisabled = isBgMatchActive || isAcademyMatchActive;

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
                    _showUnsavedChangesOnMenuClick(ref, context);
                  } else {
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

  Future<void> _showUnsavedChangesOnMenuClick(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final notifier = ref.read(studyLabProvider.notifier);
    final state = ref.read(studyLabProvider);

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
            'Your study has unsaved changes. Would you like to save before opening the menu?',
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Stay', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            TextButton(
              onPressed: () {
                notifier.clearDirty();
                Navigator.pop(ctx);
                Scaffold.of(context).openDrawer();
              },
              child: Text(
                'Discard',
                style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 15, color: Colors.white),
              label: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (state.libraryIndex != null) {
                  final success = await notifier.saveExistingStudyInLibrary(state.libraryIndex!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Study saved successfully!' : 'Save failed.',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                      ),
                    );
                    if (success) {
                      Scaffold.of(context).openDrawer();
                    }
                  }
                } else {
                  _showSaveDialogOnMenuClick(ref, context, state, notifier);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSaveDialogOnMenuClick(
    WidgetRef ref,
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final defaultName = (state.metadata.event.isNotEmpty &&
            state.metadata.event != 'Study Lab Analysis')
        ? state.metadata.event
        : '';
    final controller = TextEditingController(text: defaultName);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.save_rounded, color: Color(0xFF00E676), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Save to Game Library',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give your progress a title to save it in the game library.',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Ruy Lopez Study, Endgame Practice...',
                  hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
                  filled: true,
                  fillColor: ScholarlyTheme.panelBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
              label: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final success = await notifier.saveCurrentGameToLibrary(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Study "$name" saved!' : 'Save failed.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                    ),
                  );
                  if (success) {
                    Scaffold.of(context).openDrawer();
                  }
                }
              },
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
                  onTap: () {
                    _navigate(ref, context, 0);
                  },
                ),
                _DrawerTile(
                  label: 'Assignment',
                  icon: Icons.assignment_turned_in_rounded,
                  isSelected: currentIndex == 11,
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
                _DrawerTile(
                  label: 'Tutorial',
                  icon: Icons.menu_book_rounded,
                  isSelected: currentIndex == 7,
                  onTap: () {
                    _navigate(ref, context, 7);
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
                  onTap: () {
                    _navigate(ref, context, 9);
                  },
                ),
                _DrawerTile(
                  label: 'Account',
                  icon: Icons.manage_accounts_rounded,
                  isSelected: currentIndex == 12,
                  onTap: () {
                    _navigate(ref, context, 12);
                  },
                ),
                _DrawerTile(
                  label: 'Store',
                  icon: Icons.storefront_rounded,
                  isSelected: currentIndex == 10,
                  onTap: () {
                    _navigate(ref, context, 10);
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
            const SizedBox(width: 12),
            Image.asset(
              'assets/splash/appicon.png',
              width: 96,
              height: 96,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScholarlyTheme.accentBlue,
                ),
                child: const Icon(Icons.circle, color: Colors.white, size: 54),
              ),
            ),
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
    final state = ref.read(studyLabProvider);

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
            'Your analysis study has unsaved changes. Save before leaving, or discard your work?',
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Stay', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
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
                style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 15, color: Colors.white),
              label: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx); // close unsaved dialog
                if (state.libraryIndex != null) {
                  final success = await notifier.saveExistingStudyInLibrary(state.libraryIndex!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Study saved successfully!' : 'Save failed.',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                      ),
                    );
                    if (success) {
                      ref.read(mobileNavIndexProvider.notifier).state = destinationIndex;
                      Navigator.of(context).pop(); // Close drawer
                    }
                  }
                } else {
                  _showSaveNameDialog(ref, context, state, notifier, destinationIndex);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSaveNameDialog(
    WidgetRef ref,
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    int destinationIndex,
  ) {
    final defaultName = (state.metadata.event.isNotEmpty &&
            state.metadata.event != 'Study Lab Analysis')
        ? state.metadata.event
        : '';
    final controller = TextEditingController(text: defaultName);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.save_rounded, color: Color(0xFF00E676), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Save to Game Library',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give your progress a title to save it in the game library.',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Ruy Lopez Study, Endgame Practice...',
                  hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
                  filled: true,
                  fillColor: ScholarlyTheme.panelBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
              label: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final success = await notifier.saveCurrentGameToLibrary(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Study "$name" saved!' : 'Save failed.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                    ),
                  );
                  if (success) {
                    ref.read(mobileNavIndexProvider.notifier).state = destinationIndex;
                    Navigator.of(context).pop(); // close drawer
                  }
                }
              },
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
  final Widget? trailing;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
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
