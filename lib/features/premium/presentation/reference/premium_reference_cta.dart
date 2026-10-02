/// Premium membership CTA — one primary door when store is real.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'premium_reference_active_banner.dart';
import 'premium_reference_cta_unavailable.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceCta extends StatelessWidget {
  const PremiumReferenceCta({
    super.key,
    required this.isPremium,
    this.onActivate,
    this.onRestore,
    this.onRetryStore,
    this.busy = false,
    this.purchaseConfigured = false,
    this.joinLabel,
    this.checkingStore = false,
    this.onStoreDiagnostics,
  });

  final bool isPremium;
  final VoidCallback? onActivate;
  final VoidCallback? onRestore;

  /// Re-checks store/catalog availability (e.g. reloads the product
  /// catalogue) when the store isn't configured yet. Distinct from
  /// [onRestore] — restoring purchases is meaningless before the store is
  /// even reachable. Falls back to [onRestore] when not supplied so callers
  /// that predate this param keep their exact prior behavior.
  final VoidCallback? onRetryStore;
  final bool busy;
  final bool purchaseConfigured;
  final String? joinLabel;
  final bool checkingStore;
  final VoidCallback? onStoreDiagnostics;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return const PremiumReferenceActiveBanner();
    }
    if (!purchaseConfigured) {
      return PremiumReferenceCtaUnavailable(
        onRetry: onRetryStore ?? onRestore,
        checking: checkingStore,
        onDiagnostics: onStoreDiagnostics,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onActivate != null) ...[
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
        ] else if (onRetryStore != null) ...[
          PremiumReferenceCtaUnavailable(
            onRetry: onRetryStore,
            checking: checkingStore,
            onDiagnostics: onStoreDiagnostics,
          ),
          const SizedBox(height: 14),
        ],
        if (onRestore != null) ...[
          if (onActivate != null) const SizedBox(height: 14),
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
