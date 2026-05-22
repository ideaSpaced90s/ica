import 'package:flutter/services.dart';
import 'dart:async';

/// Service to handle custom haptic feedback patterns for the IdeaSpace Chess Academy chess engine.
class ChessHapticsService {
  bool isEnabled = true;

  /// Updates the service settings.
  void updateSettings({required bool hapticsEnabled}) {
    isEnabled = hapticsEnabled;
  }

  /// A subtle haptic pulse for selecting a piece or navigation.
  Future<void> selection() async {
    if (!isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// A light tap for standard piece moves.
  Future<void> softTap() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// A heavy impact for captures or major piece movements (Rook/Queen).
  Future<void> heavyRook() async {
    if (!isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// A rhythmic double-pulse to signal the King is in check.
  Future<void> checkPulse() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.lightImpact();
  }

  /// An intense escalating burst for the final blow (Checkmate).
  Future<void> mateBurst() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
  }

  /// A quick double-tap to indicate an illegal move or error.
  Future<void> errorFeedback() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// A subtle heartbeat pulse for low time situations.
  Future<void> heartbeat() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 400));
    await HapticFeedback.lightImpact();
  }
}
