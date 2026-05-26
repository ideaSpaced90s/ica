import '../domain/models/tutorial_lesson.dart';

class TutorialLessonsDatabase {
  static const List<TutorialLesson> lessons = [
    // Chapter 1: Board Introduction
    TutorialLesson(
      chapterId: 1,
      title: 'Board Introduction',
      setupFen: 'k7/8/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Apprentice. Welcome to the Academy. We are here to restore human mastery.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "64 squares. Alternating light and dark. Always keep a light square in your bottom-right corner.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Files are vertical. a to h.",
          highlightSquares: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'a8'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Ranks are horizontal. 1 to 8.",
          highlightSquares: ['a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Tap the 'e' file. Prove your grid awareness.",
          allowedSquares: ['e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8'],
          highlightSquares: ['e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8'],
          reactionCorrect: MentorReaction(
            dialogue: "Precision. Mastering the grid is the first step toward visualization.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Incorrect. The 'e' file is the fifth column from the left.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Chapter complete. Your journey into strategic warfare begins.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 2: Coordinates & Tile Identification
    TutorialLesson(
      chapterId: 2,
      title: 'Coordinates & Tiles',
      setupFen: 'k7/8/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Coordinates. Every square is a unique intersection of File and Rank.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Like e4. The intersection of the 'e' file and the 4th rank.",
          highlightSquares: ['e4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Find d5. Precision is required.",
          allowedSquares: ['d5'],
          reactionCorrect: MentorReaction(
            dialogue: "Spot on. d5 is a critical central square.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Incorrect. Trace column 'd' to row 5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Coordinates mastered. We now speak the same language.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 3: Pawn Movement
    TutorialLesson(
      chapterId: 3,
      title: 'Pawn Movement',
      setupFen: 'r3k2r/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Pawns. The foot soldiers. Humble, but they decide the war.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "One square forward. On their first move, they can leap two.",
          animatePathSquares: ['e2', 'e3', 'e4'],
          highlightSquares: ['e2', 'e3', 'e4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Command e2 to e4. Control the center.",
          highlightSquares: ['e2'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Splendid. The center is yours.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "No. March straight ahead to e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Pawn basics complete. They are the soul of chess.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 4: Rook Movement
    TutorialLesson(
      chapterId: 4,
      title: 'Rook Movement',
      setupFen: 'k7/8/8/8/3R4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Rook. A siege engine for straight open lines.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Horizontal and vertical. Any number of unblocked squares.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Slide the Rook from d4 to d8. Command the file.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d8',
          reactionCorrect: MentorReaction(
            dialogue: "Efficient. The back rank is now within reach.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Straight lines only. Move to d8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Rook mobility secured. Keep your files open.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 5: Bishop Movement
    TutorialLesson(
      chapterId: 5,
      title: 'Bishop Movement',
      setupFen: 'k7/8/8/8/3B4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Bishop. A long-range sniper on diagonals.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Color complexes are absolute. A light-square Bishop stays on light squares.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.bishopDiagonals,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Send the Bishop from d4 to h8.",
          highlightSquares: ['d4'],
          expectedMove: 'd4h8',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless. Long diagonals are dangerous attack vectors.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Diagonals only. Move to h8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Bishop tactics locked in. Slice through the board.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 6: Knight Movement
    TutorialLesson(
      chapterId: 6,
      title: 'Knight Movement',
      setupFen: 'k7/8/8/8/3N4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Knight. The trickster. They ignore walls.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The L-shape. Two squares one way, then one square perpendicular.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "They are the only units capable of leaping over others. Blockades mean nothing to them.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Execute an L-leap to f5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4f5',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Notice the color switch on every landing.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Two squares right, one square up. Move to f5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Knight mobility verified. Use their arc for unblockable forks.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 7: Queen Movement
    TutorialLesson(
      chapterId: 7,
      title: 'Queen Movement',
      setupFen: 'k7/8/8/8/3Q4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Queen. The apex predator. Absolute power.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The Rook's power combined with the Bishop's reach.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Unleash her. Move to d8.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d8',
          reactionCorrect: MentorReaction(
            dialogue: "Devastating. Guard her carefully.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Straight or diagonal. Glide to d8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Queen dominance affirmed. Tactical responsibility is yours.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 8: King Movement
    TutorialLesson(
      chapterId: 8,
      title: 'King Movement',
      setupFen: 'k7/8/8/8/3K4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The King. The ultimate objective. Lose him, and the battle ends.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "One square in any direction. Deliberate and vital.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Step cautiously to e5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4e5',
          reactionCorrect: MentorReaction(
            dialogue: "Steady. An active King is vital in the endgame.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "One square only. Move to e5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "King safety is paramount. Protect him.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 9: Capturing
    TutorialLesson(
      chapterId: 9,
      title: 'Capturing Pieces',
      setupFen: 'k7/8/8/4p3/3R4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Capturing. We don't jump; we occupy and remove.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Move onto the target's square to eliminate them.",
          highlightSquares: ['d4', 'e5'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The Rook on d4 cannot strike diagonally. Adjust position. Move to d5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d5',
          reactionIllegal: MentorReaction(
            dialogue: "Straight lines only. Move to d5.",
            mood: MentorMood.correction,
          ),
        ),
      ],
    ),

    // Chapter 10: Check
    TutorialLesson(
      chapterId: 10,
      title: 'Understanding Check',
      setupFen: '4k3/8/8/8/8/8/4r3/4K3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Check. A direct threat to your King. You cannot ignore it.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The enemy Rook aims at your King. Resolve this immediately.",
          highlightSquares: ['e1'],
          overlayEffect: TutorialOverlayEffect.checkPulse,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Step off the dangerous file. Move to d1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1d1',
          reactionCorrect: MentorReaction(
            dialogue: "Crisis averted. Evading is the simplest solution.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "You are in check. Step to d1 or f1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Check protocol understood. Never leave your King exposed.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 11: Escaping Check
    TutorialLesson(
      chapterId: 11,
      title: 'Escaping Check',
      setupFen: 'k7/8/8/8/8/8/4B3/r3K3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Escaping Check: Evade, Block, or Capture.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Flank attack. Moving the King is one option. Blocking is another.",
          highlightSquares: ['e1'],
          overlayEffect: TutorialOverlayEffect.checkPulse,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Intercept. Move the Bishop from e2 to d1. Shield the King.",
          highlightSquares: ['e2'],
          expectedMove: 'e2d1',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. Minor pieces are excellent shields.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Block the line. Move the Bishop to d1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Defense optimized. Evaluate all escape vectors.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 12: Checkmate
    TutorialLesson(
      chapterId: 12,
      title: 'Checkmate',
      setupFen: '7k/5Q2/6K1/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Checkmate. In check with zero escape. The end.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Coordinated attack. Deliver the final blow.",
          highlightSquares: ['f7'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Slide the Queen to g7. End it.",
          highlightSquares: ['f7'],
          expectedMove: 'f7g7',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate. g7 is defended by the King, leaving no escape.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move to g7. Support the kill.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Efficient. But g7 isn't the only path. The Queen has range. Let's reset.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now, find the Back-Rank Mate. f8 or e8. Strike from a distance.",
          resetToFen: '7k/5Q2/6K1/8/8/8/8/8 w - - 0 1',
          highlightSquares: ['f7'],
          expectedMove: 'f7f8',
          alternativeMoves: ['f7e8'],
          reactionCorrect: MentorReaction(
            dialogue: "Lethal. The back rank is a graveyard for trapped Kings.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Slide the Queen all the way to f8 or e8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Absolute victory. One goal, many tactical paths.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 13: Stalemate
    TutorialLesson(
      chapterId: 13,
      title: 'Stalemate',
      setupFen: '7k/8/5K2/6Q1/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Stalemate. No moves, but no check. A tragic draw.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Moving to g6 triggers an automatic draw. Avoid the trap.",
          highlightSquares: ['g6'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Make room. King to e6.",
          highlightSquares: ['f6'],
          expectedMove: 'f6e6',
          reactionCorrect: MentorReaction(
            dialogue: "Wise. Always leave breathing room.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Step back to e6.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Trap bypassed. Precision prevents draws.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 14: Kingside Castling
    TutorialLesson(
      chapterId: 14,
      title: 'Kingside Castling',
      setupFen: '4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Castling. Safeguard the King, activate the Rook. One move, two pieces.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Kingside (O-O). The path must be clear.",
          highlightSquares: ['e1', 'f1', 'g1', 'h1'],
          overlayEffect: TutorialOverlayEffect.castlingPath,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "No prior moves. Not in check. No threatened squares on the path.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Kingside Castle. Drag the King to g1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1g1',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless. King safe, Rook ready.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "King two squares right. Move to g1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Kingside fortress established. Castle early.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 15: Queenside Castling
    TutorialLesson(
      chapterId: 15,
      title: 'Queenside Castling',
      setupFen: '4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Queenside Castling (O-O-O). Identical logic, wider flank.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "King still moves two squares. Rook transits three.",
          highlightSquares: ['e1', 'd1', 'c1', 'b1', 'a1'],
          overlayEffect: TutorialOverlayEffect.castlingPath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Queenside Castle. King to c1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1c1',
          reactionCorrect: MentorReaction(
            dialogue: "Magnificent. Centralized Rook.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "King two squares left. Move to c1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Dual flank castling mastered. Keep them guessing.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 16: En Passant
    TutorialLesson(
      chapterId: 16,
      title: 'En Passant Capture',
      setupFen: 'k7/3p4/8/4P3/8/8/8/7K b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "En Passant. In passing. The elusive strike.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "An enemy pawn leaps two squares, landing adjacent to yours.",
          scriptedMove: 'd7d5',
          animatePathSquares: ['d7', 'd5'],
          highlightSquares: ['d7', 'd5'],
          overlayEffect: TutorialOverlayEffect.enPassantArrow,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Strike diagonally behind it. This right lasts for exactly one turn.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Strike. Move e5 to d6.",
          highlightSquares: ['e5'],
          expectedMove: 'e5d6',
          reactionCorrect: MentorReaction(
            dialogue: "Incredible. The bypassed unit is swept from the field.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Diagonal strike. Move to d6.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "En Passant demystified. You possess rare knowledge.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 17: Pawn Promotion
    TutorialLesson(
      chapterId: 17,
      title: 'Pawn Promotion',
      setupFen: 'k7/4P3/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Ascension. Reach the final rank and transform.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "You may exchange your pawn for a Queen, Rook, Bishop, or Knight of your color.",
          highlightSquares: ['e7', 'e8'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Push to e8. Claim your Queen—the most common choice.",
          highlightSquares: ['e7'],
          expectedMove: 'e7e8q',
          reactionCorrect: MentorReaction(
            dialogue: "A new Queen arises. Her power is absolute.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "March forward to e8 and choose the Queen.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "But mastery requires flexibility. Underpromotion is a rare but lethal tool used in grandmaster matches.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Tactical variety. Promoting to a Knight on g8 can sometimes deliver a sudden check or advantage. Try it.",
          resetToFen: 'k7/6P1/8/8/8/8/8/K7 w - - 0 1',
          highlightSquares: ['g7'],
          expectedMove: 'g7g8n',
          reactionCorrect: MentorReaction(
            dialogue: "Exceptional. Seeing beyond the Queen is the mark of a true tactician.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Select the Knight (N) for this demonstration.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Promotion verified. From foot soldier to officer, the choice is yours.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapters 18-23: Advanced Concepts and Verification matching plan outline
    TutorialLesson(
      chapterId: 18,
      title: 'Draw Conditions',
      setupFen: 'k7/8/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Draws. Repetition, Agreement, or the 50-move rule.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Knowledge of draws salvages half a point from the abyss.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    TutorialLesson(
      chapterId: 19,
      title: 'Opening Principles',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Opening Principles: Center, Develop, Castle.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Stake your claim. e2 to e4.",
          highlightSquares: ['e2'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. Space and development dictate the flow.",
            mood: MentorMood.encouraging,
          ),
        ),
      ],
    ),

    TutorialLesson(
      chapterId: 20,
      title: 'Piece Value Concepts',
      setupFen: 'k7/8/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Piece Value. Q:9, R:5, B:3, N:3, P:1.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Calculate every trade. Never lose value.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    TutorialLesson(
      chapterId: 21,
      title: 'Tactical Patterns',
      setupFen: 'k7/8/3q4/8/3N4/8/3K4/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Tactics. The Fork. One unit, two targets.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Find the geometries. Strike twice.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    TutorialLesson(
      chapterId: 22,
      title: 'Practice Challenges',
      setupFen: 'k7/8/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Theory absorbed. Now, visualization must be automatic.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Tactical awareness sharp. One trial remains.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 23: Graduation Match
    TutorialLesson(
      chapterId: 23,
      title: 'Graduation Match',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The final trial. Face Sparky. Show me your mastery.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 24: Italian Game
    TutorialLesson(
      chapterId: 24,
      title: 'Italian Game',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Italian Game. Fast development, quick pressure on the center.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Begin with the king pawn. Play e2 to e4.",
          highlightSquares: ['e2', 'e4'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Good. White claims space and opens the bishop.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Start with e2 to e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black meets the center directly.",
          scriptedMove: 'e7e5',
          highlightSquares: ['e7', 'e5'],
          animatePathSquares: ['e7', 'e5'],
          overlayEffect: TutorialOverlayEffect.animatePath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Develop with tempo. Knight g1 to f3.",
          highlightSquares: ['g1', 'f3'],
          expectedMove: 'g1f3',
          reactionCorrect: MentorReaction(
            dialogue: "The knight attacks e5 and prepares castling.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Bring the knight from g1 to f3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black defends with natural development.",
          scriptedMove: 'b8c6',
          highlightSquares: ['b8', 'c6'],
          animatePathSquares: ['b8', 'c6'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now the Italian bishop. Move f1 to c4.",
          highlightSquares: ['f1', 'c4'],
          expectedMove: 'f1c4',
          reactionCorrect: MentorReaction(
            dialogue: "Classical. The bishop eyes f7, the soft point.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Italian setup: bishop f1 to c4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Italian Game loaded. Develop quickly, aim clearly.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 25: Ruy Lopez
    TutorialLesson(
      chapterId: 25,
      title: 'Ruy Lopez',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Ruy Lopez. Pressure the defender before striking the center.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Open with e2 to e4.",
          highlightSquares: ['e2', 'e4'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Center claimed.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Play e2 to e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black mirrors the center.",
          scriptedMove: 'e7e5',
          highlightSquares: ['e7', 'e5'],
          animatePathSquares: ['e7', 'e5'],
          overlayEffect: TutorialOverlayEffect.animatePath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Knight g1 to f3. Attack the e5 pawn.",
          highlightSquares: ['g1', 'f3'],
          expectedMove: 'g1f3',
          reactionCorrect: MentorReaction(
            dialogue: "Pressure begins.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move the knight from g1 to f3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black defends e5 with Nc6.",
          scriptedMove: 'b8c6',
          highlightSquares: ['b8', 'c6'],
          animatePathSquares: ['b8', 'c6'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Pin the defender. Bishop f1 to b5.",
          highlightSquares: ['f1', 'b5', 'c6'],
          expectedMove: 'f1b5',
          reactionCorrect: MentorReaction(
            dialogue: "Ruy Lopez formed. Attack the guard, then the center.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The Spanish bishop goes from f1 to b5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "The Ruy Lopez teaches long pressure. Elegant and dangerous.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 26: Sicilian Defense
    TutorialLesson(
      chapterId: 26,
      title: 'Sicilian Defense',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Sicilian Defense. Black refuses symmetry and attacks from the flank.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "White begins with e2 to e4.",
          highlightSquares: ['e2', 'e4'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "The open-game invitation is sent.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Play e2 to e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black answers c7 to c5. The Sicilian begins.",
          scriptedMove: 'c7c5',
          highlightSquares: ['c7', 'c5', 'd4'],
          animatePathSquares: ['c7', 'c5'],
          overlayEffect: TutorialOverlayEffect.animatePath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Develop and prepare d4. Knight g1 to f3.",
          highlightSquares: ['g1', 'f3', 'd4'],
          expectedMove: 'g1f3',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. White prepares the central break.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "In the main Sicilian path, play Ng1-f3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Sicilian recognized. Asymmetry creates counterplay.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 27: Queen's Gambit
    TutorialLesson(
      chapterId: 27,
      title: "Queen's Gambit",
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Queen's Gambit. Offer a wing pawn to pressure the center.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Start with d2 to d4.",
          highlightSquares: ['d2', 'd4'],
          expectedMove: 'd2d4',
          reactionCorrect: MentorReaction(
            dialogue: "A queen-pawn game. Solid and ambitious.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Begin with d2 to d4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black contests the center with d5.",
          scriptedMove: 'd7d5',
          highlightSquares: ['d7', 'd5'],
          animatePathSquares: ['d7', 'd5'],
          overlayEffect: TutorialOverlayEffect.animatePath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Offer the gambit pawn. Move c2 to c4.",
          highlightSquares: ['c2', 'c4', 'd5'],
          expectedMove: 'c2c4',
          reactionCorrect: MentorReaction(
            dialogue: "Queen's Gambit formed. You ask Black to solve the center.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The gambit move is c2 to c4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "A classic weapon. The pawn is bait; the center is the prize.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 28: King's Indian Setup
    TutorialLesson(
      chapterId: 28,
      title: "King's Indian Setup",
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "King's Indian. Black invites a big center, then attacks it later.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "White builds the center. Play d2 to d4.",
          highlightSquares: ['d2', 'd4'],
          expectedMove: 'd2d4',
          reactionCorrect: MentorReaction(
            dialogue: "White takes space.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Start with d2 to d4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black develops the king knight to f6.",
          scriptedMove: 'g8f6',
          highlightSquares: ['g8', 'f6'],
          animatePathSquares: ['g8', 'f6'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "White supports the center. Play c2 to c4.",
          highlightSquares: ['c2', 'c4', 'd4'],
          expectedMove: 'c2c4',
          reactionCorrect: MentorReaction(
            dialogue: "The broad pawn center appears.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Play c2 to c4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black prepares the fianchetto with g6.",
          scriptedMove: 'g7g6',
          highlightSquares: ['g7', 'g6', 'g7'],
          animatePathSquares: ['g7', 'g6'],
          overlayEffect: TutorialOverlayEffect.animatePath,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "White develops naturally.",
          scriptedMove: 'g1f3',
          highlightSquares: ['g1', 'f3'],
          animatePathSquares: ['g1', 'f3'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The bishop slides to g7. Long diagonal pressure begins.",
          scriptedMove: 'f8g7',
          highlightSquares: ['f8', 'g7', 'a1', 'h8'],
          animatePathSquares: ['f8', 'g7'],
          overlayEffect: TutorialOverlayEffect.bishopDiagonals,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "White develops one more piece.",
          scriptedMove: 'b1c3',
          highlightSquares: ['b1', 'c3'],
          animatePathSquares: ['b1', 'c3'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black castles. The King's Indian shell is complete.",
          scriptedMove: 'e8g8',
          highlightSquares: ['e8', 'g8', 'h8', 'f8'],
          overlayEffect: TutorialOverlayEffect.castlingPath,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "King's Indian setup understood. Let the center come, then undermine it.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 29: Queen Mate
    TutorialLesson(
      chapterId: 29,
      title: 'Queen Mate',
      setupFen: '7k/5Q2/6K1/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Queen mate. The queen boxes the king; your king protects the final square.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black is trapped on the edge. The queen controls the escape line.",
          highlightSquares: ['h8', 'f7', 'g6'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Finish it. Move queen f7 to f8.",
          highlightSquares: ['f7', 'f8', 'h8'],
          expectedMove: 'f7f8',
          alternativeMoves: ['f7e8'],
          reactionCorrect: MentorReaction(
            dialogue: "Mate. Queen power, king support.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Use the queen to seal the edge. Qf8 or Qe8 mates.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Queen mate mastered. Never chase; restrict.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 30: Rook Mate
    TutorialLesson(
      chapterId: 30,
      title: 'Rook Mate',
      setupFen: '7k/5KR1/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Rook mate. The rook cuts the board; the king guards the rook.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black is on the edge. Your king protects g8.",
          highlightSquares: ['h8', 'g8', 'f7'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver mate. Rook g7 to g8.",
          highlightSquares: ['g7', 'g8'],
          expectedMove: 'g7g8',
          reactionCorrect: MentorReaction(
            dialogue: "Clean rook mate. The king cannot capture a protected rook.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Lift the rook from g7 to g8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Rook mate verified. Cut, approach, finish.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 31: Opposition
    TutorialLesson(
      chapterId: 31,
      title: 'Opposition',
      setupFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Opposition. Kings fight for entry squares in pawn endings.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Step to the side to force the enemy king to yield ground.",
          highlightSquares: ['e3', 'f3', 'e5', 'e2'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Take the outside shoulder. King e3 to f3.",
          highlightSquares: ['e3', 'f3'],
          expectedMove: 'e3f3',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The pawn ending is a king duel first.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move the king from e3 to f3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Opposition understood. In pawn endings, one tempo can be the whole game.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 32: Lucena Position
    TutorialLesson(
      chapterId: 32,
      title: 'Lucena Position',
      setupFen: '6k1/3PK3/8/8/8/8/7r/4R3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Lucena Position. In rook endings, build a bridge for your king.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The pawn is almost home. The rook must shield checks.",
          highlightSquares: ['d7', 'e7', 'e1', 'e4'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Build the bridge. Rook e1 to e4.",
          highlightSquares: ['e1', 'e4'],
          expectedMove: 'e1e4',
          reactionCorrect: MentorReaction(
            dialogue: "Bridge built. The king can hide from rook checks.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The bridge move is Re1-e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Lucena learned. Passed pawn plus active rook can be decisive.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 33: Philidor Position
    TutorialLesson(
      chapterId: 33,
      title: 'Philidor Position',
      setupFen: '8/7r/8/8/8/3k4/3P4/3K4 b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Philidor Position. The defender survives by holding the third rank.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Keep the rook active and deny the attacking king shelter.",
          highlightSquares: ['h7', 'h6', 'd2', 'd3'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Set the drawing wall. Rook h7 to h6.",
          highlightSquares: ['h7', 'h6'],
          expectedMove: 'h7h6',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. The third rank defense holds the draw.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move the rook from h7 to h6.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Philidor secured. Defense is a skill, not a surrender.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 34: Saavedra Study
    TutorialLesson(
      chapterId: 34,
      title: 'Saavedra Study',
      setupFen: '8/2P5/1K1k4/3r4/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Saavedra Study. Sometimes the strongest promotion is not a queen.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The c-pawn reaches glory, but queen promotion allows defensive tricks.",
          highlightSquares: ['c7', 'c8', 'd5', 'd6'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Find the famous move. Promote c7 to c8 as a rook.",
          highlightSquares: ['c7', 'c8'],
          expectedMove: 'c7c8r',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. Underpromotion creates the win.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Choose rook promotion. c7 to c8 equals rook.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Saavedra remembered. Mastery means choosing the exact piece.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 35: Two Bishops Mate
    TutorialLesson(
      chapterId: 35,
      title: 'Two Bishops Mate',
      setupFen: '7k/8/8/8/8/8/8/2B1KB2 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Two Bishops. They slice the board like scissors. To mate, the enemy King must be driven to a corner.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "We start by coordinating the Bishops to build a wall. Bishop to d3.",
          animatePathSquares: ['f1', 'e2', 'd3'],
          highlightSquares: ['f1', 'd3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Command the light-squared bishop. Move f1 to d3.",
          highlightSquares: ['f1'],
          expectedMove: 'f1d3',
          reactionCorrect: MentorReaction(
            dialogue: "Good. The light squares are controlled.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Play f1 to d3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King begins to retreat towards the corner.",
          scriptedMove: 'h8g7',
          animatePathSquares: ['h8', 'g7'],
          highlightSquares: ['h8', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now move the dark-squared bishop to g5 to restrict the King further.",
          highlightSquares: ['c1'],
          expectedMove: 'c1g5',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent! The bishops now control a tight diagonal grid.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move c1 to g5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats further. King to f7.",
          scriptedMove: 'g7f7',
          animatePathSquares: ['g7', 'f7'],
          highlightSquares: ['g7', 'f7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Shift the light-squared bishop to f5 to lock the King in.",
          highlightSquares: ['d3'],
          expectedMove: 'd3f5',
          reactionCorrect: MentorReaction(
            dialogue: "Magnificent. The King is trapped on the back ranks.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move d3 to f5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King runs to g7. Now we must bring our King up.",
          scriptedMove: 'f7g7',
          animatePathSquares: ['f7', 'g7'],
          highlightSquares: ['f7', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Bring your King. Move e1 to f2.",
          highlightSquares: ['e1'],
          expectedMove: 'e1f2',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. King participation is vital.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Play e1 to f2.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King shuffles to f7. We advance our King to g3.",
          scriptedMove: 'g7f7',
          animatePathSquares: ['g7', 'f7'],
          highlightSquares: ['g7', 'f7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "King to g3. Support your bishops.",
          highlightSquares: ['f2'],
          expectedMove: 'f2g3',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. Step by step, the net closes.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move your King to g3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King to g7. King to h4.",
          scriptedMove: 'f7g7',
          animatePathSquares: ['f7', 'g7'],
          highlightSquares: ['f7', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "King to h4. Take space.",
          highlightSquares: ['g3'],
          expectedMove: 'g3h4',
          reactionCorrect: MentorReaction(
            dialogue: "Outstanding. The opposing King has very few squares left.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King to f7. King to h5.",
          scriptedMove: 'g7f7',
          animatePathSquares: ['g7', 'f7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "King to h5.",
          highlightSquares: ['h4'],
          expectedMove: 'h4h5',
          reactionCorrect: MentorReaction(
            dialogue: "The White King is perfectly positioned.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King to g7. Now the bishops confine him to the edge: Bishop to g6.",
          scriptedMove: 'f7g7',
          animatePathSquares: ['f7', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Seal him in. Move f5 to g6.",
          highlightSquares: ['f5'],
          expectedMove: 'f5g6',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The King is trapped on h8 and g8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to g8.",
          scriptedMove: 'g7g8',
          animatePathSquares: ['g7', 'g8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Position the King. Move h5 to h6.",
          highlightSquares: ['h5'],
          expectedMove: 'h5h6',
          reactionCorrect: MentorReaction(
            dialogue: "Almost there. The King is ready to support the final blow.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to f8.",
          scriptedMove: 'g8f8',
          animatePathSquares: ['g8', 'f8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Restrict him. Move g6 to h5.",
          highlightSquares: ['g6'],
          expectedMove: 'g6h5',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. Now he must go back to g8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to g8.",
          scriptedMove: 'f8g8',
          animatePathSquares: ['f8', 'g8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Drive him back. Move g5 to e7.",
          highlightSquares: ['g5'],
          expectedMove: 'g5e7',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Black King is forced back to h8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to h8.",
          scriptedMove: 'g8h8',
          animatePathSquares: ['g8', 'h8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Move your light bishop to g4.",
          highlightSquares: ['h5'],
          expectedMove: 'h5g4',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. Prepare the checks.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to g8.",
          scriptedMove: 'h8g8',
          animatePathSquares: ['h8', 'g8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver the first check. Bishop g4 to e6.",
          highlightSquares: ['g4'],
          expectedMove: 'g4e6',
          reactionCorrect: MentorReaction(
            dialogue: "Check! Black King is forced to h8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to h8.",
          scriptedMove: 'g8h8',
          animatePathSquares: ['g8', 'h8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver the final blow. Bishop e7 to f6 mate.",
          highlightSquares: ['e7'],
          expectedMove: 'e7f6',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! The two bishops have successfully sealed the win.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Two Bishops Mate complete. The ultimate demonstration of diagonal control.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 36: Knight & Bishop Mate
    TutorialLesson(
      chapterId: 36,
      title: 'Knight & Bishop Mate',
      setupFen: 'k7/8/2K5/3N4/5B2/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Knight and Bishop Mate. The most difficult elementary mate. You must drive the King to the corner of the same color as your bishop.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "In this position, the light-squared bishop requires a light corner (a1 or h8) to mate. The King starts in the wrong corner (a8). We will use the W-maneuver to drive him to a1.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Begin by checking. Move the Knight d5 to b6.",
          highlightSquares: ['d5'],
          expectedMove: 'd5b6',
          reactionCorrect: MentorReaction(
            dialogue: "Check! Black King is forced to a7.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to a7.",
          scriptedMove: 'a8a7',
          animatePathSquares: ['a8', 'a7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now prevent the King from escaping back. Move bishop f4 to c7.",
          highlightSquares: ['f4'],
          expectedMove: 'f4c7',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The King cannot return to a8. He must move to a6.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to a6.",
          scriptedMove: 'a7a6',
          animatePathSquares: ['a7', 'a6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Perfect. Now restrict him further. Move bishop c7 to b8.",
          highlightSquares: ['c7'],
          expectedMove: 'c7b8',
          reactionCorrect: MentorReaction(
            dialogue: "Great. Now he must move down the file to a5.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to a5.",
          scriptedMove: 'a6a5',
          animatePathSquares: ['a6', 'a5'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now redeploy the Knight to block escape squares. Move b6 to d5.",
          highlightSquares: ['b6'],
          expectedMove: 'b6d5',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Black King moves to a4.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to a4.",
          scriptedMove: 'a5a4',
          animatePathSquares: ['a5', 'a4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Bring your King. Move c6 to c5.",
          highlightSquares: ['c6'],
          expectedMove: 'c6c5',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. Black King must move to b3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to b3.",
          scriptedMove: 'a4b3',
          animatePathSquares: ['a4', 'b3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Reposition the Knight. Move d5 to b4.",
          highlightSquares: ['d5'],
          expectedMove: 'd5b4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The Knight controls critical escape routes. Black King goes to c3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to c3.",
          scriptedMove: 'b3c3',
          animatePathSquares: ['b3', 'c3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Return your Bishop to f4.",
          highlightSquares: ['b8'],
          expectedMove: 'b8f4',
          reactionCorrect: MentorReaction(
            dialogue: "Good. The Bishop takes control of the diagonal. Black King moves back to b3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to b3.",
          scriptedMove: 'c3b3',
          animatePathSquares: ['c3', 'b3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now move Bishop f4 to e5 to guard the d6 and c7 squares.",
          highlightSquares: ['f4'],
          expectedMove: 'f4e5',
          reactionCorrect: MentorReaction(
            dialogue: "Wonderful. Black King is driven back to a4.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to a4.",
          scriptedMove: 'b3a4',
          animatePathSquares: ['b3', 'a4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Bring the King down. Move c5 to c4.",
          highlightSquares: ['c5'],
          expectedMove: 'c5c4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The King takes the opposition. Black King moves to a5.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to a5.",
          scriptedMove: 'a4a5',
          animatePathSquares: ['a4', 'a5'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver check. Move Bishop e5 to c7.",
          highlightSquares: ['e5'],
          expectedMove: 'e5c7',
          reactionCorrect: MentorReaction(
            dialogue: "Check! The King must retreat to a4.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to a4.",
          scriptedMove: 'a5a4',
          animatePathSquares: ['a5', 'a4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Move your Knight b4 to d3 to prepare the final corral.",
          highlightSquares: ['b4'],
          expectedMove: 'b4d3',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. Black King must go to a3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to a3.",
          scriptedMove: 'a4a3',
          animatePathSquares: ['a4', 'a3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Bishop c7 to b6. Guard a5.",
          highlightSquares: ['c7'],
          expectedMove: 'c7b6',
          reactionCorrect: MentorReaction(
            dialogue: "Good. The King is forced to a4.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to a4.",
          scriptedMove: 'a3a4',
          animatePathSquares: ['a3', 'a4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Check! Knight d3 to b2.",
          highlightSquares: ['d3'],
          expectedMove: 'd3b2',
          reactionCorrect: MentorReaction(
            dialogue: "Check! Black King goes back to a3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to a3.",
          scriptedMove: 'a4a3',
          animatePathSquares: ['a4', 'a3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Move King c4 to c3.",
          highlightSquares: ['c4'],
          expectedMove: 'c4c3',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The King moves closer. Black King goes to a2.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to a2.",
          scriptedMove: 'a3a2',
          animatePathSquares: ['a3', 'a2'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "King c3 to c2. Maintain the wall.",
          highlightSquares: ['c3'],
          expectedMove: 'c3c2',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Black King is forced to a3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to a3.",
          scriptedMove: 'a2a3',
          animatePathSquares: ['a2', 'a3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Check! Bishop b6 to c5.",
          highlightSquares: ['b6'],
          expectedMove: 'b6c5',
          reactionCorrect: MentorReaction(
            dialogue: "Check! Black King goes back to a2.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to a2.",
          scriptedMove: 'a3a2',
          animatePathSquares: ['a3', 'a2'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now move your Knight b2 to d3. Prepare the final mate.",
          highlightSquares: ['b2'],
          expectedMove: 'b2d3',
          reactionCorrect: MentorReaction(
            dialogue: "Great. Black King is forced to a1 (the light corner!).",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to a1.",
          scriptedMove: 'a2a1',
          animatePathSquares: ['a2', 'a1'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Bishop c5 to b4. Contain the King.",
          highlightSquares: ['c5'],
          expectedMove: 'c5b4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The King must go to a2.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King goes to a2.",
          scriptedMove: 'a1a2',
          animatePathSquares: ['a1', 'a2'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Knight d3 to c1 check! Force him back.",
          highlightSquares: ['d3'],
          expectedMove: 'd3c1',
          reactionCorrect: MentorReaction(
            dialogue: "Check! Black King must return to a1.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to a1.",
          scriptedMove: 'a2a1',
          animatePathSquares: ['a2', 'a1'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver the final blow. Bishop b4 to c3 checkmate!",
          highlightSquares: ['b4'],
          expectedMove: 'b4c3',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! The Knight and Bishop checkmate is complete.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Masterful. You have successfully executed the most complex mate in chess.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 37: Légal's Mate
    TutorialLesson(
      chapterId: 37,
      title: "Légal's Mate",
      setupFen: 'rn1qk2r/ppp2ppp/3p1n2/4p3/2BPP1b1/2N2N2/PPP2PPP/R1BQK2R w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Légal's Mate. A legendary opening trap in Philidor's Defense. White sacrifices the Queen to deliver a lightning-fast mate with minor pieces.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Black Bishop pins White's Knight on f3. White has a central break ready.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Capture the e5 pawn with your d4 pawn. Play d4xe5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4e5',
          reactionCorrect: MentorReaction(
            dialogue: "Good. This tests Black's understanding of the pin.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black captures back on e5, thinking the pinned Knight cannot move.",
          scriptedMove: 'd6e5',
          animatePathSquares: ['d6', 'e5'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Shock them. Ignore the pin and capture the e5 Knight with your f3 Knight!",
          highlightSquares: ['f3'],
          expectedMove: 'f3e5',
          reactionCorrect: MentorReaction(
            dialogue: "Sensational! The Queen is offered as bait.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black takes the bait! Bishop takes Queen on d1.",
          scriptedMove: 'g4d1',
          animatePathSquares: ['g4', 'd1'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver the first strike. Bishop c4 takes f7 with check.",
          highlightSquares: ['c4'],
          expectedMove: 'c4f7',
          reactionCorrect: MentorReaction(
            dialogue: "Check! Black King must step to e7.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King steps to e7.",
          scriptedMove: 'e8e7',
          animatePathSquares: ['e8', 'e7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver checkmate. Move Knight c3 to d5.",
          highlightSquares: ['c3'],
          expectedMove: 'c3d5',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! The Queen is gone, but the two Knights and Bishop seal the victory.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Légal's Mate complete. Always calculate concrete checkmates before worrying about material.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 38: Pawn Breakthrough
    TutorialLesson(
      chapterId: 38,
      title: 'Pawn Breakthrough',
      setupFen: '8/ppp5/8/PPP5/8/8/8/k6K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Pawn Breakthrough. In late endgames, a group of pawns can breakthrough to create a passed pawn, even without King support.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Here, White has 3 pawns against 3. We must sacrifice pawns to force one through.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Advance the center pawn to b6. Play b5 to b6.",
          highlightSquares: ['b5'],
          expectedMove: 'b5b6',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. This center push divides the defense.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black captures the center pawn. axg6 (a7xb6).",
          scriptedMove: 'a7b6',
          animatePathSquares: ['a7', 'b6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now push the opposite pawn! Move c5 to c6.",
          highlightSquares: ['c5'],
          expectedMove: 'c5c6',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant! This blockades the b-pawn and opens the path for the a-pawn.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black is forced to capture: bxc6.",
          scriptedMove: 'b7c6',
          animatePathSquares: ['b7', 'c6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now the path is clear. Push the passed pawn: a5 to a6.",
          highlightSquares: ['a5'],
          expectedMove: 'a5a6',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. The a-pawn is unstoppable and will queen.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Breakthrough complete. Knowing when and how to break pawn walls is a master skill.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 39: Wrong Bishop Draw
    TutorialLesson(
      chapterId: 39,
      title: 'Wrong Bishop Draw',
      setupFen: '7k/8/7P/8/8/8/4B3/6K1 b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Wrong Bishop Draw. In chess endings, a Bishop and a Rook pawn cannot win if the Bishop cannot control the promotion square.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Here, White has a light-squared Bishop, but the h8 corner (promotion square) is dark. Black can draw easily.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "As Black, play defensively to hold the draw.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Move your King to g8 to stay close to the corner.",
          highlightSquares: ['h8'],
          expectedMove: 'h8g8',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. Keep the King on the corner squares.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "White tries to push: Bishop to c4.",
          scriptedMove: 'e2c4',
          animatePathSquares: ['e2', 'c4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Go back to the corner. King to h8.",
          highlightSquares: ['g8'],
          expectedMove: 'g8h8',
          reactionCorrect: MentorReaction(
            dialogue: "Spot on. White cannot check you on h8 since the bishop is light-squared.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "White pushes the pawn: h6 to h7. Since the light-squared bishop cannot control h8, Black King is trapped but not in check. This is Stalemate!",
          scriptedMove: 'h6h7',
          animatePathSquares: ['h6', 'h7'],
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Draw recognized! You successfully held the wrong Bishop corner to save a draw.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 40: The Principle of Mobility
    TutorialLesson(
      chapterId: 40,
      title: 'The Principle of Mobility',
      setupFen: '8/8/4k1p1/3p1p1p/3P1P1P/6PB/5K2/8 b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Principle of Mobility. A piece's value is directly tied to its activity. A piece that cannot move is practically useless.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "In this position, White's Bishop is trapped on h3 behind its own pawn chain. Black's King and Knight are highly mobile and will dominate.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King begins to advance into the center. King to d6.",
          scriptedMove: 'e6d6',
          animatePathSquares: ['e6', 'd6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Pace your Bishop. Move h3 to f1.",
          highlightSquares: ['h3'],
          expectedMove: 'h3f1',
          reactionCorrect: MentorReaction(
            dialogue: "Good. But note how the Bishop can only move back and forth, unable to cross the pawn wall.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King marches further to c6.",
          scriptedMove: 'd6c6',
          animatePathSquares: ['d6', 'c6'],
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Mobility concept complete. Always strive to keep your pieces active and avoid blockading your own bishops.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 41: The Pawn Chain
    TutorialLesson(
      chapterId: 41,
      title: 'The Pawn Chain',
      setupFen: '6k1/pp4pp/2p1p3/3pP3/3P4/2P1P3/PP3PPP/6K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Pawn Chain. Pawn chains control space and lock diagonals. To break them, you must target the base of the chain.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Here, White has a strong pawn chain. We want to undermine Black's pawn structure by attacking its base.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Advance the f-pawn to challenge the chain. Play f2 to f3.",
          highlightSquares: ['f2'],
          expectedMove: 'f2f3',
          reactionCorrect: MentorReaction(
            dialogue: "Correct! This prepares to strike at the center chain.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black advances the King to protect the pawns.",
          scriptedMove: 'g8f7',
          animatePathSquares: ['g8', 'f7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now push further to establish space. Play f3 to f4.",
          highlightSquares: ['f3'],
          expectedMove: 'f3f4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. White expands on the kingside and pressures the base.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Pawn Chain concept complete. Targeting the base is the key to breaking defensive lines.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 42: The Backward Pawn
    TutorialLesson(
      chapterId: 42,
      title: 'The Backward Pawn',
      setupFen: 'r4rk1/1pp1qppp/3p4/3Np3/4P3/1P1P4/1PP2PPP/R4RK1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Backward Pawn. A pawn that has lagged behind its neighbors and cannot be protected by other pawns is a weakness.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black's d6 pawn is backward. The d5 square in front of it is a 'hole' (outpost) where White's Knight is perfectly placed.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Use your Knight outpost to attack the Queen. Move d5 to e7 check.",
          highlightSquares: ['d5'],
          expectedMove: 'd5e7',
          reactionCorrect: MentorReaction(
            dialogue: "Sensational! The Knight penetrates the defenses.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to step away. King to h8.",
          scriptedMove: 'g8h8',
          animatePathSquares: ['g8', 'h8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now capture the passive Rook on c8.",
          highlightSquares: ['e7'],
          expectedMove: 'e7c8',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant! The active outpost Knight wins material.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Backward Pawn lesson complete. Place pieces in weak holes to dominate the board.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 43: Doubled Pawns
    TutorialLesson(
      chapterId: 43,
      title: 'Doubled Pawns',
      setupFen: '6k1/pp1p1ppp/2p5/2P5/8/P7/1P1P1PPP/6K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Doubled Pawns. Pawns of the same color on the same file have reduced mobility and cannot support one another.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black has doubled pawns on c6 and c7. The c7 pawn is blocked and cannot defend c6. We must fix and exploit this.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Advance your d-pawn to control the center. Move d2 to d4.",
          highlightSquares: ['d2'],
          expectedMove: 'd2d4',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. We take control of the d-file.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black moves the King towards the center.",
          scriptedMove: 'g8f8',
          animatePathSquares: ['g8', 'f8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Push to d5 to blockade the pawns. Move d4 to d5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d5',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. Black's pawns are completely locked and immobile.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Doubled Pawns lesson complete. Fix and restrict weak doubled pawns to stifle your opponent.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 44: Open Files & Penetration
    TutorialLesson(
      chapterId: 44,
      title: 'Open Files & Penetration',
      setupFen: 'r5k1/pp3ppp/8/8/8/8/PP3PPP/4R1K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Open Files & Penetration. Rooks belong on open files. From there, they can invade the enemy camp.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The e-file is completely open. White's Rook must seize it and invade the 7th rank.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Invade the 7th rank! Move Rook to e7.",
          highlightSquares: ['e1'],
          expectedMove: 'e1e7',
          reactionCorrect: MentorReaction(
            dialogue: "Superb! The Rook on the 7th rank attacks Black's pawns on a7 and b7.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black Rook moves to d8, creating checkmate threats on the back rank.",
          scriptedMove: 'a8d8',
          animatePathSquares: ['a8', 'd8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Prevent back-rank mate by creating a flight square for your King. Move h2 to h3.",
          highlightSquares: ['h2'],
          expectedMove: 'h2h3',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. Creating 'luft' (a flight square) is essential for safety.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Open Files lesson complete. Control files and occupy the 7th rank to win games.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 45: Undermining (Removing the Guard)
    TutorialLesson(
      chapterId: 45,
      title: 'Undermining',
      setupFen: 'r3k2r/pp3ppp/2n1b3/8/1b1q4/2N2B2/PP3PPP/R2QK1NR w KQkq - 0 10',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Undermining is the tactical deletion of a defending piece. Look at Black's Queen on d4. It is defended by the Knight on c6.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "If we capture the c6 Knight with check, Black is forced to respond, leaving their Queen unprotected.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Eliminate the defender! Capture the Knight on c6 with your Bishop.",
          highlightSquares: ['f3', 'c6'],
          expectedMove: 'f3c6',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. Black must deal with the check first.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black is forced to capture back with the pawn.",
          scriptedMove: 'b7c6',
          animatePathSquares: ['b7', 'c6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now, Black's Queen is undefended. Capture it with your Queen!",
          highlightSquares: ['d1', 'd4'],
          expectedMove: 'd1d4',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. You won the Queen and simplified the position.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Undermining complete. By removing the guard, you won the enemy Queen.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 46: Overloading
    TutorialLesson(
      chapterId: 46,
      title: 'Overloading',
      setupFen: 'r2qk1nr/2pbbppp/2np4/1p6/2B1P3/1BN2N2/PP3PPP/R1BQ1RK1 w kq - 0 10',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Overloading occurs when a single piece has too many defensive responsibilities. Black's Bishop on d7 is guarding the Knight on c6, but it also must block any threats to the f7 square.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Create the first threat! Move your Queen to d5, targeting the weak f7 square.",
          highlightSquares: ['d1', 'd5'],
          expectedMove: 'd1d5',
          reactionCorrect: MentorReaction(
            dialogue: "Outstanding. You are threatening mate on f7.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black attempts to defend f7 by blocking with the Bishop to e6.",
          scriptedMove: 'd7e6',
          animatePathSquares: ['d7', 'e6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Black's Bishop has abandoned the Knight on c6 to protect f7. Capture the Knight on c6 with check!",
          highlightSquares: ['d5', 'c6'],
          expectedMove: 'd5c6',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect! You win the Knight because the Bishop was overloaded.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Overloading lesson complete. By creating multiple threats, you overloaded the d7 defender.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 47: Decoy & Attraction
    TutorialLesson(
      chapterId: 47,
      title: 'Decoy & Attraction',
      setupFen: 'rnb1kbnr/ppp2ppp/5q2/4p3/2B1q3/5N2/PPPP1PPP/RNBQ1RK1 w kq - 0 5',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Decoy and Attraction force an enemy piece onto a bad square using a sacrifice, setting up a follow-up double attack.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Lure the King! Sacrifice your Bishop by capturing on f7 with check.",
          highlightSquares: ['c4', 'f7'],
          expectedMove: 'c4f7',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. The King is forced to capture the Bishop.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to capture the Bishop.",
          scriptedMove: 'e8f7',
          animatePathSquares: ['e8', 'f7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The King has been attracted to f7. Move your Knight to g5 check, setting up a fork on the King and the Queen.",
          highlightSquares: ['f3', 'g5'],
          expectedMove: 'f3g5',
          reactionCorrect: MentorReaction(
            dialogue: "Incredible check. The King must run, leaving the Queen behind.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to e8.",
          scriptedMove: 'f7e8',
          animatePathSquares: ['f7', 'e8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Execute the fork! Capture Black's Queen on e4 with your Knight.",
          highlightSquares: ['g5', 'e4'],
          expectedMove: 'g5e4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent! You have successfully traded a Bishop for Black's Queen.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Decoy and Attraction complete. The sacrifice lured the King forward and won the Queen.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 48: Clearance & Vacating
    TutorialLesson(
      chapterId: 48,
      title: 'Clearance & Vacating',
      setupFen: 'rnbq1bnr/pp2k1pp/8/3QN3/2BPp3/8/PPP2PPP/RNB1K2R w KQ - 1 9',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Clearance is the tactical vacating of a square or line to allow another piece to deploy a decisive threat.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "White wants to checkmate with the Queen on e5, but our own Knight on e5 blocks the path.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Clear the e5 square with a forcing check! Move Knight to g6 check.",
          highlightSquares: ['e5', 'g6'],
          expectedMove: 'e5g6',
          reactionCorrect: MentorReaction(
            dialogue: "Well played. The Knight vacates e5 with check.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black captures the Knight with the h7 pawn.",
          scriptedMove: 'h7g6',
          animatePathSquares: ['h7', 'g6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The e5 square is clear! Move your Queen to e5 to deliver a crushing check.",
          highlightSquares: ['d5', 'e5'],
          expectedMove: 'd5e5',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The Queen occupies e5 and delivers a mating blow.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Clearance complete. By sacrificing the Knight, you cleared the path for the Queen's checkmate.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 49: Interference
    TutorialLesson(
      chapterId: 49,
      title: 'Interference',
      setupFen: 'r4bk1/pp1q2pp/2n1R3/6N1/2pp2P1/5Q2/PP3P1P/2B3K1 w - - 1 17',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Interference breaks the defensive communication between two enemy pieces by placing a blocking piece in their path.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black's Queen on d7 and Bishop on f8 both defend the critical f7 square. We can disrupt this coordination.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Interfere! Sacrifice your Rook by moving it to e7.",
          highlightSquares: ['e6', 'e7'],
          expectedMove: 'e6e7',
          reactionCorrect: MentorReaction(
            dialogue: "Magnificent Rook placement. The Queen must capture it.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black's Queen is forced to capture the Rook.",
          scriptedMove: 'd7e7',
          animatePathSquares: ['d7', 'e7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now the communication is broken. Move your Queen to d5 to check the King.",
          highlightSquares: ['f3', 'd5'],
          expectedMove: 'f3d5',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent check. Black's King is in massive trouble.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black blocks the check with the Queen on e6.",
          scriptedMove: 'e7e6',
          animatePathSquares: ['e7', 'e6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver checkmate! Capture the Queen on e6.",
          highlightSquares: ['d5', 'e6'],
          expectedMove: 'd5e6',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! A spectacular finish.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Interference complete. The Rook sacrifice broke Black's defense and paved the way to victory.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 50: Zwischenzug (The In-Between Move)
    TutorialLesson(
      chapterId: 50,
      title: 'Zwischenzug',
      setupFen: 'r1bq1b1r/ppp3kp/2N2np1/3Q4/8/8/PPP2PPP/RNB1K2R w KQ - 1 10',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Zwischenzug is German for 'in-between move'. It is an unexpected forcing move inserted before completing an exchange.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black has just played Knight to f6, hoping that if White captures on d8, Black can capture on d5. But we have a forcing check first.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Play the intermediate check! Move Bishop to h6 check.",
          highlightSquares: ['c1', 'h6'],
          expectedMove: 'c1h6',
          reactionCorrect: MentorReaction(
            dialogue: "Fantastic check. Black's King is forced to capture the Bishop.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to capture the Bishop.",
          scriptedMove: 'g7h6',
          animatePathSquares: ['g7', 'h6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Follow up with another check! Move your Queen to d2.",
          highlightSquares: ['d5', 'd2'],
          expectedMove: 'd5d2',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. The King must retreat to safety.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to g7.",
          scriptedMove: 'h6g7',
          animatePathSquares: ['h6', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now, capture the Black Queen on d8 with your Knight!",
          highlightSquares: ['c6', 'd8'],
          expectedMove: 'c6d8',
          reactionCorrect: MentorReaction(
            dialogue: "Amazing! You saved your Queen and won Black's Queen.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Zwischenzug complete. The intermediate checks saved our Queen and won Black's Queen.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 51: The Windmill Combination
    TutorialLesson(
      chapterId: 51,
      title: 'The Windmill',
      setupFen: '6k1/pp4bp/2pr4/4p3/8/1P1P4/P1P1q1RP/2B3RK w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Windmill is a sequence of discovered checks and captures where a Rook and a Bishop operate in perfect harmony.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Initiate the windmill! Capture the Bishop on g7 with check.",
          highlightSquares: ['g2', 'g7'],
          expectedMove: 'g2g7',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The King must run to h8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King escapes to h8.",
          scriptedMove: 'g8h8',
          animatePathSquares: ['g8', 'h8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver checkmate! Move the Rook to g8.",
          highlightSquares: ['g7', 'g8'],
          expectedMove: 'g7g8',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! The windmill engine successfully delivers mate.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Windmill combination complete. You swept the defense and delivered checkmate.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 52: Lasker's Double Bishop Sacrifice
    TutorialLesson(
      chapterId: 52,
      title: "Lasker's Double Sacrifice",
      setupFen: 'r4rk1/1b2bpp1/ppq1p3/2ppB2n/5P2/1P1BP3/P1PPQ1PP/R4RK1 w - - 0 15',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Lasker's Double Bishop Sacrifice is a classic attack. We sacrifice both Bishops on h7 and g7 to strip the enemy King's pawn shield.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Sacrifice the first Bishop! Capture on h7 with check.",
          highlightSquares: ['d3', 'h7'],
          expectedMove: 'd3h7',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. The King captures the Bishop.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King captures the Bishop.",
          scriptedMove: 'g8h7',
          animatePathSquares: ['g8', 'h7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Bring in the Queen! Capture the Knight on h5 with check.",
          highlightSquares: ['e2', 'h5'],
          expectedMove: 'e2h5',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect check. The King must run back to g8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to g8.",
          scriptedMove: 'h7g8',
          animatePathSquares: ['h7', 'g8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Sacrifice the second Bishop! Capture the pawn on g7.",
          highlightSquares: ['e5', 'g7'],
          expectedMove: 'e5g7',
          reactionCorrect: MentorReaction(
            dialogue: "Beautiful! The King is lured out to g7.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King captures the second Bishop.",
          scriptedMove: 'g8g7',
          animatePathSquares: ['g8', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Check again! Move Queen to g4 check.",
          highlightSquares: ['h5', 'g4'],
          expectedMove: 'h5g4',
          reactionCorrect: MentorReaction(
            dialogue: "Great check. Black's King must seek refuge on h7.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King escapes to h7.",
          scriptedMove: 'g7h7',
          animatePathSquares: ['g7', 'h7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Complete the attack! Lift the Rook to f3, preparing Rh3+ and mate.",
          highlightSquares: ['f1', 'f3'],
          expectedMove: 'f1f3',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless. Black has no defense against Rook to h3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Lasker's Sacrifice complete. The double bishop sacrifice destroyed Black's castle.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 53: Alekhine's Gun
    TutorialLesson(
      chapterId: 53,
      title: "Alekhine's Gun",
      setupFen: '2r2rk1/1q2bppp/p2p1n2/3P4/1p1BP3/1P1R4/P1R1Q1PP/5B1K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Alekhine's Gun is a heavy-piece battery where two Rooks are doubled on a file with the Queen backing them up.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Prepare to double your Rooks! Move Rook to d2.",
          highlightSquares: ['d3', 'd2'],
          expectedMove: 'd3d2',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Rooks will now double and dominate the c-file.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Alekhine's Gun lesson complete. Aligning Rooks and Queen on an open file yields absolute control.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 54: Steinitz's Queenside Majority
    TutorialLesson(
      chapterId: 54,
      title: "Steinitz's Majority",
      setupFen: '8/8/6k1/p1pp4/P1P5/1P6/5K2/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Steinitz's Queenside Pawn Majority. Having more pawns on one side allows you to create a passed pawn to win endgames.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Initiate the pawn breakthrough! Capture the d5 pawn.",
          highlightSquares: ['c4', 'd5'],
          expectedMove: 'c4d5',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. Capturing creates a distant passed pawn.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Steinitz's Majority complete. A passed pawn is a powerful weapon in endgames.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),
  ];

  static TutorialLesson getLesson(int chapterId) {
    return lessons.firstWhere(
      (l) => l.chapterId == chapterId,
      orElse: () => lessons.first,
    );
  }
}
