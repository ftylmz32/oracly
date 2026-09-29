/// P4E — a Premium object captured for A cannot authorize B.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/services/premium_grant_policy.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/premium_credential_keys.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/models/review_access_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_links.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_plan_availability.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/review_access_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const captured = 'owner-a';
  const credentials = PremiumPurchaseCredentials(
    platform: 'android',
    productId: 'oracly_premium_monthly',
    purchaseToken: 'token-a',
    transactionId: 'txn-a',
  );

  test('a repository captured for A stays closed after B is current', () async {
    final storage = LocalStorage.ephemeral();
    await storage.setString('or_local_data_owner_uid', captured);
    var live = captured;
    final repo = MockPremiumRepository(
      storage,
      secureStorage: InMemorySecureStorage(),
      ownerAccessAllowed: () {
        final local = storage.getString('or_local_data_owner_uid')?.trim();
        return live == captured && local == captured;
      },
    );
    expect(repo.ownerAccessReady, isTrue);

    live = 'owner-b';
    await storage.setString('or_local_data_owner_uid', 'owner-b');
    expect(repo.ownerAccessReady, isFalse);

    final user = MockUserRepository(storage);
    final policy = PremiumGrantPolicy(
      premium: repo,
      user: user,
      verifier: _ActiveVerifier(),
      forceReleaseMode: true,
    );
    final committed = await policy.grant(
      PremiumPlanKind.monthly,
      authoritative: true,
      credentials: credentials,
    );
    expect(committed, isFalse);
    expect(storage.getBool(MockPremiumRepository.activeKey), isNot(true));
    expect(await repo.readPurchaseCredentials(), isNull);
  });

  test('purchase result after A becomes B does not grant B', () async {
    final outcome = await _lateStoreOutcome(
      PremiumPurchaseResult.granted(
        PremiumPlanKind.yearly,
        credentials: credentials,
      ),
      purchase: true,
    );
    expect(outcome.outcome.outcome, PremiumPurchaseOutcome.unverified);
    expect(
      outcome.storage.getBool(MockPremiumRepository.activeKey),
      isNot(true),
    );
  });

  test('restore result after A becomes B does not grant B', () async {
    final outcome = await _lateStoreOutcome(
      PremiumPurchaseResult.restored(
        PremiumPlanKind.monthly,
        credentials: credentials,
      ),
      purchase: false,
    );
    expect(outcome.outcome.outcome, PremiumPurchaseOutcome.unverified);
    expect(
      outcome.storage.getBool(MockPremiumRepository.activeKey),
      isNot(true),
    );
  });

  test('a disposed premium controller does not notify', () async {
    final storage = LocalStorage.ephemeral();
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
    );
    final controller = PremiumStatusController(service);
    var notified = 0;
    controller.addListener(() => notified++);
    controller.dispose();
    controller.selectPlan(PremiumPlanKind.monthly);
    expect(notified, 0);
  });

  test(
    'review access for A does not persist onto B or write credentials',
    () async {
      final storage = LocalStorage.ephemeral();
      final secure = InMemorySecureStorage();
      await storage.setString('or_local_data_owner_uid', captured);
      var live = captured;
      final repo = MockPremiumRepository(
        storage,
        secureStorage: secure,
        ownerAccessAllowed: () {
          final local = storage.getString('or_local_data_owner_uid')?.trim();
          return live == captured && local == captured;
        },
      );
      final service = PremiumService(
        repo,
        MockUserRepository(storage),
        _ClosedPort(),
        _ActiveVerifier(),
        ReviewAccessRepository(storage, secureStorage: secure),
        _GrantingReview(),
      );
      live = 'owner-b';
      await storage.setString('or_local_data_owner_uid', 'owner-b');
      final result = await service.activateReviewAccessResult('review-code');
      expect(result.granted, isFalse);
      expect(storage.getBool(ReviewAccessRepository.grantedKey), isNot(true));
      expect(await secure.read(PremiumCredentialKeys.purchaseToken), isNull);
      expect(storage.getBool(MockPremiumRepository.activeKey), isNot(true));
    },
  );

  test('review access copy is localized in TR EN and RU', () {
    for (final code in ['tr', 'en', 'ru']) {
      OraclyL10n.bind(code);
      final label = OraclyL10n.t('premium.review_access');
      expect(label, isNot('premium.review_access'));
      expect(label, isNotEmpty);
      expect(OraclyL10n.t('premium.review_access_activate'), isNotEmpty);
    }
    OraclyL10n.bind('en');
    expect(OraclyL10n.t('premium.review_access'), 'Review access');
    OraclyL10n.bind('tr');
    expect(OraclyL10n.t('premium.review_access'), 'İnceleme erişimi');
  });

  test('iOS exposes monthly and yearly only', () {
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.lifetime,
        platform: TargetPlatform.iOS,
      ),
      isFalse,
    );
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.monthly,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.yearly,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.lifetime,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
  });

  testWidgets('premium links stay inside 320 and large text', (tester) async {
    OraclyL10n.bind('tr');
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: const Scaffold(body: PremiumReferenceLinks()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('İnceleme erişimi'), findsOneWidget);
  });
}

class _LateOutcome {
  _LateOutcome(this.outcome, this.storage);
  final PremiumPurchaseResult outcome;
  final LocalStorage storage;
}

Future<_LateOutcome> _lateStoreOutcome(
  PremiumPurchaseResult storeResult, {
  required bool purchase,
}) async {
  final storage = LocalStorage.ephemeral();
  await storage.setString('or_local_data_owner_uid', 'owner-a');
  var live = 'owner-a';
  final repo = MockPremiumRepository(
    storage,
    secureStorage: InMemorySecureStorage(),
    ownerAccessAllowed: () {
      final local = storage.getString('or_local_data_owner_uid')?.trim();
      return live == 'owner-a' && local == 'owner-a';
    },
  );
  final port = _HoldPort(storeResult);
  final service = PremiumService(
    repo,
    MockUserRepository(storage),
    port,
    _ActiveVerifier(),
  )..forceReleaseMode = true;
  final pending = purchase
      ? service.purchase(PremiumPlanKind.yearly)
      : service.restore();
  await _until(() => port.holding);
  live = 'owner-b';
  await storage.setString('or_local_data_owner_uid', 'owner-b');
  port.release();
  final result = await pending;
  return _LateOutcome(result, storage);
}

Future<void> _until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) fail('condition was not reached');
    await Future<void>.delayed(Duration.zero);
  }
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
  }) async => PremiumVerifyResult.active();
}

class _HoldPort implements PremiumPurchasePort {
  _HoldPort(this.result);

  final PremiumPurchaseResult result;
  Completer<void>? _hold;
  bool holding = false;

  void release() {
    final hold = _hold;
    if (hold != null && !hold.isCompleted) hold.complete();
  }

  Future<PremiumPurchaseResult> _wait() async {
    _hold = Completer<void>();
    holding = true;
    await _hold!.future;
    return result;
  }

  @override
  bool get isConfigured => true;

  @override
  bool get canAttemptRestore => true;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => '₺1';

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) => _wait();

  @override
  Future<PremiumPurchaseResult> restore() => _wait();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

class _ClosedPort implements PremiumPurchasePort {
  const _ClosedPort();

  @override
  bool get isConfigured => false;

  @override
  bool get canAttemptRestore => false;

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
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

class _GrantingReview implements ReviewAccessService {
  @override
  bool get isConfigured => true;

  @override
  Future<ReviewAccessResult> activate(String code) async =>
      ReviewAccessResult.granted();
}
