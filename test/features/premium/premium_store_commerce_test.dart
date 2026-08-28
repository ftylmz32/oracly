/// Real commerce port: catalog, grants, cancel/fail/pending, gems isolation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: 'app.oracly.premium.yearly',
  purchaseToken: 'token',
);

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

  test('product catalog IDs are stable placeholders for store consoles', () {
    expect(PremiumStoreCatalog.monthlyId, 'app.oracly.premium.monthly');
    expect(PremiumStoreCatalog.yearlyId, 'app.oracly.premium.yearly');
    expect(PremiumStoreCatalog.lifetimeId, 'app.oracly.premium.lifetime');
    expect(
      PremiumStoreCatalog.kindFor(PremiumStoreCatalog.yearlyId),
      PremiumPlanKind.yearly,
    );
    expect(PremiumStoreCatalog.isSubscription(PremiumPlanKind.lifetime), isFalse);
  });

  test('unavailable products never configure purchase', () async {
    final port = _ScriptedPort(
      configured: false,
      purchaseResult: PremiumPurchaseResult.unavailable(),
    );
    final service = PremiumService(premiumRepo, userRepo, port);
    await service.preparePurchase();
    expect(service.purchaseConfigured, isFalse);
    final result = await service.purchase(PremiumPlanKind.yearly);
    expect(result.granted, isFalse);
    expect(await service.isActive(), isFalse);
  });

  test('purchase success grants once and hydrates store price', () async {
    final port = _ScriptedPort(
      configured: true,
      prices: {PremiumPlanKind.yearly: '₺899,99'},
      purchaseResult: PremiumPurchaseResult.granted(
        PremiumPlanKind.yearly,
        credentials: _creds,
      ),
    );
    final service = PremiumService(premiumRepo, userRepo, port, _ActiveVerifier());
    await service.preparePurchase();
    expect(service.purchaseConfigured, isTrue);
    final plans = await service.getPlans();
    expect(
      plans.firstWhere((p) => p.kind == PremiumPlanKind.yearly).price,
      '₺899,99',
    );
    final first = await service.purchase(PremiumPlanKind.yearly);
    expect(first.granted, isTrue);
    expect(await service.isActive(), isTrue);
    expect(port.purchaseCalls, 1);

    final again = await service.purchase(PremiumPlanKind.yearly);
    expect(again.granted, isTrue);
    expect(port.purchaseCalls, 2);
    expect(await service.isActive(), isTrue);
  });

  test('cancel fail pending never grant', () async {
    for (final outcome in [
      PremiumPurchaseResult.cancelled(),
      PremiumPurchaseResult.failed(),
      PremiumPurchaseResult.pending(),
    ]) {
      SharedPreferences.setMockInitialValues({});
      final s = LocalStorage(await SharedPreferences.getInstance());
      final service = PremiumService(
        MockPremiumRepository(s),
        MockUserRepository(s),
        _ScriptedPort(configured: true, purchaseResult: outcome),
      );
      final result = await service.purchase(PremiumPlanKind.monthly);
      expect(result.granted, isFalse, reason: '${outcome.outcome}');
      expect(await service.isActive(), isFalse);
    }
  });

  test('restore success empty and failed', () async {
    final ok = PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPort(
        configured: true,
        restoreResult: PremiumPurchaseResult.restored(
          PremiumPlanKind.lifetime,
          credentials: _creds,
        ),
      ),
      _ActiveVerifier(),
    );
    final restored = await ok.restore();
    expect(restored.granted, isTrue);
    expect(await ok.isActive(), isTrue);
    expect(await ok.activePlan(), PremiumPlanKind.lifetime);

    SharedPreferences.setMockInitialValues({});
    final emptyStorage = LocalStorage(await SharedPreferences.getInstance());
    final empty = PremiumService(
      MockPremiumRepository(emptyStorage),
      MockUserRepository(emptyStorage),
      _ScriptedPort(
        configured: true,
        restoreResult: PremiumPurchaseResult.noneFound(),
      ),
    );
    final none = await empty.restore();
    expect(none.granted, isFalse);
    expect(none.message, PremiumCopy.restoreNone);
    expect(await empty.isActive(), isFalse);
  });

  test('controller blocks rapid duplicate taps while busy', () async {
    final port = _SlowPort();
    final controller = PremiumStatusController(
      PremiumService(premiumRepo, userRepo, port, _ActiveVerifier()),
    );
    await controller.load();
    expect(controller.purchaseConfigured, isTrue);

    final first = controller.purchase();
    final second = controller.purchase();
    final a = await first;
    final b = await second;
    expect(port.calls, 1);
    expect(a.granted || b.granted, isTrue);
    expect(a.granted && b.granted, isFalse);
  });

  test('premium grant does not mutate gem wallet', () async {
    final gems = GemWalletService(GemWalletStore(storage));
    await gems.earn(amount: 50, reason: 'test_seed');
    final before = gems.balance;
    final service = PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPort(
        configured: true,
        purchaseResult: PremiumPurchaseResult.granted(
          PremiumPlanKind.yearly,
          credentials: _creds,
        ),
      ),
      _ActiveVerifier(),
    );
    await service.purchase(PremiumPlanKind.yearly);
    expect(gems.balance, before);
    expect(await service.isActive(), isTrue);
  });

  test('entitlement persists across service reload', () async {
    final service = PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPort(
        configured: true,
        purchaseResult: PremiumPurchaseResult.granted(
          PremiumPlanKind.monthly,
          credentials: _creds,
        ),
      ),
      _ActiveVerifier(),
    );
    await service.purchase(PremiumPlanKind.monthly);
    final reloaded = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      const UnavailablePremiumPurchase(),
    );
    expect(await reloaded.isActive(), isTrue);
    expect(await reloaded.activePlan(), PremiumPlanKind.monthly);
  });
}

class _ScriptedPort implements PremiumPurchasePort {
  _ScriptedPort({
    required this.configured,
    this.purchaseResult,
    this.restoreResult,
    this.prices = const {},
  });

  final bool configured;
  final PremiumPurchaseResult? purchaseResult;
  final PremiumPurchaseResult? restoreResult;
  final Map<PremiumPlanKind, String> prices;
  int purchaseCalls = 0;

  @override
  bool get isConfigured => configured;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => prices[plan];

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    purchaseCalls += 1;
    return purchaseResult ?? PremiumPurchaseResult.unavailable();
  }

  @override
  Future<PremiumPurchaseResult> restore() async {
    return restoreResult ?? PremiumPurchaseResult.restoreUnavailable();
  }

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

class _SlowPort implements PremiumPurchasePort {
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    calls += 1;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return PremiumPurchaseResult.granted(plan, credentials: _creds);
  }

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreUnavailable();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}