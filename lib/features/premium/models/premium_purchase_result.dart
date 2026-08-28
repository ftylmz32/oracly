/// Outcome of a store purchase or restore — never inferred from a UI tap.
library;

import '../../../core/copy/premium_copy.dart';
import '../../../core/domain/models/premium_plan.dart';
import 'premium_purchase_credentials.dart';

enum PremiumPurchaseOutcome {
  unavailable,
  restoreUnavailable,
  cancelled,
  failed,
  restoreFailed,
  noneFound,
  pending,
  restored,
  granted,
  unverified,
}

class PremiumPurchaseResult {
  PremiumPurchaseResult({
    required this.outcome,
    required this.message,
    this.granted = false,
    this.plan,
    this.credentials,
  });

  final PremiumPurchaseOutcome outcome;
  final String message;
  final bool granted;
  final PremiumPlanKind? plan;
  final PremiumPurchaseCredentials? credentials;

  factory PremiumPurchaseResult.unavailable() => PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.unavailable,
        message: PremiumCopy.purchaseUnavailable,
      );

  factory PremiumPurchaseResult.restoreUnavailable() =>
      PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.restoreUnavailable,
        message: PremiumCopy.restoreUnavailable,
      );

  factory PremiumPurchaseResult.cancelled() => PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.cancelled,
        message: PremiumCopy.purchaseCancelled,
      );

  factory PremiumPurchaseResult.failed() => PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.failed,
        message: PremiumCopy.purchaseFailed,
      );

  factory PremiumPurchaseResult.noneFound() => PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.noneFound,
        message: PremiumCopy.restoreNone,
      );

  factory PremiumPurchaseResult.pending() => PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.pending,
        message: PremiumCopy.purchasePending,
      );

  factory PremiumPurchaseResult.restoreFailed() => PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.restoreFailed,
        message: PremiumCopy.restoreFailed,
      );

  factory PremiumPurchaseResult.unverified([String? message]) =>
      PremiumPurchaseResult(
        outcome: PremiumPurchaseOutcome.unverified,
        message: message ?? PremiumCopy.entitlementUnverified,
      );

  factory PremiumPurchaseResult.granted(
    PremiumPlanKind plan, {
    PremiumPurchaseCredentials? credentials,
  }) {
    return PremiumPurchaseResult(
      outcome: PremiumPurchaseOutcome.granted,
      message: PremiumCopy.activatedMessage,
      granted: true,
      plan: plan,
      credentials: credentials,
    );
  }

  factory PremiumPurchaseResult.restored(
    PremiumPlanKind plan, {
    PremiumPurchaseCredentials? credentials,
  }) {
    return PremiumPurchaseResult(
      outcome: PremiumPurchaseOutcome.restored,
      message: PremiumCopy.restoreSuccess,
      granted: true,
      plan: plan,
      credentials: credentials,
    );
  }
}
