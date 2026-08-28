/// Real Play Billing / StoreKit purchase port via in_app_purchase.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_result.dart';
import 'premium_purchase_port.dart';
import 'premium_store_catalog.dart';
import 'store_premium_purchase_session.dart';

class StorePremiumPurchase implements PremiumPurchasePort {
  StorePremiumPurchase({InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final StorePremiumPurchaseSession _session = StorePremiumPurchaseSession();
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _configured = false;
  final Map<String, ProductDetails> _products = {};

  @override
  bool get isConfigured => _configured;

  @override
  String? priceLabel(PremiumPlanKind plan) =>
      _products[PremiumStoreCatalog.idFor(plan)]?.price;

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  Future<void> prepare() async {
    try {
      final available = await _iap.isAvailable().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!available) {
        _configured = false;
        _products.clear();
        return;
      }
      _listen();
      final response = await _iap
          .queryProductDetails(PremiumStoreCatalog.allIds)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => ProductDetailsResponse(
              productDetails: const [],
              notFoundIDs: PremiumStoreCatalog.allIds.toList(),
            ),
          );
      _products
        ..clear()
        ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
      _configured = _products.isNotEmpty;
    } catch (_) {
      _configured = false;
      _products.clear();
    }
  }

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    if (!_configured) return PremiumPurchaseResult.unavailable();
    final product = _products[PremiumStoreCatalog.idFor(plan)];
    if (product == null) return PremiumPurchaseResult.unavailable();
    if (!_session.begin(expected: plan, restore: false)) {
      return PremiumPurchaseResult.failed();
    }
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) return PremiumPurchaseResult.failed();
      return await _session.wait(const Duration(seconds: 120));
    } catch (_) {
      return PremiumPurchaseResult.failed();
    } finally {
      _session.end();
    }
  }

  @override
  Future<PremiumPurchaseResult> restore() async {
    if (!_configured) return PremiumPurchaseResult.restoreUnavailable();
    if (!_session.begin(restore: true)) {
      return PremiumPurchaseResult.restoreFailed();
    }
    try {
      await _iap.restorePurchases();
      return await _session.wait(const Duration(seconds: 45));
    } catch (_) {
      return PremiumPurchaseResult.restoreFailed();
    } finally {
      _session.end();
    }
  }

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async {
    return _session.takeUnsolicitedGrant();
  }

  void _listen() {
    _sub ??= _iap.purchaseStream.listen(
      (purchases) => _session.onPurchases(purchases, _iap),
      onError: (_) => _session.fail(),
    );
  }

  static bool get supportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}