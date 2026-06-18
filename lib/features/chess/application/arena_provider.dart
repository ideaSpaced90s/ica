import 'dart:async';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chess_game.dart';
import '../domain/chess_960_generator.dart';
import '../domain/models/ai_avatar.dart';
import '../domain/models/candidate_move.dart';
import '../domain/chess_persona_evaluator.dart';
import '../services/chess_sound_service.dart';
import '../services/chess_haptics_service.dart';
import '../data/stockfish_service.dart';
import '../data/chess_engine_service.dart';
import '../data/uci_parser.dart';
import '../data/saved_game.dart';
import 'chess_provider.dart';
import 'store_provider.dart';
import 'package:kingslayer_chess/src/rust/api/persona.dart' as rust_persona;
import 'package:kingslayer_chess/src/rust/api/threats.dart' as rust_threats;

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
  final List<String> dominatingSquares;
  final MoveAnimationData? moveAnimation;
  final bool isPlayerWhite;
  final bool isBoardFlipped;
  final bool isTimeOut;

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
    required this.dominatingSquares,
    this.moveAnimation,
    required this.isPlayerWhite,
    required this.isBoardFlipped,
    required this.isTimeOut,
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
  final List<String> dominatingSquares;
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
  final String? loadedGameId;
  final bool isGameOver;
  final String? startupError;
  final String? premoveFrom;
  final String? premoveTo;
  final bool isTemporaryQuickPlay;
  /// True when the clock has been permanently disabled after a timeout
  /// (user chose "Continue" from the timeout popup). Clock will not
  /// restart on subsequent moves until a new game is started.
  final bool clockDisabledAfterTimeout;

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
    this.dominatingSquares = const [],
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
    this.loadedGameId,
    this.isGameOver = false,
    this.startupError,
    this.premoveFrom,
    this.premoveTo,
    this.isTemporaryQuickPlay = false,
    this.clockDisabledAfterTimeout = false,
  });

  bool get isChess960 => gameMode == 'chess960';

  bool get isInReviewMode => (isGameOver || isTimeOut) && isGameOverDismissed;

  bool get canNavigateBack =>
      recentMoves.isNotEmpty &&
      (viewingMoveIndex == null ? recentMoves.isNotEmpty : viewingMoveIndex! > -1);

  bool get canNavigateForward => viewingMoveIndex != null;


  String get currentBoardFen {
    if (viewingMoveIndex == null || viewingMoveIndex! >= recentMoves.length) {
      return game.fen;
    }
    if (viewingMoveIndex! < 0) {
      return game.initialFen;
    }
    final tempGame = chess_lib.Chess.fromFEN(game.initialFen);
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
    List<String>? dominatingSquares,
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
    Object? loadedGameId = const Object(),
    bool? isGameOver,
    Object? startupError = const Object(),
    Object? premoveFrom = const Object(),
    Object? premoveTo = const Object(),
    bool? isTemporaryQuickPlay,
    bool? clockDisabledAfterTimeout,
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
      dominatingSquares: dominatingSquares ?? this.dominatingSquares,
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
      loadedGameId: loadedGameId == const Object() ? this.loadedGameId : loadedGameId as String?,
      isGameOver: isGameOver ?? this.isGameOver,
      premoveFrom: premoveFrom == const Object() ? this.premoveFrom : premoveFrom as String?,
      premoveTo: premoveTo == const Object() ? this.premoveTo : premoveTo as String?,
      isTemporaryQuickPlay: isTemporaryQuickPlay ?? this.isTemporaryQuickPlay,
      clockDisabledAfterTimeout: clockDisabledAfterTimeout ?? this.clockDisabledAfterTimeout,
    );
  }
}

class ArenaNotifier extends Notifier<ArenaState> {
  late final StockfishService _stockfishEngine;
  late final ChessSoundService _soundService;
  late final ChessHapticsService _hapticsService;

  final List<_ArenaSnapshot> _undoStack = [];
  final List<_ArenaSnapshot> _redoStack = [];

  Timer? _clockTimer;
  Timer? _engineMoveTimer;
  String? _scheduledMove;
  StreamSubscription<String>? _stockfishSubscription;

  Future<void>? _startupFuture;
  bool _isDisposed = false;
  DateTime _lastInfoUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _pendingHintFen;
  String? _searchFen;
  bool _waitingForReady = false;
  final List<CandidateMove> _currentCandidates = [];

  @override
  ArenaState build() {
    _stockfishEngine = ref.watch(stockfishServiceProvider);
    _soundService = ref.watch(chessSoundServiceProvider);
    _hapticsService = ref.watch(chessHapticsServiceProvider);

    ref.listen<ChessState>(chessProvider, (previous, next) {
      if (state.recentMoves.isEmpty && !state.isGameOver) {
        // Sync all settings when no game is in progress
        state = state.copyWith(
          engineLevel: next.engineLevel,
          bottomAvatarId: next.bottomAvatarId,
          whiteTimeLeft: next.baseTimeDuration,
          blackTimeLeft: next.baseTimeDuration,
          baseTimeDuration: next.baseTimeDuration,
        );
      } else {
        // Always sync engine/avatar IDs so the new-game overlay reflects
        // any persona changes made in settings mid-game.
        state = state.copyWith(
          engineLevel: next.engineLevel,
          bottomAvatarId: next.bottomAvatarId,
        );
      }
    });

    ref.onDispose(() {
      _isDisposed = true;
      _clockTimer?.cancel();
      _engineMoveTimer?.cancel();
      _scheduledMove = null;
      _stockfishSubscription?.cancel();
    });

    final settings = ref.read(chessProvider);
    final mode = settings.gameMode;
    final is960 = mode == 'chess960';
    final initialGame = is960
        ? ChessGame(fen: Chess960Generator.generateRandomPosition().fen, isChess960: true)
        : ChessGame(isChess960: false);

    return ArenaState(
      game: initialGame,
      isPlayerWhite: true,
      isBoardFlipped: false,
      engineLevel: settings.engineLevel,
      bottomAvatarId: settings.bottomAvatarId,
      whiteTimeLeft: settings.baseTimeDuration,
      blackTimeLeft: settings.baseTimeDuration,
      baseTimeDuration: settings.baseTimeDuration,
      incrementDuration: settings.incrementDuration,
      gameMode: mode,
      isGameOver: initialGame.gameOver,
    );
  }

  void _prepareNewGameFromSettings({
    bool forcedPlayerWhite = true,
    String? customFen,
    bool playSound = true,
  }) {
    _stopClockTimer();
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    _stopAnalysisAndReset();
    _undoStack.clear();
    _redoStack.clear();

    final settings = ref.read(chessProvider);
    final mode = customFen != null ? 'classic' : settings.gameMode;
    final is960 = mode == 'chess960';
    final initialGame = customFen != null
        ? ChessGame(fen: customFen, isChess960: false)
        : (is960
            ? ChessGame(fen: Chess960Generator.generateRandomPosition().fen, isChess960: true)
            : ChessGame(isChess960: false));

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
      isEngineVsEngine: false,
      engineLevel: settings.engineLevel,
      bottomAvatarId: settings.bottomAvatarId,
      canUndo: false,
      canRedo: false,
      hintBestMove: null,
      hintFrom: null,
      hintTo: null,
      isHintVisible: false,
      isHintLoading: false,
      isHintBlinking: false,
      isBulbGlowing: false,
      whiteTimeLeft: settings.baseTimeDuration,
      blackTimeLeft: settings.baseTimeDuration,
      baseTimeDuration: settings.baseTimeDuration,
      incrementDuration: settings.incrementDuration,
      gameMode: mode,
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
      loadedGameId: null,
      isGameOver: initialGame.gameOver,
      clockDisabledAfterTimeout: false,
    );

    if (playSound) {
      _soundService.playSfx(SoundEffect.uiClick);
    }
  }

  void clearPremove() {
    state = state.copyWith(premoveFrom: null, premoveTo: null);
  }

  ChessEngineService get _engine {
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
    if (state.servicesStarted && _stockfishEngine.isReady) {
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

      await _stockfishEngine.init();

      final is960 = state.gameMode == 'chess960';
      await _stockfishEngine.setChess960Mode(is960);

      final avatar = AiAvatar.getAvatar(state.engineLevel);
      final config = rust_persona.getPersonaConfig(avatarName: avatar.name);
      await _stockfishEngine.setSkillLevel(config.skillLevel, multiPV: config.multiPv);
      _stockfishEngine.sendCommand('setoption name MultiPV value ${config.multiPv}');
      _stockfishEngine.sendCommand('setoption name Hash value ${avatar.hashSize}');
      _stockfishEngine.sendCommand('setoption name Contempt value ${avatar.contempt}');

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

  void _stopAnalysisAndReset() {
    if (!state.servicesStarted || !state.engineReady) return;
    _waitingForReady = true;
    _engine.sendCommand('stop');
    _engine.sendCommand('isready');
  }

  void _startAnalysis({int? depth}) async {
    if (!state.servicesStarted || !state.engineReady || _waitingForReady || state.game.gameOver || state.isPaused) return;

    _currentCandidates.clear();
    final is960 = state.gameMode == 'chess960';
    await _engine.setChess960Mode(is960);

    final avatar = AiAvatar.getAvatar(_activeAvatarId);
    final config = rust_persona.getPersonaConfig(avatarName: avatar.name);
    await _engine.setSkillLevel(config.skillLevel, multiPV: config.multiPv);
    _engine.sendCommand('setoption name MultiPV value ${config.multiPv}');
    _engine.sendCommand('setoption name Hash value ${avatar.hashSize}');
    _engine.sendCommand('setoption name Contempt value ${avatar.contempt}');

    _searchFen = state.game.fen;
    final targetDepth = depth ?? config.depth;
    final quickPlayEnabled = ref.read(chessProvider).quickPlay || state.isTemporaryQuickPlay;

    if (quickPlayEnabled && _isAiTurn()) {
      _engine.analyzePosition(state.game.fen, depth: 1);
    } else if (!state.game.gameOver) {
      _engine.analyzePosition(
        state.game.fen,
        depth: targetDepth,
        wTime: state.whiteTimeLeft,
        bTime: state.blackTimeLeft,
        wInc: state.incrementDuration,
        bInc: state.incrementDuration,
      );

      // Safety fallback timer: if the engine doesn't return a move, force stop
      _engineMoveTimer?.cancel();
      final aiTimeLeft = state.isPlayerWhite ? state.blackTimeLeft : state.whiteTimeLeft;
      final safetyTimeoutMs = (aiTimeLeft.inMilliseconds * 0.2).clamp(1000.0, 5000.0).toInt();
      _engineMoveTimer = Timer(Duration(milliseconds: safetyTimeoutMs), () {
        if (!_isDisposed && _searchFen == state.game.fen && _isAiTurn()) {
          debugPrint('ArenaNotifier: Safety timer fired after ${safetyTimeoutMs}ms. Forcing bestmove.');
          _engine.stopAnalysis();
        }
      });
    } else {
      _engine.analyzePosition(state.game.fen, depth: targetDepth);
    }
  }

  void _handleEngineOutput(String line) {
    if (_isDisposed) return;

    final trimmed = line.trim();
    if (trimmed == 'readyok') {
      _waitingForReady = false;
      state = state.copyWith(engineReady: true);
      if (_isAiTurn() && !state.game.gameOver && !state.isPaused) {
        _startAnalysis();
      }
      return;
    }

    if (_waitingForReady) {
      return;
    }

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
        if (currentAvatar.name != 'King' && currentAvatar.name != 'Kingslayer') {
          bestMoveToPlay = ChessPersonaEvaluator.selectBestMove(
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
          !state.isPaused &&
          !state.isTimeOut) {
        _engineMoveTimer?.cancel();
        _engineMoveTimer = null;
        _scheduledMove = null;
        _makeEngineMove(bestMoveToPlay);
      }
    }
  }

  void _makeEngineMove(String move) {
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    // Don't play engine moves when the game is over, paused, or when the
    // timeout popup is showing (isTimeOut = true). After the user clicks
    // "Continue", isTimeOut is cleared and a fresh analysis request is made.
    if (move.length < 4 || state.game.gameOver || state.isPaused || state.isTimeOut) return;
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

    if (state.isEngineVsEngine) {
      _saveSnapshotForUndo();
    }

    final moveMade = state.game.makeMove({
      'from': from,
      'to': to,
      'promotion': promotion,
    });

    if (moveMade) {
      final wasClockStarted = state.clockStarted;
      final isClockDisabled = state.clockDisabledAfterTimeout;
      _onMoveCompleted('$from$to$promotion');
      if (state.isTemporaryQuickPlay) {
        state = state.copyWith(isTemporaryQuickPlay: false);
      }
      if (!isClockDisabled && !wasClockStarted) {
        state = state.copyWith(
          clockStarted: true,
          activeClockSide: _clockSideForTurn(),
        );
        _startClockTicker();
      }
      if (_isAiTurn() && !state.game.gameOver && !state.isPaused) {
        unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      }
    } else {
      state = state.copyWith(moveAnimation: null);
    }
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
      dominatingSquares: List<String>.from(state.dominatingSquares),
      moveAnimation: state.moveAnimation,
      isPlayerWhite: state.isPlayerWhite,
      isBoardFlipped: state.isBoardFlipped,
      isTimeOut: state.isTimeOut,
    );
  }

  void _restoreSnapshot(_ArenaSnapshot snapshot) {
    _pendingHintFen = null;
    final is960 = state.gameMode == 'chess960';
    final restoredGame = ChessGame(fen: snapshot.fen, isChess960: is960);

    state = state.copyWith(
      game: restoredGame,
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
      dominatingSquares: snapshot.dominatingSquares,
      moveAnimation: snapshot.moveAnimation,
      isPlayerWhite: snapshot.isPlayerWhite,
      isBoardFlipped: snapshot.isBoardFlipped,
      isGameOver: restoredGame.gameOver,
      isTimeOut: snapshot.isTimeOut,
      isGameOverDismissed: (restoredGame.gameOver || snapshot.isTimeOut) ? state.isGameOverDismissed : false,
    );

    final isAi = _isAiTurn();
    state = state.copyWith(
      isEngineThinking: isAi,
    );

    if (state.clockStarted) {
      _startClockTicker();
    } else {
      _stopClockTimer();
    }

    if (isAi) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
  }

  Future<void> makeMove(String from, String to) async {
    if (state.game.gameOver && state.viewingMoveIndex == null) return;
    if (state.isTimeOut && state.viewingMoveIndex == null) return;

    // Record theme usage day
    ref.read(storeProvider.notifier).recordThemeDay(ref.read(chessProvider).boardThemeId);

    _stopAnalysisAndReset();
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;

    if (state.viewingMoveIndex != null) {
      _truncateToViewingIndex();
      state = state.copyWith(
        isGameOverDismissed: false,
        isTimeOut: false,
      );
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

    if (!_isPlayerTurn() && !state.isEngineVsEngine) {
      debugPrint('ArenaNotifier: Setting pre-move from $from to $to');
      state = state.copyWith(premoveFrom: from, premoveTo: to);
      return;
    }

    if (state.isEngineVsEngine) {
      final turnColor = state.game.turn;
      state = state.copyWith(
        isEngineVsEngine: false,
        isPlayerWhite: turnColor == chess_lib.Color.WHITE,
      );
    }

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
      _stopClockTimer();
      _soundService.playSfx(SoundEffect.promote);
      _hapticsService.selection();
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
    final isClockDisabled = state.clockDisabledAfterTimeout;
    _onMoveCompleted('$from$to');

    // Only (re)start the clock if it was already running and hasn't been
    // permanently disabled by a prior timeout-continue action.
    if (!isClockDisabled) {
      if (!wasClockStarted) {
        state = state.copyWith(clockStarted: true);
      }
      state = state.copyWith(activeClockSide: _clockSideForTurn());
      _startClockTicker();
    }

    if (_isAiTurn()) {
      state = state.copyWith(isEngineThinking: true);
    }
    await ensureGameServicesStarted(analyzeCurrentPosition: true);
    state = state.copyWith(isEngineThinking: state.engineReady);
  }

  void _truncateToViewingIndex() {
    if (state.viewingMoveIndex == null) return;
    final index = state.viewingMoveIndex!;
    final movesToKeep = state.recentMoves.sublist(0, index + 1);

    final is960 = state.gameMode == 'chess960';
    final tempGame = ChessGame(fen: state.game.initialFen, isChess960: is960);

    for (final m in movesToKeep) {
      tempGame.makeMove({'from': m.substring(0, 2), 'to': m.substring(2, 4), 'promotion': m.length > 4 ? m[4] : 'q'});
    }

    state = state.copyWith(
      game: tempGame,
      recentMoves: movesToKeep,
      lastMove: movesToKeep.isEmpty ? null : movesToKeep.last,
      viewingMoveIndex: null,
      isGameOver: tempGame.gameOver,
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

    // Compute dominating squares via Rust engine (sync FFI call).
    List<String> dominating = const [];
    try {
      dominating = rust_threats.getDominatingSquares(
        fen: state.game.fen,
        isChess960: state.isChess960,
      );
    } catch (e) {
      debugPrint('ArenaNotifier: getDominatingSquares error: $e');
    }

    state = state.copyWith(
      game: state.game,
      lastMove: moveLabel,
      recentMoves: updatedMoves,
      isEngineThinking: _isAiTurn() && state.servicesStarted && state.engineReady,
      activeClockSide: state.clockStarted ? _clockSideForTurn() : state.activeClockSide,
      threatenedSquares: threatened,
      dominatingSquares: dominating,
      isGameOver: state.game.gameOver,
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

    debugPrint('ArenaNotifier: _onMoveCompleted called. Player turn: ${_isPlayerTurn()}, premove: ${state.premoveFrom} -> ${state.premoveTo}');
    if (_isPlayerTurn() &&
        state.premoveFrom != null &&
        state.premoveTo != null) {
      final pFrom = state.premoveFrom!;
      final pTo = state.premoveTo!;
      debugPrint('ArenaNotifier: Found pre-move $pFrom -> $pTo. Clearing premove fields. Game FEN: ${state.game.fen}');
      state = state.copyWith(premoveFrom: null, premoveTo: null);

      final legalMoves = state.game.generateMoves();
      bool isLegal = false;
      final movesList = <String>[];
      for (final m in legalMoves) {
        final fromAlg = chess_lib.Chess.algebraic(m.from);
        final toAlg = chess_lib.Chess.algebraic(m.to);
        movesList.add('$fromAlg$toAlg');
        if (fromAlg == pFrom && toAlg == pTo) {
          isLegal = true;
          break;
        }
      }
      debugPrint('ArenaNotifier: Legal moves on the board: $movesList');

      debugPrint('ArenaNotifier: Pre-move legality: $isLegal');
      if (isLegal) {
        debugPrint('ArenaNotifier: Scheduling pre-move execution in 300ms');
        Future.delayed(const Duration(milliseconds: 300), () {
          debugPrint('ArenaNotifier: Delayed trigger: playerTurn=${_isPlayerTurn()}, disposed=$_isDisposed');
          if (!_isDisposed && _isPlayerTurn()) {
            debugPrint('ArenaNotifier: Executing pre-move $pFrom -> $pTo');
            makeMove(pFrom, pTo);
          }
        });
      }
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

    if (state.isEngineVsEngine) {
      final turnColor = state.game.turn;
      state = state.copyWith(
        isEngineVsEngine: false,
        isPlayerWhite: turnColor == chess_lib.Color.WHITE,
      );
    }

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
      final wasClockStarted = state.clockStarted;
      final isClockDisabled = state.clockDisabledAfterTimeout;
      _onMoveCompleted('$from$to${promotionPiece.toLowerCase()}');
      if (!isClockDisabled) {
        if (!wasClockStarted) {
          state = state.copyWith(clockStarted: true);
        }
        state = state.copyWith(activeClockSide: _clockSideForTurn());
        _startClockTicker();
      }
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      state = state.copyWith(isEngineThinking: state.engineReady);
    } else {
      state = state.copyWith(moveAnimation: null);
    }
  }

  void cancelPromotion() {
    if (!state.isPromoting) return;
    if (_undoStack.isNotEmpty) {
      _undoStack.removeLast();
      _syncUndoRedoFlags();
    }
    state = state.copyWith(
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
    );
    if (state.clockStarted && !state.isPaused) {
      _startClockTicker();
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    _stopAnalysisAndReset();

    _redoStack.add(_captureCurrentSnapshot());

    _ArenaSnapshot? snapshot;
    while (_undoStack.isNotEmpty) {
      snapshot = _undoStack.removeLast();
      if (state.isEngineVsEngine) {
        break;
      }
      final tempGame = chess_lib.Chess.fromFEN(snapshot.fen);
      final turn = tempGame.turn;
      final isPlayerTurn = snapshot.isPlayerWhite
          ? (turn == chess_lib.Color.WHITE)
          : (turn == chess_lib.Color.BLACK);
      if (isPlayerTurn) {
        break;
      } else {
        _redoStack.add(snapshot);
      }
    }

    if (snapshot != null) {
      _restoreSnapshot(snapshot);
    }
    _syncUndoRedoFlags();
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    _stopAnalysisAndReset();
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
      _scheduledMove = null;
      _stopAnalysisAndReset();
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

  void forcePlay() {
    if (!_isAiTurn() || state.game.gameOver || state.isPaused) return;
    if (_scheduledMove != null) {
      final move = _scheduledMove!;
      _engineMoveTimer?.cancel();
      _engineMoveTimer = null;
      _scheduledMove = null;
      _makeEngineMove(move);
      _soundService.playSfx(SoundEffect.uiClick);
      return;
    }
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    _engine.sendCommand('stop');
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void activateTemporaryQuickPlay() {
    if (state.game.gameOver || state.isPaused) return;
    state = state.copyWith(isTemporaryQuickPlay: true);
    _soundService.playSfx(SoundEffect.switchToggle);
    if (_isAiTurn()) {
      if (state.isEngineThinking) {
        forcePlay();
      } else {
        state = state.copyWith(isEngineThinking: true);
        unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      }
    }
  }

  void restartNormalAnalysis() {
    if (!_isAiTurn() || state.game.gameOver || state.isPaused) return;
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    _stopAnalysisAndReset();
    _startAnalysis();
    state = state.copyWith(isEngineThinking: true);
  }

  void toggleEngineVsEngine() {
    final newVal = !state.isEngineVsEngine;
    state = state.copyWith(isEngineVsEngine: newVal);

    if (newVal) {
      if (_isAiTurn() && !state.game.gameOver && !state.isPaused) {
        state = state.copyWith(isEngineThinking: true);
        unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      }
    } else {
      // Toggled off: check if it's the down side's turn (user's side).
      final turn = state.game.turn;
      final isBottomTurn = state.isPlayerWhite
          ? (turn == chess_lib.Color.WHITE)
          : (turn == chess_lib.Color.BLACK);
      if (isBottomTurn) {
        // Disconnect the bot
        _stopAnalysisAndReset();
        state = state.copyWith(isEngineThinking: false);
      }
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

  void reset({bool forcedPlayerWhite = true, String? customFen}) {
    _prepareNewGameFromSettings(
      forcedPlayerWhite: forcedPlayerWhite,
      customFen: customFen,
    );
    if (_isAiTurn()) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
  }

  void toggleBoardOrientation() {
    final isFlipped = !state.isBoardFlipped;
    state = state.copyWith(
      isBoardFlipped: isFlipped,
      isPlayerWhite: !isFlipped,
    );
    if (_isAiTurn()) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void setGameMode(String mode) {
    if (state.gameMode == mode) return;
    unawaited(ref.read(chessProvider.notifier).setGameMode(mode));
    reset(forcedPlayerWhite: state.isPlayerWhite);
  }

  void setBoardTheme(String themeId) {
    // Themes are global preferences in chessProvider
    ref.read(chessProvider.notifier).setBoardTheme(themeId);
  }

  void setTimeControl(Duration total, Duration increment) {
    ref.read(chessProvider.notifier).setTimeControl(total, increment);
    final canUpdateReadyBoard = state.recentMoves.isEmpty && !state.clockStarted;
    state = state.copyWith(
      baseTimeDuration: total,
      incrementDuration: increment,
      whiteTimeLeft: canUpdateReadyBoard ? total : state.whiteTimeLeft,
      blackTimeLeft: canUpdateReadyBoard ? total : state.blackTimeLeft,
    );
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
    // Cancel any pending engine move timer so the AI can't sneak in a
    // move after the clock has expired.
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    _stopAnalysisAndReset();

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

  void navigateBack() {
    if (state.recentMoves.isEmpty) return;
    final current = state.viewingMoveIndex;
    if (current == null) {
      if (state.recentMoves.length > 1) {
        state = state.copyWith(viewingMoveIndex: state.recentMoves.length - 2);
      } else {
        state = state.copyWith(viewingMoveIndex: -1);
      }
    } else if (current > -1) {
      state = state.copyWith(viewingMoveIndex: current - 1);
    }
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void navigateForward() {
    final current = state.viewingMoveIndex;
    if (current == null) return;
    final next = current + 1;
    if (next >= state.recentMoves.length) {
      state = state.copyWith(viewingMoveIndex: null);
    } else {
      state = state.copyWith(viewingMoveIndex: next);
    }
    _soundService.playSfx(SoundEffect.uiClick);
  }

  void continueAfterTimeout() {
    // Disable the clock permanently for the rest of this game so it
    // doesn't restart when either side makes their next move.
    state = state.copyWith(
      isTimeOut: false,
      isGameOverDismissed: false,
      clockStarted: false,
      activeClockSide: null,
      clockDisabledAfterTimeout: true,
    );
    if (_isAiTurn()) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
    _soundService.playSfx(SoundEffect.uiClick);
  }

  Future<SavedGameEntry> saveCurrentGame({String? resultOverride}) async {
    final moves = List<String>.from(state.recentMoves);
    final isWhite = state.isPlayerWhite;
    final fen = state.game.fen;

    String? existingCustomName;
    bool existingIsFavorite = false;
    final finalId = state.loadedGameId ?? DateTime.now().millisecondsSinceEpoch.toString();

    if (state.loadedGameId != null) {
      try {
        final repository = ref.read(savedGameRepositoryProvider);
        final saves = await repository.listSaves();
        final index = saves.indexWhere((e) => e.id == state.loadedGameId);
        if (index != -1) {
          final existing = saves[index];
          existingCustomName = existing.customName;
          existingIsFavorite = existing.isFavorite;
        }
      } catch (e) {
        debugPrint('Failed to load existing game details for overwrite: $e');
      }
    }

    final entry = SavedGameEntry(
      id: finalId,
      savedAt: DateTime.now(),
      fen: fen,
      recentMoves: moves,
      isPlayerWhite: isWhite,
      isBoardFlipped: state.isBoardFlipped,
      whiteTimeLeftMs: state.whiteTimeLeft.inMilliseconds,
      blackTimeLeftMs: state.blackTimeLeft.inMilliseconds,
      clockStarted: false,
      activeClockSide: null,
      customName: existingCustomName ?? 'Arena Game',
      isFavorite: existingIsFavorite,
      isRatedMode: false,
      result: resultOverride,
    );

    try {
      await ref.read(savedGameRepositoryProvider).save(entry);
    } catch (e) {
      debugPrint('ArenaNotifier: Failed to save game: $e');
    }
    await ref.read(chessProvider.notifier).loadSavedGames();
    return entry;
  }

  List<String> _computeDominatingSquares(String fen, bool isChess960) {
    try {
      return rust_threats.getDominatingSquares(fen: fen, isChess960: isChess960);
    } catch (e) {
      debugPrint('ArenaNotifier: getDominatingSquares error: $e');
      return const [];
    }
  }

  void clearMoveAnimation() {
    state = state.copyWith(moveAnimation: null);
  }

  Future<void> loadSavedGame(SavedGameEntry entry) async {
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _scheduledMove = null;
    _stopAnalysisAndReset();
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
      dominatingSquares: _computeDominatingSquares(restoredGame.fen, is960),
      isPromoting: false,
      isGameOverDismissed: false,
      isTimeOut: false,
      loadedGameId: entry.id,
      isGameOver: restoredGame.gameOver,
    );

    final isAi = _isAiTurn();
    state = state.copyWith(
      isEngineThinking: isAi,
    );

    if (state.clockStarted) {
      _startClockTicker();
    }

    if (isAi && !restoredGame.gameOver && !state.isPaused) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
  }

}

final arenaProvider = NotifierProvider<ArenaNotifier, ArenaState>(ArenaNotifier.new);
