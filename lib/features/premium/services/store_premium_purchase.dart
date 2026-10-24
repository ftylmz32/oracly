/// Real Play Billing / StoreKit purchase port via in_app_purchase.
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../../../core/storage/premium_purchase_attempt_store.dart';
import '../models/premium_purchase_result.dart';
import '../models/store_catalog_snapshot.dart';
import 'premium_plan_availability.dart';
import 'premium_purchase_port.dart';
import 'premium_store_catalog.dart';
import 'store_catalog_query.dart';
import 'store_iap_client.dart';
import 'store_premium_purchase_session.dart';

class StorePremiumPurchase
    implements
        PremiumPurchasePort,
        StoreCatalogDiagnosticsSource,
        StorePurchaseRefresher {
  StorePremiumPurchase({
    InAppPurchase? iap,
    StoreIapClient? client,
    PersistRetryCredentials? persistRetryCredentials,
    PremiumPurchaseAttemptStore? attempts,
    String? Function()? currentOwnerUid,
    // Only tests shorten it; production keeps [purchaseAnswerWindow].
    Duration answerWindow = purchaseAnswerWindow,
  }) : _iap = client ?? PluginStoreIapClient(iap),
       // ignore: prefer_initializing_formals
       _answerWindow = answerWindow,
       // ignore: prefer_initializing_formals
       _persistRetryCredentials = persistRetryCredentials,
       // ignore: prefer_initializing_formals
       _attempts = attempts,
       // ignore: prefer_initializing_formals
       _currentOwnerUid = currentOwnerUid,
       _session = StorePremiumPurchaseSession(
         attempts: attempts,
         currentOwnerTag: () => _tagOf(currentOwnerUid?.call()),
       );

  final StoreIapClient _iap;

  /// Durable, UNVERIFIED recovery store for terminal store events. Optional
  /// so direct constructions keep working; production wiring always
  /// supplies it (premium_purchase_port_provider).
  final PersistRetryCredentials? _persistRetryCredentials;

  /// Whether terminal events are persisted before store completion.
  @visibleForTesting
  bool get persistsRecovery => _persistRetryCredentials != null;

  /// Device ledger of unfinished purchases, owner-tagged. Production
  /// wiring always supplies it with [_currentOwnerUid].
  final PremiumPurchaseAttemptStore? _attempts;
  final String? Function()? _currentOwnerUid;

  static String? _tagOf(String? uid) => uid == null || uid.isEmpty
      ? null
      : PremiumPurchaseAttemptStore.ownerTag(uid);

  final StorePremiumPurchaseSession _session;
  final Duration _answerWindow;

  /// How long a purchase sheet may stay unanswered before the purchase is
  /// treated as unfinished (held), never as failed.
  static const purchaseAnswerWindow = Duration(seconds: 120);

  /// True when the IAP plugin/store reports available (restore may proceed).
  bool _storeAvailable = false;

  /// True when at least one requested product loaded (purchase may proceed).
  bool _configured = false;
  final Map<String, ProductDetails> _products = {};
  StoreCatalogSnapshot? _catalogSnapshot;

  @override
  bool get isConfigured => _configured;

  /// Store/plugin ready independent of product catalogue success.
  @override
  bool get canAttemptRestore => _storeAvailable;

  @override
  StoreCatalogSnapshot? get catalogSnapshot => _catalogSnapshot;

  /// Non-null only for products the store actually returned.
  @override
  String? priceLabel(PremiumPlanKind plan) =>
      _products[PremiumStoreCatalog.idFor(plan)]?.price;

  Future<void> dispose() => _session.cancel();

  @override
  Future<void> prepare() async {
    try {
      final load = await StoreCatalogQuery.load(
        _iap,
        PremiumPlanAvailability.storeQueryIds(),
        onAvailable: _listen,
      );
      _storeAvailable = load.storeAvailable;
      _catalogSnapshot = load.snapshot;
      _products
        ..clear()
        ..addEntries(load.products.map((p) => MapEntry(p.id, p)));
    } catch (error) {
      _storeAvailable = false;
      _products.clear();
      _catalogSnapshot = StoreCatalogSnapshot(
        at: DateTime.now().toUtc(),
        storeAvailable: false,
        availabilityExceptionType: StoreCatalogSnapshot.exceptionType(error),
      );
    }
    _configured = _products.isNotEmpty;
  }

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    if (!_configured) return PremiumPurchaseResult.unavailable();
    if (!PremiumPlanAvailability.isPurchasable(plan)) {
      return PremiumPurchaseResult.unavailable();
    }
    final product = _products[PremiumStoreCatalog.idFor(plan)];
    if (product == null) return PremiumPurchaseResult.unavailable();
    if (_session.busy) return PremiumPurchaseResult.failed();

    // The lock must be durable BEFORE the store sheet exists: no record,
    // no sheet. It names the account that pays (as an opaque tag, also
    // sent to Play), so whatever the store answers later, and whoever is
    // signed in then, it can only ever be credited to that account.
    final attempts = _attempts;
    String? ownerTag;
    String? attemptId;
    if (attempts != null) {
      ownerTag = _tagOf(_currentOwnerUid?.call());
      if (ownerTag == null) return PremiumPurchaseResult.unavailable();
      attemptId = '${DateTime.now().microsecondsSinceEpoch}-${product.id}';
      try {
        await attempts.begin(
          PremiumPurchaseAttempt(
            ownerTag: ownerTag,
            platform: defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
            productId: product.id,
            attemptId: attemptId,
            sinceUtc: DateTime.now().toUtc(),
          ),
        );
      } catch (_) {
        return PremiumPurchaseResult.failed();
      }
    }
    if (!_session.begin(expected: plan, restore: false, attemptId: attemptId)) {
      await _releaseAttempt(attemptId);
      return PremiumPurchaseResult.failed();
    }
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: ownerTag,
        ),
      );
      if (!started) {
        // The store refused to open the sheet: no transaction exists.
        await _releaseAttempt(attemptId);
        return PremiumPurchaseResult.failed();
      }
      // Silence past the window is unfinished, not failed: the lock stays
      // until a store answer for this transaction arrives.
      return await _session.wait(
        _answerWindow,
        onTimeout: PremiumPurchaseResult.pending,
      );
    } catch (_) {
      // Unknown whether a transaction started: keep the lock.
      return PremiumPurchaseResult.failed();
    } finally {
      _session.end();
    }
  }

  Future<void> _releaseAttempt(String? attemptId) async {
    final attempts = _attempts;
    if (attempts == null || attemptId == null) return;
    try {
      await attempts.release((a) => a.attemptId == attemptId);
    } catch (_) {}
  }

  @override
  bool get holdsUnfinishedPurchase => _attempts?.holdsAny ?? false;

  @override
  Future<List<StorePendingToken>> pendingTokensForCurrentOwner() async {
    final attempts = _attempts;
    final tag = _tagOf(_currentOwnerUid?.call());
    if (attempts == null || tag == null) return const [];
    final out = <StorePendingToken>[];
    for (final a in attempts.all()) {
      if (a.ownerTag != tag || a.parked) continue;
      final token = await attempts.readPendingToken(a.attemptId);
      if (token == null) continue;
      out.add(
        StorePendingToken(
          attemptId: a.attemptId,
          platform: a.platform,
          productId: a.productId,
          token: token,
        ),
      );
    }
    return out;
  }

  @override
  Future<void> settleStorePending(String attemptId) async {
    await _attempts?.release((a) => a.attemptId == attemptId);
  }

  @override
  Future<bool> recoverParked(PersistRetryCredentials save) async {
    final attempts = _attempts;
    final tag = _tagOf(_currentOwnerUid?.call());
    if (attempts == null || tag == null) return false;
    final proof = await attempts.readParked(tag);
    if (proof == null) return false;
    // Into the owner's own credential store first; only then are the
    // parked copy and its device lock dropped. A kill in between repeats.
    await save(proof);
    await attempts.clearParked(tag);
    await attempts.release(
      (a) => a.ownerTag == tag && a.parked && a.productId == proof.productId,
    );
    return true;
  }

  @override
  Future<PremiumPurchaseResult> restore() async {
    // Restore needs the store/plugin, not a successful product catalogue query.
    if (!_storeAvailable) return PremiumPurchaseResult.restoreUnavailable();
    _listen();
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

  void _listen() => _session.listen(_iap, _persistRetryCredentials);

  @override
  Future<Set<String>?> refreshStorePurchases() async {
    final client = _iap;
    if (client is! StorePurchaseQueryClient) return null;
    _listen();
    final purchases = await (client as StorePurchaseQueryClient)
        .queryPurchases();
    if (purchases == null) return null;
    final unfinished = <String>{};
    final routed = <PurchaseDetails>[];
    for (final purchase in purchases) {
      if (PremiumStoreCatalog.kindFor(purchase.productID) == null) continue;
      if (purchase.status == PurchaseStatus.pending) {
        // Owner-routed like a stream delivery: keeps or creates the lock.
        unfinished.add(purchase.productID);
        routed.add(purchase);
      } else if ((purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) &&
          purchase.pendingCompletePurchase) {
        // Finished after the app stopped listening (e.g. a slow payment
        // approved later). Only unacknowledged ones: an older, already
        // acknowledged purchase is Restore's job, never a silent grant.
        routed.add(purchase);
      }
    }
    if (routed.isNotEmpty) {
      await _session.onPurchases(
        routed,
        _iap.completePurchase,
        persistRetryCredentials: _persistRetryCredentials,
      );
    }
    return unfinished;
  }

  static bool get supportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
