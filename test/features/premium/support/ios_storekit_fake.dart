/// Offline StoreKit double for the iOS Premium client path.
library;

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_iap_client.dart';

class FakeStoreKit implements StoreIapClient {
  FakeStoreKit({
    this.available = true,
    this.products = const [],
    this.queryError,
    this.queryThrows = false,
    this.queryHangs = false,
    this.returnUnrequested = false,
    this.availabilityThrows = false,
  });

  bool available;
  List<ProductDetails> products;
  IAPError? queryError;
  bool queryThrows;
  bool queryHangs;
  bool returnUnrequested;
  bool availabilityThrows;

  /// When set, the next query waits for this gate before answering.
  Completer<void>? queryGate;
  List<PurchaseDetails> restoreEmits = const [];
  List<PurchaseDetails>? buyEmits;
  bool buyStarted = true;

  final queriedIds = <Set<String>>[];
  final responses = <ProductDetailsResponse>[];
  int restoreCalls = 0;
  int buyCalls = 0;
  int completeCalls = 0;

  final _stream = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Future<bool> isAvailable() async =>
      availabilityThrows ? throw UnsupportedError('no bridge') : available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queriedIds.add(Set<String>.of(identifiers));
    final gate = queryGate;
    if (gate != null) {
      queryGate = null;
      await gate.future;
    }
    if (queryHangs) return Completer<ProductDetailsResponse>().future;
    if (queryThrows) throw StateError('storekit bridge failure');
    final hits = [
      for (final p in products)
        if (returnUnrequested || identifiers.contains(p.id)) p,
    ];
    final response = ProductDetailsResponse(
      productDetails: queryError == null ? hits : const [],
      notFoundIDs: [
        for (final id in identifiers)
          if (queryError != null || hits.every((p) => p.id != id)) id,
      ],
      error: queryError,
    );
    responses.add(response);
    return response;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    final emits = List<PurchaseDetails>.of(restoreEmits);
    scheduleMicrotask(() => _stream.add(emits));
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalls++;
    final emits = buyEmits;
    if (buyStarted && emits != null) {
      scheduleMicrotask(() => _stream.add(List<PurchaseDetails>.of(emits)));
    }
    return buyStarted;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completeCalls++;
  }
}

ProductDetails storeProduct(String id, String price) => ProductDetails(
  id: id,
  title: id,
  description: 'Premium',
  price: price,
  rawPrice: 1,
  currencyCode: 'TRY',
);

ProductDetails get monthlyProduct =>
    storeProduct(PremiumStoreCatalog.monthlyId, 'STORE-MONTHLY');
ProductDetails get yearlyProduct =>
    storeProduct(PremiumStoreCatalog.yearlyId, 'STORE-YEARLY');
ProductDetails get lifetimeProduct =>
    storeProduct(PremiumStoreCatalog.lifetimeId, 'STORE-LIFETIME');

PurchaseDetails storeTransaction(
  String productId,
  PurchaseStatus status, {
  String token = 'server-token',
}) =>
    PurchaseDetails(
        purchaseID: 'txn-$productId-${status.name}',
        productID: productId,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: token,
          source: 'app_store',
        ),
        transactionDate: '1',
        status: status,
      )
      ..pendingCompletePurchase =
          status == PurchaseStatus.purchased ||
          status == PurchaseStatus.restored;

class ActiveVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async => PremiumVerifyResult.active('test');
}
