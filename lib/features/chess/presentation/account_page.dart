import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../application/chess_provider.dart';
import '../application/store_provider.dart';
import '../application/battleground_provider.dart';
import '../application/tutorial_provider.dart';
import '../application/assignment_provider.dart';
import '../application/lifetime_xp_provider.dart';
import '../services/chess_sound_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../application/onboarding_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/premium_membership_card.dart';
import 'widgets/ambient_scaffold.dart';
import 'sign_in_page.dart';
import 'mobile_navigation_shell.dart';
import 'arena/themes/theme_registry.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);
    final syncState = ref.watch(cloudSyncProvider);
    final syncNotifier = ref.read(cloudSyncProvider.notifier);

    // Filter registry for owned themes
    final ownedThemes = ThemeRegistry.allThemes.where((theme) {
      return storeNotifier.isBoardThemePurchased(theme.id);
    }).toList();

    return AmbientScaffold(
      blob1Color: const Color(0xFFF3E8FF), // Soft purple
      blob2Color: const Color(0xFFE0F2FE), // Soft cyan/blue
      blob3Color: const Color(0xFFDCFCE7), // Soft green
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Safe Area Spacing & Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage your membership, active themes, and cloud backup',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ScholarlyTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Subscription Status Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildSubscriptionCard(
                  context,
                  storeState,
                  storeNotifier,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Theme Usage Tracker (only when premium)
            _buildThemeUsageSection(context, storeState, storeNotifier),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Themes Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                child: JuicySectionHeader(
                  title: 'MY THEMES (${ownedThemes.length})',
                  color: ScholarlyTheme.accentBlue,
                ),
              ),
            ),

            // Owned & Active Themes Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final theme = ownedThemes[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    color: theme.lightSquare,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    color: theme.darkSquare,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    color: theme.darkSquare,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    color: theme.lightSquare,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Center(
                                      child: FractionallySizedBox(
                                        widthFactor: 0.50,
                                        heightFactor: 0.50,
                                        child: theme.buildPiece(
                                          context,
                                          'N',
                                          true,
                                          false,
                                          0.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            theme.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: ownedThemes.length),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Cloud Save Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: JuicySectionHeader(
                  title: 'CLOUD SYNC',
                  color: ScholarlyTheme.accentBlue,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: JuicyGlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildSyncStatusTile(context, syncState, syncNotifier),
                    ],
                  ),
                ),
              ),
            ),

            // Account & Preferences Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: JuicySectionHeader(
                  title: 'ACCOUNT ACTIONS',
                  color: ScholarlyTheme.accentBlue,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: JuicyGlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        label: 'Sign Out',
                        description: 'Return to the sign in screen',
                        icon: Icons.logout_rounded,
                        onTap: () async {
                          ref
                              .read(chessSoundServiceProvider)
                              .playSfx(SoundEffect.uiClick);
                          try {
                            await ref.read(authServiceProvider).signOut();
                          } catch (e) {
                            debugPrint('Firebase signout error: $e');
                          }
                          final repo = ref.read(
                            tutorialProgressRepositoryProvider,
                          );
                          await repo.setIsGoogleSignedIn(false);
                          await repo.setWelcomeGuideSeen(false);
                          await repo.setArenaIntroSeen(false);
                          await repo.setBattlegroundIntroSeen(false);
                          await repo.setPuzzlesIntroSeen(false);
                          await repo.setAcademyIntroSeen(false);
                          await repo.setAcademyAccessCount(0);

                          ref.read(showArenaIntroProvider.notifier).state =
                              true;
                          ref
                                  .read(showBattlegroundIntroProvider.notifier)
                                  .state =
                              true;
                          ref.read(showPuzzlesIntroProvider.notifier).state =
                              true;

                          ref.read(mobileNavIndexProvider.notifier).state = 0;
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const SignInPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                transitionDuration: const Duration(
                                  milliseconds: 800,
                                ),
                              ),
                            );
                          }
                        },
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Restore Purchases Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: JuicySectionHeader(
                  title: 'PURCHASES',
                  color: ScholarlyTheme.accentBlue,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: JuicyGlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        label: 'Restore Previous Purchases',
                        description: 'Re-link your Google Play purchases to this account',
                        icon: Icons.restore_rounded,
                        accentColor: ScholarlyTheme.accentBlue,
                        onTap: () {
                          ref
                              .read(chessSoundServiceProvider)
                              .playSfx(SoundEffect.uiClick);
                          storeNotifier.restorePurchases();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Checking Google Play for previous purchases...',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Danger Zone Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: JuicySectionHeader(
                  title: 'DANGER ZONE',
                  color: Colors.redAccent,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: JuicyGlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  backgroundColor: const Color(
                    0xFF1E1E24,
                  ), // Obsidian dark contrasting background
                  borderColor: Colors.redAccent.withValues(alpha: 0.35),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        label: 'Reset Progress',
                        description:
                            'Wipe ratings, XP, LP, match history & tutorial progress',
                        icon: Icons.delete_forever_rounded,
                        accentColor: Colors.redAccent,
                        onTap: () => _showResetConfirmationDialog(context, ref),
                        isDarkBg: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeUsageSection(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    if (!storeState.isPremium || storeState.cycleThemeAllocation == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final activeThemeIds = storeState.cycleThemeAllocation!.take(9).toList();
    final plan = storeState.subscriptionPlan ?? 'monthly';

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: JuicySectionHeader(
                title: 'THEME PLAY DAYS',
                color: const Color(0xFFFFD700), // Gold for premium tracker
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: activeThemeIds.map((themeId) {
                  final theme = ThemeRegistry.getTheme(themeId);
                  final isDirectlyPurchased = storeState.purchasedBoardThemes.contains(themeId);
                  final allowed = storeNotifier.getThemeAllowedDays(themeId, plan);
                  final used = storeNotifier.getThemeUsedDays(themeId);
                  final remaining = (allowed - used).clamp(0, 365);
                  final progress = allowed > 0 ? (used / allowed).clamp(0.0, 1.0) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Color Swatch
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(child: Container(color: theme.lightSquare)),
                                        Expanded(child: Container(color: theme.darkSquare)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(child: Container(color: theme.darkSquare)),
                                        Expanded(child: Container(color: theme.lightSquare)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Center(
                                child: FractionallySizedBox(
                                  widthFactor: 0.6,
                                  heightFactor: 0.6,
                                  child: theme.buildPiece(context, 'N', true, false, 0.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name & Progress
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      theme.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDirectlyPurchased
                                        ? 'Unlimited'
                                        : '$remaining / $allowed left',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDirectlyPurchased
                                          ? Colors.cyanAccent
                                          : (remaining == 0
                                              ? Colors.redAccent.shade100
                                              : const Color(0xFFFFD700).withValues(alpha: 0.8)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: isDirectlyPurchased ? 1.0 : (1.0 - progress),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFF1E293B),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDirectlyPurchased
                                        ? Colors.cyanAccent
                                        : (remaining == 0
                                            ? Colors.redAccent
                                            : const Color(0xFFFFD700)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Membership & Subscription Header Card
  Widget _buildSubscriptionCard(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    if (storeState.isPremium && storeState.subscriptionTill != null) {
      return const PremiumMembershipCard();
    }

    // Free Tier Layout
    final usage = storeState.freeTierUsage;
    final ratedRemaining = (1 - usage.ratedGamesPlayed).clamp(0, 1);
    final arenaRemaining = (3 - usage.arenaGamesPlayed).clamp(0, 3);
    final promptsRemaining = (5 - usage.chipPromptsUsed).clamp(0, 5);
    final puzzlesRemaining = (3 - usage.puzzlesSolved).clamp(0, 3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.74),
            const Color(0xFFEFF6FF).withValues(alpha: 0.68),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.62),
              shape: BoxShape.circle,
              border: Border.all(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.18),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: ScholarlyTheme.accentBlue,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'FREE ACCOUNT',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: ScholarlyTheme.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              'All AI opponents are unlocked and free. Upgrade for unlimited games, puzzles, and coaching.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.35,
                color: ScholarlyTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            ),
            child: Column(
              children: [
                Text(
                  'DAILY LIMITS REMAINING',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: ScholarlyTheme.textMuted,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 420 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: crossAxisCount == 4 ? 0.72 : 1.15,
                      children: [
                        _buildUsageTile(
                          'Rated Match',
                          ratedRemaining,
                          1,
                          Icons.emoji_events_rounded,
                        ),
                        _buildUsageTile(
                          'Arena Game',
                          arenaRemaining,
                          3,
                          Icons.sports_martial_arts_rounded,
                        ),
                        _buildUsageTile(
                          'Coaching',
                          promptsRemaining,
                          5,
                          Icons.psychology_rounded,
                        ),
                        _buildUsageTile(
                          'Puzzles',
                          puzzlesRemaining,
                          3,
                          Icons.extension_rounded,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSyncStatusTile(
    BuildContext context,
    CloudSyncState syncState,
    CloudSyncNotifier syncNotifier,
  ) {
    final authService = ref.watch(authServiceProvider);
    final isPlayGamesUser = authService.isPlayGamesUser;

    IconData statusIcon;
    Color statusColor;

    switch (syncState.status) {
      case CloudSyncStatus.syncing:
        statusIcon = Icons.sync_rounded;
        statusColor = ScholarlyTheme.accentBlue;
        break;
      case CloudSyncStatus.success:
        statusIcon = Icons.cloud_done_rounded;
        statusColor = Colors.green;
        break;
      case CloudSyncStatus.error:
        statusIcon = Icons.cloud_off_rounded;
        statusColor = Colors.redAccent;
        break;
      case CloudSyncStatus.idle:
        statusIcon = Icons.cloud_queue_rounded;
        statusColor = ScholarlyTheme.textSubtle;
        break;
    }

    final activeLottieCloud = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      width: 54,
      height: 54,
      child: Lottie.asset(
        'assets/lottie/paperplane.lottie',
        repeat: true,
        animate: true,
        fit: BoxFit.contain,
        decoder: (bytes) {
          return LottieComposition.decodeZip(
            bytes,
            filePicker: (files) {
              for (final file in files) {
                if (file.name.startsWith('animations/') && file.name.endsWith('.json')) {
                  return file;
                }
              }
              return null;
            },
          );
        },
      ),
    );

    final staticLottieCloud = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      width: 54,
      height: 54,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.srcIn,
        ),
        child: Lottie.asset(
          'assets/lottie/paperplane.lottie',
          animate: false,
          fit: BoxFit.contain,
          decoder: (bytes) {
            return LottieComposition.decodeZip(
              bytes,
              filePicker: (files) {
                for (final file in files) {
                  if (file.name.startsWith('animations/') && file.name.endsWith('.json')) {
                    return file;
                  }
                }
                return null;
              },
            );
          },
        ),
      ),
    );

    if (!isPlayGamesUser) {
      return _buildSettingsTile(
        label: 'Cloud Backup Sync',
        description: 'Sign in to sync your progress.',
        icon: Icons.cloud_off_rounded,
        accentColor: ScholarlyTheme.textSubtle,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please sign in from the main menu to enable Cloud Sync.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        trailing: staticLottieCloud,
      );
    }

    Future<void> handleSync() async {
      final success = await syncNotifier.restore();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully synced with cloud save!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sync failed: ${syncState.errorMessage ?? "Unknown error"}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }

    return _buildSettingsTile(
      label: isPlayGamesUser ? 'Cloud sync established' : 'Cloud Backup Sync',
      description: syncState.lastSyncedAt != null
          ? 'Last synced: ${DateFormat.jm().format(syncState.lastSyncedAt!)}'
          : 'Auto-syncs settings and game history',
      icon: statusIcon,
      accentColor: statusColor,
      onTap: syncState.status == CloudSyncStatus.syncing ? () {} : handleSync,
      trailing: activeLottieCloud,
    );
  }


  Future<void> _showResetConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ResetConfirmationDialog(),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(battlegroundProvider.notifier).resetRatedStats();
      await ref.read(tutorialProvider.notifier).resetAllProgress();
      await ref.read(assignmentProvider.notifier).resetAssignmentProgress();
      await ref.read(chessProvider.notifier).clearAllHistory();
      await ref.read(lifetimeXpProvider.notifier).resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Everything reset: ratings, XP, LP, match history, saved games, tutorials, and daily assignments.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildSettingsTile({
    required String label,
    required String description,
    IconData? icon,
    Widget? leading,
    required VoidCallback onTap,
    Color? accentColor,
    Widget? trailing,
    bool isDarkBg = false,
  }) {
    final effectiveAccent = accentColor;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () {
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
          onTap();
        },
        leading: leading ?? Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveAccent != null
                ? effectiveAccent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: effectiveAccent != null
                  ? effectiveAccent.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon ?? Icons.settings,
            color:
                effectiveAccent ??
                (isDarkBg ? Colors.white : ScholarlyTheme.textPrimary),
            size: 20,
          ),
        ),

        title: Text(
          label,
          style: GoogleFonts.inter(
            color:
                effectiveAccent ??
                (isDarkBg ? Colors.white : ScholarlyTheme.textPrimary),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(
            color: isDarkBg ? Colors.white60 : ScholarlyTheme.textMuted,
            fontSize: 11,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: isDarkBg ? Colors.white38 : ScholarlyTheme.textSubtle,
              size: 20,
            ),
      ),
    );
  }

  Widget _buildUsageTile(
    String label,
    int remaining,
    int limit,
    IconData icon,
  ) {
    final percent = limit > 0 ? remaining / limit : 0.0;
    Color progressColor;
    if (percent > 0.5) {
      progressColor = Colors.green;
    } else if (percent > 0.2) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: progressColor.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: progressColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: progressColor, size: 16),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$remaining / $limit',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: percent.clamp(0.0, 1.0).toDouble(),
                  color: progressColor,
                  backgroundColor: ScholarlyTheme.panelStroke.withValues(
                    alpha: 0.55,
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

class ResetConfirmationDialog extends StatefulWidget {
  const ResetConfirmationDialog({super.key});

  @override
  State<ResetConfirmationDialog> createState() =>
      _ResetConfirmationDialogState();
}

class _ResetConfirmationDialogState extends State<ResetConfirmationDialog> {
  late final TextEditingController _controller;
  bool _isResetEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ScholarlyTheme.panelBase,
      surfaceTintColor: Colors.redAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: Colors.redAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reset All Progress?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is irreversible. Your ratings, XP, LP, match history, saved games, tutorial progress, and daily assignment data will be permanently deleted.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'To confirm, type "reset" below:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ScholarlyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (text) {
                setState(() {
                  _isResetEnabled = text.trim().toLowerCase() == 'reset';
                });
              },
              decoration: InputDecoration(
                hintText: 'Type reset',
                hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textSubtle),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: ScholarlyTheme.backgroundStart,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ScholarlyTheme.panelStroke,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ScholarlyTheme.panelStroke,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _isResetEnabled
              ? () => Navigator.pop(context, true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          ),
          child: const Text('RESET ALL'),
        ),
      ],
    );
  }
}
