import '../domain/models/tutorial_lesson.dart';

class TutorialLessonsDatabase {
  static const List<TutorialLesson> lessons = [
    // Chapter 1: Board Introduction
    TutorialLesson(
      chapterId: 1,
      title: 'Board Introduction',
      setupFen: '8/8/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Welcome to the Kingslayer Academy, Apprentice. I am GM Bard, your mentor in this lifelong resistance to restore human strategic mastery.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The battlefield consists of 64 squares alternating between light and dark. Notice how the bottom-right corner square is always light.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Vertical columns are called 'Files', labeled from 'a' on the left to 'h' on the right.",
          highlightSquares: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'a8'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Horizontal rows are called 'Ranks', numbered from 1 at the bottom to 8 at the top.",
          highlightSquares: ['a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Tap any square on the central 'e' file to confirm your understanding.",
          allowedSquares: ['e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8'],
          reactionCorrect: MentorReaction(
            dialogue: "Excellent. Mastering the grid is the first step toward visualization.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "That square is not on the 'e' file. Look for the column labeled 'e' at the bottom.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Chapter complete. You have taken your first step into a larger world.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 2: Coordinates & Tile Identification
    TutorialLesson(
      chapterId: 2,
      title: 'Coordinates & Tiles',
      setupFen: '8/8/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Every square has a unique coordinate combining its File letter and Rank number.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "For example, the central square where the 'e' file meets the 4th rank is called 'e4'.",
          highlightSquares: ['e4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitSquareTap,
          dialogue: "Identify and tap the square 'd5'.",
          allowedSquares: ['d5'],
          reactionCorrect: MentorReaction(
            dialogue: "Spot on. 'd5' is a critical central square.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Incorrect coordinate. Trace the column 'd' upward until it intersects with row 5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Coordinates mastered. Now we can speak the universal language of chess.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 3: Pawn Movement
    TutorialLesson(
      chapterId: 3,
      title: 'Pawn Movement',
      setupFen: '8/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Pawns are your foot soldiers. Humble in origin, but capable of turning the tide of war.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "A pawn marches straight forward, one square at a time. However, on its very first move, it has the option to leap two squares forward.",
          animatePathSquares: ['e2', 'e3', 'e4'],
          highlightSquares: ['e2', 'e3', 'e4'],
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Command your central pawn on e2 to march two squares forward to e4.",
          highlightSquares: ['e2'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Splendid. Staking an early claim in the center is a core strategic objective.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Pawns cannot move diagonally or backward. March straight ahead to e4.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Pawn basics complete. Remember: pawns are the soul of chess.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 4: Rook Movement
    TutorialLesson(
      chapterId: 4,
      title: 'Rook Movement',
      setupFen: '8/8/8/8/3R4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Behold the Rook. A heavy siege engine that commands straight open lines.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Rooks move horizontally along ranks or vertically along files for any number of unblocked squares.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.rookLanes,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Slide the Rook all the way up the file from d4 to d8.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d8',
          reactionCorrect: MentorReaction(
            dialogue: "Commanding efficiency. The back rank is now within your operational reach.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Rooks move strictly in straight lines. Do not deviate diagonally.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Rook movement secured. Keep your files open for these heavy pieces.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 5: Bishop Movement
    TutorialLesson(
      chapterId: 5,
      title: 'Bishop Movement',
      setupFen: '8/8/8/8/3B4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "The Bishop is a swift long-range sniper operating exclusively on diagonal pathways.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Because it moves diagonally, a Bishop bound to light squares can never cross over to a dark square.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.bishopDiagonals,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Send the Bishop on a long-range transit from d4 to the corner square h8.",
          highlightSquares: ['d4'],
          expectedMove: 'd4h8',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless trajectory. Long diagonals are extremely dangerous attack vectors.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Bishops move exclusively along diagonal paths. Maintain your color complex.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Bishop tactics locked in. Coordinate pairs of bishops to slice across the entire board.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 6: Knight Movement
    TutorialLesson(
      chapterId: 6,
      title: 'Knight Movement',
      setupFen: '8/8/8/8/3N4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Ah, the Knight. The trickster of the royal court, executing maneuvers that defy standard blockades.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Knights move in a distinct 'L-shape': two squares horizontally then one vertically, or two vertically then one horizontally.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.knightLPath,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Crucially, Knights are the only pieces capable of leaping directly over intervening friendly or enemy units.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Execute an L-shaped leap with your Knight from d4 to f5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4f5',
          reactionCorrect: MentorReaction(
            dialogue: "Superb. Notice how a Knight always lands on a square of the opposite color.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Trace the L-pattern carefully: two squares right to f4, then one square up to f5.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Knight mobility verified. Use their unique arc to launch unblockable surprise forks.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 7: Queen Movement
    TutorialLesson(
      chapterId: 7,
      title: 'Queen Movement',
      setupFen: '8/8/8/8/3Q4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Her Majesty, the Queen. The absolute apex predator of the chessboard.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The Queen combines the straight-line power of the Rook with the diagonal reach of the Bishop.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Unleash the Queen across the board: move her straight up to d8.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d8',
          reactionCorrect: MentorReaction(
            dialogue: "Devastating presence. Guard her carefully; losing your Queen early is often fatal.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The Queen moves in any straight or diagonal line. Glide straight up the file to d8.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Queen dominance affirmed. With great power comes immense tactical responsibility.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 8: King Movement
    TutorialLesson(
      chapterId: 8,
      title: 'King Movement',
      setupFen: '8/8/8/8/3K4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Finally, the King. The single piece that embodies the ultimate win or loss condition of the battle.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "The King moves deliberately: exactly one square in any adjacent direction — straight or diagonal.",
          highlightSquares: ['d4'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Step your King cautiously one square diagonally from d4 to e5.",
          highlightSquares: ['d4'],
          expectedMove: 'd4e5',
          reactionCorrect: MentorReaction(
            dialogue: "Steady progression. In the endgame, an active King becomes a vital attacking force.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "The King can only move one square per turn. Do not overextend beyond adjacent fields.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "King safety parameters online. Protect him at all costs during the opening and middlegame.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 9: Capturing
    TutorialLesson(
      chapterId: 9,
      title: 'Capturing Pieces',
      setupFen: '8/8/8/4p3/3R4/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Unlike checkers, chess pieces do not jump over enemies to capture them.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "To capture, a piece moves directly onto the square occupied by an opposing unit, removing it from the board.",
          highlightSquares: ['d4', 'e5'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Your Rook on d4 cannot capture diagonally. But wait... let us shift position.",
          highlightSquares: ['d4'],
          expectedMove: 'd4d5', // Let's setup a valid capture line next
          reactionIllegal: MentorReaction(
            dialogue: "Rooks move straight. Move to d5 first.",
            mood: MentorMood.correction,
          ),
        ),
      ],
    ),

    // Chapter 10: Check
    TutorialLesson(
      chapterId: 10,
      title: 'Understanding Check',
      setupFen: '8/8/8/8/8/8/4r3/4K3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "When a King is directly threatened with capture, he is in 'Check'.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Notice the enemy Rook aiming straight down the 'e' file at your King. This threat cannot be ignored.",
          highlightSquares: ['e1'],
          overlayEffect: TutorialOverlayEffect.checkPulse,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "You must resolve the Check immediately. Step your King off the dangerous file to d1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1d1',
          reactionCorrect: MentorReaction(
            dialogue: "Crisis averted. Evading the line of fire is the simplest way out of Check.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "You cannot remain in Check. Step sideways to d1 or f1 to escape the Rook's line.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Check protocol understood. Never leave your King exposed to immediate capture.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 11: Escaping Check
    TutorialLesson(
      chapterId: 11,
      title: 'Escaping Check',
      setupFen: '8/8/8/8/8/8/3B4/r3K3 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "There are exactly three ways to escape Check: Evade, Block, or Capture the attacker.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Here, the black Rook attacks from the flank. Moving the King is possible, but let us look closer.",
          highlightSquares: ['e1'],
          overlayEffect: TutorialOverlayEffect.checkPulse,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Intercept the threat! Drop your Bishop back from d2 to c1 to block the Rook's assault.",
          highlightSquares: ['d2'],
          expectedMove: 'd2c1',
          reactionCorrect: MentorReaction(
            dialogue: "Brilliant block. Using minor pieces as shields preserves your King's castling rights.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Your King is under fire from the side. Move the Bishop to c1 to cut the attack line.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Defense systems optimized. Always evaluate all three escape vectors before panicking.",
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
          dialogue: "The ultimate objective: Checkmate. A position where the King is in Check and has absolutely zero legal escapes.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Your King and Queen work in tandem to trap the black King in the corner. Deliver the final blow.",
          highlightSquares: ['f7'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Slide the Queen in for the kill: move her from f7 directly to g7.",
          highlightSquares: ['f7'],
          expectedMove: 'f7g7',
          reactionCorrect: MentorReaction(
            dialogue: "Checkmate! The enemy King is attacked and all escape squares are covered by your King.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Look for a square right next to the black King supported by your own King. Move to g7.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Absolute victory achieved. Coordination between pieces is the key to creating mating nets.",
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
          dialogue: "Beware the tragedy of Stalemate. A game drawn instantly because the player to move has no legal moves, yet their King is NOT in Check.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "If you carelessly move your Queen to g6, the black King will be trapped with no legal moves, triggering an automatic draw.",
          highlightSquares: ['g6'],
          overlayEffect: TutorialOverlayEffect.dangerZone,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Avoid the blunder. Make a constructive move that leaves the King breathing room: move the King from f6 to e6.",
          highlightSquares: ['f6'],
          expectedMove: 'f6e6',
          reactionCorrect: MentorReaction(
            dialogue: "Wise restraint. Always ensure your opponent has a legal response when closing in.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Do not crowd the cornered King unnecessarily. Step your own King away to e6.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Stalemate trap bypassed. Precision in the endgame prevents turning a guaranteed victory into a disappointing draw.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 14: Kingside Castling
    TutorialLesson(
      chapterId: 14,
      title: 'Kingside Castling',
      setupFen: '8/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Castling is a special dual-piece maneuver that simultaneously safeguards your King and activates your Rook.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "To castle Kingside (annotated as O-O), the squares between the King and the h-file Rook must be entirely vacant.",
          highlightSquares: ['e1', 'f1', 'g1', 'h1'],
          overlayEffect: TutorialOverlayEffect.castlingPath,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Neither piece can have moved previously, the King cannot be in check, and cannot pass through attacked squares.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Execute Kingside Castling: drag your King two squares to the right from e1 to g1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1g1',
          reactionCorrect: MentorReaction(
            dialogue: "Flawless execution. The King is safely tucked away, and the Rook leaps over to f1 ready for action.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "To castle, move the King exactly two squares toward the target Rook. Ensure paths are clear and unthreatened.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Kingside fortress established. Try to castle early in every game you play.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 15: Queenside Castling
    TutorialLesson(
      chapterId: 15,
      title: 'Queenside Castling',
      setupFen: '8/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Queenside Castling (annotated as O-O-O) operates on identical logic but spans the wider left flank.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "Three empty squares must separate the King from the a-file Rook. The King still moves exactly two squares left.",
          highlightSquares: ['e1', 'd1', 'c1', 'b1', 'a1'],
          overlayEffect: TutorialOverlayEffect.castlingPath,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Perform Queenside Castling: drag your King two squares left from e1 to c1.",
          highlightSquares: ['e1'],
          expectedMove: 'e1c1',
          reactionCorrect: MentorReaction(
            dialogue: "Magnificent. Notice how the Rook transits across three squares to land centrally on d1.",
            mood: MentorMood.encouraging,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "To castle, move the King exactly two squares toward the target Rook. Ensure paths are clear and unthreatened.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Dual flank castling mastered. Flexibility in your king placement keeps your opponent guessing.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 16: En Passant
    TutorialLesson(
      chapterId: 16,
      title: 'En Passant Capture',
      setupFen: '8/8/8/3pP3/8/8/8/8 w - d6 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "We arrive at 'En Passant' (in passing) — the most elusive and misunderstood rule in chess.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "When an enemy pawn leaps two squares forward from its starting rank, landing directly adjacent to your advanced pawn...",
          highlightSquares: ['e5', 'd5'],
          overlayEffect: TutorialOverlayEffect.enPassantArrow,
        ),
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "...you have the fleeting right to capture it diagonally as if it had only advanced a single square. This right lasts for exactly one turn.",
          mentorMood: MentorMood.correction,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Strike immediately! Move your white pawn diagonally from e5 to d6 to execute En Passant.",
          highlightSquares: ['e5'],
          expectedMove: 'e5d6',
          reactionCorrect: MentorReaction(
            dialogue: "Incredible capture. The bypassed black pawn on d5 is swept from the field.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "Attack diagonally behind the advanced enemy pawn. Move your pawn to d6.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "En Passant demystified. You now possess knowledge that eludes many intermediate casual players.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapter 17: Pawn Promotion
    TutorialLesson(
      chapterId: 17,
      title: 'Pawn Promotion',
      setupFen: '8/4P3/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Ascension awaits. When a humble pawn successfully navigates the board to reach the final enemy rank...",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.demonstrate,
          dialogue: "...it undergoes an instant transformation, promoting into a Queen, Rook, Bishop, or Knight.",
          highlightSquares: ['e7', 'e8'],
          overlayEffect: TutorialOverlayEffect.glowSquare,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Push your advanced pawn on e7 to the final rank at e8 and claim your new Queen.",
          highlightSquares: ['e7'],
          expectedMove: 'e7e8q',
          reactionCorrect: MentorReaction(
            dialogue: "A new Queen arises! Promotion converts positional perseverance into massive material advantage.",
            mood: MentorMood.celebration,
          ),
          reactionIllegal: MentorReaction(
            dialogue: "March straight forward to the back rank square e8 to trigger the ascension sequence.",
            mood: MentorMood.correction,
          ),
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Promotion protocols verified. Pushing passed pawns is a primary path to victory.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    // Chapters 18-23: Advanced Concepts and Verification matching plan outline
    TutorialLesson(
      chapterId: 18,
      title: 'Draw Conditions',
      setupFen: '8/8/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Beyond Stalemate, games can end in a draw through Agreement, Threefold Repetition, or the 50-Move Rule without captures or pawn pushes.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Understanding draw mechanisms allows you to salvage half a point from inferior endgame positions.",
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
          dialogue: "Three golden rules govern the opening: Control the Center, Develop Minor Pieces rapidly, and Castle early for King safety.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.awaitMove,
          dialogue: "Stake a perfect opening claim. Play your central King's pawn to e4.",
          highlightSquares: ['e2'],
          expectedMove: 'e2e4',
          reactionCorrect: MentorReaction(
            dialogue: "Excellent start. Space, development, and safety dictate the flow of the early game.",
            mood: MentorMood.encouraging,
          ),
        ),
      ],
    ),

    TutorialLesson(
      chapterId: 20,
      title: 'Piece Value Concepts',
      setupFen: '8/8/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Material evaluation guides trades. Standard scales assign: Queen=9, Rook=5, Bishop=3, Knight=3, and Pawn=1.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Never trade a high-value piece for a lesser one unless you calculate an immediate concrete tactical gain.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    TutorialLesson(
      chapterId: 21,
      title: 'Tactical Patterns',
      setupFen: '8/8/3q4/8/3N4/8/3K4/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "Tactics win material instantly. The most common pattern is the 'Fork' — a simultaneous double-attack launched by a single unit.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Look for geometries where one piece threatens two uncoordinated enemy targets at once.",
          mentorMood: MentorMood.celebration,
        ),
      ],
    ),

    TutorialLesson(
      chapterId: 22,
      title: 'Practice Challenges',
      setupFen: '8/8/8/8/8/8/8/8 w - - 0 1',
      steps: [
        TutorialStep(
          type: TutorialStepType.dialogue,
          dialogue: "You have absorbed the theory. Now, visualization must become automatic.",
          mentorMood: MentorMood.calm,
        ),
        TutorialStep(
          type: TutorialStepType.celebration,
          dialogue: "Your tactical awareness is sharp. Only one challenge remains.",
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
          dialogue: "The final trial. You will face Sparky in a fully unrestricted chess match. Show me what you have learned.",
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
