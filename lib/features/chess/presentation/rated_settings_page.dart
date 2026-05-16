import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import '../domain/models/ai_avatar.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/game_controls.dart';
import 'widgets/avatar_selection_sheet.dart';

class RatedSettingsPage extends ConsumerStatefulWidget {
  const RatedSettingsPage({super.key});

  @override
  ConsumerState<RatedSettingsPage> createState() => _RatedSettingsPageState();
}

class _RatedSettingsPageState extends ConsumerState<RatedSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ScholarlyTheme.backgroundStart,
      drawer: const GlobalSidebar(),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // RATED STATUS HEADER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                          ScholarlyTheme.accentBlue.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: ScholarlyTheme.accentBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RATED ARENA ACTIVE',
                                    style: GoogleFonts.inter(
                                      color: ScholarlyTheme.accentBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'Competitive constraints enforced for integrity.',
                                    style: GoogleFonts.inter(
                                      color: ScholarlyTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatItem(label: 'ELO', value: '${state.userFideRating}'),
                            _StatItem(label: 'GAMES', value: '${state.ratedGamesCount}'),
                            _StatItem(label: 'STREAK', value: '${state.currentWinningStreak}🔥'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // SETTINGS SECTIONS
              SliverList(
                delegate: SliverChildListDelegate([
                  // CORE PREFERENCES
                  _SettingsCategory(
                    title: 'PREFERENCES',
                    children: [
                      // Removed Music Option
                      _SettingsSwitchTile(
                        label: 'Sound Effects',
                        description: 'Tactical move audio',
                        icon: state.isSoundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        value: state.isSoundEnabled,
                        onChanged: (v) => notifier.toggleSound(),
                      ),
                      _SettingsSwitchTile(
                        label: 'Haptic Feedback',
                        description: 'Physical impact response',
                        icon: state.isHapticsEnabled
                            ? Icons.vibration_rounded
                            : Icons.vibration_outlined,
                        value: state.isHapticsEnabled,
                        onChanged: (v) => notifier.toggleHaptics(),
                      ),
                    ],
                  ),

                  // GAMEPLAY
                  _SettingsCategory(
                    title: 'GAMEPLAY CONFIGURATION',
                    children: [
                      Builder(
                        builder: (context) {
                          final currentAvatar = AiAvatar.getAvatar(state.engineLevel);
                          return _SettingsTile(
                            label: 'Persona',
                            description: '${currentAvatar.name} • FIDE ${currentAvatar.fideRatingRange}',
                            icon: currentAvatar.icon,
                            imagePath: currentAvatar.imagePath,
                            onTap: () => showAvatarSelectionSheet(context, ref, isReadOnly: true),
                            trailing: Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: ScholarlyTheme.accentBlue,
                            ),
                          );
                        },
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ActionIconButton(
            icon: Icons.arrow_back_rounded,
            size: 24,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }


}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: ScholarlyTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.accentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelBase,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ScholarlyTheme.panelStroke),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? imagePath;

  const _SettingsTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ScholarlyTheme.backgroundStart,
          borderRadius: BorderRadius.circular(12),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  imagePath!,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                icon,
                color: ScholarlyTheme.textPrimary,
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
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: ScholarlyTheme.textSubtle,
            size: 20,
          ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: (v) {
        onChanged(v);
      },
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
              : ScholarlyTheme.backgroundStart,
          borderRadius: BorderRadius.circular(12),
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
