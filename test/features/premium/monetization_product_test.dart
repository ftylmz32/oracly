/// Product model — Free / Premium / Gems. No fake entitlement.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/dream/economy/dream_economy.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/palm/economy/palm_economy.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/economy/soul_mate_economy.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_dev_access.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
  });

  test('free defaults: no membership, no invented prices', () async {
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
    );
    expect(await service.isActive(), isFalse);
    expect(service.purchaseConfigured, isFalse);
    expect((await MockUserRepository(storage).getProfile()).isPremium, isFalse);
    expect(PremiumCopy.heroLead.toLowerCase(), isNot(contains('sır')));
    for (final plan in PremiumCatalogue.fallbackPlans()) {
      expect(plan.price, PremiumCopy.planPricePending);
      expect(plan.price, isNot(contains('₺')));
    }
  });

  test('premium experiences are only features that work and are gated', () {
    final gated = PremiumCatalogue.premiumExperiences;
    expect(gated, hasLength(3));
    expect(
      gated.map((b) => b.title),
      containsAll(<String>[
        SoulMateCopy.listTitle,
        PremiumCopy.benefitOrTitle,
        PremiumCopy.benefitJourneyTitle,
      ]),
    );
    expect(gated.every((b) => b.requiresPremium), isTrue);
    expect(
      PremiumCatalogue.includedCapabilities.map((b) => b.title),
      containsAll(<String>[
        PremiumCopy.benefitCoffeeTitle,
        PremiumCopy.benefitPalmTitle,
        PremiumCopy.benefitDiscoveryTitle,
        PremiumCopy.benefitAtmosphereTitle,
      ]),
    );
    expect(
      PremiumCatalogue.includedCapabilities.map((b) => b.title),
      isNot(contains(PremiumCopy.benefitOrTitle)),
    );
    expect(PremiumCatalogue.showcaseBenefits, hasLength(3));
    expect(
      PremiumCatalogue.showcaseBenefits.map((b) => b.title),
      containsAll([
        SoulMateCopy.listTitle,
        PremiumCopy.benefitOrTitle,
        PremiumCopy.benefitJourneyTitle,
      ]),
    );
  });

  test('verified store grant is the only premium entitlement', () async {
    final port = _GrantOnce();
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      port,
      _ActiveRemoteVerifier(),
    );
    expect(await service.purchase(PremiumPlanKind.yearly).then((r) => r.granted),
        isTrue);
    expect(await service.isActive(), isTrue);
    expect(service.wasAuthoritativelyVerified, isTrue);
    expect(storage.getBool('or_premium_active'), isTrue);
  });

  test('gems charge only implemented tarot; coffee, palm, dream, soulmate stay free', () {
    expect(TarotEconomy.readingCost, GemEconomy.tarotReading);
    expect(CoffeeEconomy.analysisCost, isNull);
    expect(DreamEconomy.analysisCost, isNull);
    expect(PalmEconomy.analysisCost, isNull);
    expect(SoulMateEconomy.drawCost, isNull);
  });

  test('debug override never writes membership', () async {
    expect(PremiumDevOverride.isActive, isFalse);
    expect(SoulMateDevAccess.allowsTestAccess, isFalse);
    expect(storage.getBool('or_premium_active'), isNull);
    expect((await MockUserRepository(storage).getProfile()).isPremium, isFalse);
  });

  test('release and profile cannot activate the debug override', () {
    PremiumDevOverride.debugEnvironment = AppEnvironment.production;
    PremiumDevOverride.debugFlag = true;
    expect(PremiumDevOverride.isActive, isFalse);
    PremiumDevOverride.resetDebug();
    expect(kReleaseMode && PremiumDevOverride.isActive, isFalse);
    expect(
      const UnavailablePremiumPurchase().isConfigured,
      isFalse,
    );
  });
}

class _GrantOnce implements PremiumPurchasePort {
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
      PremiumPurchaseResult.granted(
        plan,
        credentials: const PremiumPurchaseCredentials(
          platform: 'android',
          productId: 'app.oracly.premium.yearly',
          purchaseToken: 'token',
        ),
      );

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreUnavailable();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

class _ActiveRemoteVerifier implements PremiumEntitlementVerifier {
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
