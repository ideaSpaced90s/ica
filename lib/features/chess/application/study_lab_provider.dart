import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;
import '../data/saved_game.dart';

enum MoveAnnotation {
  brilliant,   // !! ($3)
  good,        // !  ($1)
  interesting, // !? ($5)
  dubious,     // ?! ($6)
  mistake,     // ?  ($2)
  blunder,     // ?? ($4)
  none,
}

extension MoveAnnotationExt on MoveAnnotation {
  String get glyph {
    switch (this) {
      case MoveAnnotation.brilliant: return '!!';
      case MoveAnnotation.good: return '!';
      case MoveAnnotation.interesting: return '!?';
      case MoveAnnotation.dubious: return '?!';
      case MoveAnnotation.mistake: return '?';
      case MoveAnnotation.blunder: return '??';
      case MoveAnnotation.none: return '';
    }
  }

  Color get color {
    switch (this) {
      case MoveAnnotation.brilliant:
        return const Color(0xFF00BCD4);
      case MoveAnnotation.good:
        return const Color(0xFF00C853);
      case MoveAnnotation.interesting:
        return const Color(0xFF9C27B0);
      case MoveAnnotation.dubious:
        return const Color(0xFFFF6F00);
      case MoveAnnotation.mistake:
        return const Color(0xFFE53935);
      case MoveAnnotation.blunder:
        return const Color(0xFFD50000);
      case MoveAnnotation.none:
        return Colors.grey;
    }
  }
}

class BoardArrow {
  final String from;
  final String to;
  final String color; // "green", "red", "blue", "yellow"

  const BoardArrow({
    required this.from,
    required this.to,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'color': color,
  };

  factory BoardArrow.fromJson(Map<String, dynamic> json) => BoardArrow(
    from: json['from'] as String,
    to: json['to'] as String,
    color: json['color'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardArrow &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          color == other.color;

  @override
  int get hashCode => from.hashCode ^ to.hashCode ^ color.hashCode;
}

class BoardHighlight {
  final String square;
  final String color; // "green", "red", "blue", "yellow"

  const BoardHighlight({
    required this.square,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'square': square,
    'color': color,
  };

  factory BoardHighlight.fromJson(Map<String, dynamic> json) => BoardHighlight(
    square: json['square'] as String,
    color: json['color'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardHighlight &&
          runtimeType == other.runtimeType &&
          square == other.square &&
          color == other.color;

  @override
  int get hashCode => square.hashCode ^ color.hashCode;
}

class GameMetadata {
  final String event;
  final String site;
  final String date;
  final String white;
  final String black;
  final int? whiteElo;
  final int? blackElo;
  final String result;
  final String eco;
  final String opening;

  const GameMetadata({
    this.event = 'Study Lab Analysis',
    this.site = 'IdeaSpace Chess Academy',
    this.date = '',
    this.white = 'White Player',
    this.black = 'Black Player',
    this.whiteElo,
    this.blackElo,
    this.result = '*',
    this.eco = '',
    this.opening = '',
  });

  GameMetadata copyWith({
    String? event,
    String? site,
    String? date,
    String? white,
    String? black,
    int? whiteElo,
    int? blackElo,
    String? result,
    String? eco,
    String? opening,
  }) {
    return GameMetadata(
      event: event ?? this.event,
      site: site ?? this.site,
      date: date ?? this.date,
      white: white ?? this.white,
      black: black ?? this.black,
      whiteElo: whiteElo ?? this.whiteElo,
      blackElo: blackElo ?? this.blackElo,
      result: result ?? this.result,
      eco: eco ?? this.eco,
      opening: opening ?? this.opening,
    );
  }
}

class StudyLabMoveNode {
  final int index;
  final String uci;
  final String san;
  final String fen;
  final String comment;
  final int? parentIndex;
  final List<int> childIndices;
  final MoveAnnotation annotation;
  final List<BoardArrow> arrows;
  final List<BoardHighlight> highlights;

  const StudyLabMoveNode({
    required this.index,
    required this.uci,
    required this.san,
    required this.fen,
    this.comment = '',
    this.parentIndex,
    this.childIndices = const [],
    this.annotation = MoveAnnotation.none,
    this.arrows = const [],
    this.highlights = const [],
  });

  StudyLabMoveNode copyWith({
    int? index,
    String? uci,
    String? san,
    String? fen,
    String? comment,
    int? parentIndex,
    List<int>? childIndices,
    MoveAnnotation? annotation,
    List<BoardArrow>? arrows,
    List<BoardHighlight>? highlights,
  }) {
    return StudyLabMoveNode(
      index: index ?? this.index,
      uci: uci ?? this.uci,
      san: san ?? this.san,
      fen: fen ?? this.fen,
      comment: comment ?? this.comment,
      parentIndex: parentIndex ?? this.parentIndex,
      childIndices: childIndices ?? this.childIndices,
      annotation: annotation ?? this.annotation,
      arrows: arrows ?? this.arrows,
      highlights: highlights ?? this.highlights,
    );
  }
}

class _PgnParserState {
  final int? nodeIndex;
  final String fen;
  _PgnParserState({required this.nodeIndex, required this.fen});
}

class PgnToken {
  final String type; // 'MOVE', 'COMMENT', 'PAREN_OPEN', 'PAREN_CLOSE', 'METADATA', 'NUMBER', 'NAG'
  final String value;
  PgnToken(this.type, this.value);
}

class StudyLabState {
  final List<StudyLabMoveNode> nodes;
  final int? currentNodeIndex;
  final String startFen;
  final bool isBoardFlipped;
  final String? commentary;
  final GameMetadata metadata;
  final bool isGuessingMode;
  final List<int> guessedNodes; // Mainline node indices guessed successfully

  final bool isDirty; // Tracks unsaved changes in the study
  final int? libraryIndex; // Tracks index of the study in sqlite library if saved/loaded

  StudyLabState({
    this.nodes = const [],
    this.currentNodeIndex,
    this.startFen = chess_lib.Chess.DEFAULT_POSITION,
    this.isBoardFlipped = false,
    this.commentary,
    this.metadata = const GameMetadata(),
    this.isGuessingMode = false,
    this.guessedNodes = const [],
    this.isDirty = false,
    this.libraryIndex,
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
    bool? isBoardFlipped,
    Object? commentary = const Object(),
    GameMetadata? metadata,
    bool? isGuessingMode,
    List<int>? guessedNodes,
    bool? isDirty,
    Object? libraryIndex = const Object(),
  }) {
    return StudyLabState(
      nodes: nodes ?? this.nodes,
      currentNodeIndex: currentNodeIndex == const Object()
          ? this.currentNodeIndex
          : currentNodeIndex as int?,
      startFen: startFen ?? this.startFen,
      isBoardFlipped: isBoardFlipped ?? this.isBoardFlipped,
      commentary: commentary == const Object()
          ? this.commentary
          : commentary as String?,
      metadata: metadata ?? this.metadata,
      isGuessingMode: isGuessingMode ?? this.isGuessingMode,
      guessedNodes: guessedNodes ?? this.guessedNodes,
      isDirty: isDirty ?? this.isDirty,
      libraryIndex: libraryIndex == const Object()
          ? this.libraryIndex
          : libraryIndex as int?,
    );
  }
}

class StudyLabNotifier extends Notifier<StudyLabState> {
  @override
  StudyLabState build() {
    return StudyLabState();
  }

  Future<String> _getDbPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final oldPath = '${directory.path}/kingslayer_studies.db';
    final newPath = '${directory.path}/ideaspace_studies.db';
    
    // Auto-migration logic:
    try {
      final oldFile = File(oldPath);
      final newFile = File(newPath);
      if (await oldFile.exists() && !await newFile.exists()) {
        await oldFile.rename(newPath);
        debugPrint('IdeaSpace: Migrated studies database to $newPath');
      }
    } catch (e) {
      debugPrint('IdeaSpace: Error migrating studies database: $e');
    }
    
    return newPath;
  }

  void selectNode(int? index) {
    state = state.copyWith(currentNodeIndex: index);
    _updateOpeningRecognition();
  }

  void makeMove(String from, String to, [String promotion = '']) {
    final uci = '$from$to$promotion';

    // Guess the Move validation
    if (state.isGuessingMode) {
      int? targetIndex;
      if (state.currentNodeIndex == null) {
        final roots = state.nodes.where((n) => n.parentIndex == null).toList();
        if (roots.isNotEmpty) {
          targetIndex = roots.first.index;
        }
      } else {
        final children = state.nodes[state.currentNodeIndex!].childIndices;
        if (children.isNotEmpty) {
          targetIndex = children.first;
        }
      }

      if (targetIndex != null && state.nodes[targetIndex].uci == uci) {
        final newGuessed = List<int>.from(state.guessedNodes)..add(targetIndex);
        state = state.copyWith(guessedNodes: newGuessed);
        selectNode(targetIndex);
      }
      return;
    }

    final localChess = chess_lib.Chess.fromFEN(state.activeFen);
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
    final success = localChess.move({
      'from': from,
      'to': to,
      if (promotion.isNotEmpty) 'promotion': promotion,
    });
    if (!success) return;

    final newFen = localChess.fen;

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

    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    final newNodeIdx = newNodes.length;
    final newNode = StudyLabMoveNode(
      index: newNodeIdx,
      uci: uci,
      san: san,
      fen: newFen,
      parentIndex: state.currentNodeIndex,
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
      isDirty: true,
    );

    _updateOpeningRecognition();
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
    state = state.copyWith(nodes: newNodes, isDirty: true);
  }

  void updateCommentAt(int nodeIndex, String comment) {
    if (nodeIndex < 0 || nodeIndex >= state.nodes.length) return;
    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    newNodes[nodeIndex] = newNodes[nodeIndex].copyWith(comment: comment);
    state = state.copyWith(nodes: newNodes, isDirty: true);
  }

  void deleteCurrentNode() {
    if (state.currentNodeIndex == null) return;
    final targetIdx = state.currentNodeIndex!;
    final parentIdx = state.nodes[targetIdx].parentIndex;

    final desc = _getDescendants(targetIdx);
    final toDelete = {targetIdx, ...desc};

    final newNodes = <StudyLabMoveNode>[];
    final indexMapping = <int, int>{};

    for (var i = 0; i < state.nodes.length; i++) {
      if (toDelete.contains(i)) continue;
      indexMapping[i] = newNodes.length;
      newNodes.add(state.nodes[i]);
    }

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
      isDirty: true,
    );

    _updateOpeningRecognition();
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
      isBoardFlipped: state.isBoardFlipped,
      isDirty: false,
      libraryIndex: null,
    );
  }

  void loadPositionSetup(String fen) {
    state = StudyLabState(
      nodes: const [],
      currentNodeIndex: null,
      startFen: fen,
      isBoardFlipped: state.isBoardFlipped,
      isDirty: true,
      libraryIndex: null,
    );
  }

  void clearDirty() {
    state = state.copyWith(isDirty: false);
  }

  void markDirty() {
    state = state.copyWith(isDirty: true);
  }

  void setAnnotation(int nodeIndex, MoveAnnotation a) {
    if (nodeIndex >= state.nodes.length) return;
    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    newNodes[nodeIndex] = newNodes[nodeIndex].copyWith(annotation: a);
    state = state.copyWith(nodes: newNodes, isDirty: true);
  }

  void addArrow(int nodeIndex, BoardArrow a) {
    if (nodeIndex >= state.nodes.length) return;
    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    final currentArrows = List<BoardArrow>.from(newNodes[nodeIndex].arrows);
    if (currentArrows.contains(a)) {
      currentArrows.remove(a);
    } else {
      currentArrows.add(a);
    }
    newNodes[nodeIndex] = newNodes[nodeIndex].copyWith(arrows: currentArrows);
    state = state.copyWith(nodes: newNodes, isDirty: true);
  }

  void addHighlight(int nodeIndex, BoardHighlight h) {
    if (nodeIndex >= state.nodes.length) return;
    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    final currentHighlights = List<BoardHighlight>.from(newNodes[nodeIndex].highlights);
    if (currentHighlights.contains(h)) {
      currentHighlights.remove(h);
    } else {
      currentHighlights.add(h);
    }
    newNodes[nodeIndex] = newNodes[nodeIndex].copyWith(highlights: currentHighlights);
    state = state.copyWith(nodes: newNodes, isDirty: true);
  }

  void clearMarkup(int nodeIndex) {
    if (nodeIndex >= state.nodes.length) return;
    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    newNodes[nodeIndex] = newNodes[nodeIndex].copyWith(arrows: const [], highlights: const []);
    state = state.copyWith(nodes: newNodes, isDirty: true);
  }

  void promoteVariation(int nodeIndex) {
    if (nodeIndex >= state.nodes.length) return;
    final node = state.nodes[nodeIndex];
    final parentIdx = node.parentIndex;
    if (parentIdx == null) return;

    final parent = state.nodes[parentIdx];
    final childIndices = List<int>.from(parent.childIndices);
    final currentPos = childIndices.indexOf(nodeIndex);
    if (currentPos <= 0) return;

    childIndices.removeAt(currentPos);
    childIndices.insert(0, nodeIndex);

    final newNodes = List<StudyLabMoveNode>.from(state.nodes);
    newNodes[parentIdx] = parent.copyWith(childIndices: childIndices);
    state = state.copyWith(nodes: newNodes, isDirty: true);
  }

  void setMetadata(GameMetadata m) {
    state = state.copyWith(metadata: m);
  }

  void toggleGuessingMode(bool enabled) {
    state = state.copyWith(
      isGuessingMode: enabled,
      guessedNodes: const [],
      currentNodeIndex: null, // Start at the beginning of the tree
    );
  }

  // Parses ChessBase-style [%cal ...] and [%cly ...] graphic commands from comments
  Map<String, dynamic> parseCommentGraphics(String rawComment) {
    var text = rawComment;
    final arrows = <BoardArrow>[];
    final highlights = <BoardHighlight>[];

    final graphicsRegex = RegExp(r'\[%cal\s+([^\]]+)\]');
    final circleRegex = RegExp(r'\[%cly\s+([^\]]+)\]');

    text = text.replaceAllMapped(graphicsRegex, (match) {
      final listStr = match.group(1)!;
      final items = listStr.split(',');
      for (final item in items) {
        if (item.length == 5) {
          final colorChar = item[0].toUpperCase();
          final from = item.substring(1, 3);
          final to = item.substring(3, 5);
          final color = _colorNameFromChar(colorChar);
          arrows.add(BoardArrow(from: from, to: to, color: color));
        }
      }
      return '';
    });

    text = text.replaceAllMapped(circleRegex, (match) {
      final listStr = match.group(1)!;
      final items = listStr.split(',');
      for (final item in items) {
        if (item.length == 3) {
          final colorChar = item[0].toUpperCase();
          final square = item.substring(1, 3);
          final color = _colorNameFromChar(colorChar);
          highlights.add(BoardHighlight(square: square, color: color));
        }
      }
      return '';
    });

    return {
      'comment': text.trim(),
      'arrows': arrows,
      'highlights': highlights,
    };
  }

  String _colorNameFromChar(String c) {
    switch (c) {
      case 'R': return 'red';
      case 'B': return 'blue';
      case 'Y': return 'yellow';
      case 'G':
      default:
        return 'green';
    }
  }

  List<PgnToken> tokenizePgn(String pgn) {
    final tokens = <PgnToken>[];
    int i = 0;
    final length = pgn.length;

    while (i < length) {
      final char = pgn[i];

      if (char == '[') {
        final start = i;
        while (i < length && pgn[i] != ']') {
          i++;
        }
        if (i < length) i++;
        tokens.add(PgnToken('METADATA', pgn.substring(start, i)));
        continue;
      }

      if (RegExp(r'\s').hasMatch(char)) {
        i++;
        continue;
      }

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

      if (char == '{') {
        final start = i + 1;
        i++;
        while (i < length && pgn[i] != '}') {
          i++;
        }
        final commentText = pgn.substring(start, i);
        if (i < length) i++;
        tokens.add(PgnToken('COMMENT', commentText.trim()));
        continue;
      }

      if (char == ';') {
        final start = i + 1;
        while (i < length && pgn[i] != '\n') {
          i++;
        }
        tokens.add(PgnToken('COMMENT', pgn.substring(start, i).trim()));
        continue;
      }

      final start = i;
      while (i < length && !RegExp(r'[\s()[\]{};]').hasMatch(pgn[i])) {
        i++;
      }
      final word = pgn.substring(start, i);
      if (word.isEmpty) continue;

      if (word.startsWith('\$')) {
        tokens.add(PgnToken('NAG', word));
      } else if (RegExp(r'^\d+\.*$').hasMatch(word)) {
        tokens.add(PgnToken('NUMBER', word));
      } else {
        tokens.add(PgnToken('MOVE', word));
      }
    }
    return tokens;
  }

  void loadGameEntry(
    SavedGameEntry entry, {
    List<CommentaryEntry>? chanakyaCommentary,
  }) {
    final startPosition = entry.initialFen ?? chess_lib.Chess.DEFAULT_POSITION;
    final localChess = chess_lib.Chess.fromFEN(startPosition);
    final List<StudyLabMoveNode> currentNodes = [];
    int? activeNodeIndex;

    for (final moveSan in entry.recentMoves) {
      final success = localChess.move(moveSan);
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
        san: moveSan,
        fen: fen,
        parentIndex: activeNodeIndex,
      );

      currentNodes.add(newNode);

      if (activeNodeIndex != null) {
        final parentNode = currentNodes[activeNodeIndex];
        currentNodes[activeNodeIndex] = parentNode.copyWith(
          childIndices: [...parentNode.childIndices, newNodeIndex],
        );
      }

      activeNodeIndex = newNodeIndex;
    }

    if (chanakyaCommentary != null) {
      for (var i = 0; i < currentNodes.length; i++) {
        final nodeFen = _normalizeFenForComparison(currentNodes[i].fen);
        final matchingEntries = chanakyaCommentary
            .where((e) => !e.isUser && e.associatedFen != null && _normalizeFenForComparison(e.associatedFen!) == nodeFen)
            .toList();
        if (matchingEntries.isNotEmpty) {
          final combinedText = matchingEntries.map((e) => e.text).join(' ').toLowerCase();
          final ann = _detectAnnotation(combinedText);
          if (ann != MoveAnnotation.none) {
            currentNodes[i] = currentNodes[i].copyWith(annotation: ann);
          }
        }
      }
    }

    state = StudyLabState(
      nodes: currentNodes,
      currentNodeIndex: activeNodeIndex,
      startFen: startPosition,
      isBoardFlipped: entry.isBoardFlipped,
      isDirty: false,
    );

    _updateOpeningRecognition();
  }

  String _normalizeFenForComparison(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length >= 4) {
      return parts.sublist(0, 4).join(' ');
    }
    return fen;
  }

  MoveAnnotation _detectAnnotation(String lowerText) {
    if (lowerText.contains('blunder') || lowerText.contains('terrible') || lowerText.contains('catastrophic')) {
      return MoveAnnotation.blunder;
    }
    if (lowerText.contains('brilliant') || lowerText.contains('stunning') || lowerText.contains('masterful') || lowerText.contains('exceptional')) {
      return MoveAnnotation.brilliant;
    }
    if (lowerText.contains('mistake') || lowerText.contains('inaccuracy') || lowerText.contains('error') || lowerText.contains('loses')) {
      return MoveAnnotation.mistake;
    }
    if (lowerText.contains('excellent') || lowerText.contains('strong') || lowerText.contains('best') || lowerText.contains('precise') || lowerText.contains('correct')) {
      return MoveAnnotation.good;
    }
    if (lowerText.contains('dubious') || lowerText.contains('questionable') || lowerText.contains('risky') || lowerText.contains('suspect')) {
      return MoveAnnotation.dubious;
    }
    if (lowerText.contains('interesting') || lowerText.contains('creative') || lowerText.contains('provocative') || lowerText.contains('gambit')) {
      return MoveAnnotation.interesting;
    }
    return MoveAnnotation.none;
  }

  // Load a single game record (usually selected from a multi-game PGN picker)
  void loadPgnRecord(rust_pgn.PgnGameRecord record, [int? libraryIndex]) {
    final meta = GameMetadata(
      event: record.header.event,
      site: record.header.site,
      date: record.header.date,
      white: record.header.white,
      black: record.header.black,
      whiteElo: record.header.whiteElo,
      blackElo: record.header.blackElo,
      result: record.header.result,
      eco: record.header.eco,
      opening: record.header.opening,
    );

    _importMovesOnlyPgn(record.movesPgn);

    state = state.copyWith(
      metadata: meta,
      commentary: record.header.opening.isNotEmpty 
          ? '${record.header.eco}: ${record.header.opening}' 
          : null,
      isDirty: false,
      libraryIndex: libraryIndex,
    );
  }

  void _importMovesOnlyPgn(String movesPgn) {
    final tokens = tokenizePgn(movesPgn);
    var currentNodes = <StudyLabMoveNode>[];
    int? activeNodeIndex;
    final stack = <_PgnParserState>[];
    final localChess = chess_lib.Chess();
    String lastComment = '';
    var commentArrows = <BoardArrow>[];
    var commentHighlights = <BoardHighlight>[];

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
        final parsed = parseCommentGraphics(token.value);
        final cleanText = parsed['comment'] as String;
        final listArrows = parsed['arrows'] as List<BoardArrow>;
        final listHighlights = parsed['highlights'] as List<BoardHighlight>;

        if (activeNodeIndex != null) {
          final node = currentNodes[activeNodeIndex];
          currentNodes[activeNodeIndex] = node.copyWith(
            comment: node.comment.isEmpty ? cleanText : '${node.comment}\n$cleanText',
            arrows: [...node.arrows, ...listArrows],
            highlights: [...node.highlights, ...listHighlights],
          );
        } else {
          lastComment = cleanText;
          commentArrows = listArrows;
          commentHighlights = listHighlights;
        }
        continue;
      }

      if (token.type == 'NAG') {
        if (activeNodeIndex != null) {
          final node = currentNodes[activeNodeIndex];
          final annotation = _annotationFromNag(token.value);
          currentNodes[activeNodeIndex] = node.copyWith(annotation: annotation);
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
          arrows: commentArrows,
          highlights: commentHighlights,
          parentIndex: activeNodeIndex,
        );

        lastComment = '';
        commentArrows = const [];
        commentHighlights = const [];
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
      startFen: chess_lib.Chess.DEFAULT_POSITION,
      isDirty: false,
    );

    _updateOpeningRecognition();
  }

  MoveAnnotation _annotationFromNag(String nagStr) {
    final val = int.tryParse(nagStr.replaceFirst('\$', ''));
    switch (val) {
      case 1: return MoveAnnotation.good;
      case 2: return MoveAnnotation.mistake;
      case 3: return MoveAnnotation.brilliant;
      case 4: return MoveAnnotation.blunder;
      case 5: return MoveAnnotation.interesting;
      case 6: return MoveAnnotation.dubious;
      default:
        return MoveAnnotation.none;
    }
  }

  void importPgn(String pgn) {
    // Attempt multi-game parse using Rust
    try {
      final records = rust_pgn.parsePgnDatabase(pgnText: pgn);
      if (records.isNotEmpty) {
        // Load the first game by default
        loadPgnRecord(records.first);
      }
    } catch (e) {
      debugPrint('Error parsing PGN database: $e. Falling back to simple Dart parser.');
      _importMovesOnlyPgn(pgn);
    }
  }

  // Exports just the moves section with standard PGN comments and NAGs
  String exportToPgn() {
    final buffer = StringBuffer();
    final rootNodes = state.nodes.where((n) => n.parentIndex == null).toList();
    if (rootNodes.isNotEmpty) {
      _buildPgnRecursive(rootNodes, buffer, true);
    }
    return buffer.toString().trim();
  }

  // Exports the complete annotated PGN with custom headers
  String exportFullPgn() {
    final movesOnly = exportToPgn();
    final header = rust_pgn.PgnGameHeader(
      event: state.metadata.event,
      site: state.metadata.site,
      date: state.metadata.date.isNotEmpty 
          ? state.metadata.date 
          : DateFormat('yyyy.MM.dd').format(DateTime.now()),
      white: state.metadata.white,
      black: state.metadata.black,
      whiteElo: state.metadata.whiteElo,
      blackElo: state.metadata.blackElo,
      result: state.metadata.result,
      eco: state.metadata.eco,
      opening: state.metadata.opening,
    );
    return rust_pgn.exportPgnWithHeaders(header: header, annotatedPgn: movesOnly);
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

    buffer.write(mainLineNode.san);

    // Append NAG annotations
    if (mainLineNode.annotation != MoveAnnotation.none) {
      final nagMap = {
        MoveAnnotation.good: '\$1',
        MoveAnnotation.mistake: '\$2',
        MoveAnnotation.brilliant: '\$3',
        MoveAnnotation.blunder: '\$4',
        MoveAnnotation.interesting: '\$5',
        MoveAnnotation.dubious: '\$6',
      };
      buffer.write(' ${nagMap[mainLineNode.annotation]}');
    }

    buffer.write(' ');

    // Compile comments and ChessBase graphics
    var commentText = mainLineNode.comment;
    final graphicComments = <String>[];
    if (mainLineNode.arrows.isNotEmpty) {
      final arrowStr = mainLineNode.arrows.map((a) {
        final cChar = a.color[0].toUpperCase();
        return '$cChar${a.from}${a.to}';
      }).join(',');
      graphicComments.add('%cal $arrowStr');
    }
    if (mainLineNode.highlights.isNotEmpty) {
      final highlightStr = mainLineNode.highlights.map((h) {
        final cChar = h.color[0].toUpperCase();
        return '$cChar${h.square}';
      }).join(',');
      graphicComments.add('%cly $highlightStr');
    }

    if (graphicComments.isNotEmpty) {
      final graphics = '[${graphicComments.join(',')}]';
      if (commentText.isNotEmpty) {
        commentText = '$commentText $graphics';
      } else {
        commentText = graphics;
      }
    }

    if (commentText.isNotEmpty) {
      buffer.write('{$commentText} ');
    }

    // Recursive sidelines
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
    final moves = <String>[];
    var cursor = state.currentNodeIndex;
    while (cursor != null) {
      final n = state.nodes[cursor];
      moves.insert(0, n.san);
      cursor = n.parentIndex;
    }

    if (moves.isEmpty) {
      state = state.copyWith(commentary: null);
      return;
    }

    try {
      final openingResult = rust_pgn.classifyOpeningEco(movesSan: moves);
      state = state.copyWith(
        commentary: openingResult.$2.isNotEmpty
            ? '${openingResult.$1}: ${openingResult.$2}'
            : 'Custom Analysis Line',
        metadata: state.metadata.copyWith(
          eco: openingResult.$1,
          opening: openingResult.$2,
        ),
      );
    } catch (e) {
      debugPrint('Error classifying opening: $e');
    }
  }

  // Persistence - SQLite calls
  Future<bool> saveCurrentGameToLibrary(String gameName) async {
    final dbPath = await _getDbPath();
    final movesOnly = exportToPgn();

    final header = rust_pgn.PgnGameHeader(
      event: gameName,
      site: state.metadata.site,
      date: state.metadata.date.isNotEmpty 
          ? state.metadata.date 
          : DateFormat('yyyy.MM.dd').format(DateTime.now()),
      white: state.metadata.white,
      black: state.metadata.black,
      whiteElo: state.metadata.whiteElo,
      blackElo: state.metadata.blackElo,
      result: state.metadata.result,
      eco: state.metadata.eco,
      opening: state.metadata.opening,
    );

    final record = rust_pgn.PgnGameRecord(
      header: header,
      movesPgn: movesOnly,
      index: BigInt.from(0),
    );

    final success = rust_pgn.saveStudyToDb(dbPath: dbPath, game: record);
    if (success) {
      final games = await loadGamesFromLibrary();
      final newIndex = games.length - 1;
      state = state.copyWith(
        isDirty: false,
        metadata: state.metadata.copyWith(event: gameName),
        libraryIndex: newIndex,
      );
    }
    return success;
  }

  Future<bool> saveExistingStudyInLibrary(int libraryIndex) async {
    final dbPath = await _getDbPath();
    final games = await loadGamesFromLibrary();
    if (libraryIndex < 0 || libraryIndex >= games.length) return false;

    // Clear all studies
    await clearLibrary();

    final movesOnly = exportToPgn();
    var success = true;
    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      final record = i == libraryIndex
          ? rust_pgn.PgnGameRecord(
              header: game.header,
              movesPgn: movesOnly,
              index: game.index,
            )
          : game;

      final saveOk = rust_pgn.saveStudyToDb(dbPath: dbPath, game: record);
      if (!saveOk) {
        success = false;
      }
    }

    if (success) {
      state = state.copyWith(isDirty: false);
    }
    return success;
  }

  Future<List<rust_pgn.PgnGameRecord>> loadGamesFromLibrary() async {
    final dbPath = await _getDbPath();
    return rust_pgn.loadStudiesFromDb(dbPath: dbPath);
  }

  Future<bool> clearLibrary() async {
    final dbPath = await _getDbPath();
    return rust_pgn.clearAllStudies(dbPath: dbPath);
  }

  Future<bool> updateStudyHeadersInLibrary(int indexToEdit, rust_pgn.PgnGameHeader updatedHeader) async {
    final dbPath = await _getDbPath();
    final games = await loadGamesFromLibrary();
    
    if (indexToEdit < 0 || indexToEdit >= games.length) return false;

    // Clear all studies
    await clearLibrary();

    var success = true;
    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      final header = i == indexToEdit ? updatedHeader : game.header;

      final updatedRecord = rust_pgn.PgnGameRecord(
        header: header,
        movesPgn: game.movesPgn,
        index: game.index,
      );

      final saveOk = rust_pgn.saveStudyToDb(dbPath: dbPath, game: updatedRecord);
      if (!saveOk) {
        success = false;
      }
    }
    return success;
  }

  Future<bool> deleteStudyFromLibrary(int indexToDelete) async {
    final dbPath = await _getDbPath();
    final games = await loadGamesFromLibrary();
    
    if (indexToDelete < 0 || indexToDelete >= games.length) return false;

    // Clear all studies
    await clearLibrary();

    var success = true;
    for (var i = 0; i < games.length; i++) {
      if (i == indexToDelete) continue;
      
      final game = games[i];
      final record = rust_pgn.PgnGameRecord(
        header: game.header,
        movesPgn: game.movesPgn,
        index: game.index,
      );

      final saveOk = rust_pgn.saveStudyToDb(dbPath: dbPath, game: record);
      if (!saveOk) {
        success = false;
      }
    }

    if (success) {
      if (state.libraryIndex == indexToDelete) {
        state = state.copyWith(libraryIndex: null);
      } else if (state.libraryIndex != null && state.libraryIndex! > indexToDelete) {
        state = state.copyWith(libraryIndex: state.libraryIndex! - 1);
      }
    }

    return success;
  }
}

final studyLabProvider = NotifierProvider<StudyLabNotifier, StudyLabState>(StudyLabNotifier.new);
