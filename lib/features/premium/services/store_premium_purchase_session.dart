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

/// Durably records / clears a store transaction that is not finished yet,
/// keyed by product id. Never a receipt; never grants.
typedef StorePendingWrite = Future<void> Function(String productId);

class StorePremiumPurchaseSession {
  StorePremiumPurchaseSession({
    StorePendingWrite? onStorePending,
    StorePendingWrite? onStoreSettled,
  })
    // ignore: prefer_initializing_formals
    : _onStorePending = onStorePending,
       // ignore: prefer_initializing_formals
       _onStoreSettled = onStoreSettled;

  final StorePendingWrite? _onStorePending;
  final StorePendingWrite? _onStoreSettled;
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

  /// [onTimeout] decides what silence from the store means: a purchase
  /// that never answered is unfinished, not failed.
  Future<PremiumPurchaseResult> wait(
    Duration timeout, {
    PremiumPurchaseResult Function() onTimeout = PremiumPurchaseResult.failed,
  }) async {
    final wait = _wait;
    if (wait == null) return PremiumPurchaseResult.failed();
    try {
      return await wait.future.timeout(timeout, onTimeout: onTimeout);
    } on TimeoutException {
      return onTimeout();
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
    final recognized = PremiumStoreCatalog.kindFor(purchase.productID) != null;
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Play PENDING (slow payment, cash, approval): nothing is paid yet
        // and there is no receipt to verify or acknowledge. Record it
        // durably so no second purchase starts, even after a restart, and
        // answer the waiter now instead of letting it time out as failed.
        if (!recognized) return;
        await _write(_onStorePending, purchase.productID);
        _complete(PremiumPurchaseResult.pending());
        return;
      case PurchaseStatus.error:
        // A terminal store answer (e.g. a slow payment declined).
        if (recognized) await _write(_onStoreSettled, purchase.productID);
        _complete(PremiumPurchaseResult.failed());
        return;
      case PurchaseStatus.canceled:
        if (recognized) await _write(_onStoreSettled, purchase.productID);
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
        // The receipt is saved now; the unfinished-store record is done.
        if (result != null && result.granted) {
          await _write(_onStoreSettled, purchase.productID);
        }
        if (result != null) _complete(result);
    }
  }

  static Future<void> _write(StorePendingWrite? write, String productId) async {
    if (write == null) return;
    try {
      await write(productId);
    } catch (_) {
      // Storage failed: the next store query or redelivery decides again.
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