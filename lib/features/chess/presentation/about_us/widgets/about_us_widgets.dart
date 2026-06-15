import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';

class TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const TabSelector({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'title': 'Overview', 'icon': Icons.school_rounded},
      {'title': 'Manual', 'icon': Icons.menu_book_rounded},
      {'title': 'Tech Stack', 'icon': Icons.settings_suggest_rounded},
      {'title': 'Contact', 'icon': Icons.mail_rounded},
    ];

    return JuicyGlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          final tab = tabs[index];

          Color activeColor;
          switch (index) {
            case 0:
              activeColor = Colors.indigo;
              break;
            case 1:
              activeColor = const Color(0xFF10B981);
              break;
            case 2:
              activeColor = Colors.purple;
              break;
            case 3:
              activeColor = Colors.amber.shade700;
              break;
            default:
              activeColor = Colors.blue;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? activeColor.withValues(alpha: 0.3) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 20,
                      color: isSelected ? activeColor : ScholarlyTheme.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['title'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? activeColor : ScholarlyTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class AnimatedEntryCard extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedEntryCard({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedEntryCard> createState() => _AnimatedEntryCardState();
}

class _AnimatedEntryCardState extends State<AnimatedEntryCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
