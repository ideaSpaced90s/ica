import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../application/study_lab_provider.dart';
import '../mobile_navigation_shell.dart';
import '../scholarly_theme.dart';
import '../widgets/game_controls.dart';
import 'arena_board.dart';
import '../widgets/captured_pieces_inline.dart';
import '../../domain/models/ai_avatar.dart';
import '../widgets/opponent_avatar_indicator.dart';
import '../widgets/arena_time_display.dart';
import '../widgets/arena_turn_indicator.dart';
import '../widgets/evaluation_bar.dart';
import '../widgets/user_avatar_indicator.dart';
import '../widgets/ambient_flow_backdrop.dart';
import '../widgets/classic_windows_tabs.dart';
import '../dashboard_page.dart';
import 'arena_settings_page.dart';

class ArenaPage extends ConsumerStatefulWidget {
  const ArenaPage({super.key});

  @override
  ConsumerState<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends ConsumerState<ArenaPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ConfettiController _confettiController;
  late ConfettiController _confettiBottomController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiBottomController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _confettiBottomController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final chessState = ref.read(chessProvider);
      if (chessState.recentMoves.isNotEmpty && !chessState.game.gameOver) {
        if (!chessState.isPaused) {
          ref.read(chessProvider.notifier).togglePause();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool? confirm = await _showExitConfirmation(context);
        if (confirm == true) {
          if (context.mounted) {
            exitToDashboardWithSidebar(context, ref);
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ScholarlyTheme.backgroundStart,
        body: Stack(
          children: [
            const AmbientFlowBackdrop(),
            Positioned.fill(
              child: isLandscape
                  ? _buildLandscapeLayout(context, ref, state)
                  : _buildPortraitLayout(context, ref, state),
            ),
            if ((state.game.gameOver || state.isTimeOut) && !state.isGameOverDismissed)
              _buildGameOverOverlay(context, ref, state),
            
            // Confetti Layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: ref.watch(chessProvider.select(
                  (s) => (s.animationSettings['arcadeMode'] ?? false) ? 40 : 20,
                )),
                colors: const [
                  ScholarlyTheme.accentGold,
                  ScholarlyTheme.accentBlue,
                  Colors.white,
                  Colors.yellow,
                  Color(0xFF60A5FA), // arcade blue
                  Color(0xFF7C3AED), // violet
                ],
                createParticlePath: (size) {
                  final path = Path();
                  path.addRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
                  return path;
                },
              ),
            ),
            // Arcade Mode: second bottom-blast confetti
            if (ref.watch(chessProvider.select(
              (s) => s.animationSettings['arcadeMode'] ?? false,
            )))
              Align(
                alignment: Alignment.bottomCenter,
                child: ConfettiWidget(
                  confettiController: _confettiBottomController,
                  blastDirectionality: BlastDirectionality.explosive,
                  blastDirection: -3.14 / 2, // upward
                  shouldLoop: false,
                  numberOfParticles: 30,
                  gravity: 0.05,
                  colors: const [
                    Color(0xFF3B82F6),
                    Color(0xFF60A5FA),
                    Color(0xFFBAE6FD),
                    Colors.white,
                    Color(0xFF7C3AED),
                    ScholarlyTheme.accentGold,
                  ],
                  createParticlePath: (size) {
                    final path = Path();
                    path.addOval(
                      Rect.fromCircle(
                        center: Offset(size.width / 2, size.height / 2),
                        radius: size.width / 2,
                      ),
                    );
                    return path;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, WidgetRef ref, ChessState state) {
    final isTurn = _isPlayerTurn(state);
    final isFlipped = state.isBoardFlipped;
    final topPieces = isFlipped ? state.game.capturedByWhite : state.game.capturedByBlack;
    final bottomPieces = isFlipped ? state.game.capturedByBlack : state.game.capturedByWhite;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT COLUMN (Chessboard Area) - taking 55% of the space
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Opponent Avatar Indicator (Top Left) with Inline Captured Pieces
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      ActiveAvatarWrapper(
                        isActive: !isTurn,
                        child: OpponentAvatarIndicator(
                          avatar: AiAvatar.getAvatar(state.engineLevel),
                          onTap: null, // Read-only from unrated arena
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(child: CapturedPiecesInline(pieces: topPieces)),
                    ],
                  ),
                ),
              ),
              // BoardStage centered
              Expanded(
                child: Stack(
                  children: [
                    const ArenaChessBoard(alignment: Alignment.topCenter),
                    if (state.isPaused) _buildPauseOverlay(context, ref),
                  ],
                ),
              ),
              // User Avatar Indicator (Bottom Right) with Inline Captured Pieces
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      Flexible(child: CapturedPiecesInline(pieces: bottomPieces)),
                      const SizedBox(width: 12),
                      ActiveAvatarWrapper(
                        isActive: isTurn,
                        child: state.isEngineVsEngine
                            ? OpponentAvatarIndicator(
                                avatar: AiAvatar.getAvatar(state.bottomAvatarId),
                                onTap: null, // Read-only from unrated arena
                              )
                            : const UserAvatarIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // VERTICAL SEPARATOR
        Container(
          width: 1.5,
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
        ),

        // RIGHT COLUMN (Sidebar Area) - taking 45% of the space
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Stats & Clocks wrapped in glass
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ArenaTurnIndicator(isActive: isTurn, isWhite: state.isPlayerWhite),
                              const SizedBox(width: 8),
                              EvaluationBar(fillFraction: _getEvalFraction(state, true)),
                            ],
                          ),
                          const Spacer(),
                          ArenaTimeDisplay(isActive: isTurn, timeLeft: state.isPlayerWhite ? state.whiteTimeLeft : state.blackTimeLeft),
                          const SizedBox(width: 12),
                          ArenaTimeDisplay(isActive: !isTurn, timeLeft: state.isPlayerWhite ? state.blackTimeLeft : state.whiteTimeLeft),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EvaluationBar(fillFraction: _getEvalFraction(state, false)),
                              const SizedBox(width: 8),
                              ArenaTurnIndicator(isActive: !isTurn, isWhite: !state.isPlayerWhite),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Center Section: Classic Tabbed Panel
                Expanded(
                  child: ClassicWindowsTabs(state: state),
                ),
                const SizedBox(height: 12),

                // Bottom Section: Action Row (reusing portrait action row!)
                _buildActionRow(context, ref, state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, WidgetRef ref, ChessState state) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isTurn = _isPlayerTurn(state);
    final isFlipped = state.isBoardFlipped;
    final topPieces = isFlipped ? state.game.capturedByWhite : state.game.capturedByBlack;
    final bottomPieces = isFlipped ? state.game.capturedByBlack : state.game.capturedByWhite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Top Row: Stats & Clocks wrapped in glass
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ArenaTurnIndicator(isActive: isTurn, isWhite: state.isPlayerWhite),
                            const SizedBox(width: 8),
                            EvaluationBar(fillFraction: _getEvalFraction(state, true)),
                          ],
                        ),
                        const Spacer(),
                        ArenaTimeDisplay(isActive: isTurn, timeLeft: state.isPlayerWhite ? state.whiteTimeLeft : state.blackTimeLeft),
                        const SizedBox(width: 12),
                        ArenaTimeDisplay(isActive: !isTurn, timeLeft: state.isPlayerWhite ? state.blackTimeLeft : state.whiteTimeLeft),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EvaluationBar(fillFraction: _getEvalFraction(state, false)),
                            const SizedBox(width: 8),
                            ArenaTurnIndicator(isActive: !isTurn, isWhite: !state.isPlayerWhite),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Opponent with active wrapper
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                ActiveAvatarWrapper(
                  isActive: !isTurn,
                  child: OpponentAvatarIndicator(
                    avatar: AiAvatar.getAvatar(state.engineLevel),
                    onTap: null, // Read-only from unrated arena
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(child: CapturedPiecesInline(pieces: topPieces)),
              ],
            ),
          ),
        ),
        // Board
        Expanded(
          child: Stack(
            children: [
              const ArenaChessBoard(alignment: Alignment.topCenter),
              if (state.isPaused) _buildPauseOverlay(context, ref),
            ],
          ),
        ),
        // User with active wrapper
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                Flexible(child: CapturedPiecesInline(pieces: bottomPieces)),
                const SizedBox(width: 12),
                ActiveAvatarWrapper(
                  isActive: isTurn,
                  child: state.isEngineVsEngine
                      ? OpponentAvatarIndicator(
                          avatar: AiAvatar.getAvatar(state.bottomAvatarId),
                          onTap: null, // Read-only from unrated arena
                        )
                      : const UserAvatarIndicator(),
                ),
              ],
            ),
          ),
        ),
        // Actions wrapped in glass dock
        if (!isKeyboardOpen) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildActionRow(context, ref, state),
          ),
        ],
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref, ChessState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActionIconButton(
                  icon: Icons.add_box_rounded, // UNRATED uses +
                  onTap: () => _handleNewGame(context, ref),
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: Icons.undo_rounded,
                  isEnabled: state.canUndo,
                  onTap: state.canUndo ? () => ref.read(chessProvider.notifier).undo() : null,
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: Icons.redo_rounded,
                  isEnabled: state.canRedo,
                  onTap: state.canRedo ? () => ref.read(chessProvider.notifier).redo() : null,
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: Icons.flip_camera_android_outlined,
                  isActive: state.isBoardFlipped,
                  onTap: () => ref.read(chessProvider.notifier).toggleBoardOrientation(),
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  isActive: state.isPaused,
                  onTap: () => ref.read(chessProvider.notifier).togglePause(),
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: state.isEngineVsEngine ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
                  isActive: state.isEngineVsEngine,
                  onTap: () => ref.read(chessProvider.notifier).toggleEngineVsEngine(),
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: Icons.save_rounded,
                  onTap: () => _handleSaveGame(context, ref),
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: state.isBulbGlowing ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                  isEnabled: !state.isHintLoading,
                  isActive: state.isBulbGlowing,
                  activeColor: ScholarlyTheme.accentYellowSoft,
                  activeIconColor: ScholarlyTheme.accentYellow,
                  onTap: () => ref.read(chessProvider.notifier).requestHint(),
                ),
                const SizedBox(width: 8),
                ActionIconButton(
                  icon: Icons.settings_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ArenaSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: GestureDetector(
                onTap: () => ref.read(chessProvider.notifier).togglePause(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.accentBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'RESUME GAME',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, WidgetRef ref, ChessState state) {
    final isDraw = state.game.inDraw;
    final didWin = _didPlayerWin(state);
    
    if (didWin && !_hasTriggeredConfetti) {
      _hasTriggeredConfetti = true;
      _confettiController.play();
      final arcadeMode = ref.read(chessProvider).animationSettings['arcadeMode'] ?? false;
      if (arcadeMode) {
        _confettiBottomController.play();
      }
    }

    String title = isDraw ? 'Match Draw' : (didWin ? 'Victory!' : 'Match Lost');
    String msg = isDraw 
        ? 'A well-fought strategic stalemate.' 
        : (didWin ? 'Congratulations, you have dominated the arena!' : 'Defeat is but a stepping stone to mastery.');
    
    if (state.isTimeOut) {
      title = didWin ? 'Victory (Time)' : 'Loss (Time)';
      msg = didWin ? 'Opponent ran out of time!' : 'You ran out of time!';
    }

    final accentColor = isDraw
        ? ScholarlyTheme.accentBlue
        : (didWin ? ScholarlyTheme.accentGold : const Color(0xFFFC8181));

    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: _SpringEntrance(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.92),
                        Colors.white.withValues(alpha: 0.80),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with glow
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isDraw
                              ? Icons.handshake_rounded
                              : (didWin ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded),
                          size: 36,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Title
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        msg,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _hasTriggeredConfetti = false;
                              });
                              ref.read(chessProvider.notifier).reset();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: didWin ? Colors.black : Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'PLAY NEW MATCH',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _handleSaveGame(context, ref);
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            'SAVE GAME',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.accentBlue,
                            side: BorderSide(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final notifier = ref.read(chessProvider.notifier);
                            // 1. Save current game
                            final entry = await notifier.saveCurrentGame();
                            if (entry != null) {
                              // 2. Lock for analysis
                              await notifier.lockGameForAnalysis(entry.id);
                              // 3. Load into study lab
                              ref.read(studyLabProvider.notifier).loadGameEntry(entry);
                              // 4. Reset Arena state to clean slate
                              await notifier.reset(skipAutoSave: true);
                              // 5. Navigate to analysis tab
                              ref.read(mobileNavIndexProvider.notifier).state = 4;
                            }
                          },
                          icon: const Icon(Icons.science_rounded),
                          label: Text(
                            'ANALYZE GAME',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.accentGold,
                            side: BorderSide(
                              color: ScholarlyTheme.accentGold.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(chessProvider.notifier).dismissGameOver();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.textMuted,
                            side: BorderSide(
                              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'REVIEW BOARD',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
      ),
    );
  }


  bool _didPlayerWin(ChessState state) {
    if (state.game.inDraw) return false;
    
    if (state.isTimeOut) {
      final playerTimedOut = state.isPlayerWhite 
          ? state.whiteTimeLeft <= Duration.zero 
          : state.blackTimeLeft <= Duration.zero;
      return !playerTimedOut;
    }

    // Standard game over
    return !_isPlayerTurn(state);
  }

  bool _isPlayerTurn(ChessState state) {
    if (state.game.fen.split(' ').length > 1) {
      final turnWhite = state.game.fen.split(' ')[1] == 'w';
      return state.isPlayerWhite == turnWhite;
    }
    return true;
  }

  double _getEvalFraction(ChessState state, bool forPlayer) {
    final eval = forPlayer ? (state.isPlayerWhite ? state.currentEvaluation : -state.currentEvaluation) : (state.isPlayerWhite ? -state.currentEvaluation : state.currentEvaluation);
    return (eval.clamp(-5.0, 5.0) + 5.0) / 10.0;
  }

  Future<void> _handleNewGame(BuildContext context, WidgetRef ref) async {
    if (ref.read(chessProvider).recentMoves.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          title: const Text('New Game?'),
          content: const Text('Start a new game? Progress will be saved.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('New Game')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await ref.read(chessProvider.notifier).reset();
  }

  Future<void> _handleSaveGame(BuildContext context, WidgetRef ref) async {
    final entry = await ref.read(chessProvider.notifier).saveCurrentGame();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(entry != null ? 'Saved' : 'Failed'), backgroundColor: ScholarlyTheme.accentBlue));
    }
  }

  Future<bool?> _showExitConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: const Text('Exit IdeaSpace Chess Academy?'),
        content: const Text('Do you want to quit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Quit')),
        ],
      ),
    );
  }
}

class ActiveAvatarWrapper extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const ActiveAvatarWrapper({
    super.key,
    required this.child,
    required this.isActive,
  });

  @override
  State<ActiveAvatarWrapper> createState() => _ActiveAvatarWrapperState();
}

class _ActiveAvatarWrapperState extends State<ActiveAvatarWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(curved);

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ActiveAvatarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.20),
                    blurRadius: 14,
                    spreadRadius: 3,
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class _SpringEntrance extends StatefulWidget {
  final Widget child;
  const _SpringEntrance({required this.child});

  @override
  State<_SpringEntrance> createState() => _SpringEntranceState();
}

class _SpringEntranceState extends State<_SpringEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
