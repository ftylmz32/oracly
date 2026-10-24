/// Store billing port - App Store / Play when configured.
library;

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_result.dart';
import 'store_purchase_terminal_handler.dart';

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

  /// Any account's unfinished or parked purchase on this device.
  bool get holdsUnfinishedPurchase;

  /// Hands a purchase finished for the signed-in account while another
  /// account was active (parked for it) to [save]. Never to anyone else.
  Future<bool> recoverParked(PersistRetryCredentials save);

  /// The signed-in account's own unfinished purchases that the store gave
  /// a token for. Never another account's.
  Future<List<StorePendingToken>> pendingTokensForCurrentOwner();

  /// The store answered definitively for this attempt: drop its lock.
  Future<void> settleStorePending(String attemptId, {required String why});

  /// The one plan the signed-in account may retry while its only locks are
  /// attempts the store never gave a token for, old enough and followed by
  /// a successful store query that showed nothing for that product. Null
  /// otherwise. Other plans stay blocked.
  Future<PremiumPlanKind?> retryablePlan();
}

class StorePendingToken {
  const StorePendingToken({
    required this.attemptId,
    required this.platform,
    required this.productId,
    required this.token,
  });

  final String attemptId;
  final String platform;
  final String productId;
  final String token;
}
