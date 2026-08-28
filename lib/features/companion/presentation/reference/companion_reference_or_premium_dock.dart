/// Free-user footer — quiet door into the OR paywall sheet.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../premium/presentation/reference/premium_reference_tokens.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_or_premium_sheet.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceOrPremiumDock extends StatelessWidget {
  const CompanionReferenceOrPremiumDock({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CompanionReferenceTokens.screenHorizontal,
        AppSpacing.s8,
        CompanionReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            CompanionCopy.orPaywallLead,
            textAlign: TextAlign.center,
            style: ReadingTypography.bodySmall(
              color: OraclyChrome.cream.withValues(alpha: 0.72),
            ),
          ),
          SizedBox(height: AppSpacing.s12),
          OraclyGoldButton(
            label: CompanionCopy.orPaywallCta,
            expanded: true,
            borderRadius: PremiumReferenceTokens.ctaRadius,
            onPressed: () => CompanionReferenceOrPremiumSheet.show(context),
          ),
        ],
      ),
    );
  }
}
