import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../../domain/models/ai_avatar.dart';
import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';

class ArenaPersonasSelectionPage extends ConsumerStatefulWidget {
  const ArenaPersonasSelectionPage({super.key});

  @override
  ConsumerState<ArenaPersonasSelectionPage> createState() => _ArenaPersonasSelectionPageState();
}

class _ArenaPersonasSelectionPageState extends ConsumerState<ArenaPersonasSelectionPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  
  // Drag offsets
  double _dragDx = 0.0;
  double _dragDy = 0.0;
  bool _isDragging = false;

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
      _swipeStartOffset = Offset(_dragDx, _dragDy);
      _swipeEndOffset = Offset(forward ? -500.0 : 500.0, 0.0);
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
      _isDragging = true;
      _dragDx += details.delta.dx;
      _dragDy += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_swipeController.isAnimating) return;
    _isDragging = false;

    // Threshold to complete swipe
    const double threshold = 120.0;
    if (_dragDx.abs() > threshold) {
      // Swiped past threshold -> trigger swipe away
      setState(() {
        _swipeStartOffset = Offset(_dragDx, _dragDy);
        _swipeEndOffset = Offset(_dragDx > 0 ? 500.0 : -500.0, _dragDy);
        _swipeAnimation = Tween<Offset>(
          begin: _swipeStartOffset,
          end: _swipeEndOffset,
        ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
      });
      _swipeController.forward();
    } else {
      // Return to center
      final start = Offset(_dragDx, _dragDy);
      setState(() {
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
    final nextIndex = (_currentIndex + 1) % AiAvatar.avatars.length;
    final nextAvatar = AiAvatar.avatars[nextIndex];

    final isUpSelected = state.engineLevel == currentAvatar.id;
    final isDownSelected = state.bottomAvatarId == currentAvatar.id;

    // Maintain global keys to animate flips per persona card
    _cardKeys.putIfAbsent(currentAvatar.id, () => GlobalKey<FlippableCardState>());
    _cardKeys.putIfAbsent(nextAvatar.id, () => GlobalKey<FlippableCardState>());

    return AmbientScaffold(
      blob1Color: currentAvatar.color.withValues(alpha: 0.15),
      blob2Color: const Color(0xFFF3E8FF),
      blob3Color: const Color(0xFFEFF6FF),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Back Button (PERSONAS aligned to right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
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

                // Card Stack Area
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      constraints: const BoxConstraints(
                        maxWidth: 380,
                        maxHeight: 460,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Background card (Next Card Preview)
                          if (!_swipeController.isAnimating && !_isDragging)
                            Transform.translate(
                              offset: const Offset(0, 16),
                              child: Transform.scale(
                                scale: 0.94,
                                child: Opacity(
                                  opacity: 0.5,
                                  child: _buildStaticCard(nextAvatar),
                                ),
                              ),
                            ),
                          
                          // Top Draggable/Swipable Card
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
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Traits & Bio Section Below Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentAvatar.title.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: currentAvatar.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentAvatar.playingStyle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.4,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                      ],
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
          ),
        ],
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
        child: Image.asset(
          avatar.imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Frontend of the persona card
  Widget _buildCardFront(AiAvatar avatar, bool isUpActive, bool isDownActive) {
    final isLightColor = avatar.color.computeLuminance() > 0.6;
    
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
            Image.asset(
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

            // Bottom Name / Title Card Overlay (Dark Gradient)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          avatar.name,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          avatar.icon,
                          color: avatar.color,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      avatar.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to see details',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(avatar.imagePath),
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

                Text(
                  'ENGINE SPECIFICATIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: avatar.color,
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
                  label: 'Stockfish Skill Level',
                  value: '${avatar.skillLevel} / 20',
                ),
                const SizedBox(height: 10),
                _buildSpecRow(
                  icon: Icons.search_rounded,
                  label: 'Search Depth Limit',
                  value: '${avatar.depth} moves',
                ),
                
                const Spacer(),

                // Playing Style Label
                Text(
                  'PLAYING STYLE & BIO',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: avatar.color,
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

                const Spacer(),
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

  const FlippableCard({super.key, required this.front, required this.back});

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
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;
          final isFront = angle < math.pi / 2;

          // Calculate blur magnitude: peaks at midpoint (angle = pi/2, controller.value = 0.5)
          final double blurVal = math.sin(_controller.value * math.pi) * 6.0;

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
              ..rotateY(angle),
            alignment: Alignment.center,
            child: cardContent,
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
