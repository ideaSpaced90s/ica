import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/features/chess/presentation/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
