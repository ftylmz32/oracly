/// Compact account links from Premium — gems + daily rewards.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../gems/copy/gems_copy.dart';
import 'review_access_sheet.dart';

class PremiumReferenceLinks extends StatelessWidget {
  const PremiumReferenceLinks({super.key});

  @override
  Widget build(BuildContext context) {
    // Spacing separates the links; a separator glyph was left dangling at
    // the end of a wrapped line at narrow widths and large text.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 0,
      children: [
        _Link(
          label: GemsCopy.openGemsAction,
          onTap: () => OraclyNavigationService.openGems(context),
        ),
        _Link(
          label: OraclyL10n.t(L10nKeys.dailyRewardsTitle),
          onTap: () => OraclyNavigationService.openDailyRewards(context),
        ),
        _Link(
          label: OraclyL10n.t(L10nKeys.privacy),
          onTap: () => OraclyNavigationService.openPrivacy(context),
        ),
        _Link(
          label: OraclyL10n.t('premium.review_access'),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.goldLight.withValues(alpha: 0.86),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
