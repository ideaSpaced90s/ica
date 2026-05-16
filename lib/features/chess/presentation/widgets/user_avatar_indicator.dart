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
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                // Styled Avatar Icon ring
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
                const SizedBox(width: 8),
                // Always visible tiny rating/status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isRated ? '${state.userFideRating} ELO' : 'UNRATED',
                    style: GoogleFonts.jetBrainsMono(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Expanding Contents
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: _isExpanded
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            // Name & Subtitle
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isRated ? 'Competitor' : 'Casual Player',
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (state.currentWinningStreak > 0 && isRated) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.deepOrangeAccent,
                                        size: 12,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  isRated
                                      ? 'Games: ${state.ratedGamesCount}'
                                      : 'Stats Disabled',
                                  style: GoogleFonts.inter(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
