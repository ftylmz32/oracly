/// Calm Premium entry — why it is Premium, never a hard “gerekli” wall.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/tarot/presentation/epic031/tarot_epic031_primary_button.dart';
import '../../../../shared/ui/oracly_bottom_sheet.dart';
import 'premium_unlock_list.dart';

abstract final class PremiumEntrySheet {
  PremiumEntrySheet._();

  static Future<void> show(BuildContext context) {
    return OraclyBottomSheet.show<void>(
      context,
      title: PremiumCopy.gateTitle,
      child: const PremiumEntryBody(popBeforeOpen: true),
    );
  }
}

class PremiumEntryBody extends StatelessWidget {
  const PremiumEntryBody({
    super.key,
    this.showCta = true,
    this.popBeforeOpen = false,
  });

  final bool showCta;
  final bool popBeforeOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            PremiumCopy.gateLead,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: OraclyChrome.cream.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          const PremiumUnlockList(compact: true),
          SizedBox(height: AppSpacing.md),
          Text(
            PremiumCopy.ctaUnavailable,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: OraclyChrome.goldLight.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
          if (showCta) ...[
            SizedBox(height: AppSpacing.md),
            TarotEpic031PrimaryButton(
              label: PremiumCopy.ctaExplore,
              onPressed: () {
                if (popBeforeOpen) Navigator.of(context).maybePop();
                OraclyNavigationService.openPremium(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}
