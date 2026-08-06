/// OR-030 — Premium tarot screen header.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Tarot home header — menu, title, premium gem counter.
class TarotSelectHeader extends StatelessWidget {
  const TarotSelectHeader({super.key});

  static const String _title = 'Tarot Açılımı';
  static const String _gemCount = '120';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.menu_rounded,
            semanticLabel: 'Menü',
          ),
          Expanded(
            child: Text(
              _title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const _PremiumGemCounter(count: _gemCount),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
  });

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: AppSpacing.xxl + AppSpacing.sm,
        height: AppSpacing.xxl + AppSpacing.sm,
        child: Icon(
          icon,
          size: AppSpacing.md + AppSpacing.xs,
          color: AppColors.icon,
        ),
      ),
    );
  }
}

class _PremiumGemCounter extends StatelessWidget {
  const _PremiumGemCounter({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        color: AppColors.surface.withValues(alpha: 0.88),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.32),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm + AppSpacing.xs,
          AppSpacing.xs + 2,
          AppSpacing.xs,
          AppSpacing.xs + 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diamond_rounded,
              size: AppSpacing.md,
              color: AppColors.purpleLight,
            ),
            SizedBox(width: AppSpacing.xs + 2),
            Text(
              count,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.gold],
                ),
                boxShadow: AppShadows.iconGlow,
              ),
              child: SizedBox(
                width: AppSpacing.lg + AppSpacing.xs,
                height: AppSpacing.lg + AppSpacing.xs,
                child: Icon(
                  Icons.add_rounded,
                  size: AppSpacing.md,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reading screen header — preserved for tarot reading flow.
class TarotReadingHeader extends StatelessWidget {
  const TarotReadingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.xxl + AppSpacing.sm,
            height: AppSpacing.xxl + AppSpacing.sm,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.goldLight,
              size: AppSpacing.md,
            ),
          ),
          Expanded(
            child: Text(
              'Tarot Yorumu',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.purpleLight.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleGlow,
                  blurRadius: AppShadowMetrics.iconBlur,
                ),
              ],
            ),
            child: SizedBox(
              width: AppSpacing.xl + AppSpacing.xs,
              height: AppSpacing.xl + AppSpacing.xs,
              child: Icon(
                Icons.diamond_rounded,
                size: AppSpacing.md,
                color: AppColors.purpleLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
