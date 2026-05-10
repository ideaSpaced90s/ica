import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/chess/presentation/scholarly_theme.dart';
import 'features/chess/presentation/splash_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('SARVAM AI ENVIORNMENT LOADED');
    } catch (e) {
      debugPrint('DOTENV LOAD ERROR: $e');
    }

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('GLOBAL FLUTTER ERROR: ${details.exception}\n${details.stack}');
    };

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    runApp(const KingslayerChessApp());
  }, (error, stack) {
    debugPrint('UNHANDLED ASYNC ERROR: $error\n$stack');
  });
}

class KingslayerChessApp extends StatelessWidget {
  const KingslayerChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _KingslayerAppView());
  }
}

class _KingslayerAppView extends StatelessWidget {
  const _KingslayerAppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KINGSLAYER: CHESS',
      debugShowCheckedModeBanner: false,
      theme: ScholarlyTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
