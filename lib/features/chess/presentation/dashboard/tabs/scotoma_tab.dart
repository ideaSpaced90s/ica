import 'package:flutter/material.dart';
import '../../widgets/ambient_scaffold.dart';
import '../../widgets/scotoma_card.dart';

class ScotomaTab extends StatelessWidget {
  final bool isMobile;

  const ScotomaTab({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JuicySectionHeader(
          title: 'SCOTOMA',
          icon: Icons.visibility_off_rounded,
        ),
        const SizedBox(height: 16),
        const ScotomaCard(),
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
