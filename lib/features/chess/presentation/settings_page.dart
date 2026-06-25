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

                  // DANGER ZONE
                  _DangerZoneSection(
                    onResetTap: () => _showResetConfirmationDialog(context, ref),
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
