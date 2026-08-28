/// Reconciles local Premium flag with verifier — anti-flicker when verified.
///
/// Release builds demote never-verified local flags. Remote validation against
/// Apple/Google is still external / not claimed solved here.
library;

import 'package:flutter/foundation.dart';

import '../../features/premium/models/premium_entitlement_state.dart';
import '../../features/premium/models/premium_verify_result.dart';
import '../../features/premium/services/premium_dev_override.dart';
import '../../features/premium/services/premium_entitlement_verifier.dart';
import '../domain/repositories/premium_repository.dart';

class PremiumReconcileSnapshot {
  const PremiumReconcileSnapshot({
    required this.entitlement,
    this.message,
  });

  final PremiumEntitlementState entitlement;
  final String? message;
}

class PremiumEntitlementReconciler {
  PremiumEntitlementReconciler({
    required this.premium,
    required this.purchaseConfigured,
    required this.verifier,
    this.forceReleaseMode = false,
  });

  final PremiumRepository premium;
  final bool purchaseConfigured;
  final PremiumEntitlementVerifier verifier;

  /// Release demotion switch (tests + [PremiumService.forceReleaseMode]).
  final bool forceReleaseMode;

  bool get _releaseLocked => kReleaseMode || forceReleaseMode;

  Future<PremiumReconcileSnapshot> reconcile() async {
    // DEV-ONLY: explicit ORACLY_DEV_PREMIUM unlocks canonical entitlement.
    // Runs before store checks so local inspection works without IAP wiring.
    // Ignored in release / production / staging via PremiumDevOverride.
    if (!_releaseLocked && PremiumDevOverride.isActive) {
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.active,
        message: 'dev_premium_override',
      );
    }

    if (!purchaseConfigured) {
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.unavailable,
      );
    }

    final localActive = await premium.isPremiumActive();
    final verified = premium.wasAuthoritativelyVerified;

    if (localActive && verified) {
      return _refreshVerified();
    }

    if (localActive && !verified) {
      // Never treat an unverified local boolean as production Premium.
      if (_releaseLocked) {
        await premium.clearLocalPremiumAccess();
        return const PremiumReconcileSnapshot(
          entitlement: PremiumEntitlementState.unverified,
          message: 'local_cache_not_authoritative',
        );
      }
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.unverified,
        message: 'local_cache_not_authoritative',
      );
    }

    return const PremiumReconcileSnapshot(
      entitlement: PremiumEntitlementState.inactive,
    );
  }

  Future<PremiumReconcileSnapshot> _refreshVerified() async {
    final creds = premium.readPurchaseCredentials();
    if (creds == null || !creds.isComplete) {
      // Previously verified — keep active to avoid flicker without tokens.
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.active,
      );
    }

    final result = await verifier.verify(
      platform: creds.platform,
      productId: creds.productId,
      purchaseToken: creds.purchaseToken,
      transactionId: creds.transactionId,
    );

    if (result.isActive || result.status == PremiumVerifyStatus.pending) {
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.active,
      );
    }

    if (result.status == PremiumVerifyStatus.expired ||
        result.status == PremiumVerifyStatus.inactive) {
      await premium.clearLocalPremiumAccess();
      return PremiumReconcileSnapshot(
        entitlement: result.status == PremiumVerifyStatus.expired
            ? PremiumEntitlementState.inactive
            : PremiumEntitlementState.inactive,
        message: result.reason,
      );
    }

    // unverified / error after a prior authoritative grant: keep active
    // briefly (offline / stub) — do not flicker locked.
    return const PremiumReconcileSnapshot(
      entitlement: PremiumEntitlementState.active,
    );
  }
}
