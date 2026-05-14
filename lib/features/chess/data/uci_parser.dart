class UCIParser {
  static Map<String, dynamic> parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed == 'uciok') {
      return {'type': 'uciok'};
    } else if (trimmed == 'readyok') {
      return {'type': 'readyok'};
    } else if (trimmed.startsWith('info')) {
      return _parseInfoLine(trimmed);
    } else if (trimmed.startsWith('bestmove')) {
      return _parseBestMoveLine(trimmed);
    }
    return {};
  }

  static Map<String, dynamic> _parseInfoLine(String line) {
    final parts = line.split(RegExp(r'\s+'));
    final result = <String, dynamic>{'type': 'info'};

    for (var i = 0; i < parts.length; i++) {
      if (parts[i] == 'score' && i + 2 < parts.length) {
        if (parts[i + 1] == 'cp') {
          result['score'] = int.tryParse(parts[i + 2]) ?? 0;
          result['scoreType'] = 'cp';
        } else if (parts[i + 1] == 'mate') {
          result['score'] = int.tryParse(parts[i + 2]) ?? 0;
          result['scoreType'] = 'mate';
        }
      } else if (parts[i] == 'depth' && i + 1 < parts.length) {
        result['depth'] = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'nodes' && i + 1 < parts.length) {
        result['nodes'] = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'nps' && i + 1 < parts.length) {
        result['nps'] = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'time' && i + 1 < parts.length) {
        result['time'] = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'multipv' && i + 1 < parts.length) {
        result['multipv'] = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'pv' && i + 1 < parts.length) {
        result['pv'] = parts.sublist(i + 1);
        break;
      }
    }
    return result;
  }

  static Map<String, dynamic> _parseBestMoveLine(String line) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return {'type': 'bestmove', 'bestMove': parts[1]};
    }
    return {};
  }
}
