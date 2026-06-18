import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/features/chess/application/study_lab_provider.dart';
import 'package:chess/chess.dart' as chess_lib;

void main() {
  late ProviderContainer container;
  late StudyLabNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(studyLabProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state is correct', () {
    final state = container.read(studyLabProvider);
    expect(state.nodes, isEmpty);
    expect(state.currentNodeIndex, isNull);
    expect(state.activeFen, chess_lib.Chess.DEFAULT_POSITION);
    expect(state.isGuessingMode, isFalse);
  });

  test('makeMove correctly adds nodes and computes SAN', () {
    // 1. Move e2 to e4
    notifier.makeMove('e2', 'e4');
    
    var state = container.read(studyLabProvider);
    expect(state.nodes.length, 1);
    expect(state.currentNodeIndex, 0);
    expect(state.nodes[0].san, 'e4');
    expect(state.nodes[0].uci, 'e2e4');
    expect(state.nodes[0].parentIndex, isNull);
    expect(state.nodes[0].childIndices, isEmpty);
    
    // 2. Move e7 to e5
    notifier.makeMove('e7', 'e5');
    
    state = container.read(studyLabProvider);
    expect(state.nodes.length, 2);
    expect(state.currentNodeIndex, 1);
    expect(state.nodes[1].san, 'e5');
    expect(state.nodes[1].uci, 'e7e5');
    expect(state.nodes[1].parentIndex, 0);
    expect(state.nodes[0].childIndices, [1]);
  });

  test('makeMove correctly handles variations', () {
    // 1. Move e2e4
    notifier.makeMove('e2', 'e4');
    // 2. Move e7e5 (Mainline node 1)
    notifier.makeMove('e7', 'e5');
    
    // Go back to e2e4
    notifier.selectNode(0);
    
    // 3. Move c7c5 (Variation node 2)
    notifier.makeMove('c7', 'c5');
    
    final state = container.read(studyLabProvider);
    expect(state.nodes.length, 3);
    expect(state.currentNodeIndex, 2);
    expect(state.nodes[2].san, 'c5');
    expect(state.nodes[2].parentIndex, 0);
    expect(state.nodes[0].childIndices, containsAll([1, 2]));
  });
}
