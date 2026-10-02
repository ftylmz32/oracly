/// Store-state chain of the Premium body — loading, error, plans, restore,
/// or the honest unavailable plaque. Only store-returned plans are offered.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/copy/premium_entitlement_message.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../controllers/premium_status_controller.dart';
import '../../models/premium_entitlement_state.dart';
import 'premium_reference_cta.dart';
import 'premium_reference_cta_unavailable.dart';
import 'premium_reference_plans_section.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceStoreSection extends StatelessWidget {
  const PremiumReferenceStoreSection({
    super.key,
    required this.status,
    required this.onPurchase,
    required this.onRestore,
    required this.onRetryStore,
    this.onStoreDiagnostics,
  });

  final PremiumStatusController status;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onRetryStore;
  final VoidCallback? onStoreDiagnostics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _children(),
    );
  }

  List<Widget> _children() {
    if (!status.loaded) {
      return [_note(PremiumCopy.loadingBody, 0.7, secondary: true)];
    }
    if (status.entitlement == PremiumEntitlementState.error) {
      return [
        _note(
          PremiumEntitlementMessage.forReason(
            status.entitlementMessage,
            fallback: PremiumCopy.purchaseFailed,
          ),
          0.86,
        ),
        const SizedBox(height: 12),
        if (status.checkingStore)
          Semantics(
            liveRegion: true,
            child: _note(PremiumCopy.ctaCheckingStore, 0.7, secondary: true),
          )
        else
          OraclyPressable(
            onTap: onRetryStore,
            child: Text(
              PremiumCopy.errorRetry,
              textAlign: TextAlign.center,
              style: ReadingTypography.metadata(
                color: OraclyChrome.goldLight.withValues(alpha: 0.8),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
      ];
    }
    if (status.storeOffersPlans && !status.isPremium) {
      return [
        PremiumReferencePlansSection(
          plans: status.plans,
          selected: status.selectedPlan,
          onSelected: status.selectPlan,
        ),
        SizedBox(height: PremiumReferenceTokens.plansToCta),
        _purchaseCta(),
      ];
    }
    if (status.isPremium) return const [PremiumReferenceCta(isPremium: true)];
    if (status.entitlement == PremiumEntitlementState.unverified) {
      return [
        _note(
          PremiumEntitlementMessage.forReason(
            status.entitlementMessage,
            fallback: PremiumCopy.entitlementUnverified,
          ),
          0.86,
        ),
        SizedBox(height: PremiumReferenceTokens.plansToCta),
        status.storeOffersPlans ? _purchaseCta() : _restoreOrUnavailable(),
      ];
    }
    return [_restoreOrUnavailable()];
  }

  Widget _purchaseCta() => PremiumReferenceCta(
    isPremium: false,
    busy: status.busy,
    purchaseConfigured: true,
    onActivate: onPurchase,
    onRestore: onRestore,
  );

  Widget _restoreOrUnavailable() {
    if (status.canAttemptRestore) {
      return PremiumReferenceCta(
        isPremium: false,
        busy: status.busy,
        purchaseConfigured: true,
        onActivate: null,
        onRestore: onRestore,
        onRetryStore: onRetryStore,
        checkingStore: status.checkingStore,
        onStoreDiagnostics: onStoreDiagnostics,
      );
    }
    return PremiumReferenceCtaUnavailable(
      onRetry: onRetryStore,
      checking: status.checkingStore,
      onDiagnostics: onStoreDiagnostics,
    );
  }

  Widget _note(String text, double alpha, {bool secondary = false}) {
    final color = OraclyChrome.cream.withValues(alpha: alpha);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: secondary
          ? ReadingTypography.secondary(color: color)
          : ReadingTypography.body(color: color),
    );
  }
}
