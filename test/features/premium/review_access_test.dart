/// Google Play / App Store reviewer access — separate from real Premium.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/models/review_access_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/review_access_service.dart';
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
  }) async => PremiumVerifyResult.active('test');
}

/// Configured-but-idle store port — lets the reconciler reach real local
/// premium state instead of short-circuiting to [PremiumEntitlementState.unavailable].
class _ConfiguredPort implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {}
  @override
  String? priceLabel(PremiumPlanKind plan) => null;
  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.failed();
  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreFailed();
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

/// Fake server: grants only for [validCode], counts every call, never
/// touches billing/store vocabulary.
class _FakeReviewAccessService implements ReviewAccessService {
  _FakeReviewAccessService({this.validCode = 'PLAY-REVIEW-1'});

  String? validCode;
  int activateCalls = 0;
  final submittedCodes = <String>[];

  @override
  bool get isConfigured => true;

  @override
  Future<ReviewAccessResult> activate(String code) async {
    activateCalls += 1;
    submittedCodes.add(code);
    if (validCode != null && code == validCode) {
      return ReviewAccessResult.granted();
    }
    return ReviewAccessResult.denied('invalid_code');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    (
      MockPremiumRepository,
      MockUserRepository,
      ReviewAccessRepository,
      _FakeReviewAccessService,
    )
  >
  deps() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final secure = InMemorySecureStorage();
    return (
      MockPremiumRepository(storage, secureStorage: secure),
      MockUserRepository(storage),
      ReviewAccessRepository(storage, secureStorage: secure),
      _FakeReviewAccessService(),
    );
  }

  test('valid review code unlocks Premium when no store is configured', () async {
    final (premium, users, reviewRepo, reviewService) = await deps();
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        const UnavailablePremiumPurchase(),
        null,
        reviewRepo,
        reviewService,
      ),
    );
    await status.load();
    expect(status.isPremium, isFalse);

    final granted = await status.activateReviewAccess('PLAY-REVIEW-1');
    expect(granted, isTrue);
    expect(status.isPremium, isTrue);
    expect(status.isReviewAccessActive, isTrue);
    // Distinguishable: commerce entitlement is untouched.
    expect(status.entitlement, isNot(PremiumEntitlementState.active));
  });

  test('invalid review code grants nothing and persists nothing', () async {
    final (premium, users, reviewRepo, reviewService) = await deps();
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        const UnavailablePremiumPurchase(),
        null,
        reviewRepo,
        reviewService,
      ),
    );
    await status.load();

    final granted = await status.activateReviewAccess('wrong-code');
    expect(granted, isFalse);
    expect(status.isPremium, isFalse);
    expect(reviewRepo.isGrantedLocally, isFalse);
  });

  test(
    'review access does not spoof store purchase verification: no purchase '
    'credentials, no authoritative flag, no active plan are ever written',
    () async {
      final (premium, users, reviewRepo, reviewService) = await deps();
      final status = PremiumStatusController(
        PremiumService(
          premium,
          users,
          const UnavailablePremiumPurchase(),
          null,
          reviewRepo,
          reviewService,
        ),
      );
      await status.load();
      await status.activateReviewAccess('PLAY-REVIEW-1');

      expect(status.isPremium, isTrue);
      // The commerce repository — what real billing verification reads —
      // is completely untouched by a review-access grant.
      expect(premium.isActiveNow, isFalse);
      expect(premium.wasAuthoritativelyVerified, isFalse);
      expect(await premium.activePlan(), isNull);
      expect(premium.readPurchaseCredentials(), isNull);
    },
  );

  test('normal paid entitlement is unaffected by review access and always wins', () async {
    final (premium, users, reviewRepo, reviewService) = await deps();
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'real-store-token',
      ),
    );
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        _ConfiguredPort(),
        _ActiveVerifier(),
        reviewRepo,
        reviewService,
      ),
    );
    await status.load();

    expect(status.entitlement, PremiumEntitlementState.active);
    expect(status.isPremium, isTrue);
    // Real entitlement short-circuits the review-access check entirely.
    expect(status.isReviewAccessActive, isFalse);
    expect(reviewService.activateCalls, 0);
  });

  test(
    'disabling the code server-side revokes an already-granted local session '
    'on the next reconcile — no client update required',
    () async {
      final (premium, users, reviewRepo, reviewService) = await deps();
      final status = PremiumStatusController(
        PremiumService(
          premium,
          users,
          const UnavailablePremiumPurchase(),
          null,
          reviewRepo,
          reviewService,
        ),
      );
      await status.load();
      await status.activateReviewAccess('PLAY-REVIEW-1');
      expect(status.isPremium, isTrue);

      // Operator unsets REVIEW_ACCESS_CODE_HASH server-side.
      reviewService.validCode = null;
      await status.refresh();

      expect(status.isPremium, isFalse);
      expect(status.isReviewAccessActive, isFalse);
      expect(reviewRepo.isGrantedLocally, isFalse);
    },
  );

  test('review access code is never logged/exposed via entitlementMessage', () async {
    final (premium, users, reviewRepo, reviewService) = await deps();
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        const UnavailablePremiumPurchase(),
        null,
        reviewRepo,
        reviewService,
      ),
    );
    await status.load();
    await status.activateReviewAccess('PLAY-REVIEW-1');
    expect(status.entitlementMessage ?? '', isNot(contains('PLAY-REVIEW-1')));
  });
}
