/// Editorial earlier → recent comparison with a gold spine.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../personal_discovery/models/theme_over_time_comparison.dart';
import '../../copy/discovery_journal_over_time_copy.dart';
import 'discovery_journal_over_time_node.dart';

class DiscoveryJournalOverTimeTimeline extends StatelessWidget {
  const DiscoveryJournalOverTimeTimeline({
    super.key,
    required this.comparison,
  });

  final ThemeOverTimeComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 18,
              child: CustomPaint(
                painter: const _OverTimeSpinePainter(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiscoveryJournalOverTimeNode(
                    label: DiscoveryJournalOverTimeCopy.earlierLabel,
                    window: comparison.earlier,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  DiscoveryJournalOverTimeNode(
                    label: DiscoveryJournalOverTimeCopy.recentLabel,
                    window: comparison.recent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverTimeSpinePainter extends CustomPainter {
  const _OverTimeSpinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const topNode = 18.0;
    const bottomNode = 86.0;
    final line = Paint()
      ..color = OraclyChrome.gold.withValues(alpha: 0.42)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, topNode), Offset(x, bottomNode), line);
    for (final y in [topNode, bottomNode]) {
      canvas.drawCircle(
        Offset(x, y),
        3.1,
        Paint()..color = OraclyChrome.gold.withValues(alpha: 0.88),
      );
    }
  }

  @override
  bool shouldRepaint(_OverTimeSpinePainter old) => false;
}
