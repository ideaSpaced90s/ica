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
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: ScholarlyTheme.win98Decoration(
          sunken: _isPressed || widget.isActive,
        ),
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Icon(
            widget.icon,
            color: widget.isEnabled 
                ? (widget.isActive ? ScholarlyTheme.accentGold : Colors.black)
                : Colors.grey,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ScholarlyTheme.win98Decoration(sunken: isSelected),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Tahoma',
          ),
        ),
      ),
    );
  }
}


