/// Store billing port — App Store / Play when configured.
library;

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_result.dart';

abstract class PremiumPurchasePort {
  bool get isConfigured;

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