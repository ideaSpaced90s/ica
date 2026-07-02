import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/chess_provider.dart';
import '../application/battleground_provider.dart';
import '../application/tutorial_provider.dart';
import '../application/assignment_provider.dart';
import '../application/lifetime_xp_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_scaffold.dart';
import 'notification_settings_page.dart';
import 'account_page.dart' show ResetConfirmationDialog;
import 'widgets/update_check_tile.dart';

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
                  // Group 1: SOUND
                  _SettingsCategory(
                    title: 'SOUND',
                    icon: Icons.volume_up_rounded,
                    children: [
                      _SettingsSwitchTile(
                        label: 'Music',
                        description: 'App navigation music except battleground games.',
                        icon: state.isMusicEnabled
                            ? Icons.music_note_rounded
                            : Icons.music_off_rounded,
                        value: state.isMusicEnabled,
                        onChanged: (v) => notifier.toggleMusic(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Group 2: SOUND MANAGEMENT
                  _SettingsCategory(
                    title: 'SOUND MANAGEMENT',
                    icon: Icons.tune_rounded,
                    children: [
                      _SettingsSwitchTile(
                        label: 'App Navigation',
                        icon: state.isSoundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        value: state.isSoundEnabled,
                        onChanged: (v) => notifier.toggleSound(),
                      ),
                      _SettingsSwitchTile(
                        label: 'Battleground',
                        description: 'Battleground gameplay',
                        icon: state.isBattlegroundSoundEnabled
                            ? Icons.sports_esports_rounded
                            : Icons.sports_esports_outlined,
                        value: state.isBattlegroundSoundEnabled,
                        onChanged: (v) => notifier.toggleBattlegroundSound(),
                      ),
                      _NotificationSettingsTile(
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

                  const SizedBox(height: 16),

                  // Group 3: VIBRATIONS
                  _SettingsCategory(
                    title: 'VIBRATIONS',
                    icon: Icons.vibration_rounded,
                    children: [
                      _SettingsSwitchTile(
                        label: 'Haptic Feedback',
                        description: 'Vibrations for physical impact',
                        icon: state.isHapticsEnabled
                            ? Icons.vibration_rounded
                            : Icons.vibration_outlined,
                        value: state.isHapticsEnabled,
                        onChanged: (v) => notifier.toggleHaptics(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Group 4: UPDATES
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                    child: JuicySectionHeader(
                      title: 'UPDATES',
                      icon: Icons.system_update_rounded,
                      color: ScholarlyTheme.accentBlue,
                    ),
                  ),
                  const UpdateCheckTile(),

                  const SizedBox(height: 16),

                  // Group 5: DANGER ZONE
                  _DangerZoneSection(
                    onResetTap: () => _showResetConfirmationDialog(context, ref),
                  ),

                  const SizedBox(height: 120),
                ]),
              ),
            ],
          ),
        ],
      ),
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
            content: Text('Reset successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SettingsCategory extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color headerColor;

  const _SettingsCategory({
    required this.title,
    required this.icon,
    required this.children,
    this.headerColor = ScholarlyTheme.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: JuicySectionHeader(
            title: title,
            icon: icon,
            color: headerColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: JuicyGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            borderRadius: 24,
            child: Column(
              children: children.asMap().entries.map((entry) {
                final idx = entry.key;
                final child = entry.value;
                if (idx == children.length - 1) {
                  return child;
                }
                return Column(
                  children: [
                    child,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.12),
                        height: 1,
                        thickness: 1,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DangerZoneSection extends StatelessWidget {
  final VoidCallback onResetTap;

  const _DangerZoneSection({required this.onResetTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: JuicySectionHeader(
            title: 'DANGER ZONE',
            icon: Icons.dangerous_rounded,
            color: Colors.redAccent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: JuicyGlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 24,
            backgroundColor: const Color(0xFF1E1E24),
            borderColor: Colors.redAccent.withValues(alpha: 0.35),
            child: ListTile(
              onTap: onResetTap,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              title: Text(
                'Reset Progress',
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Wipe ratings, XP, LP, match history & tutorial progress',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitchTile extends ConsumerWidget {
  final String label;
  final String? description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.label,
    this.description,
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
      subtitle: description != null && description!.isNotEmpty
          ? Text(
              description!,
              style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
            )
          : null,
      activeThumbColor: ScholarlyTheme.accentBlue,
      activeTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _NotificationSettingsTile extends ConsumerStatefulWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationSettingsTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  ConsumerState<_NotificationSettingsTile> createState() => _NotificationSettingsTileState();
}

class _NotificationSettingsTileState extends ConsumerState<_NotificationSettingsTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowController;
  late final Animation<Offset> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _arrowAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0.0),
    ).animate(CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(chessProvider.select((s) => s.isNotificationsEnabled));

    if (isEnabled) {
      if (_arrowController.isAnimating) {
        _arrowController.stop();
        _arrowController.reset();
      }
    } else {
      if (!_arrowController.isAnimating) {
        _arrowController.repeat(reverse: true);
      }
    }

    return ListTile(
      onTap: () {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        widget.onTap();
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(
          widget.icon,
          color: ScholarlyTheme.textPrimary,
          size: 20,
        ),
      ),
      title: Text(
        widget.label,
        style: GoogleFonts.inter(
          color: ScholarlyTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        widget.description,
        style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
      ),
      trailing: SlideTransition(
        position: _arrowAnimation,
        child: const Icon(
          Icons.chevron_right_rounded,
          color: ScholarlyTheme.textSubtle,
          size: 20,
        ),
      ),
    );
  }
}
