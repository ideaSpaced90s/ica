import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/study_lab_provider.dart';
import '../../../application/arena_provider.dart';
import '../../mobile_navigation_shell.dart';
import '../../scholarly_theme.dart';

class PracticeModePanel extends ConsumerWidget {
  const PracticeModePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyState = ref.watch(studyLabProvider);
    final studyNotifier = ref.read(studyLabProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRACTICE LAB',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.2,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          const Divider(color: ScholarlyTheme.panelStroke, height: 20),

          if (studyState.isGuessingMode) ...[
            // Guessing Mode Dashboard
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScholarlyTheme.panelBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ScholarlyTheme.panelStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Guess the Move Active',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentBlue,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.redAccent),
                        label: Text(
                          'Exit',
                          style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          studyNotifier.toggleGuessingMode(false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try to guess the next move made in the game. Make your move directly on the board!',
                    style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Guessed Correctly:',
                        style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textMuted),
                      ),
                      Text(
                        '${studyState.guessedNodes.length} Moves',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                // 1. Play from Position
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScholarlyTheme.panelBase,
                      foregroundColor: ScholarlyTheme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: ScholarlyTheme.panelStroke),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.play_circle_outline, color: ScholarlyTheme.accentBlue),
                    label: Text(
                      'Play Position',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onPressed: () {
                      final activeFen = studyState.activeFen;
                      
                      // 1. Load position into Arena
                      ref.read(arenaProvider.notifier).reset(customFen: activeFen);
                      
                      // 2. Navigate to Arena page index
                      ref.read(mobileNavIndexProvider.notifier).state = 1;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Arena loaded from custom analysis position!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Guess the Move
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.lightbulb_outline),
                    label: Text(
                      'Guess Move',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      if (studyState.nodes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please load or play some moves first to guess!'),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }
                      studyNotifier.toggleGuessingMode(true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
