import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chess/presentation/scholarly_theme.dart';
import 'features/chess/presentation/splash_screen.dart';
import 'src/rust/frb_generated.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/chess/application/tutorial_provider.dart';
import 'features/chess/data/tutorial_progress_repository.dart';

late SharedPreferences sharedPrefs;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    sharedPrefs = await SharedPreferences.getInstance();
    try {
      await RustLib.init();
    } catch (e) {
      debugPrint('RUST LIB INIT ERROR: $e');
    }


    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('GLOBAL FLUTTER ERROR: ${details.exception}\n${details.stack}');
    };

    if (Platform.isAndroid || Platform.isIOS) {
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
    }

    runApp(const KingslayerChessApp());
  }, (error, stack) {
    debugPrint('UNHANDLED ASYNC ERROR: $error\n$stack');
  });
}

class KingslayerChessApp extends StatelessWidget {
  const KingslayerChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        tutorialProgressRepositoryProvider.overrideWithValue(
          TutorialProgressRepository(sharedPrefs),
        ),
      ],
      child: const _KingslayerAppView(),
    );
  }
}

class _KingslayerAppView extends StatelessWidget {
  const _KingslayerAppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IdeaSpace Chess Academy',
      debugShowCheckedModeBanner: false,
      theme: ScholarlyTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
