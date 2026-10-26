/// Play Billing / StoreKit consumable purchase. Completes only after verify.
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/reading_commerce_view.dart';
import 'reading_purchase_tracker.dart';

class ReadingCommerceBuyer {
  ReadingCommerceBuyer({InAppPurchase? iap, String? Function()? ownerTag})
    : _iap = iap ?? InAppPurchase.instance,
      // ignore: prefer_initializing_formals
      _ownerTag = ownerTag;

  final InAppPurchase _iap;
  final String? Function()? _ownerTag;
  final Map<String, PurchaseDetails> _open = {};

  /// The only products this listener handles. The purchase stream also
  /// carries Premium; those events belong to the Premium session alone.
  static const productIds = {
    ReadingCommerceView.coffeeId,
    ReadingCommerceView.palmId,
    ReadingCommerceView.packId,
  };

  Stream<List<ReadingPurchaseUpdate>> get updates {
    return _iap.purchaseStream.map(_remember);
  }

  /// Reading purchases among [purchases], each with the account tag the
  /// store echoes back (Play: obfuscated account id) when it has one.
  static List<ReadingPurchaseUpdate> readingUpdatesOf(List<PurchaseDetails> purchases) => [
    for (final purchase in purchases)
      if (productIds.contains(purchase.productID)) _update(purchase),
  ];

  /// Names the paying account (opaque owner tag) to the store, so the
  /// purchase can only ever be credited to it.
  static PurchaseParam purchaseParamFor(ProductDetails product, {String? ownerTag}) =>
      PurchaseParam(productDetails: product, applicationUserName: ownerTag);

  /// Unfinished reading purchases the store still holds (Play). StoreKit
  /// redelivers unfinished transactions on its own, so iOS returns none.
  Future<List<ReadingPurchaseUpdate>> unfinishedPurchases() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return const [];
    try {
      final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await android.queryPastPurchases();
      if (response.error != null) return const [];
      return _remember([
        for (final purchase in response.pastPurchases)
          if (purchase.pendingCompletePurchase) purchase,
      ]);
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, String>> storePrices() async {
    if (!await _iap.isAvailable()) return const {};
    final response = await _iap.queryProductDetails(productIds);
    return {
      for (final product in response.productDetails) product.id: product.price,
    };
  }

  Future<bool> buy(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    final matches = response.productDetails.where((item) => item.id == productId);
    if (matches.isEmpty) return false;
    return _iap.buyConsumable(
      purchaseParam: purchaseParamFor(matches.first, ownerTag: _ownerTag?.call()),
      autoConsume: false,
    );
  }

  Future<void> complete(String purchaseId) async {
    final purchase = _open[purchaseId];
    if (purchase == null) throw StateError('purchase_not_open');
    await _iap.completePurchase(purchase);
  }

  List<ReadingPurchaseUpdate> _remember(List<PurchaseDetails> purchases) {
    final reading = [
      for (final purchase in purchases)
        if (productIds.contains(purchase.productID)) purchase,
    ];
    for (final purchase in reading) {
      final id = _purchaseIdOf(purchase);
      if (id.isNotEmpty) _open[id] = purchase;
    }
    return readingUpdatesOf(reading);
  }

  static String _purchaseIdOf(PurchaseDetails purchase) =>
      (purchase.purchaseID ?? purchase.verificationData.serverVerificationData).trim();

  static ReadingPurchaseUpdate _update(PurchaseDetails purchase) {
    final tag = purchase is GooglePlayPurchaseDetails
        ? purchase.billingClientPurchase.obfuscatedAccountId
        : null;
    return ReadingPurchaseUpdate(
      productId: purchase.productID,
      token: purchase.verificationData.serverVerificationData.trim(),
      purchaseId: _purchaseIdOf(purchase),
      status: switch (purchase.status) {
        PurchaseStatus.pending => ReadingPurchaseStatus.pending,
        PurchaseStatus.purchased || PurchaseStatus.restored => ReadingPurchaseStatus.purchased,
        PurchaseStatus.canceled => ReadingPurchaseStatus.canceled,
        PurchaseStatus.error => ReadingPurchaseStatus.failed,
      },
      ownerTag: tag != null && tag.isNotEmpty ? tag : null,
    );
  }
}
