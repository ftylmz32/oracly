/// Finishes a held store transaction only after the backend verified it.
library;

import '../models/premium_verify_result.dart';
import 'premium_entitlement_verifier.dart';
import 'premium_purchase_port.dart';

/// Every verification path (purchase, late delivery, pending resolution,
/// reconcile) goes through the verifier, so this is the one place where an
/// `active` answer, which means verified at the store and bound to the
/// signed-in account by the backend, hands the purchase to the store port
/// to be finished. Nothing is finished on any other answer.
class StoreFinishingVerifier implements PremiumEntitlementVerifier {
  StoreFinishingVerifier(this._inner, this._finisher);

  final PremiumEntitlementVerifier _inner;
  final StorePurchaseFinisher _finisher;

  @override
  bool get isRemoteVerifierConfigured => _inner.isRemoteVerifierConfigured;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final result = await _inner.verify(
      platform: platform,
      productId: productId,
      purchaseToken: purchaseToken,
      transactionId: transactionId,
    );
    if (result.isActive && platform == 'android') {
      await _finisher.finishVerified(
        purchaseToken,
        storeAcknowledged:
            result.acknowledgement == PremiumStoreAcknowledgement.acknowledged,
      );
    }
    return result;
  }
}
