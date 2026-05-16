import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/ai_avatar.dart';
import '../scholarly_theme.dart';

class OpponentAvatarIndicator extends StatefulWidget {
  final AiAvatar avatar;
  final VoidCallback? onTap;

  const OpponentAvatarIndicator({
    super.key,
    required this.avatar,
    this.onTap,
  });

  @override
  State<OpponentAvatarIndicator> createState() => _OpponentAvatarIndicatorState();
}

class _OpponentAvatarIndicatorState extends State<OpponentAvatarIndicator> {
  bool _isExpanded = false;
  Timer? _collapseTimer;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      _collapseTimer?.cancel();
      _collapseTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isExpanded = false;
          });
        }
      });
    } else {
      // If already expanded, trigger action or open Settings Page
      if (widget.onTap != null) {
        widget.onTap!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {


    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: _isExpanded ? 12 : 6,
          vertical: _isExpanded ? 8 : 6,
        ),
        decoration: ScholarlyTheme.modernDecoration().copyWith(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.avatar.color.withValues(alpha: _isExpanded ? 0.5 : 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.avatar.color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Styled Avatar Icon ring
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.avatar.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.avatar.color,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.avatar.imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Expanding Contents
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: _isExpanded
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          // Name & Subtitle
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.avatar.name,
                                    style: GoogleFonts.inter(
                                      color: ScholarlyTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified_rounded,
                                    color: widget.avatar.id == 'avatar_10' 
                                        ? ScholarlyTheme.accentBlue 
                                        : ScholarlyTheme.textMuted.withValues(alpha: 0.4),
                                    size: 12,
                                  ),
                                ],
                              ),
                              Text(
                                widget.avatar.title,
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // FIDE Rating Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ScholarlyTheme.textPrimary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: ScholarlyTheme.panelStroke,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'FIDE ${widget.avatar.fideRatingRange}',
                              style: GoogleFonts.jetBrainsMono(
                                color: ScholarlyTheme.accentBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
