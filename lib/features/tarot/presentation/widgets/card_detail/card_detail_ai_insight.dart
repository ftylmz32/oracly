/// OR-1080 — OR AI insight glass container.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../ai_reading/reading_or_orb.dart';

class CardDetailAiInsight extends StatelessWidget {
  const CardDetailAiInsight({
    super.key,
    required this.insight,
    required this.entrance,
    required this.accent,
  });

  final String insight;
  final double entrance;
  final Color accent;

  static const String title = 'OR AI Yorumu';

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 20;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xl,
              boxShadow: [
                ...AppShadows.soft,
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: AppColors.glowPurple.withValues(alpha: 0.18),
                  blurRadius: 28,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.xl,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surfaceElevated.withValues(alpha: 0.94),
                        AppColors.surface.withValues(alpha: 0.86),
                      ],
                    ),
                    borderRadius: AppRadius.xl,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.32),
                      width: AppBorderWidth.hairline,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const ReadingOrOrb(size: 44),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                title,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          insight,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.62,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
