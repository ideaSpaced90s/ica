import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import '../../services/chess_sound_service.dart';
import '../../application/chess_provider.dart';
import '../../application/arena_provider.dart';
import '../../domain/models/ai_avatar.dart';

class GMChanakyaNewGameOverlay extends ConsumerStatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const GMChanakyaNewGameOverlay({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  ConsumerState<GMChanakyaNewGameOverlay> createState() => _GMChanakyaNewGameOverlayState();
}

class _GMChanakyaNewGameOverlayState extends ConsumerState<GMChanakyaNewGameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Play Chanakya intro sound on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.chanakyaNotify);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arenaState = ref.watch(arenaProvider);
    final chessState = ref.watch(chessProvider);

    final isEvE = arenaState.isEngineVsEngine;
    final String modeText = arenaState.gameMode == 'chess960' ? 'Chess960' : 'Classic Chess';

    // Format Timing
    final String timeStr;
    if (arenaState.baseTimeDuration == Duration.zero || arenaState.baseTimeDuration.inMinutes == 0) {
      timeStr = 'Unlimited';
    } else {
      final base = arenaState.baseTimeDuration.inMinutes;
      final inc = arenaState.incrementDuration.inSeconds;
      timeStr = '${base}m | +${inc}s';
    }

    // Detail resolved details
    final String opponentLabel;
    final String opponentSub;
    final Color opponentColor;

    if (isEvE) {
      final top = AiAvatar.getAvatar(arenaState.engineLevel);
      final bottom = AiAvatar.getAvatar(arenaState.bottomAvatarId);
      opponentLabel = '${top.name} vs ${bottom.name}';
      opponentSub = 'Engine vs Engine';
      opponentColor = ScholarlyTheme.accentYellow;
    } else {
      final opponent = AiAvatar.getAvatar(arenaState.engineLevel);
      opponentLabel = opponent.name;
      opponentSub = opponent.title;
      opponentColor = opponent.color;
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // Blurred Darkened Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),

          // Central Card Info
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: ScholarlyTheme.glassPanelDecoration(radius: 24).copyWith(
                  color: Colors.white.withValues(alpha: 0.96),
                  border: Border.all(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage('assets/persona/gm_chanakya.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PremiumGradientText(
                                'GM CHANAKYA',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Supreme Chess Mentor',
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            'NEW MATCH',
                            style: GoogleFonts.jetBrainsMono(
                              color: ScholarlyTheme.accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 18),

                    // Speech Bubble / Message Content
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 100),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            height: 1.55,
                          ),
                          children: _buildChanakyaSpeech(context, arenaState, chessState),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Visual Settings Grid (Details at a glance)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.panelStroke.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ScholarlyTheme.panelStroke,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.smart_toy_rounded,
                            label: 'Opponent',
                            value: opponentLabel,
                            valSub: opponentSub,
                            iconColor: opponentColor,
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: Icons.timer_rounded,
                            label: 'Time Control',
                            value: timeStr,
                            iconColor: ScholarlyTheme.accentBlue,
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: Icons.grid_view_rounded,
                            label: 'Game Mode',
                            value: modeText,
                            iconColor: const Color(0xFF8B5CF6),
                          ),
                          if (!isEvE) ...[
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              icon: Icons.color_lens_rounded,
                              label: 'Your Side',
                              value: arenaState.isPlayerWhite ? 'White' : 'Black',
                              iconColor: Colors.blueGrey,
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action Row Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: ScholarlyTheme.panelStroke),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textSubtle,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onConfirm,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final scale = 1.0 + 0.03 * _pulseController.value;
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: ScholarlyTheme.accentBlue,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ScholarlyTheme.accentBlue.withValues(
                                            alpha: 0.25 + 0.2 * _pulseController.value,
                                          ),
                                          blurRadius: 10 + 6 * _pulseController.value,
                                          spreadRadius: 1 * _pulseController.value,
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'BEGIN TRIAL',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? valSub,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textSubtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (valSub != null)
              Text(
                valSub,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<TextSpan> _buildChanakyaSpeech(BuildContext context, ArenaState state, ChessState chessState) {
    final isEvE = state.isEngineVsEngine;
    final String modeText = state.gameMode == 'chess960' ? 'Chess960' : 'Classic Chess';

    // Format Timing
    final String timeStr;
    if (state.baseTimeDuration == Duration.zero || state.baseTimeDuration.inMinutes == 0) {
      timeStr = 'Unlimited';
    } else {
      final base = state.baseTimeDuration.inMinutes;
      final inc = state.incrementDuration.inSeconds;
      timeStr = '${base}m | +${inc}s';
    }

    if (isEvE) {
      final topAvatar = AiAvatar.getAvatar(state.engineLevel);
      final bottomAvatar = AiAvatar.getAvatar(state.bottomAvatarId);

      return [
        const TextSpan(text: 'Apprentice, you have requested a machine-vs-machine simulation. This strategic clash will be played between '),
        TextSpan(
          text: topAvatar.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFD97706),
          ),
        ),
        const TextSpan(text: ' ('),
        TextSpan(
          text: '${topAvatar.fideRatingRange} ELO',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
          ),
        ),
        const TextSpan(text: ') and '),
        TextSpan(
          text: bottomAvatar.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFD97706),
          ),
        ),
        const TextSpan(text: ' ('),
        TextSpan(
          text: '${bottomAvatar.fideRatingRange} ELO',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
          ),
        ),
        const TextSpan(text: ') under the laws of '),
        TextSpan(
          text: modeText,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2563EB),
          ),
        ),
        const TextSpan(text: '. Time control is set at '),
        TextSpan(
          text: timeStr,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const TextSpan(text: '. Do not merely watch—study the structure of their conflict and locate their critical errors.'),
      ];
    } else {
      final opponent = AiAvatar.getAvatar(state.engineLevel);
      final colorText = state.isPlayerWhite ? 'White' : 'Black';

      return [
        const TextSpan(text: 'Apprentice, your next trial is prepared. You shall face '),
        TextSpan(
          text: opponent.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFD97706),
          ),
        ),
        const TextSpan(text: ' ('),
        TextSpan(
          text: opponent.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
          ),
        ),
        const TextSpan(text: '), whose computational strength is estimated at '),
        TextSpan(
          text: '${opponent.fideRatingRange} ELO',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
          ),
        ),
        const TextSpan(text: '. You will command the '),
        TextSpan(
          text: colorText,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: state.isPlayerWhite ? const Color(0xFF0D9488) : const Color(0xFF4B5563),
          ),
        ),
        const TextSpan(text: ' pieces under a time control of '),
        TextSpan(
          text: timeStr,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const TextSpan(text: '. The battleground is '),
        TextSpan(
          text: modeText,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2563EB),
          ),
        ),
        const TextSpan(text: '. Remember: calculation merely navigates the current move, but strategy defines the future. Steel your resolve.'),
      ];
    }
  }
}
