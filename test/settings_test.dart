import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/data/settings_repository.dart';

void main() {
  test('AppSettings copyWith can set activeRatedMatchId to null', () {
    final s1 = AppSettings(activeRatedMatchId: '12345');
    expect(s1.activeRatedMatchId, '12345');

    final s2 = s1.copyWith(activeRatedMatchId: null);
    expect(s2.activeRatedMatchId, isNull);

    final s3 = s1.copyWith(activeRatedMatchId: '67890');
    expect(s3.activeRatedMatchId, '67890');

    // No argument passed keeps the old value
    final s4 = s1.copyWith();
    expect(s4.activeRatedMatchId, '12345');
  });

  test('AppSettings copyWith works with customFen', () {
    final s1 = AppSettings(customFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
    expect(s1.customFen, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');

    final s2 = s1.copyWith(customFen: null);
    expect(s2.customFen, isNull);

    final s3 = s1.copyWith(customFen: '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    expect(s3.customFen, '4k3/8/8/8/8/8/8/4K3 w - - 0 1');

    final s4 = s1.copyWith();
    expect(s4.customFen, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
  });
}
