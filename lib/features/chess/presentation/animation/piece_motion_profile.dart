import 'package:flutter/animation.dart';

/// Lightweight, per-piece motion identity configuration.
///
/// A pure-data class with zero Flutter widget tree cost.
/// All values are dimensionless modifiers consumed by the animation pipeline.
/// Theme-agnostic — applies on top of (not replacing) any board theme.
class PieceMotionProfile {
  /// Total duration of the glide movement. Capped at 800ms.
  final Duration moveDuration;

  /// The easing curve applied to the main glide movement.
  /// This is layered on top of the theme-specific curve already selected
  /// by [SignatureMoveOverlay] for board theme compatibility.
  final Curve moveCurve;

  /// Vertical arc lift factor during movement.
  /// 0.0 = perfectly flat, 1.0 = very high arc.
  /// Used as a multiplier against squareSize.
  final double verticalArcFactor;

  /// Mid-move rotation tilt in degrees (applied at peak of arc).
  /// 0.0 = no tilt. Max practical value: 3.0°.
  final double midRotationDeg;

  /// Whether to render a faint opacity ghost trail during movement.
  /// Currently: Bishop only.
  final bool hasGhostTrail;

  /// Whether the piece uses a teleport (blink) animation instead of a glide.
  final bool isTeleport;

  /// Scale factor applied at the moment of landing (compression amount).
  /// 0.0 = no compression, 0.015 = 1.5% compress, applied briefly then spring back.
  final double landingCompression;

  /// Whether the piece has a subtle scale-breathing effect when selected.
  final bool hasBreathingSelection;

  /// Amount of scale added during breathing cycle (e.g. 0.015 = 1.5% variation).
  final double selectionBreathScale;

  /// Duration of one full breathing cycle (in → out).
  final Duration breathingPeriod;

  /// Height in logical pixels the piece floats when selected.
  /// Range: 2.0 (heavy/King) to 4.5 (light/Bishop).
  final double levitationHeight;

  const PieceMotionProfile({
    required this.moveDuration,
    required this.moveCurve,
    required this.verticalArcFactor,
    required this.midRotationDeg,
    required this.hasGhostTrail,
    required this.isTeleport,
    required this.landingCompression,
    required this.hasBreathingSelection,
    required this.selectionBreathScale,
    required this.breathingPeriod,
    required this.levitationHeight,
  });

  // ────────────────────────────────────────────────────────────────────────
  // Piece Identities
  // ────────────────────────────────────────────────────────────────────────

  /// ♟ Pawn — Direct & Persistent
  /// Fast, flat, linear glide. No flourish. Slight overshoot feel from curve.
  static const PieceMotionProfile pawn = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 450),
    moveCurve: Curves.easeInOutCubic,
    verticalArcFactor: 0.05,    // almost flat
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.010,  // tiny 1% compress for a quick thud
    hasBreathingSelection: true,
    selectionBreathScale: 0.012,
    breathingPeriod: Duration(milliseconds: 1200),
    levitationHeight: 3.0,
  );

  /// ♞ Knight — Agile & Tactical
  /// Slight arc feel, micro rotation mid-move, firm stop.
  static const PieceMotionProfile knight = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 500),
    moveCurve: Curves.easeInOutBack,
    verticalArcFactor: 0.3,     // noticeable arc (knight jumps)
    midRotationDeg: 2.5,        // degree tilt mid-air
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.0,    // firm, no compress
    hasBreathingSelection: true,
    selectionBreathScale: 0.015,
    breathingPeriod: Duration(milliseconds: 1100),
    levitationHeight: 4.0,
  );

  /// ♝ Bishop — Smooth & Continuous
  /// Ultra-smooth glide, ghost opacity trail, clean stop.
  static const PieceMotionProfile bishop = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 550),
    moveCurve: Curves.easeInOutSine,
    verticalArcFactor: 0.0,     // perfectly flat diagonal glide
    midRotationDeg: 0.0,
    hasGhostTrail: true,        // ← Bishop signature
    isTeleport: false,
    landingCompression: 0.0,    // absolutely clean stop
    hasBreathingSelection: true,
    selectionBreathScale: 0.010,
    breathingPeriod: Duration(milliseconds: 1500),
    levitationHeight: 4.5,      // floats highest — effortless
  );

  /// ♜ Rook — Heavy & Grounded
  /// Slow to start (strong ease-in), heavier deceleration, micro compress on land.
  static const PieceMotionProfile rook = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 600),
    moveCurve: Curves.easeInOutQuart, // strong in, gradual out = heavy feel
    verticalArcFactor: 0.0,     // strictly horizontal/vertical — no drift
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.015,  // 1.5% compress — feels heavy landing
    hasBreathingSelection: true,
    selectionBreathScale: 0.008, // barely breathes — stable presence
    breathingPeriod: Duration(milliseconds: 1400),
    levitationHeight: 2.5,      // barely lifts — heavy
  );

  /// ♛ Queen — Dominant & Fluid
  /// fastest mover, confident glide, clean minimal settle.
  /// Now features a unique "Teleport" blink signature.
  static const PieceMotionProfile queen = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 1600), // 400ms per hop (A -> B -> A -> B)
    moveCurve: Curves.linear,
    verticalArcFactor: 0.0,
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: true,           // ← Queen signature
    landingCompression: 0.0,
    hasBreathingSelection: true,
    selectionBreathScale: 0.018, // most visible breath — dominant
    breathingPeriod: Duration(milliseconds: 1000),
    levitationHeight: 4.0,
  );

  /// ♚ King — Deliberate & Fragile
  /// Slowest. Noticeable ease-in (anticipation feel via curve). Gentle settle.
  static const PieceMotionProfile king = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 900), // increased from 700ms
    moveCurve: Curves.easeInOutQuad,  // gentle, cautious acceleration
    verticalArcFactor: 0.05,
    midRotationDeg: 0.0,
    hasGhostTrail: false,
    isTeleport: false,
    landingCompression: 0.020,  // increased from 0.003 — heavy settle
    hasBreathingSelection: true,
    selectionBreathScale: 0.020, // most visible — signals importance
    breathingPeriod: Duration(milliseconds: 1300),
    levitationHeight: 2.0,      // lowest float — cautious
  );

  // ────────────────────────────────────────────────────────────────────────
  // Lookup
  // ────────────────────────────────────────────────────────────────────────

  /// Returns the motion profile for a given piece code (e.g. 'wK', 'bN', 'P').
  /// The code is the string used throughout ChessPieceWidget.
  /// Accepts both raw type letter ('K', 'N') and prefixed codes ('wK', 'bR').
  static PieceMotionProfile forCode(String code) {
    // Strip color prefix if present
    final type = code.length > 1 ? code.substring(1).toUpperCase() : code.toUpperCase();
    switch (type) {
      case 'K': return king;
      case 'Q': return queen;
      case 'R': return rook;
      case 'B': return bishop;
      case 'N': return knight;
      case 'P': return pawn;
      default:  return pawn; // safe fallback
    }
  }
}
