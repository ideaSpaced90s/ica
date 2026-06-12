import 'dart:math' as math;
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
import '../data/uci_parser.dart';
import '../data/saved_game.dart';
import '../data/saved_game_repository.dart';
import '../domain/performance_ledger_entry.dart';
import '../data/performance_ledger_repository.dart';
import '../data/settings_repository.dart';
import '../domain/opening_classifier.dart';
import '../domain/fen_parser.dart';
import '../domain/models/dashboard_stats.dart';
import 'package:kingslayer_chess/src/rust/api/cognitive.dart';
import 'chess_provider.dart';

const _initialClock = Duration(minutes: 10);
const _clockWhite = 'white';
const _clockBlack = 'black';

List<PerformanceLedgerEntry> selectScotomaLedgerEntries(
  Iterable<PerformanceLedgerEntry> entries,
) {
  return entries
      .where(
        (entry) =>
            entry.source == PerformanceLedgerEntry.ratedBattlegroundSource &&
            const {'W', 'L', 'D'}.contains(entry.result),
      )
      .toList();
}

class BattlegroundState {
  final ChessGame game;
  final String? lastMove;
  final List<String> recentMoves;
  final List<String> uciMoves;
  final Map<String, dynamic> analysis;
  final double previousEvaluation;
  final double currentEvaluation;
  final bool isEngineThinking;
  final bool isPlayerWhite;
  final bool isBoardFlipped;
  final AiAvatar? activeOpponent;
  final bool clockStarted;
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;
  final Duration baseTimeDuration;
  final Duration incrementDuration;
  final String? activeClockSide;
  final List<String> threatenedSquares;
  final MoveAnimationData? moveAnimation;
  final bool isPaused;
  final int? viewingMoveIndex;
  final bool isGameOverDismissed;
  final bool isPromoting;
  final String? promotionSource;
  final String? promotionDestination;
  final String gameMode;
  final bool isTimeOut;
  final bool servicesStarted;
  final bool servicesStarting;
  final bool engineReady;
  final String? startupError;
  final String? premoveFrom;
  final String? premoveTo;

  // Rated ELO fields
  final int consolidatedRating;
  final int bulletElo;
  final int blitzElo;
  final int rapidElo;
  final int totalRatedGamesCount;
  final int bulletGamesClassic;
  final int bulletGames960;
  final int blitzGamesClassic;
  final int blitzGames960;
  final int rapidGamesClassic;
  final int rapidGames960;
  final int totalWinningStreak;
  final int bulletStreak;
  final int blitzStreak;
  final int rapidStreak;
  final double bulletDominance;
  final double blitzDominance;
  final double rapidDominance;
  final String? activeRatedMatchId;

  final int recalibrationGamesRemaining;
  final int? lastRatedGameTimestampMs;
  final int decayIntervalsApplied;

  // Cached dashboard metrics
  final ScotomaResult? cachedScotoma;
  final TacticalPlaystyleStats? cachedPlaystyle;
  final List<OpeningRepertoireStats> cachedOpenings;
  final MiddlegamePerformanceStats? cachedMiddlegames;
  final EndgamePerformanceStats? cachedEndgames;
  final List<double> cachedDominanceHeatmap;
  final List<PerformanceLedgerEntry> cachedLedgerEntries;

  BattlegroundState({
    required this.game,
    this.lastMove,
    this.recentMoves = const [],
    this.uciMoves = const [],
    this.analysis = const {},
    this.previousEvaluation = 0.0,
    this.currentEvaluation = 0.0,
    this.isEngineThinking = false,
    this.isPlayerWhite = true,
    this.isBoardFlipped = false,
    this.activeOpponent,
    this.clockStarted = false,
    this.whiteTimeLeft = _initialClock,
    this.blackTimeLeft = _initialClock,
    this.baseTimeDuration = _initialClock,
    this.incrementDuration = Duration.zero,
    this.activeClockSide,
    this.threatenedSquares = const [],
    this.moveAnimation,
    this.isPaused = false,
    this.viewingMoveIndex,
    this.isGameOverDismissed = false,
    this.isPromoting = false,
    this.promotionSource,
    this.promotionDestination,
    this.gameMode = 'classic',
    this.isTimeOut = false,
    this.servicesStarted = false,
    this.servicesStarting = false,
    this.engineReady = false,
    this.startupError,
    this.premoveFrom,
    this.premoveTo,

    // Rated
    this.consolidatedRating = 400,
    this.bulletElo = 400,
    this.blitzElo = 400,
    this.rapidElo = 400,
    this.totalRatedGamesCount = 0,
    this.bulletGamesClassic = 0,
    this.bulletGames960 = 0,
    this.blitzGamesClassic = 0,
    this.blitzGames960 = 0,
    this.rapidGamesClassic = 0,
    this.rapidGames960 = 0,
    this.totalWinningStreak = 0,
    this.bulletStreak = 0,
    this.blitzStreak = 0,
    this.rapidStreak = 0,
    this.bulletDominance = 0.0,
    this.blitzDominance = 0.0,
    this.rapidDominance = 0.0,
    this.activeRatedMatchId,

    // Rated inactivity & recalibration
    this.recalibrationGamesRemaining = 0,
    this.lastRatedGameTimestampMs,
    this.decayIntervalsApplied = 0,

    // Cached metrics
    this.cachedScotoma,
    this.cachedPlaystyle,
    this.cachedOpenings = const [],
    this.cachedMiddlegames,
    this.cachedEndgames,
    this.cachedDominanceHeatmap = const [],
    this.cachedLedgerEntries = const [],
  });

  bool get isChess960 => gameMode == 'chess960';
  bool get isCalibrating => totalRatedGamesCount < 10;
  bool get isCalibrated => totalRatedGamesCount >= 10 && recalibrationGamesRemaining == 0;
  int get calibrationGamesRemaining => math.max(0, 10 - totalRatedGamesCount);

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

  BattlegroundState copyWith({
    ChessGame? game,
    Object? lastMove = const Object(),
    List<String>? recentMoves,
    List<String>? uciMoves,
    Map<String, dynamic>? analysis,
    double? previousEvaluation,
    double? currentEvaluation,
    bool? isEngineThinking,
    bool? isPlayerWhite,
    bool? isBoardFlipped,
    Object? activeOpponent = const Object(),
    bool? clockStarted,
    Duration? whiteTimeLeft,
    Duration? blackTimeLeft,
    Duration? baseTimeDuration,
    Duration? incrementDuration,
    Object? activeClockSide = const Object(),
    List<String>? threatenedSquares,
    Object? moveAnimation = const Object(),
    bool? isPaused,
    Object? viewingMoveIndex = const Object(),
    bool? isGameOverDismissed,
    bool? isPromoting,
    Object? promotionSource = const Object(),
    Object? promotionDestination = const Object(),
    String? gameMode,
    bool? isTimeOut,
    bool? servicesStarted,
    bool? servicesStarting,
    bool? engineReady,
    Object? startupError = const Object(),
    Object? premoveFrom = const Object(),
    Object? premoveTo = const Object(),

    // Rated
    int? consolidatedRating,
    int? bulletElo,
    int? blitzElo,
    int? rapidElo,
    int? totalRatedGamesCount,
    int? bulletGamesClassic,
    int? bulletGames960,
    int? blitzGamesClassic,
    int? blitzGames960,
    int? rapidGamesClassic,
    int? rapidGames960,
    int? totalWinningStreak,
    int? bulletStreak,
    int? blitzStreak,
    int? rapidStreak,
    double? bulletDominance,
    double? blitzDominance,
    double? rapidDominance,
    Object? activeRatedMatchId = const Object(),

    int? recalibrationGamesRemaining,
    int? lastRatedGameTimestampMs,
    int? decayIntervalsApplied,

    // Cached metrics
    ScotomaResult? cachedScotoma,
    TacticalPlaystyleStats? cachedPlaystyle,
    List<OpeningRepertoireStats>? cachedOpenings,
    MiddlegamePerformanceStats? cachedMiddlegames,
    EndgamePerformanceStats? cachedEndgames,
    List<double>? cachedDominanceHeatmap,
    List<PerformanceLedgerEntry>? cachedLedgerEntries,
  }) {
    return BattlegroundState(
      game: game ?? this.game,
      lastMove: lastMove == const Object()
          ? this.lastMove
          : lastMove as String?,
      recentMoves: recentMoves ?? this.recentMoves,
      uciMoves: uciMoves ?? this.uciMoves,
      analysis: analysis ?? this.analysis,
      previousEvaluation: previousEvaluation ?? this.previousEvaluation,
      currentEvaluation: currentEvaluation ?? this.currentEvaluation,
      isEngineThinking: isEngineThinking ?? this.isEngineThinking,
      isPlayerWhite: isPlayerWhite ?? this.isPlayerWhite,
      isBoardFlipped: isBoardFlipped ?? this.isBoardFlipped,
      activeOpponent: activeOpponent == const Object()
          ? this.activeOpponent
          : activeOpponent as AiAvatar?,
      clockStarted: clockStarted ?? this.clockStarted,
      whiteTimeLeft: whiteTimeLeft ?? this.whiteTimeLeft,
      blackTimeLeft: blackTimeLeft ?? this.blackTimeLeft,
      baseTimeDuration: baseTimeDuration ?? this.baseTimeDuration,
      incrementDuration: incrementDuration ?? this.incrementDuration,
      activeClockSide: activeClockSide == const Object()
          ? this.activeClockSide
          : activeClockSide as String?,
      threatenedSquares: threatenedSquares ?? this.threatenedSquares,
      moveAnimation: moveAnimation == const Object()
          ? this.moveAnimation
          : moveAnimation as MoveAnimationData?,
      isPaused: isPaused ?? this.isPaused,
      viewingMoveIndex: viewingMoveIndex == const Object()
          ? this.viewingMoveIndex
          : viewingMoveIndex as int?,
      isGameOverDismissed: isGameOverDismissed ?? this.isGameOverDismissed,
      isPromoting: isPromoting ?? this.isPromoting,
      promotionSource: promotionSource == const Object()
          ? this.promotionSource
          : promotionSource as String?,
      promotionDestination: promotionDestination == const Object()
          ? this.promotionDestination
          : promotionDestination as String?,
      gameMode: gameMode ?? this.gameMode,
      isTimeOut: isTimeOut ?? this.isTimeOut,
      servicesStarted: servicesStarted ?? this.servicesStarted,
      servicesStarting: servicesStarting ?? this.servicesStarting,
      engineReady: engineReady ?? this.engineReady,
      startupError: startupError == const Object()
          ? this.startupError
          : startupError as String?,
      premoveFrom: premoveFrom == const Object()
          ? this.premoveFrom
          : premoveFrom as String?,
      premoveTo: premoveTo == const Object()
          ? this.premoveTo
          : premoveTo as String?,

      // Rated
      consolidatedRating: consolidatedRating ?? this.consolidatedRating,
      bulletElo: bulletElo ?? this.bulletElo,
      blitzElo: blitzElo ?? this.blitzElo,
      rapidElo: rapidElo ?? this.rapidElo,
      totalRatedGamesCount: totalRatedGamesCount ?? this.totalRatedGamesCount,
      bulletGamesClassic: bulletGamesClassic ?? this.bulletGamesClassic,
      bulletGames960: bulletGames960 ?? this.bulletGames960,
      blitzGamesClassic: blitzGamesClassic ?? this.blitzGamesClassic,
      blitzGames960: blitzGames960 ?? this.blitzGames960,
      rapidGamesClassic: rapidGamesClassic ?? this.rapidGamesClassic,
      rapidGames960: rapidGames960 ?? this.rapidGames960,
      totalWinningStreak: totalWinningStreak ?? this.totalWinningStreak,
      bulletStreak: bulletStreak ?? this.bulletStreak,
      blitzStreak: blitzStreak ?? this.blitzStreak,
      rapidStreak: rapidStreak ?? this.rapidStreak,
      bulletDominance: bulletDominance ?? this.bulletDominance,
      blitzDominance: blitzDominance ?? this.blitzDominance,
      rapidDominance: rapidDominance ?? this.rapidDominance,
      activeRatedMatchId: activeRatedMatchId == const Object()
          ? this.activeRatedMatchId
          : activeRatedMatchId as String?,

      recalibrationGamesRemaining: recalibrationGamesRemaining ?? this.recalibrationGamesRemaining,
      lastRatedGameTimestampMs: lastRatedGameTimestampMs ?? this.lastRatedGameTimestampMs,
      decayIntervalsApplied: decayIntervalsApplied ?? this.decayIntervalsApplied,

      // Cached metrics
      cachedScotoma: cachedScotoma ?? this.cachedScotoma,
      cachedPlaystyle: cachedPlaystyle ?? this.cachedPlaystyle,
      cachedOpenings: cachedOpenings ?? this.cachedOpenings,
      cachedMiddlegames: cachedMiddlegames ?? this.cachedMiddlegames,
      cachedEndgames: cachedEndgames ?? this.cachedEndgames,
      cachedDominanceHeatmap:
          cachedDominanceHeatmap ?? this.cachedDominanceHeatmap,
      cachedLedgerEntries: cachedLedgerEntries ?? this.cachedLedgerEntries,
    );
  }
}

class BattlegroundNotifier extends StateNotifier<BattlegroundState> {
  final Ref ref;
  final StockfishService _stockfishEngine;
  final SavedGameRepository _savedGameRepository;
  final PerformanceLedgerRepository _performanceLedgerRepository;
  // ignore: unused_field
  final ChessSoundService _soundService;
  // ignore: unused_field
  final ChessHapticsService _hapticsService;
  final SettingsRepository _settingsRepository;

  Timer? _clockTimer;
  Timer? _engineMoveTimer;
  StreamSubscription<String>? _stockfishSubscription;

  Future<void>? _startupFuture;
  bool _isDisposed = false;
  DateTime _lastInfoUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _searchFen;
  final List<CandidateMove> _currentCandidates = [];

  BattlegroundNotifier(
    this.ref,
    this._stockfishEngine,
    this._savedGameRepository,
    this._performanceLedgerRepository,
    this._soundService,
    this._hapticsService,
    this._settingsRepository,
  ) : super(BattlegroundState(game: ChessGame())) {
    _loadInitialStateAndLedger();
  }

  Future<void> _loadInitialStateAndLedger() async {
    final settings = ref.read(chessProvider);
    final s = await _settingsRepository.loadSettings();

    state = state.copyWith(
      isBoardFlipped: settings.isBoardFlipped,
      isPlayerWhite: settings.isPlayerWhite,
      gameMode: settings.gameMode,

      // Load Elo ratings, streaks, and counts
      consolidatedRating: s.consolidatedRating,
      bulletElo: s.bulletElo,
      blitzElo: s.blitzElo,
      rapidElo: s.rapidElo,
      totalRatedGamesCount: s.totalRatedGamesCount,
      bulletGamesClassic: s.bulletGamesClassic,
      bulletGames960: s.bulletGames960,
      blitzGamesClassic: s.blitzGamesClassic,
      blitzGames960: s.blitzGames960,
      rapidGamesClassic: s.rapidGamesClassic,
      rapidGames960: s.rapidGames960,
      totalWinningStreak: s.totalWinningStreak,
      bulletStreak: s.bulletStreak,
      blitzStreak: s.blitzStreak,
      rapidStreak: s.rapidStreak,
      bulletDominance: s.bulletDominance,
      blitzDominance: s.blitzDominance,
      rapidDominance: s.rapidDominance,
      activeRatedMatchId: s.activeRatedMatchId,
      recalibrationGamesRemaining: s.recalibrationGamesRemaining,
      lastRatedGameTimestampMs: s.lastRatedGameTimestampMs,
      decayIntervalsApplied: s.decayIntervalsApplied,
    );

    // Apply inactivity check and ELO decay before loading history
    await _checkInactivityAndApplyDecay();

    // Load ledger entries
    final ledgerEntries = await _performanceLedgerRepository.listEntries();
    state = state.copyWith(cachedLedgerEntries: ledgerEntries);
    _refreshDashboardStats();

    // Auto select rated opponent
    _autoSelectRatedOpponent();

    // Check for active rated match ID found on boot (unfair exit loss registration)
    if (s.activeRatedMatchId != null) {
      final matchId = s.activeRatedMatchId!;
      debugPrint(
        'BattlegroundNotifier: Active rated match ID found on boot: $matchId. Registering unfair exit loss.',
      );

      // Clear the activeRatedMatchId immediately from state and disk first.
      // This guarantees that any subsequent async step or developer hot restart
      // will not see the stale match ID again, preventing a phantom exit loop.
      state = state.copyWith(activeRatedMatchId: null);
      await _saveSettings();

      await _updateRating(0.0);

      final entry = SavedGameEntry(
        id: matchId,
        savedAt: DateTime.now(),
        fen: chess_lib.Chess.DEFAULT_POSITION,
        recentMoves: const [],
        uciMoves: const [],
        isPlayerWhite: true,
        isBoardFlipped: false,
        whiteTimeLeftMs: 0,
        blackTimeLeftMs: 0,
        clockStarted: false,
        activeClockSide: null,
        customName: 'Rated Loss (Unfair Exit)',
        isRatedMode: true,
        result: 'L',
      );
      await _savedGameRepository.save(entry);

      // reload ledger
      final freshLedger = await _performanceLedgerRepository.listEntries();
      state = state.copyWith(cachedLedgerEntries: freshLedger);
      _refreshDashboardStats();
    }
  }

  void _autoSelectRatedOpponent() {
    final bestMatch = AiAvatar.getBestMatch(state.consolidatedRating);
    debugPrint(
      'BattlegroundNotifier: Auto-selecting rated opponent for ELO ${state.consolidatedRating}: ${bestMatch.name}',
    );
    state = state.copyWith(activeOpponent: bestMatch);
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

    state = state.copyWith(servicesStarting: true, startupError: null);

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
      _stockfishSubscription ??= _stockfishEngine.outputStream.listen(
        _handleEngineOutput,
      );
      await _stockfishEngine.init();

      final opponent =
          state.activeOpponent ??
          AiAvatar.getBestMatch(state.consolidatedRating);
      await _stockfishEngine.setSkillLevel(
        opponent.skillLevel,
        multiPV: (opponent.name == 'King' || opponent.name == 'Kingslayer')
            ? 1
            : 4,
      );
      _stockfishEngine.sendCommand(
        'setoption name MultiPV value ${(opponent.name == 'King' || opponent.name == 'Kingslayer') ? 1 : 4}',
      );

      state = state.copyWith(
        servicesStarted: true,
        servicesStarting: false,
        engineReady: _stockfishEngine.isReady,
        startupError: null,
      );

      if (analyzeCurrentPosition) {
        _startAnalysis(depth: depth);
      }
    } catch (e) {
      debugPrint('BattlegroundNotifier: Startup failed: $e');
      state = state.copyWith(
        servicesStarting: false,
        servicesStarted: false,
        engineReady: false,
        startupError: 'Unable to start the engine.',
      );
    }
  }

  void _startAnalysis({int? depth}) async {
    if (!state.servicesStarted ||
        !state.engineReady ||
        state.game.gameOver ||
        state.isPaused) {
      return;
    }

    _currentCandidates.clear();
    final is960 = state.gameMode == 'chess960';
    await _stockfishEngine.setChess960Mode(is960);

    final opponent =
        state.activeOpponent ?? AiAvatar.getBestMatch(state.consolidatedRating);
    await _stockfishEngine.setSkillLevel(
      opponent.skillLevel,
      multiPV: (opponent.name == 'King' || opponent.name == 'Kingslayer')
          ? 1
          : 4,
    );
    _stockfishEngine.sendCommand(
      'setoption name MultiPV value ${(opponent.name == 'King' || opponent.name == 'Kingslayer') ? 1 : 4}',
    );

    _searchFen = state.game.fen;
    final targetDepth = depth ?? opponent.depth;
    if (state.clockStarted && !state.game.gameOver) {
      _stockfishEngine.analyzePosition(
        state.game.fen,
        depth: targetDepth,
        wTime: state.whiteTimeLeft,
        bTime: state.blackTimeLeft,
        wInc: state.incrementDuration,
        bInc: state.incrementDuration,
      );
    } else {
      _stockfishEngine.analyzePosition(state.game.fen, depth: targetDepth);
    }
  }

  void _handleEngineOutput(String line) {
    if (_isDisposed) return;
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

      // Ensure the move is actually intended for the current turn's side
      bool isMoveValidForCurrentTurn = false;
      if (bestMoveToPlay != null && bestMoveToPlay.length >= 4) {
        final fromSquare = bestMoveToPlay.substring(0, 2);
        final piece = state.game.getPiece(fromSquare);
        if (piece != null && piece.color == state.game.turn) {
          isMoveValidForCurrentTurn = true;
        }
      }

      if (bestMoveToPlay != null && aiTurn && isMoveValidForCurrentTurn) {
        final opponent =
            state.activeOpponent ??
            AiAvatar.getBestMatch(state.consolidatedRating);
        if (opponent.name != 'King' &&
            opponent.name != 'Kingslayer' &&
            _currentCandidates.isNotEmpty) {
          bestMoveToPlay = ChessPersonaEvaluator.selectBestMove(
            List.from(_currentCandidates),
            opponent,
            state.game,
            bestMoveToPlay,
          );
        }
        _currentCandidates.clear();
      }

      if (bestMoveToPlay != null &&
          aiTurn &&
          isMoveValidForCurrentTurn &&
          !state.game.gameOver &&
          !state.isPaused) {
        _engineMoveTimer?.cancel();
        final finalMove = bestMoveToPlay;
        // In rated mode we make moves instantly
        _makeEngineMove(finalMove);
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
    if (piece?.type == chess_lib.PieceType.KING &&
        (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
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
      final actualPromo = move.length > 4 ? move[4] : '';
      unawaited(_onMoveCompleted('$from$to$actualPromo'));
    } else {
      state = state.copyWith(moveAnimation: null);
    }
  }

  bool _isPlayerTurn() {
    if (state.game.gameOver || state.isPaused) return false;
    final turn = state.game.turn;
    return state.isPlayerWhite
        ? (turn == chess_lib.Color.WHITE)
        : (turn == chess_lib.Color.BLACK);
  }

  bool _isAiTurn() {
    if (state.game.gameOver || state.isPaused) return false;
    final turn = state.game.turn;
    return state.isPlayerWhite
        ? (turn == chess_lib.Color.BLACK)
        : (turn == chess_lib.Color.WHITE);
  }

  Future<void> makeMove(String from, String to) async {
    if (state.game.gameOver) return;

    if (state.viewingMoveIndex != null) {
      _truncateToViewingIndex();
    }

    if (state.isPaused) {
      state = state.copyWith(isPaused: false);
      if (state.clockStarted) {
        _startClockTicker();
      }
    }

    if (!_isPlayerTurn()) {
      debugPrint('BattlegroundNotifier: Setting pre-move from $from to $to');
      state = state.copyWith(premoveFrom: from, premoveTo: to);
      return;
    }

    final piece = state.game.getPiece(from);
    final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceCode = piece != null
        ? '$colorPrefix${piece.type.toUpperCase()}'
        : 'wP';

    final isPawn = piece?.type.toUpperCase() == 'P';
    final targetRank = to.substring(1);
    final isPromotionRank =
        (piece?.color == chess_lib.Color.WHITE && targetRank == '8') ||
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
    if (piece?.type == chess_lib.PieceType.KING &&
        (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
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
      return;
    }

    final wasClockStarted = state.clockStarted;
    unawaited(_onMoveCompleted('$from$to'));

    if (!wasClockStarted) {
      state = state.copyWith(clockStarted: true);
    }

    state = state.copyWith(activeClockSide: _clockSideForTurn());
    _startClockTicker();

    await ensureGameServicesStarted(analyzeCurrentPosition: true);
    state = state.copyWith(isEngineThinking: state.engineReady);
  }

  void clearPremove() {
    state = state.copyWith(premoveFrom: null, premoveTo: null);
  }

  void _truncateToViewingIndex() {
    if (state.viewingMoveIndex == null) return;
    final index = state.viewingMoveIndex!;
    final movesToKeep = state.recentMoves.sublist(0, index + 1);
    final uciMovesToKeep = state.uciMoves.take(index + 1).toList();

    final is960 = state.gameMode == 'chess960';
    final tempGame = ChessGame(fen: state.game.initialFen, isChess960: is960);

    for (final m in uciMovesToKeep) {
      tempGame.makeMove({
        'from': m.substring(0, 2),
        'to': m.substring(2, 4),
        'promotion': m.length > 4 ? m[4] : 'q',
      });
    }

    state = state.copyWith(
      game: tempGame,
      recentMoves: movesToKeep,
      uciMoves: uciMovesToKeep,
      lastMove: movesToKeep.isEmpty ? null : movesToKeep.last,
      viewingMoveIndex: null,
    );
  }

  Future<void> _onMoveCompleted(String moveLabel) async {
    final updatedMoves = state.game.moveHistoryLabels();
    final updatedUciMoves = [...state.uciMoves, moveLabel];
    final isWhiteTurn = state.game.turn == chess_lib.Color.WHITE;
    final playerJustMoved = isWhiteTurn ? 'Black' : 'White';

    if (state.clockStarted) {
      state = state.copyWith(
        whiteTimeLeft: isWhiteTurn
            ? state.whiteTimeLeft
            : state.whiteTimeLeft + state.incrementDuration,
        blackTimeLeft: isWhiteTurn
            ? state.blackTimeLeft + state.incrementDuration
            : state.blackTimeLeft,
      );
    }

    // Haptics and SFX are disabled in Battleground for snappiness

    final threatened = <String>[];
    final opponentColor = state.game.turn;
    final sideWhoJustMoved = opponentColor == chess_lib.Color.WHITE
        ? chess_lib.Color.BLACK
        : chess_lib.Color.WHITE;

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
      uciMoves: updatedUciMoves,
      isEngineThinking:
          _isAiTurn() && state.servicesStarted && state.engineReady,
      activeClockSide: state.clockStarted
          ? _clockSideForTurn()
          : state.activeClockSide,
      threatenedSquares: threatened,
    );

    if (state.game.gameOver) {
      _stopClockTimer();
    }

    // Apply ELO / Save Rated match outcome
    _applyRatedRatingAdjustments(playerJustMoved);

    if (state.game.gameOver) {
      state = state.copyWith(activeRatedMatchId: null);
      await _saveSettings(); // Must be awaited — guarantees null is on disk before any interruption

      String? result;
      if (state.game.inCheckmate) {
        final winnerIsWhite = playerJustMoved == 'White';
        final humanWon = winnerIsWhite == state.isPlayerWhite;
        result = humanWon ? 'W' : 'L';
      } else if (state.game.inDraw || state.game.inStalemate) {
        result = 'D';
      }
      saveCurrentGame(resultOverride: result);
    } else {
      if (state.activeRatedMatchId == null) {
        state = state.copyWith(
          activeRatedMatchId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        await _saveSettings();
      }
    }

    debugPrint('BattlegroundNotifier: _onMoveCompleted called. Player turn: ${_isPlayerTurn()}, premove: ${state.premoveFrom} -> ${state.premoveTo}');
    // Snappy Premove auto-execution
    if (_isPlayerTurn() &&
        state.premoveFrom != null &&
        state.premoveTo != null) {
      final pFrom = state.premoveFrom!;
      final pTo = state.premoveTo!;
      debugPrint('BattlegroundNotifier: Found pre-move $pFrom -> $pTo. Clearing premove fields. Game FEN: ${state.game.fen}');
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
      debugPrint('BattlegroundNotifier: Legal moves on the board: $movesList');

      debugPrint('BattlegroundNotifier: Pre-move legality: $isLegal');
      if (isLegal) {
        debugPrint('BattlegroundNotifier: Scheduling pre-move execution in 300ms');
        Future.delayed(const Duration(milliseconds: 300), () {
          debugPrint('BattlegroundNotifier: Delayed trigger: playerTurn=${_isPlayerTurn()}, disposed=$_isDisposed');
          if (!_isDisposed && _isPlayerTurn()) {
            debugPrint('BattlegroundNotifier: Executing pre-move $pFrom -> $pTo');
            makeMove(pFrom, pTo);
          }
        });
      }
    }
  }

  void _applyRatedRatingAdjustments(String player) {
    if (state.game.gameOver) {
      double actualScore = 0.5; // Draw
      if (state.game.inCheckmate) {
        final winnerIsWhite = player == 'White';
        final humanWon = winnerIsWhite == state.isPlayerWhite;
        actualScore = humanWon ? 1.0 : 0.0;
      }
      _updateRating(actualScore);
    }
  }

  String _getRatingCategory(Duration total, Duration increment) {
    final totalSeconds = total.inSeconds + (increment.inSeconds * 40);
    if (totalSeconds < 180) return 'bullet';
    if (totalSeconds < 600) return 'blitz';
    return 'rapid';
  }

  Future<void> _checkInactivityAndApplyDecay() async {
    final lastGameMs = state.lastRatedGameTimestampMs;
    if (lastGameMs == null) return; // Never played a rated game, no decay.

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diffMs = nowMs - lastGameMs;
    final double diffDays = diffMs / (1000 * 60 * 60 * 24);

    if (diffDays >= 7) {
      int newRecalGames = state.recalibrationGamesRemaining;
      if (state.totalRatedGamesCount >= 10 && state.recalibrationGamesRemaining == 0) {
        newRecalGames = 5;
      }

      final intervals = (diffDays / 7).floor();
      final newIntervalsToApply = intervals - state.decayIntervalsApplied;

      if (newIntervalsToApply > 0) {
        final decayPenalty = newIntervalsToApply * 10;
        final newConsolidated = math.max(400, state.consolidatedRating - decayPenalty);
        final newBullet = math.max(400, state.bulletElo - decayPenalty);
        final newBlitz = math.max(400, state.blitzElo - decayPenalty);
        final newRapid = math.max(400, state.rapidElo - decayPenalty);

        debugPrint('BattlegroundNotifier: Inactivity detected ($diffDays days). Applying ELO decay of $decayPenalty points.');

        state = state.copyWith(
          consolidatedRating: newConsolidated,
          bulletElo: newBullet,
          blitzElo: newBlitz,
          rapidElo: newRapid,
          recalibrationGamesRemaining: newRecalGames,
          decayIntervalsApplied: intervals,
        );
        await _saveSettings();
      } else {
        if (newRecalGames != state.recalibrationGamesRemaining) {
          state = state.copyWith(
            recalibrationGamesRemaining: newRecalGames,
          );
          await _saveSettings();
        }
      }
    }
  }

  Future<void> _updateRating(double actualScore) async {
    final category = _getRatingCategory(
      state.baseTimeDuration,
      state.incrementDuration,
    );
    final is960 = state.gameMode == 'chess960';
    final opponent =
        state.activeOpponent ?? AiAvatar.getBestMatch(state.consolidatedRating);

    int currentSpecificElo = 400;
    int currentSpecificCount = 0;
    int currentSpecificStreak = 0;

    if (category == 'bullet') {
      currentSpecificElo = state.bulletElo;
      currentSpecificCount = state.bulletGamesClassic + state.bulletGames960;
      currentSpecificStreak = state.bulletStreak;
    } else if (category == 'blitz') {
      currentSpecificElo = state.blitzElo;
      currentSpecificCount = state.blitzGamesClassic + state.blitzGames960;
      currentSpecificStreak = state.blitzStreak;
    } else {
      currentSpecificElo = state.rapidElo;
      currentSpecificCount = state.rapidGamesClassic + state.rapidGames960;
      currentSpecificStreak = state.rapidStreak;
    }

    final isUncalibrated = state.totalRatedGamesCount < 10 || state.recalibrationGamesRemaining > 0;

    final specificKFactor = (currentSpecificCount < 10 || state.recalibrationGamesRemaining > 0) ? 40 : 20;
    final expectedSpecificScore =
        1.0 /
        (1.0 + math.pow(10.0, (opponent.rating - currentSpecificElo) / 400.0));

    int newSpecificStreak = actualScore == 1.0
        ? currentSpecificStreak + 1
        : (actualScore == 0.0 ? 0 : currentSpecificStreak);
    int specificStreakBonus = (actualScore == 1.0 && newSpecificStreak >= 3)
        ? 5
        : 0;

    final newSpecificEloRaw =
        currentSpecificElo +
        (specificKFactor * (actualScore - expectedSpecificScore)).round() +
        specificStreakBonus;
    final newSpecificElo = math.max(400, newSpecificEloRaw);

    final consolidatedKFactor = isUncalibrated ? 40 : 20;
    final expectedConsolidatedScore =
        1.0 /
        (1.0 +
            math.pow(
              10.0,
              (opponent.rating - state.consolidatedRating) / 400.0,
            ));

    int newConsolidatedStreak = actualScore == 1.0
        ? state.totalWinningStreak + 1
        : (actualScore == 0.0 ? 0 : state.totalWinningStreak);
    int consolidatedStreakBonus =
        (actualScore == 1.0 && newConsolidatedStreak >= 3) ? 5 : 0;

    final newConsolidatedEloRaw =
        state.consolidatedRating +
        (consolidatedKFactor * (actualScore - expectedConsolidatedScore))
            .round() +
            consolidatedStreakBonus;
    final newConsolidatedElo = math.max(400, newConsolidatedEloRaw);

    final currentMargin = state.game.calculateMaterialMargin(
      state.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK,
    );

    double newBulletDom = state.bulletDominance;
    double newBlitzDom = state.blitzDominance;
    double newRapidDom = state.rapidDominance;

    if (category == 'bullet') {
      final count = state.bulletGamesClassic + state.bulletGames960;
      newBulletDom =
          ((state.bulletDominance * count) + currentMargin) / (count + 1);
    } else if (category == 'blitz') {
      final count = state.blitzGamesClassic + state.blitzGames960;
      newBlitzDom =
          ((state.blitzDominance * count) + currentMargin) / (count + 1);
    } else {
      final count = state.rapidGamesClassic + state.rapidGames960;
      newRapidDom =
          ((state.rapidDominance * count) + currentMargin) / (count + 1);
    }

    final newTotalCount = state.totalRatedGamesCount + 1;

    state = state.copyWith(
      consolidatedRating: newConsolidatedElo,
      totalRatedGamesCount: newTotalCount,
      totalWinningStreak: newConsolidatedStreak,
      lastRatedGameTimestampMs: DateTime.now().millisecondsSinceEpoch,
      decayIntervalsApplied: 0,
      recalibrationGamesRemaining: math.max(0, state.recalibrationGamesRemaining - 1),
      bulletElo: category == 'bullet' ? newSpecificElo : state.bulletElo,
      bulletStreak: category == 'bullet'
          ? newSpecificStreak
          : state.bulletStreak,
      bulletGamesClassic: (category == 'bullet' && !is960)
          ? state.bulletGamesClassic + 1
          : state.bulletGamesClassic,
      bulletGames960: (category == 'bullet' && is960)
          ? state.bulletGames960 + 1
          : state.bulletGames960,
      bulletDominance: newBulletDom,

      blitzElo: category == 'blitz' ? newSpecificElo : state.blitzElo,
      blitzStreak: category == 'blitz' ? newSpecificStreak : state.blitzStreak,
      blitzGamesClassic: (category == 'blitz' && !is960)
          ? state.blitzGamesClassic + 1
          : state.blitzGamesClassic,
      blitzGames960: (category == 'blitz' && is960)
          ? state.blitzGames960 + 1
          : state.blitzGames960,
      blitzDominance: newBlitzDom,

      rapidElo: category == 'rapid' ? newSpecificElo : state.rapidElo,
      rapidStreak: category == 'rapid' ? newSpecificStreak : state.rapidStreak,
      rapidGamesClassic: (category == 'rapid' && !is960)
          ? state.rapidGamesClassic + 1
          : state.rapidGamesClassic,
      rapidGames960: (category == 'rapid' && is960)
          ? state.rapidGames960 + 1
          : state.rapidGames960,
      rapidDominance: newRapidDom,
    );

    await _saveSettings();
  }

  Future<void> resignRatedGame() async {
    await _updateRating(0.0); // 0.0 = Loss
    await saveCurrentGame(
      customNameOverride: 'Rated Loss (Resigned)',
      resultOverride: 'L',
    );
    state = state.copyWith(activeRatedMatchId: null);
    await _saveSettings();
  }

  void completePromotion(String promotionPiece) {
    if (!state.isPromoting ||
        state.promotionSource == null ||
        state.promotionDestination == null) {
      return;
    }

    final from = state.promotionSource!;
    final to = state.promotionDestination!;

    final piece = state.game.getPiece(from);
    final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceCode = piece != null
        ? '$colorPrefix${piece.type.toUpperCase()}'
        : 'wP';

    state = state.copyWith(
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
    );

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
      unawaited(_onMoveCompleted('$from$to${promotionPiece.toLowerCase()}'));
      if (!wasClockStarted) {
        state = state.copyWith(clockStarted: true);
      }
      state = state.copyWith(activeClockSide: _clockSideForTurn());
      _startClockTicker();
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      state = state.copyWith(isEngineThinking: state.engineReady);
    } else {
      state = state.copyWith(moveAnimation: null);
    }
  }

  void cancelPromotion() {
    if (!state.isPromoting) return;
    state = state.copyWith(
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
    );
    if (state.clockStarted && !state.isPaused) {
      _startClockTicker();
    }
  }

  void clearBoard() {
    _clockTimer?.cancel();
    _engineMoveTimer?.cancel();

    final is960 = state.gameMode == 'chess960';
    final initialGame = is960
        ? ChessGame(
            fen: Chess960Generator.generateRandomPosition().fen,
            isChess960: true,
          )
        : ChessGame(isChess960: false);

    state = state.copyWith(
      game: initialGame,
      lastMove: null,
      recentMoves: const [],
      uciMoves: const [],
      analysis: const {},
      previousEvaluation: 0.0,
      currentEvaluation: 0.0,
      isEngineThinking: false,
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
  }

  void reset({bool forcedPlayerWhite = true, bool startClockImmediate = false}) {
    _clockTimer?.cancel();
    _engineMoveTimer?.cancel();

    final is960 = state.gameMode == 'chess960';
    final initialGame = is960
        ? ChessGame(
            fen: Chess960Generator.generateRandomPosition().fen,
            isChess960: true,
          )
        : ChessGame(isChess960: false);

    // Determine if AI moves first (player is Black means White = AI goes first)
    final aiMovesFirst = !forcedPlayerWhite;

    state = state.copyWith(
      game: initialGame,
      lastMove: null,
      recentMoves: const [],
      uciMoves: const [],
      analysis: const {},
      previousEvaluation: 0.0,
      currentEvaluation: 0.0,
      // Immediately show thinking indicator if AI moves first and starting immediately
      isEngineThinking:
          startClockImmediate && aiMovesFirst && state.servicesStarted && state.engineReady,
      isPlayerWhite: forcedPlayerWhite,
      isBoardFlipped: !forcedPlayerWhite,
      whiteTimeLeft: state.baseTimeDuration,
      blackTimeLeft: state.baseTimeDuration,
      clockStarted: startClockImmediate,
      activeClockSide: startClockImmediate ? _clockWhite : null,
      threatenedSquares: const [],
      moveAnimation: null,
      isPaused: false,
      viewingMoveIndex: null,
      isGameOverDismissed: false,
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
      isTimeOut: false,
      premoveFrom: null,
      premoveTo: null,
      // Clear any stale match ID so a fresh game never inherits a ghost ID
      activeRatedMatchId: null,
    );

    _autoSelectRatedOpponent();

    if (startClockImmediate) {
      _startClockTicker();
      if (aiMovesFirst) {
        unawaited(
          ensureGameServicesStarted(analyzeCurrentPosition: true).then((_) {
            if (!_isDisposed && state.engineReady && _isAiTurn()) {
              state = state.copyWith(isEngineThinking: true);
            }
          }),
        );
      }
    }

    // Sound effects disabled in Battleground
    // _soundService.playSfx(SoundEffect.uiClick);
  }

  void startGame() {
    if (state.game.gameOver || state.isTimeOut) return;

    final aiMovesFirst = !state.isPlayerWhite;

    state = state.copyWith(
      clockStarted: true,
      activeClockSide: _clockWhite,
      isEngineThinking: aiMovesFirst && state.servicesStarted && state.engineReady,
    );

    _startClockTicker();

    if (aiMovesFirst) {
      unawaited(
        ensureGameServicesStarted(analyzeCurrentPosition: true).then((_) {
          if (!_isDisposed && state.engineReady && _isAiTurn()) {
            state = state.copyWith(isEngineThinking: true);
          }
        }),
      );
    }
  }

  void toggleBoardOrientation() {
    state = state.copyWith(isBoardFlipped: !state.isBoardFlipped);
    // Sound effects disabled in Battleground
    // _soundService.playSfx(SoundEffect.uiClick);
  }

  void setGameMode(String mode) {
    if (state.gameMode == mode) return;
    state = state.copyWith(gameMode: mode);
    reset();
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

  void dismissGameOver() {
    state = state.copyWith(isGameOverDismissed: true);
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
          unawaited(_handleClockTimeout(_clockWhite));
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
          unawaited(_handleClockTimeout(_clockBlack));
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
    // Heartbeat haptics disabled in Battleground for snappiness
  }

  Future<void> _handleClockTimeout(String side) async {
    state = state.copyWith(
      clockStarted: false,
      activeClockSide: null,
      isEngineThinking: false,
      isTimeOut: true,
    );

    final timedOutSideIsWhite = side == _clockWhite;
    final humanWon = state.isPlayerWhite != timedOutSideIsWhite;

    // Apply loss/win to ELO
    final score = humanWon ? 1.0 : 0.0;
    await _updateRating(score);

    state = state.copyWith(activeRatedMatchId: null);
    await _saveSettings();

    final result = humanWon ? 'W' : 'L';
    await saveCurrentGame(resultOverride: result);

    // Timeout sound disabled in Battleground
  }

  String _clockSideForTurn() {
    return state.game.turn == chess_lib.Color.WHITE ? _clockWhite : _clockBlack;
  }

  void setViewingMoveIndex(int? index) {
    state = state.copyWith(viewingMoveIndex: index);
  }

  Future<void> _saveSettings() async {
    final s = await _settingsRepository.loadSettings();
    final updated = s.copyWith(
      consolidatedRating: state.consolidatedRating,
      bulletElo: state.bulletElo,
      blitzElo: state.blitzElo,
      rapidElo: state.rapidElo,
      totalRatedGamesCount: state.totalRatedGamesCount,
      bulletGamesClassic: state.bulletGamesClassic,
      bulletGames960: state.bulletGames960,
      blitzGamesClassic: state.blitzGamesClassic,
      blitzGames960: state.blitzGames960,
      rapidGamesClassic: state.rapidGamesClassic,
      rapidGames960: state.rapidGames960,
      totalWinningStreak: state.totalWinningStreak,
      bulletStreak: state.bulletStreak,
      blitzStreak: state.blitzStreak,
      rapidStreak: state.rapidStreak,
      bulletDominance: state.bulletDominance,
      blitzDominance: state.blitzDominance,
      rapidDominance: state.rapidDominance,
      activeRatedMatchId: state.activeRatedMatchId,
      lastRatedGameTimestampMs: state.lastRatedGameTimestampMs,
      recalibrationGamesRemaining: state.recalibrationGamesRemaining,
      decayIntervalsApplied: state.decayIntervalsApplied,
    );
    await _settingsRepository.saveSettings(updated);
  }

  Future<SavedGameEntry?> saveCurrentGame({
    String? customNameOverride,
    String? resultOverride,
  }) async {
    try {
      final moves = List<String>.from(state.recentMoves);
      final isWhite = state.isPlayerWhite;
      final fen = state.game.fen;
      final category = _getRatingCategory(
        state.baseTimeDuration,
        state.incrementDuration,
      );

      final entryId =
          state.activeRatedMatchId ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final entry = SavedGameEntry(
        id: entryId,
        savedAt: DateTime.now(),
        fen: fen,
        recentMoves: moves,
        uciMoves: List<String>.from(state.uciMoves),
        isPlayerWhite: isWhite,
        isBoardFlipped: state.isBoardFlipped,
        whiteTimeLeftMs: state.whiteTimeLeft.inMilliseconds,
        blackTimeLeftMs: state.blackTimeLeft.inMilliseconds,
        clockStarted: false,
        activeClockSide: null,
        customName:
            customNameOverride ?? 'Rated ${category.toUpperCase()} Game',
        isRatedMode: true,
        result: resultOverride,
        ratingCategory: category,
        ratingSnapshot: state.consolidatedRating,
        dominanceSnapshot: state.game.calculateMaterialMargin(
          isWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK,
        ),
        gameMode: state.gameMode,
        initialFen: state.game.initialFen,
      );

      await _savedGameRepository.save(entry);

      // Update global savedGames list so history page sees it!
      await ref.read(chessProvider.notifier).loadSavedGames();

      List<PerformanceLedgerEntry> updatedLedger = state.cachedLedgerEntries;
      if (entry.result != null) {
        final opponent =
            state.activeOpponent ??
            AiAvatar.getBestMatch(state.consolidatedRating);
        final ledgerEntry = PerformanceLedgerEntry(
          id: entry.id,
          timestamp: entry.savedAt,
          source: PerformanceLedgerEntry.ratedBattlegroundSource,
          ratingCategory: entry.ratingCategory ?? category,
          gameMode: entry.gameMode,
          result: entry.result!,
          dominance: entry.dominanceSnapshot ?? 0.0,
          opponentName: opponent.name,
          ratingSnapshot: entry.ratingSnapshot ?? 1200,
          fen: entry.fen,
          recentMoves: List<String>.from(entry.recentMoves),
          uciMoves: List<String>.from(entry.uciMoves),
          initialFen: entry.initialFen,
          isPlayerWhite: entry.isPlayerWhite,
          whiteTimeLeftMs: entry.whiteTimeLeftMs,
          blackTimeLeftMs: entry.blackTimeLeftMs,
        );
        updatedLedger = await _performanceLedgerRepository.addEntry(
          ledgerEntry,
        );
      }

      state = state.copyWith(
        cachedLedgerEntries: updatedLedger,
        activeRatedMatchId: entry.result != null
            ? null
            : state.activeRatedMatchId,
      );

      if (entry.result != null) {
        await _saveSettings();
      }

      _refreshDashboardStats();
      debugPrint('Rated game saved successfully: ${entry.id}');
      return entry;
    } catch (e) {
      debugPrint('Failed to save rated game: $e');
      return null;
    }
  }

  void refreshDashboardStats() {
    _refreshDashboardStats();
  }

  void _refreshDashboardStats() {
    final ratedSaves = selectScotomaLedgerEntries(state.cachedLedgerEntries);
    if (ratedSaves.isEmpty) return;

    // 1. Analyze Scotoma via Rust FFI
    ScotomaResult? scotoma;
    final uciGames = ratedSaves.map((s) {
      return SavedGameUci(
        recentMoves: s.recentMoves,
        uciMoves: s.uciMoves,
        initialFen: s.initialFen,
        finalFen: s.fen,
        isChess960: s.gameMode == 'chess960',
        isPlayerWhite: s.isPlayerWhite,
        result: s.result,
        whiteTimeLeftMs: s.whiteTimeLeftMs,
        blackTimeLeftMs: s.blackTimeLeftMs,
        ratingCategory: s.ratingCategory,
      );
    }).toList();
    try {
      scotoma = analyzeScotoma(games: uciGames);
    } catch (e) {
      debugPrint('Failed to run Rust analyzeScotoma in Battleground: $e');
    }

    // 2. Playstyle calculations
    TacticalPlaystyleStats? playstyle;
    final avgDom =
        ratedSaves.map((s) => s.dominance).reduce((a, b) => a + b) /
        ratedSaves.length;
    final aggression = math.min(1.0, math.max(0.0, (avgDom + 5) / 10));

    final maxElo = ratedSaves.map((s) => s.ratingSnapshot).reduce(math.max);
    final power = math.min(1.0, (maxElo - 400) / 2000);

    final count960 = ratedSaves.where((s) => s.gameMode == 'chess960').length;
    final versatility = count960 / ratedSaves.length;

    final wins = ratedSaves.where((s) => s.result == 'W').length;
    final intensity = wins / ratedSaves.length;

    double speedSum = 0.0;
    int speedCount = 0;
    for (final s in ratedSaves) {
      final double baseTimeMs = s.ratingCategory == 'bullet'
          ? 120000.0
          : s.ratingCategory == 'blitz'
          ? 300000.0
          : 600000.0;
      final playerTimeLeftMs = s.isPlayerWhite
          ? s.whiteTimeLeftMs
          : s.blackTimeLeftMs;
      final ratio = playerTimeLeftMs / baseTimeMs;
      speedSum += math.min(1.0, math.max(0.0, ratio));
      speedCount++;
    }
    final speed = speedCount > 0 ? (speedSum / speedCount) : 0.7;

    playstyle = TacticalPlaystyleStats(
      aggression: aggression,
      power: power,
      versatility: versatility,
      intensity: intensity,
      speed: speed,
    );

    // 3. Opening Repertoire calculations
    final List<OpeningRepertoireStats> openings = [];
    final Map<String, _OpeningRepertoireStatsBuilder> statsMap = {};
    for (final s in ratedSaves) {
      final op = OpeningClassifier.detectOpening(
        s.recentMoves,
        gameMode: s.gameMode,
      );
      if (!statsMap.containsKey(op)) {
        statsMap[op] = _OpeningRepertoireStatsBuilder(name: op);
      }
      statsMap[op]!.addPlay(s.result);
    }

    final sortedStats = statsMap.values.toList()
      ..sort((a, b) => b.plays.compareTo(a.plays));
    final totalPlays = ratedSaves.length;

    for (final s in sortedStats) {
      final double playPercentage = (s.plays / totalPlays) * 100;
      final double winRate = (s.wins + 0.5 * s.draws) / s.plays * 100;
      openings.add(
        OpeningRepertoireStats(
          name: s.name,
          plays: s.plays,
          wins: s.wins,
          draws: s.draws,
          losses: s.losses,
          playPercentage: playPercentage,
          winRate: winRate,
        ),
      );
    }

    // 4. Endgame calculations
    EndgamePerformanceStats? endgames;
    final endgameSaves = ratedSaves
        .where((s) => FenParser.isEndgame(s.fen))
        .toList();
    if (endgameSaves.isNotEmpty) {
      double totalWeightedScore = 0.0;
      double totalWeight = 0.0;

      int advantageGames = 0;
      int advantageWins = 0;

      int disadvantageGames = 0;
      int disadvantageSaves = 0;

      for (final s in endgameSaves) {
        final score = s.result == 'W' ? 1.0 : (s.result == 'D' ? 0.5 : 0.0);
        final balance = FenParser.calculateMaterialBalance(
          s.fen,
          s.isPlayerWhite,
        );

        double complexity = 1.0;
        if (balance > 0) {
          complexity = 2.0;
          advantageGames++;
          if (s.result == 'W') advantageWins++;
        } else if (balance < 0) {
          complexity = 1.5;
          disadvantageGames++;
          if (s.result == 'W' || s.result == 'D') disadvantageSaves++;
        } else {
          complexity = 1.0;
        }

        totalWeightedScore += (score * complexity);
        totalWeight += complexity;
      }

      final double epi = totalWeight > 0
          ? (totalWeightedScore / totalWeight) * 100
          : 0.0;
      final double conversionRate = advantageGames > 0
          ? (advantageWins / advantageGames) * 100
          : 0.0;
      final double saveRate = disadvantageGames > 0
          ? (disadvantageSaves / disadvantageGames) * 100
          : 0.0;

      String ratingCategory = 'Provisional';
      if (endgameSaves.length >= 15) {
        if (epi >= 85) {
          ratingCategory = 'Endgame Grandmaster';
        } else if (epi >= 70) {
          ratingCategory = 'Endgame Specialist';
        } else if (epi >= 50) {
          ratingCategory = 'Tactician Class I';
        } else {
          ratingCategory = 'Endgame Scholar';
        }
      } else {
        if (epi >= 75) {
          ratingCategory = 'Technician (Provisional)';
        } else {
          ratingCategory = 'Apprentice (Provisional)';
        }
      }

      endgames = EndgamePerformanceStats(
        epi: epi,
        conversionRate: conversionRate,
        saveRate: saveRate,
        ratingCategory: ratingCategory,
        advantageGames: advantageGames,
        advantageWins: advantageWins,
        disadvantageGames: disadvantageGames,
        disadvantageSaves: disadvantageSaves,
        endgameSavesCount: endgameSaves.length,
      );
    }

    // 5. Heatmap daily dominance metrics
    final List<double> dominanceHeatmap = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final Map<String, List<double>> dailyDom = {};
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dailyDom[dateKey] = [];
    }

    for (final s in ratedSaves) {
      if (s.timestamp.isAfter(thirtyDaysAgo)) {
        final dateKey =
            '${s.timestamp.year}-${s.timestamp.month}-${s.timestamp.day}';
        if (dailyDom.containsKey(dateKey)) {
          dailyDom[dateKey]!.add(s.dominance);
        }
      }
    }

    final List<String> sortedKeys = dailyDom.keys.toList();
    for (final key in sortedKeys) {
      final doms = dailyDom[key]!;
      final avg = doms.isEmpty
          ? 0.0
          : doms.reduce((a, b) => a + b) / doms.length;
      dominanceHeatmap.add(doms.isEmpty ? double.nan : avg);
    }

    // 4.5. Middlegame calculations
    MiddlegamePerformanceStats? middlegames;
    if (scotoma != null) {
      try {
        final rawMid = analyzeMiddlegame(games: uciGames, scotoma: scotoma);

        // Determine archetype and description dynamically in Dart based on playstyle metrics
        String archetype = 'Positional';
        String description = 'You prefer slow, strategic maneuvers, improving piece placement, and grinding down your opponent.';

        if (playstyle.aggression >= 0.65) {
          archetype = 'Attacker';
          description = 'You launch direct attacks, look for pawn storms, and push pieces forward to target the opponent king.';
        } else if (playstyle.intensity >= 0.65) {
          archetype = 'Tactician';
          description = 'You thrive in chaotic, double-edged middlegames where quick calculation and sharp shots dominate.';
        } else if (playstyle.aggression <= 0.42) {
          archetype = 'Defender';
          description = 'You prioritize absolute safety, build solid defensive walls, and wait for your opponent to overreach.';
        }

        middlegames = MiddlegamePerformanceStats(
          mpi: rawMid.mpi,
          archetype: archetype,
          description: description,
          decidedPercentage: rawMid.decidedPercentage,
          winRate: rawMid.winRate,
          totalMiddlegames: rawMid.totalMiddlegames,
        );
      } catch (e) {
        debugPrint('Failed to run Rust analyzeMiddlegame in Battleground: $e');
      }
    }

    state = state.copyWith(
      cachedScotoma: scotoma,
      cachedPlaystyle: playstyle,
      cachedOpenings: openings,
      cachedMiddlegames: middlegames,
      cachedEndgames: endgames,
      cachedDominanceHeatmap: dominanceHeatmap,
    );
  }

  Future<void> resetRatedStats() async {
    try {
      await _performanceLedgerRepository.clearAll();
      state = state.copyWith(
        consolidatedRating: 400,
        bulletElo: 400,
        blitzElo: 400,
        rapidElo: 400,
        totalRatedGamesCount: 0,
        bulletGamesClassic: 0,
        bulletGames960: 0,
        blitzGamesClassic: 0,
        blitzGames960: 0,
        rapidGamesClassic: 0,
        rapidGames960: 0,
        totalWinningStreak: 0,
        bulletStreak: 0,
        blitzStreak: 0,
        rapidStreak: 0,
        bulletDominance: 0.0,
        blitzDominance: 0.0,
        rapidDominance: 0.0,
        cachedLedgerEntries: const [],
        cachedScotoma: null,
        cachedPlaystyle: const TacticalPlaystyleStats.empty(),
        cachedOpenings: const [],
        cachedMiddlegames: null,
        cachedEndgames: null,
        cachedDominanceHeatmap: const [],
      );
      await _saveSettings();
    } catch (e) {
      debugPrint('Failed to reset rated stats: $e');
    }
  }

  void clearMoveAnimation() {
    state = state.copyWith(moveAnimation: null);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clockTimer?.cancel();
    _engineMoveTimer?.cancel();
    _stockfishSubscription?.cancel();
    super.dispose();
  }
}

class _OpeningRepertoireStatsBuilder {
  final String name;
  int plays = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;

  _OpeningRepertoireStatsBuilder({required this.name});

  void addPlay(String? result) {
    plays++;
    if (result == 'W') {
      wins++;
    } else if (result == 'D') {
      draws++;
    } else {
      losses++;
    }
  }
}

final battlegroundProvider =
    StateNotifierProvider<BattlegroundNotifier, BattlegroundState>((ref) {
      final stockfishEngine = ref.watch(stockfishServiceProvider);
      final savedGameRepository = ref.watch(savedGameRepositoryProvider);
      final performanceLedgerRepository = ref.watch(
        performanceLedgerRepositoryProvider,
      );
      final soundService = ref.watch(chessSoundServiceProvider);
      final hapticsService = ref.watch(chessHapticsServiceProvider);
      final settingsRepository = ref.watch(settingsRepositoryProvider);
      return BattlegroundNotifier(
        ref,
        stockfishEngine,
        savedGameRepository,
        performanceLedgerRepository,
        soundService,
        hapticsService,
        settingsRepository,
      );
    });
