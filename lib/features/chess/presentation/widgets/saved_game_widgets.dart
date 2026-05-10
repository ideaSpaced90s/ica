import 'package:flutter/material.dart';
import '../../data/saved_game.dart';
import '../scholarly_theme.dart';

class SavedGameTile extends StatelessWidget {
  const SavedGameTile({
    super.key,
    required this.entry,
    required this.onLoad,
    required this.onDelete,
  });

  final SavedGameEntry entry;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final savedAt = _formatTimestamp(entry.savedAt);
    final summary = entry.recentMoves.isNotEmpty
        ? entry.recentMoves.join('  ')
        : entry.fen.split(' ').first;

    return InkWell(
      onTap: onLoad,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savedAt,
                    style: const TextStyle(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: ScholarlyTheme.accentGold,
              tooltip: 'Delete save',
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final year = timestamp.year.toString().padLeft(4, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$year-$month-$day  $hour:$minute';
  }
}

class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ScholarlyTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: ScholarlyTheme.accentGold.withValues(alpha: 0.9),
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ScholarlyTheme.textPrimary,
                fontSize: 6,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
