/// In-flight purchase/restore wait — one active session at a time — and the
/// owner routing of every store delivery.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../../../core/storage/premium_purchase_attempt_store.dart';
import '../models/premium_purchase_result.dart';
import 'premium_store_catalog.dart';
import 'store_iap_client.dart';
import 'store_purchase_stream_diagnostics.dart';
import 'store_purchase_terminal_handler.dart';

export 'store_purchase_terminal_handler.dart' show PersistRetryCredentials;

class StorePremiumPurchaseSession {
  StorePremiumPurchaseSession({
    this.attempts,
    String? Function()? currentOwnerTag,
  })
    // ignore: prefer_initializing_formals
    : _currentOwnerTag = currentOwnerTag;

  /// Device ledger of unfinished purchases. Null only for direct, unwired
  /// constructions; production always supplies it.
  final PremiumPurchaseAttemptStore? attempts;
  final String? Function()? _currentOwnerTag;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PremiumPurchaseResult>? _wait;
  PremiumPlanKind? _expected;
  String? _attemptId;
  bool _restore = false;
  bool _busy = false;
  PremiumPurchaseResult? _unsolicitedGrant;

  /// Android: finished purchases (proof saved) awaiting a backend `active`
  /// before the store transaction is finished, by purchase token.
  final Map<String, PurchaseDetails> _awaitingVerify = {};

  /// Tokens finished (or found acknowledged) in this session.
  final Set<String> _finished = {};
  Future<void> Function(PurchaseDetails purchase)? _storeComplete;

  /// On Play, finishing a transaction acknowledges it, which must follow
  /// server verification and binding. StoreKit keeps finishing on delivery.
  static bool get finishesAfterVerify =>
      defaultTargetPlatform == TargetPlatform.android;

  /// A purchase or restore sheet is open.
  bool get busy => _busy;

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

  bool begin({
    PremiumPlanKind? expected,
    bool restore = false,
    String? attemptId,
  }) {
    if (_busy) return false;
    _busy = true;
    _restore = restore;
    _expected = expected;
    _attemptId = attemptId;
    _wait = Completer<PremiumPurchaseResult>();
    return true;
  }

  void end() {
    _busy = false;
    _wait = null;
    _expected = null;
    _attemptId = null;
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
    _storeComplete = completePurchase;
    final finish = finishesAfterVerify ? _holdForVerify : completePurchase;
    for (final purchase in purchases) {
      StorePurchaseStreamDiagnostics.recordPurchase(purchase);
      if (finishesAfterVerify &&
          _finished.contains(_tokenOf(purchase)) &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        // Already verified and finished in this session: a redelivery.
        continue;
      }
      await _handle(purchase, finish, persistRetryCredentials);
    }
  }

  /// Takes the place of finishing on Android: the transaction is kept,
  /// unacknowledged, until [finishVerified].
  Future<void> _holdForVerify(PurchaseDetails purchase) async {
    final token = _tokenOf(purchase);
    if (token.isNotEmpty) _awaitingVerify[token] = purchase;
  }

  /// See [StorePurchaseFinisher.finishVerified].
  Future<void> finishVerified(
    String purchaseToken, {
    required bool storeAcknowledged,
  }) async {
    final purchase = _awaitingVerify.remove(purchaseToken);
    if (purchase == null) return;
    final complete = _storeComplete;
    if (storeAcknowledged || complete == null) {
      if (storeAcknowledged) _finished.add(purchaseToken);
      return;
    }
    try {
      await complete(purchase);
      _finished.add(purchaseToken);
    } catch (_) {
      // Still verified and bound server-side, whose retry acknowledges it;
      // kept so the next active verdict tries again.
      _awaitingVerify[purchaseToken] = purchase;
    }
  }

  static String _tokenOf(PurchaseDetails purchase) =>
      purchase.verificationData.serverVerificationData;

  Future<void> _handle(
    PurchaseDetails purchase,
    Future<void> Function(PurchaseDetails purchase) completePurchase,
    PersistRetryCredentials? persistRetryCredentials,
  ) async {
    final ledger = attempts;
    final recognized = PremiumStoreCatalog.kindFor(purchase.productID) != null;
    if (ledger == null || !recognized) {
      return _handleUnrouted(purchase, completePurchase, persistRetryCredentials);
    }
    final route = _route(ledger, purchase);
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Store PENDING: nothing paid, no receipt, never acknowledged or
        // granted. Keep (or create) the device lock, remember the store's
        // id so a later answer can be matched, and answer the waiter now.
        await _try(() async {
          var attempt = route.match;
          if (attempt != null) {
            if (route.ref != null && attempt.storeRef != route.ref) {
              attempt = attempt.copyWith(storeRef: route.ref);
              await ledger.replace(attempt);
            }
          } else {
            attempt = PremiumPurchaseAttempt(
              ownerTag: route.owner ?? 'unattributed',
              platform: _platform,
              productId: purchase.productID,
              attemptId:
                  'store-${route.ref ?? DateTime.now().microsecondsSinceEpoch}',
              sinceUtc: DateTime.now().toUtc(),
              storeRef: route.ref,
            );
            await ledger.begin(attempt);
          }
          // The store's token for this unfinished purchase: lets its owner's
          // backend ask Play for the definitive outcome later.
          final token = purchase.verificationData.serverVerificationData;
          if (token.isNotEmpty) {
            await ledger.savePendingToken(attempt.attemptId, token);
          }
          final kept = attempt.attemptId;
          await _supersedeLost(ledger, attempt.ownerTag, purchase.productID, kept);
        });
        _complete(PremiumPurchaseResult.pending());
        return;
      case PurchaseStatus.error:
      case PurchaseStatus.canceled:
        // Only an answer matched to THIS transaction (its store id, or the
        // sheet we have open) releases its lock. Anything else is ignored.
        final match = route.match;
        if (match != null) {
          await _try(
            () => ledger.release(
              (a) => a.attemptId == match.attemptId,
              why: purchase.status == PurchaseStatus.canceled
                  ? 'store_cancelled'
                  : 'store_error',
            ),
          );
          // A store error on a same-plan retry may mean a transaction does
          // exist: withdraw the retry until a fresh clean store check.
          if (purchase.status == PurchaseStatus.error &&
              match.attemptId == _attemptId) {
            await _try(() async {
              for (final a in ledger.all()) {
                if (a.ownerTag == match.ownerTag &&
                    a.productId == purchase.productID &&
                    a.storeRef == null &&
                    !a.parked) {
                  await ledger.replace(a.copyWith(clearCleanCheck: true));
                }
              }
            });
          }
        }
        _complete(
          purchase.status == PurchaseStatus.canceled
              ? PremiumPurchaseResult.cancelled()
              : PremiumPurchaseResult.failed(),
        );
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final current = _currentOwnerTag?.call();
        // An explicit Restore claims untagged purchases for the signed-in
        // account; the backend still refuses one bound to another account.
        final owner = route.owner ?? (_restore ? current : null);
        if (owner == null) {
          // Fail closed: no owner can be established. Not saved, not
          // acknowledged; the store keeps redelivering it.
          StorePurchaseStreamDiagnostics.logDropped(
            reason: 'unattributed_delivery',
            status: purchase.status,
            recognized: true,
            expected: _expected,
          );
          return;
        }
        if (owner == current) {
          final result = await StorePurchaseTerminalHandler.apply(
            purchase: purchase,
            kind: PremiumStoreCatalog.kindFor(purchase.productID),
            expected: _expected,
            restore: _restore,
            persistRetryCredentials: persistRetryCredentials,
            completePurchase: completePurchase,
          );
          // The receipt is saved for its owner: the lock is done.
          if (result != null && result.granted) {
            final match = route.match;
            await _try(() async {
              await ledger.release(
                (a) =>
                    (match != null && a.attemptId == match.attemptId) ||
                    (a.ownerTag == owner &&
                        a.productId == purchase.productID &&
                        a.storeRef != null &&
                        !a.parked),
                why: 'purchased',
              );
              await _supersedeLost(ledger, owner, purchase.productID, null);
            });
          }
          if (result != null) _complete(result);
          return;
        }
        await _park(ledger, purchase, owner, route, completePurchase);
        return;
    }
  }

  /// Another account's purchase finished here. Its proof goes to that
  /// owner's slot only; the signed-in account gets no token, no save, no
  /// verify and no grant. Its transaction is finished only once the proof
  /// is durable (StoreKit) or once its owner's backend verified it (Play),
  /// and the device stays locked until the owner signs in and verifies it.
  Future<void> _park(
    PremiumPurchaseAttemptStore ledger,
    PurchaseDetails purchase,
    String owner,
    _Route route,
    Future<void> Function(PurchaseDetails purchase) completePurchase,
  ) async {
    final proof = StorePurchaseTerminalHandler.credentialsOf(purchase);
    if (!proof.isComplete) return;
    try {
      await ledger.park(owner, proof);
      final match = route.match;
      if (match != null) {
        await ledger.replace(
          match.copyWith(parked: true, storeRef: route.ref),
        );
      } else {
        await ledger.begin(
          PremiumPurchaseAttempt(
            ownerTag: owner,
            platform: _platform,
            productId: purchase.productID,
            attemptId:
                'parked-${route.ref ?? PremiumPurchaseAttemptStore.refHash(proof.purchaseToken)}',
            sinceUtc: DateTime.now().toUtc(),
            storeRef: route.ref,
            parked: true,
          ),
        );
      }
    } catch (_) {
      StorePurchaseStreamDiagnostics.logDropped(
        reason: 'park_persist_failed',
        status: purchase.status,
        recognized: true,
        expected: _expected,
      );
      return;
    }
    if (purchase.pendingCompletePurchase) await completePurchase(purchase);
  }

  _Route _route(PremiumPurchaseAttemptStore ledger, PurchaseDetails purchase) {
    final raw = _refOf(purchase);
    final ref = raw == null ? null : PremiumPurchaseAttemptStore.refHash(raw);
    final all = ledger.all();
    PremiumPurchaseAttempt? match;
    if (ref != null) {
      for (final a in all) {
        if (a.storeRef == ref) match = a;
      }
    }
    final expected = _expected;
    final expectedId = expected == null
        ? null
        : PremiumStoreCatalog.idFor(expected);
    if (match == null &&
        _attemptId != null &&
        expectedId == purchase.productID) {
      for (final a in all) {
        if (a.attemptId == _attemptId) match = a;
      }
    }
    var owner = _accountTagOf(purchase) ?? match?.ownerTag;
    if (match == null && owner != null) {
      // The store now shows a transaction for an account and product whose
      // earlier attempt never got a token (app died, store silent): it is
      // that attempt's transaction, so the lock becomes resolvable.
      for (final a in all) {
        if (a.ownerTag == owner &&
            a.productId == purchase.productID &&
            a.storeRef == null &&
            !a.parked) {
          match = a;
        }
      }
    }
    if (owner == null) {
      final sameProduct = [
        for (final a in all)
          if (a.productId == purchase.productID) a,
      ];
      if (sameProduct.length == 1) owner = sameProduct.single.ownerTag;
    }
    return _Route(ref: ref, match: match, owner: owner);
  }

  /// Lost attempts (never given a token) for [owner] and [productId] are
  /// superseded once the store accepted a transaction for the same product:
  /// that transaction is now the one that holds, and resolves, the lock.
  static Future<void> _supersedeLost(
    PremiumPurchaseAttemptStore ledger,
    String owner,
    String productId,
    String? keep,
  ) => ledger.release(
    (a) =>
        a.ownerTag == owner &&
        a.productId == productId &&
        a.storeRef == null &&
        !a.parked &&
        a.attemptId != keep,
    why: 'superseded_by_retry',
  );

  static String? _refOf(PurchaseDetails purchase) {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isNotEmpty) return token;
    final id = purchase.purchaseID;
    return id != null && id.isNotEmpty ? id : null;
  }

  /// The obfuscated account the purchase was launched for (Play only).
  static String? _accountTagOf(PurchaseDetails purchase) {
    if (purchase is! GooglePlayPurchaseDetails) return null;
    final tag = purchase.billingClientPurchase.obfuscatedAccountId;
    return tag != null && tag.isNotEmpty ? tag : null;
  }

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static Future<void> _try(Future<void> Function() body) async {
    try {
      await body();
    } catch (_) {
      // The next store answer or query decides again; the lock written
      // before the sheet opened still stands.
    }
  }

  /// Direct constructions without a ledger, and unknown products.
  Future<void> _handleUnrouted(
    PurchaseDetails purchase,
    Future<void> Function(PurchaseDetails purchase) completePurchase,
    PersistRetryCredentials? persistRetryCredentials,
  ) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        if (PremiumStoreCatalog.kindFor(purchase.productID) == null) return;
        _complete(PremiumPurchaseResult.pending());
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

class _Route {
  const _Route({required this.ref, required this.match, required this.owner});

  /// Hash of the store's own id for this transaction, when it has one.
  final String? ref;

  /// The ledger entry this delivery belongs to, if it can be matched.
  final PremiumPurchaseAttempt? match;

  /// The account tag it belongs to, if it can be established.
  final String? owner;
}
