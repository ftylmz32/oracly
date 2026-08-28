/// ÖNCE / ŞİMDİ panels with observational synthesis.
library;

import 'package:flutter/material.dart';

import '../../../design_system/oracly_chrome.dart';
import '../../../design_system/oracly_glass_card.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/reading_typography.dart';
import '../../../../features/discovery_journal/models/discovery_journal_kind.dart';
import '../../../../features/discovery_journal/presentation/widgets/discovery_journal_badge.dart';
import '../../copy/discovery_comparison_copy.dart';
import '../../models/discovery_comparison_kind.dart';
import '../../models/discovery_comparison_result.dart';
import '../../models/discovery_comparison_snapshot.dart';

class DiscoveryComparisonBody extends StatelessWidget {
  const DiscoveryComparisonBody({super.key, required this.result});

  final DiscoveryComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final badgeKind = _badgeKind(result.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 18,
                child: CustomPaint(
                  painter: const _ComparisonSpinePainter(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Panel(
                      label: DiscoveryComparisonCopy.before,
                      snapshot: result.earlier,
                      badgeKind: badgeKind,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    _Panel(
                      label: DiscoveryComparisonCopy.now,
                      snapshot: result.later,
                      badgeKind: badgeKind,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s16),
          child: OraclyGlassCard(
            premium: true,
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Text(
              result.synthesis,
              style: ReadingTypography.reflection(
                color: OraclyChrome.cream.withValues(alpha: 0.84),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DiscoveryJournalKind _badgeKind(DiscoveryComparisonKind kind) =>
      switch (kind) {
        DiscoveryComparisonKind.tarot => DiscoveryJournalKind.tarot,
        DiscoveryComparisonKind.dailyMessage =>
          DiscoveryJournalKind.dailyMessage,
        DiscoveryComparisonKind.starMap => DiscoveryJournalKind.starMap,
        DiscoveryComparisonKind.astrology => DiscoveryJournalKind.astrology,
        DiscoveryComparisonKind.companion => DiscoveryJournalKind.companion,
      };
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.label,
    required this.snapshot,
    required this.badgeKind,
  });

  final String label;
  final DiscoveryComparisonSnapshot snapshot;
  final DiscoveryJournalKind badgeKind;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            DiscoveryJournalBadge(kind: badgeKind),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                snapshot.dateLabel,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          snapshot.title,
          style: ReadingTypography.bodyCore(
            color: OraclyChrome.cream.withValues(alpha: 0.92),
          ),
        ),
        if (snapshot.preview.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            snapshot.preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );
  }
}

class _ComparisonSpinePainter extends CustomPainter {
  const _ComparisonSpinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const topNode = 18.0;
    const bottomNode = 120.0;
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
  bool shouldRepaint(_ComparisonSpinePainter old) => false;
}
