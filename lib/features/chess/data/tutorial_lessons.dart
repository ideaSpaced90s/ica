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
  ];

  static TutorialLesson getLesson(int chapterId) {
    return lessons.firstWhere(
      (l) => l.chapterId == chapterId,
      orElse: () => lessons.first,
    );
  }
}
