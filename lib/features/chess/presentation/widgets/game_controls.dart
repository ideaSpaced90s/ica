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
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isActive;

  @override
  State<ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<ActionIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final sizeInfo = MediaQuery.of(context);
    final isPortrait = sizeInfo.orientation == Orientation.portrait;
    
    // Cap button size for small height screens
    final double portraitBase = sizeInfo.size.height * 0.12;
    final size = isPortrait ? portraitBase.clamp(40.0, 80.0) : 40.0;
    
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: size + 16,
        height: size + 16,
        decoration: ScholarlyTheme.modernDecoration(
          sunken: _isPressed || widget.isActive,
        ).copyWith(
          color: (widget.isActive || _isPressed) 
              ? ScholarlyTheme.accentBlueSoft 
              : ScholarlyTheme.panelBase,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Icon(
            widget.icon,
            color: widget.isEnabled 
                ? (widget.isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary)
                : ScholarlyTheme.textSubtle,
            size: size,
          ),
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
        decoration: ScholarlyTheme.modernDecoration(sunken: isSelected).copyWith(
          color: isSelected ? ScholarlyTheme.accentBlueSoft : ScholarlyTheme.panelBase,
          borderRadius: BorderRadius.circular(20), // Pill shape
          border: Border.all(
            color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


