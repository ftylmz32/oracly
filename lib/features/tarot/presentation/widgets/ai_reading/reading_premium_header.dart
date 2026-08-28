/// Question only — cards follow; spread name sits with the reveal strip.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../reading/reading_question.dart';
import 'ai_reading_content.dart';
import 'reading_premium_animations.dart';

class ReadingPremiumHeader extends StatelessWidget {
  const ReadingPremiumHeader({
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
    final question = ReadingQuestion.real(content.userQuestion);
    final fallback = (content.spreadLabel ?? content.cardName).trim();
    final text = question ??
        (fallback.isNotEmpty ? fallback : TarotPolishCopy.generalTitle);
    final appear = readingPremiumHeaderProgress(progress);
    final opacity = (appear * (1 - exitProgress)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, (1 - appear) * 10 + exitProgress * 8),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            CraftsmanshipRhythm.afterTitle,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: question != null
                ? ReadingTypography.title()
                : ReadingTypography.sectionLabel(),
          ),
        ),
      ),
    );
  }
}
