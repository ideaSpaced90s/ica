import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'package:kingslayer_chess/features/chess/presentation/themes/theme_registry.dart';
import 'widgets/saved_game_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern Large App Bar
          SliverAppBar.large(
            backgroundColor: ScholarlyTheme.backgroundStart,
            surfaceTintColor: ScholarlyTheme.backgroundStart,
            title: Text(
              'Settings',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ScholarlyTheme.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: ScholarlyTheme.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Game Status Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _GameStatusHeader(state: state),
            ),
          ),

          // Settings Sections
          SliverList(
            delegate: SliverChildListDelegate([
              // PREFERENCES
              _SettingsCategory(
                title: 'PREFERENCES',
                children: [
                  _SettingsSwitchTile(
                    label: 'Music',
                    description: 'Background music during gameplay',
                    icon: state.isMusicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                    value: state.isMusicEnabled,
                    onChanged: (v) => notifier.toggleMusic(),
                  ),
                  _SettingsSwitchTile(
                    label: 'Sound Effects',
                    description: 'Move sounds and capture alerts',
                    icon: state.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    value: state.isSoundEnabled,
                    onChanged: (v) => notifier.toggleSound(),
                  ),
                  _SettingsSwitchTile(
                    label: 'Haptic Feedback',
                    description: 'Vibrations for physical impact',
                    icon: state.isHapticsEnabled ? Icons.vibration_rounded : Icons.vibration_outlined,
                    value: state.isHapticsEnabled,
                    onChanged: (v) => notifier.toggleHaptics(),
                  ),
                ],
              ),

              // VISUALS
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
                    trailing: Icon(Icons.chevron_right_rounded, color: ScholarlyTheme.textMuted),
                  ),
                  _SettingsSwitchTile(
                    label: 'Master Animations',
                    description: 'Enable or disable all visual effects',
                    icon: state.isAnimationsEnabled ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                    value: state.isAnimationsEnabled,
                    onChanged: (v) => notifier.toggleAnimations(),
                  ),
                ],
              ),

              // GAMEPLAY
              _SettingsCategory(
                title: 'GAMEPLAY',
                children: [
                  _SettingsTile(
                    label: 'Time Control',
                    description: '${state.whiteTimeLeft.inMinutes}+${state.incrementDuration.inSeconds} • Tap to change',
                    icon: Icons.timer_rounded,
                    onTap: () => _showTimeControlSelector(context, ref),
                    trailing: Icon(Icons.edit_rounded, size: 18, color: ScholarlyTheme.accentBlue),
                  ),
                ],
              ),

              // DATA & MANAGEMENT
              _SettingsCategory(
                title: 'MANAGEMENT',
                children: [
                  _SettingsTile(
                    label: 'Saved Games',
                    description: 'View and restore previous matches',
                    icon: Icons.folder_open_rounded,
                    onTap: () => _showSavedGamesSheet(context, ref),
                  ),
                  _SettingsTile(
                    label: 'Save Current Game',
                    description: 'Sync progress to local storage',
                    icon: Icons.save_rounded,
                    onTap: () {
                      notifier.saveCurrentGame();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Game saved successfully')),
                      );
                    },
                  ),
                ],
              ),

              // DANGER ZONE
              _SettingsCategory(
                title: 'EXIT',
                children: [
                  _SettingsTile(
                    label: 'Exit Game',
                    description: 'Save and return to system',
                    icon: Icons.exit_to_app_rounded,
                    iconColor: Colors.red.shade600,
                    onTap: () => _confirmSaveAndExit(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(chessProvider);
            final notifier = ref.read(chessProvider.notifier);

            return GlassPanel(
              padding: const EdgeInsets.all(20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                          onTap: () => notifier.setBoardTheme(theme.id),
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [theme.lightSquare, theme.darkSquare],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3), blurRadius: 10)]
                                      : [],
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

            return GlassPanel(
              padding: const EdgeInsets.all(24),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                  ref.read(chessProvider.notifier).setTimeControl(
                    Duration(minutes: totalMinutes),
                    Duration(seconds: incrementSeconds),
                  );
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Custom Time'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmSaveAndExit(BuildContext context, WidgetRef ref) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Save the game and exit?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'No',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit != true) return;

    final notifier = ref.read(chessProvider.notifier);
    await notifier.saveCurrentGame();
    await notifier.shutdown();
    SystemNavigator.pop();
  }

  Future<void> _showSavedGamesSheet(BuildContext context, WidgetRef ref) async {
    await ref.read(chessProvider.notifier).loadSavedGames();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(chessProvider);
            final notifier = ref.read(chessProvider.notifier);
            final saves = state.savedGames;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GlassPanel(
                padding: const EdgeInsets.all(14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.72,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved games',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        saves.isEmpty
                            ? 'No saved games yet.'
                            : 'Tap a save to restore it.',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.isSavedGamesLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: saves.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final entry = saves[index];
                              return SavedGameTile(
                                entry: entry,
                                onLoad: () async {
                                  Navigator.of(context).pop(); // close sheet
                                  Navigator.of(context).pop(); // close settings
                                  await notifier.loadSavedGame(entry);
                                },
                                onDelete: () =>
                                    notifier.deleteSavedGame(entry.id),
                              );
                            },
                          ),
                        ),
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
                  child: GlassPanel(
                    padding: const EdgeInsets.all(20),
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
                              description:
                                  'Custom arcs, jumps, and rotations per piece type',
                              value:
                                  state.animationSettings['pieceMotion'] ??
                                  true,
                              onChanged: (v) => notifier.updateAnimationSetting(
                                'pieceMotion',
                                v,
                              ),
                            ),
                            _AnimationToggle(
                              icon: Icons.videocam_rounded,
                              label: 'Cinematic Camera',
                              description:
                                  'Dynamic zoom and subtle board drift effects',
                              value: state.animationSettings['camera'] ?? true,
                              onChanged: (v) =>
                                  notifier.updateAnimationSetting('camera', v),
                            ),
                            _AnimationToggle(
                              icon: Icons.waves_rounded,
                              label: 'Interaction Feedback',
                              description:
                                  'Tap ripples and landing micro-animations',
                              value:
                                  state.animationSettings['feedback'] ?? true,
                              onChanged: (v) => notifier.updateAnimationSetting(
                                'feedback',
                                v,
                              ),
                            ),
                            _AnimationToggle(
                              icon: Icons.stars_rounded,
                              label: 'System Indicators',
                              description:
                                  'Orbiting stars for hints, threats, and focus',
                              value:
                                  state.animationSettings['indicators'] ?? true,
                              onChanged: (v) => notifier.updateAnimationSetting(
                                'indicators',
                                v,
                              ),
                            ),
                            _AnimationToggle(
                              icon: Icons.flare_rounded,
                              label: 'Theme Special Effects',
                              description:
                                  'Capture explosions and movement trails',
                              value:
                                  state.animationSettings['themeEffects'] ??
                                  true,
                              onChanged: (v) => notifier.updateAnimationSetting(
                                'themeEffects',
                                v,
                              ),
                            ),
                            _AnimationToggle(
                              icon: Icons.blur_on_rounded,
                              label: 'Theme Ambience',
                              description:
                                  'Animated backgrounds and square textures',
                              value:
                                  state.animationSettings['themeAmbience'] ??
                                  true,
                              onChanged: (v) => notifier.updateAnimationSetting(
                                'themeAmbience',
                                v,
                              ),
                            ),
                            _AnimationToggle(
                              icon: Icons.speed_rounded,
                              label: 'Tactile & Kinetic Impact',
                              description:
                                  'Piece thuds, dust particles, and impact shakes',
                              value:
                                  state.animationSettings['kineticImpact'] ??
                                  true,
                              onChanged: (v) => notifier.updateAnimationSetting(
                                'kineticImpact',
                                v,
                              ),
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
}

// --- NEW HELPER WIDGETS ---

class _GameStatusHeader extends StatelessWidget {
  final dynamic state; // ChessState

  const _GameStatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isCouncilOnline ? Colors.green : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: (state.isCouncilOnline ? Colors.green : Colors.red).withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.game.gameOver ? 'GAME OVER' : (state.isPaused ? 'PAUSED' : 'LIVE'),
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.game.gameOver ? 'Results ready' : 'Match in progress',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _StatusClock(
            label: 'W',
            timeLeft: state.whiteTimeLeft,
            isActive: state.clockStarted && state.activeClockSide == 'white',
          ),
          const SizedBox(width: 8),
          _StatusClock(
            label: 'B',
            timeLeft: state.blackTimeLeft,
            isActive: state.clockStarted && state.activeClockSide == 'black',
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
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.label,
    required this.description,
    required this.icon,
    this.iconColor,
    required this.onTap,
    this.trailing,
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
        child: Icon(icon, color: iconColor ?? ScholarlyTheme.textPrimary, size: 20),
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
        style: GoogleFonts.inter(
          color: ScholarlyTheme.textMuted,
          fontSize: 11,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: ScholarlyTheme.textSubtle, size: 20),
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
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? ScholarlyTheme.accentBlueSoft : ScholarlyTheme.backgroundStart,
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
        style: GoogleFonts.inter(
          color: ScholarlyTheme.textMuted,
          fontSize: 11,
        ),
      ),
      activeThumbColor: ScholarlyTheme.accentBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ThemeMiniPreview extends StatelessWidget {
  final dynamic theme;

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
    );
  }
}

// --- KEEPING EXISTING UTILITY WIDGETS ---

class _AnimationToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnimationToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onChanged(!value),
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
                  color: ScholarlyTheme.panelBase,
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
                onChanged: onChanged,
                activeThumbColor: ScholarlyTheme.accentBlue,
                activeTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusClock extends StatelessWidget {
  final String label;
  final Duration timeLeft;
  final bool isActive;

  const _StatusClock({
    required this.label,
    required this.timeLeft,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    String formatTime(Duration d) {
      final mins = d.inMinutes.toString().padLeft(2, '0');
      final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$mins:$secs';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ScholarlyTheme.modernDecoration().copyWith(
        color: isActive ? ScholarlyTheme.accentBlueSoft : ScholarlyTheme.panelBase,
        border: Border.all(
          color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
            ),
          ),
          Text(
            formatTime(timeLeft),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
            ),
          ),
        ],
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
