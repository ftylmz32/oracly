/// Narrow IAP surface for [StorePremiumPurchase] — enables fake clients in tests.
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

abstract class StoreIapClient {
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<void> restorePurchases();
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// Read-only look at the store's own list of this device's purchases,
/// including ones it has not finished (Play PENDING). Never buys, restores
/// or acknowledges. Null means the store could not be read; an empty list
/// is only ever the answer of a successful query.
abstract interface class StorePurchaseQueryClient {
  Future<List<PurchaseDetails>?> queryPurchases();
}

/// Production bridge to [InAppPurchase.instance].
class PluginStoreIapClient implements StoreIapClient, StorePurchaseQueryClient {
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

  /// Play `queryPurchasesAsync` (in-app and subscriptions). StoreKit has no
  /// equivalent query here: deferred transactions are redelivered on the
  /// purchase stream instead, so iOS reports "could not read".
  @override
  Future<List<PurchaseDetails>?> queryPurchases() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final android = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await android.queryPastPurchases();
      if (response.error != null) return null;
      return response.pastPurchases;
    } catch (_) {
      return null;
    }
  }
}