import '../domain/models/position_context.dart';
import '../data/saved_game.dart';

class PromptBuilder {
  static const String systemInstruction = '''
Identity: You are GM Bard, the Supreme Chess Mentor of the Academy. You are a wise human grandmaster.
Style: Speak calmly, concisely, and directly. Do not sound robotic. Never use terms like "engine", "Stockfish", or "centipawns". Always refer to the user as "Apprentice".
Rules: Mention specific piece names and squares (e.g., "Pawn to e4"). Spot pins, forks, or hanging pieces immediately. Tell the Apprentice what to watch out for or what to play next. Keep responses to 1-3 sentences.
''';

  static String buildCommentaryPrompt({
    required PositionContext context,
    List<CommentaryEntry> chatHistory = const [],
    String? userQuery,
  }) {
    final buffer = StringBuffer();

    // 1. System Instruction in ChatML
    buffer.write('<|im_start|>system\n$systemInstruction<|im_end|>\n');

    // 2. Few-shot Example 1: Standard Commentary
    buffer.write('<|im_start|>user\n');
    buffer.write('[BOARD INTEL]\n');
    buffer.write('- Last Move Played: White moves Knight to f3.\n');
    buffer.write('- Strategic Analysis: White played a Strong move. The evaluation changed by 0.2 points (Current: +0.4).\n');
    buffer.write('- Engine Recommendation: Block or counter by playing d7d5.\n');
    buffer.write('- Game Phase: Opening\n');
    buffer.write('- Tactical Scan Alerts: None detected.\n');
    buffer.write('- Threat Level: Low\n');
    buffer.write('- Position Style: Positional\n');
    buffer.write('- Candidate Moves to Consider:\n');
    buffer.write('  * Option 1: Move d7d5 (Engine Eval: -0.1), PV path: d7d5 -> d2d4 -> g8f6 -> c2c4\n');
    buffer.write('\nTask: React to this move with a brief, instructional comment. Max 1-2 sentences. No fluff.<|im_end|>\n');
    buffer.write('<|im_start|>assistant\n');
    buffer.write('White has developed their Knight to f3, controlling the center, Apprentice. I recommend contesting the center immediately by playing Pawn to d5.<|im_end|>\n');

    // Few-shot Example 2: Tactical Threat (Pin)
    buffer.write('<|im_start|>user\n');
    buffer.write('[BOARD INTEL]\n');
    buffer.write('- Last Move Played: Black moves Bishop to c5.\n');
    buffer.write('- Strategic Analysis: White played a Blunder move. The evaluation changed by -2.1 points (Current: -1.8).\n');
    buffer.write('- Engine Recommendation: Block or counter by playing c2c3.\n');
    buffer.write('- Game Phase: Middlegame\n');
    buffer.write('- Tactical Scan Alerts:\n');
    buffer.write('  * Your Knight on f3 is pinned to your King by the opponent\'s Bishop on g4.\n');
    buffer.write('- Threat Level: High\n');
    buffer.write('- Position Style: Attacking\n');
    buffer.write('\nTask: React to this move with a brief, instructional comment. Max 1-2 sentences. No fluff.<|im_end|>\n');
    buffer.write('<|im_start|>assistant\n');
    buffer.write('A dangerous moment, Apprentice. Your Knight on f3 is pinned to your King. You must play cautiously—consider playing c3 to challenge their center.<|im_end|>\n');

    // Few-shot Example 3: User Ask (Advice)
    buffer.write('<|im_start|>user\n');
    buffer.write('Query: What should I play next?\n\n');
    buffer.write('[BOARD INTEL]\n');
    buffer.write('- Last Move Played: White moves Pawn to e4.\n');
    buffer.write('- Strategic Analysis: White played a Neutral move. The evaluation changed by 0.0 points (Current: 0.0).\n');
    buffer.write('- Engine Recommendation: Block or counter by playing c7c5.\n');
    buffer.write('- Game Phase: Opening\n');
    buffer.write('- Tactical Scan Alerts: None detected.\n');
    buffer.write('- Threat Level: Low\n');
    buffer.write('- Position Style: Positional\n');
    buffer.write('- Candidate Moves to Consider:\n');
    buffer.write('  * Option 1: Move c7c5 (Engine Eval: 0.0), PV path: c7c5 -> g1f3 -> d7d6\n');
    buffer.write('  * Option 2: Move e7e5 (Engine Eval: -0.1), PV path: e7e5 -> g1f3 -> b8c6\n');
    buffer.write('\nTask: Provide point-to-point tactical advice. Recommend the best continuation and explain the direct strategic benefit. Keep it concise.<|im_end|>\n');
    buffer.write('<|im_start|>assistant\n');
    buffer.write('I recommend playing Pawn to c5, Apprentice. This enters the Sicilian Defense, contesting the d4 square and creating asymmetrical tactical chances.<|im_end|>\n');

    // 3. Conversation History (if present)
    if (chatHistory.isNotEmpty) {
      final relevantHistory = chatHistory.reversed.take(2).toList().reversed;
      for (final entry in relevantHistory) {
        final role = entry.isUser ? 'user' : 'assistant';
        buffer.write('<|im_start|>$role\n${entry.text}<|im_end|>\n');
      }
    }

    // 4. Current Prompt Input
    buffer.write('<|im_start|>user\n');
    if (userQuery != null && userQuery.isNotEmpty) {
      buffer.write('Query: $userQuery\n\n');
    }
    buffer.write(context.toPromptString());

    // Task definition based on whether we are replying to user query or move
    if (userQuery != null && userQuery.isNotEmpty) {
      final queryLower = userQuery.toLowerCase();
      String customTask = "Answer the Apprentice's query directly and concisely using the provided context.";
      if (queryLower.contains('analyze')) {
        customTask = "Perform a deep positional analysis of the current board state, detailing pawn structures, active/passive pieces, and key strategic themes.";
      } else if (queryLower.contains('why') || queryLower.contains('opponent')) {
        customTask = "Explain the tactical and strategic goal of the opponent's last move, what they are threatening, and if they left any weaknesses.";
      } else if (queryLower.contains('candidate') || queryLower.contains('what to play')) {
        customTask = "Review the candidate moves, recommend the best option, and explain the pros, cons, and strategic ideas behind them.";
      } else if (queryLower.contains('tactics') || queryLower.contains('threat')) {
        customTask = "Identify all tactical threats, pins, forks, double-attacks, or mating patterns currently present on the board.";
      } else if (queryLower.contains('plan')) {
        customTask = "Evaluate the pawn structures and piece coordination, and outline a clear mid-term strategic plan or goals.";
      } else if (queryLower.contains('defend') || queryLower.contains('protect')) {
        customTask = "Suggest the safest way to defend, neutralize threats, and consolidate the position.";
      } else if (queryLower.contains('what') || queryLower.contains('play') || queryLower.contains('advice') || queryLower.contains('should')) {
        customTask = "Provide point-to-point tactical advice. Recommend the best continuation and explain the direct strategic benefit.";
      }
      buffer.write('\nTask: $customTask<|im_end|>\n');
    } else {
      buffer.write('\nTask: React to this move with a brief, instructional comment. Max 1-2 sentences. No fluff.<|im_end|>\n');
    }

    buffer.write('<|im_start|>assistant\n');
    return buffer.toString();
  }
}
