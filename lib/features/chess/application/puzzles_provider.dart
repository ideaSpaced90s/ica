import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;

import '../domain/chess_game.dart';
import '../data/puzzle_repository.dart';
import '../data/prescription_puzzle_repository.dart';
import 'battleground_provider.dart';
import '../services/chess_haptics_service.dart';
import '../data/saved_game.dart'; // For CommentaryEntry
import 'chess_provider.dart' show MoveAnimationData, chessProvider, chessHapticsServiceProvider;

const _sentinel = Object();

class PuzzlesState {
  final ChessGame game;
  final rust_puzzles.Puzzle? currentPuzzle;
  final List<String> puzzleMovesRemaining;
  final List<String> recentMoves;
  final String? lastMove;
  final bool isBoardFlipped;
  final bool isPlayerWhite;
  final List<CommentaryEntry> commentaryHistory;
  final String? commentaryError;
  final bool isBulbGlowing;
  final bool isHintVisible;
  final String? hintBestMove;
  final String? hintFrom;
  final String? hintTo;
  final bool isHintLoading;
  final bool isHintBlinking;
  final MoveAnimationData? moveAnimation;
  final List<String> threatenedSquares;
  final bool isPuzzleMode;
  final ScotomaAxis? activeAxis;
  final bool isPressureCookerActive;

  PuzzlesState({
    required this.game,
    this.currentPuzzle,
    this.puzzleMovesRemaining = const [],
    this.recentMoves = const [],
    this.lastMove,
    this.isBoardFlipped = false,
    this.isPlayerWhite = true,
    this.commentaryHistory = const [],
    this.commentaryError,
    this.isBulbGlowing = false,
    this.isHintVisible = false,
    this.hintBestMove,
    this.hintFrom,
    this.hintTo,
    this.isHintLoading = false,
    this.isHintBlinking = false,
    this.moveAnimation,
    this.threatenedSquares = const [],
    this.isPuzzleMode = false,
    this.activeAxis,
    this.isPressureCookerActive = false,
  });

  PuzzlesState copyWith({
    ChessGame? game,
    Object? currentPuzzle = _sentinel,
    List<String>? puzzleMovesRemaining,
    List<String>? recentMoves,
    Object? lastMove = _sentinel,
    bool? isBoardFlipped,
    bool? isPlayerWhite,
    List<CommentaryEntry>? commentaryHistory,
    Object? commentaryError = _sentinel,
    bool? isBulbGlowing,
    bool? isHintVisible,
    Object? hintBestMove = _sentinel,
    Object? hintFrom = _sentinel,
    Object? hintTo = _sentinel,
    bool? isHintLoading,
    bool? isHintBlinking,
    Object? moveAnimation = _sentinel,
    List<String>? threatenedSquares,
    bool? isPuzzleMode,
    Object? activeAxis = _sentinel,
    bool? isPressureCookerActive,
  }) {
    return PuzzlesState(
      game: game ?? this.game,
      currentPuzzle: identical(currentPuzzle, _sentinel)
          ? this.currentPuzzle
          : currentPuzzle as rust_puzzles.Puzzle?,
      puzzleMovesRemaining: puzzleMovesRemaining ?? this.puzzleMovesRemaining,
      recentMoves: recentMoves ?? this.recentMoves,
      lastMove: identical(lastMove, _sentinel) ? this.lastMove : lastMove as String?,
      isBoardFlipped: isBoardFlipped ?? this.isBoardFlipped,
      isPlayerWhite: isPlayerWhite ?? this.isPlayerWhite,
      commentaryHistory: commentaryHistory ?? this.commentaryHistory,
      commentaryError: identical(commentaryError, _sentinel)
          ? this.commentaryError
          : commentaryError as String?,
      isBulbGlowing: isBulbGlowing ?? this.isBulbGlowing,
      isHintVisible: isHintVisible ?? this.isHintVisible,
      hintBestMove: identical(hintBestMove, _sentinel)
          ? this.hintBestMove
          : hintBestMove as String?,
      hintFrom: identical(hintFrom, _sentinel) ? this.hintFrom : hintFrom as String?,
      hintTo: identical(hintTo, _sentinel) ? this.hintTo : hintTo as String?,
      isHintLoading: isHintLoading ?? this.isHintLoading,
      isHintBlinking: isHintBlinking ?? this.isHintBlinking,
      moveAnimation: identical(moveAnimation, _sentinel)
          ? this.moveAnimation
          : moveAnimation as MoveAnimationData?,
      threatenedSquares: threatenedSquares ?? this.threatenedSquares,
      isPuzzleMode: isPuzzleMode ?? this.isPuzzleMode,
      activeAxis: identical(activeAxis, _sentinel) ? this.activeAxis : activeAxis as ScotomaAxis?,
      isPressureCookerActive: isPressureCookerActive ?? this.isPressureCookerActive,
    );
  }
}

class PuzzlesNotifier extends StateNotifier<PuzzlesState> {
  PuzzlesNotifier(
    this.ref,
    this._puzzleRepository,
    this._prescriptionRepository,
    this._hapticsService,
  ) : super(PuzzlesState(game: ChessGame(fen: '8/8/8/8/8/8/8/8 w - - 0 1')));

  final Ref ref;
  final PuzzleRepository _puzzleRepository;
  final PrescriptionPuzzleRepository _prescriptionRepository;
  final ChessHapticsService _hapticsService;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> startPuzzleMode({bool silent = false}) async {
    state = state.copyWith(isPuzzleMode: true);
    await nextPuzzle(silent: silent);
  }

  Future<void> startPrescriptionMode({bool silent = false}) async {
    state = state.copyWith(isPuzzleMode: true);
    await nextPrescriptionPuzzle(silent: silent);
  }

  Future<void> exitPuzzleMode() async {
    state = PuzzlesState(
      game: ChessGame(fen: '8/8/8/8/8/8/8/8 w - - 0 1'),
      isPuzzleMode: false,
    );
  }

  Future<void> nextPuzzle({bool silent = false}) async {
    if (!state.isPuzzleMode) return;

    debugPrint('PuzzlesNotifier: Requesting next puzzle...');
    try {
      final puzzle = await _puzzleRepository.getRandomPuzzle();
      if (puzzle != null) {
        debugPrint('PuzzlesNotifier: Loading puzzle #${puzzle.id}');
        await loadPuzzle(puzzle, silent: silent);
      } else {
        debugPrint('PuzzlesNotifier: Puzzle repository returned null');
        state = state.copyWith(
          commentaryError: 'Could not fetch a puzzle from the archives.',
        );
      }
    } catch (e) {
      debugPrint('PuzzlesNotifier: Failed to get next puzzle: $e');
      state = state.copyWith(
        commentaryError: 'An error occurred while fetching a puzzle.',
      );
    }
  }

  Future<void> nextPrescriptionPuzzle({bool silent = false}) async {
    if (!state.isPuzzleMode) return;

    debugPrint('PuzzlesNotifier: Requesting next prescription puzzle...');
    try {
      // 1. Get scotoma from battleground provider
      final bgState = ref.read(battlegroundProvider);
      final scotoma = bgState.cachedScotoma;
      
      // 2. Select dominant axis
      ScotomaAxis chosenAxis = ScotomaAxis.balanced;
      if (scotoma != null) {
        final Map<ScotomaAxis, double> axisValues = {
          ScotomaAxis.dgb: scotoma.diagonalRetreats,
          ScotomaAxis.hrz: scotoma.horizontalSwings,
          ScotomaAxis.knf: scotoma.knightForks,
          ScotomaAxis.tmp: scotoma.timePanic,
          ScotomaAxis.grd: scotoma.materialGreed,
          ScotomaAxis.tnl: scotoma.tunnelVision,
          ScotomaAxis.pin: scotoma.pinnedPieces,
          ScotomaAxis.ksb: scotoma.kingSafety,
        };

        var maxEntry = axisValues.entries.reduce((a, b) => a.value > b.value ? a : b);
        if (maxEntry.value > 0.3) {
          chosenAxis = maxEntry.key;
        }
      }

      // 3. Get user Elo
      final playerElo = bgState.consolidatedRating;
      
      debugPrint('PuzzlesNotifier: Dominant Axis determined as $chosenAxis for Elo $playerElo');

      final puzzle = await _prescriptionRepository.getPrescriptionPuzzle(
        axis: chosenAxis,
        playerElo: playerElo,
      );

      if (puzzle != null) {
        state = state.copyWith(
          activeAxis: chosenAxis,
          isPressureCookerActive: chosenAxis == ScotomaAxis.tmp,
        );
        await loadPuzzle(puzzle, silent: silent, customAxis: chosenAxis);
      } else {
        state = state.copyWith(
          commentaryError: 'Could not fetch a prescription puzzle.',
        );
      }
    } catch (e) {
      debugPrint('PuzzlesNotifier: Failed to get next prescription puzzle: $e');
      state = state.copyWith(
        commentaryError: 'An error occurred while loading your prescription.',
      );
    }
  }

  Future<void> loadPuzzle(rust_puzzles.Puzzle puzzle, {bool silent = false, ScotomaAxis? customAxis}) async {
    _clearHint();

    final restoredGame = ChessGame(fen: puzzle.fen, isChess960: false);
    final baseTurn = restoredGame.turn;
    final isPlayerWhite = baseTurn == chess_lib.Color.BLACK;

    final List<String> remainingMoves = List<String>.from(puzzle.moves);
    String? initialMove;
    if (remainingMoves.isNotEmpty) {
      initialMove = remainingMoves.removeAt(0);
    }

    state = PuzzlesState(
      game: restoredGame,
      isPlayerWhite: isPlayerWhite,
      isBoardFlipped: !isPlayerWhite,
      isPuzzleMode: true,
      currentPuzzle: puzzle,
      puzzleMovesRemaining: remainingMoves,
      recentMoves: const [],
      lastMove: null,
      activeAxis: customAxis ?? state.activeAxis,
      isPressureCookerActive: customAxis == ScotomaAxis.tmp || (customAxis == null && state.isPressureCookerActive),
    );

    if (!silent) {
      String introText = "Apprentice, I have loaded puzzle #${puzzle.id}. Rating: ${puzzle.rating}. Find the best sequence for ${isPlayerWhite ? 'White' : 'Black'}.";
      if (customAxis != null) {
        switch (customAxis) {
          case ScotomaAxis.dgb:
            introText = "Apprentice, I see your eyes miss the long diagonal. Study this position — the retreating bishop is the weapon your opponent wields against you.";
            break;
          case ScotomaAxis.hrz:
            introText = "Your blindness lies in the lateral files. Train your eye to sweep horizontally. Find the rook's path.";
            break;
          case ScotomaAxis.knf:
            introText = "The knight on the flank haunts your games. Learn to see the L-shaped threat from the edges before it forks your pieces.";
            break;
          case ScotomaAxis.tmp:
            introText = "You crumble under time pressure. 15 seconds, Apprentice. Find the move. There is no time for fear — only sight.";
            break;
          case ScotomaAxis.grd:
            introText = "Greed is your enemy. Before you capture, look at what the opponent prepares. This puzzle teaches discipline.";
            break;
          case ScotomaAxis.tnl:
            introText = "You focus on one side, blind to the other. The decisive blow always comes from where you are not looking.";
            break;
          case ScotomaAxis.pin:
            introText = "A pinned piece is a ghost defender. You have been fooled by them before. This puzzle cures the hallucination.";
            break;
          case ScotomaAxis.ksb:
            introText = "Your king breathes easy while danger forms. I will show you mating nets until they become instinct.";
            break;
          case ScotomaAxis.balanced:
            introText = "Your vision is balanced, Apprentice. Now we sharpen all edges. A well-rounded tactician fears nothing. Begin.";
            break;
        }
      }
      state = state.copyWith(
        commentaryHistory: [
          CommentaryEntry(
            text: introText,
            timestamp: DateTime.now(),
            isComplete: true,
            isUser: false,
          ),
        ],
      );
    } else {
      state = state.copyWith(commentaryHistory: const []);
    }

    if (initialMove != null && initialMove.length >= 4) {
      final from = initialMove.substring(0, 2);
      final to = initialMove.substring(2, 4);
      final promotion = initialMove.length > 4 ? initialMove[4] : 'q';

      await Future.delayed(const Duration(milliseconds: 400));
      if (_isDisposed || !state.isPuzzleMode) return;

      final piece = state.game.getPiece(from);
      final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
      final pieceCode = piece != null ? '$colorPrefix${piece.type.toUpperCase()}' : 'bP';

      state = state.copyWith(
        moveAnimation: MoveAnimationData(
          from: from,
          to: to,
          pieceCode: pieceCode,
        ),
      );

      final moveMade = state.game.makeMove({
        'from': from,
        'to': to,
        'promotion': promotion,
      });

      if (moveMade) {
        _onMoveCompleted(initialMove);
      }
    }
  }

  Future<void> resetPuzzleLine() async {
    if (state.currentPuzzle != null) {
      await loadPuzzle(state.currentPuzzle!);
    }
  }

  Future<void> makeMove(String from, String to) async {
    if (state.game.gameOver) return;
    if (state.puzzleMovesRemaining.isEmpty) return;

    final expectedMove = state.puzzleMovesRemaining.first;
    final uciAttempt = '$from$to';

    if (expectedMove.startsWith(uciAttempt)) {
      final remaining = List<String>.from(state.puzzleMovesRemaining);
      remaining.removeAt(0);

      final moveMade = state.game.makeMove({
        'from': from,
        'to': to,
        'promotion': expectedMove.length > 4 ? expectedMove[4] : 'q',
      });

      if (moveMade) {
        _onMoveCompleted(expectedMove);

        final chessSettings = ref.read(chessProvider);
        if (chessSettings.isHapticsEnabled) {
          _hapticsService.softTap();
        }

        if (remaining.isEmpty) {
          state = state.copyWith(
            puzzleMovesRemaining: const [],
            commentaryHistory: [
              ...state.commentaryHistory,
              CommentaryEntry(
                text: "Brilliant execution, Apprentice! Puzzle solved perfectly.",
                timestamp: DateTime.now(),
                isComplete: true,
                isUser: false,
              ),
            ],
          );
          return;
        }

        final oppMove = remaining.removeAt(0);
        state = state.copyWith(puzzleMovesRemaining: remaining);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isDisposed || !state.isPuzzleMode) return;

          final oppFrom = oppMove.substring(0, 2);
          final oppTo = oppMove.substring(2, 4);
          final oppPromo = oppMove.length > 4 ? oppMove[4] : 'q';

          final p = state.game.getPiece(oppFrom);
          final cp = p?.color == chess_lib.Color.WHITE ? 'w' : 'b';
          final pc = p != null ? '$cp${p.type.toUpperCase()}' : 'bP';

          state = state.copyWith(
            moveAnimation: MoveAnimationData(
              from: oppFrom,
              to: oppTo,
              pieceCode: pc,
            ),
          );

          state.game.makeMove({
            'from': oppFrom,
            'to': oppTo,
            'promotion': oppPromo,
          });
          _onMoveCompleted(oppMove);

          if (remaining.isEmpty) {
            state = state.copyWith(
              commentaryHistory: [
                ...state.commentaryHistory,
                CommentaryEntry(
                  text: "Brilliant execution, Apprentice! Puzzle solved perfectly.",
                  timestamp: DateTime.now(),
                  isComplete: true,
                  isUser: false,
                ),
              ],
            );
          }
        });
      }
    } else {
      final chessSettings = ref.read(chessProvider);
      if (chessSettings.isHapticsEnabled) {
        _hapticsService.errorFeedback();
      }

      final piece = state.game.getPiece(from);
      final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
      final pieceCode = piece != null ? '$colorPrefix${piece.type.toUpperCase()}' : 'wP';

      state = state.copyWith(
        moveAnimation: MoveAnimationData(
          from: from,
          to: to,
          pieceCode: pieceCode,
          isWrongMove: true,
        ),
        commentaryHistory: [
          ...state.commentaryHistory,
          CommentaryEntry(
            text: "Ah, not quite the best continuation, Apprentice. Look closer at the tactical weaknesses.",
            timestamp: DateTime.now(),
            isComplete: true,
            isUser: false,
          ),
        ],
      );
    }
  }

  void _onMoveCompleted(String uciMove) {
    state = state.copyWith(
      lastMove: uciMove,
      recentMoves: [...state.recentMoves, uciMove],
    );
  }

  void toggleBoardOrientation() {
    state = state.copyWith(isBoardFlipped: !state.isBoardFlipped);
  }

  Future<void> requestHint() async {
    if (state.game.gameOver || state.isHintLoading) {
      return;
    }

    if (state.puzzleMovesRemaining.isEmpty) return;
    final correctMove = state.puzzleMovesRemaining.first;
    state = state.copyWith(
      isHintLoading: true,
      isHintVisible: false,
      isHintBlinking: false,
      isBulbGlowing: true,
      hintBestMove: null,
      hintFrom: null,
      hintTo: null,
      commentaryError: null,
    );
    await _runHintFlow(correctMove);
  }

  Future<void> _runHintFlow(String bestMove) async {
    final from = bestMove.length >= 2 ? bestMove.substring(0, 2) : null;
    final to = bestMove.length >= 4 ? bestMove.substring(2, 4) : null;

    state = state.copyWith(
      hintBestMove: bestMove,
      hintFrom: from,
      hintTo: to,
      isHintLoading: false,
      isHintVisible: true,
      isHintBlinking: true,
      isBulbGlowing: true,
    );

    // Show blinking hint for 3 seconds
    Timer(const Duration(milliseconds: 3000), () {
      if (!_isDisposed) {
        _clearHint();
      }
    });
  }

  void _clearHint() {
    state = state.copyWith(
      hintBestMove: null,
      hintFrom: null,
      hintTo: null,
      isHintVisible: false,
      isHintLoading: false,
      isHintBlinking: false,
      isBulbGlowing: false,
    );
  }

  void clearMoveAnimation() {
    state = state.copyWith(moveAnimation: null);
  }
}

final puzzlesProvider = StateNotifierProvider<PuzzlesNotifier, PuzzlesState>((ref) {
  final puzzleRepository = ref.watch(puzzleRepositoryProvider);
  final prescriptionRepository = ref.watch(prescriptionPuzzleRepositoryProvider);
  final hapticsService = ref.watch(chessHapticsServiceProvider);
  return PuzzlesNotifier(ref, puzzleRepository, prescriptionRepository, hapticsService);
});
