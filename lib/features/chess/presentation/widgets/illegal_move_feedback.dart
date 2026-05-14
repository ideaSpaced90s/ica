import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/tutorial_provider.dart';
import '../scholarly_theme.dart';

class TutorialIllegalMoveFeedback extends ConsumerStatefulWidget {
  const TutorialIllegalMoveFeedback({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TutorialIllegalMoveFeedback> createState() => _TutorialIllegalMoveFeedbackState();
}

class _TutorialIllegalMoveFeedbackState extends ConsumerState<TutorialIllegalMoveFeedback> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _offsetAnimation;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Mechanical multi-phase lateral deflection curve
    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);
    final notifier = ref.read(tutorialProvider.notifier);

    // Trigger lateral mechanical deflection when a fresh invalid message hits state loop
    if (state.illegalMoveMessage != null && state.illegalMoveMessage != _lastMessage) {
      _lastMessage = state.illegalMoveMessage;
      _shakeController.forward(from: 0.0);
    } else if (state.illegalMoveMessage == null) {
      _lastMessage = null;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Shaking host wrapper encapsulating interactive board surface
        AnimatedBuilder(
          animation: _offsetAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_offsetAnimation.value, 0),
              child: child,
            );
          },
          child: widget.child,
        ),

        // 2. Overlay bottom prompt popover detailing strict rule corrections
        if (state.illegalMoveMessage != null)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: Opacity(opacity: val.clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.backgroundStart.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RULE CORRECTION',
                            style: GoogleFonts.inter(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.illegalMoveMessage!,
                            style: GoogleFonts.inter(
                              color: ScholarlyTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => notifier.clearIllegalFeedback(),
                      icon: const Icon(Icons.close_rounded, size: 18, color: ScholarlyTheme.textSubtle),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
