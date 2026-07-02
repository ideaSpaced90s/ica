import 'performance_ledger_entry.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.success()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.failure(this.errorMessage) : isValid = false;
}

class PerformanceLedgerValidator {
  static ValidationResult validate(
    PerformanceLedgerEntry entry,
    List<PerformanceLedgerEntry> existingEntries,
  ) {
    // 1. Structural Checks
    if (entry.id.trim().isEmpty) {
      return const ValidationResult.failure("Entry ID cannot be empty");
    }
    if (entry.fen.trim().isEmpty) {
      return const ValidationResult.failure("Entry FEN cannot be empty");
    }
    if (entry.result != 'W' && entry.result != 'L' && entry.result != 'D') {
      return ValidationResult.failure("Invalid game result: ${entry.result}");
    }
    if (entry.ratingCategory != 'bullet' &&
        entry.ratingCategory != 'blitz' &&
        entry.ratingCategory != 'rapid') {
      return ValidationResult.failure("Invalid rating category: ${entry.ratingCategory}");
    }

    // 2. Value Boundary Checks
    if (entry.dominance < -100.0 || entry.dominance > 100.0) {
      return ValidationResult.failure("Dominance value out of bounds: ${entry.dominance}");
    }
    if (entry.ratingSnapshot < 100 || entry.ratingSnapshot > 3500) {
      return ValidationResult.failure("Rating snapshot out of bounds: ${entry.ratingSnapshot}");
    }
    if (entry.whiteTimeLeftMs < 0 || entry.blackTimeLeftMs < 0) {
      return ValidationResult.failure(
        "Time left cannot be negative. White: ${entry.whiteTimeLeftMs}, Black: ${entry.blackTimeLeftMs}",
      );
    }

    // 3. Deduplication Check
    for (final existing in existingEntries) {
      if (existing.id == entry.id) {
        return ValidationResult.failure("Duplicate entry ID detected: ${entry.id}");
      }

      // Semantic duplicate check: same opponent, similar timestamp (within 2 seconds), and same final FEN.
      final isTimeSimilar =
          (existing.timestamp.difference(entry.timestamp).inSeconds).abs() < 2;
      final isOpponentSame = existing.opponentName == entry.opponentName;
      final isFenSame = existing.fen == entry.fen;

      if (isTimeSimilar && isOpponentSame && isFenSame) {
        return ValidationResult.failure(
          "Semantic duplicate game detected against ${entry.opponentName} at ${entry.timestamp}",
        );
      }
    }

    return const ValidationResult.success();
  }
}
