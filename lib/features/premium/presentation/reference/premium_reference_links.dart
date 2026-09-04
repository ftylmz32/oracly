/// Compact account links from Premium — gems + daily rewards.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../daily_rewards/copy/daily_rewards_copy.dart';
import '../../../gems/copy/gems_copy.dart';
import 'review_access_sheet.dart';

class PremiumReferenceLinks extends StatelessWidget {
  const PremiumReferenceLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        _Link(
          label: GemsCopy.openGemsAction,
          onTap: () => OraclyNavigationService.openGems(context),
        ),
        Text(
          '·',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gold.withValues(alpha: 0.55),
          ),
        ),
        _Link(
          label: DailyRewardsCopy.screenTitle,
          onTap: () => OraclyNavigationService.openDailyRewards(context),
        ),
        Text(
          '·',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gold.withValues(alpha: 0.55),
          ),
        ),
        _Link(
          label: OraclyL10n.t(L10nKeys.privacy),
          onTap: () => OraclyNavigationService.openPrivacy(context),
        ),
        Text(
          '·',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gold.withValues(alpha: 0.55),
          ),
        ),
        _Link(
          label: 'Review access',
          onTap: () => ReviewAccessSheet.show(context),
        ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.goldLight.withValues(alpha: 0.86),
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
