import 'package:flutter_test/flutter_test.dart';
import 'package:chess/chess.dart';

void main() {
  test('test chess properties', () {
    final chess = Chess();
    chess.move({'from': 'e2', 'to': 'e4'});

    final history = chess.history;
    expect(history.length, 1);
  });
}
