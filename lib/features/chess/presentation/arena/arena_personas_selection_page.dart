import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../../domain/models/ai_avatar.dart';
import 'package:kingslayer_chess/src/rust/api/persona.dart' as rust_persona;
import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';

class ArenaPersonasSelectionPage extends ConsumerStatefulWidget {
  final bool embedMode;
  const ArenaPersonasSelectionPage({super.key, this.embedMode = false});

  @override
  ConsumerState<ArenaPersonasSelectionPage> createState() => _ArenaPersonasSelectionPageState();
}

class _ArenaPersonasSelectionPageState extends ConsumerState<ArenaPersonasSelectionPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  
  // Drag offsets
  double _dragDx = 0.0;
  double _dragDy = 0.0;

  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  Offset _swipeStartOffset = Offset.zero;
  Offset _swipeEndOffset = Offset.zero;

  // Track card flip state per persona id
  final Map<String, GlobalKey<FlippableCardState>> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    final state = ref.read(chessProvider);
    // Initialize current index to match the current engine level if possible
    final activeIndex = AiAvatar.avatars.indexWhere((a) => a.id == state.engineLevel);
    if (activeIndex != -1) {
      _currentIndex = activeIndex;
    }

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          // Go to next/prev based on swipe direction
          if (_swipeEndOffset.dx > 0) {
            // Swiped right -> Go to previous
            _currentIndex = (_currentIndex - 1 + AiAvatar.avatars.length) % AiAvatar.avatars.length;
          } else {
            // Swiped left -> Go to next
            _currentIndex = (_currentIndex + 1) % AiAvatar.avatars.length;
          }
          // Reset drag coordinates
          _dragDx = 0.0;
          _dragDy = 0.0;
        });
        _swipeController.reset();
      }
    });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _triggerSwipe(bool forward) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    
    // Automatically unflip card before swiping to keep UI elegant
    final currentAvatar = AiAvatar.avatars[_currentIndex];
    final key = _cardKeys[currentAvatar.id];
    if (key?.currentState != null && !key!.currentState!._isFront) {
      key.currentState!._toggleFlip();
    }

    setState(() {
      _swipeController.duration = const Duration(milliseconds: 350);
      _swipeStartOffset = Offset(_dragDx, _dragDy);
      _swipeEndOffset = Offset(forward ? -600.0 : 600.0, 0.0);
      _swipeAnimation = Tween<Offset>(
        begin: _swipeStartOffset,
        end: _swipeEndOffset,
      ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.fastOutSlowIn));
    });
    _swipeController.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_swipeController.isAnimating) return;
    setState(() {
      _dragDx += details.delta.dx;
      _dragDy += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_swipeController.isAnimating) return;

    // Threshold to complete swipe
    const double threshold = 120.0;
    final double velocityDx = details.velocity.pixelsPerSecond.dx;
    const double velocityThreshold = 800.0;

    final bool isFling = velocityDx.abs() > velocityThreshold;
    final bool isSwipePassed = _dragDx.abs() > threshold;

    if (isSwipePassed || isFling) {
      // Swiped past threshold or flung -> trigger swipe away
      final bool swipeRight = isFling ? velocityDx > 0 : _dragDx > 0;
      final double targetDx = swipeRight ? 600.0 : -600.0;
      
      // Project final dy based on current vertical velocity to make fling feel physics-aligned
      final double velocityDy = details.velocity.pixelsPerSecond.dy;
      final double targetDy = _dragDy + (velocityDy * 0.08);

      // Adjust animation duration based on drag speed
      final double speed = velocityDx.abs();
      int durationMs = 350;
      if (speed > 1000) {
        durationMs = (600.0 / speed * 1000).clamp(180.0, 350.0).toInt();
      }

      setState(() {
        _swipeController.duration = Duration(milliseconds: durationMs);
        _swipeStartOffset = Offset(_dragDx, _dragDy);
        _swipeEndOffset = Offset(targetDx, targetDy);
        _swipeAnimation = Tween<Offset>(
          begin: _swipeStartOffset,
          end: _swipeEndOffset,
        ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic));
      });
      _swipeController.forward();
    } else {
      // Return to center
      final start = Offset(_dragDx, _dragDy);
      setState(() {
        _swipeController.duration = const Duration(milliseconds: 450);
        _swipeStartOffset = start;
        _swipeEndOffset = Offset.zero;
        _swipeAnimation = Tween<Offset>(
          begin: _swipeStartOffset,
          end: _swipeEndOffset,
        ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.elasticOut));
      });
      _swipeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    final currentAvatar = AiAvatar.avatars[_currentIndex];

    final isUpSelected = state.engineLevel == currentAvatar.id;
    final isDownSelected = state.bottomAvatarId == currentAvatar.id;

    final bool isWide = MediaQuery.of(context).size.width > 720;

    final mainContent = Stack(
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Back Button (PERSONAS aligned to right)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: widget.embedMode
                    ? Center(
                        child: Text(
                          'PERSONAS',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: ScholarlyTheme.textPrimary),
                            onPressed: () {
                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                              Navigator.of(context).pop();
                            },
                          ),
                          const Spacer(),
                          Text(
                            'PERSONAS',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 12),

              // Responsive Layout Select
              if (isWide)
                _buildWideLayout(
                  context: context,
                  currentAvatar: currentAvatar,
                  isUpSelected: isUpSelected,
                  isDownSelected: isDownSelected,
                  notifier: notifier,
                )
              else
                _buildNarrowLayout(
                  context: context,
                  currentAvatar: currentAvatar,
                  isUpSelected: isUpSelected,
                  isDownSelected: isDownSelected,
                  notifier: notifier,
                ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedMode) {
      return mainContent;
    }

    return AmbientScaffold(
      blob1Color: currentAvatar.color.withValues(alpha: 0.15),
      blob2Color: const Color(0xFFF3E8FF),
      blob3Color: const Color(0xFFEFF6FF),
      body: mainContent,
    );
  }

  Widget _buildWideLayout({
    required BuildContext context,
    required AiAvatar currentAvatar,
    required bool isUpSelected,
    required bool isDownSelected,
    required dynamic notifier,
  }) {
    return Expanded(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column: Navigation & Configuration (Prev chevron + Set Up)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSideNavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _triggerSwipe(false),
                  tooltip: 'Previous Persona',
                  color: currentAvatar.color,
                ),
                const SizedBox(height: 36),
                _buildSideSelectButton(
                  label: isUpSelected ? 'UP ACTIVE' : 'SET UP',
                  icon: Icons.arrow_upward_rounded,
                  color: currentAvatar.color,
                  isActive: isUpSelected,
                  onPressed: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    notifier.setEngineLevel(currentAvatar.id);
                  },
                ),
              ],
            ),
            const SizedBox(width: 60),

            // Center Column: Persona Flippable Card & Traits Container
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCardStack(
                  maxWidth: 360,
                  maxHeight: 440,
                  currentAvatar: currentAvatar,
                  isUpSelected: isUpSelected,
                  isDownSelected: isDownSelected,
                ),
                const SizedBox(height: 24),
                // Center details title badge
                Container(
                  width: 360,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currentAvatar.title.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: currentAvatar.textSafeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 60),

            // Right Column: Navigation & Configuration (Next chevron + Set Down)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSideNavButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _triggerSwipe(true),
                  tooltip: 'Next Persona',
                  color: currentAvatar.color,
                ),
                const SizedBox(height: 36),
                _buildSideSelectButton(
                  label: isDownSelected ? 'DOWN ACTIVE' : 'SET DOWN',
                  icon: Icons.arrow_downward_rounded,
                  color: currentAvatar.color,
                  isActive: isDownSelected,
                  onPressed: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    notifier.setBottomAvatarId(currentAvatar.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowLayout({
    required BuildContext context,
    required AiAvatar currentAvatar,
    required bool isUpSelected,
    required bool isDownSelected,
    required dynamic notifier,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Card Stack Area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCardStack(
                  maxWidth: 380,
                  maxHeight: 460,
                  currentAvatar: currentAvatar,
                  isUpSelected: isUpSelected,
                  isDownSelected: isDownSelected,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Traits & Bio Section Below Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  currentAvatar.title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: currentAvatar.textSafeColor,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Dating App Bottom Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Swipe Left (Prev Button - Pulsing once every 5s)
                PulsingIconButton(
                  icon: Icons.chevron_left_rounded,
                  color: ScholarlyTheme.textMuted,
                  onPressed: () => _triggerSwipe(false),
                  tooltip: 'Previous Persona',
                ),
                const SizedBox(width: 8),
                
                // Set as Up Engine (White/Player slot)
                Expanded(
                  child: JuicySelectButton(
                    label: isUpSelected ? 'UP ACTIVE' : 'SET UP',
                    icon: Icons.arrow_upward_rounded,
                    color: currentAvatar.color,
                    isActive: isUpSelected,
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      notifier.setEngineLevel(currentAvatar.id);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Set as Down Engine (Black/Opponent slot)
                Expanded(
                  child: JuicySelectButton(
                    label: isDownSelected ? 'DOWN ACTIVE' : 'SET DOWN',
                    icon: Icons.arrow_downward_rounded,
                    color: currentAvatar.color,
                    isActive: isDownSelected,
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      notifier.setBottomAvatarId(currentAvatar.id);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Swipe Right (Next Button - Pulsing once every 5s)
                PulsingIconButton(
                  icon: Icons.chevron_right_rounded,
                  color: ScholarlyTheme.textMuted,
                  onPressed: () => _triggerSwipe(true),
                  tooltip: 'Next Persona',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCardStack({
    required double maxWidth,
    required double maxHeight,
    required AiAvatar currentAvatar,
    required bool isUpSelected,
    required bool isDownSelected,
  }) {
    final int L = AiAvatar.avatars.length;
    final double currentDx = _swipeController.isAnimating ? _swipeAnimation.value.dx : _dragDx;
    final bool isMovingRight = currentDx > 0;
    
    final int midIndex = isMovingRight
        ? (_currentIndex - 1 + L) % L
        : (_currentIndex + 1) % L;
        
    final int bottomIndex = isMovingRight
        ? (_currentIndex - 2 + L) % L
        : (_currentIndex + 2) % L;

    final midAvatar = AiAvatar.avatars[midIndex];
    final bottomAvatar = AiAvatar.avatars[bottomIndex];

    // Transition progress: 150 px for full transition of background cards
    final double progress = (currentDx.abs() / 150.0).clamp(0.0, 1.0);

    // Ensure keys are tracked
    _cardKeys.putIfAbsent(currentAvatar.id, () => GlobalKey<FlippableCardState>());
    _cardKeys.putIfAbsent(midAvatar.id, () => GlobalKey<FlippableCardState>());
    _cardKeys.putIfAbsent(bottomAvatar.id, () => GlobalKey<FlippableCardState>());

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Bottom Card
          Transform.translate(
            offset: Offset(0.0, 32.0 - (16.0 * progress)),
            child: Transform.scale(
              scale: 0.88 + (0.06 * progress),
              child: Opacity(
                opacity: 0.2 + (0.3 * progress),
                child: _buildStaticCard(bottomAvatar),
              ),
            ),
          ),

          // 2. Middle Card
          Transform.translate(
            offset: Offset(0.0, 16.0 * (1.0 - progress)),
            child: Transform.scale(
              scale: 0.94 + (0.06 * progress),
              child: Opacity(
                opacity: 0.5 + (0.5 * progress),
                child: _buildStaticCard(midAvatar),
              ),
            ),
          ),

          // 3. Top Card (Interactive/Draggable/Swipable)
          AnimatedBuilder(
            animation: _swipeAnimation,
            builder: (context, child) {
              final offset = _swipeController.isAnimating
                  ? _swipeAnimation.value
                  : Offset(_dragDx, _dragDy);
              
              // Calculate rotation angle based on drag/swipe displacement
              final rotationAngle = (offset.dx / 300) * (math.pi / 16);

              return Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: rotationAngle,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onPanUpdate: _handleDragUpdate,
              onPanEnd: _handleDragEnd,
              child: FlippableCard(
                key: _cardKeys[currentAvatar.id],
                front: _buildCardFront(currentAvatar, isUpSelected, isDownSelected),
                back: _buildCardBack(currentAvatar),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideSelectButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final lightAccent = Color.alphaBlend(Colors.white.withValues(alpha: 0.25), color);
    final darkAccent = Color.alphaBlend(Colors.black.withValues(alpha: 0.2), color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isActive
                ? LinearGradient(
                    colors: [lightAccent, darkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.65),
            border: Border.all(
              color: isActive ? lightAccent : color.withValues(alpha: 0.4),
              width: isActive ? 2.5 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? Colors.white : color,
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                  color: isActive ? Colors.white : ScholarlyTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Previews or displays a static representation of cards underneath
  Widget _buildStaticCard(AiAvatar avatar) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: avatar.color.withValues(alpha: 0.4), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: buildAvatarImage(
          avatar.imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Frontend of the persona card
  Widget _buildCardFront(AiAvatar avatar, bool isUpActive, bool isDownActive) {
    final isLightColor = avatar.color.computeLuminance() > 0.6;
    final double currentDx = _swipeController.isAnimating ? _swipeAnimation.value.dx : _dragDx;
    final double progress = (currentDx.abs() / 120.0).clamp(0.0, 1.0);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: avatar.color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: avatar.color.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Portrait Image
            buildAvatarImage(
              avatar.imagePath,
              fit: BoxFit.cover,
            ),
            
            // Top Slots Badge Overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active badges
                  Row(
                    children: [
                      if (isUpActive)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: avatar.color, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: avatar.color, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                'UP ACTIVE',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isDownActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: avatar.color, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_downward_rounded, color: avatar.color, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                'DOWN ACTIVE',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: avatar.color.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FIDE ${avatar.fideRatingRange}',
                      style: GoogleFonts.jetBrainsMono(
                        color: isLightColor ? Colors.black87 : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Name Overlay at Top Center (below active/rating row)
            Positioned(
              top: 42,
              left: 12,
              right: 12,
              child: Center(
                child: Text(
                  avatar.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Card Overlay with Title and flip instruction
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 75,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      avatar.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: avatar.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to see details',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tinder-style stamp overlays
            if (progress > 0.02)
              Positioned(
                top: 48,
                left: currentDx > 0 ? 24 : null,
                right: currentDx > 0 ? null : 24,
                child: Transform.rotate(
                  angle: currentDx > 0 ? -0.2 : 0.2,
                  child: Opacity(
                    opacity: progress,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: currentDx > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          width: 3.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        currentDx > 0 ? 'PREV' : 'NEXT',
                        style: GoogleFonts.outfit(
                          color: currentDx > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
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

  // Backend of the persona card
  Widget _buildCardBack(AiAvatar avatar) {
    final config = rust_persona.getPersonaConfig(avatarName: avatar.name);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: avatar.color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: avatar.color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Mini Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatar.color.withValues(alpha: 0.15),
                        border: Border.all(
                          color: avatar.color,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: buildAvatarImage(
                          avatar.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avatar.name,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                          Text(
                            avatar.title,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ScholarlyTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ENGINE SPECIFICATIONS',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: avatar.textSafeColor,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Specs Rows
                        _buildSpecRow(
                          icon: Icons.bar_chart_rounded,
                          label: 'FIDE Rating Range',
                          value: avatar.fideRatingRange,
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.speed_rounded,
                          label: 'Engine Skill Level',
                          value: '${config.skillLevel} / 20',
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.search_rounded,
                          label: 'Search Depth Limit',
                          value: '${config.depth} moves',
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.alt_route_rounded,
                          label: 'MultiPV Candidates',
                          value: '${config.multiPv} lines',
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.casino_rounded,
                          label: 'Random Move Probability',
                          value: avatar.randomMoveProbability,
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.error_outline_rounded,
                          label: 'Blunderness Rate',
                          value: avatar.blunderness,
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.query_stats_rounded,
                          label: 'Heuristic Jitteriness',
                          value: avatar.heuristicJitteriness,
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.storage_rounded,
                          label: 'Transposition Table',
                          value: '${avatar.hashSize} MB',
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.psychology_alt_rounded,
                          label: 'Contempt Option',
                          value: avatar.contemptDisplay,
                        ),
                        const SizedBox(height: 20),

                        // Playing Style Label
                        Text(
                          'PLAYING STYLE & BIO',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: avatar.textSafeColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          avatar.playingStyle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.4,
                            color: ScholarlyTheme.textPrimary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Tap to show photo',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ScholarlyTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: ScholarlyTheme.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// 3D Flippable Card Helper Widget
class FlippableCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final VoidCallback? onTap;

  const FlippableCard({super.key, required this.front, required this.back, this.onTap});

  @override
  State<FlippableCard> createState() => FlippableCardState();
}

class FlippableCardState extends State<FlippableCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    refSound().playSfx(SoundEffect.uiClick);
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  // Helper method to retrieve sound provider without riverpod import in helper state class
  ChessSoundService refSound() {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(chessSoundServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _toggleFlip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;
          final isFront = angle < math.pi / 2;

          // Calculate blur magnitude: peaks at midpoint (angle = pi/2, controller.value = 0.5)
          final double blurVal = math.sin(_controller.value * math.pi) * 6.0;

          // 3D Lift/Elevation values
          final liftProgress = math.sin(_controller.value * math.pi);
          final scaleVal = 1.0 + (liftProgress * 0.05);
          final yOffset = -liftProgress * 15.0;

          Widget cardContent = isFront
              ? widget.front
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: widget.back,
                );

          if (blurVal > 0.1) {
            cardContent = ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
              child: cardContent,
            );
          }
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective distortion
              ..translateByDouble(0.0, yOffset, 0.0, 1.0) // lift card vertically
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Transform.scale(
              scale: scaleVal, // scale up slightly to simulate lifting
              child: cardContent,
            ),
          );
        },
      ),
    );
  }
}

// Custom Pulsing IconButton that blinks once every 5 seconds
class PulsingIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  const PulsingIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<PulsingIconButton> createState() => _PulsingIconButtonState();
}

class _PulsingIconButtonState extends State<PulsingIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        double scale = 1.0;
        double glowIntensity = 0.0;

        // Pulsing active for first 16% of 5s (~800ms)
        if (progress < 0.16) {
          final pulseProgress = progress / 0.16;
          scale = 1.0 + math.sin(pulseProgress * math.pi) * 0.15;
          glowIntensity = math.sin(pulseProgress * math.pi);
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.1 + (glowIntensity * 0.3)),
                  blurRadius: 6 + (glowIntensity * 8),
                  spreadRadius: glowIntensity * 2,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(widget.icon, color: widget.color, size: 24),
              onPressed: widget.onPressed,
              tooltip: widget.tooltip,
            ),
          ),
        );
      },
    );
  }
}

// Custom Juicy Selection Button for Up/Down slot configurations
class JuicySelectButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onPressed;

  const JuicySelectButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<JuicySelectButton> createState() => _JuicySelectButtonState();
}

class _JuicySelectButtonState extends State<JuicySelectButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color;
    final lightAccent = Color.alphaBlend(Colors.white.withValues(alpha: 0.25), baseColor);
    final darkAccent = Color.alphaBlend(Colors.black.withValues(alpha: 0.2), baseColor);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: widget.isActive
                ? LinearGradient(
                    colors: [lightAccent, darkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isActive ? null : Colors.white.withValues(alpha: 0.45),
            border: Border.all(
              color: widget.isActive ? lightAccent : baseColor.withValues(alpha: 0.4),
              width: widget.isActive ? 2 : 1.5,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isActive ? Colors.white : baseColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: widget.isActive ? Colors.white : ScholarlyTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
