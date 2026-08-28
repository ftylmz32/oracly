/// Premium membership CTA — one primary door when store is real.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'premium_reference_cta_unavailable.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceCta extends StatelessWidget {
  const PremiumReferenceCta({
    super.key,
    required this.isPremium,
    this.onActivate,
    this.onRestore,
    this.busy = false,
    this.purchaseConfigured = false,
    this.joinLabel,
  });

  final bool isPremium;
  final VoidCallback? onActivate;
  final VoidCallback? onRestore;
  final bool busy;
  final bool purchaseConfigured;
  final String? joinLabel;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return const _ActiveBanner();
    }
    if (!purchaseConfigured) {
      return PremiumReferenceCtaUnavailable(onRetry: onRestore);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OraclyGoldButton(
          label: busy
              ? PremiumCopy.ctaBusy
              : (joinLabel ?? PremiumCopy.ctaJoin),
          expanded: true,
          borderRadius: PremiumReferenceTokens.ctaRadius,
          onPressed: busy ? null : onActivate,
        ),
        const SizedBox(height: 10),
        Text(
          PremiumCopy.ctaHintConfigured,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.58),
          ),
        ),
        if (onRestore != null) ...[
          const SizedBox(height: 14),
          OraclyPressable(
            onTap: busy ? null : onRestore,
            child: Text(
              PremiumCopy.ctaRestore,
              textAlign: TextAlign.center,
              style: ReadingTypography.metadata(
                color: OraclyChrome.goldLight.withValues(alpha: 0.72),
              ).copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: CraftsmanshipRhythm.microTracking,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner();

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
