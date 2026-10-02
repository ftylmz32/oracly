/// In-flight purchase/restore wait — one active session at a time.
library;

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_result.dart';
import 'premium_store_catalog.dart';
import 'store_iap_client.dart';
import 'store_purchase_stream_diagnostics.dart';
import 'store_purchase_terminal_handler.dart';

export 'store_purchase_terminal_handler.dart' show PersistRetryCredentials;

class StorePremiumPurchaseSession {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PremiumPurchaseResult>? _wait;
  PremiumPlanKind? _expected;
  bool _restore = false;
  bool _busy = false;
  PremiumPurchaseResult? _unsolicitedGrant;

  /// Attaches the single purchase-stream listener (idempotent).
  void listen(StoreIapClient iap, PersistRetryCredentials? persist) {
    if (_sub != null) return;
    StorePurchaseStreamDiagnostics.recordListenerAttached();
    _sub = iap.purchaseStream.listen(
      (purchases) => onPurchases(
        purchases,
        iap.completePurchase,
        persistRetryCredentials: persist,
      ),
      onError: (Object error) {
        StorePurchaseStreamDiagnostics.recordStreamError(error);
        fail();
      },
    );
  }

  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
  }

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
        onTimeout: () => PremiumPurchaseResult.failed(),
      );
    } on TimeoutException {
      return PremiumPurchaseResult.failed();
    }
  }

  void fail() => _complete(PremiumPurchaseResult.failed());

  Future<void> onPurchases(
    List<PurchaseDetails> purchases,
    Future<void> Function(PurchaseDetails purchase) completePurchase, {
    PersistRetryCredentials? persistRetryCredentials,
  }) async {
    if (purchases.isEmpty) StorePurchaseStreamDiagnostics.recordEmptyBatch();
    if (purchases.isEmpty && _restore) {
      _complete(PremiumPurchaseResult.noneFound());
      return;
    }
    for (final purchase in purchases) {
      StorePurchaseStreamDiagnostics.recordPurchase(purchase);
      await _handle(purchase, completePurchase, persistRetryCredentials);
    }
  }

  Future<void> _handle(
    PurchaseDetails purchase,
    Future<void> Function(PurchaseDetails purchase) completePurchase,
    PersistRetryCredentials? persistRetryCredentials,
  ) async {
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
        // Recovery credentials are persisted BEFORE completePurchase, so a
        // store-acknowledged purchase stays re-verifiable even if the first
        // backend verify fails or the app dies before it returns.
        final result = await StorePurchaseTerminalHandler.apply(
          purchase: purchase,
          kind: PremiumStoreCatalog.kindFor(purchase.productID),
          expected: _expected,
          restore: _restore,
          persistRetryCredentials: persistRetryCredentials,
          completePurchase: completePurchase,
        );
        if (result != null) _complete(result);
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