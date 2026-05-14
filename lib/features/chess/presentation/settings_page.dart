import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'history_page.dart';
import 'package:kingslayer_chess/features/chess/presentation/themes/theme_registry.dart';
import 'package:kingslayer_chess/features/chess/presentation/themes/chess_theme.dart';
import '../domain/models/ai_avatar.dart';
import 'academy_page.dart';

class SettingsPage extends ConsumerWidget {
  final bool isAcademyMode;

  const SettingsPage({super.key, this.isAcademyMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    if (isAcademyMode) {
      return _buildLandscapeDashboard(context, ref, state, notifier);
    }

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: ScholarlyTheme.backgroundStart,
            surfaceTintColor: ScholarlyTheme.backgroundStart,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ScholarlyTheme.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
              // MATCH TYPE & COMPETITIVE SYSTEM
              if (!isAcademyMode)
                _SettingsCategory(
                  title: 'MATCH TYPE',
                  children: [
                    _SettingsTile(
                      label: 'Casual / Unrated',
                      description: 'Relaxed practice. Rating unaffected, visual animations unrestricted.',
                      icon: Icons.spa_rounded,
                      iconColor: !state.isRatedMode ? ScholarlyTheme.accentBlue : null,
                      onTap: () => notifier.setRatedMode(false),
                      trailing: !state.isRatedMode
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: ScholarlyTheme.accentBlue,
                            )
                          : const SizedBox(),
                    ),
                    _SettingsTile(
                      label: 'Rated Competitive',
                      description: 'Simulated FIDE Elo tracked. Enforces snappy boards and minimal ambient noise.',
                      icon: Icons.emoji_events_rounded,
                      iconColor: state.isRatedMode ? Colors.amber : null,
                      onTap: () => notifier.setRatedMode(true),
                      trailing: state.isRatedMode
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: ScholarlyTheme.accentBlue,
                            )
                          : const SizedBox(),
                    ),
                    // Rating Overview Premium Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ScholarlyTheme.panelBase.withValues(alpha: 0.6),
                              ScholarlyTheme.panelBase,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: state.isRatedMode
                                ? Colors.amber.withValues(alpha: 0.3)
                                : ScholarlyTheme.panelStroke,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: state.ratedGamesCount < 10
                                        ? ScholarlyTheme.accentBlueSoft
                                        : Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    state.ratedGamesCount < 10 ? 'PROVISIONAL' : 'OFFICIAL ELO',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: state.ratedGamesCount < 10
                                          ? ScholarlyTheme.accentBlue
                                          : Colors.amber.shade300,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (state.currentWinningStreak > 0)
                                  Row(
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${state.currentWinningStreak} Streak',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrangeAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${state.userFideRating}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: ScholarlyTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ELO',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ScholarlyTheme.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${state.ratedGamesCount}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: ScholarlyTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Games Played',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: ScholarlyTheme.textSubtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _SettingsTile(
                      label: 'Reset Rated Progress',
                      description: 'Reset rating enhancement to factory default settings',
                      icon: Icons.refresh_rounded,
                      iconColor: Colors.redAccent,
                      onTap: () => _confirmResetRatedStats(context, ref),
                    ),
                  ],
                ),

              // GAME MODE
              _SettingsCategory(
                title: 'GAME MODE',
                children: [
                  _SettingsTile(
                    label: 'Classic Chess',
                    description:
                        'Standard starting position and orthodox rules',
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
              _SettingsCategory(
                title: 'VISUALS',
                children: [
                  _SettingsTile(
                    label: 'Board Theme',
                    description:
                        'Current: ${ThemeRegistry.getTheme(state.boardThemeId).name}',
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
                    trailing: Icon(
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
                    enabled: !state.isRatedMode,
                  ),
                ],
              ),

              // GAMEPLAY
              if (!isAcademyMode)
                _SettingsCategory(
                  title: 'GAMEPLAY',
                  children: [
                    _SettingsTile(
                      label: 'Time Control',
                      description:
                          '${state.whiteTimeLeft.inMinutes}+${state.incrementDuration.inSeconds} • Tap to change',
                      icon: Icons.timer_rounded,
                      onTap: () => _showTimeControlSelector(context, ref),
                      trailing: Icon(
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

              // DATA & MANAGEMENT
              if (!isAcademyMode)
                _SettingsCategory(
                  title: 'MANAGEMENT',
                  children: [
                    _SettingsTile(
                      label: 'Game History',
                      description: 'View, resume, and manage your matches',
                      icon: Icons.history_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HistoryPage(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      label: 'Enter Academy',
                      description: 'Landscape study environment with persistent AI commentary',
                      icon: Icons.school_rounded,
                      iconColor: ScholarlyTheme.accentBlue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AcademyPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

              // DANGER ZONE
              if (!isAcademyMode)
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

  Widget _buildLandscapeDashboard(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
    ChessNotifier notifier,
  ) {
    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      appBar: AppBar(
        backgroundColor: ScholarlyTheme.backgroundStart,
        surfaceTintColor: ScholarlyTheme.backgroundStart,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ScholarlyTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Academy Settings',
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column 1: GAME MODE
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_esports_rounded, size: 16, color: ScholarlyTheme.accentGold),
                          const SizedBox(width: 8),
                          Text(
                            'GAME MODE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.accentGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _CompactGridTile(
                                label: 'Classic Chess',
                                description: 'Standard starting position and orthodox rules',
                                icon: Icons.grid_on_rounded,
                                onTap: () => notifier.setGameMode('classic'),
                                trailing: state.gameMode == 'classic'
                                    ? const Icon(Icons.check_circle_rounded, size: 16, color: ScholarlyTheme.accentBlue)
                                    : null,
                              ),
                              _CompactGridTile(
                                label: 'Chess 960',
                                description: 'Fischer Random setup',
                                icon: Icons.shuffle_rounded,
                                onTap: () => notifier.setGameMode('chess960'),
                                trailing: state.gameMode == 'chess960'
                                    ? const Icon(Icons.check_circle_rounded, size: 16, color: ScholarlyTheme.accentBlue)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Column 2: PREFERENCES
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 16, color: ScholarlyTheme.accentBlue),
                          const SizedBox(width: 8),
                          Text(
                            'PREFERENCES',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.accentBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _CompactGridSwitchTile(
                                label: 'Music',
                                description: 'Background audio',
                                icon: state.isMusicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                                value: state.isMusicEnabled,
                                onChanged: (v) => notifier.toggleMusic(),
                              ),
                              _CompactGridSwitchTile(
                                label: 'Sound Effects',
                                description: 'Move sounds & alerts',
                                icon: state.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                value: state.isSoundEnabled,
                                onChanged: (v) => notifier.toggleSound(),
                              ),
                              _CompactGridSwitchTile(
                                label: 'Haptics',
                                description: 'Impact vibrations',
                                icon: state.isHapticsEnabled ? Icons.vibration_rounded : Icons.vibration_outlined,
                                value: state.isHapticsEnabled,
                                onChanged: (v) => notifier.toggleHaptics(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Column 3: VISUALS
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_rounded, size: 16, color: Colors.purpleAccent),
                          const SizedBox(width: 8),
                          Text(
                            'VISUALS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.purpleAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _CompactGridTile(
                                label: 'Board Theme',
                                description: ThemeRegistry.getTheme(state.boardThemeId).name,
                                icon: Icons.palette_rounded,
                                onTap: () => _showThemeSelector(context, ref),
                                trailing: _ThemeMiniPreview(
                                  theme: ThemeRegistry.getTheme(state.boardThemeId),
                                ),
                              ),
                              _CompactGridTile(
                                label: 'Animation Engine',
                                description: 'Fine-tune movement',
                                icon: Icons.movie_filter_rounded,
                                onTap: () => _showAnimationSettingsOverlay(context, ref),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                              ),
                              _CompactGridSwitchTile(
                                label: 'Animations',
                                description: 'Master toggle',
                                icon: state.isAnimationsEnabled ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                                value: state.isAnimationsEnabled,
                                onChanged: (v) => notifier.toggleAnimations(),
                                enabled: !state.isRatedMode,
                              ),
                            ],
                          ),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
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
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 16),
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
                                            color: ScholarlyTheme.accentBlue
                                                .withValues(alpha: 0.3),
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
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? ScholarlyTheme.accentBlue
                                      : ScholarlyTheme.textPrimary,
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
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
                      final isSelected =
                          state.whiteTimeLeft.inMinutes == p['min'] &&
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
                          color: isSelected
                              ? ScholarlyTheme.accentBlue
                              : ScholarlyTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
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
              onChanged: (v) =>
                  setDialogState(() => incrementSeconds = v.toInt()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref
                      .read(chessProvider.notifier)
                      .setTimeControl(
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

  Future<void> _confirmResetRatedStats(BuildContext context, WidgetRef ref) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reset Rated Progress?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: ScholarlyTheme.textPrimary),
          ),
          content: Text(
            'This action will reset your official ELO rating and games count to factory default settings. Are you sure you want to proceed?',
            style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 14),
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
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (proceed != true) return;

    if (!context.mounted) return;

    final controller = TextEditingController();
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ScholarlyTheme.panelBase,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Re-verification Required',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: ScholarlyTheme.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please type "reset" below to confirm factory reset.',
                    style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'reset',
                      hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textSubtle),
                      filled: true,
                      fillColor: ScholarlyTheme.backgroundStart,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
                  ),
                ),
                FilledButton(
                  onPressed: controller.text.trim().toLowerCase() == 'reset'
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (finalConfirm == true) {
      ref.read(chessProvider.notifier).resetRatedStats();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rated stats reset to factory defaults.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: ScholarlyTheme.accentBlue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                              enabled: !state.isRatedMode,
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
                              enabled: !state.isRatedMode,
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
                              enabled: !state.isRatedMode,
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
                              enabled: !state.isRatedMode,
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
                              enabled: !state.isRatedMode,
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
                              enabled: !state.isRatedMode,
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

  void _showStrengthOverlay(BuildContext context, WidgetRef ref) {
    showAvatarSelectionSheet(context, ref, isBottomSlot: false);
  }
}

void showAvatarSelectionSheet(BuildContext context, WidgetRef ref, {bool isBottomSlot = false}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(chessProvider);
          final currentLevel = isBottomSlot ? state.bottomAvatarId : state.engineLevel;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: ScholarlyTheme.backgroundStart,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: ScholarlyTheme.boardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pill Tab Indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.panelStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Text(
                  isBottomSlot ? 'Select Bottom Avatar' : 'Select Persona',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Each avatar features a custom simulated playing style and FIDE scale',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Scrollable Avatars List
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: AiAvatar.avatars.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final avatar = AiAvatar.avatars[index];
                      final isSelected = currentLevel == avatar.id;
                      final isLightColor = avatar.color.computeLuminance() > 0.6;
                      final iconColor = isLightColor ? Colors.black87 : avatar.color;

                      return InkWell(
                        onTap: () {
                          if (isBottomSlot) {
                            ref.read(chessProvider.notifier).setBottomAvatarId(avatar.id);
                          } else {
                            ref.read(chessProvider.notifier).setEngineLevel(avatar.id);
                          }
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? avatar.color.withValues(alpha: 0.12) 
                                : ScholarlyTheme.panelBase,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? avatar.color 
                                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected ? [] : ScholarlyTheme.cardShadow,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon Badge
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: avatar.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: avatar.color, width: 1.5),
                                ),
                                child: Icon(avatar.icon, color: iconColor, size: 20),
                              ),
                              // Details Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          avatar.name,
                                          style: GoogleFonts.inter(
                                            color: ScholarlyTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (avatar.id == 'avatar_10')
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: ScholarlyTheme.accentBlue,
                                            size: 14,
                                          ),
                                        const Spacer(),
                                        // FIDE Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: avatar.color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'FIDE ${avatar.fideRatingRange}',
                                            style: GoogleFonts.jetBrainsMono(
                                              color: isLightColor ? Colors.black87 : avatar.color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      avatar.title,
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.accentBlue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      avatar.playingStyle,
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textMuted,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
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
                        color: state.game.gameOver
                            ? ScholarlyTheme.textMuted
                            : (state.isPaused ? Colors.red : Colors.green),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (state.game.gameOver
                                        ? ScholarlyTheme.textMuted
                                        : (state.isPaused
                                              ? Colors.red
                                              : Colors.green))
                                    .withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.game.gameOver
                          ? 'GAME OVER'
                          : (state.isPaused ? 'PAUSED' : 'LIVE'),
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
        child: Icon(
          icon,
          color: iconColor ?? ScholarlyTheme.textPrimary,
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
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: SwitchListTile(
        value: value,
        onChanged: (v) {
          if (!enabled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Animations are locked to minimal during Rated play for maximum board responsiveness.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          onChanged(v);
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? ScholarlyTheme.accentBlueSoft
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

// --- KEEPING EXISTING UTILITY WIDGETS ---

class _AnimationToggle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            if (!enabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Animations are locked to minimal during Rated play for maximum board responsiveness.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value
                    ? ScholarlyTheme.accentBlue.withValues(alpha: 0.3)
                    : Colors.transparent,
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
                    color: value
                        ? ScholarlyTheme.accentBlue
                        : ScholarlyTheme.textMuted,
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
                    if (!enabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Animations are locked to minimal during Rated play for maximum board responsiveness.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
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
        color: isActive
            ? ScholarlyTheme.accentBlueSoft
            : ScholarlyTheme.panelBase,
        border: Border.all(
          color: isActive
              ? ScholarlyTheme.accentBlue
              : ScholarlyTheme.panelStroke,
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
              color: isActive
                  ? ScholarlyTheme.accentBlue
                  : ScholarlyTheme.textMuted,
            ),
          ),
          Text(
            formatTime(timeLeft),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? ScholarlyTheme.accentBlue
                  : ScholarlyTheme.textPrimary,
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

class _CompactGridTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _CompactGridTile({
    required this.label,
    required this.description,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelBase.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ScholarlyTheme.panelStroke, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: ScholarlyTheme.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 9,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactGridSwitchTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _CompactGridSwitchTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: InkWell(
          onTap: () {
            if (!enabled) return;
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: value
                  ? ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.5)
                  : ScholarlyTheme.panelBase.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: value ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: value,
                      onChanged: enabled ? onChanged : null,
                      activeThumbColor: ScholarlyTheme.accentBlue,
                    ),
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
