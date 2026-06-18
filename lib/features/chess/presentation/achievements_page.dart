import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../application/battleground_provider.dart';
import '../application/chess_provider.dart';
import '../application/lifetime_xp_provider.dart';
import '../domain/models/ai_avatar.dart';
import '../domain/models/lifetime_xp_state.dart';
import '../domain/performance_ledger_entry.dart';
import 'mobile_navigation_shell.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_scaffold.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  static const _shareUrl = 'https://ideaspaceapps.store/chessacademy.html';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chessState = ref.watch(chessProvider);
    final bgState = ref.watch(battlegroundProvider);
    final wins = bgState.cachedLedgerEntries
        .where(
          (entry) =>
              entry.source == PerformanceLedgerEntry.ratedBattlegroundSource &&
              entry.result == 'W',
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final xpState = ref.watch(lifetimeXpProvider);
    final xpNotifier = ref.watch(lifetimeXpProvider.notifier);

    return AmbientScaffold(
      blob1Color: const Color(0xFFFFF7D6),
      blob2Color: const Color(0xFFE0F2FE),
      blob3Color: const Color(0xFFEDE9FE),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: _AchievementHeader(
                  userName: chessState.userName,
                  avatarPath: chessState.userAvatarPath,
                  elo: bgState.consolidatedRating,
                  streak: bgState.totalWinningStreak,
                  xpState: xpState,
                  xpNotifier: xpNotifier,
                ),
              ),
            ),
            if (wins.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyAchievements(
                  onBattleground: () {
                    ref.read(mobileNavIndexProvider.notifier).state = 2;
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width >= 980
                        ? 3
                        : width >= 640
                            ? 2
                            : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: crossAxisCount == 1 ? 1.42 : 0.92,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final achievement = _VictoryAchievement.fromEntry(
                            wins[index],
                            chessState.userName,
                            chessState.userAvatarPath,
                          );
                          return _VictoryCard(
                            achievement: achievement,
                            onTap: () => _showAchievementDetail(
                              context,
                              achievement,
                            ),
                          );
                        },
                        childCount: wins.length,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }



  void _showAchievementDetail(
    BuildContext context,
    _VictoryAchievement achievement,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close achievement',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AchievementDetailPage(achievement: achievement);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _VictoryAchievement {
  final PerformanceLedgerEntry entry;
  final AiAvatar opponent;
  final String userName;
  final String userAvatarPath;
  final String finalMove;
  final int cardXp;
  final String report;

  const _VictoryAchievement({
    required this.entry,
    required this.opponent,
    required this.userName,
    required this.userAvatarPath,
    required this.finalMove,
    required this.cardXp,
    required this.report,
  });

  factory _VictoryAchievement.fromEntry(
    PerformanceLedgerEntry entry,
    String userName,
    String userAvatarPath,
  ) {
    final opponent = AiAvatar.avatars.firstWhere(
      (avatar) => avatar.name.toLowerCase() == entry.opponentName.toLowerCase(),
      orElse: () => AiAvatar.getBestMatch(entry.ratingSnapshot),
    );
    final finalMove = entry.uciMoves.isNotEmpty
        ? entry.uciMoves.last
        : entry.recentMoves.isNotEmpty
            ? entry.recentMoves.last
            : 'Final move';
    final timeoutWin = entry.whiteTimeLeftMs == 0 || entry.blackTimeLeftMs == 0;
    final report = _buildReport(entry, finalMove, timeoutWin);
    final cardXp = 120 +
        (opponent.rating / 22).round() +
        entry.recentMoves.length +
        (entry.dominance.clamp(0.0, 8.0) * 10).round();

    return _VictoryAchievement(
      entry: entry,
      opponent: opponent,
      userName: userName,
      userAvatarPath: userAvatarPath,
      finalMove: finalMove,
      cardXp: cardXp,
      report: report,
    );
  }

  static String _buildReport(
    PerformanceLedgerEntry entry,
    String finalMove,
    bool timeoutWin,
  ) {
    if (timeoutWin) {
      return 'You kept the position alive under clock pressure and forced the opponent to run out of time. The final phase rewarded patience and tempo control.';
    }
    if (entry.dominance >= 3.0) {
      return 'You converted a clear material and space edge. The victory move $finalMove sealed a game where the board gradually moved to your side.';
    }
    if (entry.dominance <= 0.0) {
      return 'This was a resourceful win. The position was not simply handed over, but your final move $finalMove turned resistance into a result.';
    }
    return 'You built enough pressure to guide the ending in your favor. The final move $finalMove marked the moment the advantage became permanent.';
  }
}

class _AchievementHeader extends StatelessWidget {
  const _AchievementHeader({
    required this.userName,
    required this.avatarPath,
    required this.elo,
    required this.streak,
    required this.xpState,
    required this.xpNotifier,
  });

  final String userName;
  final String avatarPath;
  final int elo;
  final int streak;
  final LifetimeXpState xpState;
  final LifetimeXpNotifier xpNotifier;

  @override
  Widget build(BuildContext context) {
    final currentLevel = xpNotifier.currentLevel;
    final levelTitle = xpNotifier.currentLevelTitle;
    final xp = xpState.totalXp;
    final startXp = xpNotifier.xpForCurrentLevelStart;
    final nextXp = xpNotifier.xpForNextLevelStart;
    
    // Progress calculation
    double progress = 0.0;
    if (nextXp > startXp) {
      progress = (xp - startXp) / (nextXp - startXp);
    }
    progress = progress.clamp(0.0, 1.0);
    final neededXp = nextXp - xp;

    // Get gems/colors based on level
    final Color levelColor;
    final IconData gemIcon;
    switch (currentLevel) {
      case 1: levelColor = Colors.grey; gemIcon = Icons.star_border_rounded; break;
      case 2: levelColor = const Color(0xFF92400E); gemIcon = Icons.stars_rounded; break;
      case 3: levelColor = const Color(0xFF6B7280); gemIcon = Icons.diamond_rounded; break;
      case 4: levelColor = const Color(0xFF0D6EFD); gemIcon = Icons.diamond_outlined; break;
      case 5: levelColor = const Color(0xFFD97706); gemIcon = Icons.workspace_premium_rounded; break;
      case 6: levelColor = const Color(0xFF0F766E); gemIcon = Icons.shield_rounded; break;
      case 7: levelColor = const Color(0xFF6B21A8); gemIcon = Icons.military_tech_rounded; break;
      case 8: levelColor = const Color(0xFF991B1B); gemIcon = Icons.emoji_events_rounded; break;
      default: levelColor = Colors.blue; gemIcon = Icons.bolt_rounded;
    }

    return JuicyGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            children: [
              _UserAvatar(path: avatarPath, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '⚡ LIFETIME XP',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    PremiumGradientText(
                      '${NumberFormat("#,###").format(xp)} XP',
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Career Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(gemIcon, color: levelColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Level $currentLevel — $levelTitle',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (currentLevel < 8)
                Text(
                  '${NumberFormat("#,###").format(neededXp)} XP to next level',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ScholarlyTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'Max Career Title reached!',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
              color: levelColor,
            ),
          ),
          const SizedBox(height: 20),

          // Source breakdown
          const Divider(color: ScholarlyTheme.panelStroke, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _XpSourceColumn('⚔️ Wins', '+${NumberFormat("#,###").format(xpNotifier.winsXp)}'),
              _XpSourceColumn('🧩 Puzzles', '+${NumberFormat("#,###").format(xpNotifier.puzzlesXp)}'),
              _XpSourceColumn('🎬 Cinema', '+${NumberFormat("#,###").format(xpNotifier.cinemaXp)}'),
              _XpSourceColumn('📝 Reviews', '+${NumberFormat("#,###").format(xpNotifier.reviewsXp)}'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: ScholarlyTheme.panelStroke, height: 1),
          const SizedBox(height: 14),

          // Elo & Streak Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatMiniChip(label: 'CURRENT ELO', value: '$elo', icon: Icons.speed_rounded, color: ScholarlyTheme.accentBlue),
              Container(height: 20, width: 1, color: ScholarlyTheme.panelStroke),
              _StatMiniChip(label: 'WINNING STREAK', value: '$streak', icon: Icons.local_fire_department_rounded, color: const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _XpSourceColumn extends StatelessWidget {
  final String title;
  final String value;

  const _XpSourceColumn(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
        ),
      ],
    );
  }
}

class _StatMiniChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatMiniChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9, color: ScholarlyTheme.textMuted, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

class _VictoryCard extends StatelessWidget {
  const _VictoryCard({required this.achievement, required this.onTap});

  final _VictoryAchievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entry = achievement.entry;
    final date = DateFormat('MMM d, yyyy').format(entry.timestamp);
    final isLightColor = achievement.opponent.color.computeLuminance() > 0.58;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: achievement.opponent.color.withValues(alpha: 0.48),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: achievement.opponent.color.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.18,
                    child: buildAvatarImage(
                      achievement.opponent.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.96),
                          achievement.opponent.color.withValues(alpha: 0.14),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: achievement.opponent.color,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: buildAvatarImage(
                                achievement.opponent.imagePath,
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
                                  'VICTORY OVER',
                                  style: GoogleFonts.outfit(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                Text(
                                  achievement.opponent.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: ScholarlyTheme.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: achievement.opponent.color,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '+${achievement.cardXp} XP',
                              style: GoogleFonts.jetBrainsMono(
                                color: isLightColor ? Colors.black87 : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        achievement.report,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniBadge(
                            icon: Icons.calendar_today_rounded,
                            label: date,
                          ),
                          _MiniBadge(
                            icon: Icons.speed_rounded,
                            label: 'ELO ${entry.ratingSnapshot}',
                          ),
                          _MiniBadge(
                            icon: Icons.flag_rounded,
                            label: achievement.finalMove,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementDetailPage extends StatelessWidget {
  const _AchievementDetailPage({required this.achievement});

  final _VictoryAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final entry = achievement.entry;
    final date = DateFormat('MMMM d, yyyy').format(entry.timestamp);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      achievement.opponent.color.withValues(alpha: 0.20),
                      Colors.white,
                      const Color(0xFFFFF7D6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 58, 18, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: achievement.opponent.color.withValues(
                                alpha: 0.55,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: achievement.opponent.color.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1.7,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      buildAvatarImage(
                                        achievement.opponent.imagePath,
                                        fit: BoxFit.cover,
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withValues(alpha: 0.1),
                                              Colors.black.withValues(alpha: 0.78),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 20,
                                        right: 20,
                                        bottom: 18,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'BATTLEGROUND VICTORY',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFFFFD166),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.4,
                                              ),
                                            ),
                                            Text(
                                              '${achievement.userName} defeated ${achievement.opponent.name}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          _UserAvatar(
                                            path: achievement.userAvatarPath,
                                            size: 46,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  achievement.userName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    color: ScholarlyTheme
                                                        .textPrimary,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                  ),
                                                ),
                                                Text(
                                                  date,
                                                  style: GoogleFonts.inter(
                                                    color: ScholarlyTheme
                                                        .textMuted,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed: () =>
                                                _shareAchievement(context),
                                            icon: const Icon(
                                              Icons.ios_share_rounded,
                                              size: 17,
                                            ),
                                            label: Text(
                                              'Share',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  ScholarlyTheme.accentBlue,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _StatChip(
                                            label: 'POST ELO',
                                            value: '${entry.ratingSnapshot}',
                                            icon: Icons.speed_rounded,
                                          ),
                                          _StatChip(
                                            label: 'CARD XP',
                                            value: '${achievement.cardXp}',
                                            icon: Icons.bolt_rounded,
                                          ),
                                          _StatChip(
                                            label: 'FINAL MOVE',
                                            value: achievement.finalMove,
                                            icon: Icons.flag_rounded,
                                          ),
                                          _StatChip(
                                            label: 'MOVES',
                                            value: '${entry.recentMoves.length}',
                                            icon: Icons.format_list_numbered,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _DetailSection(
                                        title: 'Defeated Engine',
                                        child: Text(
                                          '${achievement.opponent.title} | FIDE ${achievement.opponent.fideRatingRange}\n${achievement.opponent.playingStyle}',
                                          style: GoogleFonts.inter(
                                            color: ScholarlyTheme.textPrimary,
                                            fontSize: 13,
                                            height: 1.55,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _DetailSection(
                                        title: 'Evaluation Report',
                                        child: Text(
                                          achievement.report,
                                          style: GoogleFonts.inter(
                                            color: ScholarlyTheme.textPrimary,
                                            fontSize: 13,
                                            height: 1.55,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _MiniBadge(
                                            icon: Icons.category_rounded,
                                            label:
                                                entry.ratingCategory.toUpperCase(),
                                          ),
                                          _MiniBadge(
                                            icon: Icons.grid_4x4_rounded,
                                            label: entry.gameMode.toUpperCase(),
                                          ),
                                          _MiniBadge(
                                            icon: Icons.balance_rounded,
                                            label:
                                                'Dominance ${entry.dominance.toStringAsFixed(1)}',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAchievement(BuildContext context) async {
    final text =
        '${achievement.userName} defeated ${achievement.opponent.name} in IdeaSpace Chess Academy. Final move: ${achievement.finalMove}. ${AchievementsPage._shareUrl}';
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'IdeaSpace Chess Academy Achievement',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Achievement share failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

class _EmptyAchievements extends StatelessWidget {
  const _EmptyAchievements({required this.onBattleground});

  final VoidCallback onBattleground;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: JuicyGlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: Color(0xFFF59E0B),
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No battleground victories yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Win rated Battleground matches to mint victory cards for this gallery.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onBattleground,
                icon: const Icon(Icons.sports_martial_arts_rounded, size: 18),
                label: Text(
                  'ENTER BATTLEGROUND',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ScholarlyTheme.accentBlue, width: 2),
        boxShadow: [
          BoxShadow(
            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.18),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipOval(
        child: path.startsWith('assets/')
            ? Image.asset(path, fit: BoxFit.cover)
            : Image.file(File(path), fit: BoxFit.cover),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ScholarlyTheme.accentBlue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ScholarlyTheme.accentBlue),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              color: ScholarlyTheme.accentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
