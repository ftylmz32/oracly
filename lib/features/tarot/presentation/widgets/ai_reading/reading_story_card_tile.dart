/// Collapsed: name + short meaning. Expanded: Oracly detail.
library;

import 'package:flutter/material.dart';

import '../../../../../core/reading_ux/reading_expand_section.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../copy/tarot_polish_copy.dart';
import 'reading_sacred_rhythm.dart';

class ReadingStoryCardTile extends StatelessWidget {
  const ReadingStoryCardTile({
    super.key,
    required this.name,
    required this.position,
    required this.insight,
    required this.detail,
  });

  final String name;
  final String position;
  final String insight;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final summary = insight.trim();
    final body = detail.trim().isNotEmpty ? detail.trim() : summary;
    final slot = position.trim();
    final same = body == summary;
    return Padding(
      padding: EdgeInsets.only(bottom: ReadingSacredRhythm.betweenActs * 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (slot.isNotEmpty) ...[
            Text(slot, style: ReadingTypography.eyebrow(fontSize: 11)),
            SizedBox(height: AppSpacing.xs),
          ],
          Text(name, style: ReadingTypography.sectionTitle()),
          SizedBox(height: CraftsmanshipRhythm.afterTitle),
          if (summary.isNotEmpty && !same) ...[
            Text(
              TarotPolishCopy.coreMeaning,
              style: ReadingTypography.sectionLabel(
                color: ReadingTypography.eyebrow().color,
                fontSize: 11,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(summary, style: ReadingTypography.reflection()),
            SizedBox(height: CraftsmanshipRhythm.paragraphGap),
            ReadingExpandSection(
              title: TarotPolishCopy.positionMeaning,
              body: body,
            ),
          ] else
            ReadingExpandSection(body: body),
        ],
      ),
    );
  }
}
