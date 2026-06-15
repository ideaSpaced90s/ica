import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/chess_provider.dart';
import '../application/battleground_provider.dart';
import '../application/tutorial_provider.dart';
import '../application/assignment_provider.dart';
import '../services/chess_sound_service.dart';
import '../services/auth_service.dart';
import '../services/play_games_sync_service.dart';
import 'package:intl/intl.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_scaffold.dart';
import 'sign_in_page.dart';
import 'mobile_navigation_shell.dart';
import '../application/onboarding_provider.dart';
import 'notification_settings_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);
    final syncState = ref.watch(googleDriveSyncProvider);
    final syncNotifier = ref.read(googleDriveSyncProvider.notifier);

    return AmbientScaffold(
      scaffoldKey: _scaffoldKey,
      blob1Color: const Color(0xFFDBEAFE), // Soft Blue
      blob2Color: const Color(0xFFFEF3C7), // Soft Gold
      blob3Color: const Color(0xFFF3E8FF), // Soft Purple
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // SETTINGS SECTIONS
              SliverList(
                delegate: SliverChildListDelegate([
                  // PREFERENCES
                  _SettingsCategory(
                    title: 'GLOBAL PREFERENCES',
                    children: [
                      _SettingsSwitchTile(
                        label: 'Music',
                        description: 'Background music during gameplay',
                        icon: state.isMusicEnabled
                            ? Icons.music_note_rounded
                            : Icons.music_off_rounded,
                        value: state.isMusicEnabled,
                        onChanged: (v) => notifier.toggleMusic(),
                      ),
                      _SettingsSwitchTile(
                        label: 'Sound Effects',
                        description: 'Move sounds and capture alerts',
                        icon: state.isSoundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        value: state.isSoundEnabled,
                        onChanged: (v) => notifier.toggleSound(),
                      ),
                      _SettingsSwitchTile(
                        label: 'Haptic Feedback',
                        description: 'Vibrations for physical impact',
                        icon: state.isHapticsEnabled
                            ? Icons.vibration_rounded
                            : Icons.vibration_outlined,
                        value: state.isHapticsEnabled,
                        onChanged: (v) => notifier.toggleHaptics(),
                      ),
                      _SettingsTile(
                        label: 'Notifications',
                        description: 'Configure briefings, streak alerts, and quiet hours',
                        icon: Icons.notifications_active_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NotificationSettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // ACCOUNT
                  _SettingsCategory(
                    title: 'ACCOUNT',
                    children: [
                      _SettingsTile(
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
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const SignInPage(),
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

                  // CLOUD SYNC
                  _SettingsCategory(
                    title: 'CLOUD SYNC',
                    children: [
                      _buildSyncStatusTile(context, syncState, syncNotifier),
                    ],
                  ),

                  // DANGER ZONE
                  _SettingsCategory(
                    title: 'DANGER ZONE',
                    children: [
                      _SettingsTile(
                        label: 'Reset',
                        description: 'Wipe ratings, match history, and tutorial progress',
                        icon: Icons.delete_forever_rounded,
                        accentColor: Colors.redAccent,
                        onTap: () => _showResetConfirmationDialog(context, ref),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),
                ]),
              ),
            ],
          ),

          _buildActionRow(context),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'GLOBAL SETTINGS',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: ScholarlyTheme.textSubtle,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cloud Sync Disabled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your Google Account to automatically sync your settings, saved games, and performance statistics to Google Drive.',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textSubtle,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
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

    return _SettingsTile(
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
      builder: (context) => AlertDialog(
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
        content: const Text(
          'This action is irreversible. All your ratings, match history, and tutorial academy progress will be permanently deleted.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('RESET ALL'),
          ),
        ],
      ),
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
}

class _SettingsCategory extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCategory({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: JuicySectionHeader(
            title: title,
            color: ScholarlyTheme.accentBlue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: JuicyGlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 24,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends ConsumerWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;
  final Widget? trailing;

  const _SettingsTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveAccent = accentColor;
    return ListTile(
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
          color: effectiveAccent ?? ScholarlyTheme.textPrimary,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: effectiveAccent ?? ScholarlyTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right_rounded,
        color: ScholarlyTheme.textSubtle,
        size: 20,
      ),
    );
  }
}

class _SettingsSwitchTile extends ConsumerWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      value: value,
      onChanged: (v) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.switchToggle);
        onChanged(v);
      },
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: value ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: ScholarlyTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
      ),
      activeThumbColor: ScholarlyTheme.accentBlue,
      activeTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
