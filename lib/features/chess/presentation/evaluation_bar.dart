import 'package:flutter/material.dart';

class EvaluationBar extends StatelessWidget {
  final double evaluation; // Centipawn score / 100
  final bool isFlipped;
  final Axis orientation;

  const EvaluationBar({
    super.key,
    required this.evaluation,
    this.isFlipped = false,
    this.orientation = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    // Score normalized to 0.0 - 1.0 (0.5 is equal, 1.0 is White wins, 0.0 is Black wins)
    final double score = ((evaluation.clamp(-5.0, 5.0) + 5.0) / 10.0);

    final bool isWhiteWinning = score > 0.5;
    final bool isBlackWinning = score < 0.5;

    return Container(
      height: orientation == Axis.horizontal ? 4 : double.infinity,
      width: orientation == Axis.horizontal ? double.infinity : 4,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(2),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: orientation == Axis.horizontal
            ? Row(
                key: ValueKey(score),
                children: _buildSegments(score, isWhiteWinning, isBlackWinning),
              )
            : Column(
                key: ValueKey(score),
                children: _buildSegments(score, isWhiteWinning, isBlackWinning),
              ),
      ),
    );
  }

  List<Widget> _buildSegments(
    double score,
    bool isWhiteWinning,
    bool isBlackWinning,
  ) {
    // If board is flipped, the logic might need to be inverted for vertical bar
    // Standard: White is bottom, Black is top.
    final List<Widget> segments = [];

    if (orientation == Axis.horizontal) {
      if (isWhiteWinning) {
        segments.add(
          Expanded(
            flex: (score * 100).round(),
            child: Container(color: Colors.white),
          ),
        );
        segments.add(
          Expanded(
            flex: ((1.0 - score) * 100).round(),
            child: Container(color: Colors.black38),
          ),
        );
      } else {
        segments.add(
          Expanded(
            flex: (score * 100).round(),
            child: Container(color: Colors.black38),
          ),
        );
        segments.add(
          Expanded(
            flex: ((1.0 - score) * 100).round(),
            child: Container(color: Colors.black),
          ),
        );
      }
    } else {
      // Vertical: Top is Black, Bottom is White by default
      // If white is winning (score > 0.5), bottom (white) segment should be larger.
      // In a Column, first item is TOP.
      if (isFlipped) {
        // Flipped: White is TOP, Black is BOTTOM
        segments.add(
          Expanded(
            flex: (score * 100).round(),
            child: Container(color: Colors.white),
          ),
        );
        segments.add(
          Expanded(
            flex: ((1.0 - score) * 100).round(),
            child: Container(color: Colors.black),
          ),
        );
      } else {
        // Standard: Black is TOP, White is BOTTOM
        segments.add(
          Expanded(
            flex: ((1.0 - score) * 100).round(),
            child: Container(color: Colors.black),
          ),
        );
        segments.add(
          Expanded(
            flex: (score * 100).round(),
            child: Container(color: Colors.white),
          ),
        );
      }
    }
    return segments;
  }
}
