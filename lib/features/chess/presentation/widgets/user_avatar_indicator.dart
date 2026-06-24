import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';

import '../../application/chess_provider.dart';
import '../../application/battleground_provider.dart';

class UserAvatarIndicator extends StatefulWidget {
  final bool isRated;
  const UserAvatarIndicator({super.key, this.isRated = false});

  @override
  State<UserAvatarIndicator> createState() => _UserAvatarIndicatorState();
}

class _UserAvatarIndicatorState extends State<UserAvatarIndicator> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final chessState = ref.watch(chessProvider);
        final userName = chessState.userName;
        final avatarPath = chessState.userAvatarPath;

        final primaryColor = ScholarlyTheme.accentBlue;

        int consolidatedRating = 1200;
        int totalWinningStreak = 0;
        if (widget.isRated) {
          final bgState = ref.watch(battlegroundProvider);
          consolidatedRating = bgState.consolidatedRating;
          totalWinningStreak = bgState.totalWinningStreak;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 12 : 6,
              vertical: 4,
            ),
            decoration: ScholarlyTheme.modernDecoration().copyWith(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withValues(alpha: _isExpanded ? 0.5 : 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Image Avatar
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: avatarPath.startsWith('assets/')
                          ? Image.asset(
                              avatarPath,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(avatarPath),
                              fit: BoxFit.cover,
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
                              const SizedBox(width: 10),
                              // Name & Rating/Subtitle Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        userName,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        style: GoogleFonts.inter(
                                          color: ScholarlyTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (widget.isRated && totalWinningStreak > 0) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.local_fire_department_rounded,
                                          color: Colors.deepOrangeAccent,
                                          size: 12,
                                        ),
                                        Text(
                                          '$totalWinningStreak',
                                          style: GoogleFonts.jetBrainsMono(
                                            color: Colors.deepOrangeAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (widget.isRated)
                                    Text(
                                      'ELO $consolidatedRating',
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: ScholarlyTheme.accentBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 4),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
