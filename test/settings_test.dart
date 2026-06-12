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
}
