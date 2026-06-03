import 'dart:ui';
import 'package:flutter/material.dart';
import 'ambient_flow_backdrop.dart';

/// A drop-in Scaffold replacement that automatically adds the aurora blob
/// backdrop behind any page. Accepts optional custom blob colors for
/// per-screen visual identity while maintaining a cohesive aurora system.
class AmbientScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  // Optional per-screen palette
  final Color blob1Color;
  final Color blob2Color;
  final Color blob3Color;

  // Standard Scaffold forwarding
  final bool extendBodyBehindAppBar;
  final bool extendBody;

  const AmbientScaffold({
    super.key,
    required this.body,
    this.drawer,
    this.scaffoldKey,
    this.blob1Color = const Color(0xFFDBEAFE),
    this.blob2Color = const Color(0xFFFEF3C7),
    this.blob3Color = const Color(0xFFF3E8FF),
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: drawer,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      body: Stack(
        children: [
          // Aurora backdrop — always at the bottom
          Positioned.fill(
            child: AmbientFlowBackdrop(
              blob1Color: blob1Color,
              blob2Color: blob2Color,
              blob3Color: blob3Color,
            ),
          ),
          // Page content on top
          body,
        ],
      ),
    );
  }
}

/// A frosted-glass panel used across all modernized pages.
/// Wraps any child in a BackdropFilter + translucent white container.
class JuicyGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final Color? backgroundColor;

  const JuicyGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 16,
    this.borderColor,
    this.shadows,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A section header chip — small all-caps label in a glass pill.
class JuicySectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;

  const JuicySectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient = const LinearGradient(
      colors: [
        Color(0xFF0D6EFD), // Primary blue
        Color(0xFFEC4899), // Hot Pink/Magenta
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final grad = gradient ?? (color == null ? defaultGradient : null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          if (grad != null)
            ShaderMask(
              shaderCallback: (bounds) => grad.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            )
          else
            Icon(icon, size: 14, color: color ?? const Color(0xFF0D6EFD)),
          const SizedBox(width: 8),
        ],
        if (grad != null)
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => grad.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          )
        else
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color ?? const Color(0xFF0D6EFD),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
      ],
    );
  }
}
