// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kingslayer_chess/main.dart';

void main() {
  testWidgets('KingslayerChessApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const KingslayerChessApp());

    // Allow splash screen initialization flow to run and navigate to Dashboard.
    await tester.pump(const Duration(seconds: 5));

    // Verify that the app title or some initial widget is present.
    expect(find.byType(KingslayerChessApp), findsOneWidget);
  });
}
