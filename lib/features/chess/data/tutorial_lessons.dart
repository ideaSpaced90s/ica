import '../domain/models/tutorial_lesson.dart';

class TutorialLessonsDatabase {
  static const List<TutorialLesson> lessons = [
    // Chapter 1: Board Introduction (old 1)
    TutorialLesson(
      chapterId: 1,
      title: 'Board Introduction',
      setupFen: 'k7/8/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Apprentice. Welcome to my Academy. I am here to forge you into a player worthy of the board.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "64 squares. Light and dark, alternating. The light square must always sit at your bottom-right. I check this before every game.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Files run vertically. I label them a through h, left to right.",
          highlightSquares: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'a8'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Ranks run horizontally. 1 through 8, bottom to top.",
          highlightSquares: ['a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Tap the 'e' file. Prove to me your eyes are already learning.",
          allowedSquares: ['e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8'],
          highlightSquares: ['e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8'],
          reactionCorrect: MentorReaction(
            dialogue: "Precise. Grid mastery is the foundation of all visualization.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "No. The 'e' file is the fifth column from the left.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Chapter complete. Your journey into strategic warfare begins now.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 2: Coordinates & Tiles (old 2)
    TutorialLesson(
      chapterId: 2,
      title: 'Coordinates & Tiles',
      setupFen: 'k7/8/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Every square has a unique address — a file letter and a rank number. I have read them instantly for forty years.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "e4. The intersection of the 'e' file and the 4th rank. The most famous square in chess.",
          highlightSquares: ['e4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Find d5 for me. Precision is non-negotiable.",
          allowedSquares: ['d5'],
          reactionCorrect: MentorReaction(
            dialogue: "Exactly. d5 is a critical central square I have contested in hundreds of games.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Wrong. Trace the 'd' column up to the 5th rank.",
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

    // Chapter 3: Pawn Movement & Capture
    TutorialLesson(
      chapterId: 3,
      title: 'Pawn Movement & Capture',
      setupFen: 'r3k2r/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "My pawns are my infantry. Humble, but they decide the outcome of wars.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "They march forward — one square, or two on their very first step. They never retreat.",
          animatePathSquares: ['e2', 'e3', 'e4'],
          highlightSquares: ['e2', 'e3', 'e4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Command e2 to e4. Seize the center.",
          highlightSquares: ['e2'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "The center is yours. That is how I open every serious game.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "March straight ahead to e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "But pawns have a unique, peculiar rule: they move straight, but they capture diagonally. One square diagonally forward.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Capture the Black pawn on d5. Take it off the board.",
          resetToFen: 'k7/8/8/3p4/4P3/8/8/7K w - - 0 1',
          highlightSquares: ['e4', 'd5'],
          expectedMove: 'e4d5',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. Capturing diagonally is the pawn's unique signature.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Capture diagonally. Move e4 to d5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Crucially, if a piece is directly in front of a pawn, it is blocked. It cannot move forward, and it cannot capture forward.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Our e4 pawn is blocked by the e5 pawn. Tap the blocked e4 pawn to acknowledge.",
          resetToFen: 'k7/8/8/4p3/4P3/8/8/7K w - - 0 1',
          allowedSquares: ['e4'],
          highlightSquares: ['e4', 'e5'],
          reactionCorrect: MentorReaction(
            dialogue: "Exactly. The path forward is blocked, and pawns cannot capture straight ahead.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Tap the highlighted e4 pawn.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Pawn basics complete. They are the soul of chess — never underestimate them.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 4: Rook Movement & Capture
    TutorialLesson(
      chapterId: 4,
      title: 'Rook Movement & Capture',
      setupFen: 'k7/8/8/8/3R4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Rook. I have used this siege engine to dominate open files and crush back ranks.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Horizontal and vertical. Any number of unblocked squares. Simple, devastating.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Slide the Rook from d4 to d8. Command the file.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d8',
          reactionCorrect: MentorReaction(
            dialogue: "Efficient. The back rank is within reach — exactly where I want my Rooks.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Straight lines only. Move to d8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Unlike pawns, Rooks capture the same way they move. They travel in a straight line and land directly on the enemy's square, taking it.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Capture the undefended Black Knight on d8. Slide the Rook up.",
          resetToFen: 'k2n4/8/8/8/3R4/8/8/7K w - - 0 1',
          highlightSquares: ['d4', 'd8'],
          expectedMove: 'd4d8',
          reactionCorrect: MentorReaction(
            dialogue: "Precisely. The Knight is removed and our Rook occupies d8.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Capture the Knight on d8. Rook d4 to d8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Rook mobility and capturing secured. Keep your files open — always.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 5: Bishop Movement & Capture
    TutorialLesson(
      chapterId: 5,
      title: 'Bishop Movement & Capture',
      setupFen: 'k7/8/8/8/3B4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Bishop. A long-range diagonal sniper. I have used it to pin and skewer from across the board.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "It lives on one color complex forever. A light-square Bishop never touches a dark square.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.bishopDiagonals,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Send the Bishop from d4 to h8.",
          highlightSquares: ['d4'],
          expectedMove: 'd4h8',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless. Long diagonals are dangerous attack vectors I exploit constantly.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Diagonals only. Move to h8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Bishops also capture the same way they move: diagonally, landing on the enemy's square and replacing them.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Capture the Black Rook on h8. Slide the Bishop along the light diagonal.",
          resetToFen: 'k6r/8/8/8/3B4/8/8/7K w - - 0 1',
          highlightSquares: ['d4', 'h8'],
          expectedMove: 'd4h8',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect capture. That diagonal threat has been resolved.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Capture the Rook. Bishop d4 to h8.",
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

    // Chapter 6: Knight Movement & Capture
    TutorialLesson(
      chapterId: 6,
      title: 'Knight Movement & Capture',
      setupFen: 'k7/8/8/8/3N4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Knight. The trickster. I have used Knights to deliver forks no opponent ever anticipated.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The L-shape — two squares in one direction, then one square perpendicular. Unique to this piece.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "They leap over all other pieces. Blockades mean nothing to a Knight.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Execute the L-leap to f5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4f5',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Notice the color switch on every landing — a Knight's signature.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Two squares right, one square up. Move to f5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Knights capture by landing on the L-shape square occupied by an enemy. Watch how the Knight jumps over obstacle pieces on its path to capture.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Jump over the pawns on b3 and c3 to capture the Black pawn on d4.",
          resetToFen: 'k7/8/8/8/3p4/1PP5/1PN5/7K w - - 0 1',
          highlightSquares: ['c2', 'd4'],
          expectedMove: 'c2d4',
          reactionCorrect: MentorReaction(
            dialogue: "Spectacular! Leaping and capturing at once. That is the magic of the Knight.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Make the L-jump to capture on d4. Knight c2 to d4.",
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

    // Chapter 7: Queen Movement & Capture
    TutorialLesson(
      chapterId: 7,
      title: 'Queen Movement & Capture',
      setupFen: 'k7/8/8/8/3Q4/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Queen. The apex predator. I guard her with my life — she is worth nine pawns of firepower.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The Rook's straight power combined with the Bishop's diagonal reach. One piece, total dominance.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Unleash her. Move to d8.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d8',
          reactionCorrect: MentorReaction(
            dialogue: "Devastating. Guard her carefully — losing the Queen is often fatal.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Straight or diagonal. Glide to d8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Queen captures in straight or diagonal lines, sweeping the board and replacing the target.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Capture the Black Bishop on g7.",
          resetToFen: 'k7/6b1/8/8/3Q4/8/8/7K w - - 0 1',
          highlightSquares: ['d4', 'g7'],
          expectedMove: 'd4g7',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The threat on g7 is eliminated.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Capture the Bishop on g7. Queen d4 to g7.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Queen dominance affirmed. Absolute power demands absolute responsibility.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 8: King Movement & Capture
    TutorialLesson(
      chapterId: 8,
      title: 'King Movement & Capture',
      setupFen: 'k7/8/8/8/3K4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The King. Lose him, and the battle ends. I have spent entire careers learning to protect this piece.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "One square in any direction — deliberate, measured, vital.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Step cautiously to e5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4e5',
          reactionCorrect: MentorReaction(
            dialogue: "Steady. An active King is a weapon in the endgame — I have won dozens of games that way.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "One square only. Move to e5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Even the King can capture! He can capture any undefended piece standing on an adjacent square.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Capture the undefended Black pawn on e5.",
          resetToFen: 'k7/8/8/4p3/3K4/8/8/8 w - - 0 1',
          highlightSquares: ['d4', 'e5'],
          expectedMove: 'd4e5',
          reactionCorrect: MentorReaction(
            dialogue: "Well done. You eliminated the pawn and claimed e5.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Capture the pawn. Move King d4 to e5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "King safety and captures complete. Foundations mastered. From here, the remaining chapters are yours to conquer — open the Academy and chart your own path. I have given you the tools. Now forge the blade.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 9: Pawn Promotion (old 17)
    TutorialLesson(
      chapterId: 9,
      title: 'Pawn Promotion',
      setupFen: 'k7/4P3/8/8/8/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Ascension. I have promoted pawns to Queens that decided world-class games in a single stroke.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Reach the final rank and transform — into a Queen, Rook, Bishop, or Knight of your color.",
          highlightSquares: ['e7', 'e8'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Push to e8. Claim your Queen — the most common and most powerful choice.",
          highlightSquares: ['e7'],
          expectedMove: 'e7e8q',
          reactionCorrect: MentorReaction(
            dialogue: "A new Queen rises. Her power is absolute.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "March to e8 and choose the Queen.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "But mastery demands flexibility. Underpromotion is a rare, lethal tool I have used in grandmaster-level positions.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Promote to a Knight on g8. Sometimes it is the exact piece the position demands.",
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
          dialogue: "Promotion verified. From foot soldier to officer — the choice is always yours.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 10: Kingside Castling (old 14)
    TutorialLesson(
      chapterId: 10,
      title: 'Kingside Castling',
      setupFen: '4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Castling. One move, two pieces repositioned. I castle in nearly every game — King safety and Rook activation at once.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Kingside (O-O). The path between King and Rook must be completely clear.",
          highlightSquares: ['e1', 'f1', 'g1', 'h1'],
          overlayEffect: TutorialOverlayEffect.castlingPath,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Neither piece can have moved previously. The King must not be in check, nor pass through a threatened square.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Kingside Castle. Drag the King to g1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1g1',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless. King safe, Rook centralized.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "King two squares right. Move to g1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Kingside fortress established. Castle early — I have paid dearly when I delayed.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 11: Queenside Castling
    TutorialLesson(
      chapterId: 11,
      title: 'Queenside Castling',
      setupFen: '4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Queenside Castling (O-O-O). Identical rules, but the queenside Rook travels three squares (a1 to d1) instead of two. A more aggressive setup.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "King moves two squares left. The Rook jumps to d1 beside him.",
          highlightSquares: ['e1', 'd1', 'c1', 'b1', 'a1'],
          overlayEffect: TutorialOverlayEffect.castlingPath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Queenside Castle. King to c1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1c1',
          reactionCorrect: MentorReaction(
            dialogue: "Magnificent. A centralized Rook on d1 is a powerful asset.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "King two squares left. Move to c1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Both flanks mastered. Keep your opponent guessing which side you will castle.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 12: En Passant (old 16)
    TutorialLesson(
      chapterId: 12,
      title: 'En Passant Capture',
      setupFen: 'k7/3p4/8/4P3/8/8/8/7K b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "En Passant. In passing. The most elusive rule in chess — I have caught opponents off guard with it many times.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "An enemy pawn leaps two squares on its first move, landing beside yours.",
          scriptedMove: 'd7d5',
          animatePathSquares: ['d7', 'd5'],
          highlightSquares: ['d7', 'd5'],
          overlayEffect: TutorialOverlayEffect.enPassantArrow,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "You may capture it diagonally behind it — but only on the very next move. Miss it and the right expires.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Strike now. Move e5 to d6.",
          highlightSquares: ['e5'],
          expectedMove: 'e5d6',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The bypassed pawn is swept from the field.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Diagonal strike. Move to d6.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "En Passant demystified. You now possess knowledge that confounds weak players.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 13: Understanding Check
    TutorialLesson(
      chapterId: 13,
      title: 'Understanding Check',
      setupFen: '4k3/8/8/8/8/8/4r3/4K3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Check. A direct threat to your King. I have never — not once — ignored a check. You cannot either.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The enemy Rook lines up on your King. Resolve this immediately — all other plans are secondary.",
          highlightSquares: ['e1'],
          overlayEffect: TutorialOverlayEffect.checkPulse,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Step off the dangerous file. Move to d1 or f1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1d1',
          alternativeMoves: ['e1f1'],
          reactionCorrect: MentorReaction(
            dialogue: "Crisis averted. Evading is the simplest solution when available.",
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

    // Chapter 14: Escaping Check
    TutorialLesson(
      chapterId: 14,
      title: 'Escaping Check',
      setupFen: 'k7/8/8/8/8/8/4B3/r3K3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Three ways I escape check — evade, block, or capture the attacker. Master all three.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "A back-rank check. Moving the King is one option. Blocking with a piece is another.",
          highlightSquares: ['e1'],
          overlayEffect: TutorialOverlayEffect.checkPulse,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Intercept. Move the Bishop from e2 to d1 — shield your King.",
          highlightSquares: ['e2'],
          expectedMove: 'e2d1',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. Minor pieces make excellent shields when placed correctly.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Block the line. Move the Bishop to d1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Defense optimized. Always evaluate every escape vector before acting.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 15: Checkmate (old 12)
    TutorialLesson(
      chapterId: 15,
      title: 'Checkmate',
      setupFen: '7k/5Q2/6K1/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Checkmate. In check with zero escape. I have delivered it thousands of times — it is always the goal.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Coordinate the attack. The final blow is one move away.",
          highlightSquares: ['f7'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Slide the Queen to g7. End it.",
          highlightSquares: ['f7'],
          expectedMove: 'f7g7',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate. g7 is defended by my King, leaving no escape.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move to g7. Support the kill.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Efficient. But g7 is not the only path. The Queen has enormous range. Let us reset.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Find the Back-Rank Mate. f8 or e8. Strike from a distance.",
          resetToFen: '7k/5Q2/6K1/8/8/8/8/8 w - - 0 1',
          highlightSquares: ['f7'],
          expectedMove: 'f7f8',
          alternativeMoves: ['f7e8'],
          reactionCorrect: MentorReaction(
            dialogue: "Lethal. The back rank is a graveyard for trapped Kings — I have buried many there.",
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

    // Chapter 16: Stalemate
    TutorialLesson(
      chapterId: 16,
      title: 'Stalemate',
      setupFen: '7k/4Q3/5K2/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Stalemate. When it is your opponent's turn, they have no legal moves, but their King is NOT in check. The game ends in an immediate draw. I have seen players throw away won games by creating stalemates.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "If White moves the Queen to f7, the Black King is trapped with no legal moves, but is not in check. That is stalemate.",
          highlightSquares: ['e7', 'f7'],
          scriptedMove: 'e7f7',
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Let us reset. Avoid the stalemate. Deliver checkmate with the Queen on g7.",
          resetToFen: '7k/4Q3/5K2/8/8/8/8/8 w - - 0 1',
          highlightSquares: ['e7', 'g7'],
          expectedMove: 'e7g7',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! Excellent. You won the game instead of gifting a draw.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Deliver mate on g7. Move e7 to g7.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Stalemate avoided. Always double check if your opponent has a legal move before making a non-checking move.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 17: Draw Conditions
    TutorialLesson(
      chapterId: 17,
      title: 'Draw Conditions',
      setupFen: 'k7/8/8/8/8/8/8/1R5K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Draws. I have claimed them deliberately and been forced into them against my will. Know every type: stalemate, repetition, and insufficient material.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Three-fold repetition occurs when the exact same board position is reached three times. Watch the Rook and King repeat positions.",
          scriptedMove: 'b1b2',
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King moves to a7.",
          scriptedMove: 'a8a7',
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "White Rook returns to b1.",
          scriptedMove: 'b2b1',
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King returns to a8. The same position is repeating.",
          scriptedMove: 'a7a8',
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Knowledge of draws salvages half a point from the abyss. That half-point has changed standings in tournaments.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 18: Piece Value Concepts
    TutorialLesson(
      chapterId: 18,
      title: 'Piece Value Concepts',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Piece values. I calculate every trade at the board: Queen 9, Rook 5, Bishop 3, Knight 3, Pawn 1. These are starting benchmarks — not laws.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Identify the minor pieces (worth 3 points). Tap a Bishop or Knight to show me.",
          allowedSquares: ['c1', 'f1', 'b1', 'g1', 'c8', 'f8', 'b8', 'g8'],
          highlightSquares: ['c1', 'f1', 'b1', 'g1'],
          reactionCorrect: MentorReaction(
            dialogue: "Indeed. Bishops and Knights are minor pieces, valued at 3 pawns.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Tap a Bishop (c1, f1) or Knight (b1, g1).",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Identify the Rook (worth 5 points). Tap a Rook.",
          allowedSquares: ['a1', 'h1', 'a8', 'h8'],
          highlightSquares: ['a1', 'h1'],
          reactionCorrect: MentorReaction(
            dialogue: "Correct. Rooks are major pieces, worth 5 points.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Tap a Rook on a1 or h1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Now tap the ultimate force: the Queen (worth 9 points).",
          allowedSquares: ['d1', 'd8'],
          highlightSquares: ['d1'],
          reactionCorrect: MentorReaction(
            dialogue: "Yes! The Queen is worth 9 points — protect her with diligence.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Tap the Queen on d1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Calculate every exchange. Never lose value without gaining something equal or greater.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 19: Opening Principles
    TutorialLesson(
      chapterId: 19,
      title: 'Opening Principles',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Three principles I live by in every opening: control the center, develop your pieces, castle your King. Everything else is detail.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Stake your claim in the center. e2 to e4.",
          highlightSquares: ['e2', 'e4'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. Space and development now flow naturally.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black claims their share of the center.",
          scriptedMove: 'e7e5',
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Develop a minor piece. Move Knight g1 to f3.",
          highlightSquares: ['g1', 'f3'],
          expectedMove: 'g1f3',
          reactionCorrect: MentorReaction(
            dialogue: "Good. Knight developed, attacking e5, and preparing castling.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black develops their Knight to c6, defending.",
          scriptedMove: 'b8c6',
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Develop your Bishop to c4.",
          highlightSquares: ['f1', 'c4'],
          expectedMove: 'f1c4',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Minor pieces are moving out.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black develops their Knight to f6.",
          scriptedMove: 'g8f6',
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now castle your King to safety. Drag the King to g1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1g1',
          reactionCorrect: MentorReaction(
            dialogue: "Wonderful! Your King is safe behind three pawns and a Rook is activated.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Opening principles verified. Control, develop, and castle.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 20: The Fork
    TutorialLesson(
      chapterId: 20,
      title: 'The Fork',
      setupFen: 'Q7/p4rkp/8/2p1q1N1/P1P5/8/8/7K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Fork. One of the most feared tactics. Let's study Petrosian vs. Simagin (1956). White (Tigran Petrosian) executed a legendary combination starting with a spectacular decoy sacrifice.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Sacrifice your Queen! Move Queen from a8 to h8 to check the King.",
          highlightSquares: ['a8', 'h8'],
          expectedMove: 'a8h8',
          reactionCorrect: MentorReaction(
            dialogue: "Outstanding! The Black King is decoyed to h8, placing it in range of a devastating fork.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Sacrifice the Queen on h8 to force the King to move.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King captures the Queen.",
          scriptedMove: 'g7h8',
          animatePathSquares: ['g7', 'h8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now, deliver the fork! Move the Knight from g5 to f7 check, capturing the Rook.",
          highlightSquares: ['g5', 'f7'],
          expectedMove: 'g5f7',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant! The Knight checks the King on h8 and forks the Queen on e5.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move the Knight to f7 to check the King and fork the Queen.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to g7.",
          scriptedMove: 'h8g7',
          animatePathSquares: ['h8', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Reap the reward of the fork! Capture the Black Queen on e5.",
          highlightSquares: ['f7', 'e5'],
          expectedMove: 'f7e5',
          reactionCorrect: MentorReaction(
            dialogue: "Incredible! You won a whole Rook and Queen, leaving Black with a hopeless position.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Knight f7 to e5 captures the Queen.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Fork tactics complete. With deep calculation, a simple fork can win entire games.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 21: The Pin
    TutorialLesson(
      chapterId: 21,
      title: 'The Pin',
      setupFen: '3rkb1r/p2nqppp/2p2n2/1B2p1B1/4P3/1QN5/PPP2PPP/2KR3R w k - 0 13',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Pin. A pin occurs when an attacked piece cannot move without exposing a more valuable target behind it. Let's study Paul Morphy's famous Opera Game (1858).",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Look at Black's Knight on d7. It is pinned to the King on e8 by our Bishop on b5. It is illegal for the Knight to move — an absolute pin.",
          mentorMood: MentorMood.calm,
          highlightSquares: ['b5', 'd7', 'e8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Morphy sacrificed a Rook to exploit this pin. Play Rook d1 captures Knight on d7.",
          highlightSquares: ['d1', 'd7'],
          expectedMove: 'd1d7',
          reactionCorrect: MentorReaction(
            dialogue: "Correct! Black is forced to recapture with their Rook to avoid losing a piece.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Capture the Knight on d7 with your Rook on d1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black recaptures with their Rook on d8.",
          scriptedMove: 'd8d7',
          animatePathSquares: ['d8', 'd7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The Black Rook on d7 is now pinned. Add more pressure! Bring your second Rook to d1.",
          highlightSquares: ['h1', 'd1'],
          expectedMove: 'h1d1',
          reactionCorrect: MentorReaction(
            dialogue: "Incredible! White has two pieces attacking the pinned Rook on d7, while Black cannot defend it further.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move your Rook from h1 to d1 to pressure the pinned piece.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Pin tactics complete. By pinning a piece and piling on pressure, you can break any defense.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 22: The Skewer
    TutorialLesson(
      chapterId: 22,
      title: 'The Skewer',
      setupFen: '8/8/2k5/8/8/8/4B3/7r w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Skewer. Often called a 'reverse pin'. You attack a valuable piece, forcing it to move, which exposes a less valuable piece behind it.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Skewer the King. Move the Bishop from e2 to f3 check.",
          highlightSquares: ['e2', 'f3'],
          expectedMove: 'e2f3',
          reactionCorrect: MentorReaction(
            dialogue: "Check! The King must step aside, leaving the Rook behind it vulnerable.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move the Bishop to f3 to deliver check and attack the Rook.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to d6.",
          scriptedMove: 'c6d6',
          animatePathSquares: ['c6', 'd6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The Rook on h1 is now exposed. Capture it with your Bishop.",
          highlightSquares: ['f3', 'h1'],
          expectedMove: 'f3h1',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent! You traded a Bishop's check for a whole Rook.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Bishop takes Rook on h1.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Skewer mastered. Attack the head, claim the tail.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 23: Discovered Attack & Check
    TutorialLesson(
      chapterId: 23,
      title: 'Discovered Attack & Check',
      setupFen: 'rn2kb1r/pp3ppp/2p5/4q3/4n3/2NQ4/PPPB1PPP/2KR1B1R w kq - 2 9',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Discovered Attack. Moving a piece out of the way to open a line of sight for a long-range piece behind it. Let's study Réti vs. Tartakower (Vienna, 1910).",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Sacrifice your Queen to force the King into position! Move Queen to d8 check.",
          highlightSquares: ['d3', 'd8'],
          expectedMove: 'd3d8',
          reactionCorrect: MentorReaction(
            dialogue: "Superb! The Black King is lured to d8.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Sacrifice the Queen. Move Queen from d3 to d8 check.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King captures the Queen.",
          scriptedMove: 'e8d8',
          animatePathSquares: ['e8', 'd8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Now, deliver the double check! Move your Bishop from d2 to g5 check.",
          highlightSquares: ['d2', 'g5'],
          expectedMove: 'd2g5',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant! The King is checked by both the Bishop on g5 and the Rook on d1. Black is forced to run.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move Bishop to g5 to deliver double check.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King escapes to c7.",
          scriptedMove: 'd8c7',
          animatePathSquares: ['d8', 'c7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver the final blow! Move the Bishop to d8 checkmate.",
          highlightSquares: ['g5', 'd8'],
          expectedMove: 'g5d8',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! The double check forced the King into a mating net, ending the game in style.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move Bishop to d8 to deliver mate.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Discovered attack and double check mastered. Unleashing two threats at once is the ultimate way to shatter your opponent's defenses.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 24: The Principle of Mobility (old 40)
    TutorialLesson(
      chapterId: 24,
      title: 'The Principle of Mobility',
      setupFen: '8/8/4k1p1/3p1p1p/3P1P1P/6PB/5K2/8 b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Mobility. A piece's value is tied directly to its activity. I have seen grandmasters lose with material advantage simply because their pieces could not move.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "White's Bishop is trapped on h3 behind its own pawn chain. A piece that cannot move is practically useless — regardless of its nominal value.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black's King advances into the center where the real action will be.",
          scriptedMove: 'e6d6',
          animatePathSquares: ['e6', 'd6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Reposition your trapped Bishop. Move h3 to f1.",
          highlightSquares: ['h3'],
          expectedMove: 'h3f1',
          reactionCorrect: MentorReaction(
            dialogue: "Good. But note: the Bishop can only shuffle, unable to cross the pawn wall.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black's King marches further. This is what active play looks like.",
          scriptedMove: 'd6c6',
          animatePathSquares: ['d6', 'c6'],
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Mobility lesson complete. Always keep your pieces active — never blockade your own Bishops.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 25: Open Files & Penetration (old 44)
    TutorialLesson(
      chapterId: 25,
      title: 'Open Files & Penetration',
      setupFen: 'r5k1/pp3ppp/8/8/8/8/PP3PPP/4R1K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Rooks belong on open files. I have won countless games by invading the 7th rank and suffocating the enemy position.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The e-file is wide open. My Rook must seize it and drive deep into the enemy camp.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Invade the 7th rank. Move Rook to e7.",
          highlightSquares: ['e1'],
          expectedMove: 'e1e7',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. The Rook on the 7th attacks Black's pawns on a7 and b7 simultaneously.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black's Rook moves to d8, creating back-rank pressure.",
          scriptedMove: 'a8d8',
          animatePathSquares: ['a8', 'd8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Create a flight square for your King. Move h2 to h3.",
          highlightSquares: ['h2'],
          expectedMove: 'h2h3',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. I always create 'luft' — a flight square — to prevent back-rank disasters.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Open Files lesson complete. Control the files, occupy the 7th rank, win the game.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 26: Undermining (old 45)
    TutorialLesson(
      chapterId: 26,
      title: 'Undermining',
      setupFen: 'r3k2r/pp3ppp/2n1b3/8/1b1q4/2N2B2/PP3PPP/R2QK1NR w KQkq - 0 10',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Undermining — the tactical deletion of a defender. Black's Queen on d4 is guarded by the Knight on c6. I remove the guard, then take the Queen.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "I capture the c6 Knight with check. Black must respond to the check — abandoning the Queen.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Eliminate the defender. Capture the Knight on c6 with your Bishop.",
          highlightSquares: ['f3', 'c6'],
          expectedMove: 'f3c6',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. Black must deal with the check first — the Queen is now abandoned.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black captures back with the pawn — forced.",
          scriptedMove: 'b7c6',
          animatePathSquares: ['b7', 'c6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Black's Queen is undefended. Capture it with your Queen.",
          highlightSquares: ['d1', 'd4'],
          expectedMove: 'd1d4',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. You won the Queen and simplified the position decisively.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Undermining complete. Remove the guard, claim the prize.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 27: Overloading (old 46)
    TutorialLesson(
      chapterId: 27,
      title: 'Overloading',
      setupFen: 'r2qk1nr/2pbbppp/2np4/1p6/2B1P3/1BN2N2/PP3PPP/R1BQ1RK1 w kq - 0 10',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Overloading. I force one piece to defend too many squares simultaneously — then exploit whichever duty it abandons.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Create the first threat. Move your Queen to d5, targeting the weak f7 square.",
          highlightSquares: ['d1', 'd5'],
          expectedMove: 'd1d5',
          reactionCorrect: MentorReaction(
            dialogue: "Outstanding. You now threaten mate on f7.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black's Bishop moves to e6 to defend f7 — abandoning the Knight on c6.",
          scriptedMove: 'd7e6',
          animatePathSquares: ['d7', 'e6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The Bishop has abandoned c6. Capture the Knight there with check.",
          highlightSquares: ['d5', 'c6'],
          expectedMove: 'd5c6',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. You win the Knight because the Bishop was overloaded.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Overloading complete. Multiple threats collapse defenses — it is that simple.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 28: Decoy & Attraction (old 47)
    TutorialLesson(
      chapterId: 28,
      title: 'Decoy & Attraction',
      setupFen: 'rnb1kbnr/ppp2ppp/5q2/4p3/2B1q3/5N2/PPPP1PPP/RNBQ1RK1 w kq - 0 5',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Decoy and Attraction. I sacrifice a piece to lure an enemy onto a bad square, then follow up with a devastating double attack.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Lure the King. Sacrifice your Bishop by capturing on f7 with check.",
          highlightSquares: ['c4', 'f7'],
          expectedMove: 'c4f7',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. The King is forced to capture the Bishop.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King is forced to capture the Bishop on f7.",
          scriptedMove: 'e8f7',
          animatePathSquares: ['e8', 'f7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The King has been attracted to f7. Knight to g5 check — fork the King and Queen.",
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
          dialogue: "Execute the fork. Capture Black's Queen on e4 with your Knight.",
          highlightSquares: ['g5', 'e4'],
          expectedMove: 'g5e4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. One Bishop traded for the enemy Queen — a massive gain.",
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



    // Chapter 29: Clearance & Vacating (old 48)
    TutorialLesson(
      chapterId: 29,
      title: 'Clearance & Vacating',
      setupFen: 'rnbq1bnr/pp2k1pp/8/3QN3/2BPp3/8/PPP2PPP/RNB1K2R w KQ - 1 9',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Clearance. I vacate a square or line to allow another piece to deploy a decisive blow. The sacrifice is the key.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "I want to deliver checkmate with the Queen on e5 — but my own Knight on e5 is blocking the path.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Clear the e5 square with a forcing check. Move Knight to g6 check.",
          highlightSquares: ['e5', 'g6'],
          expectedMove: 'e5g6',
          reactionCorrect: MentorReaction(
            dialogue: "Well played. The Knight vacates e5 with check — Black must respond.",
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
          dialogue: "The path is clear. Queen to e5 — deliver the crushing check.",
          highlightSquares: ['d5', 'e5'],
          expectedMove: 'd5e5',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The Queen occupies e5 and delivers a mating blow.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Clearance complete. Sacrifice the Knight, open the lane, deliver the verdict.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 30: Interference (old 49)
    TutorialLesson(
      chapterId: 30,
      title: 'Interference',
      setupFen: 'r4bk1/pp1q2pp/2n1R3/6N1/2pp2P1/5Q2/PP3P1P/2B3K1 w - - 1 17',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Interference. I break the communication between two enemy defenders by placing a piece directly in their path.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black's Queen on d7 and Bishop on f8 both defend f7. I will disrupt that coordination with a rook sacrifice.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Interfere. Sacrifice your Rook by moving it to e7.",
          highlightSquares: ['e6', 'e7'],
          expectedMove: 'e6e7',
          reactionCorrect: MentorReaction(
            dialogue: "Magnificent placement. The Queen must capture it.",
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
          dialogue: "Communication broken. Move your Queen to d5 to check the King.",
          highlightSquares: ['f3', 'd5'],
          expectedMove: 'f3d5',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent check. Black's King is in massive trouble.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black blocks with the Queen on e6.",
          scriptedMove: 'e7e6',
          animatePathSquares: ['e7', 'e6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver checkmate. Capture the Queen on e6.",
          highlightSquares: ['d5', 'e6'],
          expectedMove: 'd5e6',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate. A spectacular finish.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Interference complete. The Rook sacrifice broke Black's defensive web entirely.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 31: Zwischenzug (old 50)
    TutorialLesson(
      chapterId: 31,
      title: 'Zwischenzug',
      setupFen: 'r1bq1b1r/ppp3kp/2N2np1/3Q4/8/8/PPP2PPP/RNB1K2R w KQ - 1 10',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Zwischenzug — German for 'in-between move'. I insert an unexpected forcing move before completing an exchange. My opponents rarely anticipate it.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black expects me to recapture on d8. Instead, I play a devastating check first — changing everything.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Play the intermediate check. Move Bishop to h6 check.",
          highlightSquares: ['c1', 'h6'],
          expectedMove: 'c1h6',
          reactionCorrect: MentorReaction(
            dialogue: "Fantastic check. Black's King is forced to capture the Bishop.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King captures the Bishop on h6.",
          scriptedMove: 'g7h6',
          animatePathSquares: ['g7', 'h6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Follow up with another check. Move your Queen to d2.",
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
          dialogue: "Now capture the Black Queen on d8 with your Knight.",
          highlightSquares: ['c6', 'd8'],
          expectedMove: 'c6d8',
          reactionCorrect: MentorReaction(
            dialogue: "Amazing. You saved your Queen and won Black's Queen — a decisive swing.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Zwischenzug complete. The intermediate checks changed the entire material balance.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 32: Italian Game (old 24)
    TutorialLesson(
      chapterId: 32,
      title: 'Italian Game',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Italian Game. I have studied this opening for decades — fast development, quick pressure on the center.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Begin with the king pawn. Play e2 to e4.",
          highlightSquares: ['e2', 'e4'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Good. White claims space and opens the bishop's diagonal.",
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
            dialogue: "The Knight attacks e5 and prepares castling — two goals at once.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Bring the Knight from g1 to f3.",
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
          dialogue: "Now the Italian Bishop. Move f1 to c4.",
          highlightSquares: ['f1', 'c4'],
          expectedMove: 'f1c4',
          reactionCorrect: MentorReaction(
            dialogue: "Classical. The Bishop eyes f7 — the softest point in Black's position.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Italian setup: Bishop f1 to c4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Italian Game loaded. Develop quickly, aim clearly — that is my approach.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 33: Ruy Lopez (old 25)
    TutorialLesson(
      chapterId: 33,
      title: 'Ruy Lopez',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Ruy Lopez. I have played this opening in more serious games than any other — pressure the defender before striking the center.",
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
            dialogue: "Move the Knight from g1 to f3.",
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
            dialogue: "The Ruy Lopez is formed. Attack the guard of the center — then attack the center itself.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The Spanish Bishop goes from f1 to b5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Ruy Lopez complete. This opening teaches long, sustained pressure — elegant and dangerous.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 34: Sicilian Defense (old 26)
    TutorialLesson(
      chapterId: 34,
      title: 'Sicilian Defense',
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Sicilian Defense. Black refuses symmetry and attacks from the flank. I have faced it and played it — it breeds the sharpest chess.",
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
          dialogue: "Black answers c7 to c5. The Sicilian begins — asymmetry from move one.",
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
            dialogue: "Correct. White prepares the central break with d4.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "In the main Sicilian, play Ng1-f3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Sicilian recognized. Asymmetry creates counterplay — that is Black's weapon.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 35: Queen's Gambit (old 27)
    TutorialLesson(
      chapterId: 35,
      title: "Queen's Gambit",
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Queen's Gambit. I offer a wing pawn to seize control of the center. It is bait — the center is the prize.",
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
            dialogue: "The Queen's Gambit is formed. I ask Black to solve the center — and most solutions favor White.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The gambit move is c2 to c4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "A classic weapon I have used for decades. The pawn is bait — the center is the prize.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 36: King's Indian Setup (old 28)
    TutorialLesson(
      chapterId: 36,
      title: "King's Indian Setup",
      setupFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The King's Indian. Black invites a large center, then counterattacks it violently. I have been on both sides of this knife.",
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
          dialogue: "Black develops the King Knight to f6.",
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
          dialogue: "The Bishop slides to g7. Long diagonal pressure begins.",
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
          dialogue: "King's Indian setup understood. Let the center come — then undermine it. Patience is the weapon here.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 37: Queen Mate (old 29)
    TutorialLesson(
      chapterId: 37,
      title: 'Queen Mate',
      setupFen: '7k/5Q2/6K1/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Queen Mate. I have delivered this dozens of times — the Queen boxes the King, my King supports the final square.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black is trapped on the edge. The Queen controls the escape line.",
          highlightSquares: ['h8', 'f7', 'g6'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Finish it. Move Queen f7 to f8.",
          highlightSquares: ['f7', 'f8', 'h8'],
          expectedMove: 'f7f8',
          alternativeMoves: ['f7e8'],
          reactionCorrect: MentorReaction(
            dialogue: "Mate. Queen power, King support — the essential combination.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Use the Queen to seal the edge. Qf8 or Qe8 mates.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Queen mate mastered. Never chase the King — restrict it, then strike.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 38: Rook Mate (old 30)
    TutorialLesson(
      chapterId: 38,
      title: 'Rook Mate',
      setupFen: '7k/5KR1/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Rook Mate. The Rook cuts the board; my King guards the Rook. I have won this ending many times.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black is on the edge. My King protects g8 — the Rook cannot be captured.",
          highlightSquares: ['h8', 'g8', 'f7'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver mate. Rook g7 to g8.",
          highlightSquares: ['g7', 'g8'],
          expectedMove: 'g7g8',
          reactionCorrect: MentorReaction(
            dialogue: "Clean Rook mate. The King cannot capture a protected Rook.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Lift the Rook from g7 to g8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Rook mate verified. Cut, approach, finish — in that order.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 39: Opposition (old 31)
    TutorialLesson(
      chapterId: 39,
      title: 'Opposition',
      setupFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Opposition. Kings fight for entry squares in pawn endings. I have decided countless endgames by mastering this concept.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Step to the side to force the enemy King to yield ground — the shoulder move.",
          highlightSquares: ['e3', 'f3', 'e5', 'e2'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Take the outside shoulder. King e3 to f3.",
          highlightSquares: ['e3', 'f3'],
          expectedMove: 'e3f3',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. In pawn endings, the King duel comes before the pawn race.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move the King from e3 to f3.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Opposition understood. One tempo in a pawn ending can be the entire game.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 40: Wrong Bishop Draw (old 39)
    TutorialLesson(
      chapterId: 40,
      title: 'Wrong Bishop Draw',
      setupFen: '7k/8/7P/8/8/8/4B3/6K1 b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Wrong Bishop Draw. A Bishop and a Rook pawn cannot win if the Bishop does not control the promotion square. I have held draws this way.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "White's light-squared Bishop cannot control h8 — a dark square. Black simply stays in the corner. Draw.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "As Black, play defensively. Stay close to the corner.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Move your King to g8. Hug the promotion corner.",
          highlightSquares: ['h8'],
          expectedMove: 'h8g8',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. Keep the King on those corner squares.",
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
            dialogue: "Correct. White cannot check you on h8 — the Bishop is the wrong color.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "White pushes h6 to h7. The light-squared Bishop cannot control h8 — stalemate!",
          scriptedMove: 'h6h7',
          animatePathSquares: ['h6', 'h7'],
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Draw secured. You held the wrong Bishop corner — a priceless half-point.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 41: Pawn Breakthrough (old 38)
    TutorialLesson(
      chapterId: 41,
      title: 'Pawn Breakthrough',
      setupFen: '8/ppp5/8/PPP5/8/8/8/k6K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Pawn Breakthrough. I have used this technique to create a passed pawn from nothing — even without King support.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Three pawns versus three pawns. I sacrifice two to force one through. The calculation must be exact.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Advance the center pawn. Play b5 to b6.",
          highlightSquares: ['b5'],
          expectedMove: 'b5b6',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. This center push divides Black's defense.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black captures the center pawn: a7 takes b6.",
          scriptedMove: 'a7b6',
          animatePathSquares: ['a7', 'b6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Push the opposite pawn. Move c5 to c6.",
          highlightSquares: ['c5'],
          expectedMove: 'c5c6',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. This blockades the b-pawn and opens the a-pawn's path.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black is forced to capture: b7 takes c6.",
          scriptedMove: 'b7c6',
          animatePathSquares: ['b7', 'c6'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "The path is clear. Push the passed pawn: a5 to a6.",
          highlightSquares: ['a5'],
          expectedMove: 'a5a6',
          reactionCorrect: MentorReaction(
            dialogue: "The a-pawn is unstoppable. It will queen — game over.",
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



    // Chapter 42: Lucena Position (old 32)
    TutorialLesson(
      chapterId: 42,
      title: 'Lucena Position',
      setupFen: '6k1/3PK3/8/8/8/8/7r/4R3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Lucena Position. In Rook endings, I build a bridge for my King to shield from checks. This is essential endgame knowledge.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The pawn is almost home. The Rook must shield checks from the side.",
          highlightSquares: ['d7', 'e7', 'e1', 'e4'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Build the bridge. Rook e1 to e4.",
          highlightSquares: ['e1', 'e4'],
          expectedMove: 'e1e4',
          reactionCorrect: MentorReaction(
            dialogue: "Bridge built. The King can now hide from Rook checks behind it.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The bridge move is Re1-e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Lucena learned. Passed pawn plus active Rook — I have won this ending dozens of times.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 43: Philidor Position (old 33)
    TutorialLesson(
      chapterId: 43,
      title: 'Philidor Position',
      setupFen: '8/7r/8/8/8/3k4/3P4/3K4 b - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Philidor Position. The defender survives by holding the third rank. I have saved many half-points with this technique.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Keep the Rook active and deny the attacking King any shelter.",
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
            dialogue: "Move the Rook from h7 to h6.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Philidor secured. Defense is a skill, not a surrender — I hold draws I need to hold.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 44: The Pawn Chain (old 41)
    TutorialLesson(
      chapterId: 44,
      title: 'The Pawn Chain',
      setupFen: '6k1/pp4pp/2p1p3/3pP3/3P4/2P1P3/PP3PPP/6K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Pawn Chain. I have studied pawn structure my entire career. To break a chain, you must attack its base — not its tip.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "White has a strong pawn chain. I must undermine Black's structure by attacking its foundation.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Advance the f-pawn to challenge the chain. Play f2 to f3.",
          highlightSquares: ['f2'],
          expectedMove: 'f2f3',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. This prepares to strike at the center chain.",
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
          dialogue: "Push further to establish space. Play f3 to f4.",
          highlightSquares: ['f3'],
          expectedMove: 'f3f4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. White expands on the kingside and pressures the base.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Pawn Chain concept complete. Target the base — that is how chains collapse.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 45: The Backward Pawn (old 42)
    TutorialLesson(
      chapterId: 45,
      title: 'The Backward Pawn',
      setupFen: 'r4rk1/1pp1qppp/3p4/3Np3/4P3/1P1P4/1PP2PPP/R4RK1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Backward Pawn. A pawn that has lagged behind its neighbors and cannot be protected by other pawns. I exploit these mercilessly.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black's d6 pawn is backward. The d5 square in front of it is a hole — an outpost where my Knight sits perfectly.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Use your Knight outpost to attack the Queen. Move d5 to e7 check.",
          highlightSquares: ['d5'],
          expectedMove: 'd5e7',
          reactionCorrect: MentorReaction(
            dialogue: "Sensational. The Knight penetrates the defenses from the outpost.",
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
          dialogue: "Capture the passive Rook on c8.",
          highlightSquares: ['e7'],
          expectedMove: 'e7c8',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. The active outpost Knight wins material — this is positional chess at its finest.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Backward Pawn lesson complete. Place pieces in weak holes — dominate the board.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 46: Doubled Pawns (old 43)
    TutorialLesson(
      chapterId: 46,
      title: 'Doubled Pawns',
      setupFen: '6k1/pp1p1ppp/2p5/2P5/8/P7/1P1P1PPP/6K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Doubled Pawns. Two pawns of the same color on the same file — they cannot support each other. I fix them and squeeze.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black has doubled pawns on c6 and c7. The c7 pawn is blocked and cannot defend c6. This is a structural weakness I will exploit.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Advance your d-pawn to control the center. Move d2 to d4.",
          highlightSquares: ['d2'],
          expectedMove: 'd2d4',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. I take control of the d-file.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black moves the King toward the center.",
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
          dialogue: "Doubled Pawns lesson complete. Fix and restrict them — their immobility is your advantage.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 47: The Isolated Pawn
    TutorialLesson(
      chapterId: 47,
      title: 'The Isolated Pawn',
      setupFen: '4rrk1/pp3ppp/8/3p4/8/5N2/PP3PPP/3R2K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Isolated Pawn. A pawn with no friendly pawns on the files next to it. Since no pawn can defend it, it is a permanent structural weakness.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Look at Black's d5 pawn. It is isolated. The c and e pawns are gone. Black must use active pieces to defend it, tying them down.",
          mentorMood: MentorMood.calm,
          highlightSquares: ['d5'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Blockade the pawn. Move your Knight from f3 to the outpost square d4 — directly in front of the isolated pawn.",
          highlightSquares: ['f3', 'd4'],
          expectedMove: 'f3d4',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. The Knight is beautifully active here, and the isolated pawn is blocked forever.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Move the Knight to d4 to blockade.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Isolated Pawn concepts locked. Blockade the weak pawn, attack it, and conquer.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 48: Légal's Mate (old 37)
    TutorialLesson(
      chapterId: 48,
      title: "Légal's Mate",
      setupFen: 'rn1qk2r/ppp2ppp/3p1n2/4p3/2BPP1b1/2N2N2/PPP2PPP/R1BQK2R w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "A legendary opening trap in the Philidor's Defense. White sacrifices the Queen to deliver a lightning-fast mate with minor pieces. I have studied this position for years.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Black's Bishop pins White's Knight on f3. Black believes the Knight is frozen — that is the fatal assumption.",
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
          dialogue: "Black captures back on e5, believing the pinned Knight cannot move.",
          scriptedMove: 'd6e5',
          animatePathSquares: ['d6', 'e5'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Shock them. Ignore the pin — capture the e5 Knight with your f3 Knight.",
          highlightSquares: ['f3'],
          expectedMove: 'f3e5',
          reactionCorrect: MentorReaction(
            dialogue: "Sensational. The Queen is offered as bait.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black takes the bait. Bishop captures the Queen on d1.",
          scriptedMove: 'g4d1',
          animatePathSquares: ['g4', 'd1'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Deliver the first strike. Bishop c4 takes f7 with check.",
          highlightSquares: ['c4'],
          expectedMove: 'c4f7',
          reactionCorrect: MentorReaction(
            dialogue: "Check. Black King must step to e7.",
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
            dialogue: "Checkmate. The Queen is gone, but two Knights and a Bishop seal the victory.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Légal's Mate complete. Calculate concrete checkmates before worrying about material — always.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 49: The Windmill
    TutorialLesson(
      chapterId: 49,
      title: 'The Windmill',
      setupFen: '5rk1/pp3ppp/5B2/4p2q/8/1P1P2R1/P1P5/6K1 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Windmill. A Rook and Bishop operating in perfect harmony — a sequence of discovered checks and captures that strips the position bare.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Initiate the windmill. Play Rook to g7 check.",
          highlightSquares: ['g3', 'g7'],
          expectedMove: 'g3g7',
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
          dialogue: "Now, the discovered check. Retreat the Rook to f7. The Bishop on f6 delivers the check, while the Rook attacks f8.",
          highlightSquares: ['g7', 'f7'],
          expectedMove: 'g7f7',
          reactionCorrect: MentorReaction(
            dialogue: "Discovered check! The King is forced to return to g8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King returns to g8.",
          scriptedMove: 'h8g8',
          animatePathSquares: ['h8', 'g8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Re-establish the check. Rook back to g7.",
          highlightSquares: ['f7', 'g7'],
          expectedMove: 'f7g7',
          reactionCorrect: MentorReaction(
            dialogue: "Correct. King goes back to h8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to h8.",
          scriptedMove: 'g8h8',
          animatePathSquares: ['g8', 'h8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Another discovered check. Capture the pawn on b7.",
          highlightSquares: ['g7', 'b7'],
          expectedMove: 'g7b7',
          reactionCorrect: MentorReaction(
            dialogue: "Yes! Capture with discovered check. King back to g8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King returns to g8.",
          scriptedMove: 'h8g8',
          animatePathSquares: ['h8', 'g8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Check again. Rook to g7.",
          highlightSquares: ['b7', 'g7'],
          expectedMove: 'b7g7',
          reactionCorrect: MentorReaction(
            dialogue: "King back to h8.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King retreats to h8.",
          scriptedMove: 'g8h8',
          animatePathSquares: ['g8', 'h8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Discovered check again. Move Rook to g5, attacking the Queen on h5.",
          highlightSquares: ['g7', 'g5'],
          expectedMove: 'g7g5',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. King goes back to g8, and the Queen is trapped.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King returns to g8.",
          scriptedMove: 'h8g8',
          animatePathSquares: ['h8', 'g8'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Reap the final harvest. Capture the Black Queen on h5.",
          highlightSquares: ['g5', 'h5'],
          expectedMove: 'g5h5',
          reactionCorrect: MentorReaction(
            dialogue: "Incredible! You have completely cleaned the board and won the Queen.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Windmill complete. The defense was swept away and the Queen won.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 50: Lasker's Double Sacrifice (old 52)
    TutorialLesson(
      chapterId: 50,
      title: "Lasker's Double Sacrifice",
      setupFen: 'r4rk1/1b2bpp1/ppq1p3/2ppB2n/5P2/1P1BP3/P1PPQ1PP/R4RK1 w - - 0 15',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Lasker's Double Bishop Sacrifice. I have studied this attack deeply — we sacrifice both Bishops on h7 and g7 to strip the enemy King's pawn shield bare.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Sacrifice the first Bishop. Capture on h7 with check.",
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
          dialogue: "Bring in the Queen. Capture the Knight on h5 with check.",
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
          dialogue: "Sacrifice the second Bishop. Capture the pawn on g7.",
          highlightSquares: ['e5', 'g7'],
          expectedMove: 'e5g7',
          reactionCorrect: MentorReaction(
            dialogue: "Beautiful. The King is lured out to g7.",
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
          dialogue: "Check again. Move Queen to g4 check.",
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
          dialogue: "Complete the attack. Lift the Rook to f3, preparing Rh3+ and mate.",
          highlightSquares: ['f1', 'f3'],
          expectedMove: 'f1f3',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless. Black has no defense against Rook to h3.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Lasker's Double Sacrifice complete. Two Bishops destroyed the castle — and the King had nowhere to hide.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 51: Alekhine's Gun (old 53)
    TutorialLesson(
      chapterId: 51,
      title: "Alekhine's Gun",
      setupFen: '2r2rk1/1q2bppp/p2p1n2/3P4/1p1BP3/1P1R4/P1R1Q1PP/5B1K w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Alekhine's Gun. A heavy-piece battery — two Rooks doubled on a file with the Queen backing them. I have used this to suffocate entire positions.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Prepare to double your Rooks. Move Rook to d2.",
          highlightSquares: ['d3', 'd2'],
          expectedMove: 'd3d2',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. The Rooks will double and dominate the file.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Alekhine's Gun ready. Two Rooks and a Queen aligned — absolute file control.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 52: Saavedra Study (old 34)
    TutorialLesson(
      chapterId: 52,
      title: 'Saavedra Study',
      setupFen: '8/2P5/1K1k4/3r4/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Saavedra Study. Sometimes the strongest promotion is not a Queen. I have memorized this position — it shows the depths of endgame calculation.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The c-pawn reaches glory, but Queen promotion allows defensive tricks with stalemate.",
          highlightSquares: ['c7', 'c8', 'd5', 'd6'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Find the famous move. Promote c7 to c8 as a Rook.",
          highlightSquares: ['c7', 'c8'],
          expectedMove: 'c7c8r',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant. Underpromotion creates the win — the Queen would allow a stalemate trick.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Choose Rook promotion. c7 to c8 equals Rook.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Saavedra remembered. Mastery means choosing the exact piece the position demands.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 53: Two Bishops Mate (old 35)
    TutorialLesson(
      chapterId: 53,
      title: 'Two Bishops Mate',
      setupFen: '7k/8/8/8/8/8/8/2B1KB2 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Two Bishops Mate. They slice the board like scissors. I have practiced this ending until it became instinct — the enemy King must be driven to a corner.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "I start by coordinating the Bishops to build a wall. Bishop to d3.",
          animatePathSquares: ['f1', 'e2', 'd3'],
          highlightSquares: ['f1', 'd3'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Command the light-squared Bishop. Move f1 to d3.",
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
          dialogue: "Black King begins to retreat toward the corner.",
          scriptedMove: 'h8g7',
          animatePathSquares: ['h8', 'g7'],
          highlightSquares: ['h8', 'g7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Move the dark-squared Bishop to g5 to restrict the King further.",
          highlightSquares: ['c1'],
          expectedMove: 'c1g5',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The Bishops now control a tight diagonal grid.",
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
          dialogue: "Shift the light-squared Bishop to f5 to lock the King in.",
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
          dialogue: "Black King runs to g7. Now I bring my King up.",
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
            dialogue: "Correct. King participation is vital in this ending.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Play e1 to f2.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Black King shuffles to f7. I advance my King to g3.",
          scriptedMove: 'g7f7',
          animatePathSquares: ['g7', 'f7'],
          highlightSquares: ['g7', 'f7'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "King to g3. Support your Bishops.",
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
          dialogue: "Black King to g7. Now the Bishops confine him to the edge: Bishop to g6.",
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
          dialogue: "Move your light Bishop to g4.",
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
            dialogue: "Checkmate! The two Bishops have sealed the win.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Two Bishops Mate complete. The ultimate demonstration of diagonal control — I am proud of you.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 54: Knight & Bishop Mate (old 36)
    TutorialLesson(
      chapterId: 54,
      title: 'Knight & Bishop Mate',
      setupFen: 'k7/8/2K5/3N4/5B2/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Knight and Bishop Mate. The most difficult elementary mate. You must drive the King to the corner of the same color as your Bishop.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The light-squared Bishop requires a light corner (a1 or h8) to mate. The King starts in the wrong corner — I will use the W-maneuver to drive him to a1.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Begin by checking. Move the Knight d5 to b6.",
          highlightSquares: ['d5'],
          expectedMove: 'd5b6',
          reactionCorrect: MentorReaction(
            dialogue: "Check. Black King is forced to a7.",
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
          dialogue: "Prevent the King from escaping back. Move Bishop f4 to c7.",
          highlightSquares: ['f4'],
          expectedMove: 'f4c7',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. The King cannot return to a8 — he must move to a6.",
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
          dialogue: "Restrict him further. Move Bishop c7 to b8.",
          highlightSquares: ['c7'],
          expectedMove: 'c7b8',
          reactionCorrect: MentorReaction(
            dialogue: "Great. He must move down the file to a5.",
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
          dialogue: "Redeploy the Knight to block escape squares. Move b6 to d5.",
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
          dialogue: "Move Bishop f4 to e5 to guard d6 and c7 squares.",
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
            dialogue: "Check. The King must retreat to a4.",
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
          dialogue: "Check. Knight d3 to b2.",
          highlightSquares: ['d3'],
          expectedMove: 'd3b2',
          reactionCorrect: MentorReaction(
            dialogue: "Check. Black King goes back to a3.",
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
          dialogue: "Check. Bishop b6 to c5.",
          highlightSquares: ['b6'],
          expectedMove: 'b6c5',
          reactionCorrect: MentorReaction(
            dialogue: "Check. Black King goes back to a2.",
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
          dialogue: "Move your Knight b2 to d3. Prepare the final mate.",
          highlightSquares: ['b2'],
          expectedMove: 'b2d3',
          reactionCorrect: MentorReaction(
            dialogue: "Great. Black King is forced to a1 — the light corner.",
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
          dialogue: "Knight d3 to c1 check. Force him back.",
          highlightSquares: ['d3'],
          expectedMove: 'd3c1',
          reactionCorrect: MentorReaction(
            dialogue: "Check. Black King must return to a1.",
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
          dialogue: "Deliver the final blow. Bishop b4 to c3 — checkmate.",
          highlightSquares: ['b4'],
          expectedMove: 'b4c3',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate. Knight and Bishop mate — the most complex elementary mate in chess.",
            mood: MentorMood.celebration,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Masterful. You have executed the most complex mate in chess. I am genuinely impressed.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),



    // Chapter 55: Steinitz's Majority (old 54)
    TutorialLesson(
      chapterId: 55,
      title: "Steinitz's Majority",
      setupFen: '8/8/6k1/p1pp4/P1P5/1P6/5K2/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Steinitz's Queenside Pawn Majority. I have studied Steinitz's endgame technique deeply — a majority on one side creates a passed pawn to decide the game.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Initiate the pawn breakthrough. Capture the d5 pawn.",
          highlightSquares: ['c4', 'd5'],
          expectedMove: 'c4d5',
          reactionCorrect: MentorReaction(
            dialogue: "Perfect. Capturing creates a distant passed pawn — decisive in this ending.",
            mood: MentorMood.encouraging,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Steinitz's Majority complete. A passed pawn is a powerful weapon — I have won many endgames with exactly this technique.",
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
