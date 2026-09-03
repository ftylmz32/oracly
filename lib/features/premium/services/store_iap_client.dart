/// Narrow IAP surface for [StorePremiumPurchase] — enables fake clients in tests.
library;

import 'package:in_app_purchase/in_app_purchase.dart';

abstract class StoreIapClient {
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<void> restorePurchases();
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// Production bridge to [InAppPurchase.instance].
class PluginStoreIapClient implements StoreIapClient {
  PluginStoreIapClient([InAppPurchase? iap])
      : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _iap.queryProductDetails(identifiers);

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}