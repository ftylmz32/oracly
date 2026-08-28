/// Dream result hero — user narrative + editorial theme lead.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream.dart';
import '../../models/dream_insight.dart';
import '../../services/dream_reading_presentation.dart';

class DreamResultHero extends StatelessWidget {
  const DreamResultHero({super.key, required this.dream});

  final Dream? dream;

  @override
  Widget build(BuildContext context) {
    final sections = DreamReadingPresentation.sections(dream);
    DreamReadingSection? summary;
    for (final s in sections) {
      if (s.kind == DreamInsightKind.summary) {
        summary = s;
        break;
      }
    }
    final narrative = dream?.narrative.trim() ?? '';
    final themeTitle = summary?.title ?? DreamCopy.summaryTitle;
    final themeBody = summary?.body ?? '';
    final showNarrative =
        narrative.isNotEmpty && narrative != themeBody && themeBody.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclyChrome.violet.withValues(alpha: 0.08),
            const Color(0xFF08060C).withValues(alpha: 0.90),
          ],
        ),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.14),
          width: 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.nights_stay_outlined,
                  size: 16,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 8),
                Text(
                  DreamCopy.screenTitle.toUpperCase(),
                  style: ReadingTypography.sectionLabel(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (showNarrative) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                DreamCopy.narrativeHelper,
                style: ReadingTypography.micro(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                narrative,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.82),
                ).copyWith(
                  height: CraftsmanshipRhythm.bodyLineHeight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else if (narrative.isNotEmpty && themeBody.isEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                narrative,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.86),
                ).copyWith(height: CraftsmanshipRhythm.bodyLineHeight),
              ),
            ],
            if (themeBody.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                themeTitle,
                style: ReadingTypography.title(
                  color: OraclyChrome.cream.withValues(alpha: 0.96),
                ).copyWith(fontSize: 20, height: 1.28),
              ),
              const SizedBox(height: 8),
              Text(
                themeBody,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.88),
                ).copyWith(height: CraftsmanshipRhythm.bodyLineHeight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
