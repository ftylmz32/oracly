/// In-flight purchase/restore wait — one active session at a time.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_credentials.dart';
import '../models/premium_purchase_result.dart';
import 'premium_store_catalog.dart';

class StorePremiumPurchaseSession {
  Completer<PremiumPurchaseResult>? _wait;
  PremiumPlanKind? _expected;
  bool _restore = false;
  bool _busy = false;
  PremiumPurchaseResult? _unsolicitedGrant;

  bool begin({PremiumPlanKind? expected, bool restore = false}) {
    if (_busy) return false;
    _busy = true;
    _restore = restore;
    _expected = expected;
    _wait = Completer<PremiumPurchaseResult>();
    return true;
  }

  void end() {
    _busy = false;
    _wait = null;
    _expected = null;
    _restore = false;
  }

  /// Delayed / restart deliveries when no waiter is active.
  PremiumPurchaseResult? takeUnsolicitedGrant() {
    final grant = _unsolicitedGrant;
    _unsolicitedGrant = null;
    return grant;
  }

  Future<PremiumPurchaseResult> wait(Duration timeout) async {
    final wait = _wait;
    if (wait == null) return PremiumPurchaseResult.failed();
    try {
      return await wait.future.timeout(
        timeout,
        onTimeout: () => _restore
            ? PremiumPurchaseResult.noneFound()
            : PremiumPurchaseResult.failed(),
      );
    } on TimeoutException {
      return _restore
          ? PremiumPurchaseResult.noneFound()
          : PremiumPurchaseResult.failed();
    }
  }

  void fail() => _complete(PremiumPurchaseResult.failed());

  Future<void> onPurchases(
    List<PurchaseDetails> purchases,
    Future<void> Function(PurchaseDetails purchase) completePurchase,
  ) async {
    if (purchases.isEmpty && _restore) {
      _complete(PremiumPurchaseResult.noneFound());
      return;
    }
    for (final purchase in purchases) {
      await _handle(purchase, completePurchase);
    }
  }

  Future<void> _handle(
    PurchaseDetails purchase,
    Future<void> Function(PurchaseDetails purchase) completePurchase,
  ) async {
    final kind = PremiumStoreCatalog.kindFor(purchase.productID);
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Keep waiting for a terminal status; UI stays busy.
        return;
      case PurchaseStatus.error:
        _complete(PremiumPurchaseResult.failed());
        return;
      case PurchaseStatus.canceled:
        _complete(PremiumPurchaseResult.cancelled());
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (kind == null) {
          _complete(PremiumPurchaseResult.failed());
          return;
        }
        if (_expected != null && kind != _expected) return;
        if (purchase.pendingCompletePurchase) {
          await completePurchase(purchase);
        }
        final creds = PremiumPurchaseCredentials(
          platform: defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          productId: purchase.productID,
          purchaseToken: purchase.verificationData.serverVerificationData,
          transactionId: purchase.purchaseID,
        );
        _complete(
          _restore || purchase.status == PurchaseStatus.restored
              ? PremiumPurchaseResult.restored(kind, credentials: creds)
              : PremiumPurchaseResult.granted(kind, credentials: creds),
        );
        return;
    }
  }

  void _complete(PremiumPurchaseResult result) {
    final wait = _wait;
    if (wait != null && !wait.isCompleted) {
      wait.complete(result);
      return;
    }
    // Acknowledge path already ran; keep grant for prepare/recovery.
    if (result.granted) {
      _unsolicitedGrant = result;
    }
  }
}