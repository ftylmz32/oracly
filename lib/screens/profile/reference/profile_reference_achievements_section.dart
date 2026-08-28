/// Reference achievements list section.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/domain/models/achievement.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_section_title.dart';
import 'profile_reference_card_shell.dart';
import 'profile_reference_tokens.dart';
import 'profile_surface_weight.dart';

class ProfileReferenceAchievementsSection extends StatelessWidget {
  const ProfileReferenceAchievementsSection({
    super.key,
    required this.achievements,
    this.onAchievementTap,
    this.onViewAllTap,
  });

  final List<AchievementModel> achievements;
  final ValueChanged<AchievementModel>? onAchievementTap;
  final VoidCallback? onViewAllTap;

  static const String _sectionTitle = 'BAŞARIMLAR';

  @override
  Widget build(BuildContext context) {
    final visible = achievements.take(2).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OraclySectionTitle(
          label: _sectionTitle,
          tracking: 2.8,
          fontSize: 11,
          showDivider: false,
        ),
        SizedBox(height: ProfileReferenceTokens.sectionLabelToContent),
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0)
            SizedBox(height: ProfileReferenceTokens.achievementItemGap),
          _AchievementRow(
            achievement: visible[i],
            onTap: onAchievementTap == null
                ? null
                : () => onAchievementTap!(visible[i]),
          ),
        ],
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, this.onTap});

  final AchievementModel achievement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.utility,
      height: ProfileReferenceTokens.achievementCardHeight,
      borderRadius: ProfileReferenceTokens.achievementRadius,
      padding: ProfileReferenceTokens.settingsPadding,
      onTap: onTap,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ProfileReferenceTokens.statRadius,
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.22),
                  AppColors.surfaceElevated.withValues(alpha: 0.48),
                ],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
            ),
            child: SizedBox(
              width: ProfileReferenceTokens.settingsIconWell,
              height: ProfileReferenceTokens.settingsIconWell,
              child: Icon(
                achievement.icon,
                size: 18,
                color: palette.goldLight.withValues(
                  alpha: achievement.unlocked ? 0.92 : 0.45,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.title,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: OraclyChrome.cream.withValues(alpha: 0.92),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: AppTextStyles.caption.copyWith(
                    height: 1.1,
                    color: OraclyChrome.cream.withValues(alpha: 0.68),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: palette.goldLight.withValues(alpha: 0.72),
          ),
        ],
      ),
    );
  }
}
