/// Reconciles local Premium flag with verifier — fail-closed on restart refresh.
library;

import 'package:flutter/foundation.dart';

import '../../features/premium/models/premium_entitlement_state.dart';
import '../../features/premium/models/premium_verify_result.dart';
import '../../features/premium/services/premium_dev_override.dart';
import '../../features/premium/services/premium_entitlement_verifier.dart';
import '../../features/premium/services/premium_store_catalog.dart';
import '../auth/user_local_data_isolation.dart';
import '../domain/repositories/premium_repository.dart';

class PremiumReconcileSnapshot {
  const PremiumReconcileSnapshot({
    required this.entitlement,
    this.message,
    this.definitive = true,
  });

  final PremiumEntitlementState entitlement;
  final String? message;

  /// False only for transient verify/transport failures that preserve a
  /// previously-proven active grant without freshly confirming it.
  final bool definitive;
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
      // Saved recovery credentials are verified by the backend, not the
      // store, so a missing store connection must not strand a paid
      // purchase. Store availability decides only when nothing is saved.
      if (!await premium.isPremiumActive()) {
        final recovered = await _recoverFromSavedCredentials();
        if (recovered != null) return recovered;
      }
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

    // Not locally active, but a store-acknowledged purchase may have left
    // recovery credentials whose first backend verify never succeeded
    // (transient failure, app killed, response lost). Their presence proves
    // nothing — only a fresh backend verify can grant.
    return await _recoverFromSavedCredentials() ??
        const PremiumReconcileSnapshot(
          entitlement: PremiumEntitlementState.inactive,
        );
  }

  /// Backend reasons that prove THIS token can never verify. Everything else
  /// that is not active (auth_required at cold start, provider not
  /// configured, transaction_not_found while Apple settles, ambiguous or
  /// unknown states) keeps the recovery material for a later reconcile.
  static const _unusableCredentialReasons = <String>{
    'unknown_product',
    'platform_product_mismatch',
    'bundle_mismatch',
    'product_mismatch',
    'jws_invalid',
    'receipt_no_transaction_id',
    'purchase_bound_to_other_account',
  };

  /// Null when there is no usable recovery material (none saved, owner not
  /// isolated, incomplete, or a product this build does not recognize).
  Future<PremiumReconcileSnapshot?> _recoverFromSavedCredentials() async {
    final creds = await premium.readPurchaseCredentials();
    if (creds == null || !creds.isComplete) return null;
    final kind = PremiumStoreCatalog.kindFor(creds.productId);
    if (kind == null) return null;

    final result = await verifier.verify(
      platform: creds.platform,
      productId: creds.productId,
      purchaseToken: creds.purchaseToken,
      transactionId: creds.transactionId,
    );

    if (result.isActive) {
      // Same owner gate as PremiumGrantPolicy.grant: the owner may have
      // switched while verify was in flight.
      final committed = await UserLocalDataIsolation.runOwnerScopedMutation(
        () async {
          if (!_ownerReady) return false;
          await premium.activatePlan(kind, authoritative: true);
          return true;
        },
      );
      if (!committed) {
        return const PremiumReconcileSnapshot(
          entitlement: PremiumEntitlementState.inactive,
          message: 'owner_changed',
          definitive: false,
        );
      }
      return const PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.active,
      );
    }

    if (result.status == PremiumVerifyStatus.pending) {
      return PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.pending,
        message: result.reason,
      );
    }

    final unusable =
        result.status == PremiumVerifyStatus.expired ||
        result.status == PremiumVerifyStatus.inactive ||
        (result.status == PremiumVerifyStatus.unverified &&
            _unusableCredentialReasons.contains(result.reason));
    if (!unusable) {
      // Never grant, never retire; freshness throttles the next attempt.
      return PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.inactive,
        message: result.reason,
        definitive: false,
      );
    }

    await UserLocalDataIsolation.runOwnerScopedMutation(() async {
      if (!_ownerReady) return;
      await premium.clearPurchaseCredentials();
    });
    return PremiumReconcileSnapshot(
      entitlement: PremiumEntitlementState.inactive,
      message: result.reason,
    );
  }

  bool get _ownerReady {
    final repository = premium;
    if (repository is PremiumOwnerBoundary) {
      return (repository as PremiumOwnerBoundary).ownerAccessReady;
    }
    return true;
  }

  Future<PremiumReconcileSnapshot> _refreshVerified() async {
    final creds = await premium.readPurchaseCredentials();
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

    if (result.status == PremiumVerifyStatus.error) {
      // Transient failure (network, parse error, backend 5xx) — the store
      // never actually said this purchase is invalid, it just couldn't be
      // confirmed right now. Reaching this branch already required
      // `localActive && verified` (an already-proven grant), so never
      // demote it on ambiguity; the next successful reconcile re-confirms
      // normally. A never-verified user never reaches this branch at all
      // (see `reconcile()`), so this cannot fabricate Premium for anyone.
      // R3.1 — definitive:false so freshness is not advanced.
      return PremiumReconcileSnapshot(
        entitlement: PremiumEntitlementState.active,
        message: result.reason,
        definitive: false,
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
