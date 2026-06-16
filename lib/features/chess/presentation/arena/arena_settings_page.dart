import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/arena_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import 'themes/theme_registry.dart';
import '../shared/themes/chess_theme.dart';
import '../../domain/models/ai_avatar.dart';
import '../widgets/ambient_scaffold.dart';
import 'dart:ui';
import 'arena_personas_selection_page.dart';
import 'chessboard_themes_page.dart';


class ArenaSettingsPage extends ConsumerStatefulWidget {
  const ArenaSettingsPage({super.key});

  @override
  ConsumerState<ArenaSettingsPage> createState() => _ArenaSettingsPageState();
}

class _ArenaSettingsPageState extends ConsumerState<ArenaSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return AmbientScaffold(
      scaffoldKey: _scaffoldKey,
      blob1Color: const Color(0xFFE2E8F0),
      blob2Color: const Color(0xFFDBEAFE),
      blob3Color: const Color(0xFFD1FAE5),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Extra top padding since app bar is gone
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 32),
              ),

              // Title with back button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: ScholarlyTheme.textPrimary),
                        onPressed: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SETTINGS',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
                        label: 'Chess 960',
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



                  // VISUALS
                  _SettingsCategory(
                      title: 'VISUALS',
                      children: [
                        _SettingsTile(
                          label: 'Chessboard Themes',
                          description: 'Current: ${ThemeRegistry.getTheme(state.boardThemeId).name}',
                          icon: Icons.palette_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChessboardThemesPage(),
                              ),
                            );
                          },
                          trailing: _ThemeMiniPreview(
                            theme: ThemeRegistry.getTheme(state.boardThemeId),
                          ),
                        ),
                        _SettingsSwitchTile(
                          label: 'Animations State',
                          icon: state.isAnimationsEnabled
                              ? Icons.auto_awesome_rounded
                              : Icons.auto_awesome_outlined,
                          value: state.isAnimationsEnabled,
                          onChanged: (v) => notifier.toggleAnimations(),
                          enabled: true,
                        ),
                      ],
                    ),

                  // SOUNDS
                  _SettingsCategory(
                    title: 'SOUNDS',
                    children: [
                      _SettingsSwitchTile(
                        label: 'Game Sounds',
                        icon: state.isGameSoundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        value: state.isGameSoundEnabled,
                        onChanged: (v) => notifier.toggleGameSound(),
                        enabled: true,
                      ),
                    ],
                  ),

                  // GAMEPLAY
                  _SettingsCategory(
                      title: 'GAMEPLAY',
                      children: [
                        _SettingsTile(
                          label: 'Time',
                          description: (() {
                            final baseSecs = state.baseTimeDuration.inSeconds;
                            final mins = baseSecs ~/ 60;
                            final secs = baseSecs % 60;
                            final timeStr = secs == 0 ? '$mins' : '$mins:${secs.toString().padLeft(2, '0')}';
                            return '$timeStr+${state.incrementDuration.inSeconds} • Tap to change';
                          })(),
                          icon: Icons.timer_rounded,
                          onTap: () => _showTimeControlSelector(context, ref),
                          trailing: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: ScholarlyTheme.accentBlue,
                          ),
                        ),
                        _SettingsTile(
                          label: 'Personas',
                          description: 'Swipe and select Up & Down engine profiles',
                          icon: Icons.people_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ArenaPersonasSelectionPage(),
                              ),
                            );
                          },
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: ScholarlyTheme.accentBlueSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AiAvatar.getAvatar(state.engineLevel).name,
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.accentBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '↑',
                                      style: TextStyle(
                                        color: ScholarlyTheme.accentBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AiAvatar.getAvatar(state.bottomAvatarId).name,
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.accentBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '↓',
                                      style: TextStyle(
                                        color: ScholarlyTheme.accentBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        _SettingsSwitchTile(
                          label: 'Quick play',
                          description: state.quickPlay
                              ? 'Keep quick play active across all moves'
                              : 'Tap the flash icon once on the board to force play immediately',
                          icon: Icons.flash_on_rounded,
                          value: state.quickPlay,
                          onChanged: (v) => notifier.toggleQuickPlay(v),
                          enabled: true,
                        ),
                      ],
                    ),



                  const SizedBox(height: 120), // Bottom padding
                ]),
              ),
            ],
          ),
        ],
      ),
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

            final bulletPresets = [
              {'label': '0.5+0', 'min': 0, 'sec': 30, 'inc': 0},
              {'label': '1+0', 'min': 1, 'sec': 0, 'inc': 0},
              {'label': '2+1', 'min': 2, 'sec': 0, 'inc': 1},
            ];
            final blitzPresets = [
              {'label': '3+0', 'min': 3, 'sec': 0, 'inc': 0},
              {'label': '3+2', 'min': 3, 'sec': 0, 'inc': 2},
              {'label': '5+0', 'min': 5, 'sec': 0, 'inc': 0},
            ];
            final rapidPresets = [
              {'label': '10+0', 'min': 10, 'sec': 0, 'inc': 0},
              {'label': '15+10', 'min': 15, 'sec': 0, 'inc': 10},
              {'label': '30+0', 'min': 30, 'sec': 0, 'inc': 0},
            ];

            Widget buildGroup(String title, IconData icon, List<Map<String, dynamic>> group) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: ScholarlyTheme.accentBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.map((p) {
                      final isSelected = state.baseTimeDuration.inMinutes == p['min'] &&
                          state.baseTimeDuration.inSeconds % 60 == p['sec'] &&
                          state.incrementDuration.inSeconds == p['inc'];
                      return ChoiceChip(
                        label: Text(p['label'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(arenaProvider.notifier).setTimeControl(
                              Duration(minutes: p['min'] as int, seconds: p['sec'] as int),
                              Duration(seconds: p['inc'] as int),
                            );
                            Navigator.pop(context);
                          }
                        },
                        selectedColor: ScholarlyTheme.accentBlueSoft,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }

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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: ScholarlyTheme.panelStroke,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Time',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        buildGroup('Bullet Arena', Icons.bolt_rounded, bulletPresets),
                        buildGroup('Blitz Arena', Icons.local_fire_department_rounded, blitzPresets),
                        buildGroup('Rapid Arena', Icons.timer_rounded, rapidPresets),
                        const SizedBox(height: 8),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _showCustomTimeControls(BuildContext context, WidgetRef ref) {
    final baseTime = ref.read(chessProvider).baseTimeDuration;
    int totalMinutes = baseTime.inMinutes;
    if (totalMinutes < 1) totalMinutes = 1;
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
                  ref.read(arenaProvider.notifier).setTimeControl(
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

  const _SettingsTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color? effectiveAccent = null;
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
  final String? description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SettingsSwitchTile({
    required this.label,
    this.description,
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
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.switchToggle);
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
        subtitle: description != null && description!.isNotEmpty
            ? (label == 'Quick play'
                ? GestureDetector(
                    onTap: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('⚠️ Opponents may not play at full strength!'),
                          backgroundColor: Colors.orangeAccent,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: Text(
                      description!,
                      style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
                    ),
                  )
                : Text(
                    description!,
                    style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
                  ))
            : null,
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
        // Always use monochrome gradient, never the board PNG image.
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
