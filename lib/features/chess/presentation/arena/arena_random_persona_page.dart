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
  final bool embedMode;
  final VoidCallback? onMatchCommitted;
  const ArenaRandomPersonaPage({
    super.key,
    this.embedMode = false,
    this.onMatchCommitted,
  });

  @override
  ConsumerState<ArenaRandomPersonaPage> createState() =>
      _ArenaRandomPersonaPageState();
}

class _ArenaRandomPersonaPageState extends ConsumerState<ArenaRandomPersonaPage>
    with TickerProviderStateMixin {
  bool _isShuffling = false;
  // Temporary avatars shown only during the shuffle animation
  AiAvatar? _shuffleUpAvatar;
  AiAvatar? _shuffleDownAvatar;
  Timer? _shuffleTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _diceRotationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _diceRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _animationController.dispose();
    _diceRotationController.dispose();
    super.dispose();
  }

  void _triggerShuffle() {
    if (_isShuffling) return;

    // Seed shuffle from current provider state
    final chessState = ref.read(chessProvider);
    _shuffleUpAvatar = AiAvatar.getAvatar(chessState.engineLevel);
    _shuffleDownAvatar = AiAvatar.getAvatar(chessState.bottomAvatarId);

    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      _isShuffling = true;
    });
    _animationController.forward();
    _diceRotationController.repeat();

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
        _diceRotationController.stop();
        _diceRotationController.reset();
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
          _shuffleUpAvatar = list[randUpIdx];
          _shuffleDownAvatar = list[randDownIdx];
        });
        ticks++;
      }
    });
  }

  Future<void> _commitMatchSelection() async {
    if (_shuffleUpAvatar == null || _shuffleDownAvatar == null) return;
    final notifier = ref.read(chessProvider.notifier);
    await notifier.setEngineLevel(_shuffleUpAvatar!.id);
    await notifier.setBottomAvatarId(_shuffleDownAvatar!.id);
    // Clear temp shuffle avatars — provider is now the source of truth
    if (mounted) {
      setState(() {
        _shuffleUpAvatar = null;
        _shuffleDownAvatar = null;
      });
    }
    if (!mounted) return;
    if (widget.onMatchCommitted != null) {
      widget.onMatchCommitted!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always watch the provider so Explorer changes reflect here immediately
    final chessState = ref.watch(chessProvider);
    final displayUpAvatar = _isShuffling
        ? _shuffleUpAvatar ?? AiAvatar.getAvatar(chessState.engineLevel)
        : AiAvatar.getAvatar(chessState.engineLevel);
    final displayDownAvatar = _isShuffling
        ? _shuffleDownAvatar ?? AiAvatar.getAvatar(chessState.bottomAvatarId)
        : AiAvatar.getAvatar(chessState.bottomAvatarId);

    final mainContent = SafeArea(
      child: Column(
        children: [
          // Header
          if (!widget.embedMode)
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // UP ENGINE CARD
                      _buildMatchmakingCard(
                        role: 'UP ENGINE (WHITE)',
                        avatar: displayUpAvatar,
                      ),

                      const SizedBox(height: 12),

                      // Glowing dice button replaces VS
                      _buildGlowingDiceButton(),

                      const SizedBox(height: 12),

                      // DOWN ENGINE CARD
                      _buildMatchmakingCard(
                        role: 'DOWN ENGINE (BLACK)',
                        avatar: displayDownAvatar,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedMode) {
      return mainContent;
    }

    return AmbientScaffold(
      blob1Color: const Color(0xFFFAE8FF), // Light Pink/Purple
      blob2Color: const Color(0xFFEFF6FF), // Light Blue
      blob3Color: const Color(0xFFECFDF5), // Light Green
      body: mainContent,
    );
  }

  Widget _buildGlowingDiceButton() {
    final blueColor = const Color(0xFF2563EB); // Static blue hue
    return GestureDetector(
      onTap: _isShuffling ? null : _triggerShuffle,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.85),
          boxShadow: [
            BoxShadow(
              color: blueColor.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: blueColor,
            width: 2.0,
          ),
        ),
        child: Center(
          child: RotationTransition(
            turns: _diceRotationController,
            child: Icon(
              Icons.casino_rounded,
              size: 28,
              color: blueColor,
            ),
          ),
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
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: avatar.color.withValues(alpha: 0.25),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: avatar.color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            role,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: ScholarlyTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
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
          const SizedBox(height: 10),
          Text(
            avatar.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            avatar.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: ScholarlyTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: avatar.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${avatar.fideRatingRange} ELO',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: avatar.textSafeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
