import 'dart:math' as math;
import 'dart:async';
import 'package:chess/chess.dart' as chess_lib;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'game_clock_provider.dart';
import 'package:kingslayer_chess/src/rust/api/threats.dart';
import 'package:kingslayer_chess/src/rust/api/humanizer.dart';
import 'package:kingslayer_chess/src/rust/api/context.dart';
import 'package:kingslayer_chess/src/rust/api/chanakya.dart' as rust_chanakya;
import '../domain/models/precomputed_rust_context.dart';


import '../data/saved_game.dart';
import '../data/saved_game_repository.dart';
import '../data/performance_ledger_repository.dart';
import '../data/stockfish_service.dart';
import '../data/chess_engine_service.dart';
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
import 'battleground_provider.dart';


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
    required this.analysis,

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
  final Map<String, dynamic> analysis;

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
    this.quickPlay = false,
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
    this.isWaitingForSideChoice = false,
    this.isAcademyBlunderActive = false,

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
  final bool quickPlay;
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
  final bool isWaitingForSideChoice;
  final bool isAcademyBlunderActive;


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
    bool? quickPlay,
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
    bool? isWaitingForSideChoice,
    bool? isAcademyBlunderActive,

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
      quickPlay: quickPlay ?? this.quickPlay,
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
      isWaitingForSideChoice: isWaitingForSideChoice ?? this.isWaitingForSideChoice,
      isAcademyBlunderActive: isAcademyBlunderActive ?? this.isAcademyBlunderActive,

    );
  }
}

class ChessNotifier extends StateNotifier<ChessState> {
  final Ref ref;

  ChessNotifier(
    this.ref,
    this._stockfishEngine,
    this._commentaryEngine,
    this._savedGameRepository,
    this._performanceLedgerRepository,
    this._soundService,
    this._hapticsService,
    this._aiContextService,
    this._settingsRepository,
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
        quickPlay: s.quickPlay,
        baseTimeDuration: Duration(minutes: s.totalTimeMinutes),
        whiteTimeLeft: Duration(minutes: s.totalTimeMinutes),
        blackTimeLeft: Duration(minutes: s.totalTimeMinutes),
        incrementDuration: Duration(seconds: s.incrementSeconds),
        gameMode: s.gameMode,
        userName: s.userName,
        userAvatarPath: s.userAvatarPath,
      );
      _soundService.boardThemeId = s.boardThemeId;
      _soundService.isThemeSoundEnabled = true;
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



      // Automatically load saved games and populate dashboard caches on boot
      await loadSavedGames();
      _syncTimesToClockProvider();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final s = await _settingsRepository.loadSettings();
      final updated = s.copyWith(
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
        quickPlay: state.quickPlay,
        totalTimeMinutes: state.baseTimeDuration.inMinutes,
        incrementSeconds: state.incrementDuration.inSeconds,
        gameMode: state.gameMode,
        userName: state.userName,
        userAvatarPath: state.userAvatarPath,
      );
      await _settingsRepository.saveSettings(updated);
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
      isRatedMode: false,
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
      isRatedMode: false,
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
      isRatedMode: false,
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
      isRatedMode: false,
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
      isRatedMode: false,
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
      isRatedMode: false,
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
    _soundService.boardThemeId = themeId;
    _soundService.isThemeSoundEnabled = true;
    _saveSettings();
  }

  void toggleQuickPlay(bool value) {
    state = state.copyWith(quickPlay: value);
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

  bool isAnimationTypeEnabled(String key, {bool isRated = false}) {
    if (isRated || state.isAcademyActive) {
      return key == 'pieceMotion';
    }
    if (!state.isAnimationsEnabled) {
      return false;
    }
    final themeId = state.boardThemeId;
    if (themeId == 'classic' || themeId == 'scholar' || themeId == 'vector_glass') {
      return false;
    }
    return true;
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

  ChessEngineService get _engine {
    return _stockfishEngine;
  }

  final CommentaryEngine _commentaryEngine;
  final SavedGameRepository _savedGameRepository;
  final PerformanceLedgerRepository _performanceLedgerRepository;
  final ChessSoundService _soundService;
  final ChessHapticsService _hapticsService;
  final AiContextService _aiContextService;
  final SettingsRepository _settingsRepository;
  final _uuid = const Uuid();

  Timer? _engineMoveTimer;
  Timer? _commentaryRevealTimer;
  Timer? _maxThinkingTimer;
  DateTime? _engineStartTime;
  StreamSubscription<String>? _stockfishSubscription;

  Future<void> _cancelEngineSubscriptions() async {
    await _stockfishSubscription?.cancel();
    _stockfishSubscription = null;
  }
  final List<_BoardSnapshot> _undoStack = [];
  final List<_BoardSnapshot> _redoStack = [];
  final List<CandidateMove> _currentCandidates = [];
  Future<PrecomputedRustContext>? _pendingRustContextFuture;

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
      _stockfishSubscription ??= _stockfishEngine.outputStream.listen(
        _handleEngineOutput,
      );

      await _stockfishEngine.init();

      final avatar = AiAvatar.getAvatar(state.engineLevel);
      final multiPV = state.isAcademyActive ? 3 : (avatar.name == 'Kingslayer' ? 1 : 4);
      
      await _stockfishEngine.setSkillLevel(
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

      // Check if we are in Academy Mode and it was the user who just moved
      if (state.isAcademyActive &&
          aiTurn &&
          !state.isWaitingForSideChoice &&
          !state.isAcademyBlunderActive &&
          !state.game.gameOver &&
          !state.isPaused &&
          state.game.history.length >= 3) {
        
        // Calculate evaluation delta
        final double prevEval = state.previousEvaluation;
        final double currEval = newEval ?? state.currentEvaluation;
        final double evalDiff = -currEval - prevEval;

        debugPrint('Academy Mode evaluation check: prev=$prevEval, curr=$currEval, diff=$evalDiff, history=${state.game.history.length}');

        if (evalDiff <= -1.2) {
          // It's an absolute blunder! Set flag and trigger Chanakya's intervention
          final lastMove = _lastMoveFromHistory();
          final friendlyMoveName = lastMove != null
              ? _formatMoveFriendly(lastMove)
              : (state.recentMoves.isNotEmpty ? state.recentMoves.last : (state.lastMove ?? ''));
          final titlePrefix = "**${state.userName}: $friendlyMoveName**\n\n";

          state = state.copyWith(
            isAcademyBlunderActive: true,
            pendingEngineMove: bestMoveToPlay,
          );

          final lastMoveStr = state.lastMove ?? '';
          unawaited(_handleAcademyBlunderIntervention(
            evalDiff: evalDiff,
            lastMove: lastMoveStr,
            titlePrefix: titlePrefix,
          ));

          // Return early! Do NOT schedule the engine move.
          return;
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
        final now = DateTime.now();
        final elapsed = now
            .difference(_engineStartTime ?? now)
            .inMilliseconds;
        final randomDelayMs = 1500 + math.Random().nextInt(3000); // 1.5s to 4.5s
        final remainingDelay = math.max(0, randomDelayMs - elapsed);

        _engineMoveTimer = Timer(Duration(milliseconds: remainingDelay), () {
          if (!_isDisposed && !state.isPaused) {
            _makeEngineMove(finalMove);
          }
        });
      }
    }
  }

  /// Selects the best move for the current AI persona from Stockfish's MultiPV
  /// candidate list.
  ///
  /// **Academy mode** is fully routed through the Rust FFI
  /// (`selectChanakyaMoveRust`) which applies three layers of adaptive
  /// intelligence:
  ///   1. Opening jitter (Elo-gap variety, decays after move 12)
  ///   2. Cognitive scotoma targeting (exploits the user's blindspot profile)
  ///   3. Playstyle countering (solid defence vs attackers / aggression vs
  ///      passifiers)
  ///
  /// **Non-Academy play** is handled by the existing Dart-side heuristics that
  /// give each AI avatar (Pawnzy, Molly, Blaire, etc.) its characteristic style.
  String _applyPersonaHeuristics(
    List<CandidateMove> candidates,
    AiAvatar avatar,
    ChessGame game,
    String engineBestMove,
  ) {
    if (candidates.isEmpty) return engineBestMove;

    // ── Academy Mode: route through Rust adaptive intelligence filter ──────
    if (state.isAcademyActive) {
      try {
        final bgState = ref.read(battlegroundProvider);
        final scotomaRaw = bgState.cachedScotoma;
        final playstyleRaw = bgState.cachedPlaystyle;

        // Map Dart domain objects → Rust FFI structs
        final rustScotoma = rust_chanakya.ChanakyaScotoma(
          diagonalRetreats: scotomaRaw?.diagonalRetreats ?? 0.15,
          horizontalSwings: scotomaRaw?.horizontalSwings ?? 0.15,
          knightForks: scotomaRaw?.knightForks ?? 0.15,
          pinnedPieces: scotomaRaw?.pinnedPieces ?? 0.15,
          kingSafety: scotomaRaw?.kingSafety ?? 0.15,
          materialGreed: scotomaRaw?.materialGreed ?? 0.15,
          tunnelVision: scotomaRaw?.tunnelVision ?? 0.15,
          timePanic: scotomaRaw?.timePanic ?? 0.15,
        );

        final rustPlaystyle = rust_chanakya.ChanakyaPlaystyle(
          aggression: playstyleRaw?.aggression ?? 0.5,
          intensity: playstyleRaw?.intensity ?? 0.5,
          speed: playstyleRaw?.speed ?? 0.7,
        );

        final rustCandidates = candidates.map((c) => rust_chanakya.ChanakyaCandidate(
          uciMove: c.uciMove,
          evaluation: c.evaluation,
        )).toList();

        final halfMoveCount = game.history.length;
        final evalAbs = (state.currentEvaluation).abs();

        final selected = rust_chanakya.selectChanakyaMoveRust(
          fen: game.fen,
          candidates: rustCandidates,
          scotoma: rustScotoma,
          playstyle: rustPlaystyle,
          halfMoveCount: halfMoveCount,
          evalAbs: evalAbs,
          isChess960: game.isChess960,
        );

        if (selected.isNotEmpty) {
          debugPrint(
            '🧠 Chanakya [Rust Filter] selected: $selected '
            '| ELO-gap jitter: move $halfMoveCount | evalAbs: ${evalAbs.toStringAsFixed(2)} '
            '| scotoma dgb=${rustScotoma.diagonalRetreats.toStringAsFixed(2)} '
            'knf=${rustScotoma.knightForks.toStringAsFixed(2)} '
            'ksb=${rustScotoma.kingSafety.toStringAsFixed(2)} '
            '| aggression=${rustPlaystyle.aggression.toStringAsFixed(2)}',
          );
          return selected;
        }
      } catch (e) {
        debugPrint('⚠️  Chanakya Rust FFI failed, falling back to engine best: $e');
      }
      // Fallback to Stockfish best if Rust call fails
      return engineBestMove;
    }

    // ── Non-Academy Mode: existing Dart persona heuristics ────────────────
    String bestCandidateMove = candidates.first.uciMove;
    double highestAdjustedScore = -999.0;

    debugPrint('--- Persona Candidate Interception [${avatar.name}] ---');

    for (final candidate in candidates) {
      if (candidate.uciMove.length < 4) continue;

      final adjustedScore = candidate.evaluation;

      debugPrint(
        '  Candidate ${candidate.multipvIndex}: ${candidate.uciMove} | '
        'Base Eval: ${candidate.evaluation.toStringAsFixed(2)} | '
        'Adjusted: ${adjustedScore.toStringAsFixed(2)}',
      );

      if (adjustedScore > highestAdjustedScore) {
        highestAdjustedScore = adjustedScore;
        bestCandidateMove = candidate.uciMove;
      }
    }

    debugPrint('  Selected Persona Move [${avatar.name}]: $bestCandidateMove');
    return bestCandidateMove;
  }


  void sendCommand(String command) {
    _engine.sendCommand(command);
  }



  Future<List<SavedGameEntry>> loadSavedGames() async {
    state = state.copyWith(isSavedGamesLoading: true);
    try {
      final saves = await _savedGameRepository.listSaves();
      state = state.copyWith(
        savedGames: saves,
        isSavedGamesLoading: false,
      );
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
        isRatedMode: false,
        isAcademyActive: state.isAcademyActive,
        result: result,
        ratingSnapshot: ratingSnapshot,
        dominanceSnapshot: dominanceSnapshot,
        ratingCategory: ratingCategory,
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

      state = state.copyWith(
        savedGames: finalSaves,
        isSavingGame: false,
        commentaryError: null,
        loadedSaveId: entry.id,
      );
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
      ref.read(battlegroundProvider.notifier).refreshDashboardStats();
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
      ref.read(battlegroundProvider.notifier).refreshDashboardStats();
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
      );
      ref.read(battlegroundProvider.notifier).refreshDashboardStats();
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
      analysis: const {},
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
        analysis: const {},
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
      isAcademyActive: entry.isAcademyActive,
      userName: state.userName,
      userAvatarPath: state.userAvatarPath,
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
      analysis: Map<String, dynamic>.from(state.analysis),

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
      analysis: snapshot.analysis,
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
      isAcademyBlunderActive: false,
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

  Future<void> makeMove(String from, String to) async {
    if (state.game.gameOver) return;

    if (state.isAcademyBlunderActive) {
      state = state.copyWith(
        isAcademyBlunderActive: false,
        pendingEngineMove: null,
      );
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

    AiAvatar avatar = AiAvatar.getAvatar(activeAvatarId);
    int targetDepth = depth ?? avatar.depth;

    // ── Academy Mode: dynamic Elo-based difficulty calibration ─────────────
    if (state.isAcademyActive) {
      final bgState = ref.read(battlegroundProvider);
      final userElo = bgState.consolidatedRating;

      // Chanakya targets User ELO + 200 (clamped to range of known avatars)
      const chanakyaEloGap = 200;
      final targetElo = (userElo + chanakyaEloGap).clamp(400, 3200);
      final chanakyaAvatar = AiAvatar.getBestMatch(targetElo);

      // Tight-fight detection: game is close (eval within ±1.5) past move 20
      final halfMoveCount = state.game.history.length;
      final evalAbs = state.currentEvaluation.abs();
      final isTightFight = halfMoveCount >= 20 && evalAbs <= 1.5;

      // Apply boosted depth in tight-fight mode
      final baseDepth = chanakyaAvatar.depth;
      final chanakyaDepth = isTightFight ? (baseDepth + 2) : baseDepth;

      avatar = chanakyaAvatar;
      targetDepth = depth ?? chanakyaDepth;

      debugPrint(
        '🧠 Chanakya level calibration: userElo=$userElo → target=${chanakyaAvatar.name} '
        '(skillLevel=${chanakyaAvatar.skillLevel}, depth=$chanakyaDepth) '
        '| tightFight=$isTightFight | evalAbs=${evalAbs.toStringAsFixed(2)}',
      );
    }
    // ────────────────────────────────────────────────────────────────────────

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

    if (state.isAcademyBlunderActive) {
      state = state.copyWith(
        isAcademyBlunderActive: false,
        pendingEngineMove: null,
      );
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

  void _startPrecomputingRustContext(String move, ChessGame game) {
    // Compute FEN before the move
    String fenBefore = game.fen;
    if (game.history.isNotEmpty) {
      try {
        final temp = ChessGame(fen: game.fen, isChess960: game.isChess960);
        temp.undo();
        fenBefore = temp.fen;
      } catch (e) {
        debugPrint('ContextBuilder: Error calculating FEN before move: $e');
      }
    }

    final fen = game.fen;
    final historyLength = game.history.length;

    _pendingRustContextFuture = Future.wait([
      Future(() {
        try {
          return humanizeMoveRust(fenBefore: fenBefore, moveUci: move);
        } catch (e) {
          debugPrint('ContextBuilder: Error calling humanizeMoveRust: $e');
          return move;
        }
      }),
      Future(() {
        try {
          return analyzeTacticalThreats(fen: fen);
        } catch (e) {
          debugPrint('ContextBuilder: Error calling analyzeTacticalThreats: $e');
          return <String>[];
        }
      }),
      Future(() {
        try {
          final metrics = evaluatePositionMetrics(
            fen: fen,
            historyLength: historyLength,
          );
          return metrics.gamePhase;
        } catch (e) {
          debugPrint('Rust Context Engine Error: $e');
          final moveCount = historyLength;
          if (moveCount <= 20) return 'Opening';
          return 'Middlegame';
        }
      }),
    ]).then((results) {
      return PrecomputedRustContext(
        moveDescription: results[0] as String,
        tacticalThreats: results[1] as List<String>,
        gamePhase: results[2] as String,
      );
    });
  }

  Stream<String> _typewriterStream(Stream<String> source) async* {
    String targetText = '';
    String currentTypedText = '';
    bool sourceDone = false;

    final subscription = source.listen(
      (text) {
        targetText = text;
      },
      onDone: () {
        sourceDone = true;
      },
      onError: (e) {
        sourceDone = true;
      },
    );

    try {
      while (!sourceDone || currentTypedText.length < targetText.length) {
        if (currentTypedText.length < targetText.length) {
          currentTypedText = targetText.substring(0, currentTypedText.length + 1);
          yield currentTypedText;
          await Future.delayed(const Duration(milliseconds: 25));
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } finally {
      await subscription.cancel();
    }
  }

  void _onMoveCompleted(String lastMove) {
    _startPrecomputingRustContext(lastMove, state.game);
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
  }



  chess_lib.Move? _lastMoveFromHistory() {
    final history = state.game.history;
    if (history.isEmpty) return null;
    final lastState = history.last;
    return lastState.move as chess_lib.Move?;
  }

  String _formatMoveFriendly(chess_lib.Move move) {
    String pieceName = 'Pawn';
    switch (move.piece) {
      case chess_lib.PieceType.PAWN:
        pieceName = 'Pawn';
        break;
      case chess_lib.PieceType.KNIGHT:
        pieceName = 'Knight';
        break;
      case chess_lib.PieceType.BISHOP:
        pieceName = 'Bishop';
        break;
      case chess_lib.PieceType.ROOK:
        pieceName = 'Rook';
        break;
      case chess_lib.PieceType.QUEEN:
        pieceName = 'Queen';
        break;
      case chess_lib.PieceType.KING:
        pieceName = 'King';
        break;
    }
    final from = chess_lib.Chess.algebraic(move.from);
    final to = chess_lib.Chess.algebraic(move.to);
    return '$pieceName $from-$to';
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

  Future<void> sendUserQuery(String query, {String? titlePrefix}) async {
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
      titlePrefix: titlePrefix ?? '',
    );
  }

  Future<void> _runCommentary({
    required String player,
    required String move,
    required String evalScore,
    String? userQuery,
    bool revealHintAfterTyping = false,
    bool isNested = false,
    String titlePrefix = '',
  }) async {
    _cancelCommentaryReveal();

    final newEntry = CommentaryEntry(
      text: titlePrefix,
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

    if (state.isAcademyActive) {
      _soundService.playSfx(SoundEffect.bookFlip);
    } else {
      _soundService.playSfx(SoundEffect.gmchanakyaThinking);
    }

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

        PrecomputedRustContext? precomputed;
        if (_pendingRustContextFuture != null) {
          try {
            precomputed = await _pendingRustContextFuture;
          } catch (e) {
            debugPrint('Error awaiting precomputed context: $e');
          }
          _pendingRustContextFuture = null;
        }

        structuredPrompt = await _aiContextService.generateCommentaryPrompt(
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
          precomputed: precomputed,
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

      int charCount = 0;
      await for (final chunk in _typewriterStream(stream)) {
        if (_isDisposed) break;

        final updatedHistory = List<CommentaryEntry>.from(
          state.commentaryHistory,
        );
        if (updatedHistory.isNotEmpty) {
          updatedHistory[updatedHistory.length - 1] = updatedHistory.last
              .copyWith(text: '$titlePrefix$chunk');
        }

        state = state.copyWith(
          commentaryHistory: updatedHistory,
          isCommentaryLoading: false,
          isCommentaryStreaming: true,
        );

        charCount++;
        if (charCount % 2 == 0) {
          _soundService.playWriting();
        }

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
          var textToSet = finalHistory.last.text;
          if (isNested) {
            textToSet = '$textToSet\n\nWould you like to proceed or alter course? To alter course, use the Back button.';
          }
          finalHistory[finalHistory.length - 1] = finalHistory.last.copyWith(
            text: textToSet,
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

    final timedOutSideIsWhite = side == _clockWhite;
    final playerIsWhite = state.isPlayerWhite;
    final humanWon = playerIsWhite != timedOutSideIsWhite;
    _soundService.playSfx(humanWon ? SoundEffect.victory : SoundEffect.defeat);
  }

  void _stopClock() {
    if (_isDisposed) return;
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

    _engineMoveTimer?.cancel();
    _maxThinkingTimer?.cancel();
    _maxThinkingTimer = null;

    final bool wasBlunderActive = state.isAcademyBlunderActive;
    final cachedCommentary = List<CommentaryEntry>.from(state.commentaryHistory);

    // 1. Always pause when navigating history to prevent engine interference
    if (!state.isPaused && !wasBlunderActive) {
      state = state.copyWith(isPaused: true);
      _stopClock();
    }

    // 2. Full-turn undo logic:
    // If it is the player's turn, it means the engine has already responded to the player's last move.
    // To make "Undo" meaningful for the player, we should undo both the engine move and the player move.
    bool shouldUndoTwice =
        _isPlayerTurn() &&
        _undoStack.length >= 2 &&
        !state.game.gameOver &&
        !state.isEngineVsEngine;

    // First undo
    _redoStack.add(_captureCurrentSnapshot());
    final snapshot = _undoStack.removeLast();
    _restoreSnapshot(snapshot);

    // Second undo
    if (shouldUndoTwice && _undoStack.isNotEmpty) {
      _redoStack.add(_captureCurrentSnapshot());
      final snapshot2 = _undoStack.removeLast();
      _restoreSnapshot(snapshot2);
    }

    _syncUndoRedoFlags();

    if (wasBlunderActive) {
      // Restore gameplay
      state = state.copyWith(
        isPaused: false,
        isAcademyBlunderActive: false,
        pendingEngineMove: null,
        commentaryHistory: cachedCommentary,
      );
      if (state.clockStarted) {
        _startClockTicker();
      }

      // Show glowing clue for the best move in this restored position
      final bestMove = state.analysis['bestMove'] as String?;
      if (bestMove != null) {
        unawaited(_runHintFlow(bestMove));
      }
    }
  }

  void continueAfterBlunder() {
    if (state.pendingEngineMove != null) {
      final engineMove = state.pendingEngineMove!;
      state = state.copyWith(
        pendingEngineMove: null,
        isAcademyBlunderActive: false,
      );
      _makeEngineMove(engineMove);
    } else {
      state = state.copyWith(
        isAcademyBlunderActive: false,
      );
    }
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
    final preserveEvE = state.isEngineVsEngine;
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
      isAcademyActive: false,
      isTimeOut: false,
      userName: state.userName,
      userAvatarPath: state.userAvatarPath,
    );

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
      isRatedMode: false,
    );
  }

  Future<void> initializeAcademySession({String? customFen}) async {
    // Transitioning into Academy Mode. Ensure any old engine output stream is canceled,
    // and servicesStarted is set to false so the Crafty engine can be clean-started.
    await _cancelEngineSubscriptions();

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

    final bool waitingForChoice = customFen == null;

    state = ChessState(
      game: ChessGame(fen: customFen, isChess960: false),
      isPlayerWhite: false, // Default placeholder, will be set by user choice
      isBoardFlipped: true, // Default placeholder
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
      servicesStarted: false, // Will start on-demand
      servicesStarting: false,
      engineReady: false,
      isCommentaryEngineLoading: _commentaryEngine.isInitializing,
      commentaryError: _commentaryEngine.lastError,
      savedGames: state.savedGames,
      isAcademyActive: true,
      userName: state.userName,
      userAvatarPath: state.userAvatarPath,
      isWaitingForSideChoice: waitingForChoice,
      isPaused: waitingForChoice, // Pause only if waiting for choice
      commentaryHistory: [
        CommentaryEntry(
          text: customFen != null
              ? "Ah, you bring me a position from your Study Lab! Let me examine this setup. What would you like to know or practice from here?"
              : "Hello, ${state.userName}! Welcome to the GM Chanakya Chess School. Please select whether you wish to play Classic Chess or Chess960, and choose to play as White or Black to begin our training:",
          timestamp: DateTime.now(),
          isComplete: true,
          isUser: false,
        ),
      ],
    );

    _syncUndoRedoFlags();

    if (!waitingForChoice) {
      // Start analysis which will trigger the engine move for custom positions
      await ensureGameServicesStarted(analyzeCurrentPosition: true);
      await _engine.setSkillLevel(AiAvatar.getAvatar(preserveLevel).skillLevel,
          multiPV: 3); // Academy uses MultiPV=3
      state = state.copyWith(isEngineThinking: state.engineReady);
    }

    _soundService.updateSettings(
      sfxEnabled: state.isSoundEnabled,
      bgmEnabled: state.isMusicEnabled,
      gameSoundEnabled: state.isGameSoundEnabled,
      soundSettings: state.soundSettings,
      academySoundEnabled: state.isAcademySoundEnabled,
      academySoundSettings: state.academySoundSettings,
      isAcademyActive: true,
      isRatedMode: false,
    );
  }

  Future<void> selectAcademySide(bool playAsWhite, {required String gameMode}) async {
    final is960 = gameMode == 'chess960';
    await _engine.setChess960Mode(is960);

    final newGame = is960
        ? ChessGame(
            fen: Chess960Generator.generateRandomPosition().fen,
            isChess960: true,
          )
        : ChessGame(isChess960: false);

    // 1. Update state flags
    state = state.copyWith(
      isWaitingForSideChoice: false,
      isPlayerWhite: playAsWhite,
      isBoardFlipped: !playAsWhite,
      isPaused: false,
      gameMode: gameMode,
      game: newGame,
    );

    // 2. Add user choice message to history
    final choiceStr = playAsWhite ? "White" : "Black";
    final modeStr = is960 ? "Chess 960" : "Classic Chess";
    final userEntry = CommentaryEntry(
      text: "I choose to play as $choiceStr in $modeStr mode.",
      timestamp: DateTime.now(),
      isUser: true,
      isComplete: true,
    );

    // 3. Prepare GM's response text
    String gmResponse = "";
    if (playAsWhite) {
      gmResponse = "Excellent, you have chosen to play as White in $modeStr. Go ahead, make your opening move to secure the center, and I shall observe.";
    } else {
      gmResponse = "Excellent, you have chosen to play as Black in $modeStr. Today, I shall take the first step. Observe how I open the board to secure the center, then the path will be yours to choose.";
    }

    final gmEntry = CommentaryEntry(
      text: gmResponse,
      timestamp: DateTime.now(),
      isUser: false,
      isComplete: true,
    );

    state = state.copyWith(
      commentaryHistory: [...state.commentaryHistory, userEntry, gmEntry],
    );

    // Play complete sound
    _soundService.playSfx(SoundEffect.gmchanakyaComplete);

    // 4. Start engine services
    await ensureGameServicesStarted(analyzeCurrentPosition: true);
    await _engine.setSkillLevel(AiAvatar.getAvatar(state.engineLevel).skillLevel,
        multiPV: 3); // Academy uses MultiPV=3

    // 5. If playing as Black, the engine (White) must think/make the first move!
    if (!playAsWhite) {
      state = state.copyWith(isEngineThinking: state.engineReady);
    }
  }

  Future<void> _handleAcademyBlunderIntervention({
    required double evalDiff,
    required String lastMove,
    required String titlePrefix,
  }) async {
    // 1. Play thinking sound
    _soundService.playSfx(SoundEffect.gmchanakyaThinking);

    // 2. Construct a blunder prompt instructing the AI to output exactly one brief sentence
    final prompt = "The user playing as ${state.isPlayerWhite ? 'White' : 'Black'} just blundered by playing $lastMove. "
        "The position evaluation dropped by ${evalDiff.abs().toStringAsFixed(1)} pawns. "
        "Write exactly one very brief sentence explaining why this move is a blunder and what threat it creates. "
        "Do not include any greeting, intro, outro, or conversational filler. Keep it under 25 words.";

    // 3. Run commentary stream for the blunder
    await _runCommentary(
      player: state.isPlayerWhite ? 'White' : 'Black',
      move: _formatMoveForPrompt(lastMove),
      evalScore: _formatEvalForPrompt(state.currentEvaluation),
      userQuery: prompt,
      isNested: true,
      titlePrefix: titlePrefix,
    );
  }

  Future<void> shutdown() async {
    _engineMoveTimer?.cancel();
    _stopClock();
    _cancelCommentaryReveal();
    await _cancelEngineSubscriptions();
    _stockfishEngine.dispose();
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
    _stockfishEngine.dispose();
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
  final commentaryEngine = ref.watch(commentaryEngineProvider);
  final savedGameRepository = ref.watch(savedGameRepositoryProvider);
  final performanceLedgerRepository = ref.watch(performanceLedgerRepositoryProvider);
  final soundService = ref.watch(chessSoundServiceProvider);
  final hapticsService = ref.watch(chessHapticsServiceProvider);
  final aiContextService = ref.watch(aiContextServiceProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return ChessNotifier(
    ref,
    stockfishEngine,
    commentaryEngine,
    savedGameRepository,
    performanceLedgerRepository,
    soundService,
    hapticsService,
    aiContextService,
    settingsRepository,
  );
});


