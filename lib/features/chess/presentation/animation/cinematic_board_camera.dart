import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../application/chess_provider.dart';

class CinematicBoardCamera extends StatefulWidget {
  final Widget child;
  final CameraMotionCue? cue;
  final bool isEnabled;
  final bool isFlipped;

  const CinematicBoardCamera({
    super.key,
    required this.child,
    required this.cue,
    required this.isEnabled,
    required this.isFlipped,
  });

  @override
  State<CinematicBoardCamera> createState() => _CinematicBoardCameraState();
}

class _CinematicBoardCameraState extends State<CinematicBoardCamera>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _motion;
  late final Animation<double> _mateFade;
  CameraMotionCue? _activeCue;

  @override
  void initState() {
    super.initState();
    _activeCue = widget.cue;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _motion = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
    ]).animate(_controller);
    _mateFade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 36),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 44,
      ),
    ]).animate(_controller);

    if (widget.isEnabled && _activeCue != null) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant CinematicBoardCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEnabled) {
      _controller.stop();
      _controller.value = 0.0;
      _activeCue = null;
      return;
    }

    if (widget.cue != null && widget.cue?.id != oldWidget.cue?.id) {
      _activeCue = widget.cue;
      _controller.duration = widget.cue!.isCheckmate
          ? const Duration(milliseconds: 1180)
          : const Duration(milliseconds: 760);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled || _activeCue == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final cue = _activeCue!;
        final direction = _moveDirection(cue.from, cue.to, widget.isFlipped);
        final drift = _driftPixels(cue) * _motion.value;
        final zoom = 1.0 + (_zoomAmount(cue) * _motion.value);
        final shifted = Transform.translate(
          offset: direction * drift,
          child: Transform.scale(
            scale: zoom,
            alignment: Alignment.center,
            child: child,
          ),
        );

        if (!cue.isCheckmate) {
          return shifted;
        }

        return ColorFiltered(
          colorFilter: ColorFilter.matrix(
            _saturationMatrix(1.0 - (0.48 * _mateFade.value)),
          ),
          child: shifted,
        );
      },
    );
  }

  double _driftPixels(CameraMotionCue cue) {
    if (cue.isCheckmate) return 5.0;

    // Tiered impact for heavy captures
    if (cue.isCapture) {
      if (cue.capturedPiece == 'q') return 4.8; // Queen: High impact
      if (cue.capturedPiece == 'r') return 4.5; // Rook: Heavy impact
      return 4.0; // Bishop/Knight: Standard impact
    }

    if (cue.isCheck) return 4.0;
    return 3.0;
  }

  double _zoomAmount(CameraMotionCue cue) {
    if (cue.isCheckmate) return 0.035;
    if (cue.isCheck) return 0.018;

    // Tiered zoom for heavy captures
    if (cue.isCapture) {
      if (cue.capturedPiece == 'q') return 0.026; // Queen: Dramatic zoom
      if (cue.capturedPiece == 'r') return 0.020; // Rook: Strong zoom
      return 0.012; // Bishop/Knight: Subtle zoom
    }

    return 0.006;
  }

  Offset _moveDirection(String from, String to, bool isFlipped) {
    if (from.length < 2 || to.length < 2) {
      return Offset.zero;
    }

    final fromCol = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = 8 - int.parse(from[1]);
    final toCol = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRow = 8 - int.parse(to[1]);

    final dx =
        (isFlipped ? 7 - toCol : toCol) - (isFlipped ? 7 - fromCol : fromCol);
    final dy =
        (isFlipped ? 7 - toRow : toRow) - (isFlipped ? 7 - fromRow : fromRow);
    final distance = math.sqrt((dx * dx) + (dy * dy));

    if (distance == 0) {
      return Offset.zero;
    }
    return Offset(dx / distance, dy / distance);
  }

  List<double> _saturationMatrix(double saturation) {
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;
    final inv = 1 - saturation;

    return <double>[
      r * inv + saturation,
      g * inv,
      b * inv,
      0,
      0,
      r * inv,
      g * inv + saturation,
      b * inv,
      0,
      0,
      r * inv,
      g * inv,
      b * inv + saturation,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
