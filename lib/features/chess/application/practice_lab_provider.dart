import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../data/analysis_stockfish_service.dart';
import '../data/chess_engine_service.dart';
import '../data/uci_parser.dart';
import '../services/chess_sound_service.dart';
import 'chess_provider.dart';
import 'study_lab_provider.dart';
import 'analysis_engine_controller.dart';

void _logDebug(String msg) {
  // ignore: avoid_print
  print('PracticeLabProvider: $msg');
}

class PracticeLabState {
  final bool isSessionActive;
  final String fen;
  final String startFen;
  final bool isPlayerWhite;
  final int botSkillLevel;
  final List<String> moveHistory;
  final List<String> sanHistory;
  final bool isEngineThinking;
  final double? evalScore;
  final bool isMate;
  final int? mateIn;
  final bool isGameOver;
  final String? gameResult;
  final bool isBoardFlipped;
  final String? pendingPromoFrom;
  final String? pendingPromoTo;
  final int? startNodeIndex;
  final int? viewingMoveIndex;

  // Timer additions
  final bool showTimer;
  final bool isClockRunning;
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;
  final Duration baseTimeDuration;
  final Duration incrementDuration;
  final String? gameConclusion;

  PracticeLabState({
    this.isSessionActive = false,
    this.fen = '',
    this.startFen = '',
    this.isPlayerWhite = true,
    this.botSkillLevel = 12,
    this.moveHistory = const [],
    this.sanHistory = const [],
    this.isEngineThinking = false,
    this.evalScore,
    this.isMate = false,
    this.mateIn,
    this.isGameOver = false,
    this.gameResult,
    this.isBoardFlipped = false,
    this.pendingPromoFrom,
    this.pendingPromoTo,
    this.startNodeIndex,
    this.viewingMoveIndex,

    // Timer additions defaults
    this.showTimer = false,
    this.isClockRunning = false,
    this.whiteTimeLeft = const Duration(minutes: 10),
    this.blackTimeLeft = const Duration(minutes: 10),
    this.baseTimeDuration = const Duration(minutes: 10),
    this.incrementDuration = const Duration(seconds: 0),
    this.gameConclusion,
  });

  PracticeLabState copyWith({
    bool? isSessionActive,
    String? fen,
    String? startFen,
    bool? isPlayerWhite,
    int? botSkillLevel,
    List<String>? moveHistory,
    List<String>? sanHistory,
    bool? isEngineThinking,
    double? evalScore,
    bool? isMate,
    int? mateIn,
    bool? isGameOver,
    String? gameResult,
    bool? isBoardFlipped,
    String? pendingPromoFrom,
    String? pendingPromoTo,
    int? startNodeIndex,
    int? viewingMoveIndex,
    bool clearViewingMoveIndex = false,
    // Sentinel flags to explicitly clear nullable promo fields.
    // Using the same pattern as clearViewingMoveIndex because passing null
    // via a nullable String? parameter cannot be distinguished from "not provided".
    bool clearPendingPromo = false,

    // Timer copyWith addition
    bool? showTimer,
    bool? isClockRunning,
    Duration? whiteTimeLeft,
    Duration? blackTimeLeft,
    Duration? baseTimeDuration,
    Duration? incrementDuration,
    String? gameConclusion,
    bool clearGameConclusion = false,
  }) {
    return PracticeLabState(
      isSessionActive: isSessionActive ?? this.isSessionActive,
      fen: fen ?? this.fen,
      startFen: startFen ?? this.startFen,
      isPlayerWhite: isPlayerWhite ?? this.isPlayerWhite,
      botSkillLevel: botSkillLevel ?? this.botSkillLevel,
      moveHistory: moveHistory ?? this.moveHistory,
      sanHistory: sanHistory ?? this.sanHistory,
      isEngineThinking: isEngineThinking ?? this.isEngineThinking,
      evalScore: evalScore ?? this.evalScore,
      isMate: isMate ?? this.isMate,
      mateIn: mateIn ?? this.mateIn,
      isGameOver: isGameOver ?? this.isGameOver,
      gameResult: gameResult ?? this.gameResult,
      isBoardFlipped: isBoardFlipped ?? this.isBoardFlipped,
      pendingPromoFrom: clearPendingPromo ? null : (pendingPromoFrom ?? this.pendingPromoFrom),
      pendingPromoTo: clearPendingPromo ? null : (pendingPromoTo ?? this.pendingPromoTo),
      startNodeIndex: startNodeIndex ?? this.startNodeIndex,
      viewingMoveIndex: clearViewingMoveIndex ? null : (viewingMoveIndex ?? this.viewingMoveIndex),

      showTimer: showTimer ?? this.showTimer,
      isClockRunning: isClockRunning ?? this.isClockRunning,
      whiteTimeLeft: whiteTimeLeft ?? this.whiteTimeLeft,
      blackTimeLeft: blackTimeLeft ?? this.blackTimeLeft,
      baseTimeDuration: baseTimeDuration ?? this.baseTimeDuration,
      incrementDuration: incrementDuration ?? this.incrementDuration,
      gameConclusion: clearGameConclusion ? null : (gameConclusion ?? this.gameConclusion),
    );
  }
}

class PracticeLabNotifier extends Notifier<PracticeLabState> {
  late final ChessEngineService _service;
  Ref get _ref => ref;
  StreamSubscription? _subscription;
  Timer? _chessClockTimer;
  Timer? _engineTimer;

  @override
  PracticeLabState build() {
    _service = ref.watch(analysisStockfishServiceProvider);
    _subscription = _service.outputStream.listen(_handleEngineOutput);
    _logDebug('PracticeLabNotifier initialized, listening to dedicated Practice Lab engine');

    ref.onDispose(() {
      _chessClockTimer?.cancel();
      _engineTimer?.cancel();
      _subscription?.cancel();
      _logDebug('PracticeLabNotifier disposed');
    });

    return PracticeLabState();
  }

  void _handleEngineOutput(String line) {
    _logDebug('[RECV] Active=${state.isSessionActive} Thinking=${state.isEngineThinking}: $line');
    if (!state.isSessionActive || !state.isEngineThinking) return;

    if (line.startsWith('info')) {
      final parsed = UCIParser.parseLine(line);
      final mpv = parsed['multipv'] as int? ?? 1;
      if (mpv == 1 && parsed.containsKey('score')) {
        final score = parsed['score'] as int;
        final isMate = parsed['scoreType'] == 'mate';
        final double eval = isMate ? (score > 0 ? 99.0 : -99.0) : score / 100.0;
        final int? mateIn = isMate ? score : null;

        state = state.copyWith(
          evalScore: eval,
          isMate: isMate,
          mateIn: mateIn,
        );
      }
    } else if (line.startsWith('bestmove')) {
      final parsed = UCIParser.parseLine(line);
      final bestMove = parsed['bestMove'] as String?;
      _logDebug('[BESTMOVE] parsed: $bestMove');
      if (bestMove != null && bestMove != '(none)') {
        _applyEngineMove(bestMove);
      } else {
        state = state.copyWith(isEngineThinking: false);
      }
    }
  }

  void toggleTimer(bool value) {
    _chessClockTimer?.cancel();
    state = state.copyWith(
      showTimer: value,
      isClockRunning: false,
      whiteTimeLeft: state.baseTimeDuration,
      blackTimeLeft: state.baseTimeDuration,
    );
  }

  void setTimerPreset(Duration base, Duration inc) {
    _chessClockTimer?.cancel();
    state = state.copyWith(
      showTimer: true,
      isClockRunning: false,
      baseTimeDuration: base,
      incrementDuration: inc,
      whiteTimeLeft: base,
      blackTimeLeft: base,
    );
  }

  void setCustomBaseTime(Duration base) {
    _chessClockTimer?.cancel();
    state = state.copyWith(
      showTimer: true,
      isClockRunning: false,
      baseTimeDuration: base,
      whiteTimeLeft: base,
      blackTimeLeft: base,
    );
  }

  void setCustomIncrement(Duration inc) {
    _chessClockTimer?.cancel();
    state = state.copyWith(
      showTimer: true,
      isClockRunning: false,
      incrementDuration: inc,
      whiteTimeLeft: state.baseTimeDuration,
      blackTimeLeft: state.baseTimeDuration,
    );
  }

  void _startChessClock() {
    _chessClockTimer?.cancel();
    if (!state.isSessionActive || !state.showTimer || state.isGameOver) return;

    DateTime lastTick = DateTime.now();
    _chessClockTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!state.isSessionActive || state.isGameOver) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(lastTick);
      lastTick = now;

      final isWhiteToMove = !state.fen.contains(' b ');

      if (isWhiteToMove) {
        final newTime = state.whiteTimeLeft - elapsed;
        if (newTime <= Duration.zero) {
          _chessClockTimer?.cancel();
          final conclusion = state.isPlayerWhite ? 'You lost on time' : 'You won on time';
          state = state.copyWith(
            whiteTimeLeft: Duration.zero,
            isGameOver: true,
            gameResult: '0-1',
            gameConclusion: conclusion,
            isClockRunning: false,
          );
        } else {
          state = state.copyWith(whiteTimeLeft: newTime);
        }
      } else {
        final newTime = state.blackTimeLeft - elapsed;
        if (newTime <= Duration.zero) {
          _chessClockTimer?.cancel();
          final conclusion = state.isPlayerWhite ? 'You won on time' : 'You lost on time';
          state = state.copyWith(
            blackTimeLeft: Duration.zero,
            isGameOver: true,
            gameResult: '1-0',
            gameConclusion: conclusion,
            isClockRunning: false,
          );
        } else {
          state = state.copyWith(blackTimeLeft: newTime);
        }
      }
    });
  }

  Future<void> startSession(String fen, bool playerIsWhite) async {
    _logDebug('startSession FEN=$fen playerIsWhite=$playerIsWhite');
    
    // Ensure service is ready
    if (!_service.isReady) {
      _logDebug('startSession: Service not ready, calling init()...');
      await _service.init();
      for (var i = 0; i < 50; i++) {
        if (_service.isReady) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _logDebug('startSession: Service readiness after wait: ${_service.isReady}');
    }

    // 1. Pause the analysis engine to free up CPU resources on mobile/Android devices.
    await _ref.read(analysisEngineControllerProvider.notifier).toggleEngine(false, '');

    // 2. Clear and set new state
    final localChess = chess_lib.Chess.fromFEN(fen);
    final isWhiteTurn = localChess.turn == chess_lib.Color.WHITE;
    final isEngineTurn = isWhiteTurn != playerIsWhite;
    final isGameOver = localChess.game_over;

    String? gameResult;
    String? gameConclusion;
    if (isGameOver) {
      if (localChess.in_checkmate) {
        gameResult = isWhiteTurn ? '0-1' : '1-0';
        gameConclusion = 'Checkmate';
      } else if (localChess.in_threefold_repetition) {
        gameResult = '½-½';
        gameConclusion = 'Draw (Repetition)';
      } else if (localChess.insufficient_material) {
        gameResult = '½-½';
        gameConclusion = 'Draw (Insufficient Material)';
      } else if (localChess.in_stalemate) {
        gameResult = '½-½';
        gameConclusion = 'Stalemate';
      } else {
        gameResult = '½-½';
        gameConclusion = 'Draw';
      }
    }

    final currentShowTimer = state.showTimer;
    final currentBaseTime = state.baseTimeDuration;
    final currentIncrement = state.incrementDuration;

    final studyState = _ref.read(studyLabProvider);
    state = PracticeLabState(
      isSessionActive: true,
      fen: fen,
      startFen: fen,
      isPlayerWhite: playerIsWhite,
      botSkillLevel: 20,
      moveHistory: const [],
      sanHistory: const [],
      // Set isEngineThinking=true immediately if engine goes first, so the board is
      // never rendered as interactive during the async setup awaits below.
      isEngineThinking: isEngineTurn && !isGameOver,
      isGameOver: isGameOver,
      gameResult: gameResult,
      gameConclusion: gameConclusion,
      isBoardFlipped: !playerIsWhite,
      startNodeIndex: studyState.currentNodeIndex,

      showTimer: currentShowTimer,
      baseTimeDuration: currentBaseTime,
      incrementDuration: currentIncrement,
      whiteTimeLeft: currentBaseTime,
      blackTimeLeft: currentBaseTime,
      isClockRunning: currentShowTimer && !isGameOver,
    );

    // 3. Configure stockfish options
    _logDebug('Sending config options: Skill Level=20, MultiPV=1');
    await _service.stopAnalysis();
    await _service.sendCommand('setoption name Skill Level value 20');
    await _service.sendCommand('setoption name MultiPV value 1');

    // 4. Start chess clock if enabled
    _chessClockTimer?.cancel();
    if (currentShowTimer && !isGameOver) {
      _startChessClock();
    }

    // 5. Trigger engine move if it is the engine's turn and the game is not already over
    if (isEngineTurn && !isGameOver) {
      _logDebug('It is Engine\'s turn to move. Triggering initial engine move.');
      await _triggerEngineMove();
    }
  }

  void makePlayerMove(String from, String to, [String promotion = '']) {
    _logDebug('makePlayerMove from=$from to=$to promotion=$promotion');
    if (state.isEngineThinking || state.isGameOver || !state.isSessionActive) {
      _logDebug('makePlayerMove ignored: isThinking=${state.isEngineThinking} isGameOver=${state.isGameOver} isActive=${state.isSessionActive}');
      return;
    }

    List<String> currentMoveHistory = state.moveHistory;
    List<String> currentSanHistory = state.sanHistory;
    String currentFen = state.fen;

    if (state.viewingMoveIndex != null) {
      final index = state.viewingMoveIndex!;
      if (index == -1) {
        currentFen = state.startFen;
        currentMoveHistory = const [];
        currentSanHistory = const [];
      } else {
        currentFen = getFenAtMove(index);
        currentMoveHistory = state.moveHistory.sublist(0, index + 1);
        currentSanHistory = state.sanHistory.sublist(0, index + 1);
      }
    }

    final localChess = chess_lib.Chess.fromFEN(currentFen);
    final isWhiteTurn = localChess.turn == chess_lib.Color.WHITE;
    if (isWhiteTurn != state.isPlayerWhite) {
      _logDebug('makePlayerMove ignored: Turn=$isWhiteTurn playerIsWhite=${state.isPlayerWhite}');
      return;
    }

    final moves = localChess.generate_moves();
    chess_lib.Move? matchingMove;
    for (final m in moves) {
      final mFrom = chess_lib.Chess.algebraic(m.from);
      final mTo = chess_lib.Chess.algebraic(m.to);
      final mPromo = m.promotion != null ? m.promotion.toString().split('.').last.toLowerCase()[0] : '';
      if (mFrom == from && mTo == to && mPromo == promotion) {
        matchingMove = m;
        break;
      }
    }

    if (matchingMove == null) {
      _logDebug('makePlayerMove ignored: matchingMove is null');
      return;
    }

    final san = localChess.move_to_san(matchingMove);
    final uci = '$from$to$promotion';
    final isCapture = matchingMove.captured != null;
    final isCastling = (matchingMove.flags & 32) != 0 || (matchingMove.flags & 64) != 0;
    final isPromotion = matchingMove.promotion != null;

    final success = localChess.move({
      'from': from,
      'to': to,
      if (promotion.isNotEmpty) 'promotion': promotion,
    });

    if (!success) {
      _logDebug('makePlayerMove ignored: move failed in chess_lib');
      return;
    }

    final isCheck = localChess.in_check;
    final isCheckmate = localChess.in_checkmate;

    // Play SFX and Haptics
    final soundService = _ref.read(chessSoundServiceProvider);
    final hapticsService = _ref.read(chessHapticsServiceProvider);
    final isHapticsEnabled = _ref.read(chessProvider).isHapticsEnabled;

    if (isCheckmate) {
      soundService.playSfx(SoundEffect.gameover);
      if (isHapticsEnabled) {
        hapticsService.mateBurst();
      }
    } else if (isCheck) {
      soundService.playSfx(SoundEffect.check);
      if (isHapticsEnabled) {
        hapticsService.checkPulse();
      }
    } else if (isPromotion) {
      soundService.playSfx(SoundEffect.promote);
      if (isHapticsEnabled) {
        hapticsService.softTap();
      }
    } else if (isCapture) {
      soundService.playSfx(SoundEffect.capture);
      if (isHapticsEnabled) {
        hapticsService.heavyRook();
      }
    } else if (isCastling) {
      soundService.playSfx(SoundEffect.castle);
      if (isHapticsEnabled) {
        hapticsService.softTap();
      }
    } else {
      soundService.playSfx(SoundEffect.move);
      if (isHapticsEnabled) {
        hapticsService.softTap();
      }
    }

    final newFen = localChess.fen;
    final newMoves = List<String>.from(currentMoveHistory)..add(uci);
    final newSan = List<String>.from(currentSanHistory)..add(san);

    final isGameOver = localChess.game_over;
    String? gameResult;
    String? gameConclusion;
    if (isGameOver) {
      if (localChess.in_checkmate) {
        gameResult = state.isPlayerWhite ? '1-0' : '0-1';
        gameConclusion = 'Checkmate';
      } else if (localChess.in_threefold_repetition) {
        gameResult = '½-½';
        gameConclusion = 'Draw (Repetition)';
      } else if (localChess.insufficient_material) {
        gameResult = '½-½';
        gameConclusion = 'Draw (Insufficient Material)';
      } else if (localChess.in_stalemate) {
        gameResult = '½-½';
        gameConclusion = 'Stalemate';
      } else {
        gameResult = '½-½';
        gameConclusion = 'Draw';
      }
      _chessClockTimer?.cancel();
    }

    // Add increment if clock is active
    Duration newWhiteTime = state.whiteTimeLeft;
    Duration newBlackTime = state.blackTimeLeft;
    if (state.showTimer && !isGameOver) {
      if (state.isPlayerWhite) {
        newWhiteTime += state.incrementDuration;
      } else {
        newBlackTime += state.incrementDuration;
      }
    }

    _logDebug('makePlayerMove success, newFen=$newFen isGameOver=$isGameOver gameResult=$gameResult');

    state = state.copyWith(
      fen: newFen,
      moveHistory: newMoves,
      sanHistory: newSan,
      isGameOver: isGameOver,
      gameResult: gameResult,
      gameConclusion: gameConclusion,
      whiteTimeLeft: newWhiteTime,
      blackTimeLeft: newBlackTime,
      isClockRunning: state.showTimer && !isGameOver,
      clearViewingMoveIndex: state.viewingMoveIndex != null,
    );

    if (!isGameOver) {
      _triggerEngineMove();
    }
  }

  Future<void> _triggerEngineMove() async {
    _logDebug('_triggerEngineMove: Setting isEngineThinking=true');
    
    // Ensure service is ready
    if (!_service.isReady) {
      _logDebug('_triggerEngineMove: Service not ready, calling init()...');
      await _service.init();
      for (var i = 0; i < 50; i++) {
        if (_service.isReady) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _logDebug('_triggerEngineMove: Service readiness after wait: ${_service.isReady}');
    }

    _engineTimer?.cancel();
    await _service.stopAnalysis();

    state = state.copyWith(isEngineThinking: true);

    _logDebug('Sending search commands: FEN=${state.fen} (depth search)');
    await _service.sendCommand('position fen ${state.fen}');
    await _service.sendCommand('go depth 22');
  }

  void _applyEngineMove(String uci) {
    _logDebug('_applyEngineMove uci=$uci');
    if (uci.length < 4) {
      _logDebug('_applyEngineMove failed: uci too short');
      state = state.copyWith(isEngineThinking: false);
      return;
    }
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promo = uci.length > 4 ? uci.substring(4, 5) : '';

    final localChess = chess_lib.Chess.fromFEN(state.fen);
    final moves = localChess.generate_moves();
    chess_lib.Move? matchingMove;
    for (final m in moves) {
      final mFrom = chess_lib.Chess.algebraic(m.from);
      final mTo = chess_lib.Chess.algebraic(m.to);
      final mPromo = m.promotion != null ? m.promotion.toString().split('.').last.toLowerCase()[0] : '';
      if (mFrom == from && mTo == to && mPromo == promo) {
        matchingMove = m;
        break;
      }
    }

    if (matchingMove == null) {
      _logDebug('_applyEngineMove failed: matchingMove is null in current FEN=${state.fen}');
      state = state.copyWith(isEngineThinking: false);
      return;
    }

    final san = localChess.move_to_san(matchingMove);
    final isCapture = matchingMove.captured != null;
    final isCastling = (matchingMove.flags & 32) != 0 || (matchingMove.flags & 64) != 0;
    final isPromotion = matchingMove.promotion != null;

    final success = localChess.move({
      'from': from,
      'to': to,
      if (promo.isNotEmpty) 'promotion': promo,
    });

    if (!success) {
      _logDebug('_applyEngineMove failed: move execution in chess_lib failed');
      state = state.copyWith(isEngineThinking: false);
      return;
    }

    final isCheck = localChess.in_check;
    final isCheckmate = localChess.in_checkmate;

    // Play SFX and Haptics
    final soundService = _ref.read(chessSoundServiceProvider);
    final hapticsService = _ref.read(chessHapticsServiceProvider);
    final isHapticsEnabled = _ref.read(chessProvider).isHapticsEnabled;

    if (isCheckmate) {
      soundService.playSfx(SoundEffect.gameover);
      if (isHapticsEnabled) {
        hapticsService.mateBurst();
      }
    } else if (isCheck) {
      soundService.playSfx(SoundEffect.check);
      if (isHapticsEnabled) {
        hapticsService.checkPulse();
      }
    } else if (isPromotion) {
      soundService.playSfx(SoundEffect.promote);
      if (isHapticsEnabled) {
        hapticsService.softTap();
      }
    } else if (isCapture) {
      soundService.playSfx(SoundEffect.capture);
      if (isHapticsEnabled) {
        hapticsService.heavyRook();
      }
    } else if (isCastling) {
      soundService.playSfx(SoundEffect.castle);
      if (isHapticsEnabled) {
        hapticsService.softTap();
      }
    } else {
      soundService.playSfx(SoundEffect.move);
      if (isHapticsEnabled) {
        hapticsService.softTap();
      }
    }

    final newFen = localChess.fen;
    final newMoves = List<String>.from(state.moveHistory)..add(uci);
    final newSan = List<String>.from(state.sanHistory)..add(san);

    final isGameOver = localChess.game_over;
    String? gameResult;
    String? gameConclusion;
    if (isGameOver) {
      if (localChess.in_checkmate) {
        gameResult = state.isPlayerWhite ? '0-1' : '1-0';
        gameConclusion = 'Checkmate';
      } else if (localChess.in_threefold_repetition) {
        gameResult = '½-½';
        gameConclusion = 'Draw (Repetition)';
      } else if (localChess.insufficient_material) {
        gameResult = '½-½';
        gameConclusion = 'Draw (Insufficient Material)';
      } else if (localChess.in_stalemate) {
        gameResult = '½-½';
        gameConclusion = 'Stalemate';
      } else {
        gameResult = '½-½';
        gameConclusion = 'Draw';
      }
      _chessClockTimer?.cancel();
    }

    // Add increment if clock is active
    Duration newWhiteTime = state.whiteTimeLeft;
    Duration newBlackTime = state.blackTimeLeft;
    if (state.showTimer && !isGameOver) {
      if (!state.isPlayerWhite) {
        newWhiteTime += state.incrementDuration;
      } else {
        newBlackTime += state.incrementDuration;
      }
    }

    _logDebug('_applyEngineMove success: newFen=$newFen isGameOver=$isGameOver gameResult=$gameResult');

    state = state.copyWith(
      fen: newFen,
      moveHistory: newMoves,
      sanHistory: newSan,
      isEngineThinking: false,
      isGameOver: isGameOver,
      gameResult: gameResult,
      gameConclusion: gameConclusion,
      whiteTimeLeft: newWhiteTime,
      blackTimeLeft: newBlackTime,
      isClockRunning: state.showTimer && !isGameOver,
    );
  }



  void resign() {
    if (!state.isSessionActive || state.isGameOver) return;

    _chessClockTimer?.cancel();
    final gameResult = state.isPlayerWhite ? '0-1' : '1-0';
    state = state.copyWith(
      isGameOver: true,
      gameResult: gameResult,
      gameConclusion: 'Resigned',
      isClockRunning: false,
    );
  }

  Future<void> endSession(String analysisCurrentFen) async {
    _chessClockTimer?.cancel();
    _engineTimer?.cancel();
    state = PracticeLabState();

    await _service.stopAnalysis();
    await _service.sendCommand('setoption name Skill Level value 20');
    await _service.sendCommand('setoption name MultiPV value 3');
    await _ref.read(analysisEngineControllerProvider.notifier).toggleEngine(true, analysisCurrentFen);
  }

  Future<void> endSessionWithoutRestartingEngine() async {
    _chessClockTimer?.cancel();
    _engineTimer?.cancel();
    state = PracticeLabState();

    await _service.stopAnalysis();
    await _service.sendCommand('setoption name Skill Level value 20');
    await _service.sendCommand('setoption name MultiPV value 3');
  }

  void flipBoard() {
    state = state.copyWith(isBoardFlipped: !state.isBoardFlipped);
  }

  void setPendingPromo(String? from, String? to) {
    if (from == null && to == null) {
      // Use the sentinel flag to explicitly clear these nullable fields.
      // Passing null directly to copyWith cannot clear them due to the ?? fallback.
      state = state.copyWith(clearPendingPromo: true);
    } else {
      state = state.copyWith(
        pendingPromoFrom: from,
        pendingPromoTo: to,
      );
    }
  }

  void undo() {
    if (!state.isSessionActive || state.isEngineThinking || state.moveHistory.length < 2) return;

    final localChess = chess_lib.Chess.fromFEN(state.startFen);
    final newMoves = state.moveHistory.sublist(0, state.moveHistory.length - 2);
    final newSan = state.sanHistory.sublist(0, state.sanHistory.length - 2);

    for (final uci in newMoves) {
      final from = uci.substring(0, 2);
      final to = uci.substring(2, 4);
      final promo = uci.length > 4 ? uci.substring(4, 5) : '';
      localChess.move({
        'from': from,
        'to': to,
        if (promo.isNotEmpty) 'promotion': promo,
      });
    }

    state = state.copyWith(
      fen: localChess.fen,
      moveHistory: newMoves,
      sanHistory: newSan,
      isGameOver: false,
      gameResult: null,
      clearGameConclusion: true,
      isEngineThinking: false,
      clearViewingMoveIndex: true,
      isClockRunning: state.showTimer,
    );

    if (state.showTimer) {
      _startChessClock();
    }

    _ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
  }

  String getFenAtMove(int index) {
    // index == -1 means the start position (before any moves were made in this session).
    if (index < 0) return state.startFen;
    if (index >= state.moveHistory.length) return state.fen;
    final tempChess = chess_lib.Chess.fromFEN(state.startFen);
    for (var i = 0; i <= index; i++) {
      final uci = state.moveHistory[i];
      final from = uci.substring(0, 2);
      final to = uci.substring(2, 4);
      final promo = uci.length > 4 ? uci.substring(4, 5) : '';
      tempChess.move({
        'from': from,
        'to': to,
        if (promo.isNotEmpty) 'promotion': promo,
      });
    }
    return tempChess.fen;
  }

  void navigateToMove(int? index) {
    if (!state.isSessionActive) return;
    if (index == null) {
      state = state.copyWith(clearViewingMoveIndex: true);
      return;
    }
    final target = index.clamp(-1, state.moveHistory.length - 1);
    state = state.copyWith(viewingMoveIndex: target);
  }

  void stepBackward() {
    if (!state.isSessionActive) return;
    final currentIdx = state.viewingMoveIndex ?? state.moveHistory.length;
    if (currentIdx > -1) {
      navigateToMove(currentIdx - 1);
    }
  }

  void stepForward() {
    if (!state.isSessionActive) return;
    final currentIdx = state.viewingMoveIndex;
    if (currentIdx == null) return; // Already at live move
    if (currentIdx >= state.moveHistory.length - 1) {
      navigateToMove(null); // Return to live game
    } else {
      navigateToMove(currentIdx + 1);
    }
  }

  void exportSessionToAnalysis() {
    if (state.moveHistory.isEmpty) return;

    final studyNotifier = _ref.read(studyLabProvider.notifier);

    // Reset study tree's current node to the starting point
    studyNotifier.selectNode(state.startNodeIndex);

    for (final uci in state.moveHistory) {
      final from = uci.substring(0, 2);
      final to = uci.substring(2, 4);
      final promo = uci.length > 4 ? uci.substring(4, 5) : '';
      studyNotifier.makeMove(from, to, promo);
    }
  }
}

final practiceLabProvider = NotifierProvider<PracticeLabNotifier, PracticeLabState>(PracticeLabNotifier.new);
