/// Membership plaque. A period is named only when the plan is verified.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/legal/legal_copy.dart';
import '../../../../core/theme/reading_typography.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceActiveBanner extends StatelessWidget {
  const PremiumReferenceActiveBanner({super.key, this.verifiedPlan});

  final PremiumPlanKind? verifiedPlan;

  @override
  Widget build(BuildContext context) {
    final detail = verifiedPlan == null
        ? PremiumCopy.membershipUnverified
        : LegalCopy.planDisclosure(verifiedPlan!);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: PremiumReferenceTokens.ctaRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A100C), Color(0xFF0A0608)],
        ),
        border: Border.all(
          color: OraclyChrome.goldLight.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          children: [
            Text(
              PremiumCopy.membershipOpen,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.94),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              PremiumCopy.activeBody,
              textAlign: TextAlign.center,
              style: ReadingTypography.secondary(
                color: OraclyChrome.cream.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(
                color: OraclyChrome.goldLight.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
