import '../domain/models/position_context.dart';
import '../data/saved_game.dart';

class PromptBuilder {
  static const String systemInstruction = '''
Identity: You are GM Bard, the Supreme Chess Mentor of the Academy. You are a wise human grandmaster.
Style: Speak calmly, concisely, and directly. Do not sound robotic. Never use terms like "engine", "Stockfish", "centipawns", or "evaluation". Always refer to the user as "Apprentice".
Rules:
1. You MUST always mention the specific chess move that was played or recommend the exact next move using standard piece names and squares (e.g., "Pawn to e4", "Knight to f3").
2. NEVER mention raw numerical evaluation scores, score changes, or points in your output (e.g. do NOT say "0.8 points", "0.0", or "change of 0.8"). Instead, explain the practical strategic consequence of the move (e.g., "weakening your kingside pawn structure", "opening up tactical lines", or "ceding control of the center").
3. Keep responses strictly limited to 1 or 2 sentences maximum. Do not write extended or general explanations. Be highly concise.
''';

  static String buildCommentaryPrompt({
    required PositionContext context,
    List<CommentaryEntry> chatHistory = const [],
    String? userQuery,
    String? systemInstructionOverride,
  }) {
    final buffer = StringBuffer();

    // 1. System Instruction in Gemma 3 formatting
    final system = systemInstructionOverride ?? systemInstruction;
    buffer.write('<start_of_turn>system\n$system<end_of_turn>\n');

    // 2. Few-shot Example 1: Standard Commentary
    buffer.write('<start_of_turn>user\n');
    buffer.write('Board State:\n');
    buffer.write('- Last Move Played: Knight to f3\n');
    buffer.write('- Analysis: The last move was a Strong move.\n');
    buffer.write('- Recommendation: Consider playing d7d5.\n');
    buffer.write('- Game Phase: Opening\n');
    buffer.write('- Tactical Alerts: None detected.\n');
    buffer.write('- Threat Level: Low\n');
    buffer.write('- Position Style: Positional\n');
    buffer.write('\nInstruction: React to the move with a brief, grandmaster-style comment. Speak directly to the Apprentice. Max 1-2 sentences.<end_of_turn>\n');
    buffer.write('<start_of_turn>model\n');
    buffer.write('White has developed their Knight to f3, controlling the center, Apprentice. I recommend contesting the center immediately by playing Pawn to d5.<end_of_turn>\n');

    // Few-shot Example 2: Tactical Threat (Pin)
    buffer.write('<start_of_turn>user\n');
    buffer.write('Board State:\n');
    buffer.write('- Last Move Played: Bishop to c5\n');
    buffer.write('- Analysis: The last move was a Blunder move.\n');
    buffer.write('- Recommendation: Consider playing c2c3.\n');
    buffer.write('- Game Phase: Middlegame\n');
    buffer.write('- Tactical Alerts:\n');
    buffer.write('  * Your Knight on f3 is pinned to your King by the opponent\'s Bishop on g4.\n');
    buffer.write('- Threat Level: High\n');
    buffer.write('- Position Style: Attacking\n');
    buffer.write('\nInstruction: React to the move with a brief, grandmaster-style comment. Speak directly to the Apprentice. Max 1-2 sentences.<end_of_turn>\n');
    buffer.write('<start_of_turn>model\n');
    buffer.write('A dangerous moment, Apprentice. Your Knight on f3 is pinned to your King. You must play cautiously—consider playing Pawn to c3 to challenge their center.<end_of_turn>\n');

    // Few-shot Example 3: User Ask (Advice)
    buffer.write('<start_of_turn>user\n');
    buffer.write('Apprentice: What should I play next?\n\n');
    buffer.write('Board State:\n');
    buffer.write('- Last Move Played: Pawn to e4\n');
    buffer.write('- Analysis: The last move was a Good move.\n');
    buffer.write('- Recommendation: Consider playing c7c5.\n');
    buffer.write('- Game Phase: Opening\n');
    buffer.write('- Tactical Alerts: None detected.\n');
    buffer.write('- Threat Level: Low\n');
    buffer.write('- Position Style: Positional\n');
    buffer.write('- Candidate Moves:\n');
    buffer.write('  * Option 1: Move c7c5, continuation: c7c5 -> g1f3 -> d7d6\n');
    buffer.write('  * Option 2: Move e7e5, continuation: e7e5 -> g1f3 -> b8c6\n');
    buffer.write('\nInstruction: Recommend the best move continuation and explain its direct benefit. Max 2 sentences.<end_of_turn>\n');
    buffer.write('<start_of_turn>model\n');
    buffer.write('I recommend playing Pawn to c5, Apprentice. This enters the Sicilian Defense, contesting the d4 square and creating asymmetrical tactical chances.<end_of_turn>\n');

    // 3. Conversation History (if present)
    if (chatHistory.isNotEmpty) {
      final relevantHistory = chatHistory.reversed.take(2).toList().reversed;
      for (final entry in relevantHistory) {
        final role = entry.isUser ? 'user' : 'model';
        buffer.write('<start_of_turn>$role\n${entry.text}<end_of_turn>\n');
      }
    }

    // 4. Current Prompt Input
    buffer.write('<start_of_turn>user\n');
    if (userQuery != null && userQuery.isNotEmpty) {
      buffer.write('Apprentice: $userQuery\n\n');
    }
    buffer.write(context.toPromptString());

    // Task definition based on whether we are replying to user query or move
    if (userQuery != null && userQuery.isNotEmpty) {
      final queryLower = userQuery.toLowerCase();
      String customTask = "Answer the Apprentice's query directly and concisely using the provided context. Limit to max 2 sentences.";
      if (queryLower.contains('analyze')) {
        customTask = "Perform a brief positional analysis of the current board state, highlighting the strategic situation and move recommendations. Max 2 sentences.";
      } else if (queryLower.contains('why') || queryLower.contains('opponent')) {
        customTask = "Briefly explain the goal and threats of the opponent's last move, and suggest a countermove. Max 2 sentences.";
      } else if (queryLower.contains('candidate') || queryLower.contains('what to play')) {
        customTask = "Review candidate moves, recommend the best option, and explain its main benefit. Max 2 sentences.";
      } else if (queryLower.contains('tactics') || queryLower.contains('threat')) {
        customTask = "Identify any tactical threats, pins, or forks, and recommend a response move. Max 2 sentences.";
      } else if (queryLower.contains('plan')) {
        customTask = "Briefly outline a clear mid-term strategic plan with specific move recommendations. Max 2 sentences.";
      } else if (queryLower.contains('defend') || queryLower.contains('protect')) {
        customTask = "Recommend a defensive move to consolidate the position. Max 2 sentences.";
      } else if (queryLower.contains('what') || queryLower.contains('play') || queryLower.contains('advice') || queryLower.contains('should')) {
        customTask = "Recommend the best move continuation and explain its direct benefit. Max 2 sentences.";
      }
      buffer.write('\nInstruction: $customTask<end_of_turn>\n');
    } else {
      buffer.write('\nInstruction: React to the move with a brief, grandmaster-style comment. Speak directly to the Apprentice. Max 1-2 sentences.<end_of_turn>\n');
    }

    buffer.write('<start_of_turn>model\n');
    return buffer.toString();
  }
}
