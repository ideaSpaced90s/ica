// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:kingslayer_chess/main.dart';

void main() {
  testWidgets('KingslayerChessApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KingslayerChessApp());

    // Verify that the app title or some initial widget is present.
    // Since it's a chess app with a splash screen, we just check if it pumps correctly.
    expect(find.byType(KingslayerChessApp), findsOneWidget);
  });
}
