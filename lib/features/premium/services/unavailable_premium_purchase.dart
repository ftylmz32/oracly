/// Default billing port — no App Store / Play products loaded.
library;

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_result.dart';
import 'premium_purchase_port.dart';

class UnavailablePremiumPurchase implements PremiumPurchasePort {
  const UnavailablePremiumPurchase();

  @override
  bool get isConfigured => false;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    return PremiumPurchaseResult.unavailable();
  }

  @override
  Future<PremiumPurchaseResult> restore() async {
    return PremiumPurchaseResult.restoreUnavailable();
  }

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}