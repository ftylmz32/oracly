/// Review access must survive a fresh PremiumService/PremiumStatusController
/// instance built on the SAME underlying storage — simulating an app
/// restart (or adb install -r, which preserves app data on Android) without
/// re-entering the reviewer code. Reproduces the reported bug: activation
/// succeeded in one session, but a fresh session showed isPremium=false.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/review_access_result.dart';
import 'package:oracly_new/features/premium/services/review_access_service.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Server behavior is controlled per test — a real activate() call over the
/// network, distinguishing definitive denial from transient failure exactly
/// like the real HttpReviewAccessService.
class _ScriptedReviewAccessService implements ReviewAccessService {
  _ScriptedReviewAccessService(this._respond);

  final ReviewAccessResult Function(String code) _respond;
  int activateCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ReviewAccessResult> activate(String code) async {
    activateCalls += 1;
    return _respond(code);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Simulates the app process restarting: SAME persisted storage (the
  /// SharedPreferences mock backing survives within one test, and a real
  /// device's SharedPreferences/EncryptedSharedPreferences survive process
  /// restart and `adb install -r`), but brand-new repository/service/
  /// PremiumService/PremiumStatusController object graph — exactly what
  /// `main.dart` constructs fresh on every cold start.
  Future<PremiumStatusController> freshSessionOn(
    LocalStorage storage,
    SecureStorage secure, {
    required ReviewAccessResult Function(String code) serverResponse,
  }) async {
    final premium = MockPremiumRepository(storage, secureStorage: secure);
    final users = MockUserRepository(storage);
    final reviewRepo = ReviewAccessRepository(storage, secureStorage: secure);
    final reviewService = _ScriptedReviewAccessService(serverResponse);
    final controller = PremiumStatusController(
      PremiumService(
        premium,
        users,
        const UnavailablePremiumPurchase(),
        null,
        reviewRepo,
        reviewService,
      ),
    );
    await controller.load();
    return controller;
  }

  test(
    'activate → persist → fresh controller/service instance → reconcile → isPremium true',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();

      // Session 1: activation.
      final session1 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => code == 'PLAY-REVIEW-1'
            ? ReviewAccessResult.granted()
            : ReviewAccessResult.denied('invalid_code'),
      );
      final granted = await session1.activateReviewAccess('PLAY-REVIEW-1');
      expect(granted, isTrue);
      expect(session1.isPremium, isTrue);

      // "App restart": brand-new controller/service/repository objects,
      // same underlying storage, reviewer code never re-entered.
      final session2 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => code == 'PLAY-REVIEW-1'
            ? ReviewAccessResult.granted()
            : ReviewAccessResult.denied('invalid_code'),
      );
      expect(session2.isPremium, isTrue);
      expect(session2.isReviewAccessActive, isTrue);
    },
  );

  test(
    'invalid/revoked stored review access → reconcile on a fresh instance → isPremium false',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();

      final session1 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => ReviewAccessResult.granted(),
      );
      expect(await session1.activateReviewAccess('PLAY-REVIEW-1'), isTrue);

      // Operator disabled the code server-side — a definitive denial.
      final session2 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) =>
            ReviewAccessResult.denied('invalid_code'),
      );
      expect(session2.isPremium, isFalse);
      expect(session2.isReviewAccessActive, isFalse);
    },
  );

  test(
    'commerce inactive + valid stored review access, fresh instance → isPremium true',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();
      final session1 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => ReviewAccessResult.granted(),
      );
      await session1.activateReviewAccess('PLAY-REVIEW-1');

      // Fresh instance; UnavailablePremiumPurchase means commerce is
      // permanently non-configured/inactive here — review access must
      // still win.
      final session2 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => ReviewAccessResult.granted(),
      );
      expect(session2.entitlement.allowsPremiumFeatures, isFalse);
      expect(session2.isPremium, isTrue);
    },
  );

  test(
    'no stored review access on a fresh instance → unchanged normal (free) behavior',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();

      final session = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => ReviewAccessResult.denied('invalid_code'),
      );
      expect(session.isPremium, isFalse);
      expect(session.isReviewAccessActive, isFalse);
    },
  );

  test(
    'transient revalidation failure on restart does NOT wipe a previously '
    'valid grant (the actual fix for the reported bug)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();

      final session1 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => ReviewAccessResult.granted(),
      );
      expect(await session1.activateReviewAccess('PLAY-REVIEW-1'), isTrue);

      // Cold-start connectivity not ready yet / transient network failure —
      // NOT a definitive "the code is wrong" answer.
      final session2 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) =>
            ReviewAccessResult.denied('network_or_parse', definitive: false),
      );
      expect(session2.isPremium, isTrue);
      expect(session2.isReviewAccessActive, isTrue);

      // And once the network is back, a real definitive denial still works.
      final session3 = await freshSessionOn(
        storage,
        secure,
        serverResponse: (code) => ReviewAccessResult.denied('invalid_code'),
      );
      expect(session3.isPremium, isFalse);
    },
  );
}
