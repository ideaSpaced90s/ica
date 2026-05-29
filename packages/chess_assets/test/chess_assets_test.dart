import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_assets/chess_assets.dart';

void main() {
  testWidgets('Renders all 20 themes on ChessBoardWidget without breaking', (WidgetTester tester) async {
    for (final theme in ChessThemes.all) {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: ChessBoardWidget(theme: theme),
              ),
            ),
          ),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(ChessBoardWidget), findsOneWidget);
      
      // Verify pieces are rendered
      expect(find.byType(ChessPieceWidget), findsWidgets);
    }
  });

  testWidgets('ChessPieceWidget renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChessPieceWidget(
            type: ChessPieceType.king,
            color: ChessPieceColor.white,
            theme: ChessThemes.classicWood,
            size: 50,
          ),
        ),
      ),
    );

    expect(find.byType(ChessPieceWidget), findsOneWidget);
  });
}
