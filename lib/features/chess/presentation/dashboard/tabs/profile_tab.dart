import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/chess_provider.dart';
import '../../../application/battleground_provider.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../../widgets/daily_motivational_quote.dart';
import '../../widgets/profile_customization_overlay.dart';
import '../../widgets/progression_charts.dart';
import '../widgets/dashboard_widgets.dart';

class ProfileTab extends ConsumerWidget {
  final bool isMobile;

  const ProfileTab({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final bgState = ref.watch(battlegroundProvider);

    if (isMobile) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: () => showProfileCustomizationOverlay(context, ref),
                child: Container(
                  width: 140,
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.8),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: state.userAvatarPath.startsWith('assets/')
                        ? Image.asset(state.userAvatarPath, fit: BoxFit.cover)
                        : Image.file(
                            File(state.userAvatarPath),
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                          ),
                  ),
                ),
              ),
            ),
            const DailyMotivationalQuoteCard(),
            const SizedBox(height: 20),
            MasterCard(state: state, bgState: bgState),
            const SizedBox(height: 32),
            const JuicySectionHeader(
              title: 'ARENAS',
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.0,
              mainAxisSpacing: 16,
              children: [
                TierCard(
                  title: 'BULLET',
                  icon: Icons.bolt_rounded,
                  elo: bgState.bulletElo,
                  streak: bgState.bulletStreak,
                  classic: bgState.bulletGamesClassic,
                  dominance: bgState.bulletDominance,
                ),
                TierCard(
                  title: 'BLITZ',
                  icon: Icons.local_fire_department_rounded,
                  elo: bgState.blitzElo,
                  streak: bgState.blitzStreak,
                  classic: bgState.blitzGamesClassic,
                  dominance: bgState.blitzDominance,
                ),
                TierCard(
                  title: 'RAPID',
                  icon: Icons.timer_rounded,
                  elo: bgState.rapidElo,
                  streak: bgState.rapidStreak,
                  classic: bgState.rapidGamesClassic,
                  dominance: bgState.rapidDominance,
                ),
                const TimeControlCard(isMobile: true),
              ],
            ),
            if (bgState.totalWinningStreak > 0) ...[
              const SizedBox(height: 32),
              WinStreakBanner(bgState: bgState),
            ],
            const SizedBox(height: 32),
            const JuicySectionHeader(
              title: 'RECENT WINS',
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: 16),
            RecentMasterpieces(state: state),
            const SizedBox(height: 32),
            const JuicySectionHeader(
              title: 'ELO PROGRESS',
              icon: Icons.show_chart_rounded,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 268, child: EloAscentChart()),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    // Desktop: header is already shown above tab strip; profile tab = arenas + recent wins
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TierCard(
                title: 'BULLET',
                icon: Icons.bolt_rounded,
                elo: bgState.bulletElo,
                streak: bgState.bulletStreak,
                classic: bgState.bulletGamesClassic,
                dominance: bgState.bulletDominance,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TierCard(
                title: 'BLITZ',
                icon: Icons.local_fire_department_rounded,
                elo: bgState.blitzElo,
                streak: bgState.blitzStreak,
                classic: bgState.blitzGamesClassic,
                dominance: bgState.blitzDominance,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TierCard(
                title: 'RAPID',
                icon: Icons.timer_rounded,
                elo: bgState.rapidElo,
                streak: bgState.rapidStreak,
                classic: bgState.rapidGamesClassic,
                dominance: bgState.rapidDominance,
              ),
            ),
          ],
        ),
        if (bgState.totalWinningStreak > 0) ...[
          const SizedBox(height: 32),
          WinStreakBanner(bgState: bgState),
        ],
        const SizedBox(height: 32),
        const JuicySectionHeader(
          title: 'RECENT WINS',
          icon: Icons.workspace_premium_rounded,
        ),
        const SizedBox(height: 16),
        RecentMasterpieces(state: state),
        const SizedBox(height: 32),
        const JuicySectionHeader(
          title: 'ELO PROGRESS',
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 340, child: EloAscentChart()),
        const SizedBox(height: 32),
      ],
    );
  }
}
