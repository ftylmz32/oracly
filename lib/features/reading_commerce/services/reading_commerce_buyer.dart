/// Play Billing / StoreKit consumable purchase. Completes only after verify.
library;

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/reading_commerce_view.dart';
import 'reading_purchase_tracker.dart';

class ReadingCommerceBuyer {
  ReadingCommerceBuyer({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final Map<String, PurchaseDetails> _open = {};

  Stream<List<ReadingPurchaseUpdate>> get updates {
    return _iap.purchaseStream.map((purchases) {
      return [
        for (final purchase in purchases) _update(purchase),
      ];
    });
  }

  Future<Map<String, String>> storePrices() async {
    if (!await _iap.isAvailable()) return const {};
    final response = await _iap.queryProductDetails({
      ReadingCommerceView.coffeeId,
      ReadingCommerceView.palmId,
      ReadingCommerceView.packId,
    });
    return {
      for (final product in response.productDetails) product.id: product.price,
    };
  }

  Future<bool> buy(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    final matches = response.productDetails.where((item) => item.id == productId);
    if (matches.isEmpty) return false;
    return _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: matches.first),
      autoConsume: false,
    );
  }

  Future<void> complete(String purchaseId) async {
    final purchase = _open[purchaseId];
    if (purchase == null) throw StateError('purchase_not_open');
    await _iap.completePurchase(purchase);
  }

  ReadingPurchaseUpdate _update(PurchaseDetails purchase) {
    final token = purchase.verificationData.serverVerificationData.trim();
    final purchaseId = (purchase.purchaseID ?? token).trim();
    if (purchaseId.isNotEmpty) _open[purchaseId] = purchase;
    return ReadingPurchaseUpdate(
      productId: purchase.productID,
      token: token,
      purchaseId: purchaseId,
      status: switch (purchase.status) {
        PurchaseStatus.pending => ReadingPurchaseStatus.pending,
        PurchaseStatus.purchased || PurchaseStatus.restored => ReadingPurchaseStatus.purchased,
        PurchaseStatus.canceled => ReadingPurchaseStatus.canceled,
        PurchaseStatus.error => ReadingPurchaseStatus.failed,
      },
    );
  }
}
