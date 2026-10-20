/// Play Billing / StoreKit consumable purchase. Completes only after verify.
library;

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/reading_commerce_view.dart';

enum ReadingBuyKind { granted, pending, canceled, failed }

class ReadingBuyResult {
  const ReadingBuyResult(this.kind);
  final ReadingBuyKind kind;
}

class ReadingCommerceBuyer {
  ReadingCommerceBuyer({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

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

  Future<ReadingBuyResult> buy({
    required String productId,
    required Future<bool> Function(String purchaseToken) verify,
  }) async {
    final response = await _iap.queryProductDetails({productId});
    final product = response.productDetails.where((item) => item.id == productId);
    if (product.isEmpty) return const ReadingBuyResult(ReadingBuyKind.failed);
    final completer = Completer<PurchaseDetails?>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.productID != productId || completer.isCompleted) continue;
        completer.complete(purchase);
      }
    });
    try {
      final started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product.first),
        autoConsume: false,
      );
      if (!started) return const ReadingBuyResult(ReadingBuyKind.failed);
      final purchase = await completer.future.timeout(const Duration(seconds: 120));
      if (purchase == null) return const ReadingBuyResult(ReadingBuyKind.failed);
      if (purchase.status == PurchaseStatus.pending) {
        return const ReadingBuyResult(ReadingBuyKind.pending);
      }
      if (purchase.status == PurchaseStatus.canceled) {
        return const ReadingBuyResult(ReadingBuyKind.canceled);
      }
      if (purchase.status != PurchaseStatus.purchased) {
        return const ReadingBuyResult(ReadingBuyKind.failed);
      }
      final token = purchase.verificationData.serverVerificationData.trim();
      if (token.isEmpty) return const ReadingBuyResult(ReadingBuyKind.failed);
      final granted = await verify(token);
      if (granted) await _iap.completePurchase(purchase);
      return ReadingBuyResult(granted ? ReadingBuyKind.granted : ReadingBuyKind.failed);
    } on TimeoutException {
      return const ReadingBuyResult(ReadingBuyKind.failed);
    } finally {
      await subscription.cancel();
    }
  }
}
