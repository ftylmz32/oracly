/// OR-1090 — Achievement golden badge widget.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/achievement_models.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.compact = false,
  });

  final Achievement achievement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: unlocked
                    ? [
                        AppColors.gold.withValues(alpha: 0.22),
                        AppColors.surface.withValues(alpha: 0.82),
                      ]
                    : [
                        AppColors.surface.withValues(alpha: 0.72),
                        AppColors.primary.withValues(alpha: 0.5),
                      ],
              ),
              borderRadius: AppRadius.lg,
              border: Border.all(
                color: unlocked
                    ? AppColors.gold.withValues(alpha: 0.55)
                    : AppColors.gold.withValues(alpha: 0.15),
                width: unlocked ? AppBorderWidth.thin : AppBorderWidth.hairline,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: AppColors.goldGlow.withValues(alpha: 0.28),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 40 : 52,
                    height: compact ? 40 : 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: unlocked
                            ? [
                                AppColors.goldLight.withValues(alpha: 0.85),
                                AppColors.gold.withValues(alpha: 0.45),
                              ]
                            : [
                                AppColors.textHint.withValues(alpha: 0.3),
                                AppColors.primary,
                              ],
                      ),
                      border: Border.all(
                        color: AppColors.gold.withValues(
                          alpha: unlocked ? 0.5 : 0.2,
                        ),
                        width: AppBorderWidth.hairline,
                      ),
                    ),
                    child: Icon(
                      achievement.icon,
                      color: unlocked
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: compact ? 20 : 26,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    achievement.id.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: unlocked
                          ? AppColors.goldLight
                          : AppColors.textHint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!compact) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      achievement.id.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({
    super.key,
    required this.achievements,
    this.compact = false,
  });

  final List<Achievement> achievements;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 3 : 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: compact ? 0.85 : 0.92,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return AchievementBadge(
          achievement: achievements[index],
          compact: compact,
        );
      },
    );
  }
}
