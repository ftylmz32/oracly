// ignore_for_file: prefer_initializing_formals

/// Grant policy after store purchase — verification before local activation.
///
/// HONESTY: Without a remote verifier returning active, release builds do not
/// grant. Debug may optionally grant via PremiumDevOverride (non-authoritative).
/// Apple/Google receipt validation happens server-side (real App Store Server
/// API / Google Play Developer API calls) — this class only calls the
/// verifier and never judges a receipt/token itself.
library;

import 'package:flutter/foundation.dart';

import '../../features/premium/models/premium_purchase_credentials.dart';
import '../../features/premium/models/premium_purchase_result.dart';
import '../../features/premium/models/premium_verify_result.dart';
import '../../features/premium/services/premium_dev_override.dart';
import '../../features/premium/services/premium_entitlement_verifier.dart';
import '../auth/user_local_data_isolation.dart';
import '../domain/models/premium_plan.dart';
import '../domain/repositories/premium_repository.dart';
import '../domain/repositories/user_repository.dart';

class PremiumGrantPolicy {
  PremiumGrantPolicy({
    required PremiumRepository premium,
    required UserRepository user,
    required PremiumEntitlementVerifier verifier,
    required bool forceReleaseMode,
  }) : _premium = premium,
       _user = user,
       _verifier = verifier,
       _forceReleaseMode = forceReleaseMode;

  final PremiumRepository _premium;
  final UserRepository _user;
  final PremiumEntitlementVerifier _verifier;
  final bool _forceReleaseMode;

  Future<PremiumPurchaseResult> applyStoreOutcome(
    PremiumPurchaseResult result,
  ) async {
    if (!result.granted || result.plan == null) return result;
    return _verifyThenMaybeGrant(result);
  }

  Future<PremiumPurchaseResult> _verifyThenMaybeGrant(
    PremiumPurchaseResult result,
  ) async {
    final plan = result.plan!;
    final creds = result.credentials;
    final verify = await _runVerify(creds);

    if (verify.isActive) {
      final committed = await grant(
        plan,
        authoritative: true,
        credentials: creds,
      );
      return committed ? result : PremiumPurchaseResult.unverified();
    }

    if (verify.status == PremiumVerifyStatus.pending) {
      return PremiumPurchaseResult.pending();
    }

    // No remote provider: local cache always returns unverified.
    if (verify.status == PremiumVerifyStatus.unverified &&
        !_verifier.isRemoteVerifierConfigured) {
      if (!kReleaseMode && !_forceReleaseMode && PremiumDevOverride.isActive) {
        final committed = await grant(
          plan,
          authoritative: false,
          credentials: creds,
        );
        return committed ? result : PremiumPurchaseResult.unverified();
      }
      return PremiumPurchaseResult.unverified();
    }

    return PremiumPurchaseResult.unverified();
  }

  Future<PremiumVerifyResult> _runVerify(
    PremiumPurchaseCredentials? creds,
  ) async {
    if (creds == null || !creds.isComplete) {
      return PremiumVerifyResult.unverified('missing_purchase_credentials');
    }
    return _verifier.verify(
      platform: creds.platform,
      productId: creds.productId,
      purchaseToken: creds.purchaseToken,
      transactionId: creds.transactionId,
    );
  }

  static bool _sameCredentials(
    PremiumPurchaseCredentials? saved,
    PremiumPurchaseCredentials next,
  ) {
    return saved != null &&
        saved.platform == next.platform &&
        saved.productId == next.productId &&
        saved.purchaseToken == next.purchaseToken &&
        saved.transactionId == next.transactionId;
  }

  bool get _ownerReady {
    final premium = _premium;
    if (premium is PremiumOwnerBoundary) {
      return (premium as PremiumOwnerBoundary).ownerAccessReady;
    }
    return true;
  }

  /// Local commit only. Store verification stays outside this gate.
  /// Returns false when the captured owner is no longer current.
  Future<bool> grant(
    PremiumPlanKind plan, {
    required bool authoritative,
    PremiumPurchaseCredentials? credentials,
  }) {
    return UserLocalDataIsolation.runOwnerScopedMutation(() async {
      if (!_ownerReady) return false;
      // A verified store grant is not locally committed until its proof is
      // durable. Otherwise a credential write failure could leave active=true
      // for the live session yet make restart unverifiable. The store path
      // already saved this exact proof before completing the transaction;
      // rewriting it could only destroy that copy on a storage failure. A
      // failed read throws here, so nothing is activated.
      if (credentials != null &&
          !_sameCredentials(
            await _premium.readPurchaseCredentials(),
            credentials,
          )) {
        await _premium.savePurchaseCredentials(credentials);
      }
      await _premium.activatePlan(plan, authoritative: authoritative);
      // Profile flag mirrors local access. Authoritative proof is separate
      // (wasAuthoritativelyVerified) — never overwrite access with false here.
      final profile = await _user.getProfile();
      await _user.saveProfile(profile.copyWith(isPremium: true));
      if (authoritative) {
        await _user.unlockAchievement('first_premium');
      }
      return true;
    });
  }
}
