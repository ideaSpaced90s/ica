import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mobile_navigation_shell.dart';

class PageTransitionOverlay extends ConsumerStatefulWidget {
  const PageTransitionOverlay({super.key});

  @override
  ConsumerState<PageTransitionOverlay> createState() => _PageTransitionOverlayState();
}

class _PageTransitionOverlayState extends ConsumerState<PageTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  int _lastIndex = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _opacity = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(mobileNavIndexProvider);
    if (_lastIndex != -1 && index != _lastIndex) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
    _lastIndex = index;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => _opacity.value > 0
          ? Container(color: Colors.black.withValues(alpha: _opacity.value))
          : const SizedBox.shrink(),
    );
  }
}
