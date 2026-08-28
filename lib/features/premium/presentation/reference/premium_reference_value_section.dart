/// WHAT YOU GET / WHY IT MATTERS — value without a sales shout.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceValueSection extends StatelessWidget {
  const PremiumReferenceValueSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PremiumCopy.whatTitle,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(
            color: PremiumReferenceTokens.champagne,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          PremiumCopy.whatBody,
          textAlign: TextAlign.center,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          PremiumCopy.whyTitle,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(
            color: PremiumReferenceTokens.champagne,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          PremiumCopy.whyBody,
          textAlign: TextAlign.center,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.84),
          ),
        ),
      ],
    );
  }
}
