import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import 'ambient_scaffold.dart';

/// Launches the professional glassmorphic overlay for custom profile editing.
void showProfileCustomizationOverlay(BuildContext context, WidgetRef ref) {
  final state = ref.read(chessProvider);

  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    barrierDismissible: true,
    barrierLabel: 'Dismiss Profile Editor',
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _ProfileCustomizerContent(
            initialName: state.userName,
            initialAvatarPath: state.userAvatarPath,
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      final curveValue = Curves.easeOutBack.transform(anim1.value);
      return Transform.translate(
        offset: Offset(0, 60 * (1 - curveValue)),
        child: Opacity(
          opacity: anim1.value,
          child: child,
        ),
      );
    },
  );
}

class _ProfileCustomizerContent extends ConsumerStatefulWidget {
  final String initialName;
  final String initialAvatarPath;

  const _ProfileCustomizerContent({
    required this.initialName,
    required this.initialAvatarPath,
  });

  @override
  ConsumerState<_ProfileCustomizerContent> createState() => _ProfileCustomizerContentState();
}

class _ProfileCustomizerContentState extends ConsumerState<_ProfileCustomizerContent> {
  late TextEditingController _nameController;
  late String _selectedAvatarPath;

  final List<Map<String, String>> _avatars = const [
    {'name': 'Bard', 'path': 'assets/persona/gm_bard.png'},
    {'name': 'Kingslayer', 'path': 'assets/persona/gm_kingslayer.png'},
    {'name': 'Morphy', 'path': 'assets/persona/gm_morphy.png'},
    {'name': 'Titan', 'path': 'assets/persona/gm_titan.png'},
    {'name': 'Blitzer', 'path': 'assets/persona/blitzer.png'},
    {'name': 'Gambit', 'path': 'assets/persona/gambit.png'},
    {'name': 'Rook-ie', 'path': 'assets/persona/rook-ie.png'},
    {'name': 'Sentinel', 'path': 'assets/persona/sentinel.png'},
    {'name': 'Sparky', 'path': 'assets/persona/sparky.png'},
    {'name': 'Stonewall', 'path': 'assets/persona/stonewall.png'},
    {'name': 'Vanguard', 'path': 'assets/persona/vanguard.png'},
    {'name': 'Pawnzy', 'path': 'assets/persona/pawnzy.png'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedAvatarPath = widget.initialAvatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: JuicyGlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EDIT PROFILE',
                  style: GoogleFonts.outfit(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: ScholarlyTheme.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Selected Avatar Preview
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ScholarlyTheme.accentBlue,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _selectedAvatarPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: ScholarlyTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name input
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'PLAYER USERNAME',
                labelStyle: GoogleFonts.inter(
                  color: ScholarlyTheme.accentBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.35),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ScholarlyTheme.accentBlue, width: 2.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),

            // Avatar list section
            Text(
              'SELECT CHESS ARCHETYPE',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Grid of Avatars
            SizedBox(
              height: 220,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final av = _avatars[index];
                  final isSelected = _selectedAvatarPath == av['path'];

                  return GestureDetector(
                    onTap: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      setState(() {
                        _selectedAvatarPath = av['path']!;
                      });
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? ScholarlyTheme.accentBlue : Colors.white.withValues(alpha: 0.5),
                                    width: isSelected ? 3.0 : 1.5,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    av['path']!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: ScholarlyTheme.accentBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          av['name']!,
                          style: GoogleFonts.inter(
                            color: isSelected ? ScholarlyTheme.textPrimary : ScholarlyTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save Action Button
            GestureDetector(
              onTap: () {
                final newName = _nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a username', style: GoogleFonts.inter()),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                ref.read(chessProvider.notifier).updateProfile(
                  name: newName,
                  avatarPath: _selectedAvatarPath,
                );

                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      ScholarlyTheme.accentBlue,
                      Color(0xFF5B21B6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'SAVE PROFILE',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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
}
