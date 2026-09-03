/// Reconciles local Premium flag with verifier — fail-closed on restart refresh.
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
    this.canAttemptRestore = false,
    this.forceReleaseMode = false,
  });

  final PremiumRepository premium;
  final bool purchaseConfigured;
  final bool canAttemptRestore;
  final PremiumEntitlementVerifier verifier;
  final bool forceReleaseMode;

  bool get _releaseLocked => kReleaseMode || forceReleaseMode;

  Future<PremiumReconcileSnapshot> reconcile() async {
    if (!_releaseLocked && PremiumDevOverride.isActive) {
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.active,
        message: 'dev_premium_override',
      );
    }

    if (!purchaseConfigured && !canAttemptRestore) {
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
      if (_releaseLocked) {
        await premium.clearLocalPremiumAccess();
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
      await _demoteAfterFailedRefresh('missing_purchase_credentials');
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.unverified,
        message: 'missing_purchase_credentials',
      );
    }

    final result = await verifier.verify(
      platform: creds.platform,
      productId: creds.productId,
      purchaseToken: creds.purchaseToken,
      transactionId: creds.transactionId,
    );

    if (result.isActive) {
      final plan = await premium.activePlan();
      if (plan != null) {
        await premium.activatePlan(plan, authoritative: true);
      }
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.active,
      );
    }

    if (result.status == PremiumVerifyStatus.pending) {
      await _demoteAfterFailedRefresh(result.reason);
      return PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.pending,
        message: result.reason,
      );
    }

    if (result.status == PremiumVerifyStatus.expired ||
        result.status == PremiumVerifyStatus.inactive) {
      await premium.clearLocalPremiumAccess();
      return PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.inactive,
        message: result.reason,
      );
    }

    await premium.clearLocalPremiumAccess();
    return PremiumReconcileSnapshot(
      entitlement: PremiumEntitlementState.unverified,
      message: result.reason ?? 'verification_failed',
    );
  }

  Future<void> _demoteAfterFailedRefresh(String? _) async {
    await premium.clearLocalPremiumAccess();
  }
}
