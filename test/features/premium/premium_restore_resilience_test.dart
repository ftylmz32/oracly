/// Restore must not require a successful product catalogue query.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_iap_client.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ActiveVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async =>
      PremiumVerifyResult.active('test');
}

class _UnverifiedVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async =>
      PremiumVerifyResult.unverified('backend_rejected');
}

class _FakeIap implements StoreIapClient {
  _FakeIap({
    this.available = true,
    this.products = const [],
    this.queryThrows = false,
    this.restoreEmits = const [],
  });

  final bool available;
  final List<ProductDetails> products;
  final bool queryThrows;
  final List<PurchaseDetails> restoreEmits;

  final _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();
  int restoreCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    if (queryThrows) throw StateError('query failed');
    return ProductDetailsResponse(
      productDetails: products,
      notFoundIDs: identifiers
          .where((id) => products.every((p) => p.id != id))
          .toList(),
    );
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    scheduleMicrotask(() {
      _purchaseController.add(List<PurchaseDetails>.from(restoreEmits));
    });
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  void dispose() => _purchaseController.close();
}

ProductDetails _yearlyProduct() => ProductDetails(
      id: PremiumStoreCatalog.yearlyId,
      title: 'Yearly',
      description: 'Premium',
      price: 'TRY 899.99',
      rawPrice: 899.99,
      currencyCode: 'TRY',
    );

PurchaseDetails _restoredYearly({String token = 'server-token'}) =>
    PurchaseDetails(
      purchaseID: 'txn-restore-1',
      productID: PremiumStoreCatalog.yearlyId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: token,
        source: 'google_play',
      ),
      transactionDate: '1',
      status: PurchaseStatus.restored,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late MockPremiumRepository premiumRepo;
  late MockUserRepository userRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    premiumRepo = MockPremiumRepository(storage);
    userRepo = MockUserRepository(storage);
  });

  test('store available + catalogue available -> restore works', () async {
    final iap = _FakeIap(
      available: true,
      products: [_yearlyProduct()],
      restoreEmits: [_restoredYearly()],
    );
    addTearDown(iap.dispose);
    final port = StorePremiumPurchase(client: iap);
    await port.prepare();
    expect(port.isConfigured, isTrue);
    expect(port.canAttemptRestore, isTrue);

    final service = PremiumService(
      premiumRepo,
      userRepo,
      port,
      _ActiveVerifier(),
    )..forceReleaseMode = true;
    final result = await service.restore();
    expect(iap.restoreCalls, 1);
    expect(result.granted, isTrue);
    expect(result.outcome, PremiumPurchaseOutcome.restored);
    expect(await service.isActive(), isTrue);
    expect(premiumRepo.wasAuthoritativelyVerified, isTrue);
  });

  test('store available + catalogue empty -> restore still attempted', () async {
    final iap = _FakeIap(
      available: true,
      products: const [],
      restoreEmits: [_restoredYearly()],
    );
    addTearDown(iap.dispose);
    final port = StorePremiumPurchase(client: iap);
    await port.prepare();
    expect(port.isConfigured, isFalse);
    expect(port.canAttemptRestore, isTrue);

    final service = PremiumService(
      premiumRepo,
      userRepo,
      port,
      _ActiveVerifier(),
    )..forceReleaseMode = true;
    final result = await service.restore();
    expect(iap.restoreCalls, 1);
    expect(result.granted, isTrue);
    expect(await service.isActive(), isTrue);
  });

  test('store available + catalogue query failed -> restore still attempted',
      () async {
    final iap = _FakeIap(
      available: true,
      queryThrows: true,
      restoreEmits: [_restoredYearly()],
    );
    addTearDown(iap.dispose);
    final port = StorePremiumPurchase(client: iap);
    await port.prepare();
    expect(port.isConfigured, isFalse);
    expect(port.canAttemptRestore, isTrue);

    final service = PremiumService(
      premiumRepo,
      userRepo,
      port,
      _ActiveVerifier(),
    )..forceReleaseMode = true;
    final result = await service.restore();
    expect(iap.restoreCalls, 1);
    expect(result.granted, isTrue);
  });

  test(
    'controller restore proceeds when catalogue empty but store available',
    () async {
      final iap = _FakeIap(
        available: true,
        products: const [],
        restoreEmits: [_restoredYearly()],
      );
      addTearDown(iap.dispose);
      final port = StorePremiumPurchase(client: iap);
      final service = PremiumService(
        premiumRepo,
        userRepo,
        port,
        _ActiveVerifier(),
      )..forceReleaseMode = true;
      final status = PremiumStatusController(service);
      await status.load();
      expect(status.purchaseConfigured, isFalse);
      expect(service.canAttemptRestore, isTrue);

      final result = await status.restore();
      expect(iap.restoreCalls, 1);
      expect(result.granted, isTrue);
      expect(status.isPremium, isTrue);
    },
  );

  test('store unavailable -> honest unavailable result', () async {
    final iap = _FakeIap(available: false, products: [_yearlyProduct()]);
    addTearDown(iap.dispose);
    final port = StorePremiumPurchase(client: iap);
    await port.prepare();
    expect(port.canAttemptRestore, isFalse);
    expect(port.isConfigured, isFalse);

    final result = await port.restore();
    expect(iap.restoreCalls, 0);
    expect(result.outcome, PremiumPurchaseOutcome.restoreUnavailable);
    expect(result.message, PremiumCopy.restoreUnavailable);
    expect(result.granted, isFalse);
  });

  test('restored purchase still follows verifier/grant path', () async {
    final iap = _FakeIap(
      available: true,
      products: const [],
      restoreEmits: [_restoredYearly()],
    );
    addTearDown(iap.dispose);
    final port = StorePremiumPurchase(client: iap);
    await port.prepare();

    final denied = PremiumService(
      premiumRepo,
      userRepo,
      port,
      _UnverifiedVerifier(),
    )..forceReleaseMode = true;
    final deniedResult = await denied.restore();
    expect(iap.restoreCalls, 1);
    expect(deniedResult.granted, isFalse);
    expect(deniedResult.outcome, PremiumPurchaseOutcome.unverified);
    expect(await denied.isActive(), isFalse);
    expect(premiumRepo.wasAuthoritativelyVerified, isFalse);
  });

  test('no restored purchase never grants Premium', () async {
    final iap = _FakeIap(
      available: true,
      products: const [],
      restoreEmits: const [],
    );
    addTearDown(iap.dispose);
    final port = StorePremiumPurchase(client: iap);
    await port.prepare();
    expect(port.isConfigured, isFalse);
    expect(port.canAttemptRestore, isTrue);

    final service = PremiumService(
      premiumRepo,
      userRepo,
      port,
      _ActiveVerifier(),
    )..forceReleaseMode = true;
    final result = await service.restore();
    expect(iap.restoreCalls, 1);
    expect(result.granted, isFalse);
    expect(result.outcome, PremiumPurchaseOutcome.noneFound);
    expect(await service.isActive(), isFalse);
  });

  test('restored purchase without credentials never grants', () async {
    final iap = _FakeIap(
      available: true,
      products: const [],
      restoreEmits: [_restoredYearly(token: '')],
    );
    addTearDown(iap.dispose);
    final port = StorePremiumPurchase(client: iap);
    await port.prepare();
    final service = PremiumService(
      premiumRepo,
      userRepo,
      port,
      _ActiveVerifier(),
    )..forceReleaseMode = true;
    final result = await service.restore();
    expect(result.granted, isFalse);
    expect(await service.isActive(), isFalse);
  });
}
