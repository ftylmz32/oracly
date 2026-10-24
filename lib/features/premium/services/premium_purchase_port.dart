/// Store billing port - App Store / Play when configured.
library;

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_result.dart';

abstract class PremiumPurchasePort {
  /// Product catalogue loaded - required for new purchases / price labels.
  bool get isConfigured;

  /// Store/plugin can run restorePurchases. Independent of catalogue load.
  bool get canAttemptRestore;

  /// Query store products. May flip [isConfigured]. No-op when closed.
  Future<void> prepare();

  /// Store price label when known; otherwise null.
  String? priceLabel(PremiumPlanKind plan);

  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan);

  /// Real restore via App Store / Play. Never fake it here.
  Future<PremiumPurchaseResult> restore();

  /// Purchase completed while no waiter (kill / delay). Default: none.
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

/// Optional: a port that can re-read the store's own record of this
/// device's purchases without buying or restoring. Returns the product ids
/// the store still reports as unfinished, or null when it could not be
/// read. A newly finished purchase found there (not yet acknowledged) is
/// handled like a stream delivery: proof saved first, then acknowledged.
abstract interface class StorePurchaseRefresher {
  Future<Set<String>?> refreshStorePurchases();
}
