/// History result — the same revealed story as the live reading.
library;

import 'package:flutter/material.dart';

import 'ai_reading_content.dart';
import 'reading_premium_header.dart';
import 'reading_premium_sections.dart';
import 'reading_story_strip.dart';

class ReadingGlassSectionList extends StatelessWidget {
  const ReadingGlassSectionList({
    super.key,
    required this.content,
    required this.sectionMaster,
  });

  final AiReadingContent content;
  final double sectionMaster;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReadingPremiumHeader(
          content: content,
          progress: sectionMaster,
        ),
        ReadingStoryStrip(
          content: content,
          progress: sectionMaster,
        ),
        ReadingPremiumSections(
          content: content,
          sectionMaster: sectionMaster,
          ambientPhase: 0,
          exitProgress: 0,
        ),
      ],
    );
  }
}
