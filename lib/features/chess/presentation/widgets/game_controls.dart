import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/chess_provider.dart';
import '../scholarly_theme.dart';

class _JuicyTheme {
  final List<Color> colors;
  final Color glowColor;
  final Color iconColor;
  final Color borderColor;

  const _JuicyTheme({
    required this.colors,
    required this.glowColor,
    required this.iconColor,
    required this.borderColor,
  });
}

_JuicyTheme _getJuicyTheme(IconData icon, {Color? baseColor, Color? activeColor, Color? iconColor, Color? activeIconColor}) {
  List<Color> colors;
  Color glowColor;
  Color iconClr;
  Color borderClr;

  if (icon == Icons.menu_rounded) {
    // Cyberpunk Cobalt
    colors = const [Color(0xFF2563EB), Color(0xFF1D4ED8)];
    glowColor = const Color(0xFF3B82F6);
    iconClr = Colors.white;
    borderClr = const Color(0xFF60A5FA);
  } else if (icon == Icons.add_box_rounded || icon == Icons.casino_rounded) {
    // Golden Amber
    colors = const [Color(0xFFF59E0B), Color(0xFFD97706)];
    glowColor = const Color(0xFFFBBF24);
    iconClr = Colors.white;
    borderClr = const Color(0xFFFDE047);
  } else if (icon == Icons.undo_rounded || icon == Icons.redo_rounded) {
    // Royal Amethyst
    colors = const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
    glowColor = const Color(0xFFA78BFA);
    iconClr = Colors.white;
    borderClr = const Color(0xFFC084FC);
  } else if (icon == Icons.flip_camera_android_outlined) {
    // Tropical Cyan
    colors = const [Color(0xFF06B6D4), Color(0xFF0891B2)];
    glowColor = const Color(0xFF22D3EE);
    iconClr = Colors.white;
    borderClr = const Color(0xFF67E8F9);
  } else if (icon == Icons.pause_rounded || icon == Icons.play_arrow_rounded) {
    // Sunset Crimson
    colors = const [Color(0xFFEF4444), Color(0xFFDC2626)];
    glowColor = const Color(0xFFF87171);
    iconClr = Colors.white;
    borderClr = const Color(0xFFFCA5A5);
  } else if (icon == Icons.smart_toy_rounded || icon == Icons.smart_toy_outlined) {
    // Synthwave Magenta
    colors = const [Color(0xFFEC4899), Color(0xFFD946EF)];
    glowColor = const Color(0xFFF472B6);
    iconClr = Colors.white;
    borderClr = const Color(0xFFF5D0FE);
  } else if (icon == Icons.save_rounded) {
    // Ocean Azure
    colors = const [Color(0xFF0EA5E9), Color(0xFF0284C7)];
    glowColor = const Color(0xFF38BDF8);
    iconClr = Colors.white;
    borderClr = const Color(0xFF7DD3FC);
  } else if (icon == Icons.lightbulb_rounded || icon == Icons.lightbulb_outline_rounded) {
    // Neon Sunfire
    colors = const [Color(0xFFEAB308), Color(0xFFCA8A04)];
    glowColor = const Color(0xFFFDE047);
    iconClr = Colors.white;
    borderClr = const Color(0xFFFEF08A);
  } else if (icon == Icons.timer_rounded) {
    // Deep Indigo
    colors = const [Color(0xFF6366F1), Color(0xFF4F46E5)];
    glowColor = const Color(0xFF818CF8);
    iconClr = Colors.white;
    borderClr = const Color(0xFFA5B4FC);
  } else if (icon == Icons.settings_suggest_rounded) {
    // Slate Chrome
    colors = const [Color(0xFF64748B), Color(0xFF475569)];
    glowColor = const Color(0xFF94A3B8);
    iconClr = Colors.white;
    borderClr = const Color(0xFFCBD5E1);
  } else if (icon == Icons.grid_view_rounded || icon == Icons.shuffle_rounded) {
    // Electric Orange
    colors = const [Color(0xFFF97316), Color(0xFFEA580C)];
    glowColor = const Color(0xFFFB923C);
    iconClr = Colors.white;
    borderClr = const Color(0xFFFDBA74);
  } else {
    // Fallback Blue
    colors = const [Color(0xFF0D6EFD), Color(0xFF0A58CA)];
    glowColor = const Color(0xFF3B82F6);
    iconClr = Colors.white;
    borderClr = const Color(0xFF60A5FA);
  }

  // Support manual style overrides from callers if provided
  if (baseColor != null) {
    colors = [baseColor, baseColor.withValues(alpha: 0.8)];
    glowColor = baseColor;
    borderClr = baseColor.withValues(alpha: 0.5);
  }
  if (iconColor != null) {
    iconClr = iconColor;
  }
  if (activeColor != null && activeColor.a > 0.5) {
    colors = [activeColor, activeColor.withValues(alpha: 0.8)];
    glowColor = activeColor;
    borderClr = activeColor.withValues(alpha: 0.5);
  }
  if (activeIconColor != null) {
    iconClr = activeIconColor;
  }

  return _JuicyTheme(
    colors: colors,
    glowColor: glowColor,
    iconColor: iconClr,
    borderColor: borderClr,
  );
}

class ActionIconButton extends StatefulWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.isActive = false,
    this.activeColor,
    this.activeIconColor,
    this.iconColor,
    this.baseColor,
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
  final Color? iconColor;
  final Color? baseColor;
  final double? size;

  @override
  State<ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<ActionIconButton> with TickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _blinkController;
  late Animation<double> _glowAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.4), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    if (widget.shouldBlink) {
      _startBlink();
    }

    if (widget.isActive) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(ActionIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBlink && !oldWidget.shouldBlink) {
      _startBlink();
    }

    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sizeInfo = MediaQuery.of(context);
    final isPortrait = sizeInfo.orientation == Orientation.portrait;

    // Cap button size for small height screens
    final double portraitBase = sizeInfo.size.height * 0.07;
    final defaultSize = isPortrait ? portraitBase.clamp(32.0, 56.0) : 32.0;
    final size = widget.size ?? defaultSize;

    final theme = _getJuicyTheme(
      widget.icon,
      baseColor: widget.baseColor,
      activeColor: widget.activeColor,
      iconColor: widget.iconColor,
      activeIconColor: widget.activeIconColor,
    );

    return GestureDetector(
      onTapDown: widget.isEnabled
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isEnabled
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: _isPressed ? Curves.easeOutCubic : Curves.elasticOut,
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnimation, _pulseAnimation]),
          builder: (context, child) {
            final double blinkVal = _glowAnimation.value;
            final double pulseVal = _pulseAnimation.value;

            // Compute neon glowing shadow configurations
            final double glowOpacity = widget.isActive
                ? (0.4 + 0.3 * pulseVal)
                : (blinkVal > 0.0 ? blinkVal * 0.6 : (_isPressed ? 0.5 : 0.25));

            final double glowBlur = widget.isActive
                ? (12.0 + 8.0 * pulseVal)
                : (blinkVal > 0.0 ? blinkVal * 25.0 : (_isPressed ? 16.0 : 8.0));

            final double glowSpread = widget.isActive
                ? (2.0 + 2.0 * pulseVal)
                : (blinkVal > 0.0 ? blinkVal * 8.0 : (_isPressed ? 3.0 : 1.0));

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: size + 16,
              height: size + 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isEnabled
                      ? theme.colors
                      : const [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                ),
                border: Border.all(
                  color: widget.isEnabled
                      ? theme.borderColor.withValues(alpha: 0.6)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  if (widget.isEnabled)
                    BoxShadow(
                      color: theme.glowColor.withValues(alpha: glowOpacity),
                      blurRadius: glowBlur,
                      spreadRadius: glowSpread,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Physical Gel Gloss Shine Overlay
                    if (widget.isEnabled)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.25, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    // Centered Icon Content
                    Center(
                      child: Icon(
                        widget.icon,
                        color: widget.isEnabled
                            ? theme.iconColor
                            : const Color(0xFF94A3B8),
                        size: size,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
