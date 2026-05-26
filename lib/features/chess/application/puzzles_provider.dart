import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;

import '../domain/chess_game.dart';
import '../data/puzzle_repository.dart';
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
    );
  }
}

class PuzzlesNotifier extends StateNotifier<PuzzlesState> {
  PuzzlesNotifier(
    this.ref,
    this._puzzleRepository,
    this._hapticsService,
  ) : super(PuzzlesState(game: ChessGame(fen: '8/8/8/8/8/8/8/8 w - - 0 1')));

  final Ref ref;
  final PuzzleRepository _puzzleRepository;
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

  Future<void> loadPuzzle(rust_puzzles.Puzzle puzzle, {bool silent = false}) async {
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
    );

    if (!silent) {
      final introText = "Apprentice, I have loaded puzzle #${puzzle.id}. Rating: ${puzzle.rating}. Find the best sequence for ${isPlayerWhite ? 'White' : 'Black'}.";
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
  final hapticsService = ref.watch(chessHapticsServiceProvider);
  return PuzzlesNotifier(ref, puzzleRepository, hapticsService);
});
