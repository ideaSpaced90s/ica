import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/ai_avatar.dart';
import '../../application/chess_provider.dart';
import '../scholarly_theme.dart';
import '../../services/chess_sound_service.dart';
import '../widgets/ambient_scaffold.dart';

class ArenaRandomPersonaPage extends ConsumerStatefulWidget {
  const ArenaRandomPersonaPage({super.key});

  @override
  ConsumerState<ArenaRandomPersonaPage> createState() =>
      _ArenaRandomPersonaPageState();
}

class _ArenaRandomPersonaPageState extends ConsumerState<ArenaRandomPersonaPage>
    with SingleTickerProviderStateMixin {
  bool _isShuffling = false;
  AiAvatar? _upAvatar;
  AiAvatar? _downAvatar;
  Timer? _shuffleTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Start with current selected personas
    final chessState = ref.read(chessProvider);
    _upAvatar = AiAvatar.getAvatar(chessState.engineLevel);
    _downAvatar = AiAvatar.getAvatar(chessState.bottomAvatarId);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _triggerShuffle() {
    if (_isShuffling) return;

    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      _isShuffling = true;
    });
    _animationController.forward();

    int ticks = 0;
    const maxTicks = 18;
    _shuffleTimer?.cancel();
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 80), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (ticks >= maxTicks) {
        timer.cancel();
        _shuffleTimer = null;
        _animationController.reverse();
        setState(() {
          _isShuffling = false;
        });
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        await _commitMatchSelection();
      } else {
        setState(() {
          // Select two distinct random avatars from the list
          final list = AiAvatar.avatars;
          final randUpIdx = math.Random().nextInt(list.length);
          int randDownIdx = math.Random().nextInt(list.length);
          while (randDownIdx == randUpIdx) {
            randDownIdx = math.Random().nextInt(list.length);
          }
          _upAvatar = list[randUpIdx];
          _downAvatar = list[randDownIdx];
        });
        ticks++;
      }
    });
  }

  Future<void> _commitMatchSelection() async {
    if (_upAvatar == null || _downAvatar == null) return;
    final notifier = ref.read(chessProvider.notifier);
    await notifier.setEngineLevel(_upAvatar!.id);
    await notifier.setBottomAvatarId(_downAvatar!.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AmbientScaffold(
      blob1Color: const Color(0xFFFAE8FF), // Light Pink/Purple
      blob2Color: const Color(0xFFEFF6FF), // Light Blue
      blob3Color: const Color(0xFFECFDF5), // Light Green
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: ScholarlyTheme.textPrimary,
                    ),
                    onPressed: () {
                      ref
                          .read(chessSoundServiceProvider)
                          .playSfx(SoundEffect.uiNavigate);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RANDOM MATCHMAKING',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // UP ENGINE CARD
                        if (_upAvatar != null)
                          _buildMatchmakingCard(
                            role: 'UP ENGINE (WHITE)',
                            avatar: _upAvatar!,
                          ),

                        const SizedBox(height: 16),

                        // VS divider
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.panelStroke.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'VS',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.textMuted,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // DOWN ENGINE CARD
                        if (_downAvatar != null)
                          _buildMatchmakingCard(
                            role: 'DOWN ENGINE (BLACK)',
                            avatar: _downAvatar!,
                          ),

                        const SizedBox(height: 40),

                        // Roll Button
                        SizedBox(
                          width: 220,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isShuffling ? null : _triggerShuffle,
                            icon: const Icon(Icons.casino_rounded, size: 24),
                            label: Text(
                              _isShuffling ? 'SHUFFLING...' : 'ROLL MATCH',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ScholarlyTheme.accentGold,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: ScholarlyTheme.accentGold
                                  .withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchmakingCard({
    required String role,
    required AiAvatar avatar,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: avatar.color.withValues(alpha: 0.25),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: avatar.color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            role,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: ScholarlyTheme.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: avatar.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: avatar.color.withValues(alpha: 0.3),
                width: 2.0,
              ),
            ),
            child: buildAvatarImage(avatar.imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 14),
          Text(
            avatar.name,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            avatar.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: ScholarlyTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: avatar.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${avatar.fideRatingRange} ELO',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: avatar.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
