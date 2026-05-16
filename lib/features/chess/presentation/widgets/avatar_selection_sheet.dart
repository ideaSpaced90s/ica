import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../domain/models/ai_avatar.dart';
import '../scholarly_theme.dart';

void showAvatarSelectionSheet(BuildContext context, WidgetRef ref, {bool isBottomSlot = false, bool isReadOnly = false}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(chessProvider);
          final currentLevel = isBottomSlot ? state.bottomAvatarId : state.engineLevel;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: ScholarlyTheme.backgroundStart,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: ScholarlyTheme.boardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pill Tab Indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.panelStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Text(
                  isReadOnly ? 'Tactical Personas' : (isBottomSlot ? 'Select Bottom Avatar' : 'Select Persona'),
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  isReadOnly ? 'Competitive profiles are automatically assigned based on your ELO.' : 'Each avatar features a custom simulated playing style and FIDE scale',
                  style: GoogleFonts.inter(
                    color: isReadOnly ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Scrollable Avatars List
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: AiAvatar.avatars.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final avatar = AiAvatar.avatars[index];
                      final isSelected = currentLevel == avatar.id;
                      final isLightColor = avatar.color.computeLuminance() > 0.6;

                      return InkWell(
                        onTap: isReadOnly ? null : () {
                          if (isBottomSlot) {
                            ref.read(chessProvider.notifier).setBottomAvatarId(avatar.id);
                          } else {
                            ref.read(chessProvider.notifier).setEngineLevel(avatar.id);
                          }
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? avatar.color.withValues(alpha: 0.12) 
                                : ScholarlyTheme.panelBase,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? avatar.color 
                                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected ? [] : ScholarlyTheme.cardShadow,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon Badge
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: avatar.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: avatar.color, width: 1.5),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    avatar.imagePath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Details Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          avatar.name,
                                          style: GoogleFonts.inter(
                                            color: ScholarlyTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (avatar.id == 'avatar_10')
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: ScholarlyTheme.accentBlue,
                                            size: 14,
                                          ),
                                        const Spacer(),
                                        // FIDE Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: avatar.color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'FIDE ${avatar.fideRatingRange}',
                                            style: GoogleFonts.jetBrainsMono(
                                              color: isLightColor ? Colors.black87 : avatar.color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      avatar.title,
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.accentBlue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      avatar.playingStyle,
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textMuted,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
