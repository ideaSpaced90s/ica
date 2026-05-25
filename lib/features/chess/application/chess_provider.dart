import 'dart:math' as math;
import 'dart:async';
import 'package:chess/chess.dart' as chess_lib;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'game_clock_provider.dart';
import 'package:kingslayer_chess/src/rust/api/threats.dart';

import '../data/saved_game.dart';
import '../data/saved_game_repository.dart';
import '../domain/performance_ledger_entry.dart';
import '../data/performance_ledger_repository.dart';
import '../data/stockfish_service.dart';
import '../data/chess_engine_service.dart';
import '../data/crafty_service.dart';
import '../data/uci_parser.dart';
import '../domain/chess_game.dart';
import '../domain/chess_960_generator.dart';
import '../services/commentary_engine.dart';
import '../services/chess_sound_service.dart';
import '../services/ai_context_service.dart';
import '../data/settings_repository.dart';
import '../services/chess_haptics_service.dart';
import '../domain/models/ai_avatar.dart';
import '../domain/models/candidate_move.dart';
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;
import '../data/puzzle_repository.dart';
import '../domain/models/dashboard_stats.dart';
import '../domain/opening_classifier.dart';
import '../domain/fen_parser.dart';
import 'package:kingslayer_chess/src/rust/api/cognitive.dart';


const _sentinel = Object();
// Commentary default
const defaultCommentary = 'Make the first move to awaken the board.';
const _initialClock = Duration(minutes: 10);
const _clockWhite = 'white';
const _clockBlack = 'black';

class _BoardSnapshot {
  const _BoardSnapshot({
    required this.fen,
    required this.lastMove,
    required this.recentMoves,
    required this.previousEvaluation,
    required this.currentEvaluation,
    required this.commentaryHistory,
    required this.isCommentaryStreaming,
    required this.isCommentaryLoading,
    required this.isCommentaryEngineLoading,
    required this.commentaryError,
    required this.isEngineThinking,
    required this.hintBestMove,
    required this.hintFrom,
    required this.hintTo,
    required this.isHintVisible,
    required this.isHintLoading,
    required this.isHintBlinking,
    required this.isBulbGlowing,
    required this.whiteTimeLeft,
    required this.blackTimeLeft,
    required this.clockStarted,
    required this.activeClockSide,
    required this.threatenedSquares,
    this.pendingEngineMove,
    this.engineSelectionSquare,
    this.moveAnimation,
    required this.isAiOperational,
    required this.isAnimationsEnabled,
    required this.isPlayerWhite,
    required this.isBoardFlipped,
    required this.gameMode,
    required this.isRatedMode,
    required this.consolidatedRating,
    required this.bulletElo,
    required this.blitzElo,
    required this.rapidElo,
    required this.totalRatedGamesCount,
    required this.bulletGamesClassic,
    required this.bulletGames960,
    required this.blitzGamesClassic,
    required this.blitzGames960,
    required this.rapidGamesClassic,
    required this.rapidGames960,
    required this.totalWinningStreak,
    required this.bulletStreak,
    required this.blitzStreak,
    required this.rapidStreak,
    required this.bulletDominance,
    required this.blitzDominance,
    required this.rapidDominance,
    required this.isPuzzleMode,
    this.currentPuzzle,
    required this.puzzleMovesRemaining,
    this.activeRatedMatchId,
  });

  final String fen;
  final String? lastMove;
  final List<String> recentMoves;
  final double previousEvaluation;
  final double currentEvaluation;
  final List<CommentaryEntry> commentaryHistory;
  final bool isCommentaryStreaming;
  final bool isCommentaryLoading;
  final bool isCommentaryEngineLoading;
  final String? commentaryError;
  final bool isEngineThinking;
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
  final String? pendingEngineMove;
  final String? engineSelectionSquare;
  final MoveAnimationData? moveAnimation;
  final bool isAiOperational;
  final bool isAnimationsEnabled;
  final bool isPlayerWhite;
  final bool isBoardFlipped;
  final String gameMode;
  final bool isRatedMode;
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
  final bool isPuzzleMode;
  final rust_puzzles.Puzzle? currentPuzzle;
  final List<String> puzzleMovesRemaining;
  final String? activeRatedMatchId;
}

class MoveAnimationData {
  final String from;
  final String to;
  final String pieceCode;
  final bool isCapture;
  final bool isWrongMove;

  // Castling support: second piece (Rook)
  final String? rookFrom;
  final String? rookTo;
  final String? rookPieceCode;

  const MoveAnimationData({
    required this.from,
    required this.to,
    required this.pieceCode,
    this.isCapture = false,
    this.isWrongMove = false,
    this.rookFrom,
    this.rookTo,
    this.rookPieceCode,
  });

  bool get isCastle => rookFrom != null && rookTo != null;
}


class ChessState {
  ChessState({
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
    this.commentaryHistory = const [],
    this.isCommentaryStreaming = false,
    this.isCommentaryLoading = false,
    this.isCommentaryEngineLoading = false,
    this.commentaryError,
    this.hintBestMove,
    this.hintFrom,
    this.hintTo,
    this.isHintVisible = false,
    this.isHintLoading = false,
    this.isHintBlinking = false,
    this.isBulbGlowing = false,
    this.servicesStarted = false,
    this.servicesStarting = false,
    this.engineReady = false,
    this.startupError,
    this.whiteTimeLeft = _initialClock,
    this.blackTimeLeft = _initialClock,
    this.clockStarted = false,
    this.activeClockSide,
    this.savedGames = const [],
    this.isSavedGamesLoading = false,
    this.isSavingGame = false,
    this.threatenedSquares = const [],
    this.loadedSaveId,
    this.activeRatedMatchId,
    this.pendingEngineMove,
    this.engineSelectionSquare,
    this.moveAnimation,
    this.boardThemeId = 'classic',
    this.isSoundEnabled = true,
    this.isGameSoundEnabled = true,
    this.isAcademySoundEnabled = true,
    this.isMusicEnabled = false,
    this.showLog = false,
    this.showCoordinates = true,
    this.incrementDuration = const Duration(seconds: 0),
    this.isHapticsEnabled = true,
    this.isPaused = false,
    this.viewingMoveIndex,
    this.isAiOperational = true,
    this.isGameOverDismissed = false,
    this.isPromoting = false,
    this.promotionSource,
    this.promotionDestination,
    this.isAnimationsEnabled = true,
    this.animationSettings = const {
      'pieceMotion': true,
      'feedback': true,
      'indicators': true,
      'themeEffects': true,
      'themeAmbience': true,
      'kineticImpact': true,
      'arcadeMode': true,
    },
    this.soundSettings = const {
      'moveSounds': true,
      'captureSounds': true,
      'alertSounds': true,
    },
    this.academySoundSettings = const {
      'moveSounds': true,
      'captureSounds': true,
      'alertSounds': true,
      'outcomeSounds': true,
      'coachSounds': true,
      'ambientClicks': true,
    },
    this.isCouncilOnline = false,
    this.baseTimeDuration = _initialClock,
    this.gameMode = 'classic',
    this.isRatedMode = true,
    this.consolidatedRating = 1200,
    this.bulletElo = 1200,
    this.blitzElo = 1200,
    this.rapidElo = 1200,
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
    this.isPuzzleMode = false,
    this.currentPuzzle,
    this.puzzleMovesRemaining = const [],
    this.academyHouseAnimations = true,
    this.academyHouseColorFonts = true,
    this.academyHouseBoldEmphasis = true,
    this.academyHouseTypingEffect = true,
    this.chanakyaSuggestion,
    this.isAcademyActive = false,
    this.glowingSquare,
    this.academyAnimationTrigger = 0,
    this.hasBlinkedMenu = false,
    this.isTimeOut = false,
    this.userName = 'Apprentice',
    this.userAvatarPath = 'assets/persona/user_profile_0.png',
    this.cachedScotoma,
    this.cachedPlaystyle,
    this.cachedOpenings = const [],
    this.cachedEndgames,
    this.cachedDominanceHeatmap = const [],
    this.cachedLedgerEntries = const [],
  });

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
  final List<CommentaryEntry> commentaryHistory;
  final bool isCommentaryStreaming;
  final bool isCommentaryLoading;
  final bool isCommentaryEngineLoading;
  final String? commentaryError;
  final String? hintBestMove;
  final String? hintFrom;
  final String? hintTo;
  final bool isHintVisible;
  final bool isHintLoading;
  final bool isHintBlinking;
  final bool isBulbGlowing;
  final bool servicesStarted;
  final bool servicesStarting;
  final bool engineReady;
  final String? startupError;
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;
  final bool clockStarted;
  final String? activeClockSide;
  final List<SavedGameEntry> savedGames;
  final bool isSavedGamesLoading;
  final bool isSavingGame;
  final List<String> threatenedSquares;
  final String? loadedSaveId;
  final String? activeRatedMatchId;
  final String? pendingEngineMove;
  final String? engineSelectionSquare;
  final MoveAnimationData? moveAnimation;
  final String boardThemeId;
  final bool isSoundEnabled;
  final bool isGameSoundEnabled;
  final bool isAcademySoundEnabled;
  final bool isMusicEnabled;
  final bool showLog;
  final bool showCoordinates;
  final Duration incrementDuration;
  final bool isHapticsEnabled;
  final bool isPaused;
  final int? viewingMoveIndex;
  final bool isAiOperational;
  final bool isGameOverDismissed;
  final bool isPromoting;
  final String? promotionSource;
  final String? promotionDestination;
  final bool isAnimationsEnabled;
  final Map<String, bool> animationSettings;
  final Map<String, bool> soundSettings;
  final Map<String, bool> academySoundSettings;
  final bool isCouncilOnline;
  final Duration baseTimeDuration;
  final String gameMode;
  final bool isRatedMode;
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
  final bool isPuzzleMode;
  final rust_puzzles.Puzzle? currentPuzzle;
  final List<String> puzzleMovesRemaining;
  final bool academyHouseAnimations;
  final bool academyHouseColorFonts;
  final bool academyHouseBoldEmphasis;
  final bool academyHouseTypingEffect;
  final MoveAnimationData? chanakyaSuggestion;
  final bool isAcademyActive;
  final String? glowingSquare;
  final int academyAnimationTrigger;
  final bool hasBlinkedMenu;
  final bool isTimeOut;
  final String userName;
  final String userAvatarPath;
  final ScotomaResult? cachedScotoma;
  final TacticalPlaystyleStats? cachedPlaystyle;
  final List<OpeningRepertoireStats> cachedOpenings;
  final EndgamePerformanceStats? cachedEndgames;
  final List<double> cachedDominanceHeatmap;
  final List<PerformanceLedgerEntry> cachedLedgerEntries;

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

  ChessState copyWith({
    ChessGame? game,
    Object? lastMove = _sentinel,
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
    List<CommentaryEntry>? commentaryHistory,
    bool? isCommentaryStreaming,
    bool? isCommentaryLoading,
    bool? isCommentaryEngineLoading,
    Object? commentaryError = _sentinel,
    Object? hintBestMove = _sentinel,
    Object? hintFrom = _sentinel,
    Object? hintTo = _sentinel,
    bool? isHintVisible,
    bool? isHintLoading,
    bool? isHintBlinking,
    bool? isBulbGlowing,
    bool? servicesStarted,
    bool? servicesStarting,
    bool? engineReady,
    Object? startupError = _sentinel,
    Duration? whiteTimeLeft,
    Duration? blackTimeLeft,
    bool? clockStarted,
    Object? activeClockSide = _sentinel,
    List<SavedGameEntry>? savedGames,
    bool? isSavedGamesLoading,
    bool? isSavingGame,
    List<String>? threatenedSquares,
    Object? loadedSaveId = _sentinel,
    Object? activeRatedMatchId = _sentinel,
    Object? pendingEngineMove = _sentinel,
    Object? engineSelectionSquare = _sentinel,
    Object? moveAnimation = _sentinel,
    String? boardThemeId,
    bool? isSoundEnabled,
    bool? isGameSoundEnabled,
    bool? isAcademySoundEnabled,
    bool? isMusicEnabled,
    bool? showLog,
    bool? showCoordinates,
    Duration? incrementDuration,
    bool? isHapticsEnabled,
    bool? isPaused,
    Object? viewingMoveIndex = _sentinel,
    bool? isAiOperational,
    bool? isGameOverDismissed,
    bool? isPromoting,
    Object? promotionSource = _sentinel,
    Object? promotionDestination = _sentinel,
    bool? isAnimationsEnabled,
    Map<String, bool>? animationSettings,
    Map<String, bool>? soundSettings,
    Map<String, bool>? academySoundSettings,
    bool? isCouncilOnline,
    Duration? baseTimeDuration,
    String? gameMode,
    bool? isRatedMode,
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
    bool? isPuzzleMode,
    Object? currentPuzzle = _sentinel,
    List<String>? puzzleMovesRemaining,
    bool? academyHouseAnimations,
    bool? academyHouseColorFonts,
    bool? academyHouseBoldEmphasis,
    bool? academyHouseTypingEffect,
    Object? chanakyaSuggestion = _sentinel,
    bool? isAcademyActive,
    Object? glowingSquare = _sentinel,
    int? academyAnimationTrigger,
    bool? hasBlinkedMenu,
    bool? isTimeOut,
    String? userName,
    String? userAvatarPath,
    ScotomaResult? cachedScotoma,
    TacticalPlaystyleStats? cachedPlaystyle,
    List<OpeningRepertoireStats>? cachedOpenings,
    EndgamePerformanceStats? cachedEndgames,
    List<double>? cachedDominanceHeatmap,
    List<PerformanceLedgerEntry>? cachedLedgerEntries,
  }) {
    return ChessState(
      game: game ?? this.game,
      lastMove: identical(lastMove, _sentinel)
          ? this.lastMove
          : lastMove as String?,
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
      commentaryHistory: commentaryHistory ?? this.commentaryHistory,
      isCommentaryStreaming:
          isCommentaryStreaming ?? this.isCommentaryStreaming,
      isCommentaryLoading: isCommentaryLoading ?? this.isCommentaryLoading,
      isCommentaryEngineLoading:
          isCommentaryEngineLoading ?? this.isCommentaryEngineLoading,
      commentaryError: identical(commentaryError, _sentinel)
          ? this.commentaryError
          : commentaryError as String?,
      hintBestMove: identical(hintBestMove, _sentinel)
          ? this.hintBestMove
          : hintBestMove as String?,
      hintFrom: identical(hintFrom, _sentinel)
          ? this.hintFrom
          : hintFrom as String?,
      hintTo: identical(hintTo, _sentinel) ? this.hintTo : hintTo as String?,
      isHintVisible: isHintVisible ?? this.isHintVisible,
      isHintLoading: isHintLoading ?? this.isHintLoading,
      isHintBlinking: isHintBlinking ?? this.isHintBlinking,
      isBulbGlowing: isBulbGlowing ?? this.isBulbGlowing,
      servicesStarted: servicesStarted ?? this.servicesStarted,
      servicesStarting: servicesStarting ?? this.servicesStarting,
      engineReady: engineReady ?? this.engineReady,
      startupError: identical(startupError, _sentinel)
          ? this.startupError
          : startupError as String?,
      whiteTimeLeft: whiteTimeLeft ?? this.whiteTimeLeft,
      blackTimeLeft: blackTimeLeft ?? this.blackTimeLeft,
      clockStarted: clockStarted ?? this.clockStarted,
      activeClockSide: identical(activeClockSide, _sentinel)
          ? this.activeClockSide
          : activeClockSide as String?,
      savedGames: savedGames ?? this.savedGames,
      isSavedGamesLoading: isSavedGamesLoading ?? this.isSavedGamesLoading,
      isSavingGame: isSavingGame ?? this.isSavingGame,
      threatenedSquares: threatenedSquares ?? this.threatenedSquares,
      loadedSaveId: identical(loadedSaveId, _sentinel)
          ? this.loadedSaveId
          : loadedSaveId as String?,
      activeRatedMatchId: identical(activeRatedMatchId, _sentinel)
          ? this.activeRatedMatchId
          : activeRatedMatchId as String?,
      pendingEngineMove: identical(pendingEngineMove, _sentinel)
          ? this.pendingEngineMove
          : pendingEngineMove as String?,
      engineSelectionSquare: identical(engineSelectionSquare, _sentinel)
          ? this.engineSelectionSquare
          : engineSelectionSquare as String?,
      moveAnimation: identical(moveAnimation, _sentinel)
          ? this.moveAnimation
          : moveAnimation as MoveAnimationData?,
      boardThemeId: boardThemeId ?? this.boardThemeId,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isGameSoundEnabled: isGameSoundEnabled ?? this.isGameSoundEnabled,
      isAcademySoundEnabled: isAcademySoundEnabled ?? this.isAcademySoundEnabled,
      isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
      showLog: showLog ?? this.showLog,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      incrementDuration: incrementDuration ?? this.incrementDuration,
      isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
      isPaused: isPaused ?? this.isPaused,
      viewingMoveIndex: identical(viewingMoveIndex, _sentinel)
          ? this.viewingMoveIndex
          : viewingMoveIndex as int?,
      isAiOperational: isAiOperational ?? this.isAiOperational,
      isGameOverDismissed: isGameOverDismissed ?? this.isGameOverDismissed,
      isPromoting: isPromoting ?? this.isPromoting,
      promotionSource: identical(promotionSource, _sentinel)
          ? this.promotionSource
          : promotionSource as String?,
      promotionDestination: identical(promotionDestination, _sentinel)
          ? this.promotionDestination
          : promotionDestination as String?,
      isAnimationsEnabled: isAnimationsEnabled ?? this.isAnimationsEnabled,
      animationSettings: animationSettings ?? this.animationSettings,
      soundSettings: soundSettings ?? this.soundSettings,
      academySoundSettings: academySoundSettings ?? this.academySoundSettings,
      isCouncilOnline: isCouncilOnline ?? this.isCouncilOnline,
      baseTimeDuration: baseTimeDuration ?? this.baseTimeDuration,
      gameMode: gameMode ?? this.gameMode,
      isRatedMode: isRatedMode ?? this.isRatedMode,
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
      isPuzzleMode: isPuzzleMode ?? this.isPuzzleMode,
      currentPuzzle: identical(currentPuzzle, _sentinel)
          ? this.currentPuzzle
          : currentPuzzle as rust_puzzles.Puzzle?,
      puzzleMovesRemaining: puzzleMovesRemaining ?? this.puzzleMovesRemaining,
      academyHouseAnimations:
          academyHouseAnimations ?? this.academyHouseAnimations,
      academyHouseColorFonts:
          academyHouseColorFonts ?? this.academyHouseColorFonts,
      academyHouseBoldEmphasis:
          academyHouseBoldEmphasis ?? this.academyHouseBoldEmphasis,
      academyHouseTypingEffect:
          academyHouseTypingEffect ?? this.academyHouseTypingEffect,
      chanakyaSuggestion: identical(chanakyaSuggestion, _sentinel)
          ? this.chanakyaSuggestion
          : chanakyaSuggestion as MoveAnimationData?,
      isAcademyActive: isAcademyActive ?? this.isAcademyActive,
      glowingSquare: identical(glowingSquare, _sentinel)
          ? this.glowingSquare
          : glowingSquare as String?,
      academyAnimationTrigger:
          academyAnimationTrigger ?? this.academyAnimationTrigger,
      hasBlinkedMenu: hasBlinkedMenu ?? this.hasBlinkedMenu,
      isTimeOut: isTimeOut ?? this.isTimeOut,
      userName: userName ?? this.userName,
      userAvatarPath: userAvatarPath ?? this.userAvatarPath,
      cachedScotoma: cachedScotoma ?? this.cachedScotoma,
      cachedPlaystyle: cachedPlaystyle ?? this.cachedPlaystyle,
      cachedOpenings: cachedOpenings ?? this.cachedOpenings,
      cachedEndgames: cachedEndgames ?? this.cachedEndgames,
      cachedDominanceHeatmap: cachedDominanceHeatmap ?? this.cachedDominanceHeatmap,
      cachedLedgerEntries: cachedLedgerEntries ?? this.cachedLedgerEntries,
    );
  }
}

class ChessNotifier extends StateNotifier<ChessState> {
  final Ref ref;

  ChessNotifier(
    this.ref,
    this._stockfishEngine,
    this._craftyEngine,
    this._commentaryEngine,
    this._savedGameRepository,
    this._performanceLedgerRepository,
    this._soundService,
    this._hapticsService,
    this._aiContextService,
    this._settingsRepository,
    this._puzzleRepository,
  ) : super(
        ChessState(
          game: ChessGame(),
          commentaryHistory: [
            CommentaryEntry(
              text: "Welcome to the Academy, Apprentice. I am GM Chanakya. Place your pieces on the board or ask me for strategic counsel, and we shall prepare for the coming trials against the machine collective.",
              timestamp: DateTime.now(),
              isComplete: true,
              isUser: false,
            ),
          ],
        ),
      ) {
    _soundService.updateSettings(sfxEnabled: true, bgmEnabled: false, isRatedMode: false);
    _hapticsService.updateSettings(hapticsEnabled: true);
    _commentaryEngine.onPuzzleLoaded = loadPuzzle;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final s = await _settingsRepository.loadSettings();
      final is960 = s.gameMode == 'chess960';
      final initialGame = is960
          ? ChessGame(
              fen: Chess960Generator.generateRandomPosition().fen,
              isChess960: true,
            )
          : ChessGame(isChess960: false);

      state = state.copyWith(
        game: initialGame,
        boardThemeId: s.boardThemeId,
        isSoundEnabled: s.isSoundEnabled,
        isGameSoundEnabled: s.isGameSoundEnabled,
        isAcademySoundEnabled: s.isAcademySoundEnabled,
        isMusicEnabled: s.isMusicEnabled,
        isAnimationsEnabled: s.isAnimationsEnabled,
        animationSettings: s.animationSettings,
        soundSettings: s.soundSettings,
        academySoundSettings: s.academySoundSettings,
        isHapticsEnabled: s.isHapticsEnabled,
        showCoordinates: s.showCoordinates,
        engineLevel: s.engineLevel,
        bottomAvatarId: s.bottomAvatarId,
        isAiOperational: s.isAiOperational,
        baseTimeDuration: Duration(minutes: s.totalTimeMinutes),
        whiteTimeLeft: Duration(minutes: s.totalTimeMinutes),
        blackTimeLeft: Duration(minutes: s.totalTimeMinutes),
        incrementDuration: Duration(seconds: s.incrementSeconds),
        gameMode: s.gameMode,
        isRatedMode: s.isRatedMode,
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
        academyHouseAnimations: s.academyHouseAnimations,
        academyHouseColorFonts: s.academyHouseColorFonts,
        academyHouseBoldEmphasis: s.academyHouseBoldEmphasis,
        academyHouseTypingEffect: s.academyHouseTypingEffect,
        bulletDominance: s.bulletDominance,
        blitzDominance: s.blitzDominance,
        rapidDominance: s.rapidDominance,
        userName: s.userName,
        userAvatarPath: s.userAvatarPath,
        activeRatedMatchId: s.activeRatedMatchId,
      );
      await _engine.setChess960Mode(is960);
      final avatar = AiAvatar.getAvatar(s.engineLevel);
      await _engine.setSkillLevel(
        avatar.skillLevel,
        multiPV: avatar.name == 'Kingslayer' ? 1 : 4,
      );
      _soundService.updateSettings(
        sfxEnabled: s.isSoundEnabled,
        bgmEnabled: s.isMusicEnabled,
        gameSoundEnabled: s.isGameSoundEnabled,
        soundSettings: s.soundSettings,
        academySoundEnabled: s.isAcademySoundEnabled,
        academySoundSettings: s.academySoundSettings,
        isAcademyActive: state.isAcademyActive,
        isRatedMode: s.isRatedMode,
      );
      _hapticsService.updateSettings(hapticsEnabled: s.isHapticsEnabled);

      if (s.activeRatedMatchId != null) {
        debugPrint('Active rated match ID found on boot: ${s.activeRatedMatchId}. Registering unfair exit loss.');
        await _updateRating(0.0);
        
        final entry = SavedGameEntry(
          id: s.activeRatedMatchId!,
          savedAt: DateTime.now(),
          fen: chess_lib.Chess.DEFAULT_POSITION,
          recentMoves: const [],
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
        
        state = state.copyWith(activeRatedMatchId: null);
        await _saveSettings();
      }

      // Automatically load saved games and populate dashboard caches on boot
      await loadSavedGames();
      _syncTimesToClockProvider();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final s = AppSettings(
        boardThemeId: state.boardThemeId,
        isSoundEnabled: state.isSoundEnabled,
        isGameSoundEnabled: state.isGameSoundEnabled,
        isAcademySoundEnabled: state.isAcademySoundEnabled,
        isMusicEnabled: state.isMusicEnabled,
        isAnimationsEnabled: state.isAnimationsEnabled,
        animationSettings: state.animationSettings,
        soundSettings: state.soundSettings,
        academySoundSettings: state.academySoundSettings,
        isHapticsEnabled: state.isHapticsEnabled,
        showCoordinates: state.showCoordinates,
        engineLevel: state.engineLevel,
        bottomAvatarId: state.bottomAvatarId,
        isAiOperational: state.isAiOperational,
        totalTimeMinutes: state.baseTimeDuration.inMinutes,
        incrementSeconds: state.incrementDuration.inSeconds,
        gameMode: state.gameMode,
        isRatedMode: state.isRatedMode,
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
        academyHouseAnimations: state.academyHouseAnimations,
        academyHouseColorFonts: state.academyHouseColorFonts,
        academyHouseBoldEmphasis: state.academyHouseBoldEmphasis,
        academyHouseTypingEffect: state.academyHouseTypingEffect,
        bulletDominance: state.bulletDominance,
        blitzDominance: state.blitzDominance,
        rapidDominance: state.rapidDominance,
        userName: state.userName,
        userAvatarPath: state.userAvatarPath,
        activeRatedMatchId: state.activeRatedMatchId,
      );
      await _settingsRepository.saveSettings(s);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  Future<void> setGameMode(String mode) async {
    final is960 = mode == 'chess960';
    state = state.copyWith(gameMode: mode);
    await _engine.setChess960Mode(is960);
    await _saveSettings();
    await reset();
  }

  Future<void> setRatedMode(bool isRated) async {
    if (state.isRatedMode == isRated) return;

    
    final newBoardThemeId = isRated ? 'classic' : state.boardThemeId;
    final newIsMusicEnabled = isRated ? false : state.isMusicEnabled;
    
    state = state.copyWith(
      isRatedMode: isRated,
      isEngineVsEngine: isRated ? false : state.isEngineVsEngine,
      boardThemeId: newBoardThemeId,
      isMusicEnabled: newIsMusicEnabled,
      // Force snappy animations for rated mode
      animationSettings: isRated 
        ? {
            'pieceMotion': true,
            'feedback': false,
            'indicators': false,
            'themeEffects': false,
            'themeAmbience': false,
            'kineticImpact': false,
            'arcadeMode': false,
          }
        : state.animationSettings,
    );

    if (isRated) {
      _autoSelectRatedOpponent();
    }
    
    // Update sound service state
    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: newIsMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: state.isAcademyActive,
      isRatedMode: isRated,
    );
    
    await _saveSettings();
    await reset(skipAutoSave: true);
  }

  Future<void> resetRatedStats() async {
    try {
      await _performanceLedgerRepository.clearAll();
      state = state.copyWith(
        consolidatedRating: 1200,
        bulletElo: 1200,
        blitzElo: 1200,
        rapidElo: 1200,
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
      );
      _refreshDashboardStats();
      await _saveSettings();
    } catch (e) {
      debugPrint('Failed to reset rated stats & ledger: $e');
    }
  }

  void toggleSound() {
    final newEnabled = !state.isSoundEnabled;
    state = state.copyWith(isSoundEnabled: newEnabled);
    _soundService.updateSettings(
      sfxEnabled: newEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: state.isAcademyActive,
      isRatedMode: state.isRatedMode,
    );
    _saveSettings();
  }

  void toggleMusic() {
    final newEnabled = !state.isMusicEnabled;
    state = state.copyWith(isMusicEnabled: newEnabled);
    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: newEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: state.isAcademyActive,
      isRatedMode: state.isRatedMode,
    );
    _saveSettings();
  }

  void toggleGameSound() {
    final newEnabled = !state.isGameSoundEnabled;
    state = state.copyWith(isGameSoundEnabled: newEnabled);
    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: newEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: state.isAcademyActive,
      isRatedMode: state.isRatedMode,
    );
    _saveSettings();
  }

  void updateSoundSetting(String key, bool enabled) {
    final newSettings = Map<String, bool>.from(state.soundSettings);
    newSettings[key] = enabled;
    state = state.copyWith(soundSettings: newSettings);
    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: newSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: state.isAcademyActive,
      isRatedMode: state.isRatedMode,
    );
    _saveSettings();
  }

  bool isSoundSettingEnabled(String key) {
    return state.isGameSoundEnabled && (state.soundSettings[key] ?? true);
  }

  void toggleAcademySound() {
    final newEnabled = !state.isAcademySoundEnabled;
    state = state.copyWith(isAcademySoundEnabled: newEnabled);
    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: newEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: state.isAcademyActive,
      isRatedMode: state.isRatedMode,
    );
    _saveSettings();
  }

  void updateAcademySoundSetting(String key, bool enabled) {
    final newSettings = Map<String, bool>.from(state.academySoundSettings);
    newSettings[key] = enabled;
    state = state.copyWith(academySoundSettings: newSettings);
    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: newSettings,
      isAcademyActive: state.isAcademyActive,
      isRatedMode: state.isRatedMode,
    );
    _saveSettings();
  }

  bool isAcademySoundSettingEnabled(String key) {
    return state.isAcademySoundEnabled && (state.academySoundSettings[key] ?? true);
  }

  void toggleLog() {
    state = state.copyWith(showLog: !state.showLog);
  }

  void toggleCoordinates() {
    state = state.copyWith(showCoordinates: !state.showCoordinates);
    _saveSettings();
  }

  void setBoardTheme(String themeId) {
    state = state.copyWith(boardThemeId: themeId);
    _saveSettings();
  }

  void setTimeControl(Duration total, Duration increment) {
    state = state.copyWith(
      baseTimeDuration: total,
      whiteTimeLeft: total,
      blackTimeLeft: total,
      incrementDuration: increment,
      clockStarted: false,
      activeClockSide: null,
    );
    _stopClock();
    _syncTimesToClockProvider();
    _saveSettings();
  }

  void toggleHaptics() {
    final newEnabled = !state.isHapticsEnabled;
    state = state.copyWith(isHapticsEnabled: newEnabled);
    _hapticsService.updateSettings(hapticsEnabled: newEnabled);
    _saveSettings();
  }

  void toggleAnimations() {
    state = state.copyWith(isAnimationsEnabled: !state.isAnimationsEnabled);
    _saveSettings();
  }

  void updateAnimationSetting(String key, bool value) {
    final newSettings = Map<String, bool>.from(state.animationSettings);
    newSettings[key] = value;
    state = state.copyWith(animationSettings: newSettings);
    _saveSettings();
  }

  bool isAnimationTypeEnabled(String key) {
    if (state.isRatedMode || state.isAcademyActive || state.isPuzzleMode) {
      return key == 'pieceMotion';
    }
    return state.isAnimationsEnabled && (state.animationSettings[key] ?? true);
  }

  void toggleAcademyHouseAnimations() {
    state = state.copyWith(academyHouseAnimations: !state.academyHouseAnimations);
    _saveSettings();
  }

  void toggleAcademyHouseColorFonts() {
    state = state.copyWith(academyHouseColorFonts: !state.academyHouseColorFonts);
    _saveSettings();
  }

  void toggleAcademyHouseBoldEmphasis() {
    state = state.copyWith(academyHouseBoldEmphasis: !state.academyHouseBoldEmphasis);
    _saveSettings();
  }

  void toggleAcademyHouseTypingEffect() {
    state = state.copyWith(academyHouseTypingEffect: !state.academyHouseTypingEffect);
    _saveSettings();
  }

  void togglePause() {
    final newPaused = !state.isPaused;
    state = state.copyWith(isPaused: newPaused);
    if (newPaused) {
      _stopClock();
      _engineMoveTimer?.cancel();
    } else {
      // Clear analysis position when resuming game
      state = state.copyWith(
        viewingMoveIndex: null,
        threatenedSquares: const [],
      );

      if (state.clockStarted) {
        _startClockTicker();
      }
      if (state.servicesStarted &&
          _isAiTurn() &&
          !state.game.gameOver &&
          state.pendingEngineMove == null) {
        _startAnalysis();
        state = state.copyWith(isEngineThinking: true);
      }
    }
  }

  void toggleAiOperational() {
    final newState = !state.isAiOperational;
    state = state.copyWith(isAiOperational: newState);
    _saveSettings();
  }

  void dismissGameOver() {
    state = state.copyWith(isGameOverDismissed: true);
  }

  void markMenuAsBlinked() {
    state = state.copyWith(hasBlinkedMenu: true);
  }

  void jumpToMove(int index) {
    if (index < -1 || index >= state.recentMoves.length) return;
    state = state.copyWith(viewingMoveIndex: index == -1 ? null : index);

    // Auto-analyze position when jumping in analysis
    if (state.isPaused) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
  }

  void _truncateToViewingIndex() {
    if (state.viewingMoveIndex == null) return;

    final targetLength = state.viewingMoveIndex! + 1;
    while (state.game.history.length > targetLength) {
      state.game.undo();
    }

    // Clear redo stack as we are branching
    _redoStack.clear();

    state = state.copyWith(
      viewingMoveIndex: null,
      recentMoves: state.game.moveHistoryLabels(),
      lastMove: _lastMoveUci(),
      threatenedSquares: const [], // Clear threats from old position
    );
    _syncUndoRedoFlags();
  }

  String? _lastMoveUci() {
    final history = state.game.history;
    if (history.isEmpty) return null;
    try {
      final last = history.last;
      final move = last.move;
      final from = chess_lib.Chess.algebraic(move.from);
      final to = chess_lib.Chess.algebraic(move.to);
      final promotion = move.promotion != null
          ? move.promotion.toString().split('.').last.toLowerCase()[0]
          : '';
      return '$from$to$promotion';
    } catch (e) {
      return null;
    }
  }

  void stepMove(int delta) {
    final currentIndex =
        state.viewingMoveIndex ?? (state.recentMoves.length - 1);
    jumpToMove(currentIndex + delta);
  }

  void goToStart() {
    jumpToMove(-1);
  }

  void goToEnd() {
    jumpToMove(state.recentMoves.length - 1);
  }

  void showThreats() {
    final fen = state.currentBoardFen;

    // Side-by-side execution: benchmark and compare both engines!
    final stopwatchDart = Stopwatch()..start();
    final game = ChessGame(fen: fen);
    final turn = game.turn;
    final opponentColor = turn == chess_lib.Color.WHITE
        ? chess_lib.Color.BLACK
        : chess_lib.Color.WHITE;

    final threatenedDart = <String>[];
    for (final square in chess_lib.Chess.SQUARES.keys) {
      if (game.isAttacked(square, opponentColor)) {
        final piece = game.getPiece(square);
        if (piece != null && piece.color == turn) {
          threatenedDart.add(square);
        }
      }
    }
    stopwatchDart.stop();

    // Run Rust Bitboard Engine
    final stopwatchRust = Stopwatch()..start();
    List<String> threatenedRust = [];
    try {
      threatenedRust = getThreatenedSquares(fen: fen);
    } catch (e) {
      debugPrint('Rust Threat Engine Error: $e');
    }
    stopwatchRust.stop();

    // Log Side-by-Side comparison summary
    debugPrint(
      'Threat Engine Benchmark:\n'
      '  Dart evaluation: ${stopwatchDart.elapsedMicroseconds} μs\n'
      '  Rust evaluation: ${stopwatchRust.elapsedMicroseconds} μs\n'
      '  Parity Check: Dart: ${threatenedDart.length} squares | Rust: ${threatenedRust.length} squares',
    );

    // Use Rust output if populated, falling back to Dart safely
    final finalThreats = threatenedRust.isNotEmpty ? threatenedRust : threatenedDart;
    state = state.copyWith(threatenedSquares: finalThreats);
  }

  final ChessEngineService _stockfishEngine;
  final ChessEngineService _craftyEngine;

  String get _activeAvatarId {
    if (state.isAcademyActive) {
      return 'academy';
    }
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

  ChessEngineService get _engine {
    final avatarId = _activeAvatarId;
    if (avatarId == 'academy') {
      return _craftyEngine.isError ? _stockfishEngine : _craftyEngine;
    }
    final craftyIds = {'avatar_0', 'avatar_1', 'avatar_4', 'avatar_7', 'avatar_9'};
    if (craftyIds.contains(avatarId)) {
      return _craftyEngine.isError ? _stockfishEngine : _craftyEngine;
    }
    return _stockfishEngine;
  }

  final CommentaryEngine _commentaryEngine;
  final SavedGameRepository _savedGameRepository;
  final PerformanceLedgerRepository _performanceLedgerRepository;
  final ChessSoundService _soundService;
  final ChessHapticsService _hapticsService;
  final AiContextService _aiContextService;
  final SettingsRepository _settingsRepository;
  final PuzzleRepository _puzzleRepository;
  final _uuid = const Uuid();

  Timer? _engineMoveTimer;
  Timer? _commentaryRevealTimer;
  Timer? _maxThinkingTimer;
  DateTime? _engineStartTime;
  StreamSubscription<String>? _stockfishSubscription;
  StreamSubscription<String>? _craftySubscription;

  Future<void> _cancelEngineSubscriptions() async {
    await _stockfishSubscription?.cancel();
    _stockfishSubscription = null;
    await _craftySubscription?.cancel();
    _craftySubscription = null;
  }
  final List<_BoardSnapshot> _undoStack = [];
  final List<_BoardSnapshot> _redoStack = [];
  final List<CandidateMove> _currentCandidates = [];

  String? _pendingHintFen;
  Future<void>? _startupFuture;
  bool _isDisposed = false;
  DateTime _lastInfoUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> ensureGameServicesStarted({
    bool analyzeCurrentPosition = false,
    int? depth,
  }) async {
    if (_isDisposed) {
      return;
    }

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
      commentaryError: null,
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
      // Start listening to BOTH engines BEFORE init so we don't miss uciok/readyok
      _stockfishSubscription ??= _stockfishEngine.outputStream.listen(
        _handleEngineOutput,
      );
      _craftySubscription ??= _craftyEngine.outputStream.listen(
        _handleEngineOutput,
      );

      await _stockfishEngine.init();
      await _craftyEngine.init();

      final avatar = AiAvatar.getAvatar(state.engineLevel);
      final multiPV = state.isAcademyActive ? 3 : (avatar.name == 'Kingslayer' ? 1 : 4);
      
      await _stockfishEngine.setSkillLevel(
        avatar.skillLevel,
        multiPV: multiPV,
      );
      await _craftyEngine.setSkillLevel(
        avatar.skillLevel,
        multiPV: multiPV,
      );

      state = state.copyWith(
        servicesStarted: true,
        servicesStarting: false,
        engineReady: _engine.isReady,
        isCouncilOnline: _commentaryEngine.isInitialized,
        startupError: null,
      );
      // Initialization will happen on-demand in _runCommentary
      // unawaited(_initializeCommentaryEngine());
      if (analyzeCurrentPosition) {
        _startAnalysis(depth: depth);
      }
    } catch (error, stackTrace) {
      debugPrint('ChessNotifier startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        servicesStarting: false,
        servicesStarted: false,
        engineReady: false,
        startupError: 'Unable to start the engine.',
      );
    }
  }

  void _handleEngineOutput(String line) {
    if (_isDisposed) {
      return;
    }

    final parsed = UCIParser.parseLine(line);
    if (parsed.isEmpty) {
      return;
    }

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
        bool isBottomTurn = false;
        final fenParts = state.game.fen.split(' ');
        if (fenParts.length > 1) {
          final turnWhite = fenParts[1] == 'w';
          isBottomTurn = (state.isPlayerWhite == turnWhite);
        }
        final activeAvatarId = (state.isEngineVsEngine && isBottomTurn)
            ? state.bottomAvatarId
            : state.engineLevel;
        final currentAvatar = AiAvatar.getAvatar(activeAvatarId);

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
        _maxThinkingTimer?.cancel();
        _maxThinkingTimer = null;
        _engineMoveTimer?.cancel();

        final finalMove = bestMoveToPlay;
        if (state.isAnimationsEnabled && !state.isRatedMode) {
          final now = DateTime.now();
          final elapsed = now
              .difference(_engineStartTime ?? now)
              .inMilliseconds;
          // Ensure at least 2s total time (thinking + delay)
          final remainingDelay = math.max(0, 2000 - elapsed);

          _engineMoveTimer = Timer(Duration(milliseconds: remainingDelay), () {
            if (!_isDisposed && !state.isPaused) {
              _makeEngineMove(finalMove);
            }
          });
        } else {
          _makeEngineMove(finalMove);
        }
      }
    }
  }

  String _applyPersonaHeuristics(
    List<CandidateMove> candidates,
    AiAvatar avatar,
    ChessGame game,
    String engineBestMove,
  ) {
    if (candidates.isEmpty) return engineBestMove;

    bool isOpenFile(String fileChar) {
      for (int r = 1; r <= 8; r++) {
        final p = game.getPiece('$fileChar$r');
        if (p != null && p.type == chess_lib.PieceType.PAWN) {
          return false;
        }
      }
      return true;
    }

    String bestCandidateMove = candidates.first.uciMove;
    double highestAdjustedScore = -999.0;

    final turnColor = game.turn;
    final opponentColor = turnColor == chess_lib.Color.WHITE
        ? chess_lib.Color.BLACK
        : chess_lib.Color.WHITE;

    debugPrint('--- Persona Candidate Interception (${avatar.name}) ---');

    for (final candidate in candidates) {
      if (candidate.uciMove.length < 4) continue;
      final fromSq = candidate.uciMove.substring(0, 2);
      final toSq = candidate.uciMove.substring(2, 4);

      final piece = game.getPiece(fromSq);
      final targetPiece = game.getPiece(toSq);

      double adjustedScore = candidate.evaluation;

      // Trait scoring adjustments
      if (avatar.name == 'Sparky') {
        final randomVal = (math.Random().nextDouble() * 3.0) - 1.5; // -1.5 to +1.5
        adjustedScore += randomVal;
      } else if (avatar.name == 'Pawnzy') {
        if (piece?.type == chess_lib.PieceType.PAWN) {
          adjustedScore += 1.5;
        }
      } else if (avatar.name == 'Rook-ie') {
        if (targetPiece != null) {
          // If target piece is undefended by the opponent
          if (!game.isAttacked(toSq, opponentColor)) {
            adjustedScore += 2.0;
          } else {
            adjustedScore += 0.5; // Loves capturing generally
          }
        }
      } else if (avatar.name == 'Stonewall') {
        if (piece?.type == chess_lib.PieceType.PAWN) {
          final fromRank = int.tryParse(fromSq[1]) ?? 0;
          final toRank = int.tryParse(toSq[1]) ?? 0;
          if ((toRank - fromRank).abs() <= 1) {
            adjustedScore += 0.6; // Closed short steps
          }
        } else if (targetPiece != null) {
          adjustedScore -= 0.5; // Penalize early unforced trades
        }
      } else if (avatar.name == 'Blitzer') {
        if (piece?.type == chess_lib.PieceType.KNIGHT ||
            piece?.type == chess_lib.PieceType.BISHOP) {
          adjustedScore += 0.8;
        }
        // Find opponent king's coordinate
        String? opponentKingSq;
        for (final sq in chess_lib.Chess.SQUARES.keys) {
          final p = game.getPiece(sq);
          if (p != null && p.type == chess_lib.PieceType.KING && p.color == opponentColor) {
            opponentKingSq = sq;
            break;
          }
        }
        if (opponentKingSq != null) {
          final fromFileIdx = toSq.codeUnitAt(0) - 97; // 'a'.codeUnitAt(0)
          final fromRankIdx = int.tryParse(toSq[1]) ?? 1;
          final kingFileIdx = opponentKingSq.codeUnitAt(0) - 97;
          final kingRankIdx = int.tryParse(opponentKingSq[1]) ?? 1;
          final distance = math.sqrt(math.pow(fromFileIdx - kingFileIdx, 2) + math.pow(fromRankIdx - kingRankIdx, 2));
          adjustedScore += math.max(0.0, (10.0 - distance) * 0.15); // Reward moving closer to opponent king
        }
      } else if (avatar.name == 'Gambit') {
        // Enjoys material chaos or sacrifices to open active vectors
        if (candidate.evaluation < -0.5 && (targetPiece != null || piece?.type == chess_lib.PieceType.PAWN)) {
          adjustedScore += 1.2;
        }
      } else if (avatar.name == 'Vanguard') {
        if (targetPiece != null && !game.isAttacked(toSq, opponentColor)) {
          adjustedScore += 1.5; // Highly prioritize capturing hanging pieces
        }
      } else if (avatar.name == 'Sentinel') {
        final file = toSq[0];
        final rank = toSq[1];
        final isCenterFile = file == 'c' || file == 'd' || file == 'e' || file == 'f';
        final isCenterRank = rank == '4' || rank == '5';
        if (isCenterFile && isCenterRank) {
          adjustedScore += 0.8; // Prioritize central outposts
        }
        if (piece?.type == chess_lib.PieceType.KING) {
          adjustedScore += 0.4; // Prophylactic king safety moves
        }
      } else if (avatar.name == 'Morphy') {
        final file = toSq[0];
        if ((piece?.type == chess_lib.PieceType.ROOK || piece?.type == chess_lib.PieceType.QUEEN) && isOpenFile(file)) {
          adjustedScore += 1.0; // Reward rooks and queens on open files
        }
        final moveCount = game.history.length;
        if (moveCount < 24 && (piece?.type == chess_lib.PieceType.KNIGHT || piece?.type == chess_lib.PieceType.BISHOP)) {
          adjustedScore += 0.6; // Rapid minor piece development in early game
        }
      } else if (avatar.name == 'Titan') {
        final file = toSq[0];
        final rank = toSq[1];
        final isCenterFile = file == 'd' || file == 'e';
        final isCenterRank = rank == '4' || rank == '5';
        if (isCenterFile && isCenterRank) {
          adjustedScore += 0.3; // Subtle center control positional pressure
        }
      }

      // Academy Variation Heuristics (Move 1-10)
      if (state.isAcademyActive) {
        final halfMoveCount = game.history.length;
        if (halfMoveCount < 20) {
          // Decay factor: high randomization at start, decreasing as opening progresses
          final decay = math.max(0.0, (20 - halfMoveCount) / 20.0);
          final random = math.Random();
          // Up to 5.0 points of random variance to allow "odd" but legal moves
          final randomBonus = random.nextDouble() * 5.0 * decay;

          // Subtle bonus for "odd" flank openings mentioned by user
          final isFlankMove = toSq.startsWith('a') ||
              toSq.startsWith('h') ||
              fromSq.startsWith('a') ||
              fromSq.startsWith('h');
          if (isFlankMove && candidate.evaluation > -1.5) {
            adjustedScore += 1.5 * decay;
          }

          adjustedScore += randomBonus;
        }
      }

      debugPrint(
        '  Candidate ${candidate.multipvIndex}: ${candidate.uciMove} | Base Eval: ${candidate.evaluation.toStringAsFixed(2)} | Adjusted: ${adjustedScore.toStringAsFixed(2)}',
      );

      if (adjustedScore > highestAdjustedScore) {
        highestAdjustedScore = adjustedScore;
        bestCandidateMove = candidate.uciMove;
      }
    }

    debugPrint('  Selected Persona Move: $bestCandidateMove');
    return bestCandidateMove;
  }

  void sendCommand(String command) {
    _engine.sendCommand(command);
  }

  void _refreshDashboardStats() {
    final ratedSaves = state.cachedLedgerEntries;

    // 1. Analyze Scotoma via Rust FFI
    ScotomaResult? scotoma;
    if (ratedSaves.isNotEmpty) {
      final uciGames = ratedSaves.map((s) {
        return SavedGameUci(
          recentMoves: s.recentMoves,
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
        debugPrint('Failed to run Rust analyzeScotoma: $e');
      }
    }

    // 2. Playstyle calculations
    TacticalPlaystyleStats? playstyle;
    if (ratedSaves.isNotEmpty) {
      final avgDom = ratedSaves.map((s) => s.dominance).reduce((a, b) => a + b) / ratedSaves.length;
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
        final playerTimeLeftMs = s.isPlayerWhite ? s.whiteTimeLeftMs : s.blackTimeLeftMs;
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
    } else {
      playstyle = const TacticalPlaystyleStats.empty();
    }

    // 3. Opening Repertoire calculations
    final List<OpeningRepertoireStats> openings = [];
    if (ratedSaves.isNotEmpty) {
      final Map<String, _OpeningRepertoireStatsBuilder> statsMap = {};
      for (final s in ratedSaves) {
        final op = OpeningClassifier.detectOpening(s.recentMoves, gameMode: s.gameMode);
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
        openings.add(OpeningRepertoireStats(
          name: s.name,
          plays: s.plays,
          wins: s.wins,
          draws: s.draws,
          losses: s.losses,
          playPercentage: playPercentage,
          winRate: winRate,
        ));
      }
    }

    // 4. Endgame calculations
    EndgamePerformanceStats? endgames;
    if (ratedSaves.isNotEmpty) {
      final endgameSaves = ratedSaves.where((s) => FenParser.isEndgame(s.fen)).toList();
      if (endgameSaves.isNotEmpty) {
        double totalWeightedScore = 0.0;
        double totalWeight = 0.0;

        int advantageGames = 0;
        int advantageWins = 0;

        int disadvantageGames = 0;
        int disadvantageSaves = 0; // wins + draws

        for (final s in endgameSaves) {
          final score = s.result == 'W' ? 1.0 : (s.result == 'D' ? 0.5 : 0.0);
          final balance = FenParser.calculateMaterialBalance(s.fen, s.isPlayerWhite);

          double complexity = 1.0;
          if (balance > 0) {
            complexity = 2.0; // Attacking advantage
            advantageGames++;
            if (s.result == 'W') advantageWins++;
          } else if (balance < 0) {
            complexity = 1.5; // Defensive disadvantage
            disadvantageGames++;
            if (s.result == 'W' || s.result == 'D') disadvantageSaves++;
          } else {
            complexity = 1.0; // Equal
          }

          totalWeightedScore += (score * complexity);
          totalWeight += complexity;
        }

        final double epi = totalWeight > 0 ? (totalWeightedScore / totalWeight) * 100 : 0.0;
        final double conversionRate = advantageGames > 0 ? (advantageWins / advantageGames) * 100 : 0.0;
        final double saveRate = disadvantageGames > 0 ? (disadvantageSaves / disadvantageGames) * 100 : 0.0;

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
    }

    // 5. Heatmap daily dominance metrics
    final List<double> dominanceHeatmap = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    // Group by day (ascending order: oldest first, newest last)
    final Map<String, List<double>> dailyDom = {};
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dailyDom[dateKey] = [];
    }

    for (final s in state.cachedLedgerEntries) {
      if (s.timestamp.isAfter(thirtyDaysAgo)) {
        final dateKey = '${s.timestamp.year}-${s.timestamp.month}-${s.timestamp.day}';
        if (dailyDom.containsKey(dateKey)) {
          dailyDom[dateKey]!.add(s.dominance);
        }
      }
    }

    final List<String> sortedKeys = dailyDom.keys.toList();
    for (final key in sortedKeys) {
      final doms = dailyDom[key]!;
      final avg = doms.isEmpty ? 0.0 : doms.reduce((a, b) => a + b) / doms.length;
      dominanceHeatmap.add(doms.isEmpty ? double.nan : avg);
    }

    state = state.copyWith(
      cachedScotoma: scotoma,
      cachedPlaystyle: playstyle,
      cachedOpenings: openings,
      cachedEndgames: endgames,
      cachedDominanceHeatmap: dominanceHeatmap,
    );
  }

  Future<List<SavedGameEntry>> loadSavedGames() async {
    state = state.copyWith(isSavedGamesLoading: true);
    try {
      final saves = await _savedGameRepository.listSaves();
      final ledgerEntries = await _performanceLedgerRepository.listEntries();
      state = state.copyWith(
        savedGames: saves,
        cachedLedgerEntries: ledgerEntries,
        isSavedGamesLoading: false,
      );
      _refreshDashboardStats();
      return saves;
    } catch (error, stackTrace) {
      debugPrint('Failed to load saved games: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        isSavedGamesLoading: false,
        commentaryError: 'Could not load saved games.',
      );
      return state.savedGames;
    }
  }

  Future<SavedGameEntry?> saveCurrentGame({
    String? customNameOverride,
    String? resultOverride,
    int? ratingSnapshot,
    double? dominanceSnapshot,
    String? ratingCategory,
  }) async {

    state = state.copyWith(isSavingGame: true);
    try {
      final isUpdate = state.loadedSaveId != null;
      final targetId = state.loadedSaveId ?? _uuid.v4();

      // Preserve custom name and favorite flags if updating an existing game
      String? customName;
      bool isFavorite = false;
      if (isUpdate) {
        final existing = state.savedGames
            .where((s) => s.id == targetId)
            .firstOrNull;
        if (existing != null) {
          customName = existing.customName;
          isFavorite = existing.isFavorite;
        }
      }

      // Automatically calculate results if game is over and resultOverride is null
      String? result = resultOverride;
      if (result == null && state.game.gameOver) {
        if (state.game.inCheckmate) {
          final lastMover = _playerWhoJustMoved();
          final winnerIsWhite = lastMover == 'White';
          result = (winnerIsWhite == state.isPlayerWhite) ? 'W' : 'L';
        } else if (state.game.inDraw || state.game.inStalemate) {
          result = 'D';
        }
      }
      if (result == null && state.isTimeOut) {
        final playerTimedOut = state.isPlayerWhite 
            ? state.whiteTimeLeft <= Duration.zero 
            : state.blackTimeLeft <= Duration.zero;
        result = playerTimedOut ? 'L' : 'W';
      }

      final entry = SavedGameEntry(
        id: targetId,
        savedAt: DateTime.now(),
        fen: state.game.fen,
        recentMoves: List<String>.from(state.recentMoves),
        isPlayerWhite: state.isPlayerWhite,
        isBoardFlipped: state.isBoardFlipped,
        whiteTimeLeftMs: state.whiteTimeLeft.inMilliseconds,
        blackTimeLeftMs: state.blackTimeLeft.inMilliseconds,
        clockStarted: state.clockStarted,
        activeClockSide: state.activeClockSide,
        lastMove: state.lastMove,
        commentaryHistory: state.commentaryHistory,
        customName: customNameOverride ?? customName,
        isFavorite: isFavorite,

        gameMode: state.gameMode,
        isRatedMode: state.isRatedMode,
        isAcademyActive: state.isAcademyActive,
        result: result,
        ratingSnapshot: ratingSnapshot ?? (state.isRatedMode ? _getCurrentCategoryElo() : null),
        dominanceSnapshot: dominanceSnapshot ?? (state.isRatedMode ? _getCurrentCategoryDominance() : null),
        ratingCategory: ratingCategory ?? (state.isRatedMode ? _getRatingCategory(state.baseTimeDuration, state.incrementDuration) : null),
        initialFen: state.game.initialFen,
      );

      final saves = isUpdate
          ? await _savedGameRepository.update(entry)
          : await _savedGameRepository.save(entry);

      // If update returned without modifying because save was deleted/missing, fallback to saving brand new
      List<SavedGameEntry> finalSaves = saves;
      if (isUpdate && !saves.any((s) => s.id == targetId)) {
        finalSaves = await _savedGameRepository.save(entry);
      }

      List<PerformanceLedgerEntry> updatedLedger = state.cachedLedgerEntries;
      if (entry.isRatedMode && entry.result != null) {
        final avatar = AiAvatar.getAvatar(state.engineLevel);
        final ledgerEntry = PerformanceLedgerEntry(
          id: entry.id,
          timestamp: entry.savedAt,
          ratingCategory: entry.ratingCategory ?? _getRatingCategory(state.baseTimeDuration, state.incrementDuration),
          gameMode: entry.gameMode,
          result: entry.result!,
          dominance: entry.dominanceSnapshot ?? 0.0,
          opponentName: avatar.name,
          ratingSnapshot: entry.ratingSnapshot ?? 1200,
          fen: entry.fen,
          recentMoves: List<String>.from(entry.recentMoves),
          isPlayerWhite: entry.isPlayerWhite,
          whiteTimeLeftMs: entry.whiteTimeLeftMs,
          blackTimeLeftMs: entry.blackTimeLeftMs,
        );
        updatedLedger = await _performanceLedgerRepository.addEntry(ledgerEntry);
      }

      state = state.copyWith(
        savedGames: finalSaves,
        cachedLedgerEntries: updatedLedger,
        isSavingGame: false,
        commentaryError: null,
        loadedSaveId: entry.id,
        activeRatedMatchId: (entry.isRatedMode && entry.result != null) ? null : state.activeRatedMatchId,
      );
      if (entry.isRatedMode && entry.result != null) {
        await _saveSettings();
      }
      _refreshDashboardStats();
      debugPrint('Game saved successfully: ${entry.id}');
      return entry;
    } catch (error, stackTrace) {
      debugPrint('Failed to save game: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        isSavingGame: false,
        commentaryError: 'Could not save the game.',
      );
      return null;
    }
  }

  Future<void> deleteSavedGame(String id) async {
    try {
      final saves = await _savedGameRepository.delete(id);
      state = state.copyWith(savedGames: saves);
      _refreshDashboardStats();
    } catch (error, stackTrace) {
      debugPrint('Failed to delete save: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(commentaryError: 'Could not delete the save.');
    }
  }

  Future<void> toggleFavorite(String id) async {
    final entry = state.savedGames.firstWhere((e) => e.id == id);
    final updated = entry.copyWith(isFavorite: !entry.isFavorite);
    try {
      final saves = await _savedGameRepository.update(updated);
      state = state.copyWith(savedGames: saves);
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  Future<void> renameSavedGame(String id, String newName) async {
    final entry = state.savedGames.firstWhere((e) => e.id == id);
    final updated = entry.copyWith(customName: newName);
    try {
      final saves = await _savedGameRepository.update(updated);
      state = state.copyWith(savedGames: saves);
    } catch (e) {
      debugPrint('Failed to rename game: $e');
    }
  }

  Future<void> lockGameForAnalysis(String id) async {
    final entryIndex = state.savedGames.indexWhere((e) => e.id == id);
    if (entryIndex == -1) return;
    final entry = state.savedGames[entryIndex];
    final updated = entry.copyWith(isLockedForAnalysis: true);
    try {
      final saves = await _savedGameRepository.update(updated);
      state = state.copyWith(savedGames: saves);
      _refreshDashboardStats();
    } catch (e) {
      debugPrint('Failed to lock game for analysis: $e');
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _savedGameRepository.clearAll();
      await _performanceLedgerRepository.clearAll();
      state = state.copyWith(
        savedGames: const [],
        cachedLedgerEntries: const [],
      );
      _refreshDashboardStats();
    } catch (e) {
      debugPrint('Failed to clear history: $e');
    }
  }

  void _reconstructUndoStack(SavedGameEntry entry) {
    _undoStack.clear();
    _redoStack.clear();

    final is960 = entry.gameMode == 'chess960';
    final startFen = entry.initialFen ?? (is960 ? entry.fen : chess_lib.Chess.DEFAULT_POSITION);

    final localChess = chess_lib.Chess.fromFEN(startFen);
    final List<String> currentRecentMoves = [];

    // 1. Add starting position snapshot
    _undoStack.add(_BoardSnapshot(
      fen: startFen,
      lastMove: null,
      recentMoves: const [],
      previousEvaluation: 0.0,
      currentEvaluation: 0.0,
      commentaryHistory: const [],
      isCommentaryStreaming: false,
      isCommentaryLoading: false,
      isCommentaryEngineLoading: false,
      commentaryError: null,
      isEngineThinking: false,
      hintBestMove: null,
      hintFrom: null,
      hintTo: null,
      isHintVisible: false,
      isHintLoading: false,
      isHintBlinking: false,
      isBulbGlowing: false,
      whiteTimeLeft: Duration(milliseconds: entry.whiteTimeLeftMs),
      blackTimeLeft: Duration(milliseconds: entry.blackTimeLeftMs),
      clockStarted: false,
      activeClockSide: null,
      threatenedSquares: const [],
      pendingEngineMove: null,
      engineSelectionSquare: null,
      moveAnimation: null,
      isAiOperational: state.isAiOperational,
      isAnimationsEnabled: state.isAnimationsEnabled,
      isPlayerWhite: entry.isPlayerWhite,
      isBoardFlipped: entry.isBoardFlipped,
      gameMode: entry.gameMode,
      isRatedMode: entry.isRatedMode,
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
      isPuzzleMode: false,
      currentPuzzle: null,
      puzzleMovesRemaining: const [],
      activeRatedMatchId: state.activeRatedMatchId,
    ));

    // 2. Replay all moves and add snapshots
    for (final moveSan in entry.recentMoves) {
      final success = localChess.move(moveSan);
      if (!success) continue;

      currentRecentMoves.add(moveSan);

      _undoStack.add(_BoardSnapshot(
        fen: localChess.fen,
        lastMove: moveSan,
        recentMoves: List<String>.from(currentRecentMoves),
        previousEvaluation: 0.0,
        currentEvaluation: 0.0,
        commentaryHistory: const [],
        isCommentaryStreaming: false,
        isCommentaryLoading: false,
        isCommentaryEngineLoading: false,
        commentaryError: null,
        isEngineThinking: false,
        hintBestMove: null,
        hintFrom: null,
        hintTo: null,
        isHintVisible: false,
        isHintLoading: false,
        isHintBlinking: false,
        isBulbGlowing: false,
        whiteTimeLeft: Duration(milliseconds: entry.whiteTimeLeftMs),
        blackTimeLeft: Duration(milliseconds: entry.blackTimeLeftMs),
        clockStarted: false,
        activeClockSide: null,
        threatenedSquares: const [],
        pendingEngineMove: null,
        engineSelectionSquare: null,
        moveAnimation: null,
        isAiOperational: state.isAiOperational,
        isAnimationsEnabled: state.isAnimationsEnabled,
        isPlayerWhite: entry.isPlayerWhite,
        isBoardFlipped: entry.isBoardFlipped,
        gameMode: entry.gameMode,
        isRatedMode: entry.isRatedMode,
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
        isPuzzleMode: false,
        currentPuzzle: null,
        puzzleMovesRemaining: const [],
        activeRatedMatchId: state.activeRatedMatchId,
      ));
    }

    // 3. Remove the last snapshot since it is the current state
    if (_undoStack.isNotEmpty) {
      _undoStack.removeLast();
    }
  }

  Future<void> loadSavedGame(SavedGameEntry entry) async {
    _engineMoveTimer?.cancel();
    _cancelCommentaryReveal();
    _pendingHintFen = null;
    _undoStack.clear();
    _redoStack.clear();
    _stopClock();

    final is960 = entry.gameMode == 'chess960';
    await _engine.setChess960Mode(is960);
    final restoredGame = ChessGame(fen: entry.fen, isChess960: is960);
    state = ChessState(
      game: restoredGame,
      lastMove: entry.lastMove,
      recentMoves: entry.recentMoves,
      isPlayerWhite: entry.isPlayerWhite,
      isBoardFlipped: entry.isBoardFlipped,
      commentaryHistory: entry.commentaryHistory,
      servicesStarted: state.servicesStarted,
      servicesStarting: state.servicesStarting,
      engineReady: state.engineReady,
      isCommentaryEngineLoading: _commentaryEngine.isInitializing,
      commentaryError: _commentaryEngine.lastError,
      whiteTimeLeft: Duration(milliseconds: entry.whiteTimeLeftMs),
      blackTimeLeft: Duration(milliseconds: entry.blackTimeLeftMs),
      clockStarted: entry.clockStarted,
      activeClockSide: entry.clockStarted
          ? (entry.activeClockSide ?? _clockSideForGame(restoredGame))
          : null,
      savedGames: state.savedGames,
      threatenedSquares: const [],
      // Preserve existing user interface & environment preferences
      boardThemeId: state.boardThemeId,
      isSoundEnabled: state.isSoundEnabled,
      isGameSoundEnabled: state.isGameSoundEnabled,
      isAcademySoundEnabled: state.isAcademySoundEnabled,
      isMusicEnabled: state.isMusicEnabled,
      isHapticsEnabled: state.isHapticsEnabled,
      showCoordinates: state.showCoordinates,
      isAiOperational: state.isAiOperational,
      incrementDuration: state.incrementDuration,
      baseTimeDuration: state.baseTimeDuration,
      engineLevel: state.engineLevel,
      isEngineVsEngine: state.isEngineVsEngine,
      isAnimationsEnabled: state.isAnimationsEnabled,
      animationSettings: state.animationSettings,
      soundSettings: state.soundSettings,
      academySoundSettings: state.academySoundSettings,
      loadedSaveId: entry.id,
      gameMode: entry.gameMode,
      isRatedMode: entry.isRatedMode,
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
      isAcademyActive: entry.isAcademyActive,
      userName: state.userName,
      userAvatarPath: state.userAvatarPath,
      cachedScotoma: state.cachedScotoma,
      cachedPlaystyle: state.cachedPlaystyle,
      cachedOpenings: state.cachedOpenings,
      cachedEndgames: state.cachedEndgames,
      cachedDominanceHeatmap: state.cachedDominanceHeatmap,
      cachedLedgerEntries: state.cachedLedgerEntries,
    );

    _reconstructUndoStack(entry);
    _syncUndoRedoFlags();

    if (state.clockStarted) {
      _startClockTicker();
    }

    if (_isAiTurn() && !state.game.gameOver) {
      await ensureGameServicesStarted(analyzeCurrentPosition: true);
      state = state.copyWith(isEngineThinking: state.engineReady);
    } else if (!state.game.gameOver) {
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
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

  _BoardSnapshot _captureCurrentSnapshot() {
    if (state.clockStarted) {
      final clockState = ref.read(gameClockProvider);
      state = state.copyWith(
        whiteTimeLeft: clockState.whiteTimeLeft,
        blackTimeLeft: clockState.blackTimeLeft,
      );
    }
    return _BoardSnapshot(
      fen: state.game.fen,
      lastMove: state.lastMove,
      recentMoves: List<String>.from(state.recentMoves),
      previousEvaluation: state.previousEvaluation,
      currentEvaluation: state.currentEvaluation,
      commentaryHistory: List.from(state.commentaryHistory),
      isCommentaryStreaming: state.isCommentaryStreaming,
      isCommentaryLoading: state.isCommentaryLoading,
      isCommentaryEngineLoading: state.isCommentaryEngineLoading,
      commentaryError: state.commentaryError,
      isEngineThinking: state.isEngineThinking,
      hintBestMove: state.hintBestMove,
      hintFrom: state.hintFrom,
      hintTo: state.hintTo,
      isHintVisible: state.isHintVisible,
      isHintLoading: state.isHintLoading,
      isHintBlinking: state.isHintBlinking,
      isBulbGlowing: state.isBulbGlowing,
      whiteTimeLeft: state.whiteTimeLeft,
      blackTimeLeft: state.blackTimeLeft,
      clockStarted: state.clockStarted,
      activeClockSide: state.activeClockSide,
      threatenedSquares: List<String>.from(state.threatenedSquares),
      pendingEngineMove: state.pendingEngineMove,
      engineSelectionSquare: state.engineSelectionSquare,
      moveAnimation: state.moveAnimation,
      isAiOperational: state.isAiOperational,
      isAnimationsEnabled: state.isAnimationsEnabled,
      isPlayerWhite: state.isPlayerWhite,
      isBoardFlipped: state.isBoardFlipped,
      gameMode: state.gameMode,
      isRatedMode: state.isRatedMode,
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
      isPuzzleMode: state.isPuzzleMode,
      currentPuzzle: state.currentPuzzle,
      puzzleMovesRemaining: List<String>.from(state.puzzleMovesRemaining),
      activeRatedMatchId: state.activeRatedMatchId,
    );
  }

  void _restoreSnapshot(_BoardSnapshot snapshot) {
    _cancelCommentaryReveal();
    _pendingHintFen = null;

    final is960 = snapshot.gameMode == 'chess960';
    unawaited(_engine.setChess960Mode(is960));

    state = state.copyWith(
      game: ChessGame(fen: snapshot.fen, isChess960: is960),
      lastMove: snapshot.lastMove,
      recentMoves: snapshot.recentMoves,
      previousEvaluation: snapshot.previousEvaluation,
      currentEvaluation: snapshot.currentEvaluation,
      commentaryHistory: snapshot.commentaryHistory,
      isCommentaryStreaming: snapshot.isCommentaryStreaming,
      isCommentaryLoading: snapshot.isCommentaryLoading,
      isCommentaryEngineLoading: snapshot.isCommentaryEngineLoading,
      commentaryError: snapshot.commentaryError,
      isEngineThinking: snapshot.isEngineThinking,
      analysis: const {},
      hintBestMove: snapshot.hintBestMove,
      hintFrom: snapshot.hintFrom,
      hintTo: snapshot.hintTo,
      isHintVisible: snapshot.isHintVisible,
      isHintLoading: snapshot.isHintLoading,
      isHintBlinking: snapshot.isHintBlinking,
      isBulbGlowing: snapshot.isBulbGlowing,
      whiteTimeLeft: snapshot.whiteTimeLeft,
      blackTimeLeft: snapshot.blackTimeLeft,
      clockStarted: snapshot.clockStarted,
      activeClockSide: snapshot.activeClockSide,
      threatenedSquares: snapshot.threatenedSquares,
      pendingEngineMove: snapshot.pendingEngineMove,
      engineSelectionSquare: snapshot.engineSelectionSquare,
      moveAnimation: snapshot.moveAnimation,
      isAiOperational: snapshot.isAiOperational,
      isPlayerWhite: snapshot.isPlayerWhite,
      isBoardFlipped: snapshot.isBoardFlipped,
      gameMode: snapshot.gameMode,
      isRatedMode: snapshot.isRatedMode,
      consolidatedRating: snapshot.consolidatedRating,
      bulletElo: snapshot.bulletElo,
      blitzElo: snapshot.blitzElo,
      rapidElo: snapshot.rapidElo,
      totalRatedGamesCount: snapshot.totalRatedGamesCount,
      bulletGamesClassic: snapshot.bulletGamesClassic,
      bulletGames960: snapshot.bulletGames960,
      blitzGamesClassic: snapshot.blitzGamesClassic,
      blitzGames960: snapshot.blitzGames960,
      rapidGamesClassic: snapshot.rapidGamesClassic,
      rapidGames960: snapshot.rapidGames960,
      totalWinningStreak: snapshot.totalWinningStreak,
      bulletStreak: snapshot.bulletStreak,
      blitzStreak: snapshot.blitzStreak,
      rapidStreak: snapshot.rapidStreak,
      bulletDominance: snapshot.bulletDominance,
      blitzDominance: snapshot.blitzDominance,
      rapidDominance: snapshot.rapidDominance,
      isPuzzleMode: snapshot.isPuzzleMode,
      currentPuzzle: snapshot.currentPuzzle,
      puzzleMovesRemaining: snapshot.puzzleMovesRemaining,
      activeRatedMatchId: snapshot.activeRatedMatchId,
    );
    _syncUndoRedoFlags();
    if (state.clockStarted) {
      _startClockTicker();
    } else {
      _stopClock();
    }
    if (state.servicesStarted && _isAiTurn()) {
      _startAnalysis();
    }
  }

  void _makeEngineMove(String moveStr) {
    if (moveStr.length < 4) {
      return;
    }
    final from = moveStr.substring(0, 2);
    final to = moveStr.substring(2, 4);
    final promotion = moveStr.length > 4 ? moveStr[4] : 'q';

    final piece = state.game.getPiece(from);
    final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceCode = piece != null
        ? '$colorPrefix${piece.type.toUpperCase()}'
        : 'bP';

    // Detect Castling for animation
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

    // Trigger animation before the actual move is made in the game state
    state = state.copyWith(
      moveAnimation: MoveAnimationData(
        from: from,
        to: to,
        pieceCode: pieceCode,
        rookFrom: rookFrom,
        rookTo: rookTo,
        rookPieceCode: rookPieceCode,
      ),
      engineSelectionSquare: null, // Clear selection when move starts
    );

    _saveSnapshotForUndo();
    _clearHint();
    final moveMade = state.game.makeMove({
      'from': from,
      'to': to,
      'promotion': promotion,
    });
    if (moveMade) {
      final wasClockStarted = state.clockStarted;
      _onMoveCompleted('$from$to');

      if (!wasClockStarted) {
        state = state.copyWith(clockStarted: true);
      }

      _setActiveClockSide(_clockSideForTurn());
      _startClockTicker();

      // Always trigger analysis after an engine move to get the score for commentary
      if (!state.game.gameOver) {
        unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
      }
    }
  }

  bool _isWhite(Object? color) {
    if (color == null) return false;
    final s = color.toString().toLowerCase();
    return s == 'white' || s == 'w' || s.contains('white');
  }

  bool _isBlack(Object? color) {
    if (color == null) return false;
    final s = color.toString().toLowerCase();
    return s == 'black' || s == 'b' || s.contains('black');
  }

  // Public version for UI
  bool isWhite(Object? color) => _isWhite(color);
  bool isBlack(Object? color) => _isBlack(color);

  void clearMoveAnimation() {
    state = state.copyWith(moveAnimation: null);
  }

  bool _isPlayerTurn() {
    final turn = state.game.turn;
    if (state.isPlayerWhite) {
      return turn == chess_lib.Color.WHITE;
    } else {
      return turn == chess_lib.Color.BLACK;
    }
  }

  bool _isAiTurn() {
    if (state.game.gameOver || state.isPaused) return false;

    // If auto-play is enabled, it's always the AI's turn to move if it's not paused
    if (state.isEngineVsEngine) return true;

    final turn = state.game.turn;
    if (state.isPlayerWhite) {
      return turn == chess_lib.Color.BLACK;
    } else {
      return turn == chess_lib.Color.WHITE;
    }
  }

  String _playerWhoJustMoved() {
    // If it's now White's turn, Black just moved.
    return state.game.turn == chess_lib.Color.WHITE ? 'Black' : 'White';
  }

  Future<void> startPuzzleMode({bool silent = false}) async {
    state = state.copyWith(isPuzzleMode: true);
    await nextPuzzle(silent: silent);
  }

  Future<void> exitPuzzleMode() async {
    state = state.copyWith(
      isPuzzleMode: false,
      currentPuzzle: null,
      puzzleMovesRemaining: const [],
    );
    await reset();
  }

  Future<void> nextPuzzle({bool silent = false}) async {
    if (!state.isPuzzleMode) return;
    
    debugPrint('ChessNotifier: Requesting next puzzle...');
    try {
      final puzzle = await _puzzleRepository.getRandomPuzzle();
      if (puzzle != null) {
        debugPrint('ChessNotifier: Loading puzzle #${puzzle.id}');
        await loadPuzzle(puzzle, silent: silent);
      } else {
        debugPrint('ChessNotifier: Puzzle repository returned null');
        state = state.copyWith(
          commentaryError: 'Could not fetch a puzzle from the archives.',
        );
      }
    } catch (e) {
      debugPrint('ChessNotifier: Failed to get next puzzle: $e');
      state = state.copyWith(
        commentaryError: 'An error occurred while fetching a puzzle.',
      );
    }
  }

  Future<void> loadPuzzle(rust_puzzles.Puzzle puzzle, {bool silent = false}) async {
    _engineMoveTimer?.cancel();
    _cancelCommentaryReveal();
    _pendingHintFen = null;
    _undoStack.clear();
    _redoStack.clear();
    _stopClock();

    final restoredGame = ChessGame(fen: puzzle.fen, isChess960: false);
    
    final baseTurn = restoredGame.turn;
    final isPlayerWhite = baseTurn == chess_lib.Color.BLACK;

    final List<String> remainingMoves = List<String>.from(puzzle.moves);
    String? initialMove;
    if (remainingMoves.isNotEmpty) {
      initialMove = remainingMoves.removeAt(0);
    }

    state = ChessState(
      game: restoredGame,
      isPlayerWhite: isPlayerWhite,
      isBoardFlipped: !isPlayerWhite,
      isPuzzleMode: true,
      currentPuzzle: puzzle,
      puzzleMovesRemaining: remainingMoves,
      boardThemeId: state.boardThemeId,
      isSoundEnabled: state.isSoundEnabled,
      isGameSoundEnabled: state.isGameSoundEnabled,
      isAcademySoundEnabled: state.isAcademySoundEnabled,
      isMusicEnabled: state.isMusicEnabled,
      isHapticsEnabled: state.isHapticsEnabled,
      showCoordinates: state.showCoordinates,
      isAnimationsEnabled: state.isAnimationsEnabled,
      animationSettings: state.animationSettings,
      soundSettings: state.soundSettings,
      academySoundSettings: state.academySoundSettings,
      gameMode: 'classic',
      isRatedMode: false,
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
      userName: state.userName,
      userAvatarPath: state.userAvatarPath,
      cachedScotoma: state.cachedScotoma,
      cachedPlaystyle: state.cachedPlaystyle,
      cachedOpenings: state.cachedOpenings,
      cachedEndgames: state.cachedEndgames,
      cachedDominanceHeatmap: state.cachedDominanceHeatmap,
      cachedLedgerEntries: state.cachedLedgerEntries,
    );

    _syncUndoRedoFlags();

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

    if (state.isPuzzleMode) {
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
          
          if (state.isHapticsEnabled) {
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
        if (state.isHapticsEnabled) {
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
      return;
    }

    // 1. Handle branching from history viewing
    if (state.viewingMoveIndex != null) {
      _truncateToViewingIndex();
    }

    // 2. Handle branching from Undo/Redo stack
    if (_redoStack.isNotEmpty) {
      _redoStack.clear();
      _syncUndoRedoFlags();
    }

    if (state.isPaused) {
      // Auto-resume on user move
      state = state.copyWith(isPaused: false);
      if (state.clockStarted) {
        _startClockTicker();
      }
    }

    if (!_isPlayerTurn() && !state.isEngineVsEngine) {
      debugPrint('ChessNotifier: Not player turn. Ignoring move.');
      return;
    }

    final piece = state.game.getPiece(from);
    final colorPrefix = piece?.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceCode = piece != null
        ? '$colorPrefix${piece.type.toUpperCase()}'
        : 'wP';

    _saveSnapshotForUndo();
    _clearHint();

    // Detect Promotion
    final isPawn = piece?.type.toUpperCase() == 'P';
    final targetRank = to.substring(1);
    final isPromotionRank =
        (piece?.color == chess_lib.Color.WHITE && targetRank == '8') ||
        (piece?.color == chess_lib.Color.BLACK && targetRank == '1');

    if (isPawn && isPromotionRank) {
      state = state.copyWith(
        isPromoting: true,
        promotionSource: from,
        promotionDestination: to,
        moveAnimation: null, // Don't animate until piece is chosen
      );
      return;
    }

    final targetPiece = state.game.getPiece(to);
    final isCapture = targetPiece != null;

    // Detect Castling for animation
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

    // Trigger animation
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
      state = state.copyWith(
        moveAnimation: null,
      ); // Revert animation if move failed
      if (state.isHapticsEnabled) {
        _hapticsService.errorFeedback();
      }
      return;
    }

    final wasClockStarted = state.clockStarted;
    _onMoveCompleted('$from$to');

    if (!wasClockStarted) {
      state = state.copyWith(clockStarted: true);
    }

    _setActiveClockSide(_clockSideForTurn());
    _startClockTicker();

    // The Scout (Stockfish) starts its calculation
    // debugPrint(
    //   'ChessNotifier: Player move completed. Starting engine analysis...',
    // );
    await ensureGameServicesStarted(analyzeCurrentPosition: true);
    // debugPrint(
    //   'ChessNotifier: Engine analysis requested for FEN: ${state.game.fen}',
    // );

    state = state.copyWith(isEngineThinking: state.engineReady);
  }

  void _startAnalysis({int? depth}) {
    if (_isDisposed) return;

    bool isBottomTurn = false;
    final fenParts = state.game.fen.split(' ');
    if (fenParts.length > 1) {
      final turnWhite = fenParts[1] == 'w';
      isBottomTurn = (state.isPlayerWhite == turnWhite);
    }

    final activeAvatarId = (state.isEngineVsEngine && isBottomTurn)
        ? state.bottomAvatarId
        : state.engineLevel;

    final avatar = AiAvatar.getAvatar(activeAvatarId);
    final targetDepth = depth ?? avatar.depth;

    // Dynamically apply current moving engine's skill level constraints
    _currentCandidates.clear();
    _engine.setSkillLevel(
      avatar.skillLevel,
      multiPV: state.isAcademyActive ? 3 : (avatar.name == 'Kingslayer' ? 1 : 4),
    );

    // Record start time for the 2s minimum delay logic
    _engineStartTime = DateTime.now();

    // Cancel any existing max thinking timer
    _maxThinkingTimer?.cancel();
    _maxThinkingTimer = null;

    // Only force move (10s timeout) if it's the AI's turn to respond
    if (_isAiTurn()) {
      _maxThinkingTimer = Timer(const Duration(seconds: 10), () {
        _engine.sendCommand('stop');
      });
    }

    try {
      _engine.analyzePosition(state.game.fen, depth: targetDepth);
    } catch (e) {
      debugPrint('ChessNotifier: Failed to trigger engine analysis: $e');
    }
  }

  Future<void> switchSides() async {
    _undoStack.clear();
    _redoStack.clear();
    _cancelCommentaryReveal();
    _pendingHintFen = null;
    _stopClock();

    final newIsPlayerWhite = !state.isPlayerWhite;
    final newGame = state.isChess960
        ? ChessGame(
            fen: Chess960Generator.generateRandomPosition().fen,
            isChess960: true,
          )
        : ChessGame(isChess960: false);

    state = state.copyWith(
      game: newGame,
      isPlayerWhite: newIsPlayerWhite,
      isBoardFlipped: !newIsPlayerWhite,
      isEngineThinking: !newIsPlayerWhite && state.servicesStarted,
      servicesStarted: state.servicesStarted,
      servicesStarting: state.servicesStarting,
      engineReady: state.engineReady,
      isCommentaryEngineLoading: _commentaryEngine.isInitializing,
      commentaryError: _commentaryEngine.lastError,
      whiteTimeLeft: state.baseTimeDuration,
      blackTimeLeft: state.baseTimeDuration,
      savedGames: state.savedGames,
      threatenedSquares: const [],
      isPromoting: false,
      isTimeOut: false,
    );

    _syncUndoRedoFlags();
    if (!newIsPlayerWhite) {
      await ensureGameServicesStarted(analyzeCurrentPosition: true);
      state = state.copyWith(isEngineThinking: state.engineReady);
    }
  }

  void toggleBoardOrientation() {
    final newFlipped = !state.isBoardFlipped;
    final newIsPlayerWhite =
        !state.isPlayerWhite; // Always toggle to maintain "Down = User"

    // debugPrint(
    //   'ChessNotifier: Rotation triggered. Switching player to ${newIsPlayerWhite ? 'White' : 'Black'} to maintain Down=User.',
    // );

    state = state.copyWith(
      isBoardFlipped: newFlipped,
      isPlayerWhite: newIsPlayerWhite,
      threatenedSquares: const [], // Clear visual noise during rotation
    );

    // Auto-move on rotation if it's now the engine's turn
    if (_isAiTurn() && !state.game.gameOver) {
      // debugPrint('ChessNotifier: Rotation triggered engine analysis.');
      unawaited(ensureGameServicesStarted(analyzeCurrentPosition: true));
    }
  }

  Future<void> toggleEngineVsEngine() async {
    if (state.isRatedMode) return;
    final newVal = !state.isEngineVsEngine;
    state = state.copyWith(isEngineVsEngine: newVal);

    if (newVal && !state.game.gameOver && !state.isPaused) {
      // Start the clock if not already started when enabling auto-play
      if (!state.clockStarted) {
        state = state.copyWith(clockStarted: true);
        _startClockTicker();
      }

      await ensureGameServicesStarted(analyzeCurrentPosition: true);
      state = state.copyWith(isEngineThinking: state.engineReady);
    }
  }

  Future<void> setEngineLevel(String level) async {
    if (state.isRatedMode) return; // Prevent manual change in rated mode
    final avatar = AiAvatar.getAvatar(level);
    state = state.copyWith(engineLevel: level);

    await _engine.setSkillLevel(
      avatar.skillLevel,
      multiPV: avatar.name == 'Kingslayer' ? 1 : 4,
    );
    _saveSettings();
    if (state.servicesStarted && _isAiTurn()) {
      _currentCandidates.clear();
      _engine.analyzePosition(state.game.fen, depth: avatar.depth);
    }
  }

  void _autoSelectRatedOpponent() {
    final bestMatch = AiAvatar.getBestMatch(state.consolidatedRating);
    debugPrint('Auto-selecting rated opponent for ELO ${state.consolidatedRating}: ${bestMatch.name} (${bestMatch.id})');
    state = state.copyWith(engineLevel: bestMatch.id);
  }

  Future<void> setBottomAvatarId(String level) async {
    final avatar = AiAvatar.getAvatar(level);
    state = state.copyWith(bottomAvatarId: level);

    _saveSettings();
    // If auto-play is ongoing and it's the bottom engine's turn, update immediately
    if (state.servicesStarted && state.isEngineVsEngine) {
      bool isBottomTurn = false;
      final fenParts = state.game.fen.split(' ');
      if (fenParts.length > 1) {
        final turnWhite = fenParts[1] == 'w';
        isBottomTurn = (state.isPlayerWhite == turnWhite);
      }
      if (isBottomTurn) {
        await _engine.setSkillLevel(
          avatar.skillLevel,
          multiPV: avatar.name == 'Kingslayer' ? 1 : 4,
        );
        _currentCandidates.clear();
        _engine.analyzePosition(state.game.fen, depth: avatar.depth);
      }
    }
  }

  Future<void> updateProfile({required String name, required String avatarPath}) async {
    state = state.copyWith(
      userName: name,
      userAvatarPath: avatarPath,
    );
    await _saveSettings();
  }

  Future<void> requestHint() async {
    if (state.game.gameOver || state.isHintLoading || state.isEngineThinking) {
      return;
    }

    _cancelCommentaryReveal();

    if (state.isPuzzleMode) {
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
      return;
    }

    _pendingHintFen = state.game.fen;
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
    await ensureGameServicesStarted();
    if (state.engineReady) {
      // Analyze for a quick hint
      _engine.analyzePosition(state.game.fen, depth: 14);
    }
  }

  void clearHint() {
    _clearHint();
  }

  void completePromotion(String promotionPiece) async {
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

    final targetPiece = state.game.getPiece(to);
    final isCapture = targetPiece != null;

    state = state.copyWith(
      isPromoting: false,
      promotionSource: null,
      promotionDestination: null,
      moveAnimation: MoveAnimationData(
        from: from,
        to: to,
        pieceCode: pieceCode,
        isCapture: isCapture,
      ),
    );

    final moveMade = state.game.makeMove({
      'from': from,
      'to': to,
      'promotion': promotionPiece,
    });

    if (!moveMade) {
      state = state.copyWith(moveAnimation: null);
      return;
    }

    final wasClockStarted = state.clockStarted;
    _onMoveCompleted('$from$to');

    if (!wasClockStarted) {
      state = state.copyWith(clockStarted: true);
    }

    _setActiveClockSide(_clockSideForTurn());
    _startClockTicker();

    await ensureGameServicesStarted(analyzeCurrentPosition: true);

    state = state.copyWith(isEngineThinking: state.engineReady);
  }

  void _onMoveCompleted(String lastMove) {
    if (state.clockStarted) {
      final clockState = ref.read(gameClockProvider);
      state = state.copyWith(
        whiteTimeLeft: clockState.whiteTimeLeft,
        blackTimeLeft: clockState.blackTimeLeft,
      );
    }

    final updatedMoves = state.game.moveHistoryLabels();
    final move = _lastMoveFromHistory();

    final player = _playerWhoJustMoved();

    // Apply Clock Increment
    if (state.clockStarted && !state.game.gameOver) {
      final isWhite = player == 'White';
      ref.read(gameClockProvider.notifier).applyIncrement(state.incrementDuration, isWhite);
      if (isWhite) {
        state = state.copyWith(
          whiteTimeLeft: state.whiteTimeLeft + state.incrementDuration,
        );
      } else {
        state = state.copyWith(
          blackTimeLeft: state.blackTimeLeft + state.incrementDuration,
        );
      }
    }

    // Professional Haptics
    if (state.isHapticsEnabled) {
      if (state.game.inCheckmate) {
        _hapticsService.mateBurst();
      } else if (state.game.inCheck) {
        _hapticsService.checkPulse();
      } else if (move?.captured != null) {
        _hapticsService.heavyRook();
      } else {
        _hapticsService.softTap();
      }
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
      game: state.game, // Maintain the same instance to preserve history
      lastMove: lastMove,
      recentMoves: updatedMoves,
      previousEvaluation: state.currentEvaluation,
      isEngineThinking:
          _isAiTurn() && state.servicesStarted && state.engineReady,
      commentaryError: null,
      activeClockSide: state.clockStarted
          ? _clockSideForTurn()
          : state.activeClockSide,
      threatenedSquares: threatened,
      chanakyaSuggestion: null,
    );

    if (state.game.gameOver) {
      if (state.game.inCheckmate) {
        unawaited(_soundService.duckBgmTemporarily());
      }
      
      bool isDraw = state.game.inDraw || state.game.inStalemate;
      if (isDraw) {
        _soundService.playSfx(SoundEffect.draw);
      } else {
        final winnerIsWhite = player == 'White';
        final humanWon = winnerIsWhite == state.isPlayerWhite;
        if (humanWon) {
          _soundService.playSfx(SoundEffect.victory);
        } else {
          _soundService.playSfx(SoundEffect.defeat);
        }
      }
    } else if (state.game.inCheck) {
      _soundService.playSfx(SoundEffect.check);
    } else {
      _playMoveSound();
    }
    _applyRatedRatingAdjustments(player);

    if (state.isRatedMode) {
      if (state.game.gameOver) {
        state = state.copyWith(activeRatedMatchId: null);
        _saveSettings();
        
        String? result;
        if (state.game.inCheckmate) {
          final winnerIsWhite = player == 'White';
          final humanWon = winnerIsWhite == state.isPlayerWhite;
          result = humanWon ? 'W' : 'L';
        } else if (state.game.inDraw || state.game.inStalemate) {
          result = 'D';
        }
        saveCurrentGame(resultOverride: result);
      } else {
        if (state.activeRatedMatchId == null) {
          state = state.copyWith(activeRatedMatchId: state.loadedSaveId ?? _uuid.v4());
          _saveSettings();
        }
      }
    }
  }

  void _applyRatedRatingAdjustments(String player) {
    // Perform Elo rating adjustments if match concluded in Rated Mode
    if (state.isRatedMode && !state.isEngineVsEngine && state.game.gameOver) {
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

  Future<void> _updateRating(double actualScore) async {
    final category = _getRatingCategory(state.baseTimeDuration, state.incrementDuration);
    final is960 = state.gameMode == 'chess960';
    final avatar = AiAvatar.getAvatar(state.engineLevel);
    
    // 1. Update Specific Tiered Rating
    int currentSpecificElo = 1200;
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

    final specificKFactor = currentSpecificCount < 10 ? 40 : 20;
    final expectedSpecificScore = 1.0 / (1.0 + math.pow(10.0, (avatar.rating - currentSpecificElo) / 400.0));
    
    int newSpecificStreak = actualScore == 1.0 ? currentSpecificStreak + 1 : (actualScore == 0.0 ? 0 : currentSpecificStreak);
    int specificStreakBonus = (actualScore == 1.0 && newSpecificStreak >= 3) ? 5 : 0;
    
    final newSpecificEloRaw = currentSpecificElo + (specificKFactor * (actualScore - expectedSpecificScore)).round() + specificStreakBonus;
    final newSpecificElo = math.max(400, newSpecificEloRaw);

    // 2. Update Consolidated Rating
    final consolidatedKFactor = state.totalRatedGamesCount < 10 ? 40 : 20;
    final expectedConsolidatedScore = 1.0 / (1.0 + math.pow(10.0, (avatar.rating - state.consolidatedRating) / 400.0));
    
    int newConsolidatedStreak = actualScore == 1.0 ? state.totalWinningStreak + 1 : (actualScore == 0.0 ? 0 : state.totalWinningStreak);
    int consolidatedStreakBonus = (actualScore == 1.0 && newConsolidatedStreak >= 3) ? 5 : 0;
    
    final newConsolidatedEloRaw = state.consolidatedRating + (consolidatedKFactor * (actualScore - expectedConsolidatedScore)).round() + consolidatedStreakBonus;
    final newConsolidatedElo = math.max(400, newConsolidatedEloRaw);

    // 3. Update Dominance Index (Material Margin Average)
    final currentMargin = state.game.calculateMaterialMargin(
      state.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK
    );
    
    double newBulletDom = state.bulletDominance;
    double newBlitzDom = state.blitzDominance;
    double newRapidDom = state.rapidDominance;
    
    if (category == 'bullet') {
      final count = state.bulletGamesClassic + state.bulletGames960;
      newBulletDom = ((state.bulletDominance * count) + currentMargin) / (count + 1);
    } else if (category == 'blitz') {
      final count = state.blitzGamesClassic + state.blitzGames960;
      newBlitzDom = ((state.blitzDominance * count) + currentMargin) / (count + 1);
    } else {
      final count = state.rapidGamesClassic + state.rapidGames960;
      newRapidDom = ((state.rapidDominance * count) + currentMargin) / (count + 1);
    }

    // 4. Prepare State Update
    final newTotalCount = state.totalRatedGamesCount + 1;
    
    state = state.copyWith(
      consolidatedRating: newConsolidatedElo,
      totalRatedGamesCount: newTotalCount,
      totalWinningStreak: newConsolidatedStreak,
      bulletElo: category == 'bullet' ? newSpecificElo : state.bulletElo,
      bulletStreak: category == 'bullet' ? newSpecificStreak : state.bulletStreak,
      bulletGamesClassic: (category == 'bullet' && !is960) ? state.bulletGamesClassic + 1 : state.bulletGamesClassic,
      bulletGames960: (category == 'bullet' && is960) ? state.bulletGames960 + 1 : state.bulletGames960,
      bulletDominance: newBulletDom,
      
      blitzElo: category == 'blitz' ? newSpecificElo : state.blitzElo,
      blitzStreak: category == 'blitz' ? newSpecificStreak : state.blitzStreak,
      blitzGamesClassic: (category == 'blitz' && !is960) ? state.blitzGamesClassic + 1 : state.blitzGamesClassic,
      blitzGames960: (category == 'blitz' && is960) ? state.blitzGames960 + 1 : state.blitzGames960,
      blitzDominance: newBlitzDom,
      
      rapidElo: category == 'rapid' ? newSpecificElo : state.rapidElo,
      rapidStreak: category == 'rapid' ? newSpecificStreak : state.rapidStreak,
      rapidGamesClassic: (category == 'rapid' && !is960) ? state.rapidGamesClassic + 1 : state.rapidGamesClassic,
      rapidGames960: (category == 'rapid' && is960) ? state.rapidGames960 + 1 : state.rapidGames960,
      rapidDominance: newRapidDom,
    );

    await _saveSettings();
  }

  Future<void> resignRatedGame() async {
    if (!state.isRatedMode) return;

    // 1. Mark as Loss in rating
    await _updateRating(0.0); // 0.0 = Loss

    // 2. Save game to history as "Resigned"
    await saveCurrentGame(
      customNameOverride: 'Rated Loss (Resigned)',
      resultOverride: 'L',
    );

    // 3. Reset the game
    await reset(skipAutoSave: true);
  }

  int _getCurrentCategoryElo() {
    final category = _getRatingCategory(state.baseTimeDuration, state.incrementDuration);
    if (category == 'bullet') return state.bulletElo;
    if (category == 'blitz') return state.blitzElo;
    return state.rapidElo;
  }

  double _getCurrentCategoryDominance() {
    final category = _getRatingCategory(state.baseTimeDuration, state.incrementDuration);
    if (category == 'bullet') return state.bulletDominance;
    if (category == 'blitz') return state.blitzDominance;
    return state.rapidDominance;
  }

  chess_lib.Move? _lastMoveFromHistory() {
    final history = state.game.history;
    if (history.isEmpty) return null;
    final lastState = history.last;
    return lastState.move as chess_lib.Move?;
  }

  void _playMoveSound() {
    final lastMove = _lastMoveFromHistory();

    if (lastMove == null) return;

    // Check for promotion first
    if (lastMove.promotion != null) {
      _soundService.playSfx(SoundEffect.promote);
      return;
    }

    // 1. Check for capture
    bool isCapture = lastMove.captured != null;

    if (isCapture) {
      _soundService.playCapture();
      return;
    }

    // 2. Identify piece type for move sound
    final piece = lastMove.piece; // Piece type that moved
    final type = piece.toString().toLowerCase();

    // Check for castling (King moving 2 squares horizontally)
    bool isCastle = false;
    if (type == 'k') {
      final fromFile = lastMove.from % 8;
      final toFile = lastMove.to % 8;
      if ((fromFile - toFile).abs() == 2) {
        isCastle = true;
      }
    }

    if (isCastle) {
      _soundService.playSfx(SoundEffect.castle);
    } else if (type == 'k') {
      _soundService.playKingMove();
    } else if (type == 'p') {
      _soundService.playPawnMove();
    } else {
      _soundService.playWhoosh();
    }
  }

  void playNotify() {
    _soundService.playNotify();
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

  Future<void> sendUserQuery(String query) async {
    if (query.trim().isEmpty) return;

    final userEntry = CommentaryEntry(
      text: query,
      timestamp: DateTime.now(),
      isUser: true,
    );

    state = state.copyWith(
      commentaryHistory: [...state.commentaryHistory, userEntry],
      commentaryError: null,
      chanakyaSuggestion: null,
    );

    await _runCommentary(
      player: _playerWhoJustMoved(),
      move: _formatMoveForPrompt(state.lastMove ?? 'Opening'),
      evalScore: _formatEvalForPrompt(state.currentEvaluation),
      userQuery: query,
    );
  }

  Future<void> _runCommentary({
    required String player,
    required String move,
    required String evalScore,
    String? userQuery,
    bool revealHintAfterTyping = false,
    bool isNested = false,
  }) async {
    _cancelCommentaryReveal();

    final newEntry = CommentaryEntry(
      text: '',
      timestamp: DateTime.now(),
      isComplete: false,
      isUser: false,
    );

    // Update state IMMEDIATELY to show "Thinking"
    state = state.copyWith(
      commentaryHistory: [...state.commentaryHistory, newEntry],
      isCommentaryLoading: true,
      isCommentaryStreaming: false,
    );

    _soundService.playSfx(SoundEffect.gmchanakyaThinking);

    try {
      // 1. Wait briefly for a fresh evaluation if it's the start of a turn
      if (!isNested) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      String? structuredPrompt;
      try {
        final bestMove = state.analysis['bestMove'] as String?;
        final pvRaw = state.analysis['pv'];
        final List<String> pv = pvRaw is List ? List<String>.from(pvRaw) : [];

        structuredPrompt = _aiContextService.generateCommentaryPrompt(
          move: move,
          currentEval: state.currentEvaluation,
          previousEval: state.previousEvaluation,
          game: state.game,
          bestMove: bestMove,
          pvLine: pv,
          chatHistory: state.commentaryHistory,
          candidates: _currentCandidates,
          userQuery: userQuery,
          systemInstructionOverride: _commentaryEngine.systemInstruction,
        );
      } catch (e) {
        debugPrint('KingSlayer: Context injection failed: $e');
      }

      final stream = _commentaryEngine.generateCommentaryStream(
        player: player,
        move: move,
        evalScore: evalScore,
        structuredPrompt: structuredPrompt,
        userQuery: userQuery,
      );

      await for (final chunk in stream) {
        if (_isDisposed) break;

        final updatedHistory = List<CommentaryEntry>.from(
          state.commentaryHistory,
        );
        if (updatedHistory.isNotEmpty) {
          updatedHistory[updatedHistory.length - 1] = updatedHistory.last
              .copyWith(text: chunk);
        }

        state = state.copyWith(
          commentaryHistory: updatedHistory,
          isCommentaryLoading: false,
          isCommentaryStreaming: true,
        );

        _soundService.playWriting();

        if (state.academyHouseAnimations) {
          _extractMoveSuggestion(chunk);
        }
      }

      if (!_isDisposed) {
        // Mark current commentary as complete
        final finalHistory = List<CommentaryEntry>.from(
          state.commentaryHistory,
        );
        if (finalHistory.isNotEmpty) {
          finalHistory[finalHistory.length - 1] = finalHistory.last.copyWith(
            isComplete: true,
          );
        }
        state = state.copyWith(
          commentaryHistory: finalHistory,
          isCommentaryStreaming: false,
        );

        _soundService.playSfx(SoundEffect.gmchanakyaComplete);

        // --- NO AUTOMATIC ORCHESTRATION ---
        // The High Council (AI) only reveals its intelligence when asked.
        // It no longer gates the S-engine (Stockfish) moves.

        if (revealHintAfterTyping &&
            state.hintFrom != null &&
            state.hintTo != null) {
          state = state.copyWith(isHintVisible: true, isHintLoading: false);
        }
      }
    } catch (e) {
      debugPrint('KingSlayer: AI sequence failed: $e');
      if (!_isDisposed) {
        state = state.copyWith(isCommentaryLoading: false);
        // Fallback: Reveal robot move if AI failed
        if (state.pendingEngineMove != null) {
          final engineMove = state.pendingEngineMove!;
          state = state.copyWith(pendingEngineMove: null);
          _makeEngineMove(engineMove);
        }
      }
    } finally {
      if (!_isDisposed && !isNested) {
        state = state.copyWith(isCommentaryLoading: false);

        // Robot Mode Continuity removed.
        // The AI now only speaks when the user chats or requests a hint.
      }
    }
  }

  void _cancelCommentaryReveal() {
    _commentaryRevealTimer?.cancel();
    _commentaryRevealTimer = null;
  }

  void _clearHint() {
    _pendingHintFen = null;
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

  void _syncTimesToClockProvider() {
    ref.read(gameClockProvider.notifier).setClock(
      whiteTime: state.whiteTimeLeft,
      blackTime: state.blackTimeLeft,
      started: state.clockStarted,
      activeSide: state.activeClockSide,
      timeOut: state.isTimeOut,
    );
  }

  void handleClockTimeout(String side) {
    _handleClockTimeout(side);
  }

  void _startClockTicker() {
    ref.read(gameClockProvider.notifier).setClock(
      whiteTime: state.whiteTimeLeft,
      blackTime: state.blackTimeLeft,
      started: true,
      activeSide: state.activeClockSide ?? _clockSideForTurn(),
      timeOut: state.isTimeOut,
    );
    if (!state.clockStarted || state.activeClockSide == null) {
      state = state.copyWith(
        clockStarted: true,
        activeClockSide: state.activeClockSide ?? _clockSideForTurn(),
      );
    }
  }

  void _setActiveClockSide(String? side) {
    if (!state.clockStarted || side == null || state.game.gameOver) {
      state = state.copyWith(activeClockSide: null);
      _stopClock();
      return;
    }
    state = state.copyWith(activeClockSide: side);
    ref.read(gameClockProvider.notifier).setActiveSide(side);
  }

  void _handleClockTimeout(String side) {
    _stopClock();
    
    // Determine the result for the player
    double actualScore = 0.5; // Default to draw (unlikely in timeout but safe)
    if (state.isRatedMode) {
      final timedOutSideIsWhite = side == _clockWhite;
      final playerIsWhite = state.isPlayerWhite;
      
      // If player is the side that timed out, they lose. If opponent timed out, player wins.
      actualScore = (playerIsWhite == timedOutSideIsWhite) ? 0.0 : 1.0;
      _updateRating(actualScore);
    }

    state = state.copyWith(
      whiteTimeLeft: side == _clockWhite ? Duration.zero : state.whiteTimeLeft,
      blackTimeLeft: side == _clockBlack ? Duration.zero : state.blackTimeLeft,
      clockStarted: false,
      activeClockSide: null,
      isEngineThinking: false,
      isTimeOut: true,
      commentaryError: side == _clockWhite
          ? 'White ran out of time.'
          : 'Black ran out of time.',
    );

    String? result;
    if (state.isRatedMode) {
      final timedOutSideIsWhite = side == _clockWhite;
      final playerIsWhite = state.isPlayerWhite;
      result = (playerIsWhite == timedOutSideIsWhite) ? 'L' : 'W';
      
      state = state.copyWith(activeRatedMatchId: null);
      _saveSettings();
      
      saveCurrentGame(resultOverride: result);
    }

    final timedOutSideIsWhite = side == _clockWhite;
    final playerIsWhite = state.isPlayerWhite;
    final humanWon = playerIsWhite != timedOutSideIsWhite;
    _soundService.playSfx(humanWon ? SoundEffect.victory : SoundEffect.defeat);
  }

  void _stopClock() {
    final clockState = ref.read(gameClockProvider);
    ref.read(gameClockProvider.notifier).stopClock();
    state = state.copyWith(
      whiteTimeLeft: clockState.whiteTimeLeft,
      blackTimeLeft: clockState.blackTimeLeft,
      clockStarted: false,
    );
  }

  String _clockSideForTurn() {
    return state.game.turn == chess_lib.Color.WHITE ? _clockWhite : _clockBlack;
  }

  String _clockSideForGame(ChessGame game) {
    return game.turn == chess_lib.Color.WHITE ? _clockWhite : _clockBlack;
  }

  String _formatMoveForPrompt(String move) {
    if (move.length < 4) {
      return move;
    }
    final from = move.substring(0, 2);
    final to = move.substring(2, 4);
    final promotion = move.length > 4
        ? '=${move.substring(4).toUpperCase()}'
        : '';
    return '$from-$to$promotion';
  }

  String _formatEvalForPrompt(double eval) {
    if (eval >= 90) {
      return '+M';
    }
    if (eval <= -90) {
      return '-M';
    }
    final formatted = eval.toStringAsFixed(1);
    return eval > 0 ? '+$formatted' : formatted;
  }

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }

    // 1. Always pause when navigating history to prevent engine interference
    if (!state.isPaused) {
      state = state.copyWith(isPaused: true);
      _stopClock();
      _engineMoveTimer?.cancel();
    }

    // 2. Full-turn undo logic:
    // If it is the player's turn, it means the engine has already responded to the player's last move.
    // To make "Undo" meaningful for the player, we should undo both the engine move and the player move.
    bool shouldUndoTwice =
        _isPlayerTurn() &&
        _undoStack.length >= 2 &&
        !state.game.gameOver &&
        !state.isEngineVsEngine;

    // First undo (Engine's move)
    _redoStack.add(_captureCurrentSnapshot());
    final snapshot = _undoStack.removeLast();
    _restoreSnapshot(snapshot);

    // Second undo (Player's move)
    if (shouldUndoTwice && _undoStack.isNotEmpty) {
      _redoStack.add(_captureCurrentSnapshot());
      final snapshot2 = _undoStack.removeLast();
      _restoreSnapshot(snapshot2);
    }

    _syncUndoRedoFlags();
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }

    // Keep game paused during history review
    if (!state.isPaused) {
      state = state.copyWith(isPaused: true);
      _stopClock();
      _engineMoveTimer?.cancel();
    }

    _undoStack.add(_captureCurrentSnapshot());
    final snapshot = _redoStack.removeLast();
    _restoreSnapshot(snapshot);
    _syncUndoRedoFlags();
  }

  Future<void> reset({bool? forcedPlayerWhite, bool skipAutoSave = false}) async {
    if (state.isAcademyActive) {
      await _cancelEngineSubscriptions();
      state = state.copyWith(servicesStarted: false, engineReady: false);
    }



    final preservePlayerWhite = forcedPlayerWhite ?? state.isPlayerWhite;
    final preserveBoardFlipped = forcedPlayerWhite != null ? !forcedPlayerWhite : state.isBoardFlipped;
    final preserveRated = state.isRatedMode;
    final preserveEvE = preserveRated ? false : state.isEngineVsEngine;
    final preserveLevel = state.engineLevel;
    final preserveBottomLevel = state.bottomAvatarId;

    _undoStack.clear();
    _redoStack.clear();
    _cancelCommentaryReveal();
    _pendingHintFen = null;
    _stopClock();

    final preserveTheme = state.boardThemeId;
    final preserveSound = state.isSoundEnabled;
    final preserveGameSound = state.isGameSoundEnabled;
    final preserveAcademySound = state.isAcademySoundEnabled;
    final preserveMusic = state.isMusicEnabled;
    final preserveAnimations = state.isAnimationsEnabled;
    final preserveAnimationSettings = state.animationSettings;
    final preserveSoundSettings = state.soundSettings;
    final preserveAcademySoundSettings = state.academySoundSettings;
    final preserveHaptics = state.isHapticsEnabled;
    final preserveCoordinates = state.showCoordinates;
    final preserveAiOperational = state.isAiOperational;
    final preserveIncrement = state.incrementDuration;
    final baseTime = state.baseTimeDuration;
    final preserveMode = state.gameMode;

    final is960 = preserveMode == 'chess960';
    await _engine.setChess960Mode(is960);
    final newGame = is960
        ? ChessGame(
            fen: Chess960Generator.generateRandomPosition().fen,
            isChess960: true,
          )
        : ChessGame(isChess960: false);

    state = ChessState(
      game: newGame,
      isPlayerWhite: preservePlayerWhite,
      isBoardFlipped: preserveBoardFlipped,
      isEngineVsEngine: preserveEvE,
      engineLevel: preserveLevel,
      bottomAvatarId: preserveBottomLevel,
      boardThemeId: preserveTheme,
      isSoundEnabled: preserveSound,
      isGameSoundEnabled: preserveGameSound,
      isAcademySoundEnabled: preserveAcademySound,
      isMusicEnabled: preserveMusic,
      isAnimationsEnabled: preserveAnimations,
      animationSettings: preserveAnimationSettings,
      soundSettings: preserveSoundSettings,
      academySoundSettings: preserveAcademySoundSettings,
      isHapticsEnabled: preserveHaptics,
      showCoordinates: preserveCoordinates,
      isAiOperational: preserveAiOperational,
      whiteTimeLeft: baseTime,
      blackTimeLeft: baseTime,
      incrementDuration: preserveIncrement,
      baseTimeDuration: baseTime,
      isEngineThinking: false,
      servicesStarted: state.servicesStarted,
      servicesStarting: false,
      engineReady: state.engineReady,
      isCommentaryEngineLoading: _commentaryEngine.isInitializing,
      commentaryError: _commentaryEngine.lastError,
      savedGames: state.savedGames,
      pendingEngineMove: null, // Clear pending move on reset
      isGameOverDismissed: false,
      gameMode: preserveMode,
      isRatedMode: preserveRated,
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
      isAcademyActive: false,
      isTimeOut: false,
      userName: state.userName,
      userAvatarPath: state.userAvatarPath,
      cachedScotoma: state.cachedScotoma,
      cachedPlaystyle: state.cachedPlaystyle,
      cachedOpenings: state.cachedOpenings,
      cachedEndgames: state.cachedEndgames,
      cachedDominanceHeatmap: state.cachedDominanceHeatmap,
      cachedLedgerEntries: state.cachedLedgerEntries,
    );

    if (preserveRated) {
      _autoSelectRatedOpponent();
    }

    _syncUndoRedoFlags();

    // Always start thinking if Robot Mode is on OR if it's currently the Engine's turn
    if (preserveEvE || !preservePlayerWhite) {
      await ensureGameServicesStarted(analyzeCurrentPosition: true);
      await _engine.setSkillLevel(AiAvatar.getAvatar(preserveLevel).skillLevel,
          multiPV: 1); // Reset MultiPV for normal play
      state = state.copyWith(isEngineThinking: state.engineReady);
    }

    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: false,
      isRatedMode: state.isRatedMode,
    );
  }

  Future<void> initializeAcademySession({String? customFen}) async {
    // Transitioning into Academy Mode. Ensure any old engine output stream is canceled,
    // and servicesStarted is set to false so the Crafty engine can be clean-started.
    await _cancelEngineSubscriptions();

    // Force state to Engine as White, Board Flipped
    _undoStack.clear();
    _redoStack.clear();
    _cancelCommentaryReveal();
    _pendingHintFen = null;
    _stopClock();

    final preserveTheme = state.boardThemeId;
    final preserveSound = state.isSoundEnabled;
    final preserveGameSound = state.isGameSoundEnabled;
    final preserveAcademySound = state.isAcademySoundEnabled;
    final preserveMusic = state.isMusicEnabled;
    final preserveAnimations = state.isAnimationsEnabled;
    final preserveAnimationSettings = state.animationSettings;
    final preserveSoundSettings = state.soundSettings;
    final preserveAcademySoundSettings = state.academySoundSettings;
    final preserveHaptics = state.isHapticsEnabled;
    final preserveCoordinates = state.showCoordinates;
    final preserveAiOperational = state.isAiOperational;
    final baseTime = state.baseTimeDuration;
    final preserveLevel = state.engineLevel;
    final preserveBottomLevel = state.bottomAvatarId;

    state = ChessState(
      game: ChessGame(fen: customFen, isChess960: false),
      isPlayerWhite: false, // Engine is White
      isBoardFlipped: true, // White is at the top
      engineLevel: preserveLevel,
      bottomAvatarId: preserveBottomLevel,
      boardThemeId: preserveTheme,
      isSoundEnabled: preserveSound,
      isGameSoundEnabled: preserveGameSound,
      isAcademySoundEnabled: preserveAcademySound,
      isMusicEnabled: preserveMusic,
      isAnimationsEnabled: preserveAnimations,
      animationSettings: preserveAnimationSettings,
      soundSettings: preserveSoundSettings,
      academySoundSettings: preserveAcademySoundSettings,
      isHapticsEnabled: preserveHaptics,
      showCoordinates: preserveCoordinates,
      isAiOperational: preserveAiOperational,
      whiteTimeLeft: baseTime,
      blackTimeLeft: baseTime,
      baseTimeDuration: baseTime,
      isEngineThinking: false,
      servicesStarted: false, // Will start Crafty on-demand below
      servicesStarting: false,
      engineReady: false,
      isCommentaryEngineLoading: _commentaryEngine.isInitializing,
      commentaryError: _commentaryEngine.lastError,
      savedGames: state.savedGames,
      isAcademyActive: true,
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
      userName: state.userName,
      userAvatarPath: state.userAvatarPath,
      cachedScotoma: state.cachedScotoma,
      cachedPlaystyle: state.cachedPlaystyle,
      cachedOpenings: state.cachedOpenings,
      cachedEndgames: state.cachedEndgames,
      cachedDominanceHeatmap: state.cachedDominanceHeatmap,
      cachedLedgerEntries: state.cachedLedgerEntries,
      commentaryHistory: [
        CommentaryEntry(
          text: customFen != null
              ? "Ah, you bring me a position from your Study Lab! Let me examine this setup. What would you like to know or practice from here?"
              : "Welcome back to the Academy, Apprentice. Today, I shall take the first step. Observe how I open the board to secure the center, then the path will be yours to choose.",
          timestamp: DateTime.now(),
          isComplete: true,
          isUser: false,
        ),
      ],
    );

    _syncUndoRedoFlags();

    // Start analysis which will trigger the engine move
    await ensureGameServicesStarted(analyzeCurrentPosition: true);
    await _engine.setSkillLevel(AiAvatar.getAvatar(preserveLevel).skillLevel,
        multiPV: 3); // Academy uses MultiPV=3
    state = state.copyWith(isEngineThinking: state.engineReady);

    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: true,
      isRatedMode: state.isRatedMode,
    );
  }

  Future<void> shutdown() async {
    _engineMoveTimer?.cancel();
    _stopClock();
    _cancelCommentaryReveal();
    await _cancelEngineSubscriptions();
    _stockfishEngine.dispose();
    _craftyEngine.dispose();
    await _commentaryEngine.dispose();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _engineMoveTimer?.cancel();
    _maxThinkingTimer?.cancel();
    _stopClock();
    _cancelCommentaryReveal();
    _stockfishSubscription?.cancel();
    _stockfishSubscription = null;
    _craftySubscription?.cancel();
    _craftySubscription = null;
    _stockfishEngine.dispose();
    _craftyEngine.dispose();
    unawaited(_commentaryEngine.dispose());
    super.dispose();
  }

  void _extractMoveSuggestion(String text) {
    if (!state.academyHouseAnimations) return;

    // Regex to find SAN-like moves (e.g., Nf3, e4, O-O, etc.)
    final moveRegex = RegExp(
      r'\b([a-h][1-8]-?[a-h][1-8]|[NBRQK]?[a-h]?[1-8]?x?[a-h][1-8](?:=[NBRQK])?[+#]?|O-O(?:-O)?)\b',
    );

    final matches = moveRegex.allMatches(text);
    if (matches.isEmpty) return;

    // Get the last mentioned move
    final lastMatch = matches.last.group(0);
    if (lastMatch == null) return;

    final move = state.game.findMoveBySan(lastMatch);
    if (move != null) {
      final from = chess_lib.Chess.algebraic(move.from);
      final to = chess_lib.Chess.algebraic(move.to);
      final colorPrefix = move.color == chess_lib.Color.WHITE ? 'w' : 'b';
      String pieceChar = 'P';
      switch (move.piece) {
        case chess_lib.PieceType.PAWN: pieceChar = 'P'; break;
        case chess_lib.PieceType.KNIGHT: pieceChar = 'N'; break;
        case chess_lib.PieceType.BISHOP: pieceChar = 'B'; break;
        case chess_lib.PieceType.ROOK: pieceChar = 'R'; break;
        case chess_lib.PieceType.QUEEN: pieceChar = 'Q'; break;
        case chess_lib.PieceType.KING: pieceChar = 'K'; break;
      }
      final pieceCode = '$colorPrefix$pieceChar';

      state = state.copyWith(
        chanakyaSuggestion: MoveAnimationData(
          from: from,
          to: to,
          pieceCode: pieceCode,
          isCapture: move.captured != null,
        ),
        academyAnimationTrigger: state.academyAnimationTrigger + 1,
      );
    }
  }

  void triggerAcademyAnimation() {
    state = state.copyWith(
      academyAnimationTrigger: state.academyAnimationTrigger + 1,
    );
  }

  void glowSquare(String square) {
    state = state.copyWith(glowingSquare: square);
    Timer(const Duration(milliseconds: 1000), () {
      if (!_isDisposed && state.glowingSquare == square) {
        state = state.copyWith(glowingSquare: null);
      }
    });
  }
}

// Removed duplicate stockfishServiceProvider
final chessSoundServiceProvider = Provider((ref) {
  final service = ChessSoundService();
  ref.onDispose(() => service.dispose());
  return service;
});
final chessHapticsServiceProvider = Provider((ref) => ChessHapticsService());
final commentaryEngineProvider = Provider((ref) => CommentaryEngine());
final savedGameRepositoryProvider = Provider((ref) => SavedGameRepository());
final performanceLedgerRepositoryProvider = Provider((ref) => PerformanceLedgerRepository());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

final chessProvider = StateNotifierProvider<ChessNotifier, ChessState>((ref) {
  final stockfishEngine = ref.watch(stockfishServiceProvider);
  final craftyEngine = ref.watch(craftyServiceProvider);
  final commentaryEngine = ref.watch(commentaryEngineProvider);
  final savedGameRepository = ref.watch(savedGameRepositoryProvider);
  final performanceLedgerRepository = ref.watch(performanceLedgerRepositoryProvider);
  final soundService = ref.watch(chessSoundServiceProvider);
  final hapticsService = ref.watch(chessHapticsServiceProvider);
  final aiContextService = ref.watch(aiContextServiceProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  final puzzleRepository = ref.watch(puzzleRepositoryProvider);
  return ChessNotifier(
    ref,
    stockfishEngine,
    craftyEngine,
    commentaryEngine,
    savedGameRepository,
    performanceLedgerRepository,
    soundService,
    hapticsService,
    aiContextService,
    settingsRepository,
    puzzleRepository,
  );
});

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
