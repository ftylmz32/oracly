/// Opening story paragraph — reflective journal, not metrics.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../discovery_journal/presentation/widgets/discovery_archive_heading.dart';
import '../../copy/my_story_copy.dart';
import '../../models/personal_story.dart';

class MyStoryNarrative extends StatelessWidget {
  const MyStoryNarrative({super.key, required this.story});

  final PersonalStory story;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoveryArchiveHeading(label: MyStoryCopy.title, top: 0),
        OraclyGlassCard(
          premium: true,
          borderRadius: OraclyChrome.heroRadius,
          glowStrength: 0.80,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.narrative,
                style: ReadingTypography.reflection(
                  color: OraclyChrome.cream.withValues(alpha: 0.88),
                ),
              ),
              if (story.sourcesLine != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s12),
                  child: Text(
                    MyStoryCopy.sourcesLine(story.sourcesLine!),
                    style: ReadingTypography.footnote(
                      color: OraclyChrome.cream.withValues(alpha: 0.52),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s12),
                child: Text(
                  MyStoryCopy.footnote,
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.cream.withValues(alpha: 0.46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
