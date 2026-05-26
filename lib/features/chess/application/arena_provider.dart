import 'dart:math' as math;
import 'dart:async';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chess_game.dart';
import '../domain/chess_960_generator.dart';
import '../domain/models/ai_avatar.dart';
import '../domain/models/candidate_move.dart';
import '../services/chess_sound_service.dart';
import '../services/chess_haptics_service.dart';
import '../data/stockfish_service.dart';
import '../data/crafty_service.dart';
import '../data/chess_engine_service.dart';
import '../data/uci_parser.dart';
import '../data/saved_game.dart';
import 'chess_provider.dart';

const _initialClock = Duration(minutes: 10);
const _clockWhite = 'white';
const _clockBlack = 'black';

class _ArenaSnapshot {
  final String fen;
  final String? lastMove;
  final List<String> recentMoves;
  final double previousEvaluation;
  final double currentEvaluation;
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;
  final bool clockStarted;
  final String? activeClockSide;
  final List<String> threatenedSquares;
  final MoveAnimationData? moveAnimation;
  final bool isPlayerWhite;
  final bool isBoardFlipped;

  const _ArenaSnapshot({
    required this.fen,
    this.lastMove,
    required this.recentMoves,
    required this.previousEvaluation,
    required this.currentEvaluation,
    required this.whiteTimeLeft,
    required this.blackTimeLeft,
    required this.clockStarted,
    this.activeClockSide,
    required this.threatenedSquares,
    this.moveAnimation,
    required this.isPlayerWhite,
    required this.isBoardFlipped,
  });
}

class ArenaState {
  final ChessGame game;
  final String? lastMove;
  final List<String> recentMoves;
  final Map<String, dynamic> analysis;
  final double previousEvaluation;
  final double currentEvaluation;
  final bool isEngineThinking;
  final bool isPlayerWhite;
  final bool isBoardFlipped;
  final bool isEngineVsEngine;
  final String engineLevel;
  final String bottomAvatarId;
  final bool canUndo;
  final bool canRedo;
  final String? hintBestMove;
  final String? hintFrom;
  final String? hintTo;
  final bool isHintVisible;
  final bool isHintLoading;
  final bool isHintBlinking;
  final bool isBulbGlowing;
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;
  final bool clockStarted;
  final String? activeClockSide;
  final List<String> threatenedSquares;
  final MoveAnimationData? moveAnimation;
  final bool isPaused;
  final int? viewingMoveIndex;
  final bool isAiOperational;
  final bool isGameOverDismissed;
  final bool isPromoting;
  final String? promotionSource;
  final String? promotionDestination;
  final Duration baseTimeDuration;
  final Duration incrementDuration;
  final String gameMode;
  final bool isTimeOut;
  final bool servicesStarted;
  final bool servicesStarting;
  final bool engineReady;
  final String? startupError;

  ArenaState({
    required this.game,
    this.lastMove,
    this.recentMoves = const [],
    this.analysis = const {},
    this.previousEvaluation = 0.0,
    this.currentEvaluation = 0.0,
    this.isEngineThinking = false,
    this.isPlayerWhite = true,
    this.isBoardFlipped = false,
    this.isEngineVsEngine = false,
    this.engineLevel = 'avatar_6',
    this.bottomAvatarId = 'avatar_6',
    this.canUndo = false,
    this.canRedo = false,
    this.hintBestMove,
    this.hintFrom,
    this.hintTo,
    this.isHintVisible = false,
    this.isHintLoading = false,
    this.isHintBlinking = false,
    this.isBulbGlowing = false,
    this.whiteTimeLeft = _initialClock,
    this.blackTimeLeft = _initialClock,
    this.clockStarted = false,
    this.activeClockSide,
    this.threatenedSquares = const [],
    this.moveAnimation,
    this.isPaused = false,
    this.viewingMoveIndex,
    this.isAiOperational = true,
    this.isGameOverDismissed = false,
    this.isPromoting = false,
    this.promotionSource,
    this.promotionDestination,
    this.baseTimeDuration = _initialClock,
    this.incrementDuration = Duration.zero,
    this.gameMode = 'classic',
    this.isTimeOut = false,
    this.servicesStarted = false,
    this.servicesStarting = false,
    this.engineReady = false,
    this.startupError,
  });

  bool get isChess960 => gameMode == 'chess960';

  String get currentBoardFen {
    if (viewingMoveIndex == null || viewingMoveIndex! >= recentMoves.length) {
      return game.fen;
    }
    final tempGame = chess_lib.Chess();
    for (int i = 0; i <= viewingMoveIndex!; i++) {
      tempGame.move(recentMoves[i]);
    }
    return tempGame.fen;
  }

  ArenaState copyWith({
    ChessGame? game,
    Object? lastMove = const Object(),
    List<String>? recentMoves,
    Map<String, dynamic>? analysis,
    double? previousEvaluation,
    double? currentEvaluation,
    bool? isEngineThinking,
    bool? isPlayerWhite,
    bool? isBoardFlipped,
    bool? isEngineVsEngine,
    String? engineLevel,
    String? bottomAvatarId,
    bool? canUndo,
    bool? canRedo,
    Object? hintBestMove = const Object(),
    Object? hintFrom = const Object(),
    Object? hintTo = const Object(),
    bool? isHintVisible,
    bool? isHintLoading,
    bool? isHintBlinking,
    bool? isBulbGlowing,
    Duration? whiteTimeLeft,
    Duration? blackTimeLeft,
    bool? clockStarted,
    Object? activeClockSide = const Object(),
    List<String>? threatenedSquares,
    Object? moveAnimation = const Object(),
    bool? isPaused,
    Object? viewingMoveIndex = const Object(),
    bool? isAiOperational,
    bool? isGameOverDismissed,
    bool? isPromoting,
    Object? promotionSource = const Object(),
    Object? promotionDestination = const Object(),
    Duration? baseTimeDuration,
    Duration? incrementDuration,
    String? gameMode,
    bool? isTimeOut,
    bool? servicesStarted,
    bool? servicesStarting,
    bool? engineReady,
    Object? startupError = const Object(),
  }) {
    return ArenaState(
      game: game ?? this.game,
      lastMove: lastMove == const Object() ? this.lastMove : lastMove as String?,
      recentMoves: recentMoves ?? this.recentMoves,
      analysis: analysis ?? this.analysis,
      previousEvaluation: previousEvaluation ?? this.previousEvaluation,
      currentEvaluation: currentEvaluation ?? this.currentEvaluation,
      isEngineThinking: isEngineThinking ?? this.isEngineThinking,
      isPlayerWhite: isPlayerWhite ?? this.isPlayerWhite,
      isBoardFlipped: isBoardFlipped ?? this.isBoardFlipped,
      isEngineVsEngine: isEngineVsEngine ?? this.isEngineVsEngine,
      engineLevel: engineLevel ?? this.engineLevel,
      bottomAvatarId: bottomAvatarId ?? this.bottomAvatarId,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      hintBestMove: hintBestMove == const Object() ? this.hintBestMove : hintBestMove as String?,
      hintFrom: hintFrom == const Object() ? this.hintFrom : hintFrom as String?,
      hintTo: hintTo == const Object() ? this.hintTo : hintTo as String?,
      isHintVisible: isHintVisible ?? this.isHintVisible,
      isHintLoading: isHintLoading ?? this.isHintLoading,
      isHintBlinking: isHintBlinking ?? this.isHintBlinking,
      isBulbGlowing: isBulbGlowing ?? this.isBulbGlowing,
      whiteTimeLeft: whiteTimeLeft ?? this.whiteTimeLeft,
      blackTimeLeft: blackTimeLeft ?? this.blackTimeLeft,
      clockStarted: clockStarted ?? this.clockStarted,
      activeClockSide: activeClockSide == const Object() ? this.activeClockSide : activeClockSide as String?,
      threatenedSquares: threatenedSquares ?? this.threatenedSquares,
      moveAnimation: moveAnimation == const Object() ? this.moveAnimation : moveAnimation as MoveAnimationData?,
      isPaused: isPaused ?? this.isPaused,
      viewingMoveIndex: viewingMoveIndex == const Object() ? this.viewingMoveIndex : viewingMoveIndex as int?,
      isAiOperational: isAiOperational ?? this.isAiOperational,
      isGameOverDismissed: isGameOverDismissed ?? this.isGameOverDismissed,
      isPromoting: isPromoting ?? this.isPromoting,
      promotionSource: promotionSource == const Object() ? this.promotionSource : promotionSource as String?,
      promotionDestination: promotionDestination == const Object() ? this.promotionDestination : promotionDestination as String?,
      baseTimeDuration: baseTimeDuration ?? this.baseTimeDuration,
      incrementDuration: incrementDuration ?? this.incrementDuration,
      gameMode: gameMode ?? this.gameMode,
      isTimeOut: isTimeOut ?? this.isTimeOut,
      servicesStarted: servicesStarted ?? this.servicesStarted,
      servicesStarting: servicesStarting ?? this.servicesStarting,
      engineReady: engineReady ?? this.engineReady,
      startupError: startupError == const Object() ? this.startupError : startupError as String?,
    );
  }
}

class ArenaNotifier extends StateNotifier<ArenaState> {
  final Ref ref;
  final StockfishService _stockfishEngine;
  final CraftyService _craftyEngine;
  final ChessSoundService _soundService;
  final ChessHapticsService _hapticsService;

  final List<_ArenaSnapshot> _undoStack = [];
  final List<_ArenaSnapshot> _redoStack = [];

  Timer? _clockTimer;
  Timer? _engineMoveTimer;
  StreamSubscription<String>? _stockfishSubscription;
  StreamSubscription<String>? _craftySubscription;

  Future<void>? _startupFuture;
  bool _isDisposed = false;
  DateTime _lastInfoUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _pendingHintFen;
  String? _searchFen;
  final List<CandidateMove> _currentCandidates = [];

  ArenaNotifier(
    this.ref,
    this._stockfishEngine,
    this._craftyEngine,
    this._soundService,
    this._hapticsService,
  ) : super(ArenaState(game: ChessGame())) {
    _loadInitialState();
  }

  void _loadInitialState() {
    final settings = ref.read(chessProvider);
    state = state.copyWith(
      isBoardFlipped: settings.isBoardFlipped,
      isPlayerWhite: settings.isPlayerWhite,
      engineLevel: settings.engineLevel,
      bottomAvatarId: settings.bottomAvatarId,
      whiteTimeLeft: settings.baseTimeDuration,
      blackTimeLeft: settings.baseTimeDuration,
      baseTimeDuration: settings.baseTimeDuration,
      incrementDuration: settings.incrementDuration,
      gameMode: settings.gameMode,
    );
  }

  ChessEngineService get _engine {
    final avatarId = _activeAvatarId;
    final craftyIds = {'avatar_0', 'avatar_1', 'avatar_4', 'avatar_7', 'avatar_9'};
    if (craftyIds.contains(avatarId)) {
      return _craftyEngine.isError ? _stockfishEngine : _craftyEngine;
    }
    return _stockfishEngine;
  }

  String get _activeAvatarId {
    bool isBottomTurn = false;
    final fenParts = state.game.fen.split(' ');
    if (fenParts.length > 1) {
      final turnWhite = fenParts[1] == 'w';
      isBottomTurn = (state.isPlayerWhite == turnWhite);
    }
    return (state.isEngineVsEngine && isBottomTurn)
        ? state.bottomAvatarId
        : state.engineLevel;
  }

  Future<void> ensureGameServicesStarted({
    bool analyzeCurrentPosition = false,
    int? depth,
  }) async {
    if (_isDisposed) return;
    if (state.servicesStarted) {
      if (analyzeCurrentPosition) {
        _startAnalysis(depth: depth);
      }
      return;
    }

    if (_startupFuture != null) {
      await _startupFuture;
      if (analyzeCurrentPosition && state.engineReady) {
        _startAnalysis(depth: depth);
      }
      return;
    }

    state = state.copyWith(
      servicesStarting: true,
      startupError: null,
    );

    _startupFuture = _startServices(
      depth: depth,
      analyzeCurrentPosition: analyzeCurrentPosition,
    );
    await _startupFuture;
    _startupFuture = null;
  }

  Future<void> _startServices({
    required int? depth,
    required bool analyzeCurrentPosition,
  }) async {
    try {
      _stockfishSubscription ??= _stockfishEngine.outputStream.listen(_handleEngineOutput);
      _craftySubscription ??= _craftyEngine.outputStream.listen(_handleEngineOutput);

      await _stockfishEngine.init();
      await _craftyEngine.init();

      final avatar = AiAvatar.getAvatar(state.engineLevel);
      await _stockfishEngine.setSkillLevel(avatar.skillLevel, multiPV: avatar.name == 'Kingslayer' ? 1 : 4);
      await _craftyEngine.setSkillLevel(avatar.skillLevel, multiPV: avatar.name == 'Kingslayer' ? 1 : 4);

      state = state.copyWith(
        servicesStarted: true,
        servicesStarting: false,
        engineReady: _engine.isReady,
        startupError: null,
      );

      if (analyzeCurrentPosition) {
        _startAnalysis(depth: depth);
      }
    } catch (e) {
      debugPrint('ArenaNotifier: Startup failed: $e');
      state = state.copyWith(
        servicesStarting: false,
        servicesStarted: false,
        engineReady: false,
        startupError: 'Unable to start the engine.',
      );
    }
  }

  void _startAnalysis({int? depth}) async {
    if (!state.servicesStarted || !state.engineReady || state.game.gameOver || state.isPaused) return;

    _currentCandidates.clear();
    final is960 = state.gameMode == 'chess960';
    await _engine.setChess960Mode(is960);

    final avatar = AiAvatar.getAvatar(_activeAvatarId);
    await _engine.setSkillLevel(avatar.skillLevel, multiPV: avatar.name == 'Kingslayer' ? 1 : 4);

    _searchFen = state.game.fen;
    final targetDepth = depth ?? avatar.depth;
    _engine.analyzePosition(state.game.fen, depth: targetDepth);
  }

  void _handleEngineOutput(String line) {
    if (_isDisposed) return;

    // Check if output is relevant to the search FEN of the current game
    if (_searchFen != state.game.fen) return;

    final parsed = UCIParser.parseLine(line);
    if (parsed.isEmpty) return;

    double? newEval;
    if (parsed.containsKey('score')) {
      final score = parsed['score'] as int;
      newEval = parsed['scoreType'] == 'mate'
          ? (score > 0 ? 99.0 : -99.0)
          : score / 100.0;
    }

    if (parsed['type'] == 'info') {
      final now = DateTime.now();
      if (now.difference(_lastInfoUpdateTime).inMilliseconds < 250) {
        return;
      }
      _lastInfoUpdateTime = now;
    }

    state = state.copyWith(
      analysis: {...state.analysis, ...parsed},
      currentEvaluation: newEval ?? state.currentEvaluation,
      engineReady: true,
    );

    if (parsed.containsKey('multipv') && parsed.containsKey('pv')) {
      final mpv = parsed['multipv'] as int;
      final pvList = parsed['pv'] as List<String>;
      if (pvList.isNotEmpty) {
        final uciMove = pvList.first;
        final candidate = CandidateMove(
          multipvIndex: mpv,
          uciMove: uciMove,
          evaluation: newEval ?? state.currentEvaluation,
          fullPv: pvList,
        );
        final idx = _currentCandidates.indexWhere((c) => c.multipvIndex == mpv);
        if (idx != -1) {
          _currentCandidates[idx] = candidate;
        } else {
          _currentCandidates.add(candidate);
        }
      }
    }

    if (parsed.containsKey('bestMove')) {
      final rawBestMove = parsed['bestMove'] as String?;
      final aiTurn = _isAiTurn();

      String? bestMoveToPlay = rawBestMove;

      if (rawBestMove != null && _currentCandidates.isNotEmpty) {
        final currentAvatar = AiAvatar.getAvatar(_activeAvatarId);
        if (currentAvatar.name != 'Kingslayer') {
          bestMoveToPlay = _applyPersonaHeuristics(
            List.from(_currentCandidates),
            currentAvatar,
            state.game,
            rawBestMove,
          );
        }
      }

      // Ensure the move is actually intended for the current turn's side
      bool isMoveValidForCurrentTurn = false;
      if (bestMoveToPlay != null && bestMoveToPlay.length >= 4) {
        final fromSquare = bestMoveToPlay.substring(0, 2);
        final piece = state.game.getPiece(fromSquare);
        if (piece != null && piece.color == state.game.turn) {
          isMoveValidForCurrentTurn = true;
        }
      }

      if (bestMoveToPlay != null &&
          _pendingHintFen != null &&
          _pendingHintFen == state.game.fen) {
        _pendingHintFen = null;
        unawaited(_runHintFlow(bestMoveToPlay));
      }

      if (bestMoveToPlay != null &&
          aiTurn &&
          isMoveValidForCurrentTurn &&
          !state.game.gameOver &&
          !state.isPaused) {
        _engineMoveTimer?.cancel();
        final finalMove = bestMoveToPlay;
        
        if (ref.read(chessProvider).isAnimationsEnabled) {
          _engineMoveTimer = Timer(const Duration(milliseconds: 1500), () {
            if (!_isDisposed && !state.isPaused && _searchFen == state.game.fen) {
              _makeEngineMove(finalMove);
            }
          });
        } else {
          _makeEngineMove(finalMove);
        }
      }
    }
  }

  void _makeEngineMove(String move) {
    if (move.length < 4 || state.game.gameOver || state.isPaused) return;
    final from = move.substring(0, 2);
    final to = move.substring(2, 4);

    final piece = state.game.getPiece(from);
    final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceCode = piece != null
        ? '$colorPrefix${piece.type.toUpperCase()}'
        : 'wP';

    final targetPiece = state.game.getPiece(to);
    final isCapture = targetPiece != null;

    String? rookFrom;
    String? rookTo;
    String? rookPieceCode;
    if (piece?.type == chess_lib.PieceType.KING && (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
      final isWhite = piece?.color == chess_lib.Color.WHITE;
      final rank = isWhite ? '1' : '8';
      final isKingside = to[0] == 'g';

      rookFrom = isKingside ? 'h$rank' : 'a$rank';
      rookTo = isKingside ? 'f$rank' : 'd$rank';
      rookPieceCode = isWhite ? 'wR' : 'bR';
    }

    state = state.copyWith(
      moveAnimation: MoveAnimationData(
        from: from,
        to: to,
        pieceCode: pieceCode,
        isCapture: isCapture,
        rookFrom: rookFrom,
        rookTo: rookTo,
        rookPieceCode: rookPieceCode,
      ),
    );

    final promotion = move.length > 4 ? move[4] : 'q';
    final moveMade = state.game.makeMove({
      'from': from,
      'to': to,
      'promotion': promotion,
    });

    if (moveMade) {
      _onMoveCompleted('$from$to$promotion');
    } else {
      state = state.copyWith(moveAnimation: null);
    }
  }

  String _applyPersonaHeuristics(
    List<CandidateMove> candidates,
    AiAvatar avatar,
    ChessGame game,
    String engineBestMove,
  ) {
    if (candidates.isEmpty) return engineBestMove;
    String bestCandidateMove = candidates.first.uciMove;
    double highestAdjustedScore = -999.0;

    for (final candidate in candidates) {
      if (candidate.uciMove.length < 4) continue;
      final fromSq = candidate.uciMove.substring(0, 2);

      final piece = game.getPiece(fromSq);
      double adjustedScore = candidate.evaluation;

      if (avatar.name == 'Sparky') {
        final randomVal = (math.Random().nextDouble() * 3.0) - 1.5;
        adjustedScore += randomVal;
      } else if (avatar.name == 'Pawnzy') {
        if (piece?.type == chess_lib.PieceType.PAWN) {
          adjustedScore += 1.5;
        }
      } else if (avatar.name == 'Rook-ie') {
        if (piece?.type == chess_lib.PieceType.ROOK) {
          adjustedScore += 1.5;
        }
      } else if (avatar.name == 'Bishop-hop') {
        if (piece?.type == chess_lib.PieceType.BISHOP) {
          adjustedScore += 1.5;
        }
      }

      if (adjustedScore > highestAdjustedScore) {
        highestAdjustedScore = adjustedScore;
        bestCandidateMove = candidate.uciMove;
      }
    }
    return bestCandidateMove;
  }

  bool _isPlayerTurn() {
    if (state.game.gameOver || state.isPaused) return false;
    if (state.isEngineVsEngine) return false;
    final turn = state.game.turn;
    return state.isPlayerWhite ? (turn == chess_lib.Color.WHITE) : (turn == chess_lib.Color.BLACK);
  }

  bool _isAiTurn() {
    if (state.game.gameOver || state.isPaused) return false;
    if (state.isEngineVsEngine) return true;
    final turn = state.game.turn;
    return state.isPlayerWhite ? (turn == chess_lib.Color.BLACK) : (turn == chess_lib.Color.WHITE);
  }

  void _saveSnapshotForUndo() {
    _undoStack.add(_captureCurrentSnapshot());
    _redoStack.clear();
    _syncUndoRedoFlags();
  }

  void _syncUndoRedoFlags() {
    state = state.copyWith(
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
    );
  }

  _ArenaSnapshot _captureCurrentSnapshot() {
    return _ArenaSnapshot(
      fen: state.game.fen,
      lastMove: state.lastMove,
      recentMoves: List<String>.from(state.recentMoves),
      previousEvaluation: state.previousEvaluation,
      currentEvaluation: state.currentEvaluation,
      whiteTimeLeft: state.whiteTimeLeft,
      blackTimeLeft: state.blackTimeLeft,
      clockStarted: state.clockStarted,
      activeClockSide: state.activeClockSide,
      threatenedSquares: List<String>.from(state.threatenedSquares),
      moveAnimation: state.moveAnimation,
      isPlayerWhite: state.isPlayerWhite,
      isBoardFlipped: state.isBoardFlipped,
    );
  }

  void _restoreSnapshot(_ArenaSnapshot snapshot) {
    _pendingHintFen = null;
    final is960 = state.gameMode == 'chess960';

    state = state.copyWith(
      game: ChessGame(fen: snapshot.fen, isChess960: is960),
      lastMove: snapshot.lastMove,
      recentMoves: snapshot.recentMoves,
      previousEvaluation: snapshot.previousEvaluation,
      currentEvaluation: snapshot.currentEvaluation,
      analysis: const {},
      hintBestMove: null,
      hintFrom: null,
      hintTo: null,
      isHintVisible: false,
      isHintLoading: false,
      isHintBlinking: false,
      isBulbGlowing: false,
      whiteTimeLeft: snapshot.whiteTimeLeft,
      blackTimeLeft: snapshot.blackTimeLeft,
      clockStarted: snapshot.clockStarted,
      activeClockSide: snapshot.activeClockSide,
      threatenedSquares: snapshot.threatenedSquares,
      moveAnimation: snapshot.moveAnimation,
      isPlayerWhite: snapshot.isPlayerWhite,
      isBoardFlipped: snapshot.isBoardFlipped,
    );

    if (state.clockStarted) {
      _startClockTicker();
    } else {
      _stopClockTimer();
    }

    if (_isAiTurn()) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
  }

  Future<void> makeMove(String from, String to) async {
    if (state.game.gameOver) return;

    if (state.viewingMoveIndex != null) {
      _truncateToViewingIndex();
    }

    if (_redoStack.isNotEmpty) {
      _redoStack.clear();
      _syncUndoRedoFlags();
    }

    if (state.isPaused) {
      state = state.copyWith(isPaused: false);
      if (state.clockStarted) {
        _startClockTicker();
      }
    }

    if (!_isPlayerTurn() && !state.isEngineVsEngine) return;

    final piece = state.game.getPiece(from);
    final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceCode = piece != null ? '$colorPrefix${piece.type.toUpperCase()}' : 'wP';

    _saveSnapshotForUndo();
    _clearHint();

    final isPawn = piece?.type.toUpperCase() == 'P';
    final targetRank = to.substring(1);
    final isPromotionRank = (piece?.color == chess_lib.Color.WHITE && targetRank == '8') ||
                            (piece?.color == chess_lib.Color.BLACK && targetRank == '1');

    if (isPawn && isPromotionRank) {
      state = state.copyWith(
        isPromoting: true,
        promotionSource: from,
        promotionDestination: to,
        moveAnimation: null,
      );
      return;
    }

    final targetPiece = state.game.getPiece(to);
    final isCapture = targetPiece != null;

    String? rookFrom;
    String? rookTo;
    String? rookPieceCode;
    if (piece?.type == chess_lib.PieceType.KING && (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
      final isWhite = piece?.color == chess_lib.Color.WHITE;
      final rank = isWhite ? '1' : '8';
      final isKingside = to[0] == 'g';

      rookFrom = isKingside ? 'h$rank' : 'a$rank';
      rookTo = isKingside ? 'f$rank' : 'd$rank';
      rookPieceCode = isWhite ? 'wR' : 'bR';
    }

    state = state.copyWith(
      moveAnimation: MoveAnimationData(
        from: from,
        to: to,
        pieceCode: pieceCode,
        isCapture: isCapture,
        rookFrom: rookFrom,
        rookTo: rookTo,
        rookPieceCode: rookPieceCode,
      ),
    );

    final moveMade = state.game.makeMove({
      'from': from,
      'to': to,
      'promotion': 'q',
    });

    if (!moveMade) {
      state = state.copyWith(moveAnimation: null);
      if (ref.read(chessProvider).isHapticsEnabled) {
        _hapticsService.errorFeedback();
      }
      return;
    }

    final wasClockStarted = state.clockStarted;
    _onMoveCompleted('$from$to');

    if (!wasClockStarted) {
      state = state.copyWith(clockStarted: true);
    }

    state = state.copyWith(activeClockSide: _clockSideForTurn());
    _startClockTicker();

    await ensureGameServicesStarted(analyzeCurrentPosition: true);
    state = state.copyWith(isEngineThinking: state.engineReady);
  }

  void _truncateToViewingIndex() {
    if (state.viewingMoveIndex == null) return;
    final index = state.viewingMoveIndex!;
    final movesToKeep = state.recentMoves.sublist(0, index + 1);

    final is960 = state.gameMode == 'chess960';
    final tempGame = is960
        ? ChessGame(fen: Chess960Generator.generateRandomPosition().fen, isChess960: true)
        : ChessGame();

    for (final m in movesToKeep) {
      tempGame.makeMove({'from': m.substring(0, 2), 'to': m.substring(2, 4), 'promotion': m.length > 4 ? m[4] : 'q'});
    }

    state = state.copyWith(
      game: tempGame,
      recentMoves: movesToKeep,
      lastMove: movesToKeep.isEmpty ? null : movesToKeep.last,
      viewingMoveIndex: null,
    );
  }

  void _onMoveCompleted(String moveLabel) {
    final updatedMoves = state.game.moveHistoryLabels();
    final move = state.game.history.isEmpty ? null : state.game.history.last;
    final isWhiteTurn = state.game.turn == chess_lib.Color.WHITE;
    final playerJustMoved = isWhiteTurn ? 'Black' : 'White';

    if (state.clockStarted) {
      state = state.copyWith(
        whiteTimeLeft: isWhiteTurn ? state.whiteTimeLeft : state.whiteTimeLeft + state.incrementDuration,
        blackTimeLeft: isWhiteTurn ? state.blackTimeLeft + state.incrementDuration : state.blackTimeLeft,
      );
    }

    if (ref.read(chessProvider).isHapticsEnabled) {
      if (state.game.inCheckmate) {
        _hapticsService.mateBurst();
      } else if (state.game.inCheck) {
        _hapticsService.checkPulse();
      } else if (move?.move.captured != null) {
        _hapticsService.heavyRook();
      } else {
        _hapticsService.softTap();
      }
    }

    final threatened = <String>[];
    final opponentColor = state.game.turn;
    final sideWhoJustMoved = opponentColor == chess_lib.Color.WHITE ? chess_lib.Color.BLACK : chess_lib.Color.WHITE;

    for (final file in ChessGame.files) {
      for (final rank in ChessGame.ranks) {
        final square = '$file$rank';
        final piece = state.game.getPiece(square);
        if (piece != null && piece.color == opponentColor) {
          if (state.game.isAttacked(square, sideWhoJustMoved)) {
            threatened.add(square);
          }
        }
      }
    }

    state = state.copyWith(
      game: state.game,
      lastMove: moveLabel,
      recentMoves: updatedMoves,
      isEngineThinking: _isAiTurn() && state.servicesStarted && state.engineReady,
      activeClockSide: state.clockStarted ? _clockSideForTurn() : state.activeClockSide,
      threatenedSquares: threatened,
    );

    if (state.game.gameOver) {
      _stopClockTimer();
      final isDraw = state.game.inDraw || state.game.inStalemate;
      if (isDraw) {
        _soundService.playSfx(SoundEffect.draw);
      } else {
        final humanWon = (playerJustMoved == 'White') == state.isPlayerWhite;
        _soundService.playSfx(humanWon ? SoundEffect.victory : SoundEffect.defeat);
      }
    } else if (state.game.inCheck) {
      _soundService.playSfx(SoundEffect.check);
    } else {
      _soundService.playSfx(move?.move.captured != null ? SoundEffect.capture : SoundEffect.move);
    }
  }

  void completePromotion(String promotionPiece) {
    if (!state.isPromoting || state.promotionSource == null || state.promotionDestination == null) return;

    final from = state.promotionSource!;
    final to = state.promotionDestination!;

    final piece = state.game.getPiece(from);
    final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceCode = piece != null ? '$colorPrefix${piece.type.toUpperCase()}' : 'wP';

    state = state.copyWith(
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
    );

    _saveSnapshotForUndo();

    state = state.copyWith(
      moveAnimation: MoveAnimationData(
        from: from,
        to: to,
        pieceCode: pieceCode,
        isCapture: state.game.getPiece(to) != null,
      ),
    );

    final moveMade = state.game.makeMove({
      'from': from,
      'to': to,
      'promotion': promotionPiece.toLowerCase(),
    });

    if (moveMade) {
      _onMoveCompleted('$from$to$promotionPiece');
      _startClockTicker();
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      state = state.copyWith(isEngineThinking: state.engineReady);
    } else {
      state = state.copyWith(moveAnimation: null);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_captureCurrentSnapshot());
    final snapshot = _undoStack.removeLast();
    _restoreSnapshot(snapshot);
    _syncUndoRedoFlags();
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_captureCurrentSnapshot());
    final snapshot = _redoStack.removeLast();
    _restoreSnapshot(snapshot);
    _syncUndoRedoFlags();
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void togglePause() {
    final newVal = !state.isPaused;
    state = state.copyWith(isPaused: newVal);

    if (newVal) {
      _stopClockTimer();
      _engineMoveTimer?.cancel();
      _engineMoveTimer = null;
      _engine.sendCommand('stop');
      state = state.copyWith(isEngineThinking: false);
    } else {
      if (state.clockStarted) {
        _startClockTicker();
      }
      if (_isAiTurn()) {
        unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      }
    }
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void toggleEngineVsEngine() {
    final newVal = !state.isEngineVsEngine;
    state = state.copyWith(isEngineVsEngine: newVal);

    if (newVal && _isAiTurn() && !state.game.gameOver && !state.isPaused) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
    _soundService.playSfx(SoundEffect.uiClick);
  }

  Future<void> requestHint() async {
    if (state.game.gameOver || state.isHintLoading || state.isEngineThinking) return;

    _pendingHintFen = state.game.fen;
    state = state.copyWith(
      isHintLoading: true,
      isHintVisible: false,
      isHintBlinking: false,
      isBulbGlowing: true,
      hintBestMove: null,
      hintFrom: null,
      hintTo: null,
    );
    await ensureGameServicesStarted();
    if (state.engineReady) {
      _engine.analyzePosition(state.game.fen, depth: 14);
    }
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

  void reset({bool forcedPlayerWhite = true}) {
    _clockTimer?.cancel();
    _engineMoveTimer?.cancel();
    _undoStack.clear();
    _redoStack.clear();

    final is960 = state.gameMode == 'chess960';
    final initialGame = is960
        ? ChessGame(fen: Chess960Generator.generateRandomPosition().fen, isChess960: true)
        : ChessGame(isChess960: false);

    state = state.copyWith(
      game: initialGame,
      lastMove: null,
      recentMoves: const [],
      analysis: const {},
      previousEvaluation: 0.0,
      currentEvaluation: 0.0,
      isEngineThinking: false,
      isPlayerWhite: forcedPlayerWhite,
      isBoardFlipped: !forcedPlayerWhite,
      canUndo: false,
      canRedo: false,
      whiteTimeLeft: state.baseTimeDuration,
      blackTimeLeft: state.baseTimeDuration,
      clockStarted: false,
      activeClockSide: null,
      threatenedSquares: const [],
      moveAnimation: null,
      isPaused: false,
      viewingMoveIndex: null,
      isGameOverDismissed: false,
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
      isTimeOut: false,
    );

    _soundService.playSfx(SoundEffect.uiClick);
  }

  void toggleBoardOrientation() {
    state = state.copyWith(
      isBoardFlipped: !state.isBoardFlipped,
    );
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void setGameMode(String mode) {
    if (state.gameMode == mode) return;
    state = state.copyWith(gameMode: mode);
    reset();
  }

  void setBoardTheme(String themeId) {
    // Themes are global preferences in chessProvider
    ref.read(chessProvider.notifier).setBoardTheme(themeId);
  }

  void setTimeControl(Duration total, Duration increment) {
    state = state.copyWith(
      baseTimeDuration: total,
      incrementDuration: increment,
      whiteTimeLeft: total,
      blackTimeLeft: total,
    );
    reset();
  }

  void selectUpperAvatar(String avatarId) {
    state = state.copyWith(engineLevel: avatarId);
    reset();
  }

  void selectBottomAvatar(String avatarId) {
    state = state.copyWith(bottomAvatarId: avatarId);
    reset();
  }

  void dismissGameOver() {
    state = state.copyWith(isGameOverDismissed: true);
  }

  void playNotify() {
    _soundService.playNotify();
  }

  void _startClockTicker() {
    _clockTimer?.cancel();
    if (state.game.gameOver || state.isPaused) return;

    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (state.game.gameOver || state.isPaused || !state.clockStarted) {
        _clockTimer?.cancel();
        return;
      }

      final side = state.activeClockSide;
      if (side == _clockWhite) {
        final next = state.whiteTimeLeft - const Duration(milliseconds: 100);
        if (next <= Duration.zero) {
          _clockTimer?.cancel();
          state = state.copyWith(
            whiteTimeLeft: Duration.zero,
            isTimeOut: true,
            clockStarted: false,
            activeClockSide: null,
          );
          _handleClockTimeout(_clockWhite);
          return;
        }
        state = state.copyWith(whiteTimeLeft: next);
        _triggerHeartbeatIfRequired(next);
      } else if (side == _clockBlack) {
        final next = state.blackTimeLeft - const Duration(milliseconds: 100);
        if (next <= Duration.zero) {
          _clockTimer?.cancel();
          state = state.copyWith(
            blackTimeLeft: Duration.zero,
            isTimeOut: true,
            clockStarted: false,
            activeClockSide: null,
          );
          _handleClockTimeout(_clockBlack);
          return;
        }
        state = state.copyWith(blackTimeLeft: next);
        _triggerHeartbeatIfRequired(next);
      }
    });
  }

  void _stopClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void _triggerHeartbeatIfRequired(Duration time) {
    if (ref.read(chessProvider).isHapticsEnabled && time <= const Duration(seconds: 10) && time.inMilliseconds % 1000 == 0) {
      _hapticsService.heartbeat();
    }
  }

  void _handleClockTimeout(String side) {
    state = state.copyWith(
      clockStarted: false,
      activeClockSide: null,
      isEngineThinking: false,
      isTimeOut: true,
    );

    final timedOutSideIsWhite = side == _clockWhite;
    final humanWon = state.isPlayerWhite != timedOutSideIsWhite;
    _soundService.playSfx(humanWon ? SoundEffect.victory : SoundEffect.defeat);
  }

  String _clockSideForTurn() {
    return state.game.turn == chess_lib.Color.WHITE ? _clockWhite : _clockBlack;
  }

  void setViewingMoveIndex(int? index) {
    state = state.copyWith(viewingMoveIndex: index);
  }

  Future<SavedGameEntry> saveCurrentGame({String? resultOverride}) async {
    final moves = List<String>.from(state.recentMoves);
    final isWhite = state.isPlayerWhite;
    final fen = state.game.fen;

    final entry = SavedGameEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      savedAt: DateTime.now(),
      fen: fen,
      recentMoves: moves,
      isPlayerWhite: isWhite,
      isBoardFlipped: state.isBoardFlipped,
      whiteTimeLeftMs: state.whiteTimeLeft.inMilliseconds,
      blackTimeLeftMs: state.blackTimeLeft.inMilliseconds,
      clockStarted: false,
      activeClockSide: null,
      customName: 'Arena Game',
      isRatedMode: false,
      result: resultOverride,
    );

    await ref.read(savedGameRepositoryProvider).save(entry);
    await ref.read(chessProvider.notifier).loadSavedGames();
    return entry;
  }

  void clearMoveAnimation() {
    state = state.copyWith(moveAnimation: null);
  }

  Future<void> loadSavedGame(SavedGameEntry entry) async {
    _engineMoveTimer?.cancel();
    _undoStack.clear();
    _redoStack.clear();
    _stopClockTimer();

    final is960 = entry.gameMode == 'chess960';
    final restoredGame = ChessGame(fen: entry.fen, isChess960: is960);
    state = ArenaState(
      game: restoredGame,
      lastMove: entry.lastMove,
      recentMoves: entry.recentMoves,
      isPlayerWhite: entry.isPlayerWhite,
      isBoardFlipped: entry.isBoardFlipped,
      whiteTimeLeft: Duration(milliseconds: entry.whiteTimeLeftMs),
      blackTimeLeft: Duration(milliseconds: entry.blackTimeLeftMs),
      clockStarted: entry.clockStarted,
      threatenedSquares: const [],
      isPromoting: false,
      isGameOverDismissed: false,
      isTimeOut: false,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clockTimer?.cancel();
    _engineMoveTimer?.cancel();
    _stockfishSubscription?.cancel();
    _craftySubscription?.cancel();
    super.dispose();
  }
}

final arenaProvider = StateNotifierProvider<ArenaNotifier, ArenaState>((ref) {
  final stockfishEngine = ref.watch(stockfishServiceProvider);
  final craftyEngine = ref.watch(craftyServiceProvider);
  final soundService = ref.watch(chessSoundServiceProvider);
  final hapticsService = ref.watch(chessHapticsServiceProvider);
  return ArenaNotifier(
    ref,
    stockfishEngine,
    craftyEngine,
    soundService,
    hapticsService,
  );
});
