/// Glass body for ReadingGlassPanel — isolated from shimmer rebuilds.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/copy/transparency_copy.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import 'ai_reading_content.dart';
import 'reading_glass_section_list.dart';
import 'reading_or_orb.dart';

class ReadingGlassBody extends StatelessWidget {
  const ReadingGlassBody({
    super.key,
    required this.content,
    required this.sectionMaster,
    required this.useBackdrop,
  });

  final AiReadingContent content;
  final double sectionMaster;
  final bool useBackdrop;

  @override
  Widget build(BuildContext context) {
    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated.withValues(alpha: 0.94),
            AppColors.surface.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.gold.withValues(
            alpha: OraclySignatureMaterials.goldBorder,
          ),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const ReadingOrOrb(size: 32),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.isAiInterpretation
                            ? TarotPolishCopy.readingTitleAi
                            : TarotPolishCopy.readingTitleLocal,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        TransparencyCopy.interpretationBrief,
                        style: ReadingTypography.footnote(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            ReadingGlassSectionList(
              content: content,
              sectionMaster: sectionMaster,
            ),
          ],
        ),
      ),
    );
    if (!useBackdrop) return body;
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: OraclySignatureMaterials.blurChamber,
        sigmaY: OraclySignatureMaterials.blurChamber,
      ),
      child: body,
    );
  }
}
