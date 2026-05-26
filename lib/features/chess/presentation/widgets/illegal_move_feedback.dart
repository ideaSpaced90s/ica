import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/tutorial_provider.dart';

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

        // 2. Overlay top-of-board notification — elegant coaching feedback
        if (state.illegalMoveMessage != null)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, -12 * (1.0 - val)),
                  child: Opacity(opacity: val.clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.illegalMoveMessage!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => notifier.clearIllegalFeedback(),
                      child: const Icon(Icons.close_rounded, size: 15, color: Color(0xFF64748B)),
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
