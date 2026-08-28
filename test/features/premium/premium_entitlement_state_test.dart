/// Premium entitlement states — commerce-backed, never UI-only flags.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
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

class _Port implements PremiumPurchasePort {
  _Port({
    this.configured = true,
    this.purchaseResult,
    this.restoreResult,
    this.throwOnPurchase = false,
  });

  bool configured;
  PremiumPurchaseResult? purchaseResult;
  PremiumPurchaseResult? restoreResult;
  final bool throwOnPurchase;

  static const _creds = PremiumPurchaseCredentials(
    platform: 'android',
    productId: 'app.oracly.premium.yearly',
    purchaseToken: 'token',
  );

  @override
  bool get isConfigured => configured;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    if (throwOnPurchase) throw StateError('store');
    return purchaseResult ??
        PremiumPurchaseResult.granted(plan, credentials: _creds);
  }

  @override
  Future<PremiumPurchaseResult> restore() async {
    return restoreResult ??
        PremiumPurchaseResult.restored(
          PremiumPlanKind.yearly,
          credentials: _creds,
        );
  }

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(MockPremiumRepository, MockUserRepository)> repos() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    return (MockPremiumRepository(storage), MockUserRepository(storage));
  }

  test('unavailable store settles to unavailable', () async {
    final (premium, users) = await repos();
    final status = PremiumStatusController(
      PremiumService(premium, users, const UnavailablePremiumPurchase()),
    );
    await status.load();
    expect(status.entitlement, PremiumEntitlementState.unavailable);
    expect(status.isPremium, isFalse);
  });

  test('stale local premium flag stays locked without store', () async {
    final (premium, users) = await repos();
    await premium.activatePlan(PremiumPlanKind.yearly);
    expect(await premium.isPremiumActive(), isTrue);
    final status = PremiumStatusController(
      PremiumService(premium, users, const UnavailablePremiumPurchase()),
    );
    await status.load();
    expect(status.purchaseConfigured, isFalse);
    expect(status.entitlement, PremiumEntitlementState.unavailable);
    expect(status.isPremium, isFalse);
  });

  test('configured free user settles to inactive', () async {
    final (premium, users) = await repos();
    final status = PremiumStatusController(
      PremiumService(premium, users, _Port()),
    );
    await status.load();
    expect(status.entitlement, PremiumEntitlementState.inactive);
  });

  test('active membership from repository is active entitlement', () async {
    final (premium, users) = await repos();
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    final status = PremiumStatusController(
      PremiumService(premium, users, _Port()),
    );
    await status.load();
    expect(status.entitlement, PremiumEntitlementState.active);
  });

  test('purchase is pending then active after commerce grant', () async {
    final (premium, users) = await repos();
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        _Port(
          purchaseResult: PremiumPurchaseResult.granted(
            PremiumPlanKind.yearly,
            credentials: _Port._creds,
          ),
        ),
        _ActiveVerifier(),
      ),
    );
    await status.load();
    final future = status.purchase();
    expect(status.entitlement, PremiumEntitlementState.pending);
    await future;
    expect(status.entitlement, PremiumEntitlementState.active);
  });

  test('restore is restoring then active after commerce restore', () async {
    final (premium, users) = await repos();
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        _Port(
          restoreResult: PremiumPurchaseResult.restored(
            PremiumPlanKind.yearly,
            credentials: _Port._creds,
          ),
        ),
        _ActiveVerifier(),
      ),
    );
    await status.load();
    final future = status.restore();
    expect(status.entitlement, PremiumEntitlementState.restoring);
    await future;
    expect(status.entitlement, PremiumEntitlementState.active);
  });

  test('commerce failure becomes error without unlocking', () async {
    final (premium, users) = await repos();
    final status = PremiumStatusController(
      PremiumService(premium, users, _Port(throwOnPurchase: true)),
    );
    await status.load();
    final result = await status.purchase();
    expect(result.granted, isFalse);
    expect(status.entitlement, PremiumEntitlementState.error);
    expect(status.isPremium, isFalse);
  });

  test('store pending outcome settles without permanent busy lock', () async {
    final (premium, users) = await repos();
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        _Port(purchaseResult: PremiumPurchaseResult.pending()),
      ),
    );
    await status.load();
    await status.purchase();
    expect(status.entitlement, isNot(PremiumEntitlementState.pending));
    expect(status.busy, isFalse);
    expect(status.isPremium, isFalse);
    expect(status.entitlementMessage, isNotNull);
  });
}
