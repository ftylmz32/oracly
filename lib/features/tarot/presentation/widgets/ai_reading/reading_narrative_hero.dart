/// Full primary Narrative — never condensed (Phase 7E hero).
library;

import 'package:flutter/material.dart';

import '../../../../../core/design_system/oracly_chrome.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../../core/theme/reading_flow_text.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../copy/tarot_polish_copy.dart';

class ReadingNarrativeHero extends StatelessWidget {
  const ReadingNarrativeHero({
    super.key,
    required this.body,
    this.opening = '',
  });

  final String body;
  final String opening;

  @override
  Widget build(BuildContext context) {
    final primary = body.trim();
    final lead = opening.trim();
    if (primary.isEmpty && lead.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: CraftsmanshipRhythm.betweenActs * 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lead.isNotEmpty) ...[
            Text(
              TarotPolishCopy.overviewTitle,
              style: ReadingTypography.sectionLabel(
                color: OraclyChrome.goldLight.withValues(alpha: 0.88),
              ),
            ),
            SizedBox(height: CraftsmanshipRhythm.afterTitle),
            ReadingFlowText(
              text: lead,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.90),
              ),
            ),
            SizedBox(height: CraftsmanshipRhythm.betweenSections),
          ],
          Text(
            TarotPolishCopy.storyTitle,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight.withValues(alpha: 0.90),
            ),
          ),
          SizedBox(height: CraftsmanshipRhythm.afterTitle + AppSpacing.xs),
          if (primary.isNotEmpty)
            ReadingFlowText(
              text: primary,
              emphasizeFirst: true,
              style: ReadingTypography.bodyCore(
                color: OraclyChrome.cream.withValues(alpha: 0.96),
              ),
            ),
        ],
      ),
    );
  }
}
