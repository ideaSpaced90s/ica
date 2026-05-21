import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';
import 'package:kingslayer_chess/features/chess/presentation/themes/theme_registry.dart';
import 'package:kingslayer_chess/features/chess/presentation/themes/chess_theme.dart';
import '../domain/models/ai_avatar.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/game_controls.dart';
import 'widgets/avatar_selection_sheet.dart';
import 'widgets/ambient_scaffold.dart';
import 'dart:ui';

class UnratedSettingsPage extends ConsumerStatefulWidget {
  final bool isAcademyMode;

  const UnratedSettingsPage({super.key, this.isAcademyMode = false});

  @override
  ConsumerState<UnratedSettingsPage> createState() => _UnratedSettingsPageState();
}

class _UnratedSettingsPageState extends ConsumerState<UnratedSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return AmbientScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const GlobalSidebar(),
      blob1Color: const Color(0xFFE2E8F0),
      blob2Color: const Color(0xFFDBEAFE),
      blob3Color: const Color(0xFFD1FAE5),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Extra top padding since app bar is gone
              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // Settings Sections
              SliverList(
                delegate: SliverChildListDelegate([
                  // GAME MODE
                  _SettingsCategory(
                    title: 'GAME MODE',
                    children: [
                      _SettingsTile(
                        label: 'Classic Chess',
                        description: 'Standard starting position and orthodox rules',
                        icon: Icons.grid_on_rounded,
                        onTap: () => notifier.setGameMode('classic'),
                        trailing: state.gameMode == 'classic'
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: ScholarlyTheme.accentBlue,
                              )
                            : const SizedBox(),
                      ),
                      _SettingsTile(
                        label: 'Chess 960 (Fischer Random)',
                        description: 'Randomized back-rank setup for dynamic play',
                        icon: Icons.shuffle_rounded,
                        onTap: () => notifier.setGameMode('chess960'),
                        trailing: state.gameMode == 'chess960'
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: ScholarlyTheme.accentBlue,
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),

                  // PREFERENCES
                  _SettingsCategory(
                    title: 'PREFERENCES',
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
                    ],
                  ),

                  // VISUALS
                  if (!widget.isAcademyMode)
                    _SettingsCategory(
                      title: 'VISUALS',
                      children: [
                        _SettingsTile(
                          label: 'Board Theme',
                          description: 'Current: ${ThemeRegistry.getTheme(state.boardThemeId).name}',
                          icon: Icons.palette_rounded,
                          onTap: () => _showThemeSelector(context, ref),
                          trailing: _ThemeMiniPreview(
                            theme: ThemeRegistry.getTheme(state.boardThemeId),
                          ),
                        ),
                        _SettingsTile(
                          label: 'Animation Engine',
                          description: 'Fine-tune movement and effects',
                          icon: Icons.movie_filter_rounded,
                          onTap: () => _showAnimationSettingsOverlay(context, ref),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                        _SettingsSwitchTile(
                          label: 'Master Animations',
                          description: 'Enable or disable all visual effects',
                          icon: state.isAnimationsEnabled
                              ? Icons.auto_awesome_rounded
                              : Icons.auto_awesome_outlined,
                          value: state.isAnimationsEnabled,
                          onChanged: (v) => notifier.toggleAnimations(),
                          enabled: true, // Always enabled in Unrated Arena Settings
                        ),
                      ],
                    ),

                  // GAMEPLAY
                  if (!widget.isAcademyMode)
                    _SettingsCategory(
                      title: 'GAMEPLAY',
                      children: [
                        _SettingsTile(
                          label: 'Time Control',
                          description: '${state.whiteTimeLeft.inMinutes}+${state.incrementDuration.inSeconds} • Tap to change',
                          icon: Icons.timer_rounded,
                          onTap: () => _showTimeControlSelector(context, ref),
                          trailing: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: ScholarlyTheme.accentBlue,
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final currentAvatar = AiAvatar.getAvatar(state.engineLevel);
                            return _SettingsTile(
                              label: 'Persona',
                              description: '${currentAvatar.name} • ${currentAvatar.title}',
                              icon: currentAvatar.icon,
                              imagePath: currentAvatar.imagePath,
                              onTap: () => _showStrengthOverlay(context, ref),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: currentAvatar.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: currentAvatar.color),
                                ),
                                child: Text(
                                  'FIDE ${currentAvatar.fideRatingRange}',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: currentAvatar.color.computeLuminance() > 0.6 ? Colors.black87 : currentAvatar.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 120), // Bottom padding for floating bar
                ]),
              ),
            ], // End of slivers
          ), // End of CustomScrollView

          // Global Consistency Action Row (Floating over the scroll view)
          _buildActionRow(context),
        ], // End of Stack.children
      ), // End of Stack
    ); // End of Scaffold
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
            icon: Icons.menu_rounded,
            size: 24,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Text(
            'UNRATED SETTINGS',
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

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(chessProvider);
            final notifier = ref.read(chessProvider.notifier);

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Board Theme',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ThemeRegistry.allThemes.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final theme = ThemeRegistry.allThemes[index];
                              final isSelected = state.boardThemeId == theme.id;

                              return GestureDetector(
                                onTap: () {
                                  notifier.setBoardTheme(theme.id);
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.lightSquare,
                                            theme.darkSquare,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? ScholarlyTheme.accentBlue
                                              : ScholarlyTheme.panelStroke,
                                          width: isSelected ? 3 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                                                  blurRadius: 10,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: theme.buildPiece(
                                            context,
                                            'N',
                                            true,
                                            false,
                                            0.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      theme.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTimeControlSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(chessProvider);
            final notifier = ref.read(chessProvider.notifier);

            final presets = [
              {'label': '1+0', 'min': 1, 'inc': 0},
              {'label': '3+0', 'min': 3, 'inc': 0},
              {'label': '3+2', 'min': 3, 'inc': 2},
              {'label': '10+0', 'min': 10, 'inc': 0},
              {'label': '10+5', 'min': 10, 'inc': 5},
              {'label': '5+25', 'min': 5, 'inc': 25},
            ];

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Control',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: presets.map((p) {
                          final isSelected = state.whiteTimeLeft.inMinutes == p['min'] &&
                              state.incrementDuration.inSeconds == p['inc'];
                          return ChoiceChip(
                            label: Text(p['label'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                notifier.setTimeControl(
                                  Duration(minutes: p['min'] as int),
                                  Duration(seconds: p['inc'] as int),
                                );
                              }
                            },
                            selectedColor: ScholarlyTheme.accentBlueSoft,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Custom',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _showCustomTimeControls(context, ref),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _showCustomTimeControls(BuildContext context, WidgetRef ref) {
    int totalMinutes = ref.read(chessProvider).whiteTimeLeft.inMinutes;
    int incrementSeconds = ref.read(chessProvider).incrementDuration.inSeconds;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Column(
          children: [
            _TimeSliderRow(
              label: 'Minutes',
              value: totalMinutes.toDouble(),
              min: 1,
              max: 60,
              onChanged: (v) => setDialogState(() => totalMinutes = v.toInt()),
            ),
            const SizedBox(height: 16),
            _TimeSliderRow(
              label: 'Increment',
              value: incrementSeconds.toDouble(),
              min: 0,
              max: 60,
              onChanged: (v) => setDialogState(() => incrementSeconds = v.toInt()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ref.read(chessProvider.notifier).setTimeControl(
                        Duration(minutes: totalMinutes),
                        Duration(seconds: incrementSeconds),
                      );
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Custom Time'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAnimationSettingsOverlay(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(chessProvider);
                final notifier = ref.read(chessProvider.notifier);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.85,
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Animation Engine',
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: ScholarlyTheme.textMuted,
                                      ),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fine-tune your visual experience',
                                  style: GoogleFonts.inter(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _AnimationToggle(
                                  icon: Icons.auto_awesome_motion_rounded,
                                  label: 'Signature Piece Motion',
                                  description: 'Custom arcs, jumps, and rotations per piece type',
                                  value: state.animationSettings['pieceMotion'] ?? true,
                                  onChanged: (v) => notifier.updateAnimationSetting(
                                    'pieceMotion',
                                    v,
                                  ),
                                  enabled: true, // Always active in unrated settings
                                ),
                                _AnimationToggle(
                                  icon: Icons.waves_rounded,
                                  label: 'Interaction Feedback',
                                  description: 'Tap ripples and landing micro-animations',
                                  value: state.animationSettings['feedback'] ?? true,
                                  onChanged: (v) => notifier.updateAnimationSetting(
                                    'feedback',
                                    v,
                                  ),
                                  enabled: true, // Always active in unrated settings
                                ),
                                _AnimationToggle(
                                  icon: Icons.stars_rounded,
                                  label: 'System Indicators',
                                  description: 'Orbiting stars for hints, threats, and focus',
                                  value: state.animationSettings['indicators'] ?? true,
                                  onChanged: (v) => notifier.updateAnimationSetting(
                                    'indicators',
                                    v,
                                  ),
                                  enabled: true, // Always active in unrated settings
                                ),
                                _AnimationToggle(
                                  icon: Icons.flare_rounded,
                                  label: 'Theme Special Effects',
                                  description: 'Capture explosions and movement trails',
                                  value: state.animationSettings['themeEffects'] ?? true,
                                  onChanged: (v) => notifier.updateAnimationSetting(
                                    'themeEffects',
                                    v,
                                  ),
                                  enabled: true, // Always active in unrated settings
                                ),
                                _AnimationToggle(
                                  icon: Icons.blur_on_rounded,
                                  label: 'Theme Ambience',
                                  description: 'Animated backgrounds and square textures',
                                  value: state.animationSettings['themeAmbience'] ?? true,
                                  onChanged: (v) => notifier.updateAnimationSetting(
                                    'themeAmbience',
                                    v,
                                  ),
                                  enabled: true, // Always active in unrated settings
                                ),
                                _AnimationToggle(
                                  icon: Icons.speed_rounded,
                                  label: 'Tactile & Kinetic Impact',
                                  description: 'Piece thuds, dust particles, and impact shakes',
                                  value: state.animationSettings['kineticImpact'] ?? true,
                                  onChanged: (v) => notifier.updateAnimationSetting(
                                    'kineticImpact',
                                    v,
                                  ),
                                  enabled: true, // Always active in unrated settings
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ScholarlyTheme.accentBlue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Done',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(a1.value),
          child: FadeTransition(opacity: a1, child: child),
        );
      },
    );
  }

  void _showStrengthOverlay(BuildContext context, WidgetRef ref) {
    showAvatarSelectionSheet(context, ref, isBottomSlot: false);
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
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        onTap();
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
      trailing: trailing ??
          Icon(
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
  final bool enabled;

  const _SettingsSwitchTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: SwitchListTile(
        value: value,
        onChanged: (v) {
          if (!enabled) return;
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
          onChanged(v);
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.5),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _ThemeMiniPreview extends StatelessWidget {
  final ChessTheme theme;

  const _ThemeMiniPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.lightSquare, theme.darkSquare],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScholarlyTheme.panelStroke),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: theme.buildPiece(context, 'N', true, false, 0.0),
        ),
      ),
    );
  }
}

class _AnimationToggle extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _AnimationToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            if (!enabled) return;
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: value ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: (v) {
                    if (!enabled) return;
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                    onChanged(v);
                  },
                  activeThumbColor: ScholarlyTheme.accentBlue,
                  activeTrackColor: ScholarlyTheme.accentBlue.withValues(
                    alpha: 0.3,
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

class _TimeSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _TimeSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${value.toInt()}',
              style: GoogleFonts.jetBrainsMono(
                color: ScholarlyTheme.accentBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: ScholarlyTheme.accentBlue,
            inactiveTrackColor: ScholarlyTheme.panelStroke,
            thumbColor: ScholarlyTheme.accentBlue,
            overlayColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
