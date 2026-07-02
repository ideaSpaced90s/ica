import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/assignment_provider.dart';
import '../application/battleground_provider.dart';
import '../application/chess_provider.dart';
import '../application/lifetime_xp_provider.dart';
import '../domain/models/ai_avatar.dart';
import '../domain/models/assignment_state.dart';
import '../domain/models/lifetime_xp_state.dart';
import '../domain/performance_ledger_entry.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_scaffold.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  static const _shareUrl = 'https://play.google.com/store/apps/details?id=com.dsamok.ideaspacechess';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chessState = ref.watch(chessProvider);
    final bgState = ref.watch(battlegroundProvider);
    final assignmentState = ref.watch(assignmentProvider);
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
                child: _UserEloStrengthCard(
                  userName: chessState.userName,
                  avatarPath: chessState.userAvatarPath,
                  elo: bgState.consolidatedRating,
                  streak: bgState.totalWinningStreak,
                  totalGames: bgState.totalRatedGamesCount,
                  bulletElo: bgState.bulletElo,
                  blitzElo: bgState.blitzElo,
                  rapidElo: bgState.rapidElo,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'SEASON PERFORMANCE',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ScholarlyTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _FormFactorSeasonCard(state: assignmentState),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: _SeasonHistoryPanel(history: assignmentState.seasonHistory),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  '⚡ LIFETIME XP',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ScholarlyTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: _LifetimeXpCard(
                  xpState: xpState,
                  xpNotifier: xpNotifier,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  '🏆 VICTORY GALLERY',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ScholarlyTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            if (wins.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptyAchievements(),
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

class _UserEloStrengthCard extends StatelessWidget {
  const _UserEloStrengthCard({
    required this.userName,
    required this.avatarPath,
    required this.elo,
    required this.streak,
    required this.totalGames,
    required this.bulletElo,
    required this.blitzElo,
    required this.rapidElo,
  });

  final String userName;
  final String avatarPath;
  final int elo;
  final int streak;
  final int totalGames;
  final int bulletElo;
  final int blitzElo;
  final int rapidElo;

  @override
  Widget build(BuildContext context) {
    final matchedAvatar = AiAvatar.getBestMatch(elo);

    return JuicyGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      borderColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar & Name
          Row(
            children: [
              _UserAvatar(path: avatarPath, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          matchedAvatar.icon,
                          color: matchedAvatar.color,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${matchedAvatar.name} Level (${matchedAvatar.fideRatingRange} FIDE)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: ScholarlyTheme.panelStroke, height: 1),
          const SizedBox(height: 18),

          // Main Elo & Streak display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'CURRENT ELO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: ScholarlyTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_rounded, color: ScholarlyTheme.accentBlue, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        '$elo',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(height: 36, width: 1, color: ScholarlyTheme.panelStroke),
              Column(
                children: [
                  Text(
                    'WINNING STREAK',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: ScholarlyTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 6),
                      Text(
                        '$streak',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: ScholarlyTheme.panelStroke, height: 1),
          const SizedBox(height: 16),

          // Sub-ratings: Bullet, Blitz, Rapid ELOs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SubRatingColumn(label: '🚄 Bullet', value: '$bulletElo'),
              _SubRatingColumn(label: '⚡ Blitz', value: '$blitzElo'),
              _SubRatingColumn(label: '🐢 Rapid', value: '$rapidElo'),
              _SubRatingColumn(label: '📊 Games', value: '$totalGames'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubRatingColumn extends StatelessWidget {
  const _SubRatingColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: ScholarlyTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LifetimeXpCard extends StatelessWidget {
  const _LifetimeXpCard({
    required this.xpState,
    required this.xpNotifier,
  });

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
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFF59E0B),
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL LIFETIME XP',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
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

class _AchievementDetailPage extends StatefulWidget {
  const _AchievementDetailPage({required this.achievement});

  final _VictoryAchievement achievement;

  @override
  State<_AchievementDetailPage> createState() => _AchievementDetailPageState();
}

class _AchievementDetailPageState extends State<_AchievementDetailPage> {
  final _cardKey = GlobalKey();
  bool _sharing = false;
  late ConfettiController _confettiTop;
  late ConfettiController _confettiBottom;

  _VictoryAchievement get achievement => widget.achievement;

  @override
  void initState() {
    super.initState();
    _confettiTop = ConfettiController(duration: const Duration(seconds: 4));
    _confettiBottom = ConfettiController(duration: const Duration(seconds: 4));
    // Brief confetti burst when the victory card opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confettiTop.play();
        _confettiBottom.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiTop.dispose();
    _confettiBottom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = achievement.entry;
    final date = DateFormat('MMMM d, yyyy').format(entry.timestamp);
    final botColor = achievement.opponent.color;
    final botColorDim = botColor.withValues(alpha: 0.18);

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient radial glow from opponent color
            Positioned(
              top: -80,
              left: -60,
              right: -60,
              child: Container(
                height: 340,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      botColor.withValues(alpha: 0.28),
                      botColorDim,
                      Colors.transparent,
                    ],
                    radius: 0.85,
                  ),
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 58, 16, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1623),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: botColor.withValues(alpha: 0.55),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: botColor.withValues(alpha: 0.30),
                                  blurRadius: 40,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 16),
                                ),
                                BoxShadow(
                                  color: botColor.withValues(alpha: 0.12),
                                  blurRadius: 80,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(27),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── HERO IMAGE ─────────────────────────────
                                  AspectRatio(
                                    aspectRatio: 1.65,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        buildAvatarImage(
                                          achievement.opponent.imagePath,
                                          fit: BoxFit.cover,
                                        ),
                                        // Cinematic multi-stop gradient
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withValues(alpha: 0.05),
                                                Colors.black.withValues(alpha: 0.15),
                                                Colors.black.withValues(alpha: 0.72),
                                                const Color(0xFF0F1623),
                                              ],
                                              stops: const [0.0, 0.35, 0.75, 1.0],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                        // Lateral bot-color vignette
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  botColor.withValues(alpha: 0.22),
                                                  Colors.transparent,
                                                  Colors.transparent,
                                                  botColor.withValues(alpha: 0.12),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Bottom text overlay
                                        Positioned(
                                          left: 20,
                                          right: 20,
                                          bottom: 18,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Golden badge pill
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFFFD166), Color(0xFFFF9500)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '⚡  BATTLEGROUND VICTORY',
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFF1A0A00),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Title: player defeated [BOT in bot color]
                                              RichText(
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1.1,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: '${achievement.userName} ',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                    const TextSpan(
                                                      text: 'defeated ',
                                                      style: TextStyle(color: Colors.white70),
                                                    ),
                                                    TextSpan(
                                                      text: achievement.opponent.name,
                                                      style: TextStyle(
                                                        color: botColor,
                                                        shadows: [
                                                          Shadow(
                                                            color: botColor.withValues(alpha: 0.6),
                                                            blurRadius: 12,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Play Store badge (top-right)
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => launchUrl(
                                              Uri.parse(AchievementsPage._shareUrl),
                                              mode: LaunchMode.externalApplication,
                                            ),
                                            child: Image.asset(
                                              'assets/splash/googleplaybadge.png',
                                              height: 36,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ── CARD BODY ──────────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User row
                                        Row(
                                          children: [
                                            // Avatar with bot-color ring
                                            Container(
                                              padding: const EdgeInsets.all(2.5),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    botColor,
                                                    botColor.withValues(alpha: 0.4),
                                                  ],
                                                ),
                                              ),
                                              child: _UserAvatar(
                                                path: achievement.userAvatarPath,
                                                size: 44,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    achievement.userName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                  Text(
                                                    date,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Gold gradient Share button
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFFFD166), Color(0xFFFF9500)],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x55FF9500),
                                                    blurRadius: 12,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(12),
                                                  onTap: _sharing ? null : () => _captureAndShare(),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (_sharing)
                                                          const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Color(0xFF1A0A00),
                                                            ),
                                                          )
                                                        else
                                                          const Icon(
                                                            Icons.ios_share_rounded,
                                                            size: 16,
                                                            color: Color(0xFF1A0A00),
                                                          ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          'Share',
                                                          style: GoogleFonts.inter(
                                                            fontWeight: FontWeight.w900,
                                                            fontSize: 13,
                                                            color: const Color(0xFF1A0A00),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        // ── 2x2 STAT TILE GRID ──────────────
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _DarkStatTile(
                                                label: 'POST ELO',
                                                value: '${entry.ratingSnapshot}',
                                                icon: Icons.speed_rounded,
                                                iconColor: const Color(0xFF38BDF8),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _DarkStatTile(
                                                label: 'CARD XP',
                                                value: '+${achievement.cardXp}',
                                                icon: Icons.bolt_rounded,
                                                iconColor: const Color(0xFFFFD166),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _DarkStatTile(
                                                label: 'FINAL MOVE',
                                                value: achievement.finalMove,
                                                icon: Icons.flag_rounded,
                                                iconColor: const Color(0xFF4ADE80),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _DarkStatTile(
                                                label: 'MOVES',
                                                value: '${entry.recentMoves.length}',
                                                icon: Icons.format_list_numbered,
                                                iconColor: const Color(0xFFA78BFA),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        // ── DEFEATED BOT SECTION ────────────
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: botColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: botColor.withValues(alpha: 0.28),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Header: ⚔ DEFEATED · SPARKY
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.sports_kabaddi_rounded,
                                                    size: 14,
                                                    color: botColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'DEFEATED  ·  ${achievement.opponent.name.toUpperCase()}',
                                                    style: GoogleFonts.outfit(
                                                      color: botColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 1.1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              // Bot title in italic
                                              Text(
                                                achievement.opponent.title,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white.withValues(alpha: 0.90),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              // FIDE pill + playing style
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 6,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: botColor.withValues(alpha: 0.20),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: botColor.withValues(alpha: 0.45),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'FIDE ${achievement.opponent.fideRatingRange}',
                                                      style: GoogleFonts.jetBrainsMono(
                                                        color: botColor,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                achievement.opponent.playingStyle,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                  height: 1.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        // ── EVALUATION REPORT ───────────────
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF13100A),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFFFFD166).withValues(alpha: 0.22),
                                            ),
                                          ),
                                          child: IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                // Gold left accent bar
                                                Container(
                                                  width: 4,
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Color(0xFFFFD166), Color(0xFFFF9500)],
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                    ),
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(16),
                                                      bottomLeft: Radius.circular(16),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.analytics_outlined,
                                                              size: 13,
                                                              color: Color(0xFFFFD166),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              'EVALUATION REPORT',
                                                              style: GoogleFonts.outfit(
                                                                color: const Color(0xFFFFD166),
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w900,
                                                                letterSpacing: 1.0,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          achievement.report,
                                                          style: GoogleFonts.inter(
                                                            color: Colors.white.withValues(alpha: 0.88),
                                                            fontSize: 13,
                                                            height: 1.6,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // ── DARK GLASS MINI BADGES ──────────
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _DarkMiniBadge(
                                              icon: Icons.category_rounded,
                                              label: entry.ratingCategory.toUpperCase(),
                                            ),
                                            _DarkMiniBadge(
                                              icon: Icons.grid_4x4_rounded,
                                              label: entry.gameMode.toUpperCase(),
                                            ),
                                            _DarkMiniBadge(
                                              icon: Icons.balance_rounded,
                                              label: 'Dominance ${entry.dominance.toStringAsFixed(1)}',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        // ── BRANDING FOOTER ─────────────────
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.04),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.07),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // App icon + name
                                              Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.asset(
                                                      'assets/splash/appicon_foreground.png',
                                                      width: 32,
                                                      height: 32,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Chess Academy',
                                                        style: GoogleFonts.outfit(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w900,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Powered by ',
                                                            style: GoogleFonts.inter(
                                                              color: Colors.white38,
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          Image.asset(
                                                            'assets/splash/ideaspace.png',
                                                            height: 11,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              // Google Play badge
                                              GestureDetector(
                                                onTap: () => launchUrl(
                                                  Uri.parse(AchievementsPage._shareUrl),
                                                  mode: LaunchMode.externalApplication,
                                                ),
                                                child: Image.asset(
                                                  'assets/splash/googleplaybadge.png',
                                                  height: 30,
                                                ),
                                              ),
                                            ],
                                          ),
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
                ),
              ],
            ),
            // ── CONFETTI TOP ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiTop,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 55,
                gravity: 0.18,
                colors: [
                  achievement.opponent.color,
                  const Color(0xFFFFD166),
                  Colors.white,
                  const Color(0xFF38BDF8),
                  const Color(0xFF4ADE80),
                  const Color(0xFFA78BFA),
                ],
              ),
            ),
            // ── CONFETTI BOTTOM ───────────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: ConfettiWidget(
                confettiController: _confettiBottom,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: -3.14 / 2,
                shouldLoop: false,
                numberOfParticles: 55,
                gravity: 0.05,
                colors: [
                  achievement.opponent.color,
                  const Color(0xFFFFD166),
                  Colors.white,
                  const Color(0xFF38BDF8),
                  const Color(0xFF4ADE80),
                  const Color(0xFFA78BFA),
                ],
              ),
            ),
            // ── CLOSE BUTTON ──────────────────────────────────────────────
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndShare() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      // Wait for the widget to be fully painted before capturing
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = Directory.systemTemp;
      final file = await File('${tempDir.path}/victory_card.png')
          .writeAsBytes(pngBytes);

      final text =
          '${achievement.userName} defeated ${achievement.opponent.name} '
          'in IdeaSpace Chess Academy! 🎮\n'
          '${AchievementsPage._shareUrl}';

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile(file.path)],
          subject: 'IdeaSpace Chess Academy Victory',
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _EmptyAchievements extends StatelessWidget {
  const _EmptyAchievements();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: (size * 2).round(),
              ),
      ),
    );
  }
}

/// Dark stat tile used in the 2x2 grid inside the premium victory card detail.
class _DarkStatTile extends StatelessWidget {
  const _DarkStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2236),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



/// Dark glass chip for the premium victory card detail footer badges.
class _DarkMiniBadge extends StatelessWidget {
  const _DarkMiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white60),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Light badge variant — used in gallery list cards.
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



Color _getRankColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'bronze':
      return const Color(0xFF92400E);
    case 'silver':
      return const Color(0xFF6B7280);
    case 'gold':
      return const Color(0xFFF59E0B);
    case 'platinum':
      return const Color(0xFF0D9488);
    case 'diamond':
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFF6B7280);
  }
}

class _FormFactorSeasonCard extends StatelessWidget {
  const _FormFactorSeasonCard({required this.state});

  final AssignmentState state;

  @override
  Widget build(BuildContext context) {
    final currentLp = state.currentMonthLp;
    final rank = state.formFactorRank;
    final rankColor = _getRankColor(rank);

    // Days remaining in month
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    // Form Factor Progress toward next rank
    int nextRankLp = 300;
    int currentRankStartLp = 0;
    if (currentLp >= 2000) {
      nextRankLp = 3000; // soft cap
      currentRankStartLp = 2000;
    } else if (currentLp >= 1200) {
      nextRankLp = 2000;
      currentRankStartLp = 1200;
    } else if (currentLp >= 700) {
      nextRankLp = 1200;
      currentRankStartLp = 700;
    } else if (currentLp >= 300) {
      nextRankLp = 700;
      currentRankStartLp = 300;
    }

    final double lpProgress = ((currentLp - currentRankStartLp) / (nextRankLp - currentRankStartLp)).clamp(0.0, 1.0);

    return JuicyGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      backgroundColor: Colors.white,
      borderColor: rankColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: rankColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '⚔️ FORM FACTOR',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: ScholarlyTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$daysLeft Days Left',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${rank.toUpperCase()} RANK',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: rankColor,
                ),
              ),
              Text(
                '${NumberFormat("#,###").format(currentLp)} LP',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lpProgress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9ECEF),
              color: rankColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.monthlyWins}W • ${state.monthlyDraws}D • ${state.monthlyLosses}L',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: ScholarlyTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Assignments LP: +${state.monthlyAssignmentsCompleted * 15}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: ScholarlyTheme.textSubtle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeasonHistoryPanel extends StatelessWidget {
  const _SeasonHistoryPanel({required this.history});

  final List<MonthlySeasonHistory> history;

  @override
  Widget build(BuildContext context) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      borderColor: Colors.teal.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: Colors.teal, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '📜 SEASONS HISTORY',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.teal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '${history.length} Seasons',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No season data recorded yet. Your rank will archive here at the end of the month!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ScholarlyTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => const Divider(color: ScholarlyTheme.panelStroke, height: 16),
              itemBuilder: (context, index) {
                final season = history[history.length - 1 - index]; // Show newest first
                final rankColor = _getRankColor(season.rank);

                // Parse month ID like "2026-06" to friendly "June 2026"
                String displayMonth = season.monthId;
                try {
                  final parts = season.monthId.split('-');
                  if (parts.length == 2) {
                    final year = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final date = DateTime(year, month, 1);
                    displayMonth = DateFormat('MMMM yyyy').format(date);
                  }
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayMonth,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ScholarlyTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${season.wins}W • ${season.draws}D • ${season.losses}L • ${season.assignmentsCompleted} Assignments',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: ScholarlyTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 1),
                            ),
                            child: Text(
                              season.rank.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: rankColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${NumberFormat("#,###").format(season.lp)} LP',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
