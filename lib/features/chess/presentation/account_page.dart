import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../application/chess_provider.dart';
import '../application/store_provider.dart';
import '../application/battleground_provider.dart';
import '../application/tutorial_provider.dart';
import '../application/assignment_provider.dart';
import '../services/chess_sound_service.dart';
import '../services/auth_service.dart';
import '../services/play_games_sync_service.dart';
import '../application/onboarding_provider.dart';
import 'scholarly_theme.dart';
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
    final syncState = ref.watch(googleDriveSyncProvider);
    final syncNotifier = ref.read(googleDriveSyncProvider.notifier);

    // Grouping themes for ownership checking
    final freeThemeIds = {'classic', 'scholar', 'vector_wood', 'theme3', 'sprite_fairytale'};
    
    // Filter registry for owned themes
    final ownedThemes = ThemeRegistry.allThemes.where((theme) {
      return freeThemeIds.contains(theme.id) ||
             storeState.isPremium ||
             storeState.purchasedBoardThemes.contains(theme.id);
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
                child: _buildSubscriptionCard(context, storeState, storeNotifier),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Themes Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                  },
                  childCount: ownedThemes.length,
                ),
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
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                          try {
                            await ref.read(authServiceProvider).signOut();
                          } catch (e) {
                            debugPrint('Firebase signout error: $e');
                          }
                          final repo = ref.read(tutorialProgressRepositoryProvider);
                          await repo.setIsGoogleSignedIn(false);
                          await repo.setWelcomeGuideSeen(false);
                          await repo.setArenaIntroSeen(false);
                          await repo.setBattlegroundIntroSeen(false);
                          await repo.setPuzzlesIntroSeen(false);
                          await repo.setAcademyIntroSeen(false);
                          await repo.setAcademyAccessCount(0);

                          ref.read(showArenaIntroProvider.notifier).state = true;
                          ref.read(showBattlegroundIntroProvider.notifier).state = true;
                          ref.read(showPuzzlesIntroProvider.notifier).state = true;

                          ref.read(mobileNavIndexProvider.notifier).state = 0;
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const SignInPage(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 800),
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
                  backgroundColor: const Color(0xFF1E1E24), // Obsidian dark contrasting background
                  borderColor: Colors.redAccent.withValues(alpha: 0.35),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        label: 'Reset Progress',
                        description: 'Wipe ratings, match history, and tutorial progress',
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

            // Restore Purchases Action at the absolute bottom
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      storeNotifier.restorePurchases();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Checking Google Play for previous purchases...'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restore_rounded, size: 18, color: ScholarlyTheme.accentBlue),
                    label: Text(
                      'RESTORE PREVIOUS PURCHASES',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: ScholarlyTheme.accentBlue,
                      ),
                    ),
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

  // Membership & Subscription Header Card
  Widget _buildSubscriptionCard(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');

    if (storeState.isPremium && storeState.subscriptionTill != null) {
      final rawPlan = storeState.subscriptionPlan ?? 'Premium';
      final planName = (rawPlan == 'sixmonth' ? '6-Month' : rawPlan).toUpperCase();
      final expiryStr = dateFormat.format(storeState.subscriptionTill!);
      final daysLeft = storeState.subscriptionTill!.difference(DateTime.now()).inDays;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Sleek Dark Steel
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.cyan, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$planName SUBSCRIBER',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.cyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renews till: $expiryStr ($daysLeft days left)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '✓ All app features and themes unlocked',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                _showCancelDialog(context, storeNotifier);
              },
              child: Text(
                'CANCEL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Free Tier Layout
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: ScholarlyTheme.accentBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FREE ACCOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All AI opponents are unlocked & free.',
                  style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                ),
                Text(
                  'Upgrade to unlock unlimited games, puzzles & coaching.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ScholarlyTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cancel Dialog
  void _showCancelDialog(BuildContext context, StoreNotifier storeNotifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Cancel Subscription',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
          ),
          content: Text(
            'Are you sure you want to cancel your simulated subscription? You will lose access to premium AI coaching limits immediately.',
            style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Subscription', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                storeNotifier.cancelSubscription();
                Navigator.pop(context);
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Subscription cancelled successfully.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Yes, Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncStatusTile(
    BuildContext context,
    GoogleDriveSyncState syncState,
    GoogleDriveSyncNotifier syncNotifier,
  ) {
    final authService = ref.watch(authServiceProvider);
    final isPlayGamesUser = authService.isPlayGamesUser;

    if (!isPlayGamesUser) {
      return _buildSettingsTile(
        label: 'Google Drive Cloud Sync',
        description: 'Sign in to sync your progress.',
        icon: Icons.cloud_off_rounded,
        accentColor: ScholarlyTheme.textSubtle,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in from the main menu to enable Cloud Sync.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        trailing: const Icon(
          Icons.cloud_off_rounded,
          color: ScholarlyTheme.textSubtle,
          size: 20,
        ),
      );
    }

    IconData statusIcon;
    Color statusColor;

    switch (syncState.status) {
      case GoogleDriveSyncStatus.syncing:
        statusIcon = Icons.sync_rounded;
        statusColor = ScholarlyTheme.accentBlue;
        break;
      case GoogleDriveSyncStatus.success:
        statusIcon = Icons.cloud_done_rounded;
        statusColor = Colors.green;
        break;
      case GoogleDriveSyncStatus.error:
        statusIcon = Icons.cloud_off_rounded;
        statusColor = Colors.redAccent;
        break;
      case GoogleDriveSyncStatus.idle:
        statusIcon = Icons.cloud_queue_rounded;
        statusColor = ScholarlyTheme.textSubtle;
        break;
    }

    Future<void> handleSync() async {
      final success = await syncNotifier.restore();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully synced with Google Drive cloud save!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${syncState.errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }

    return _buildSettingsTile(
      label: 'Google Drive Cloud Sync',
      description: syncState.status == GoogleDriveSyncStatus.syncing
          ? 'Syncing your data...'
          : syncState.lastSyncedAt != null
              ? 'Last synced: ${DateFormat.jm().format(syncState.lastSyncedAt!)}'
              : 'Auto-syncs settings and game history',
      icon: statusIcon,
      accentColor: statusColor,
      onTap: syncState.status == GoogleDriveSyncStatus.syncing ? () {} : handleSync,
      trailing: syncState.status == GoogleDriveSyncStatus.syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentBlue),
              ),
            )
          : TextButton.icon(
              onPressed: syncState.status == GoogleDriveSyncStatus.syncing ? null : handleSync,
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: Text(
                'Sync Now',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Future<void> _showResetConfirmationDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ResetConfirmationDialog(),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(battlegroundProvider.notifier).resetRatedStats();
      await ref.read(tutorialProvider.notifier).resetAllProgress();
      await ref.read(assignmentProvider.notifier).resetAssignmentProgress();
      await ref.read(chessProvider.notifier).clearAllHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All progress, rated stats, match history, assignment data, and tutorial records have been reset.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildSettingsTile({
    required String label,
    required String description,
    required IconData icon,
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
        leading: Container(
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
            icon,
            color: effectiveAccent ?? (isDarkBg ? Colors.white : ScholarlyTheme.textPrimary),
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: effectiveAccent ?? (isDarkBg ? Colors.white : ScholarlyTheme.textPrimary),
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
        trailing: trailing ?? Icon(
          Icons.chevron_right_rounded,
          color: isDarkBg ? Colors.white38 : ScholarlyTheme.textSubtle,
          size: 20,
        ),
      ),
    );
  }
}

class ResetConfirmationDialog extends StatefulWidget {
  const ResetConfirmationDialog({super.key});

  @override
  State<ResetConfirmationDialog> createState() => _ResetConfirmationDialogState();
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
        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2), width: 1),
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
            child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
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
              'This action is irreversible. All your ratings, match history, and tutorial academy progress will be permanently deleted.',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: ScholarlyTheme.backgroundStart,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
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
          onPressed: _isResetEnabled ? () => Navigator.pop(context, true) : null,
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
