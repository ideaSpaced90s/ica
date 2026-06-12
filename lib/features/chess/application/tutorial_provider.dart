import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../domain/models/tutorial_constants.dart';
import '../domain/models/tutorial_lesson.dart';
import '../domain/models/tutorial_progress.dart';
import '../data/tutorial_lessons.dart';
import '../data/tutorial_progress_repository.dart';
import '../services/chess_sound_service.dart';
import 'chess_provider.dart';
import 'assignment_provider.dart';
import 'battleground_provider.dart';

final tutorialProgressRepositoryProvider = Provider<TutorialProgressRepository>((ref) {
  throw UnimplementedError('Initialized in main() ProviderScope overrides');
});

final tutorialProvider = StateNotifierProvider<TutorialNotifier, TutorialState>((ref) {
  final repo = ref.watch(tutorialProgressRepositoryProvider);
  final sounds = ref.watch(chessSoundServiceProvider);
  return TutorialNotifier(repo, sounds, ref);
});

class TutorialState {
  final chess_lib.Chess board;
  final int currentChapterIndex;
  final int currentStepIndex;
  final TutorialLesson currentLesson;
  final TutorialStep currentStep;
  final List<String> highlightSquares;
  final List<String> animatePathSquares;
  final String? glowSquare;
  final String? dangerZone;
  final String? lastMentorDialogue;
  final MentorMood mentorMood;
  final bool isAwaitingMove;
  final bool isAnimating;
  final TutorialProgress progress;
  final bool isChapterComplete;
  final bool isTutorialComplete;
  final String? illegalMoveMessage;
  final int mistakesMadeInChapter;

  TutorialState({
    required this.board,
    required this.currentChapterIndex,
    required this.currentStepIndex,
    required this.currentLesson,
    required this.currentStep,
    this.highlightSquares = const [],
    this.animatePathSquares = const [],
    this.glowSquare,
    this.dangerZone,
    this.lastMentorDialogue,
    this.mentorMood = MentorMood.calm,
    this.isAwaitingMove = false,
    this.isAnimating = false,
    required this.progress,
    this.isChapterComplete = false,
    this.isTutorialComplete = false,
    this.illegalMoveMessage,
    this.mistakesMadeInChapter = 0,
  });

  TutorialState copyWith({
    chess_lib.Chess? board,
    int? currentChapterIndex,
    int? currentStepIndex,
    TutorialLesson? currentLesson,
    TutorialStep? currentStep,
    List<String>? highlightSquares,
    List<String>? animatePathSquares,
    String? glowSquare,
    String? dangerZone,
    String? lastMentorDialogue,
    MentorMood? mentorMood,
    bool? isAwaitingMove,
    bool? isAnimating,
    TutorialProgress? progress,
    bool? isChapterComplete,
    bool? isTutorialComplete,
    String? illegalMoveMessage,
    int? mistakesMadeInChapter,
    bool clearIllegalMessage = false,
  }) {
    return TutorialState(
      board: board ?? this.board,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentLesson: currentLesson ?? this.currentLesson,
      currentStep: currentStep ?? this.currentStep,
      highlightSquares: highlightSquares ?? this.highlightSquares,
      animatePathSquares: animatePathSquares ?? this.animatePathSquares,
      glowSquare: glowSquare ?? this.glowSquare,
      dangerZone: dangerZone ?? this.dangerZone,
      lastMentorDialogue: lastMentorDialogue ?? this.lastMentorDialogue,
      mentorMood: mentorMood ?? this.mentorMood,
      isAwaitingMove: isAwaitingMove ?? this.isAwaitingMove,
      isAnimating: isAnimating ?? this.isAnimating,
      progress: progress ?? this.progress,
      isChapterComplete: isChapterComplete ?? this.isChapterComplete,
      isTutorialComplete: isTutorialComplete ?? this.isTutorialComplete,
      illegalMoveMessage: clearIllegalMessage ? null : (illegalMoveMessage ?? this.illegalMoveMessage),
      mistakesMadeInChapter: mistakesMadeInChapter ?? this.mistakesMadeInChapter,
    );
  }
}

class TutorialNotifier extends StateNotifier<TutorialState> {
  final TutorialProgressRepository _repository;
  final ChessSoundService _sounds;
  final Ref ref;
  Timer? _hesitationTimer;

  TutorialNotifier(this._repository, this._sounds, this.ref) : super(_getInitialState()) {
    _initialize();
  }

  static TutorialState _getInitialState() {
    final firstLesson = TutorialLessonsDatabase.lessons.first;
    final board = chess_lib.Chess();
    board.load(firstLesson.setupFen);
    
    return TutorialState(
      board: board,
      currentChapterIndex: 1,
      currentStepIndex: 0,
      currentLesson: firstLesson,
      currentStep: firstLesson.steps.first,
      highlightSquares: firstLesson.steps.first.highlightSquares,
      animatePathSquares: firstLesson.steps.first.animatePathSquares,
      lastMentorDialogue: firstLesson.steps.first.dialogue,
      mentorMood: firstLesson.steps.first.mentorMood,
      isAwaitingMove: firstLesson.steps.first.type == TutorialStepType.awaitMove,
      progress: const TutorialProgress(),
    );
  }

  Future<void> _initialize() async {
    final loadedProgress = await _repository.loadProgress();
    state = state.copyWith(progress: loadedProgress);
    // If an active session snapshot exists, display the custom resume banner layout.
    // The presentation layer will present the prompt inline above the chapter selection UI.
  }

  void resumeActiveSession() {
    final p = state.progress;
    if (!p.hasActiveSession) return;
    
    final chapterId = p.activeChapterIndex!;
    final stepIdx = p.activeStepIndex!;
    final fen = p.activeFenSnapshot!;

    final lesson = TutorialLessonsDatabase.getLesson(chapterId);
    final safeStepIndex = stepIdx < lesson.steps.length ? stepIdx : 0;
    final step = lesson.steps[safeStepIndex];

    final newBoard = chess_lib.Chess();
    newBoard.load(fen);

    state = state.copyWith(
      board: newBoard,
      currentChapterIndex: chapterId,
      currentStepIndex: safeStepIndex,
      currentLesson: lesson,
      currentStep: step,
      highlightSquares: step.highlightSquares,
      animatePathSquares: step.animatePathSquares,
      lastMentorDialogue: step.dialogue,
      mentorMood: step.mentorMood,
      isAwaitingMove: step.type == TutorialStepType.awaitMove,
      isChapterComplete: false,
      mistakesMadeInChapter: 0,
    );

    _sounds.playSfx(SoundEffect.bookFlip);
    _startHesitationTimer();
  }

  void loadChapter(int chapterId) {
    final lesson = TutorialLessonsDatabase.getLesson(chapterId);
    final newBoard = chess_lib.Chess();
    newBoard.load(lesson.setupFen);

    final firstStep = lesson.steps.first;
    var boardToUse = newBoard;

    // Handle automated scripted move for demonstrations on first step
    if (firstStep.scriptedMove != null && firstStep.scriptedMove!.length >= 4) {
      final from = firstStep.scriptedMove!.substring(0, 2);
      final to = firstStep.scriptedMove!.substring(2, 4);
      
      final animatedBoard = chess_lib.Chess();
      animatedBoard.load(boardToUse.fen);
      animatedBoard.move({'from': from, 'to': to, 'promotion': 'q'});
      boardToUse = animatedBoard;
      _playBoardMoveSound(boardToUse);
    }

    String mentorDialogue = firstStep.dialogue;
    try {
      final assignmentState = ref.read(assignmentProvider);
      final isRevisionMode = assignmentState.isCalibrated &&
          assignmentState.goalDeadline != null &&
          DateTime.now().isAfter(assignmentState.goalDeadline!) &&
          ref.read(battlegroundProvider).consolidatedRating < assignmentState.goalElo;

      if (isRevisionMode && chapterId >= 1 && chapterId <= 9) {
        mentorDialogue = "[REVISION MODE] Apprentice, your target deadline has passed and your rating remains below target. We must revise the fundamentals. Let's review Chapter $chapterId: ${lesson.title}.\n\n$mentorDialogue";
      }
    } catch (_) {}

    state = state.copyWith(
      board: boardToUse,
      currentChapterIndex: chapterId,
      currentStepIndex: 0,
      currentLesson: lesson,
      currentStep: firstStep,
      highlightSquares: firstStep.highlightSquares,
      animatePathSquares: firstStep.animatePathSquares,
      lastMentorDialogue: mentorDialogue,
      mentorMood: firstStep.mentorMood,
      isAwaitingMove: firstStep.type == TutorialStepType.awaitMove,
      isChapterComplete: false,
      mistakesMadeInChapter: 0,
    );

    _sounds.playSfx(SoundEffect.bookFlip);
    _startHesitationTimer();
    
    // Autosave progress update incrementally per action loop
    _autosave();
  }

  void dismissCompletionOverlay() {
    state = state.copyWith(isChapterComplete: false);
  }


  void advanceStep() {
    _cancelHesitationTimer();

    final nextStepIdx = state.currentStepIndex + 1;
    if (nextStepIdx >= state.currentLesson.steps.length) {
      _completeChapter();
      return;
    }

    final nextStep = state.currentLesson.steps[nextStepIdx];
    
    // Automatically highlight allowed squares for identification steps if not explicitly provided
    List<String> activeHighlights = nextStep.highlightSquares;
    if (nextStep.type == TutorialStepType.awaitSquareTap && activeHighlights.isEmpty) {
      activeHighlights = nextStep.allowedSquares;
    }

    // Handle mid-lesson board reset if specified
    var boardToUse = state.board;
    if (nextStep.resetToFen != null) {
      boardToUse = chess_lib.Chess();
      boardToUse.load(nextStep.resetToFen!);
    }

    // Handle automated scripted move for demonstrations
    if (nextStep.scriptedMove != null && nextStep.scriptedMove!.length >= 4) {
      final from = nextStep.scriptedMove!.substring(0, 2);
      final to = nextStep.scriptedMove!.substring(2, 4);
      
      // We must create a new board instance for Riverpod to detect the change
      final newBoard = chess_lib.Chess();
      newBoard.load(boardToUse.fen);
      newBoard.move({'from': from, 'to': to, 'promotion': 'q'});
      boardToUse = newBoard;
      _playBoardMoveSound(boardToUse);
    }

    state = state.copyWith(
      currentStepIndex: nextStepIdx,
      currentStep: nextStep,
      board: boardToUse,
      highlightSquares: activeHighlights,
      animatePathSquares: nextStep.animatePathSquares,
      lastMentorDialogue: nextStep.dialogue,
      mentorMood: nextStep.mentorMood,
      isAwaitingMove: nextStep.type == TutorialStepType.awaitMove,
      isAnimating: false,
      clearIllegalMessage: true,
    );

    _sounds.playSfx(SoundEffect.bookFlip);
    _startHesitationTimer();
    _autosave();
  }

  void handleSquareTap(String square) {
    if (state.currentStep.type != TutorialStepType.awaitSquareTap || state.isAnimating) return;

    _cancelHesitationTimer();

    if (state.currentStep.allowedSquares.contains(square)) {
      final reaction = state.currentStep.reactionCorrect;
      if (reaction != null) {
        state = state.copyWith(
          lastMentorDialogue: reaction.dialogue,
          mentorMood: reaction.mood,
          isAnimating: true,
          clearIllegalMessage: true,
        );
      }
      _sounds.playSfx(SoundEffect.capture);
      // Let user review reaction briefly before stepping ahead
      Future.delayed(const Duration(milliseconds: 1500), () {
        advanceStep();
      });
    } else {
      final reaction = state.currentStep.reactionIllegal;
      state = state.copyWith(
        illegalMoveMessage: reaction?.dialogue ?? "Incorrect square selection.",
        mentorMood: reaction?.mood ?? MentorMood.correction,
        mistakesMadeInChapter: state.mistakesMadeInChapter + 1,
      );
      _sounds.playSfx(SoundEffect.illegal);
      _startHesitationTimer();
    }
  }

  void handleMoveAttempt(String from, String to) {
    if (!state.isAwaitingMove || state.isAnimating) return;

    _cancelHesitationTimer();

    final attemptedUci = '$from$to';
    final expectedUci = state.currentStep.expectedMove;

    // Check if move matches scripted tutorial expected behavior
    bool isExpected = false;
    if (expectedUci != null) {
      final baseExpected = expectedUci.substring(0, 4);
      if (attemptedUci.startsWith(baseExpected)) {
        if (expectedUci.length > 4 && attemptedUci.length > 4) {
          // Both have specific promotion suffixes, they must match exactly
          isExpected = attemptedUci == expectedUci;
        } else {
          // Base squares match, and at least one is a simple coordinate move
          isExpected = true;
        }
      }
    }
    
    // Check alternative moves if primary didn't match
    if (!isExpected && state.currentStep.alternativeMoves.isNotEmpty) {
      isExpected = state.currentStep.alternativeMoves.any((m) {
        final baseAlternative = m.substring(0, math.min(4, m.length));
        if (attemptedUci.startsWith(baseAlternative)) {
          if (m.length > 4 && attemptedUci.length > 4) {
             return m == attemptedUci;
          }
          return true;
        }
        return false;
      });
    }

    if (isExpected) {
      // Extract promotion piece: 
      // 1. From the user's attempt if provided
      // 2. Otherwise from the lesson's expectedMove if it has one
      // 3. Finally default to queen
      String promo = 'q';
      if (attemptedUci.length > 4) {
        promo = attemptedUci[4];
      } else if (expectedUci != null && expectedUci.length > 4) {
        promo = expectedUci[4];
      }
      
      final success = state.board.move({'from': from, 'to': to, 'promotion': promo});
      if (success) {
        final reaction = state.currentStep.reactionCorrect;
        if (reaction != null) {
          state = state.copyWith(
            lastMentorDialogue: reaction.dialogue,
            mentorMood: reaction.mood,
            isAnimating: true,
            clearIllegalMessage: true,
          );
        }
        
        _playBoardMoveSound(state.board);

        // Advance to next setup after brief visual celebration delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          advanceStep();
        });
      }
    } else {
      final reaction = state.currentStep.reactionIllegal;
      state = state.copyWith(
        illegalMoveMessage: reaction?.dialogue ?? "That move does not follow the instructions.",
        mentorMood: reaction?.mood ?? MentorMood.correction,
        mistakesMadeInChapter: state.mistakesMadeInChapter + 1,
      );
      _sounds.playSfx(SoundEffect.illegal);
      _startHesitationTimer();
    }
  }

  void _completeChapter() {
    _cancelHesitationTimer();

    final chapId = state.currentChapterIndex;
    
    // Evaluate star ratings based on chapter accuracy metric
    int earnedStars = 3;
    if (state.mistakesMadeInChapter == 1) earnedStars = 2;
    if (state.mistakesMadeInChapter > 1) earnedStars = 1;

    // Update global retention parameters
    final prevBestStars = state.progress.stars[chapId] ?? 0;
    final finalStars = earnedStars > prevBestStars ? earnedStars : prevBestStars;
    
    final updatedStarsMap = Map<int, int>.from(state.progress.stars);
    updatedStarsMap[chapId] = finalStars;

    // Only grant base bonus XP once per chapter unlock
    int xpGranted = 0;
    final isFirstCompletion = !state.progress.completedChapters.contains(chapId);
    if (isFirstCompletion) {
      xpGranted = TutorialRewards.calculateXp(finalStars);
    } else if (earnedStars > prevBestStars) {
      // Grant delta difference bonus if player improved their score
      xpGranted = TutorialRewards.calculateXp(earnedStars) - TutorialRewards.calculateXp(prevBestStars);
    }

    final newTotalXp = state.progress.totalXp + xpGranted;
    final updatedCompletedSet = Set<int>.from(state.progress.completedChapters)..add(chapId);
    
    // Unlock next target chapter cleanly
    final nextChapterUnlock = chapId + 1;
    final updatedUnlockedSet = Set<int>.from(state.progress.unlockedChapters)..add(nextChapterUnlock);

    final updatedProgress = state.progress.copyWith(
      completedChapters: updatedCompletedSet,
      unlockedChapters: updatedUnlockedSet,
      stars: updatedStarsMap,
      totalXp: newTotalXp,
      currentRank: TutorialRank.fromXp(newTotalXp),
      clearActiveSession: true, // Clean mid-lesson snapshot checkpoint
    );

    state = state.copyWith(
      isChapterComplete: true,
      progress: updatedProgress,
      mentorMood: MentorMood.celebration,
      lastMentorDialogue: "Congratulations! You have completed Chapter $chapId.",
    );

    _sounds.playSfx(SoundEffect.gameover); // Existing major achievement sound

    // Save persistent updates to repository
    unawaited(_repository.saveProgress(updatedProgress));
    unawaited(_repository.clearActiveSession());
  }

  void _startHesitationTimer() {
    _cancelHesitationTimer();
    final delaySec = state.progress.settings.hesitationTimerSeconds;
    if (delaySec <= 0) return;

    _hesitationTimer = Timer(Duration(seconds: delaySec), () {
      final reaction = state.currentStep.reactionHesitation;
      if (reaction != null && mounted) {
        state = state.copyWith(
          lastMentorDialogue: reaction.dialogue,
          mentorMood: reaction.mood,
        );
        _sounds.playSfx(SoundEffect.check); // Gentle alert hint chime
      }
    });
  }

  void _cancelHesitationTimer() {
    _hesitationTimer?.cancel();
    _hesitationTimer = null;
  }

  void _playBoardMoveSound(chess_lib.Chess board) {
    if (board.history.isEmpty) return;

    if (board.in_check) {
      _sounds.playSfx(SoundEffect.check);
      return;
    }

    final lastState = board.history.last;
    final lastMove = lastState.move;

    if (lastMove.promotion != null) {
      _sounds.playSfx(SoundEffect.promote);
      return;
    }

    final pieceType = lastMove.piece.toString().toLowerCase();
    bool isCastle = false;
    if (pieceType == 'k') {
      final fromFile = lastMove.from % 8;
      final toFile = lastMove.to % 8;
      if ((fromFile - toFile).abs() == 2) {
        isCastle = true;
      }
    }

    if (isCastle) {
      _sounds.playSfx(SoundEffect.castle);
    } else if (lastMove.captured != null) {
      _sounds.playSfx(SoundEffect.capture);
    } else {
      _sounds.playSfx(SoundEffect.move);
    }
  }

  void _autosave() {
    // Non-blocking incremental active checkpoint auto-save loop
    unawaited(_repository.saveActiveSession(
      chapterIndex: state.currentChapterIndex,
      stepIndex: state.currentStepIndex,
      fenSnapshot: state.board.fen,
    ));
    
    // Keep local dynamic reference synchronized
    state = state.copyWith(
      progress: state.progress.copyWith(
        activeChapterIndex: state.currentChapterIndex,
        activeStepIndex: state.currentStepIndex,
        activeFenSnapshot: state.board.fen,
      ),
    );
  }

  void clearIllegalFeedback() {
    state = state.copyWith(clearIllegalMessage: true);
  }

  Future<void> resetAllProgress() async {
    await _repository.resetAllProgress();
    state = _getInitialState();
  }

  void updateSettings(TutorialSettings settings) {
    final updatedProgress = state.progress.copyWith(settings: settings);
    state = state.copyWith(progress: updatedProgress);
    unawaited(_repository.saveProgress(updatedProgress));
  }

  @override
  void dispose() {
    _cancelHesitationTimer();
    super.dispose();
  }
}
