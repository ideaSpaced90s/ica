import 'dart:math';
import '../data/prescription_puzzle_repository.dart';

class ChanakyaQuotes {
  static final Random _random = Random();

  // 1. Diagnostic Intros — 4 variations per ScotomaAxis
  static const Map<ScotomaAxis, List<String>> intros = {
    ScotomaAxis.dgb: [
      "Apprentice, your eyes miss the long diagonal. Study this position — the retreating bishop is the weapon your opponent wields against you.",
      "I have reviewed your recent games. The retreating bishop on the long diagonal strikes when you least expect it. Today, we train your eye to see it coming.",
      "The diagonal is your blind alley. A bishop retreating to safety looks passive — but it bites. We correct this pattern today.",
      "Your records reveal a recurring weakness: the long diagonal retreat eludes you. The bishop moves backward to strike forward. Learn to see through this illusion.",
    ],
    ScotomaAxis.hrz: [
      "Your blindness lies in the lateral files. Train your eye to sweep horizontally. Find the rook's path.",
      "The rook slides across the rank — and you do not see it coming. This horizontal blindness is a gap in your radar that we shall close today.",
      "Study your losses, Apprentice. The decisive blow came along the rank, not the file. We train your lateral vision now.",
      "A rook on an open rank is a devastating weapon, and you have been slow to recognize it. Today's puzzles will sharpen your awareness of horizontal threats.",
    ],
    ScotomaAxis.knf: [
      "The knight on the flank haunts your games. Learn to see the L-shaped threat from the edges before it forks your pieces.",
      "Knights do not announce their intentions — they strike in silence. Your records show you are frequently caught by the fork. We correct this today.",
      "The L-shape is chess's most deceptive weapon. Your games show a pattern: you miss the knight fork until it is too late. This training plan begins your improvement.",
      "Apprentice, knights on the rim are not dim — they are dangerous. Your blind spot for knight forks has cost you material. Let us end that pattern.",
    ],
    ScotomaAxis.tmp: [
      "You crumble under time pressure. 15 seconds, Apprentice. Find the move. There is no time for fear — only sight.",
      "Your game collapses when the clock threatens you. Today we train your instinct — the ability to find the correct move in seconds, not minutes.",
      "Time panic is a disease of the untrained mind. You have the knowledge; you lack the speed. Today's puzzles are timed. Learn to trust your instinct.",
      "Your clock management reveals a critical flaw: you freeze when time is short. We train the reflex today. The correct move must become instinct.",
    ],
    ScotomaAxis.grd: [
      "Greed is your enemy. Before you capture, look at what the opponent prepares. This puzzle teaches discipline.",
      "Your games are filled with poisoned captures. The opponent offers material — you take it — and you suffer. Today we break the habit of unexamined greed.",
      "The free pawn is never truly free. Your loss history confirms it. Before you reach out to capture, ask: why is this piece being offered to me?",
      "Material greed has blinded you to the opponent's hidden intentions. This training plan trains you to always ask — what does my opponent gain when I capture?",
    ],
    ScotomaAxis.tnl: [
      "You focus on one side, blind to the other. The decisive blow always comes from where you are not looking.",
      "Tunnel vision: you lock onto one threat and lose sight of the entire board. Your games prove it. Today we train the panoramic vision every master possesses.",
      "Your opponent attacked on the queenside while you fixated on the kingside. This happened repeatedly. We treat the tunnel today — see the entire board.",
      "A great chess player sees all 64 squares at once. Your records show that you fixate. We open the vision today.",
    ],
    ScotomaAxis.pin: [
      "A pinned piece is a ghost defender. You have been fooled by them before. This puzzle corrects the hallucination.",
      "Your games reveal that you have often relied on a pinned piece to defend — only to discover it cannot. Today we make this lesson permanent.",
      "The pin removes a defender while leaving it on the board. This illusion has fooled you many times. Today's training plan corrects the ghost-defender blindspot.",
      "You count pinned pieces as defenders. They are not. This fundamental error has cost you games. We correct it today — once and for all.",
    ],
    ScotomaAxis.ksb: [
      "Your king breathes easy while danger forms. I will show you mating nets until they become instinct.",
      "You have underestimated the danger to your king on multiple occasions. Today I show you the mating patterns that haunted your games, until you recognize them instantly.",
      "King safety is not an option — it is a requirement. Your games show a recurring disregard for the king's shelter. We correct this with targeted pattern recognition.",
      "The king hunt — your most common cause of defeat. Your king safety instincts need sharpening. This training plan gives you the positions that punish carelessness.",
    ],
    ScotomaAxis.balanced: [
      "Your vision is balanced, Apprentice. Now we sharpen all edges. A well-rounded tactician fears nothing. Begin.",
      "No single weakness dominates your profile. Yet balance is not mastery — it is the starting point. We sharpen every edge today.",
      "A balanced tactician is a versatile one. Your scotoma shows no critical blind spots — we now intensify the training across all dimensions.",
      "The diagnostics show parity across all blindspot axes. Good. Now we elevate every axis. The well-rounded master leaves no weakness untrained.",
    ],
  };

  // 2. Wrong Move Warnings — expanded to 28 strings
  static const List<String> wrongMoves = [
    "Ah, not quite. Do not snatch at the bait. Visualize the opponent's reply before you leap.",
    "Look closer, Apprentice. A hasty move is a trap you set for yourself.",
    "A move made in haste leads to regret in leisure. Recalculate your path.",
    "That square is a mirage. Do not let your desires blind you to the reality of the board.",
    "Your mind wanders like a wild elephant. Focus. Discipline is the key to sight.",
    "A warrior does not strike blindly. Understand the weaknesses of the enemy first.",
    "A simple error, but fatal. Think before you commit your forces.",
    "The board does not lie. That move leaves you vulnerable. Search for the true path.",
    "You play with hope, not calculation. Hope is a poor shield against checkmate.",
    "An incorrect attempt. Go back. Let patience guide your hand.",
    "Do you see the danger now? Retreat and find the hidden line.",
    "A tactical error. The wise man learns from his defeat. Try again.",
    "Your eyes are captured by the wrong target. Look at the whole board.",
    "Do not let frustration cloud your calculation. Start from the beginning.",
    "Your opponent expected that. Surprise them with the correct continuation.",
    "The sequence you chose was not wrong by accident — it was wrong by instinct. Train the instinct.",
    "Not every aggressive move is the correct move. This one is not. Look deeper.",
    "The puzzle has a solution hidden in the tension between the pieces. You have not found it yet.",
    "That square looked inviting, did it not? The best traps always do. Look again.",
    "A natural-looking move — but natural is not always correct. Find the exceptional one.",
    "You moved the piece your hand wanted to move. Move the piece the position demands.",
    "An incorrect idea, but not a wasted one. Now you know one path that does not work.",
    "Every wrong move narrows the search. You are getting closer. Think again.",
    "The solution requires a counter-intuitive decision. Abandon the obvious.",
    "Trust your calculation, not your instinct. The instinct has misled you here.",
    "The pattern is there — you are looking at the wrong piece. Shift your attention.",
    "Chess is a game of patience. The correct move will reveal itself when you stop forcing.",
    "Recalculate. The winning sequence begins differently than you imagined.",
  ];

  // 3. Move Progress (Correct mid-puzzle) — expanded to 20 strings
  static const List<String> correctMoves = [
    "Yes, the path opens. Follow it.",
    "Good sight. Now deliver the finishing blow.",
    "The first step is correct. Keep your focus.",
    "Instinct is translating to action. Continue.",
    "A clean execution. The puzzle unravels.",
    "They falter. Strike again.",
    "Your calculation is holding true. Proceed.",
    "The coordinates align. Find the next move.",
    "Perfect placement. The end is in sight.",
    "Do not stop now. Complete the sequence.",
    "Excellent. The combination is unfolding exactly as it should.",
    "That move was precise. The opponent has no good reply. Continue.",
    "You see it now. The rest of the sequence is yours to complete.",
    "Good. The tactical logic is sound. What comes next?",
    "The position is cracking. One more accurate move seals it.",
    "You are in the zone, Apprentice. Do not break concentration.",
    "That is correct. Every move in a tactical sequence must be this precise.",
    "The domino falls. Drive the combination to its conclusion.",
    "Exactly right. The opponent is helpless now. Finish the work.",
    "A moment of clarity. Sustain it. The final blow is within reach.",
  ];

  // 4. Puzzle Solved / Training Counters
  static const Map<int, List<String>> progressQuotes = {
    1: [
      "Well done. One step taken on the path. 4 puzzles remain to complete your daily training plan.",
      "First victory secured. Keep the vision sharp, 4 more to go.",
      "The training begins to show results. 4 puzzles remaining.",
      "A successful start. The mind begins to see. 4 to go.",
      "Good execution. Do not let your guard down now, 4 puzzles left.",
    ],
    2: [
      "Instinct is forming. 3 puzzles remaining.",
      "A second blow delivered. 3 steps left to complete this training set.",
      "The blindspot begins to clear. 3 puzzles left.",
      "You calculate well today. Keep this pace for 3 more puzzles.",
      "Halfway to the target. 3 puzzles remain.",
    ],
    3: [
      "Sharp focus! You are over halfway there. 2 puzzles left.",
      "Two steps remain. The training begins to show in your eyes.",
      "A third checkmate. Only 2 puzzles stand between you and balance.",
      "Good vision. Stay disciplined for the final 2 puzzles.",
      "The enemy is retreating. 2 puzzles remaining.",
    ],
    4: [
      "Excellent. One final puzzle to clear your visual field.",
      "The end is near. Focus all your energy on this last puzzle.",
      "Only 1 challenge left. Prove your mastery.",
      "You have done well. Now, solve the final puzzle of your daily training plan.",
      "One last step, Apprentice. Make it perfect.",
    ],
  };

  // 5. Complete Training
  static const List<String> completions = [
    "Training plan complete! Your visual fields are sharpening. Return to the Arena and let your games prove your sight.",
    "Your mind is balanced, Apprentice. The training is done for now. Go test your sight in a rated battleground.",
    "Your visual blindspot is temporarily cleared. Go play a rated match to verify your progress.",
    "Daily training complete. You have earned your rest — or your next victory in the Arena.",
    "Excellent discipline. Your calculation is restored. Go, test your strength against the avatars now.",
    "We have corrected the blindspot for today. Go play in the Arena and see the difference.",
  ];

  static String getIntro(ScotomaAxis axis) {
    final list = intros[axis] ?? intros[ScotomaAxis.balanced]!;
    return list[_random.nextInt(list.length)];
  }

  static String getWrongMove() {
    return wrongMoves[_random.nextInt(wrongMoves.length)];
  }

  static String getCorrectMove() {
    return correctMoves[_random.nextInt(correctMoves.length)];
  }

  static String getProgress(int solvedCount) {
    final list = progressQuotes[solvedCount];
    if (list == null || list.isEmpty) {
      return "Puzzle solved. Keep going!";
    }
    return list[_random.nextInt(list.length)];
  }

  static String getCompletion() {
    return completions[_random.nextInt(completions.length)];
  }
}
