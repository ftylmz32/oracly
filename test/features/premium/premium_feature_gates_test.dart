/// Premium gate matrix + delayed grant recovery.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_feature_gates.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
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
      PremiumVerifyResult.active();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gate matrix: SoulMate gated; core rituals free; OR preview free', () {
    expect(
      PremiumFeatureGates.ritualRequiresPremium(OraclyFeatureId.soulMate),
      isTrue,
    );
    expect(
      PremiumFeatureGates.ritualRequiresPremium(OraclyFeatureId.tarot),
      isFalse,
    );
    expect(
      PremiumFeatureGates.ritualRequiresPremium(OraclyFeatureId.aiChat),
      isFalse,
    );
    expect(PremiumFeatureGates.orChamberPreviewAllowedWhenFree, isTrue);
    expect(
      PremiumFeatureGates.capabilityRequiresPremium(
        PremiumGatedCapability.orFullConversation,
      ),
      isTrue,
    );
    expect(
      PremiumFeatureGates.capabilityRequiresPremium(
        PremiumGatedCapability.soulMateGeneration,
      ),
      isTrue,
    );
  });

  test('unsolicited grant during prepare activates entitlement once', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final port = _LateGrantPort();
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      port,
      _ActiveVerifier(),
    );
    expect(await service.isActive(), isFalse);
    await service.preparePurchase();
    expect(await service.isActive(), isTrue);
    expect(await service.activePlan(), PremiumPlanKind.yearly);
    await service.preparePurchase();
    expect(port.consumeCalls, 2);
  });
}

class _LateGrantPort implements PremiumPurchasePort {
  PremiumPurchaseResult? _late = PremiumPurchaseResult.restored(
    PremiumPlanKind.yearly,
    credentials: const PremiumPurchaseCredentials(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'late-token',
    ),
  );
  int consumeCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.unavailable();

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreUnavailable();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async {
    consumeCalls += 1;
    final grant = _late;
    _late = null;
    return grant;
  }
}
