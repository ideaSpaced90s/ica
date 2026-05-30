import 'dart:math';
import '../data/prescription_puzzle_repository.dart';

class ChanakyaQuotes {
  static final Random _random = Random();

  // 1. Diagnostic Intros
  static const Map<ScotomaAxis, String> intros = {
    ScotomaAxis.dgb: "Apprentice, your eyes miss the long diagonal. Study this position — the retreating bishop is the weapon your opponent wields against you.",
    ScotomaAxis.hrz: "Your blindness lies in the lateral files. Train your eye to sweep horizontally. Find the rook's path.",
    ScotomaAxis.knf: "The knight on the flank haunts your games. Learn to see the L-shaped threat from the edges before it forks your pieces.",
    ScotomaAxis.tmp: "You crumble under time pressure. 15 seconds, Apprentice. Find the move. There is no time for fear — only sight.",
    ScotomaAxis.grd: "Greed is your enemy. Before you capture, look at what the opponent prepares. This puzzle teaches discipline.",
    ScotomaAxis.tnl: "You focus on one side, blind to the other. The decisive blow always comes from where you are not looking.",
    ScotomaAxis.pin: "A pinned piece is a ghost defender. You have been fooled by them before. This puzzle cures the hallucination.",
    ScotomaAxis.ksb: "Your king breathes easy while danger forms. I will show you mating nets until they become instinct.",
    ScotomaAxis.balanced: "Your vision is balanced, Apprentice. Now we sharpen all edges. A well-rounded tactician fears nothing. Begin.",
  };

  // 2. Wrong Move Warnings
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
  ];

  // 3. Move Progress (Correct mid-puzzle)
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
  ];

  // 4. Puzzle Solved / Dose Counters
  static const Map<int, List<String>> progressQuotes = {
    1: [
      "Well done. One step taken on the path. 4 puzzles remain to complete your prescription.",
      "First victory secured. Keep the vision sharp, 4 more to go.",
      "The medicine begins to work. 4 puzzles remaining.",
      "A successful start. The mind begins to see. 4 to go.",
      "Good execution. Do not let your guard down now, 4 puzzles left.",
    ],
    2: [
      "Instinct is forming. 3 puzzles remaining.",
      "A second blow delivered. 3 steps left to complete the dose.",
      "The scotoma begins to clear. 3 puzzles left.",
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
      "You have done well. Now, solve the final puzzle of your prescription.",
      "One last step, Apprentice. Make it perfect.",
    ],
  };

  // 5. Complete Prescription
  static const List<String> completions = [
    "Prescription complete! Your visual fields are sharpening. Return to the Arena and let your games prove your sight.",
    "Your mind is balanced, Apprentice. The training is done for now. Go test your sight in a rated battleground.",
    "The visual scotoma is temporarily cleared. Go play a rated match to verify your progress.",
    "Prescription dose complete. You have earned your rest — or your next victory in the Arena.",
    "Excellent discipline. Your calculation is restored. Go, test your strength against the avatars now.",
    "We have cured the blindness for today. Go play in the Arena and see the difference.",
  ];

  static String getIntro(ScotomaAxis axis) {
    return intros[axis] ?? intros[ScotomaAxis.balanced]!;
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
