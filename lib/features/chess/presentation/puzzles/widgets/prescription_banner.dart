import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/prescription_puzzle_repository.dart';

class PrescriptionBanner extends StatelessWidget {
  final ScotomaAxis axis;

  const PrescriptionBanner({
    super.key,
    required this.axis,
  });

  Color _getThemeColor() {
    switch (axis) {
      case ScotomaAxis.dgb:
      case ScotomaAxis.hrz:
      case ScotomaAxis.knf:
        return const Color(0xFF2563EB); // Geometry Therapy (Blue)
      case ScotomaAxis.tnl:
      case ScotomaAxis.pin:
        return const Color(0xFF7C3AED); // Attentional Therapy (Violet)
      case ScotomaAxis.grd:
      case ScotomaAxis.ksb:
        return const Color(0xFFEF4444); // Impulse & Defense (Crimson)
      case ScotomaAxis.tmp:
        return const Color(0xFFF59E0B); // Pressure Cooker (Amber)
      case ScotomaAxis.balanced:
        return const Color(0xFF10B981); // Balanced Vision (Emerald)
    }
  }

  String _getCategoryText() {
    switch (axis) {
      case ScotomaAxis.dgb:
      case ScotomaAxis.hrz:
      case ScotomaAxis.knf:
        return 'GEOMETRY THERAPY';
      case ScotomaAxis.tnl:
      case ScotomaAxis.pin:
        return 'ATTENTIONAL THERAPY';
      case ScotomaAxis.grd:
      case ScotomaAxis.ksb:
        return 'IMPULSE & DEFENSE';
      case ScotomaAxis.tmp:
        return 'PRESSURE COOKER';
      case ScotomaAxis.balanced:
        return 'BALANCED VISION';
    }
  }

  String _getSubsetTitle() {
    switch (axis) {
      case ScotomaAxis.dgb:
        return 'The Long Diagonal';
      case ScotomaAxis.hrz:
        return 'Lateral Sweeps';
      case ScotomaAxis.knf:
        return 'Knight Vision';
      case ScotomaAxis.tnl:
        return 'Board-Wide Vision';
      case ScotomaAxis.pin:
        return 'Unpinning the Mind';
      case ScotomaAxis.grd:
        return 'The Poisoned Apple';
      case ScotomaAxis.ksb:
        return 'King Radar';
      case ScotomaAxis.tmp:
        return 'Survival Mode';
      case ScotomaAxis.balanced:
        return 'General Mastery';
    }
  }

  String _getDescription() {
    switch (axis) {
      case ScotomaAxis.dgb:
        return 'Cures Diagonal Retreat Blindness (DGB)';
      case ScotomaAxis.hrz:
        return 'Cures Horizontal Swing Blindness (HRZ)';
      case ScotomaAxis.knf:
        return 'Cures Flank Knight Blindness (KNF)';
      case ScotomaAxis.tnl:
        return 'Cures Flank Tunnel Vision (TNL)';
      case ScotomaAxis.pin:
        return 'Cures Pinned Piece Hallucination (PIN)';
      case ScotomaAxis.grd:
        return 'Cures Material Greed Bias (GRD)';
      case ScotomaAxis.ksb:
        return 'Cures King Safety Blindness (KSB)';
      case ScotomaAxis.tmp:
        return 'Cures Time Pressure Distress (TMP)';
      case ScotomaAxis.balanced:
        return 'Sharpens all cognitive-visual dimensions';
    }
  }

  IconData _getIcon() {
    switch (axis) {
      case ScotomaAxis.dgb:
        return Icons.gesture_rounded;
      case ScotomaAxis.hrz:
        return Icons.swap_horiz_rounded;
      case ScotomaAxis.knf:
        return Icons.star_outline_rounded;
      case ScotomaAxis.tnl:
        return Icons.zoom_out_map_rounded;
      case ScotomaAxis.pin:
        return Icons.link_off_rounded;
      case ScotomaAxis.grd:
        return Icons.gavel_rounded;
      case ScotomaAxis.ksb:
        return Icons.security_rounded;
      case ScotomaAxis.tmp:
        return Icons.timer_rounded;
      case ScotomaAxis.balanced:
        return Icons.remove_red_eye_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIcon(),
              color: themeColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getCategoryText(),
                  style: GoogleFonts.outfit(
                    color: themeColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _getSubsetTitle(),
                  style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 0.5),
                Text(
                  _getDescription(),
                  style: GoogleFonts.inter(
                    color: Colors.black54,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
