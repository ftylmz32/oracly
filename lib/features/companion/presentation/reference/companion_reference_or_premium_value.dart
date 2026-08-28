/// Compact OR paywall commerce block — used by focused CTA tests.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../premium/presentation/reference/premium_reference_cta.dart';
import '../../copy/companion_copy.dart';

class CompanionReferenceOrPremiumValue extends StatelessWidget {
  const CompanionReferenceOrPremiumValue({
    super.key,
    required this.isPremium,
    required this.purchaseConfigured,
    required this.onPurchase,
    required this.onRestore,
    this.busy = false,
    this.compact = false,
  });

  final bool isPremium;
  final bool purchaseConfigured;
  final bool busy;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 0, 0, compact ? 8 : 0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            CompanionCopy.orPaywallHonesty,
            textAlign: TextAlign.center,
            style: ReadingTypography.bodySmall(
              color: OraclyChrome.cream.withValues(alpha: 0.62),
            ),
          ),
          SizedBox(height: AppSpacing.s16),
          PremiumReferenceCta(
            isPremium: isPremium,
            busy: busy,
            purchaseConfigured: purchaseConfigured,
            joinLabel: CompanionCopy.orPaywallCta,
            onActivate: onPurchase,
            onRestore: onRestore,
          ),
        ],
      ),
    );
  }
}
