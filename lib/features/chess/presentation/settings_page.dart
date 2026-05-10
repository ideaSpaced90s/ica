import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/saved_game_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Modern Title Bar
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: ScholarlyTheme.textPrimary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Settings',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: ScholarlyTheme.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Game Status Header
              GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GAME STATUS',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              state.game.gameOver 
                                  ? 'Game Over' 
                                  : (state.isPaused ? 'Paused' : 'In Progress'),
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Council status orb
                            Container(
                              width: 8,
                              height: 8,
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
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _StatusClock(
                          label: 'White',
                          timeLeft: state.whiteTimeLeft,
                          isActive: state.clockStarted && state.activeClockSide == 'white',
                        ),
                        const SizedBox(width: 8),
                        _StatusClock(
                          label: 'Black',
                          timeLeft: state.blackTimeLeft,
                          isActive: state.clockStarted && state.activeClockSide == 'black',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Audio & Visual (Compact Grid)
                      const _SectionHeader(title: 'PREFERENCES'),
                      GlassPanel(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: [
                            _SquareSettingsButton(
                              label: 'Music',
                              sunken: state.isMusicEnabled,
                              onTap: () => notifier.toggleMusic(),
                              child: Icon(
                                state.isMusicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                                size: 28,
                                color: state.isMusicEnabled ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                              ),
                            ),
                            _SquareSettingsButton(
                              label: 'Sounds',
                              sunken: state.isSoundEnabled,
                              onTap: () => notifier.toggleSound(),
                              child: Icon(
                                state.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                size: 28,
                                color: state.isSoundEnabled ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                              ),
                            ),
                            _SquareSettingsButton(
                              label: 'Animations',
                              sunken: state.isAnimationsEnabled,
                              onTap: () => notifier.toggleAnimations(),
                              child: Icon(
                                state.isAnimationsEnabled ? Icons.movie_filter_rounded : Icons.movie_filter_outlined,
                                size: 28,
                                color: state.isAnimationsEnabled ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chessboard Themes
                      const _SectionHeader(title: 'CHESSBOARD'),
                      GlassPanel(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: [
                            _SquareSettingsButton(
                              label: 'Classic',
                              sunken: state.boardThemeId == 'classic',
                              onTap: () => notifier.setBoardTheme('classic'),
                              child: _buildThemePreview(const Color(0xFFE8D1B5), const Color(0xFFB58863)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 2',
                              sunken: state.boardThemeId == 'theme2',
                              onTap: () => notifier.setBoardTheme('theme2'),
                              child: _buildThemePreview(const Color(0xFFDEE3E6), const Color(0xFF8CA2AD)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 3',
                              sunken: state.boardThemeId == 'theme3',
                              onTap: () => notifier.setBoardTheme('theme3'),
                              child: _buildThemePreview(const Color(0xFFEBECD0), const Color(0xFF779556)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 4',
                              sunken: state.boardThemeId == 'theme4',
                              onTap: () => notifier.setBoardTheme('theme4'),
                              child: _buildThemePreview(const Color(0xFFBBBBBB), const Color(0xFF666666)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 5',
                              sunken: state.boardThemeId == 'theme5',
                              onTap: () => notifier.setBoardTheme('theme5'),
                              child: _buildThemePreview(const Color(0xFFF3E5F5), const Color(0xFF9575CD)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 6',
                              sunken: state.boardThemeId == 'theme6',
                              onTap: () => notifier.setBoardTheme('theme6'),
                              child: _buildThemePreview(const Color(0xFFE0F2F1), const Color(0xFF006064)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 7',
                              sunken: state.boardThemeId == 'theme7',
                              onTap: () => notifier.setBoardTheme('theme7'),
                              child: _buildThemePreview(const Color(0xFFFFF3E0), const Color(0xFFE64A19)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 8',
                              sunken: state.boardThemeId == 'theme8',
                              onTap: () => notifier.setBoardTheme('theme8'),
                              child: _buildThemePreview(const Color(0xFFECEFF1), const Color(0xFF263238)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 9',
                              sunken: state.boardThemeId == 'theme9',
                              onTap: () => notifier.setBoardTheme('theme9'),
                              child: _buildThemePreview(const Color(0xFFF1F8E9), const Color(0xFF33691E)),
                            ),
                            _SquareSettingsButton(
                              label: 'Theme 10',
                              sunken: state.boardThemeId == 'theme10',
                              onTap: () => notifier.setBoardTheme('theme10'),
                              child: _buildThemePreview(const Color(0xFFF3E5F5), const Color(0xFF4A148C)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Controls
                      const _SectionHeader(title: 'TIME CONTROLS'),
                      GlassPanel(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: [
                            _SquareSettingsButton(
                              onTap: () => notifier.setTimeControl(const Duration(minutes: 1), Duration.zero),
                              sunken: state.whiteTimeLeft.inMinutes == 1 && state.incrementDuration.inSeconds == 0,
                              child: Text('1+0', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setTimeControl(const Duration(minutes: 3), Duration.zero),
                              sunken: state.whiteTimeLeft.inMinutes == 3 && state.incrementDuration.inSeconds == 0,
                              child: Text('3+0', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setTimeControl(const Duration(minutes: 3), const Duration(seconds: 2)),
                              sunken: state.whiteTimeLeft.inMinutes == 3 && state.incrementDuration.inSeconds == 2,
                              child: Text('3+2', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setTimeControl(const Duration(minutes: 10), Duration.zero),
                              sunken: state.whiteTimeLeft.inMinutes == 10 && state.incrementDuration.inSeconds == 0,
                              child: Text('10+0', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setTimeControl(const Duration(minutes: 10), const Duration(seconds: 5)),
                              sunken: state.whiteTimeLeft.inMinutes == 10 && state.incrementDuration.inSeconds == 5,
                              child: Text('10+5', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Auto Play Delay
                      const _SectionHeader(title: 'AUTO PLAY'),
                      GlassPanel(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: [
                            _SquareSettingsButton(
                              onTap: () => notifier.setAutoPlayDelay(Duration.zero),
                              sunken: state.autoPlayDelay.inSeconds == 0,
                              label: 'Instant',
                              child: Text('0s', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setAutoPlayDelay(const Duration(seconds: 2)),
                              sunken: state.autoPlayDelay.inSeconds == 2,
                              child: Text('2s', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setAutoPlayDelay(const Duration(seconds: 3)),
                              sunken: state.autoPlayDelay.inSeconds == 3,
                              child: Text('3s', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setAutoPlayDelay(const Duration(seconds: 4)),
                              sunken: state.autoPlayDelay.inSeconds == 4,
                              child: Text('4s', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setAutoPlayDelay(const Duration(seconds: 5)),
                              sunken: state.autoPlayDelay.inSeconds == 5,
                              child: Text('5s', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                            _SquareSettingsButton(
                              onTap: () => notifier.setAutoPlayDelay(const Duration(seconds: 10)),
                              sunken: state.autoPlayDelay.inSeconds == 10,
                              child: Text('10s', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions Grid
                      const _SectionHeader(title: 'ACTIONS'),
                      GlassPanel(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: [
                            _SquareSettingsButton(
                              label: 'Saves',
                              onTap: () => _showSavedGamesSheet(context, ref),
                              child: Icon(Icons.folder_open_rounded, size: 28, color: ScholarlyTheme.textPrimary),
                            ),
                            _SquareSettingsButton(
                              label: 'Save',
                              onTap: () => notifier.saveCurrentGame(),
                              child: Icon(Icons.save_rounded, size: 28, color: ScholarlyTheme.textPrimary),
                            ),
                            _SquareSettingsButton(
                              label: 'Exit',
                              onTap: () => _confirmSaveAndExit(context, ref),
                              child: Icon(Icons.exit_to_app_rounded, size: 28, color: Colors.red.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildThemePreview(Color c1, Color c2) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Future<void> _confirmSaveAndExit(BuildContext context, WidgetRef ref) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Save the game and exit?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Yes', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                padding: const EdgeInsets.all(18),
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
                          fontSize: 18,
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
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.isSavedGamesLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: saves.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final entry = saves[index];
                              return SavedGameTile(
                                entry: entry,
                                onLoad: () async {
                                  Navigator.of(context).pop(); // close sheet
                                  Navigator.of(context).pop(); // close settings
                                  await notifier.loadSavedGame(entry);
                                },
                                onDelete: () => notifier.deleteSavedGame(entry.id),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: ScholarlyTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
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

class _SquareSettingsButton extends StatelessWidget {
  final Widget child;
  final String? label;
  final VoidCallback onTap;
  final bool sunken;

  const _SquareSettingsButton({
    required this.child,
    this.label,
    required this.onTap,
    this.sunken = false,
  });

  @override
  Widget build(BuildContext context) {
    final sizeInfo = MediaQuery.of(context);
    final isPortrait = sizeInfo.orientation == Orientation.portrait;
    final double portraitBase = sizeInfo.size.height * 0.12;
    final size = (isPortrait ? portraitBase.clamp(40.0, 80.0) : 40.0);
    final outerSize = size + 16;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: outerSize,
        height: outerSize,
        decoration: ScholarlyTheme.modernDecoration().copyWith(
          color: sunken ? ScholarlyTheme.accentBlueSoft : ScholarlyTheme.panelBase,
          border: Border.all(
            color: sunken ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(child: child),
            ),
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: isPortrait ? 11 : 9,
                    fontWeight: sunken ? FontWeight.w600 : FontWeight.w500,
                    color: sunken ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


