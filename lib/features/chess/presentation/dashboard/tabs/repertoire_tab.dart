import 'package:flutter/material.dart';
import '../../widgets/ambient_scaffold.dart';
import '../../widgets/phase_analysis_widgets.dart';

class RepertoireTab extends StatelessWidget {
  final bool isMobile;

  const RepertoireTab({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JuicySectionHeader(
          title: 'REPERTOIRE',
          icon: Icons.auto_stories_rounded,
        ),
        const SizedBox(height: 16),
        const RepertoireCard(),
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
