// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/src/rust/frb_generated.dart';
import 'package:kingslayer_chess/features/chess/data/puzzle_repository.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    print('=== INITIALIZING RUST LIB ===');
    await RustLib.init();
    print('=== RUST LIB INITIALIZED ===');
  });

  testWidgets('Test Puzzle Repository and Queries on Windows', (WidgetTester tester) async {
    final repo = PuzzleRepository();
    
    print('=== TESTING DATABASE PATH GETTING ===');
    try {
      final dbPath = await repo.getDatabasePath();
      print('=== SUCCESS: DB PATH IS $dbPath ===');
    } catch (e, stack) {
      print('=== ERROR GETTING DB PATH: $e ===\n$stack');
    }

    print('=== TESTING RANDOM PUZZLE GETTING ===');
    try {
      final p = await repo.getRandomPuzzle();
      if (p != null) {
        print('=== SUCCESS: GET RANDOM PUZZLE SUCCESS! ID: ${p.id}, Rating: ${p.rating}, FEN: ${p.fen} ===');
      } else {
        print('=== FAIL: GET RANDOM PUZZLE RETURNED NULL ===');
      }
    } catch (e, stack) {
      print('=== ERROR GETTING RANDOM PUZZLE: $e ===\n$stack');
    }
  });
}
