import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/chess_provider.dart';
import '../../scholarly_theme.dart';

class TacticsPlaybackControls extends ConsumerWidget {
  const TacticsPlaybackControls({
    super.key,
    this.axis = Axis.vertical,
  });

  final Axis axis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);
    
    final isPlaying = state.isTacticsPlaybackActive;
    
    final children = [
      _PlaybackActionIcon(
        icon: Icons.skip_previous_rounded,
        tooltip: 'Jump to Start',
        onTap: () => notifier.jumpTactic(toStart: true),
      ),
      _PlaybackActionIcon(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Previous Move',
        onTap: () => notifier.stepTactic(-1),
      ),
      _PlaybackActionIcon(
        icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        tooltip: isPlaying ? 'Pause Tactic' : 'Play Tactic',
        isActive: isPlaying,
        isBlinking: isPlaying,
        onTap: () => notifier.toggleTacticPlayback(),
      ),
      _PlaybackActionIcon(
        icon: Icons.stop_rounded,
        tooltip: 'Stop & Close',
        onTap: () => notifier.stopTacticPlayback(),
      ),
      _PlaybackActionIcon(
        icon: Icons.chevron_right_rounded,
        tooltip: 'Next Move',
        onTap: () => notifier.stepTactic(1),
      ),
      _PlaybackActionIcon(
        icon: Icons.skip_next_rounded,
        tooltip: 'Jump to End',
        onTap: () => notifier.jumpTactic(toStart: false),
      ),
    ];

    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 8),
          ]
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(width: 8),
          ]
        ],
      );
    }
  }
}

class _PlaybackActionIcon extends StatefulWidget {
  const _PlaybackActionIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
    this.isBlinking = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool isActive;
  final bool isBlinking;

  @override
  State<_PlaybackActionIcon> createState() => _PlaybackActionIconState();
}

class _PlaybackActionIconState extends State<_PlaybackActionIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    if (widget.isBlinking) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PlaybackActionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking != oldWidget.isBlinking) {
      if (widget.isBlinking) {
        _blinkController.repeat(reverse: true);
      } else {
        _blinkController.stop();
        _blinkController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = ScholarlyTheme.accentGold;

    return Tooltip(
      message: widget.tooltip ?? '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (context, child) {
              final opacity = widget.isBlinking ? _blinkAnimation.value : 1.0;

              final Color bgColor = widget.isBlinking
                  ? themeColor.withValues(alpha: 0.25 * opacity)
                  : _isPressed
                      ? themeColor.withValues(alpha: 0.35)
                      : _isHovered
                          ? themeColor.withValues(alpha: 0.22)
                          : widget.isActive
                              ? themeColor.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.45);

              final Color borderColor = widget.isBlinking
                  ? themeColor.withValues(alpha: 0.6 * opacity)
                  : _isPressed
                      ? themeColor.withValues(alpha: 0.8)
                      : _isHovered
                          ? themeColor.withValues(alpha: 0.7)
                          : widget.isActive
                              ? themeColor.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.7);

              final Color iconColor = widget.isBlinking
                  ? themeColor.withValues(alpha: 0.3 + 0.7 * opacity)
                  : _isHovered || widget.isActive || _isPressed
                      ? themeColor
                      : themeColor.withValues(alpha: 0.85);

              final double scale = _isPressed
                  ? 0.92
                  : _isHovered
                      ? 1.12
                      : 1.0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 38,
                height: 38,
                transform: Matrix4.diagonal3Values(scale, scale, 1.0),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered || widget.isActive || widget.isBlinking
                          ? themeColor.withValues(alpha: widget.isBlinking ? 0.35 * opacity : 0.22)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: _isHovered ? 12 : 6,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
