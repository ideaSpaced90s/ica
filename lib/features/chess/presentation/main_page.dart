import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/chess_provider.dart';
import 'zen_arena_page.dart';
import 'rated_arena_page.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We select only isRatedMode to avoid unnecessary rebuilds of this shell
    final isRated = ref.watch(chessProvider.select((s) => s.isRatedMode));

    final Widget child;
    if (isRated) {
      child = const RatedArenaPage();
    } else {
      child = const ZenArenaPage();
    }

    return child;
  }
}
