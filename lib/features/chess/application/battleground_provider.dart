import 'dart:math' as math;
import 'dart:async';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chess_game.dart';
import '../domain/models/ai_avatar.dart';
import '../domain/models/candidate_move.dart';
import '../domain/chess_persona_evaluator.dart';
import '../services/chess_sound_service.dart';
import '../services/chess_haptics_service.dart';
import '../data/arasan_service.dart';
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
import 'package:kingslayer_chess/src/rust/api/persona.dart' as rust_persona;
import 'performance_ledger_manager.dart';
import 'chess_provider.dart';
import 'store_provider.dart';
import '../services/cloud_sync_service.dart';

const _initialClock = Duration(minutes: 10);
const _clockWhite = 'white';
const _clockBlack = 'black';



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
  final bool isResigned;
  final bool servicesStarted;
  final bool servicesStarting;
  final bool engineReady;
  final String? startupError;
  final String? premoveFrom;
  final String? premoveTo;
  final int drawOffersCount;
  final bool isDrawAgreed;

  // Rated ELO fields
  final int consolidatedRating;
  final int bulletElo;
  final int blitzElo;
  final int rapidElo;
  final int totalRatedGamesCount;
  final int bulletGamesClassic;
  final int blitzGamesClassic;
  final int rapidGamesClassic;
  final int totalWinningStreak;
  final int bulletStreak;
  final int blitzStreak;
  final int rapidStreak;
  final double bulletDominance;
  final double blitzDominance;
  final double rapidDominance;
  final String? activeRatedMatchId;
  final String? activeRatedMatchRatingCategory;

  final int recalibrationGamesRemaining;
  final int? lastRatedGameTimestampMs;
  final int decayIntervalsApplied;
  final int decayIntervalsAppliedAtLastGame;
  final bool hasLoadedSettings;

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
    this.isResigned = false,
    this.servicesStarted = false,
    this.servicesStarting = false,
    this.engineReady = false,
    this.startupError,
    this.premoveFrom,
    this.premoveTo,
    this.drawOffersCount = 0,
    this.isDrawAgreed = false,

    // Rated
    this.consolidatedRating = 400,
    this.bulletElo = 400,
    this.blitzElo = 400,
    this.rapidElo = 400,
    this.totalRatedGamesCount = 0,
    this.bulletGamesClassic = 0,
    this.blitzGamesClassic = 0,
    this.rapidGamesClassic = 0,
    this.totalWinningStreak = 0,
    this.bulletStreak = 0,
    this.blitzStreak = 0,
    this.rapidStreak = 0,
    this.bulletDominance = 0.0,
    this.blitzDominance = 0.0,
    this.rapidDominance = 0.0,
    this.activeRatedMatchId,
    this.activeRatedMatchRatingCategory,

    // Rated inactivity & recalibration
    this.recalibrationGamesRemaining = 0,
    this.lastRatedGameTimestampMs,
    this.decayIntervalsApplied = 0,
    this.decayIntervalsAppliedAtLastGame = 0,
    this.hasLoadedSettings = false,

    // Cached metrics
    this.cachedScotoma,
    this.cachedPlaystyle,
    this.cachedOpenings = const [],
    this.cachedMiddlegames,
    this.cachedEndgames,
    this.cachedDominanceHeatmap = const [],
    this.cachedLedgerEntries = const [],
  });

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
    bool? isResigned,
    bool? servicesStarted,
    bool? servicesStarting,
    bool? engineReady,
    Object? startupError = const Object(),
    Object? premoveFrom = const Object(),
    Object? premoveTo = const Object(),
    int? drawOffersCount,
    bool? isDrawAgreed,

    // Rated
    int? consolidatedRating,
    int? bulletElo,
    int? blitzElo,
    int? rapidElo,
    int? totalRatedGamesCount,
    int? bulletGamesClassic,
    int? blitzGamesClassic,
    int? rapidGamesClassic,
    int? totalWinningStreak,
    int? bulletStreak,
    int? blitzStreak,
    int? rapidStreak,
    double? bulletDominance,
    double? blitzDominance,
    double? rapidDominance,
    Object? activeRatedMatchId = const Object(),
    Object? activeRatedMatchRatingCategory = const Object(),

    int? recalibrationGamesRemaining,
    int? lastRatedGameTimestampMs,
    int? decayIntervalsApplied,
    int? decayIntervalsAppliedAtLastGame,
    bool? hasLoadedSettings,

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
      isResigned: isResigned ?? this.isResigned,
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
      drawOffersCount: drawOffersCount ?? this.drawOffersCount,
      isDrawAgreed: isDrawAgreed ?? this.isDrawAgreed,

      // Rated
      consolidatedRating: consolidatedRating ?? this.consolidatedRating,
      bulletElo: bulletElo ?? this.bulletElo,
      blitzElo: blitzElo ?? this.blitzElo,
      rapidElo: rapidElo ?? this.rapidElo,
      totalRatedGamesCount: totalRatedGamesCount ?? this.totalRatedGamesCount,
      bulletGamesClassic: bulletGamesClassic ?? this.bulletGamesClassic,
      blitzGamesClassic: blitzGamesClassic ?? this.blitzGamesClassic,
      rapidGamesClassic: rapidGamesClassic ?? this.rapidGamesClassic,
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
      activeRatedMatchRatingCategory: activeRatedMatchRatingCategory == const Object()
          ? this.activeRatedMatchRatingCategory
          : activeRatedMatchRatingCategory as String?,

      recalibrationGamesRemaining: recalibrationGamesRemaining ?? this.recalibrationGamesRemaining,
      lastRatedGameTimestampMs: lastRatedGameTimestampMs ?? this.lastRatedGameTimestampMs,
      decayIntervalsApplied: decayIntervalsApplied ?? this.decayIntervalsApplied,
      decayIntervalsAppliedAtLastGame: decayIntervalsAppliedAtLastGame ?? this.decayIntervalsAppliedAtLastGame,
      hasLoadedSettings: hasLoadedSettings ?? this.hasLoadedSettings,

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

class BattlegroundNotifier extends Notifier<BattlegroundState> {
  late final ArasanService _arasanEngine;
  late final SavedGameRepository _savedGameRepository;
  // ignore: unused_field
  late final ChessSoundService _soundService;
  // ignore: unused_field
  late final ChessHapticsService _hapticsService;
  late final SettingsRepository _settingsRepository;

  Timer? _clockTimer;
  Timer? _engineMoveTimer;
  StreamSubscription<String>? _arasanSubscription;

  Future<void>? _startupFuture;
  bool _isDisposed = false;
  DateTime _lastInfoUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _searchFen;
  final List<CandidateMove> _currentCandidates = [];
  bool _waitingForReady = false;
  final List<double> _dominanceSamples = [];

  @override
  BattlegroundState build() {
    _arasanEngine = ref.watch(arasanServiceProvider);
    _savedGameRepository = ref.watch(savedGameRepositoryProvider);
    _soundService = ref.watch(chessSoundServiceProvider);
    _hapticsService = ref.watch(chessHapticsServiceProvider);
    _settingsRepository = ref.watch(settingsRepositoryProvider);

    // Sync sound service settings immediately when entering Battleground mode
    final initialSettings = ref.read(chessProvider);
    _soundService.updateSettings(
      sfxEnabled: initialSettings.isSoundEnabled,
      bgmEnabled: initialSettings.isMusicEnabled,
      gameSoundEnabled: initialSettings.isGameSoundEnabled,
      soundSettings: initialSettings.soundSettings,
      academySoundEnabled: initialSettings.isAcademySoundEnabled,
      academySoundSettings: initialSettings.academySoundSettings,
      isAcademyActive: false,
      isRatedMode: true,
      isBattlegroundSoundEnabled: initialSettings.isBattlegroundSoundEnabled,
    );

    ref.listen<ChessState>(chessProvider, (previous, next) {
      // Sync sound settings when settings change
      _soundService.updateSettings(
        sfxEnabled: next.isSoundEnabled,
        bgmEnabled: next.isMusicEnabled,
        gameSoundEnabled: next.isGameSoundEnabled,
        soundSettings: next.soundSettings,
        academySoundEnabled: next.isAcademySoundEnabled,
        academySoundSettings: next.academySoundSettings,
        isAcademyActive: false,
        isRatedMode: true,
        isBattlegroundSoundEnabled: next.isBattlegroundSoundEnabled,
      );
    });

    ref.listen<PerformanceLedgerManagerState>(performanceLedgerManagerProvider, (previous, next) {
      if (next.isInitialized) {
        final dominanceHeatmap = _recalculateHeatmap(next.entries);
        state = state.copyWith(
          cachedLedgerEntries: next.entries,
          cachedScotoma: next.cache.scotomaResult,
          cachedPlaystyle: next.cache.playstyleStats,
          cachedOpenings: next.cache.openingsStats,
          cachedMiddlegames: next.cache.middlegameStats,
          cachedEndgames: next.cache.endgameStats,
          cachedDominanceHeatmap: dominanceHeatmap,
        );
      }
    });

    ref.onDispose(() {
      _isDisposed = true;
      _clockTimer?.cancel();
      _engineMoveTimer?.cancel();
      _arasanSubscription?.cancel();
    });

    _loadInitialStateAndLedger();

    return BattlegroundState(game: ChessGame());
  }

  Future<void> _loadInitialStateAndLedger() async {
    final settings = ref.read(chessProvider);
    final s = await _settingsRepository.loadSettings();

    state = state.copyWith(
      isBoardFlipped: settings.isBoardFlipped,
      isPlayerWhite: settings.isPlayerWhite,
      gameMode: 'classic',

      // Load Elo ratings, streaks, and counts
      consolidatedRating: s.consolidatedRating,
      bulletElo: s.bulletElo,
      blitzElo: s.blitzElo,
      rapidElo: s.rapidElo,
      totalRatedGamesCount: s.totalRatedGamesCount,
      bulletGamesClassic: s.bulletGamesClassic,
      blitzGamesClassic: s.blitzGamesClassic,
      rapidGamesClassic: s.rapidGamesClassic,
      totalWinningStreak: s.totalWinningStreak,
      bulletStreak: s.bulletStreak,
      blitzStreak: s.blitzStreak,
      rapidStreak: s.rapidStreak,
      bulletDominance: s.bulletDominance,
      blitzDominance: s.blitzDominance,
      rapidDominance: s.rapidDominance,
      activeRatedMatchId: s.activeRatedMatchId,
      activeRatedMatchRatingCategory: s.activeRatedMatchRatingCategory,
      recalibrationGamesRemaining: s.recalibrationGamesRemaining,
      lastRatedGameTimestampMs: s.lastRatedGameTimestampMs,
      decayIntervalsApplied: s.decayIntervalsApplied,
      decayIntervalsAppliedAtLastGame: s.decayIntervalsAppliedAtLastGame,
    );

    // Apply inactivity check and ELO decay before loading history
    await _checkInactivityAndApplyDecay();

    // Load ledger entries and cached stats from manager
    final managerState = ref.read(performanceLedgerManagerProvider);
    final dominanceHeatmap = _recalculateHeatmap(managerState.entries);
    state = state.copyWith(
      cachedLedgerEntries: managerState.entries,
      cachedScotoma: managerState.cache.scotomaResult,
      cachedPlaystyle: managerState.cache.playstyleStats,
      cachedOpenings: managerState.cache.openingsStats,
      cachedMiddlegames: managerState.cache.middlegameStats,
      cachedEndgames: managerState.cache.endgameStats,
      cachedDominanceHeatmap: dominanceHeatmap,
    );

    // Auto select rated opponent
    _autoSelectRatedOpponent();

    // Check for active rated match ID found on boot (unfair exit loss registration)
    if (s.activeRatedMatchId != null) {
      final matchId = s.activeRatedMatchId!;
      final opponent = s.activeRatedMatchOpponentId != null
          ? AiAvatar.getAvatar(s.activeRatedMatchOpponentId!)
          : AiAvatar.getBestMatch(s.consolidatedRating);

      debugPrint(
        'BattlegroundNotifier: Active rated match ID found on boot: $matchId with opponent ${opponent.name}. Registering unfair exit loss.',
      );

      // Clear the activeRatedMatchId immediately from state and disk first.
      // This guarantees that any subsequent async step or developer hot restart
      // will not see the stale match ID again, preventing a phantom exit loop.
      final category = s.activeRatedMatchRatingCategory ?? 'rapid';
      state = state.copyWith(
        activeRatedMatchId: null,
        activeRatedMatchRatingCategory: null,
      );
      await _saveSettings();

      await _updateRating(
        0.0,
        opponentOverride: opponent,
        skipGameCountUpdate: true,
        categoryOverride: category,
      );

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
        ratingCategory: category,
      );
      await _savedGameRepository.save(entry);

      // Sync boot-up forfeit to performance ledger
      final ledgerEntry = PerformanceLedgerEntry(
        id: entry.id,
        timestamp: entry.savedAt,
        source: PerformanceLedgerEntry.ratedBattlegroundSource,
        ratingCategory: category,
        gameMode: 'classic',
        result: 'L',
        dominance: 0.0,
        opponentName: opponent.name,
        ratingSnapshot: state.consolidatedRating,
        fen: entry.fen,
        recentMoves: const [],
        uciMoves: const [],
        initialFen: chess_lib.Chess.DEFAULT_POSITION,
        isPlayerWhite: true,
        whiteTimeLeftMs: 0,
        blackTimeLeftMs: 0,
        reachedEndgame: false,
        baseTimeMs: state.baseTimeDuration.inMilliseconds,
      );
      await ref.read(performanceLedgerManagerProvider.notifier).addEntry(ledgerEntry);
    }

    state = state.copyWith(hasLoadedSettings: true);
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
    if (state.servicesStarted && _arasanEngine.isReady) {
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

  rust_persona.PersonaConfig _getPersonaConfigSafely(String avatarName) {
    try {
      return rust_persona.getPersonaConfig(avatarName: avatarName);
    } catch (e) {
      debugPrint('BattlegroundNotifier: getPersonaConfig error: $e. Using fallback config.');
      return const rust_persona.PersonaConfig(
        multiPv: 1,
        skillLevel: 20,
        depth: 15,
      );
    }
  }

  Future<void> _startServices({
    required int? depth,
    required bool analyzeCurrentPosition,
  }) async {
    try {
      _arasanSubscription ??= _arasanEngine.outputStream.listen(
        _handleEngineOutput,
      );
      await _arasanEngine.init();

      await _arasanEngine.setChess960Mode(false); // Battleground always classic

      final opponent =
          state.activeOpponent ??
          AiAvatar.getBestMatch(state.consolidatedRating);
      final config = _getPersonaConfigSafely(opponent.name);
      await _arasanEngine.setSkillLevel(
        config.skillLevel,
        multiPV: config.multiPv,
      );
      _arasanEngine.sendCommand(
        'setoption name MultiPV value ${config.multiPv}',
      );
      _arasanEngine.sendCommand(
        'setoption name Hash value ${opponent.hashSize}',
      );
      _arasanEngine.sendCommand(
        'setoption name Contempt value ${opponent.contempt}',
      );

      state = state.copyWith(
        servicesStarted: true,
        servicesStarting: false,
        engineReady: _arasanEngine.isReady,
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
        _waitingForReady ||
        state.game.gameOver ||
        state.isPaused) {
      return;
    }

    _currentCandidates.clear();
    await _arasanEngine.setChess960Mode(false); // Battleground always classic

    final opponent =
        state.activeOpponent ?? AiAvatar.getBestMatch(state.consolidatedRating);
    final config = _getPersonaConfigSafely(opponent.name);
    await _arasanEngine.setSkillLevel(
      config.skillLevel,
      multiPV: config.multiPv,
    );
    _arasanEngine.sendCommand(
      'setoption name MultiPV value ${config.multiPv}',
    );
    _arasanEngine.sendCommand(
      'setoption name Hash value ${opponent.hashSize}',
    );
    _arasanEngine.sendCommand(
      'setoption name Contempt value ${opponent.contempt}',
    );

    _searchFen = state.game.fen;
    final targetDepth = depth ?? config.depth;
    if (!state.game.gameOver) {
      _arasanEngine.analyzePosition(
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
          debugPrint('BattlegroundNotifier: Safety timer fired after ${safetyTimeoutMs}ms. Forcing bestmove.');
          _arasanEngine.stopAnalysis();
        }
      });
    } else {
      _arasanEngine.analyzePosition(state.game.fen, depth: targetDepth);
    }
  }

  void _stopAnalysisAndReset() {
    if (!state.servicesStarted || !state.engineReady) return;
    _waitingForReady = true;
    _arasanEngine.sendCommand('stop');
    _arasanEngine.sendCommand('isready');
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
        _currentCandidates.sort((a, b) => a.multipvIndex.compareTo(b.multipvIndex));
      }
    }

    if (parsed.containsKey('bestMove')) {
      final rawBestMove = parsed['bestMove'] as String?;
      final aiTurn = _isAiTurn();

      String? bestMoveToPlay = rawBestMove;

      if (rawBestMove != null && _currentCandidates.isNotEmpty) {
        final opponent =
            state.activeOpponent ??
            AiAvatar.getBestMatch(state.consolidatedRating);
        if (opponent.name != 'King' && opponent.name != 'Kingslayer') {
          bestMoveToPlay = ChessPersonaEvaluator.selectBestMove(
            List.from(_currentCandidates),
            opponent,
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
          aiTurn &&
          isMoveValidForCurrentTurn &&
          !state.game.gameOver &&
          !state.isPaused) {
        _engineMoveTimer?.cancel();
        final finalMove = bestMoveToPlay;
        // In rated mode we make moves instantly
        unawaited(_makeEngineMove(finalMove));
      }

      _currentCandidates.clear();
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
  }

  Future<void> _makeEngineMove(String move) async {
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
      await _onMoveCompleted('$from$to$actualPromo');
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

    // Record theme usage day
    ref.read(storeProvider.notifier).recordThemeDay(ref.read(chessProvider).boardThemeId);

    if (!_isPlayerTurn()) {
      debugPrint('BattlegroundNotifier: Setting pre-move from $from to $to');
      state = state.copyWith(premoveFrom: from, premoveTo: to);
      return;
    }

    _stopAnalysisAndReset();
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;

    if (state.viewingMoveIndex != null) {
      _truncateToViewingIndex();
    }

    if (state.isPaused) {
      state = state.copyWith(isPaused: false);
      if (state.clockStarted) {
        _startClockTicker();
      }
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
      _soundService.playBattlegroundSfx(SoundEffect.promote);
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
    await _onMoveCompleted('$from$to');

    if (state.game.gameOver || state.isTimeOut) {
      state = state.copyWith(
        clockStarted: false,
        activeClockSide: null,
        isEngineThinking: false,
      );
      _stopClockTimer();
      _engineMoveTimer?.cancel();
      _engineMoveTimer = null;
      _stopAnalysisAndReset();
      return;
    }

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

    final tempGame = ChessGame(fen: state.game.initialFen, isChess960: false);

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

    final move = state.game.history.isEmpty ? null : state.game.history.last;

    // Haptics enabled in Battleground when globally enabled, SFX enabled if configured
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

    // Play Battleground SFX
    bool isCastle = false;
    if (move != null) {
      final piece = move.move.piece;
      final type = piece.toString().toLowerCase();
      if (type == 'k') {
        final fromFile = move.move.from % 8;
        final toFile = move.move.to % 8;
        if ((fromFile - toFile).abs() == 2) {
          isCastle = true;
        }
      }
    }

    if (state.game.gameOver) {
      final isDraw = state.game.inDraw || state.game.inStalemate;
      if (isDraw) {
        _soundService.playBattlegroundSfx(SoundEffect.draw);
      } else {
        final winnerIsWhite = playerJustMoved == 'White';
        final humanWon = winnerIsWhite == state.isPlayerWhite;
        _soundService.playBattlegroundSfx(humanWon ? SoundEffect.victory : SoundEffect.defeat);
      }
    } else if (state.game.inCheck) {
      _soundService.playBattlegroundSfx(SoundEffect.check);
    } else if (isCastle) {
      _soundService.playBattlegroundSfx(SoundEffect.castle);
    } else {
      _soundService.playBattlegroundSfx(move?.move.captured != null ? SoundEffect.capture : SoundEffect.move);
    }

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

    if (updatedUciMoves.length % 2 == 0) {
      final currentMargin = state.game.calculateMaterialMargin(
        state.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK,
      );
      _dominanceSamples.add(currentMargin);
    }

    if (state.game.gameOver) {
      _stopClockTimer();
    }

    // Apply ELO / Save Rated match outcome
    await _applyRatedRatingAdjustments(playerJustMoved);

    if (state.game.gameOver) {
      state = state.copyWith(
        activeRatedMatchId: null,
        activeRatedMatchRatingCategory: null,
      );
      await _saveSettings(); // Must be awaited — guarantees null is on disk before any interruption

      String? result;
      if (state.game.inCheckmate) {
        final winnerIsWhite = playerJustMoved == 'White';
        final humanWon = winnerIsWhite == state.isPlayerWhite;
        result = humanWon ? 'W' : 'L';
      } else if (state.game.inDraw || state.game.inStalemate) {
        result = 'D';
      }
      await saveCurrentGame(resultOverride: result);
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

  Future<void> _applyRatedRatingAdjustments(String player) async {
    if (state.game.gameOver) {
      double actualScore = 0.5; // Draw
      if (state.game.inCheckmate) {
        final winnerIsWhite = player == 'White';
        final humanWon = winnerIsWhite == state.isPlayerWhite;
        actualScore = humanWon ? 1.0 : 0.0;
      }
      await _updateRating(actualScore, dominanceOverride: _getAverageDominance());
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
      final currentPeriodApplied = state.decayIntervalsApplied - state.decayIntervalsAppliedAtLastGame;
      final newIntervalsToApply = intervals - currentPeriodApplied;

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
          decayIntervalsApplied: state.decayIntervalsApplied + newIntervalsToApply,
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

  double _getAverageDominance() {
    if (_dominanceSamples.isEmpty) {
      return state.game.calculateMaterialMargin(
        state.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK,
      );
    }
    final sum = _dominanceSamples.reduce((a, b) => a + b);
    return sum / _dominanceSamples.length;
  }

  Future<void> _updateRating(
    double actualScore, {
    AiAvatar? opponentOverride,
    double? dominanceOverride,
    bool skipGameCountUpdate = false,
    String? categoryOverride,
  }) async {
    final category = categoryOverride ?? _getRatingCategory(
      state.baseTimeDuration,
      state.incrementDuration,
    );
    final opponent = opponentOverride ??
        state.activeOpponent ?? AiAvatar.getBestMatch(state.consolidatedRating);

    int currentSpecificElo = 400;
    int currentSpecificCount = 0;
    int currentSpecificStreak = 0;

    if (category == 'bullet') {
      currentSpecificElo = state.bulletElo;
      currentSpecificCount = state.bulletGamesClassic;
      currentSpecificStreak = state.bulletStreak;
    } else if (category == 'blitz') {
      currentSpecificElo = state.blitzElo;
      currentSpecificCount = state.blitzGamesClassic;
      currentSpecificStreak = state.blitzStreak;
    } else {
      currentSpecificElo = state.rapidElo;
      currentSpecificCount = state.rapidGamesClassic;
      currentSpecificStreak = state.rapidStreak;
    }

    final isUncalibrated = state.totalRatedGamesCount < 10 || state.recalibrationGamesRemaining > 0;

    final specificKFactor = (currentSpecificCount < 10 || state.recalibrationGamesRemaining > 0) ? 40 : 20;
    final expectedSpecificScore =
        1.0 /
        (1.0 + math.pow(10.0, (opponent.rating - currentSpecificElo) / 400.0));

    int newSpecificStreak = actualScore == 1.0
        ? currentSpecificStreak + 1
        : 0;
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
        : 0;
    int consolidatedStreakBonus =
        (actualScore == 1.0 && newConsolidatedStreak >= 3) ? 5 : 0;

    final newConsolidatedEloRaw =
        state.consolidatedRating +
        (consolidatedKFactor * (actualScore - expectedConsolidatedScore))
            .round() +
            consolidatedStreakBonus;
    final newConsolidatedElo = math.max(400, newConsolidatedEloRaw);

    final currentMargin = dominanceOverride ?? state.game.calculateMaterialMargin(
      state.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK,
    );

    double newBulletDom = state.bulletDominance;
    double newBlitzDom = state.blitzDominance;
    double newRapidDom = state.rapidDominance;

    if (!skipGameCountUpdate) {
      if (category == 'bullet') {
        final count = state.bulletGamesClassic;
        newBulletDom =
            ((state.bulletDominance * count) + currentMargin) / (count + 1);
      } else if (category == 'blitz') {
        final count = state.blitzGamesClassic;
        newBlitzDom =
            ((state.blitzDominance * count) + currentMargin) / (count + 1);
      } else {
        final count = state.rapidGamesClassic;
        newRapidDom =
            ((state.rapidDominance * count) + currentMargin) / (count + 1);
      }
    }

    final newTotalCount = skipGameCountUpdate ? state.totalRatedGamesCount : state.totalRatedGamesCount + 1;

    state = state.copyWith(
      consolidatedRating: newConsolidatedElo,
      totalRatedGamesCount: newTotalCount,
      totalWinningStreak: newConsolidatedStreak,
      lastRatedGameTimestampMs: DateTime.now().millisecondsSinceEpoch,
      decayIntervalsAppliedAtLastGame: state.decayIntervalsApplied,
      recalibrationGamesRemaining: skipGameCountUpdate
          ? state.recalibrationGamesRemaining
          : math.max(0, state.recalibrationGamesRemaining - 1),
      bulletElo: category == 'bullet' ? newSpecificElo : state.bulletElo,
      bulletStreak: category == 'bullet'
          ? newSpecificStreak
          : state.bulletStreak,
      bulletGamesClassic: (category == 'bullet' && !skipGameCountUpdate)
          ? state.bulletGamesClassic + 1
          : state.bulletGamesClassic,
      bulletDominance: newBulletDom,

      blitzElo: category == 'blitz' ? newSpecificElo : state.blitzElo,
      blitzStreak: category == 'blitz' ? newSpecificStreak : state.blitzStreak,
      blitzGamesClassic: (category == 'blitz' && !skipGameCountUpdate)
          ? state.blitzGamesClassic + 1
          : state.blitzGamesClassic,
      blitzDominance: newBlitzDom,

      rapidElo: category == 'rapid' ? newSpecificElo : state.rapidElo,
      rapidStreak: category == 'rapid' ? newSpecificStreak : state.rapidStreak,
      rapidGamesClassic: (category == 'rapid' && !skipGameCountUpdate)
          ? state.rapidGamesClassic + 1
          : state.rapidGamesClassic,
      rapidDominance: newRapidDom,
    );

    await _saveSettings();
  }

  Future<void> resignRatedGame() async {
    _clockTimer?.cancel();
    _clockTimer = null;
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _searchFen = null;
    _stopAnalysisAndReset();

    await _updateRating(0.0, dominanceOverride: _getAverageDominance()); // 0.0 = Loss
    await saveCurrentGame(
      customNameOverride: 'Rated Loss (Resigned)',
      resultOverride: 'L',
    );
    state = state.copyWith(
      activeRatedMatchId: null,
      activeRatedMatchRatingCategory: null,
      clockStarted: false,
      activeClockSide: null,
      isGameOverDismissed: false,
      isResigned: true,
    );
    await _saveSettings();
  }

  void pauseGame() {
    if (state.isPaused) return;
    state = state.copyWith(isPaused: true);
    _stopClockTimer();
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _stopAnalysisAndReset();
    state = state.copyWith(isEngineThinking: false);
    debugPrint('BattlegroundNotifier: Rated game paused via lifecycle.');
  }

  void resumeGame() {
    if (!state.isPaused) return;
    state = state.copyWith(isPaused: false);
    if (state.clockStarted) {
      _startClockTicker();
    }
    if (_isAiTurn() && !state.game.gameOver && !state.isTimeOut) {
      state = state.copyWith(isEngineThinking: true);
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
    debugPrint('BattlegroundNotifier: Rated game resumed via lifecycle.');
  }

  Future<bool> offerDraw() async {
    // 1. Increment drawOffersCount
    final newCount = state.drawOffersCount + 1;
    state = state.copyWith(drawOffersCount: newCount);

    // 2. Minimum move requirement: 20 plies (10 moves for each side)
    if (state.recentMoves.length < 20) {
      return false;
    }

    final opponent = state.activeOpponent ?? AiAvatar.getBestMatch(state.consolidatedRating);
    final contempt = opponent.contempt;

    // Calculate player's evaluation (White perspective vs Black perspective)
    final double playerEval = state.isPlayerWhite ? state.currentEvaluation : -state.currentEvaluation;

    // AI's evaluation is the negative of the player's evaluation
    final double aiEval = -playerEval;

    bool accepted = false;

    // If AI is winning significantly, it declines.
    double aiWinningThreshold = 1.0; 
    if (contempt > 0) {
      aiWinningThreshold = 0.4;
    } else if (contempt < 0) {
      aiWinningThreshold = 1.5;
    }

    if (aiEval >= aiWinningThreshold) {
      accepted = false;
    } else if (playerEval >= 1.5) {
      accepted = true;
    } else {
      if (contempt > 0) {
        final acceptProbability = 0.8 - (contempt / 150.0);
        final randomValue = math.Random().nextDouble();
        accepted = randomValue < acceptProbability;
      } else {
        accepted = true;
      }
    }

    if (accepted) {
      _clockTimer?.cancel();
      _clockTimer = null;
      _engineMoveTimer?.cancel();
      _engineMoveTimer = null;
      _searchFen = null;
      _stopAnalysisAndReset();

      await _updateRating(0.5, dominanceOverride: _getAverageDominance()); // 0.5 = Draw
      await saveCurrentGame(
        customNameOverride: 'Draw by Agreement',
        resultOverride: 'D',
      );

      state = state.copyWith(
        activeRatedMatchId: null,
        activeRatedMatchRatingCategory: null,
        clockStarted: false,
        activeClockSide: null,
        isGameOverDismissed: false,
        isDrawAgreed: true,
      );
      await _saveSettings();
      return true;
    }

    return false;
  }

  Future<void> completePromotion(String promotionPiece) async {
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
      await _onMoveCompleted('$from$to${promotionPiece.toLowerCase()}');

      if (state.game.gameOver || state.isTimeOut) {
        state = state.copyWith(
          clockStarted: false,
          activeClockSide: null,
          isEngineThinking: false,
        );
        _stopClockTimer();
        _engineMoveTimer?.cancel();
        _engineMoveTimer = null;
        _stopAnalysisAndReset();
        return;
      }

      if (!wasClockStarted) {
        state = state.copyWith(clockStarted: true);
      }
      state = state.copyWith(activeClockSide: _clockSideForTurn());
      _startClockTicker();
      await ensureGameServicesStarted(analyzeCurrentPosition: true);
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
    if (state.clockStarted && !state.isPaused && !state.game.gameOver && !state.isTimeOut) {
      _startClockTicker();
    }
  }

  void clearBoard() {
    _clockTimer?.cancel();
    _clockTimer = null;
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _searchFen = null;
    _stopAnalysisAndReset();
    _dominanceSamples.clear();

    final initialGame = ChessGame(isChess960: false); // Battleground always classic

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
      whiteTimeLeft: state.baseTimeDuration,
      blackTimeLeft: state.baseTimeDuration,
      threatenedSquares: const [],
      moveAnimation: null,
      isPaused: false,
      viewingMoveIndex: null,
      isGameOverDismissed: false,
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
      isTimeOut: false,
      isResigned: false,
      drawOffersCount: 0,
      isDrawAgreed: false,
    );
  }

  void reset({
    bool forcedPlayerWhite = true,
    bool startClockImmediate = false,
    bool keepOpponent = false,
  }) {
    _clockTimer?.cancel();
    _clockTimer = null;
    _engineMoveTimer?.cancel();
    _engineMoveTimer = null;
    _searchFen = null;
    _stopAnalysisAndReset();
    _dominanceSamples.clear();

    final initialGame = ChessGame(isChess960: false); // Battleground always classic

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
      isResigned: false,
      premoveFrom: null,
      premoveTo: null,
      drawOffersCount: 0,
      isDrawAgreed: false,
      // Clear any stale match ID so a fresh game never inherits a ghost ID
      activeRatedMatchId: null,
      activeRatedMatchRatingCategory: null,
    );

    if (!keepOpponent || state.activeOpponent == null) {
      _autoSelectRatedOpponent();
    }

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
  }



  Future<void> startGame() async {
    if (state.game.gameOver || state.isTimeOut) return;

    final aiMovesFirst = !state.isPlayerWhite;

    final category = _getRatingCategory(state.baseTimeDuration, state.incrementDuration);
    state = state.copyWith(
      clockStarted: true,
      activeClockSide: _clockWhite,
      isEngineThinking: aiMovesFirst && state.servicesStarted && state.engineReady,
      activeRatedMatchId: DateTime.now().millisecondsSinceEpoch.toString(),
      activeRatedMatchRatingCategory: category,
    );
    await _saveSettings();

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
    _soundService.playBattlegroundSfx(SoundEffect.uiClick);
  }

  // setGameMode removed: Battleground is Classic chess only.
  // Chess 960 is available in Arena and Academy.

  void setTimeControl(Duration total, Duration increment) {
    state = state.copyWith(
      baseTimeDuration: total,
      incrementDuration: increment,
      whiteTimeLeft: total,
      blackTimeLeft: total,
    );
    reset(keepOpponent: true);
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
    if (ref.read(chessProvider).isHapticsEnabled &&
        time <= const Duration(seconds: 10) &&
        time.inMilliseconds % 1000 == 0) {
      _hapticsService.heartbeat();
    }
  }

  Future<void> _handleClockTimeout(String side) async {
    if (state.game.inCheckmate) {
      return;
    }
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
    await _updateRating(score, dominanceOverride: _getAverageDominance());

    state = state.copyWith(
      activeRatedMatchId: null,
      activeRatedMatchRatingCategory: null,
    );
    await _saveSettings();

    final result = humanWon ? 'W' : 'L';
    await saveCurrentGame(resultOverride: result);

    // Timeout sound in Battleground
    _soundService.playBattlegroundSfx(humanWon ? SoundEffect.victory : SoundEffect.defeat);
  }

  String _clockSideForTurn() {
    return state.game.turn == chess_lib.Color.WHITE ? _clockWhite : _clockBlack;
  }

  void setViewingMoveIndex(int? index) {
    state = state.copyWith(viewingMoveIndex: index);
  }

  Future<void> _saveSettings() async {
    // Uses atomic updateSettings() to serialize concurrent calls and eliminate
    // the read-modify-write race condition (Bug C-01 fix).
    await _settingsRepository.updateSettings((s) => s.copyWith(
      consolidatedRating: state.consolidatedRating,
      bulletElo: state.bulletElo,
      blitzElo: state.blitzElo,
      rapidElo: state.rapidElo,
      totalRatedGamesCount: state.totalRatedGamesCount,
      bulletGamesClassic: state.bulletGamesClassic,
      blitzGamesClassic: state.blitzGamesClassic,
      rapidGamesClassic: state.rapidGamesClassic,
      totalWinningStreak: state.totalWinningStreak,
      bulletStreak: state.bulletStreak,
      blitzStreak: state.blitzStreak,
      rapidStreak: state.rapidStreak,
      bulletDominance: state.bulletDominance,
      blitzDominance: state.blitzDominance,
      rapidDominance: state.rapidDominance,
      activeRatedMatchId: state.activeRatedMatchId,
      activeRatedMatchOpponentId: state.activeRatedMatchId != null ? state.activeOpponent?.id : null,
      activeRatedMatchRatingCategory: state.activeRatedMatchRatingCategory,
      lastRatedGameTimestampMs: state.lastRatedGameTimestampMs,
      recalibrationGamesRemaining: state.recalibrationGamesRemaining,
      decayIntervalsApplied: state.decayIntervalsApplied,
      decayIntervalsAppliedAtLastGame: state.decayIntervalsAppliedAtLastGame,
    ));
    ref.read(cloudSyncProvider.notifier).backup(silent: true);
  }

  /// Reloads all BattlegroundNotifier state from disk.
  /// Called after a cloud restore so the UI reflects restored data
  /// without requiring an app restart (Bug C-02 fix).
  Future<void> reloadFromDisk() async {
    _settingsRepository.clearCache();
    await _loadInitialStateAndLedger();
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

      if (entry.result != null) {
        final opponent =
            state.activeOpponent ??
            AiAvatar.getBestMatch(state.consolidatedRating);
        
        bool reachedEndgame = false;
        String? endgameFen;
        try {
          final tempGame = ChessGame(
            fen: entry.initialFen,
            isChess960: entry.gameMode == 'chess960',
          );
          if (FenParser.isEndgame(tempGame.fen)) {
            reachedEndgame = true;
            endgameFen = tempGame.fen;
          } else {
            for (final move in entry.uciMoves) {
              tempGame.makeMove(move);
              if (FenParser.isEndgame(tempGame.fen)) {
                reachedEndgame = true;
                endgameFen = tempGame.fen;
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('Error replaying game to detect endgame: $e');
        }

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
          reachedEndgame: reachedEndgame,
          baseTimeMs: state.baseTimeDuration.inMilliseconds,
          endgameFen: endgameFen,
        );
        await ref.read(performanceLedgerManagerProvider.notifier).addEntry(ledgerEntry);
      }

      state = state.copyWith(
        activeRatedMatchId: entry.result != null
            ? null
            : state.activeRatedMatchId,
        activeRatedMatchRatingCategory: entry.result != null
            ? null
            : state.activeRatedMatchRatingCategory,
      );
      ref.read(cloudSyncProvider.notifier).backup(silent: true);

      if (entry.result != null) {
        await _saveSettings();
      }
      debugPrint('Rated game saved successfully: ${entry.id}');
      return entry;
    } catch (e) {
      debugPrint('Failed to save rated game: $e');
      return null;
    }
  }

  void refreshDashboardStats() {
    ref.read(performanceLedgerManagerProvider.notifier).reloadFromDisk();
  }

  List<double> _recalculateHeatmap(List<PerformanceLedgerEntry> ratedSaves) {
    final List<double> dominanceHeatmap = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final Map<String, List<double>> dailyDom = {};
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyDom[dateKey] = [];
    }

    for (final s in ratedSaves) {
      if (s.timestamp.isAfter(thirtyDaysAgo)) {
        final dateKey =
            '${s.timestamp.year}-${s.timestamp.month.toString().padLeft(2, '0')}-${s.timestamp.day.toString().padLeft(2, '0')}';
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
    return dominanceHeatmap;
  }

  Future<void> resetRatedStats() async {
    try {
      await ref.read(performanceLedgerManagerProvider.notifier).clearAll();
      state = state.copyWith(
        consolidatedRating: 400,
        bulletElo: 400,
        blitzElo: 400,
        rapidElo: 400,
        totalRatedGamesCount: 0,
        bulletGamesClassic: 0,
        blitzGamesClassic: 0,
        rapidGamesClassic: 0,
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
        decayIntervalsApplied: 0,
        decayIntervalsAppliedAtLastGame: 0,
      );
      await _saveSettings();
    } catch (e) {
      debugPrint('Failed to reset rated stats: $e');
    }
  }

  void clearMoveAnimation() {
    state = state.copyWith(moveAnimation: null);
  }
}

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

final battlegroundProvider =
    NotifierProvider<BattlegroundNotifier, BattlegroundState>(BattlegroundNotifier.new);
