import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../scholarly_theme.dart';

class UserAvatarIndicator extends StatefulWidget {
  const UserAvatarIndicator({super.key});

  @override
  State<UserAvatarIndicator> createState() => _UserAvatarIndicatorState();
}

class _UserAvatarIndicatorState extends State<UserAvatarIndicator> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(chessProvider);
        final isRated = state.isRatedMode;
        final primaryColor = ScholarlyTheme.accentBlue;
        final bgColor = ScholarlyTheme.accentBlue.withValues(alpha: 0.1);

        return GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: ScholarlyTheme.panelBase,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                if (_isExpanded)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar Icon - Always Visible
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isRated ? Icons.emoji_events_rounded : Icons.person_outline_rounded,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
                // Horizontal Expansion Content
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  child: Container(
                    constraints: _isExpanded ? const BoxConstraints(minWidth: 0) : const BoxConstraints(maxWidth: 0),
                    child: _isExpanded
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 12),
                              // Rating Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isRated ? '${state.consolidatedRating} MASTER' : 'UNRATED',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (state.totalWinningStreak > 0 && isRated) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.deepOrangeAccent,
                                        size: 14,
                                      ),
                                      Text(
                                        '${state.totalWinningStreak}',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: Colors.deepOrangeAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
