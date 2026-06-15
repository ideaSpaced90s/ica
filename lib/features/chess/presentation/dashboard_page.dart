import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import '../application/battleground_provider.dart';
import '../application/arena_provider.dart';
import 'mobile_navigation_shell.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_scaffold.dart';
import 'widgets/profile_customization_overlay.dart';
import 'widgets/daily_motivational_quote.dart';
import 'dashboard/widgets/dashboard_widgets.dart';
import 'dashboard/tabs/profile_tab.dart';
import 'dashboard/tabs/history_30d_tab.dart';
import 'dashboard/tabs/repertoire_tab.dart';
import 'dashboard/tabs/playstyle_tab.dart';
import 'dashboard/tabs/scotoma_tab.dart';

// ── Tab definition ─────────────────────────────────────────────────────────────
class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef(this.label, this.icon);
}

const List<_TabDef> _kDashTabs = [
  _TabDef('STANDING', Icons.person_rounded),
  _TabDef('30D', Icons.calendar_today_rounded),
  _TabDef('REPERTOIRE', Icons.auto_stories_rounded),
  _TabDef('PLAYSTYLE', Icons.radar_rounded),
  _TabDef('SCOTOMA', Icons.visibility_off_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final bgState = ref.watch(battlegroundProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1100;

    return AmbientScaffold(
      blob1Color: const Color(0xFFDBEAFE),
      blob2Color: const Color(0xFFFEF3C7),
      blob3Color: const Color(0xFFF3E8FF),
      body: isMobile
          ? _buildMobileLayout(context, state, bgState)
          : _buildDesktopLayout(context, state, bgState),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(
    BuildContext context,
    ChessState state,
    BattlegroundState bgState,
  ) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              const ProfileTab(isMobile: true),
              const History30DTab(isMobile: true),
              const RepertoireTab(isMobile: true),
              const PlaystyleTab(isMobile: true),
              const ScotomaTab(isMobile: true),
            ],
          ),
        ),
        _buildMobileTabBar(),
      ],
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_kDashTabs.length, (i) {
              final tab = _kDashTabs[i];
              final isSelected = _selectedTab == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ScholarlyTheme.accentBlue.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        color: isSelected
                            ? ScholarlyTheme.accentBlue
                            : ScholarlyTheme.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: GoogleFonts.outfit(
                          color: isSelected
                              ? ScholarlyTheme.accentBlue
                              : ScholarlyTheme.textMuted,
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopLayout(
    BuildContext context,
    ChessState state,
    BattlegroundState bgState,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner (avatar + name + metrics)
            _buildHeaderSection(context, ref, state, bgState),
            const SizedBox(height: 20),
            // Horizontal pill tab strip
            _buildDesktopTabStrip(),
            const SizedBox(height: 28),
            // Active tab content
            _buildDesktopTabContent(state, bgState),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTabStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_kDashTabs.length, (i) {
          final tab = _kDashTabs[i];
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ScholarlyTheme.accentBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: ScholarlyTheme.accentBlue
                                .withValues(alpha: 0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      color: isSelected
                          ? Colors.white
                          : ScholarlyTheme.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab.label,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : ScholarlyTheme.textMuted,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.8,
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

  Widget _buildDesktopTabContent(ChessState state, BattlegroundState bgState) {
    switch (_selectedTab) {
      case 0:
        return const ProfileTab(isMobile: false);
      case 1:
        return const History30DTab(isMobile: false);
      case 2:
        return const RepertoireTab(isMobile: false);
      case 3:
        return const PlaystyleTab(isMobile: false);
      case 4:
        return const ScotomaTab(isMobile: false);
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DESKTOP HEADER BANNER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeaderSection(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
    BattlegroundState bgState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final profile = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => showProfileCustomizationOverlay(context, ref),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.8),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: state.userAvatarPath.startsWith('assets/')
                            ? Image.asset(state.userAvatarPath, fit: BoxFit.cover)
                            : Image.file(
                                File(state.userAvatarPath),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME BACK,',
                          style: GoogleFonts.outfit(
                            color: ScholarlyTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.userName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const DailyMotivationalQuoteCard(),
            ],
          );

          final metrics = Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              ConsolidatedEloCard(bgState: bgState),
              TotalMatchesCard(bgState: bgState),
              const GameModesCard(),
            ],
          );

          if (constraints.maxWidth < 1160) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [profile, const SizedBox(height: 20), metrics],
            );
          }

          return Row(
            children: [
              Expanded(child: profile),
              const SizedBox(width: 32),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
void exitToDashboardWithSidebar(BuildContext context, WidgetRef ref) {
  if (!context.mounted) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    try {
      final container = ProviderScope.containerOf(context);
      final currentIndex = container.read(mobileNavIndexProvider);
      if (currentIndex == 1) {
        final arenaState = container.read(arenaProvider);
        if (arenaState.recentMoves.isNotEmpty &&
            !arenaState.game.gameOver &&
            !arenaState.isPaused) {
          container.read(arenaProvider.notifier).togglePause();
        }
      } else if (currentIndex == 3) {
        container.read(chessProvider.notifier).initializeAcademySession();
      }
      container.read(mobileNavIndexProvider.notifier).state = 0;
    } catch (_) {
      if (ref.context.mounted) {
        final currentIndex = ref.read(mobileNavIndexProvider);
        if (currentIndex == 1) {
          final arenaState = ref.read(arenaProvider);
          if (arenaState.recentMoves.isNotEmpty &&
              !arenaState.game.gameOver &&
              !arenaState.isPaused) {
            ref.read(arenaProvider.notifier).togglePause();
          }
        } else if (currentIndex == 3) {
          ref.read(chessProvider.notifier).initializeAcademySession();
        }
        ref.read(mobileNavIndexProvider.notifier).state = 0;
      }
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  });
}
