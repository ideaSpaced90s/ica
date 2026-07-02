import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidPlayIntegrityProvider(),
      providerApple: AppleAppAttestProvider(),
    );
    await GoogleSignIn.instance.initialize();
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

    runApp(const IdeaSpaceChessApp());
  }, (error, stack) {
    debugPrint('UNHANDLED ASYNC ERROR: $error\n$stack');
  });
}

class IdeaSpaceChessApp extends StatelessWidget {
  const IdeaSpaceChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        tutorialProgressRepositoryProvider.overrideWithValue(
          TutorialProgressRepository(sharedPrefs),
        ),
      ],
      child: const _IdeaSpaceAppView(),
    );
  }
}

class _IdeaSpaceAppView extends StatelessWidget {
  const _IdeaSpaceAppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess',
      debugShowCheckedModeBanner: false,
      theme: ScholarlyTheme.themeData,
      home: const SplashScreen(),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            if (height > 0 && width / height > 0.72) {
              final targetWidth = height * 0.5625;
              final mediaQuery = MediaQuery.of(context);
              final adjustedPadding = mediaQuery.padding.copyWith(
                left: 0,
                right: 0,
              );
              final adjustedViewPadding = mediaQuery.viewPadding.copyWith(
                left: 0,
                right: 0,
              );

              return Container(
                color: Colors.black,
                child: Center(
                  child: SizedBox(
                    width: targetWidth,
                    child: MediaQuery(
                      data: mediaQuery.copyWith(
                        size: Size(targetWidth, height),
                        padding: adjustedPadding,
                        viewPadding: adjustedViewPadding,
                      ),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
