/// Cards in their positions — art dominant. No interpretation wall.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'ai_reading_content.dart';
import 'reading_arrive.dart';
import 'reading_sacred_rhythm.dart';
import 'reading_story_face.dart';

class ReadingStoryStrip extends StatelessWidget {
  const ReadingStoryStrip({
    super.key,
    required this.content,
    required this.progress,
    this.exitProgress = 0,
  });

  final AiReadingContent content;
  final double progress;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    final faces = ReadingStoryFaceSpec.of(content);
    final opacity = (progress * (1 - exitProgress)).clamp(0.0, 1.0);
    final gap = AppSpacing.md;
    final spread = (content.spreadLabel ?? '').trim();

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.only(
          top: ReadingSacredRhythm.afterCard,
          bottom: CraftsmanshipRhythm.betweenActs * 0.25,
        ),
        child: Column(
          children: [
            if (spread.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  spread,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.sectionLabel(fontSize: 10),
                ),
              ),
            if (faces.length == 1)
              Center(
                child: ReadingStoryArrive(
                  index: 0,
                  count: 1,
                  master: progress,
                  child: ReadingStoryFace(spec: faces.first, hero: true),
                ),
              )
            else
              SizedBox(
                height: ReadingStoryFace.stripHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: CraftsmanshipRhythm.scrollPhysics,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  itemCount: faces.length,
                  separatorBuilder: (context, index) => SizedBox(width: gap),
                  itemBuilder: (context, index) {
                    return ReadingStoryArrive(
                      index: index,
                      count: faces.length,
                      master: progress,
                      child: ReadingStoryFace(spec: faces[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
