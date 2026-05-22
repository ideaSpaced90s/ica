// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Print PathProvider paths', () async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      print('=== DOCUMENTS DIRECTORY: ${docDir.path} ===');
    } catch (e) {
      print('=== DOCUMENTS DIRECTORY ERROR: $e ===');
    }

    try {
      final appSupportDir = await getApplicationSupportDirectory();
      print('=== APP SUPPORT DIRECTORY: ${appSupportDir.path} ===');
    } catch (e) {
      print('=== APP SUPPORT DIRECTORY ERROR: $e ===');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      print('=== TEMP DIRECTORY: ${tempDir.path} ===');
    } catch (e) {
      print('=== TEMP DIRECTORY ERROR: $e ===');
    }
  });
}
