import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';
import '../../domain/models/historical_game.dart';
import '../../domain/models/tutorial_lesson.dart' show MentorMood;
import '../../application/historical_cinema_provider.dart';
import '../../services/chess_sound_service.dart';
import '../../application/chess_provider.dart' show chessProvider, chessSoundServiceProvider;
import '../arena/themes/theme_registry.dart';
import '../shared/widgets/chess_piece_widget.dart';

class HistoricalCinemaPage extends ConsumerStatefulWidget {
  const HistoricalCinemaPage({super.key});

  @override
  ConsumerState<HistoricalCinemaPage> createState() => _HistoricalCinemaPageState();
}

class _HistoricalCinemaPageState extends ConsumerState<HistoricalCinemaPage> {
  final ScrollController _tapeScrollController = ScrollController();
  final chess_lib.Chess _board = chess_lib.Chess();

  @override
  void dispose() {
    _tapeScrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveMove(int index, int totalMoves) {
    if (!_tapeScrollController.hasClients) return;
    
    // Each move item is roughly 60px wide
    final double targetOffset = (index * 60.0) - 100.0;
    final maxScroll = _tapeScrollController.position.maxScrollExtent;
    
    _tapeScrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Color _getMoodColor(MentorMood mood) {
    switch (mood) {
      case MentorMood.encouraging:
        return const Color(0xFF10B981); // Emerald Green
      case MentorMood.correction:
        return const Color(0xFFF59E0B); // Amber
      case MentorMood.celebration:
        return const Color(0xFFF59E0B); // Gold/Gold tint
      case MentorMood.calm:
        return ScholarlyTheme.accentBlue;
    }
  }

  String _getMoodName(MentorMood mood) {
    switch (mood) {
      case MentorMood.encouraging:
        return "GM CHANAKYA — ENCOURAGING";
      case MentorMood.correction:
        return "GM CHANAKYA — CORRECTIVE";
      case MentorMood.celebration:
        return "GM CHANAKYA — TRIUMPHANT";
      case MentorMood.calm:
        return "GM CHANAKYA";
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historicalCinemaProvider);
    final notifier = ref.read(historicalCinemaProvider.notifier);
    final soundService = ref.read(chessSoundServiceProvider);

    ref.listen<HistoricalCinemaState>(historicalCinemaProvider, (previous, next) {
      final oldGame = previous?.activeGame;
      final newGame = next.activeGame;
      if (newGame == null) return;
      
      // If we switched games, don't play chess move sounds, just reset/ignore
      if (oldGame?.id != newGame.id) {
        return;
      }
      
      final oldIdx = previous?.currentMoveIndex ?? 0;
      final newIdx = next.currentMoveIndex;
      
      if (newIdx > oldIdx) {
        // Player advanced forward
        final moveIndex = newIdx - 1;
        if (moveIndex >= 0 && moveIndex < newGame.moves.length) {
          final moveSan = newGame.moves[moveIndex];
          _playSanMoveSound(moveSan, soundService);
        }
      } else if (newIdx < oldIdx) {
        // Player stepped backward
        if (newIdx > 0) {
          soundService.playSfx(SoundEffect.move);
        }
      }
    });

    final game = state.activeGame;
    if (game == null) {
      return const AmbientScaffold(
        body: Center(child: Text("No game active.")),
      );
    }

    // Scroll the tape to follow active index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveMove(state.currentMoveIndex, game.moves.length);
    });

    // Sync board state to active move FEN
    final currentFen = game.fens[state.currentMoveIndex];
    _board.load(currentFen);

    // Get current commentary
    HistoricalAnnotation? activeCommentary;
    // Walk backward to find the last displayed commentary
    for (int i = state.currentMoveIndex; i >= 0; i--) {
      if (game.annotations.containsKey(i)) {
        activeCommentary = game.annotations[i];
        break;
      }
    }
    
    final commentaryText = activeCommentary?.commentary ?? 
        (state.currentMoveIndex > 0 
            ? "Move ${state.currentMoveIndex}: ${game.moves[state.currentMoveIndex - 1]}" 
            : "Select a game to begin playback, Apprentice.");
    final commentaryMood = activeCommentary?.mood ?? MentorMood.calm;
    final moodColor = _getMoodColor(commentaryMood);

    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    Widget boardWidget = _buildChessBoard(context, currentFen);
    Widget controlsWidget = _buildMediaControls(context, state, notifier, soundService);
    Widget commentaryWidget = _buildCommentaryPanel(context, commentaryText, commentaryMood, moodColor);
    Widget moveTapeWidget = _buildMoveTape(context, game, state.currentMoveIndex, notifier, soundService);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          notifier.pause();
        }
      },
      child: AmbientScaffold(
        blob1Color: const Color(0xFFFEF9C3), // Soft Gold
        blob2Color: const Color(0xFFDBEAFE), // Soft Blue
        blob3Color: const Color(0xFFF3E8FF), // Soft Purple
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Header
              _buildHeader(context, game),
              
              Expanded(
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side: Chess board and tape
                          Expanded(
                            flex: 11,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Expanded(child: Center(child: AspectRatio(aspectRatio: 1.0, child: boardWidget))),
                                  const SizedBox(height: 10),
                                  moveTapeWidget,
                                ],
                              ),
                            ),
                          ),
                          // Vertical divider
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 24),
                            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                          ),
                          // Right side: Commentary and media controls
                          Expanded(
                            flex: 9,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: commentaryWidget),
                                  const SizedBox(height: 12),
                                  controlsWidget,
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Board
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: boardWidget,
                          ),
                          // Move Tape
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: moveTapeWidget,
                          ),
                          // Commentary bubble
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: commentaryWidget,
                            ),
                          ),
                          // Media controls
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: controlsWidget,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HistoricalGame game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${game.white} vs. ${game.black}".toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${game.event} (${game.year}) — ${game.educationalTheme}",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ScholarlyTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChessBoard(BuildContext context, String fen) {
    final activeThemeId = ref.watch(chessProvider).boardThemeId;
    final theme = ThemeRegistry.getTheme(activeThemeId);
    _board.load(fen);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              boxShadow: ScholarlyTheme.boardShadow,
              border: Border.all(color: theme.frameColor, width: 2),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              padding: EdgeInsets.zero,
              itemCount: 64,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final row = index ~/ 8;
                final col = index % 8;
                final isLight = (row + col) % 2 == 0;
                final squareName = _getSquareName(row, col);
                final pieceObj = _board.get(squareName);

                return Container(
                  decoration: BoxDecoration(
                    color: isLight ? theme.lightSquare : theme.darkSquare,
                  ),
                  child: Stack(
                    children: [
                      if (pieceObj != null)
                        Center(
                          child: ChessPieceWidget(
                            squareName: squareName,
                            pieceCode: '${pieceObj.color == chess_lib.Color.WHITE ? 'w' : 'b'}${pieceObj.type.toUpperCase()}',
                            highlighted: false,
                            theme: theme,
                            isMoving: false,
                          ),
                        ),
                      if (col == 0 || row == 7)
                        _buildCoordinateLabel(row, col, isLight),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getSquareName(int row, int col) {
    final fileChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rankChar = String.fromCharCode('1'.codeUnitAt(0) + (7 - row));
    return '$fileChar$rankChar';
  }

  Widget _buildCoordinateLabel(int row, int col, bool isLight) {
    final textColor = isLight ? Colors.black54 : Colors.white70;
    return Stack(
      children: [
        if (col == 0)
          Positioned(
            top: 2,
            left: 3,
            child: Text(
              '${8 - row}',
              style: TextStyle(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (row == 7)
          Positioned(
            bottom: 2,
            right: 3,
            child: Text(
              String.fromCharCode('a'.codeUnitAt(0) + col),
              style: TextStyle(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaControls(
    BuildContext context,
    HistoricalCinemaState state,
    HistoricalCinemaNotifier notifier,
    ChessSoundService soundService,
  ) {
    final isPlaying = state.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Jump to Start
          _buildControlButton(
            icon: Icons.skip_previous_rounded,
            tooltip: "Jump to Start",
            onPressed: () {
              soundService.playSfx(SoundEffect.click);
              notifier.jumpToMove(0);
            },
          ),
          // Step Back
          _buildControlButton(
            icon: Icons.chevron_left_rounded,
            tooltip: "Previous Move",
            onPressed: state.currentMoveIndex > 0
                ? () {
                    notifier.previousMove();
                  }
                : null,
          ),
          // Play / Pause
          GestureDetector(
            onTap: () {
              soundService.playSfx(SoundEffect.click);
              notifier.togglePlay();
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ScholarlyTheme.accentBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          // Step Forward
          _buildControlButton(
            icon: Icons.chevron_right_rounded,
            tooltip: "Next Move",
            onPressed: state.activeGame != null && state.currentMoveIndex < state.activeGame!.moves.length
                ? () {
                    notifier.nextMove();
                  }
                : null,
          ),
          // Jump to End
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            tooltip: "Jump to End",
            onPressed: state.activeGame != null
                ? () {
                    soundService.playSfx(SoundEffect.click);
                    notifier.jumpToMove(state.activeGame!.moves.length);
                  }
                : null,
          ),
          // Speed Indicator Chip
          _buildSpeedControl(state, notifier, soundService),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 24),
        color: ScholarlyTheme.textPrimary,
        disabledColor: ScholarlyTheme.textSubtle.withValues(alpha: 0.4),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSpeedControl(
    HistoricalCinemaState state,
    HistoricalCinemaNotifier notifier,
    ChessSoundService soundService,
  ) {
    final speeds = [4.0, 2.5, 1.5]; // Slow, Medium, Fast
    final labels = ["0.5x", "1.0x", "1.5x"];
    
    int currentIdx = speeds.indexOf(state.playbackSpeedSeconds);
    if (currentIdx == -1) currentIdx = 1; // Default to medium

    return GestureDetector(
      onTap: () {
        soundService.playSfx(SoundEffect.click);
        final nextIdx = (currentIdx + 1) % speeds.length;
        notifier.setSpeed(speeds[nextIdx]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          labels[currentIdx],
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentaryPanel(
    BuildContext context,
    String text,
    MentorMood mood,
    Color moodColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: moodColor.withValues(alpha: 0.28), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mentor Profile Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: moodColor.withValues(alpha: 0.4), width: 1.5),
                  image: const DecorationImage(
                    image: AssetImage('assets/persona/gm_chanakya.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMoodName(mood),
                      style: GoogleFonts.inter(
                        color: moodColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Sage of the Academy",
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildCommentaryText(
                text,
                GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaryText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: baseStyle.color,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildMoveTape(
    BuildContext context,
    HistoricalGame game,
    int activeIdx,
    HistoricalCinemaNotifier notifier,
    ChessSoundService soundService,
  ) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        controller: _tapeScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: game.moves.length + 1,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final isStart = index == 0;
          final label = isStart ? "Start" : "${(index - 1) ~/ 2 + 1}${ (index - 1) % 2 == 0 ? '.' : '...' } ${game.moves[index - 1]}";
          final isActive = index == activeIdx;

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isActive,
              selectedColor: ScholarlyTheme.accentGold.withValues(alpha: 0.25),
              checkmarkColor: Colors.transparent,
              showCheckmark: false,
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              side: BorderSide(
                color: isActive
                    ? ScholarlyTheme.accentGold
                    : ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
                width: isActive ? 1.5 : 1.0,
              ),
              labelStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? ScholarlyTheme.textPrimary : ScholarlyTheme.textMuted,
              ),
              onSelected: (selected) {
                if (selected) {
                  soundService.playSfx(SoundEffect.click);
                  notifier.jumpToMove(index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _playSanMoveSound(String san, ChessSoundService soundService) {
    final cleanSan = san.toUpperCase();
    if (cleanSan.contains('O-O') || cleanSan.contains('0-0')) {
      soundService.playSfx(SoundEffect.castle);
    } else if (cleanSan.contains('+') || cleanSan.contains('#')) {
      soundService.playSfx(SoundEffect.check);
    } else if (cleanSan.contains('=')) {
      soundService.playSfx(SoundEffect.promote);
    } else if (cleanSan.contains('X')) {
      soundService.playSfx(SoundEffect.capture);
    } else {
      soundService.playSfx(SoundEffect.move);
    }
  }
}
