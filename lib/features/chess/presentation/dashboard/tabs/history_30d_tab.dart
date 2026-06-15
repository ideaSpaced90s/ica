import 'package:flutter/material.dart';
import '../../widgets/ambient_scaffold.dart';
import '../../widgets/progression_charts.dart';

class History30DTab extends StatelessWidget {
  final bool isMobile;

  const History30DTab({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JuicySectionHeader(
          title: '30D',
          icon: Icons.calendar_today_rounded,
        ),
        const SizedBox(height: 16),
        const DominanceHeatmap(),
        const SizedBox(height: 32),
      ],
    );

    if (isMobile) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: body,
      );
    }
    return body;
  }
}
