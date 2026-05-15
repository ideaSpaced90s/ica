// Core Data Models for the Scripted Tutorial System

enum TutorialStepType {
  /// Simple dialogue sequence where GM Bard explains concepts.
  dialogue,

  /// Visual demonstration where pieces move automatically with path traces.
  demonstrate,

  /// Player must perform a specific legal move on the board.
  awaitMove,

  /// Player must tap a specific highlighted tile/piece to identify rules.
  awaitSquareTap,

  /// Small multi-move puzzle challenge reinforcing the lesson.
  miniChallenge,

  /// Chapter graduation or sub-section completion.
  celebration,
}

enum MentorMood {
  /// Default state. Calm blue tint, steady delivery.
  calm,

  /// Rewarding state. Soft green tint, joyful/celebratory feedback.
  encouraging,

  /// Corrective state. Amber tint, constructive guidance on mistakes.
  correction,

  /// Exceptional event state. Gold tint, celebratory particles.
  celebration,
}

/// Defines specific custom board overlays used to demonstrate concepts visually.
enum TutorialOverlayEffect {
  none,
  glowSquare,
  animatePath,
  dangerZone,
  knightLPath,
  bishopDiagonals,
  rookLanes,
  checkPulse,
  castlingPath,
  enPassantArrow,
}

class MentorReaction {
  final String dialogue;
  final MentorMood mood;
  final String? overlayEffectString;

  const MentorReaction({
    required this.dialogue,
    this.mood = MentorMood.calm,
    this.overlayEffectString,
  });
}

class TutorialStep {
  final TutorialStepType type;
  final String dialogue;
  final MentorMood mentorMood;

  /// Squares to glow or highlight to guide the user's attention.
  final List<String> highlightSquares;

  /// Sequence of squares defining an animated arrow or piece path demonstration.
  final List<String> animatePathSquares;

  /// The UCI move expected from the user during `awaitMove` steps (e.g. 'e2e4').
  final String? expectedMove;

  /// Alternative UCI moves that are also considered correct.
  final List<String> alternativeMoves;

  /// Optional FEN to reset the board to when this step starts.
  final String? resetToFen;

  /// Specific squares the user is allowed to tap/interact with during identifying steps.
  final List<String> allowedSquares;

  /// Visual overlay effect to apply to the board for this step.
  final TutorialOverlayEffect overlayEffect;

  /// Reaction from GM Bard when the user performs the correct action.
  final MentorReaction? reactionCorrect;

  /// Reaction from GM Bard when the user performs an incorrect or illegal action.
  final MentorReaction? reactionIllegal;

  /// Reaction from GM Bard if the user takes too long to respond.
  final MentorReaction? reactionHesitation;

  const TutorialStep({
    required this.type,
    required this.dialogue,
    this.mentorMood = MentorMood.calm,
    this.highlightSquares = const [],
    this.animatePathSquares = const [],
    this.expectedMove,
    this.alternativeMoves = const [],
    this.resetToFen,
    this.allowedSquares = const [],
    this.overlayEffect = TutorialOverlayEffect.none,
    this.reactionCorrect,
    this.reactionIllegal,
    this.reactionHesitation,
  });
}

class TutorialLesson {
  final int chapterId;
  final String title;
  final String setupFen;
  final List<TutorialStep> steps;

  const TutorialLesson({
    required this.chapterId,
    required this.title,
    required this.setupFen,
    required this.steps,
  });
}
