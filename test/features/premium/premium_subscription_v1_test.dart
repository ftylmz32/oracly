/// Premium subscription V1 — one status, no fake grant, honest billing port.
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
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/deck_selection/deck_selection_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('defaults to free and shares one persisted flag', () async {
    final service = PremiumService(premiumRepo, userRepo);
    expect(await service.isActive(), isFalse);
    expect(service.isActiveNow, isFalse);
    expect((await userRepo.getProfile()).isPremium, isFalse);
  });

  test('unavailable purchase never grants premium', () async {
    final service = PremiumService(premiumRepo, userRepo);
    final result = await service.purchase(PremiumPlanKind.yearly);
    expect(service.purchaseConfigured, isFalse);
    expect(result.granted, isFalse);
    expect(result.message, PremiumCopy.purchaseUnavailable);
    expect(await service.isActive(), isFalse);
    expect((await userRepo.getProfile()).isPremium, isFalse);
  });

  test('restore without store config never grants', () async {
    final service = PremiumService(
      premiumRepo,
      userRepo,
      const UnavailablePremiumPurchase(),
    );
    final result = await service.restore();
    expect(result.granted, isFalse);
    expect(result.message, PremiumCopy.restoreUnavailable);
    expect(await service.isActive(), isFalse);
  });

  test('cancelled and failed purchases never grant', () async {
    final cancelled = PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPurchase(PremiumPurchaseResult.cancelled()),
    );
    final cancelResult = await cancelled.purchase(PremiumPlanKind.monthly);
    expect(cancelResult.message, PremiumCopy.purchaseCancelled);
    expect(await cancelled.isActive(), isFalse);

    final failed = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _ScriptedPurchase(PremiumPurchaseResult.failed()),
    );
    final failResult = await failed.purchase(PremiumPlanKind.yearly);
    expect(failResult.message, PremiumCopy.purchaseFailed);
    expect(await failed.isActive(), isFalse);
  });

  test('verified purchase grants and survives restart', () async {
    final service = PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPurchase(
        PremiumPurchaseResult.granted(PremiumPlanKind.monthly, credentials: _creds),
      ),
      _ActiveVerifier(),
    );
    final result = await service.purchase(PremiumPlanKind.monthly);
    expect(result.granted, isTrue);
    expect(await service.isActive(), isTrue);
    expect(await service.activePlan(), PremiumPlanKind.monthly);
    expect((await userRepo.getProfile()).isPremium, isTrue);

    final restarted = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
    );
    expect(await restarted.isActive(), isTrue);
    expect(await restarted.activePlan(), PremiumPlanKind.monthly);
  });

  test('verified restore grants when a prior purchase exists', () async {
    final service = PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPurchase(
        PremiumPurchaseResult.noneFound(),
        restore: PremiumPurchaseResult.restored(PremiumPlanKind.yearly, credentials: _creds),
      ),
      _ActiveVerifier(),
    );
    final none = await PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPurchase(
        PremiumPurchaseResult.failed(),
        restore: PremiumPurchaseResult.noneFound(),
      ),
    ).restore();
    expect(none.granted, isFalse);
    expect(none.message, PremiumCopy.restoreNone);

    final restored = await service.restore();
    expect(restored.granted, isTrue);
    expect(await service.isActive(), isTrue);
  });

  test('plan selection does not grant premium', () async {
    final status = PremiumStatusController(PremiumService(premiumRepo, userRepo));
    await status.load();
    status.selectPlan(PremiumPlanKind.lifetime);
    expect(status.selectedPlan, PremiumPlanKind.lifetime);
    expect(status.isPremium, isFalse);
    expect(await premiumRepo.isPremiumActive(), isFalse);
  });

  test('premium grant does not change gem balance', () async {
    final wallet = GemWalletService(GemWalletStore(storage));
    expect(wallet.balance, 0);
    final service = PremiumService(
      premiumRepo,
      userRepo,
      _ScriptedPurchase(
        PremiumPurchaseResult.granted(PremiumPlanKind.yearly, credentials: _creds),
      ),
      _ActiveVerifier(),
    );
    await service.purchase(PremiumPlanKind.yearly);
    expect(await service.isActive(), isTrue);
    expect(wallet.balance, 0);
  });

  test('only the real classic deck is selectable', () {
    final classic =
        TarotDeckCatalogue.decks.firstWhere((d) => d.id == 'classic');
    expect(classic.requiresPremium, isFalse);
    expect(TarotDeckCatalogue.decks, hasLength(1));
    expect(TarotDeckCatalogue.isSelectable('classic'), isTrue);
    expect(TarotDeckCatalogue.isSelectable('golden'), isFalse);
    expect(TarotDeckCatalogue.isUnbuilt('moon_oracle'), isTrue);
  });
}

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
      PremiumVerifyResult.active();
}

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: 'app.oracly.premium.yearly',
  purchaseToken: 'test-token',
);

class _ScriptedPurchase implements PremiumPurchasePort {
  _ScriptedPurchase(this._purchase, {PremiumPurchaseResult? restore})
      : _restore = restore ?? PremiumPurchaseResult.restoreUnavailable();

  final PremiumPurchaseResult _purchase;
  final PremiumPurchaseResult _restore;

  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => isConfigured;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      _purchase;

  @override
  Future<PremiumPurchaseResult> restore() async => _restore;

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}
