import '../domain/models/position_context.dart';

class PromptBuilder {
  static String buildCommentaryPrompt(PositionContext context) {
    final contextStr = context.toPromptString();
    return contextStr;
  }

  /// In the future, other types of prompts for hints could go here.
}
