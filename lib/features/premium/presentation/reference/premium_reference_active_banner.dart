/// Calm plaque shown when Premium is already active.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceActiveBanner extends StatelessWidget {
  const PremiumReferenceActiveBanner({super.key});

  static const _velvet = Color(0xFF1A100C);
  static const _ink = Color(0xFF0A0608);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: PremiumReferenceTokens.ctaRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_velvet, _ink],
        ),
        border: Border.all(
          color: OraclyChrome.goldLight.withValues(alpha: 0.36),
          width: 1.05,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: PremiumReferenceTokens.ctaPadding,
        child: Column(
          children: [
            Text(
              OraclyL10n.t('premium.status_active_label'),
              textAlign: TextAlign.center,
              style: ReadingTypography.sectionLabel(fontSize: 10).copyWith(
                letterSpacing: CraftsmanshipRhythm.sectionLabelTracking + 0.8,
                color: OraclyChrome.goldPrimary.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              PremiumCopy.ctaActive,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.90),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
