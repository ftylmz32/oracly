/// Real Play Billing / StoreKit purchase port via in_app_purchase.
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
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
    StorePendingWrite? persistStorePending,
    StorePendingWrite? clearStorePending,
    // Only tests shorten it; production keeps [purchaseAnswerWindow].
    Duration answerWindow = purchaseAnswerWindow,
  }) : _iap = client ?? PluginStoreIapClient(iap),
       // ignore: prefer_initializing_formals
       _answerWindow = answerWindow,
       // ignore: prefer_initializing_formals
       _persistRetryCredentials = persistRetryCredentials,
       // ignore: prefer_initializing_formals
       _persistStorePending = persistStorePending,
       _session = StorePremiumPurchaseSession(
         onStorePending: persistStorePending,
         onStoreSettled: clearStorePending,
       );

  final StoreIapClient _iap;

  /// Durable, UNVERIFIED recovery store for terminal store events. Optional
  /// so direct constructions keep working; production wiring always
  /// supplies it (premium_purchase_port_provider).
  final PersistRetryCredentials? _persistRetryCredentials;

  /// Whether terminal events are persisted before store completion.
  @visibleForTesting
  bool get persistsRecovery => _persistRetryCredentials != null;

  /// Durable record of a purchase the store has not finished.
  final StorePendingWrite? _persistStorePending;

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
    if (!_session.begin(expected: plan, restore: false)) {
      return PremiumPurchaseResult.failed();
    }
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) return PremiumPurchaseResult.failed();
      var silent = false;
      final result = await _session.wait(
        _answerWindow,
        onTimeout: () {
          silent = true;
          return PremiumPurchaseResult.pending();
        },
      );
      // A launched purchase with no terminal answer may still be charged
      // later (slow payment). Hold it like a reported PENDING; a late
      // purchased / declined event or a store query settles it.
      if (silent) await _recordUnfinished(product.id);
      return result;
    } catch (_) {
      return PremiumPurchaseResult.failed();
    } finally {
      _session.end();
    }
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

  Future<void> _recordUnfinished(String productId) async {
    final write = _persistStorePending;
    if (write == null) return;
    try {
      await write(productId);
    } catch (_) {}
  }

  @override
  Future<Set<String>?> refreshStorePurchases() async {
    final client = _iap;
    if (client is! StorePurchaseQueryClient) return null;
    _listen();
    final purchases = await (client as StorePurchaseQueryClient)
        .queryPurchases();
    if (purchases == null) return null;
    final unfinished = <String>{};
    final finished = <PurchaseDetails>[];
    for (final purchase in purchases) {
      if (PremiumStoreCatalog.kindFor(purchase.productID) == null) continue;
      if (purchase.status == PurchaseStatus.pending) {
        unfinished.add(purchase.productID);
      } else if ((purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) &&
          purchase.pendingCompletePurchase) {
        // Finished after the app stopped listening (e.g. a slow payment
        // approved later). Only unacknowledged ones: an older, already
        // acknowledged purchase is Restore's job, never a silent grant.
        finished.add(purchase);
      }
    }
    if (finished.isNotEmpty) {
      await _session.onPurchases(
        finished,
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
