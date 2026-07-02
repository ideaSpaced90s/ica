import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/data/arasan_service.dart';

void main() {
  test('ArasanService setChess960Mode returns immediately when process is null', () async {
    final service = ArasanService();
    
    // We haven't called service.init(), so process is null.
    // setChess960Mode should return immediately without hanging.
    final future = service.setChess960Mode(true);
    
    // Expect it to complete within a very short timeout
    await expectLater(
      future.timeout(const Duration(seconds: 1)),
      completes,
    );
  });

  test('ArasanService setSkillLevel returns immediately when process is null', () async {
    final service = ArasanService();
    
    final future = service.setSkillLevel(10);
    
    await expectLater(
      future.timeout(const Duration(seconds: 1)),
      completes,
    );
  });
}
