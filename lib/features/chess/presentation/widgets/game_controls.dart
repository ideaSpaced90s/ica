import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/chess_provider.dart';
import '../scholarly_theme.dart';

class ActionIconButton extends StatefulWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.isActive = false,
    this.activeColor,
    this.activeIconColor,
    this.size,
    this.shouldBlink = false,
    this.onBlinkComplete,
  });

  final bool shouldBlink;
  final VoidCallback? onBlinkComplete;

  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isActive;
  final Color? activeColor;
  final Color? activeIconColor;
  final double? size;

  @override
  State<ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<ActionIconButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _blinkController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut));

    if (widget.shouldBlink) {
      _startBlink();
    }
  }

  @override
  void didUpdateWidget(ActionIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBlink && !oldWidget.shouldBlink) {
      _startBlink();
    }
  }

  Future<void> _startBlink() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    for (int i = 0; i < 5; i++) {
      if (!mounted) break;
      await _blinkController.forward();
      if (!mounted) break;
      _blinkController.reset();
      
      if (i < 4) { // Don't wait after the last blink
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
    
    widget.onBlinkComplete?.call();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sizeInfo = MediaQuery.of(context);
    final isPortrait = sizeInfo.orientation == Orientation.portrait;

    // Cap button size for small height screens
    final double portraitBase = sizeInfo.size.height * 0.12;
    final defaultSize = isPortrait ? portraitBase.clamp(40.0, 80.0) : 40.0;
    final size = widget.size ?? defaultSize;

    return GestureDetector(
      onTapDown: widget.isEnabled
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isEnabled
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: size + 16,
            height: size + 16,
            decoration: ScholarlyTheme.modernDecoration(
              sunken: _isPressed || widget.isActive,
            ).copyWith(
              color: (widget.isActive || _isPressed)
                  ? (widget.activeColor ?? ScholarlyTheme.accentBlueSoft)
                  : ScholarlyTheme.panelBase,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (_glowAnimation.value > 0)
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.5 * _glowAnimation.value),
                    blurRadius: 25 * _glowAnimation.value,
                    spreadRadius: 8 * _glowAnimation.value,
                  ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Center(
              child: Icon(
                widget.icon,
                color: widget.isEnabled
                    ? (widget.isActive || _glowAnimation.value > 0.4
                        ? (widget.activeIconColor ?? ScholarlyTheme.accentBlue)
                        : ScholarlyTheme.textPrimary)
                    : ScholarlyTheme.textSubtle,
                size: size,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimePresetChip extends StatelessWidget {
  const TimePresetChip({
    super.key,
    required this.label,
    required this.total,
    required this.inc,
    required this.ref,
    required this.isSelected,
  });

  final String label;
  final Duration total;
  final Duration inc;
  final WidgetRef ref;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ref.read(chessProvider.notifier).setTimeControl(total, inc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: ScholarlyTheme.modernDecoration(sunken: isSelected)
            .copyWith(
              color: isSelected
                  ? ScholarlyTheme.accentBlueSoft
                  : ScholarlyTheme.panelBase,
              borderRadius: BorderRadius.circular(20), // Pill shape
              border: Border.all(
                color: isSelected
                    ? ScholarlyTheme.accentBlue
                    : ScholarlyTheme.panelStroke,
                width: 1,
              ),
            ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? ScholarlyTheme.accentBlue
                : ScholarlyTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
