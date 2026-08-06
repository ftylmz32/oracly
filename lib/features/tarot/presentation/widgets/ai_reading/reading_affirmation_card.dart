/// OR-301 — Golden affirmation card with soft glow.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/reading_section_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'reading_flow_text.dart';
import 'reading_premium_animations.dart';

class ReadingAffirmationCard extends StatelessWidget {
  const ReadingAffirmationCard({
    super.key,
    required this.text,
    required this.index,
    required this.master,
    this.exitProgress = 0,
  });

  final String text;
  final int index;
  final double master;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    final progress = readingPremiumReflectionProgress(index, master);
    final slide = (1 - progress) * 14;

    return Opacity(
      opacity: (progress * (1 - exitProgress)).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide + exitProgress * 14),
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: RepaintBoundary(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lg,
                color: AppColors.surface.withValues(alpha: 0.38),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.10),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    ReadingSectionCopy.questionPrompt,
                    style: ReadingTypography.sectionLabel(
                      color: AppColors.goldLight.withValues(alpha: 0.72),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Icon(
                    Icons.format_quote_rounded,
                    size: 22,
                    color: AppColors.gold.withValues(alpha: 0.48),
                  ),
                  SizedBox(height: AppSpacing.md),
                  ReadingFlowText(
                    text: text,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.reflection(
                      color: AppColors.goldLight.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
