import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:intl/intl.dart';
import '../data/stockfish_service.dart';
import '../data/uci_parser.dart';

class StudyLabMoveNode {
  final int index;
  final String uci;
  final String san;
  final String fen;
  final String comment;
  final int? parentIndex;
  final List<int> childIndices;

  const StudyLabMoveNode({
    required this.index,
    required this.uci,
    required this.san,
    required this.fen,
    this.comment = '',
    this.parentIndex,
    this.childIndices = const [],
  });

  StudyLabMoveNode copyWith({
    int? index,
    String? uci,
    String? san,
    String? fen,
    String? comment,
    int? parentIndex,
    List<int>? childIndices,
  }) {
    return StudyLabMoveNode(
      index: index ?? this.index,
      uci: uci ?? this.uci,
      san: san ?? this.san,
      fen: fen ?? this.fen,
      comment: comment ?? this.comment,
      parentIndex: parentIndex ?? this.parentIndex,
      childIndices: childIndices ?? this.childIndices,
    );
  }
}

class _PgnParserState {
  final int? nodeIndex;
  final String fen;
  _PgnParserState({required this.nodeIndex, required this.fen});
}

class PgnToken {
  final String type; // 'MOVE', 'COMMENT', 'PAREN_OPEN', 'PAREN_CLOSE', 'METADATA', 'NUMBER'
  final String value;
  PgnToken(this.type, this.value);
}

class StudyLabState {
  final List<StudyLabMoveNode> nodes;
  final int? currentNodeIndex;
  final String startFen;
  final bool isAnalysisActive;
  final int engineDepth;
  final bool isBoardFlipped;
  final Map<int, Map<String, dynamic>> engineLines; // multiPV index -> line info
  final String? commentary; // GM Bard commentary or opening name

  StudyLabState({
    this.nodes = const [],
    this.currentNodeIndex,
    this.startFen = chess_lib.Chess.DEFAULT_POSITION,
    this.isAnalysisActive = false,
    this.engineDepth = 15,
    this.isBoardFlipped = false,
    this.engineLines = const {},
    this.commentary,
  });

  String get activeFen {
    if (currentNodeIndex == null || currentNodeIndex! >= nodes.length) {
      return startFen;
    }
    return nodes[currentNodeIndex!].fen;
  }

  bool get canUndo => currentNodeIndex != null;
  bool get canRedo {
    if (currentNodeIndex == null) {
      return nodes.any((n) => n.parentIndex == null);
    }
    return nodes[currentNodeIndex!].childIndices.isNotEmpty;
  }

  StudyLabState copyWith({
    List<StudyLabMoveNode>? nodes,
    Object? currentNodeIndex = const Object(),
    String? startFen,
    bool? isAnalysisActive,
    int? engineDepth,
    bool? isBoardFlipped,
    Map<int, Map<String, dynamic>>? engineLines,
    Object? commentary = const Object(),
  }) {
    return StudyLabState(
      nodes: nodes ?? this.nodes,
      currentNodeIndex: currentNodeIndex == const Object()
          ? this.currentNodeIndex
          : currentNodeIndex as int?,
      startFen: startFen ?? this.startFen,
      isAnalysisActive: isAnalysisActive ?? this.isAnalysisActive,
      engineDepth: engineDepth ?? this.engineDepth,
      isBoardFlipped: isBoardFlipped ?? this.isBoardFlipped,
      engineLines: engineLines ?? this.engineLines,
      commentary: commentary == const Object()
          ? this.commentary
          : commentary as String?,
    );
  }
}

class StudyLabNotifier extends StateNotifier<StudyLabState> {
  final StockfishService _engine;
  StreamSubscription? _engineSubscription;

  StudyLabNotifier(this._engine) : super(StudyLabState()) {
    _initEngineListener();
  }

  void _initEngineListener() {
    _engineSubscription = _engine.outputStream.listen((line) {
      if (!state.isAnalysisActive) return;
      final parsed = UCIParser.parseLine(line);
      if (parsed['type'] == 'info' && parsed.containsKey('multipv')) {
        final multiPV = parsed['multipv'] as int;
        final currentLines = Map<int, Map<String, dynamic>>.from(state.engineLines);
        currentLines[multiPV] = parsed;
        state = state.copyWith(engineLines: currentLines);
      }
    });
  }

  @override
  void dispose() {
    _engineSubscription?.cancel();
    super.dispose();
  }

  Future<void> toggleAnalysis() async {
    final active = !state.isAnalysisActive;
    state = state.copyWith(
      isAnalysisActive: active,
      engineLines: {},
    );

    if (active) {
      await _engine.init();
      await _engine.sendCommand('setoption name MultiPV value 3');
      _triggerAnalysis();
    } else {
      await _engine.stopAnalysis();
    }
  }

  void updateEngineDepth(int depth) {
    state = state.copyWith(engineDepth: depth);
    if (state.isAnalysisActive) {
      _triggerAnalysis();
    }
  }

  void _triggerAnalysis() {
    if (!state.isAnalysisActive) return;
    state = state.copyWith(engineLines: {});
    _engine.analyzePosition(state.activeFen, depth: state.engineDepth);
  }

  void selectNode(int? index) {
    state = state.copyWith(currentNodeIndex: index);
    _updateOpeningRecognition();
    _triggerAnalysis();
  }

  void makeMove(String from, String to, [String promotion = '']) {
    final localChess = chess_lib.Chess.fromFEN(state.activeFen);
    
    // Find the move in generate_moves to get its SAN before executing the move
    final moves = localChess.generate_moves();
    chess_lib.Move? matchingMove;
    for (final m in moves) {
      final mFrom = chess_lib.Chess.algebraic(m.from);
      final mTo = chess_lib.Chess.algebraic(m.to);
      final mPromo = m.promotion != null ? m.promotion.toString().split('.').last.toLowerCase()[0] : '';
      if (mFrom == from && mTo == to && mPromo == promotion) {
        matchingMove = m;
        break;
      }
    }

    if (matchingMove == null) return;
    
    final san = localChess.move_to_san(matchingMove);

    final moveMap = {
      'from': from,
      'to': to,
      if (promotion.isNotEmpty) 'promotion': promotion,
    };

    final success = localChess.move(moveMap);
    if (!success) return;

    final uci = '$from$to$promotion';
    final newFen = localChess.fen;

    // Check if node already exists as a child of current node
    final children = state.currentNodeIndex == null
        ? state.nodes.where((n) => n.parentIndex == null).toList()
        : state.nodes[state.currentNodeIndex!].childIndices
            .map((idx) => state.nodes[idx])
            .toList();

    final existingNode = children.where((n) => n.uci == uci).firstOrNull;

    if (existingNode != null) {
      selectNode(existingNode.index);
      return;
    }

    // Create a new node
    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    final newNodeIdx = newNodes.length;
    final newNode = StudyLabMoveNode(
      index: newNodeIdx,
      uci: uci,
      san: san,
      fen: newFen,
      parentIndex: state.currentNodeIndex,
      childIndices: const [],
    );

    newNodes.add(newNode);

    if (state.currentNodeIndex != null) {
      final parentNode = newNodes[state.currentNodeIndex!];
      newNodes[state.currentNodeIndex!] = parentNode.copyWith(
        childIndices: [...parentNode.childIndices, newNodeIdx],
      );
    }

    state = state.copyWith(
      nodes: newNodes,
      currentNodeIndex: newNodeIdx,
    );

    _updateOpeningRecognition();
    _triggerAnalysis();
  }

  void undo() {
    if (state.currentNodeIndex == null) return;
    final parentIdx = state.nodes[state.currentNodeIndex!].parentIndex;
    selectNode(parentIdx);
  }

  void redo() {
    final children = state.currentNodeIndex == null
        ? state.nodes.where((n) => n.parentIndex == null).toList()
        : state.nodes[state.currentNodeIndex!].childIndices
            .map((idx) => state.nodes[idx])
            .toList();

    if (children.isNotEmpty) {
      selectNode(children.first.index);
    }
  }

  void flipBoard() {
    state = state.copyWith(isBoardFlipped: !state.isBoardFlipped);
  }

  void updateComment(String comment) {
    if (state.currentNodeIndex == null) return;
    final idx = state.currentNodeIndex!;
    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    newNodes[idx] = newNodes[idx].copyWith(comment: comment);
    state = state.copyWith(nodes: newNodes);
  }

  void deleteCurrentNode() {
    if (state.currentNodeIndex == null) return;
    final targetIdx = state.currentNodeIndex!;
    final parentIdx = state.nodes[targetIdx].parentIndex;

    // Filter out targetIdx and any of its recursive descendants
    final desc = _getDescendants(targetIdx);
    final toDelete = {targetIdx, ...desc};

    final newNodes = <StudyLabMoveNode>[];
    final indexMapping = <int, int>{}; // old index -> new index

    for (var i = 0; i < state.nodes.length; i++) {
      if (toDelete.contains(i)) continue;
      indexMapping[i] = newNodes.length;
      newNodes.add(state.nodes[i]);
    }

    // Remap parent and child pointers
    for (var i = 0; i < newNodes.length; i++) {
      final node = newNodes[i];
      final newParentIdx = node.parentIndex != null ? indexMapping[node.parentIndex!] : null;
      final newChildren = node.childIndices
          .where((idx) => !toDelete.contains(idx))
          .map((idx) => indexMapping[idx]!)
          .toList();

      newNodes[i] = node.copyWith(
        index: i,
        parentIndex: newParentIdx,
        childIndices: newChildren,
      );
    }

    final newCurrentIdx = parentIdx != null ? indexMapping[parentIdx] : null;

    state = state.copyWith(
      nodes: newNodes,
      currentNodeIndex: newCurrentIdx,
    );

    _updateOpeningRecognition();
    _triggerAnalysis();
  }

  Set<int> _getDescendants(int index) {
    final result = <int>{};
    final queue = <int>[...state.nodes[index].childIndices];
    while (queue.isNotEmpty) {
      final next = queue.removeAt(0);
      if (result.add(next)) {
        queue.addAll(state.nodes[next].childIndices);
      }
    }
    return result;
  }

  void clearBoard() {
    state = StudyLabState(
      nodes: const [],
      currentNodeIndex: null,
      startFen: chess_lib.Chess.DEFAULT_POSITION,
      isAnalysisActive: state.isAnalysisActive,
      engineDepth: state.engineDepth,
      isBoardFlipped: state.isBoardFlipped,
    );
    _triggerAnalysis();
  }

  List<PgnToken> tokenizePgn(String pgn) {
    final tokens = <PgnToken>[];
    int i = 0;
    final length = pgn.length;

    while (i < length) {
      final char = pgn[i];

      // Metadata tags: [...]
      if (char == '[') {
        final start = i;
        while (i < length && pgn[i] != ']') {
          i++;
        }
        if (i < length) i++; // consume ']'
        tokens.add(PgnToken('METADATA', pgn.substring(start, i)));
        continue;
      }

      // Whitespace
      if (RegExp(r'\s').hasMatch(char)) {
        i++;
        continue;
      }

      // Parenthesis
      if (char == '(') {
        tokens.add(PgnToken('PAREN_OPEN', '('));
        i++;
        continue;
      }
      if (char == ')') {
        tokens.add(PgnToken('PAREN_CLOSE', ')'));
        i++;
        continue;
      }

      // Comment curly braces: {...}
      if (char == '{') {
        final start = i + 1;
        i++;
        while (i < length && pgn[i] != '}') {
          i++;
        }
        final commentText = pgn.substring(start, i);
        if (i < length) i++; // consume '}'
        tokens.add(PgnToken('COMMENT', commentText.trim()));
        continue;
      }

      // Comment rest-of-line: ;...
      if (char == ';') {
        final start = i + 1;
        while (i < length && pgn[i] != '\n') {
          i++;
        }
        tokens.add(PgnToken('COMMENT', pgn.substring(start, i).trim()));
        continue;
      }

      // Word tokens: move numbers or moves
      final start = i;
      while (i < length && !RegExp(r'[\s()[\]{};]').hasMatch(pgn[i])) {
        i++;
      }
      final word = pgn.substring(start, i);
      if (word.isEmpty) continue;

      // Check if it's a move number like 1. or 2...
      if (RegExp(r'^\d+\.*$').hasMatch(word)) {
        tokens.add(PgnToken('NUMBER', word));
      } else {
        tokens.add(PgnToken('MOVE', word));
      }
    }
    return tokens;
  }

  void importPgn(String pgn) {
    final tokens = tokenizePgn(pgn);
    
    var currentNodes = <StudyLabMoveNode>[];
    int? activeNodeIndex;
    
    final stack = <_PgnParserState>[];
    final localChess = chess_lib.Chess(); 
    String lastComment = '';

    for (final token in tokens) {
      if (token.type == 'METADATA') {
        if (token.value.contains('FEN "')) {
          final regExp = RegExp(r'FEN "([^"]+)"');
          final match = regExp.firstMatch(token.value);
          if (match != null) {
            final customFen = match.group(1)!;
            localChess.load(customFen);
          }
        }
        continue;
      }
      
      if (token.type == 'COMMENT') {
        if (activeNodeIndex != null) {
          final node = currentNodes[activeNodeIndex];
          currentNodes[activeNodeIndex] = node.copyWith(
            comment: node.comment.isEmpty ? token.value : '${node.comment}\n${token.value}',
          );
        } else {
          lastComment = token.value;
        }
        continue;
      }
      
      if (token.type == 'PAREN_OPEN') {
        stack.add(_PgnParserState(
          nodeIndex: activeNodeIndex,
          fen: localChess.fen,
        ));
        
        if (activeNodeIndex != null) {
          final parentIdx = currentNodes[activeNodeIndex].parentIndex;
          activeNodeIndex = parentIdx;
          if (parentIdx != null) {
            localChess.load(currentNodes[parentIdx].fen);
          } else {
            localChess.load(chess_lib.Chess.DEFAULT_POSITION);
          }
        }
        continue;
      }
      
      if (token.type == 'PAREN_CLOSE') {
        if (stack.isNotEmpty) {
          final restored = stack.removeLast();
          activeNodeIndex = restored.nodeIndex;
          localChess.load(restored.fen);
        }
        continue;
      }
      
      if (token.type == 'MOVE') {
        final success = localChess.move(token.value);
        if (!success) continue; 
        
        final lastMove = localChess.history.last.move;
        final fromSquare = chess_lib.Chess.algebraic(lastMove.from);
        final toSquare = chess_lib.Chess.algebraic(lastMove.to);
        final promo = lastMove.promotion != null ? lastMove.promotion.toString().split('.').last.toLowerCase()[0] : '';
        final uci = '$fromSquare$toSquare$promo';
        final fen = localChess.fen;
        final newNodeIndex = currentNodes.length;
        
        final newNode = StudyLabMoveNode(
          index: newNodeIndex,
          uci: uci,
          san: token.value,
          fen: fen,
          comment: lastComment,
          parentIndex: activeNodeIndex,
          childIndices: const [],
        );
        
        lastComment = '';
        currentNodes.add(newNode);
        
        if (activeNodeIndex != null) {
          final parentNode = currentNodes[activeNodeIndex];
          currentNodes[activeNodeIndex] = parentNode.copyWith(
            childIndices: [...parentNode.childIndices, newNodeIndex],
          );
        }
        
        activeNodeIndex = newNodeIndex;
      }
    }
    
    state = state.copyWith(
      nodes: currentNodes,
      currentNodeIndex: activeNodeIndex,
      startFen: currentNodes.isEmpty ? chess_lib.Chess.DEFAULT_POSITION : chess_lib.Chess.DEFAULT_POSITION,
    );

    _updateOpeningRecognition();
    _triggerAnalysis();
  }

  String exportToPgn() {
    final buffer = StringBuffer();
    buffer.writeln('[Event "Study Lab Analysis"]');
    buffer.writeln('[Site "Kingslayer"]');
    buffer.writeln('[Date "${DateFormat('yyyy.MM.dd').format(DateTime.now())}"]');
    buffer.writeln('[Result "*"]');
    if (state.startFen != chess_lib.Chess.DEFAULT_POSITION) {
      buffer.writeln('[SetUp "1"]');
      buffer.writeln('[FEN "${state.startFen}"]');
    }
    buffer.writeln();
    
    final rootNodes = state.nodes.where((n) => n.parentIndex == null).toList();
    if (rootNodes.isNotEmpty) {
      _buildPgnRecursive(rootNodes, buffer, true);
    }
    
    return buffer.toString().trim();
  }

  void _buildPgnRecursive(List<StudyLabMoveNode> branchNodes, StringBuffer buffer, bool showMoveNumber) {
    if (branchNodes.isEmpty) return;
    
    final mainLineNode = branchNodes.first;
    
    if (showMoveNumber) {
      final turnNumber = _getMoveNumberFromFen(mainLineNode.fen);
      final isWhite = !mainLineNode.fen.contains(' b ');
      if (isWhite) {
        buffer.write('$turnNumber. ');
      } else {
        buffer.write('${turnNumber - 1}... ');
      }
    }
    
    buffer.write('${mainLineNode.san} ');
    if (mainLineNode.comment.isNotEmpty) {
      buffer.write('{${mainLineNode.comment}} ');
    }
    
    for (int i = 1; i < branchNodes.length; i++) {
      buffer.write('( ');
      final sideLineRoot = branchNodes[i];
      _buildPgnRecursive([sideLineRoot], buffer, true);
      buffer.write(') ');
    }
    
    final nextNodes = mainLineNode.childIndices.map((idx) => state.nodes[idx]).toList();
    if (nextNodes.isNotEmpty) {
      final forceMoveNumber = branchNodes.length > 1;
      _buildPgnRecursive(nextNodes, buffer, forceMoveNumber);
    }
  }

  int _getMoveNumberFromFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 6) {
      return int.tryParse(parts[5]) ?? 1;
    }
    return 1;
  }

  void _updateOpeningRecognition() {
    // A simplified opening recognition for primary lines
    final moves = <String>[];
    var cursor = state.currentNodeIndex;
    while (cursor != null) {
      final n = state.nodes[cursor];
      moves.insert(0, n.san);
      cursor = n.parentIndex;
    }

    final pgnText = moves.join(' ');
    String? name;

    if (pgnText.startsWith('e4 e5 Nf3 Nc6 Bb5')) {
      name = 'Ruy Lopez Opening';
    } else if (pgnText.startsWith('e4 c5')) {
      name = 'Sicilian Defense';
    } else if (pgnText.startsWith('d4 d5 c4')) {
      name = 'Queen\'s Gambit';
    } else if (pgnText.startsWith('e4 e5 Nf3 Nc6 Bc4')) {
      name = 'Italian Game';
    } else if (pgnText.startsWith('e4 e6')) {
      name = 'French Defense';
    } else if (pgnText.startsWith('e4 d6')) {
      name = 'Pirc Defense';
    } else if (pgnText.startsWith('d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3 O-O')) {
      name = 'King\'s Indian Defense';
    } else if (pgnText.startsWith('e4 e5 Nf3 Nf6')) {
      name = 'Petrov\'s Defense';
    } else if (pgnText.startsWith('e4 c6')) {
      name = 'Caro-Kann Defense';
    } else if (pgnText.isNotEmpty) {
      name = 'Custom Analysis Line';
    }

    state = state.copyWith(commentary: name);
  }
}

final studyLabProvider = StateNotifierProvider<StudyLabNotifier, StudyLabState>((ref) {
  final engine = ref.watch(stockfishServiceProvider);
  return StudyLabNotifier(engine);
});
