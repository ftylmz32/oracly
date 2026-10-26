/// #44 P0 — a Play purchase the store has not finished (PENDING, a slow
/// payment, or no answer within the purchase window) is held durably for
/// the current owner: no second payment can start (plan switch, double
/// tap, restart), nothing is acknowledged or granted before a real
/// PURCHASED receipt verifies, and only a terminal store answer, or the
/// user's own successful store check, releases the hold.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/premium_purchase_attempt_store.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_store_pending.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/providers/premium_purchase_port_provider.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_iap_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/ios_storekit_fake.dart' show monthlyProduct, yearlyProduct;

PurchaseDetails _play(
  String productId,
  PurchaseStatus status, {
  bool acknowledged = false,
}) =>
    PurchaseDetails(
        purchaseID: 'GPA.$productId',
        productID: productId,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'play-token-$productId',
          source: 'google_play',
        ),
        transactionDate: '1',
        status: status,
      )
      ..pendingCompletePurchase =
          !acknowledged &&
          (status == PurchaseStatus.purchased ||
              status == PurchaseStatus.restored);

/// What Play last said about each token, as the backend would read it.
final _playStatus = <String, PurchaseStatus>{};

void _remember(List<PurchaseDetails> purchases) {
  for (final p in purchases) {
    final token = p.verificationData.serverVerificationData;
    if (token.isNotEmpty) _playStatus[token] = p.status;
  }
}

/// The backend's real answer for a token Play still holds as pending.
PremiumVerifyResult? _playVerdict(String token) =>
    _playStatus[token] == PurchaseStatus.pending
        ? PremiumVerifyResult.pending('subscription_pending')
        : null;

/// Play billing with a purchase stream and `queryPurchasesAsync`.
class _FakePlay implements StoreIapClient, StorePurchaseQueryClient {
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();

  /// Emitted right after a purchase sheet launches; empty = store silence.
  List<PurchaseDetails> onBuy = const [];

  /// `queryPurchasesAsync` answer; null = the store could not be read.
  List<PurchaseDetails>? query = const [];

  int buyCalls = 0;
  int restoreCalls = 0;
  int queryCalls = 0;
  final completed = <String>[];

  void emit(List<PurchaseDetails> purchases) {
    _remember(purchases);
    _stream.add(purchases);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [monthlyProduct, yearlyProduct],
        notFoundIDs: const [],
      );

  @override
  Future<void> restorePurchases() async => restoreCalls++;

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalls++;
    final emits = onBuy;
    _remember(emits);
    if (emits.isNotEmpty) scheduleMicrotask(() => _stream.add(emits));
    return true;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);

  @override
  Future<List<PurchaseDetails>?> queryPurchases() async {
    queryCalls++;
    _remember(query ?? const []);
    return query;
  }
}

class _Verifier implements PremiumEntitlementVerifier {
  PremiumVerifyResult answer = PremiumVerifyResult.active('subscription_active');
  final tokens = <String>[];

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    tokens.add(purchaseToken);
    return _playVerdict(purchaseToken) ?? answer;
  }
}

class _App {
  _App(this.repo, this.play, this.verifier, this.controller, this.attempts);
  final MockPremiumRepository repo;
  final PremiumPurchaseAttemptStore attempts;
  final _FakePlay play;
  final _Verifier verifier;
  final PremiumStatusController controller;
}

/// One app launch over [storage]: a fresh port, service and controller.
Future<_App> _launch(
  LocalStorage storage,
  InMemorySecureStorage secure, {
  _FakePlay? play,
  _Verifier? verifier,
  Duration answerWindow = const Duration(milliseconds: 40),
}) async {
  final repo = MockPremiumRepository(storage, secureStorage: secure);
  final store = play ?? _FakePlay();
  final verify = verifier ?? _Verifier();
  final attempts = PremiumPurchaseAttemptStore(storage, secure);
  final port = createStorePremiumPurchase(
    () => repo,
    client: store,
    answerWindow: answerWindow,
    attempts: attempts,
    currentOwnerUid: () => storage.getString(UserLocalDataIsolation.ownerKey),
  );
  final service = PremiumService(
    repo,
    MockUserRepository(storage),
    port,
    verify,
  )..forceReleaseMode = true;
  final controller = PremiumStatusController(service);
  await controller.load();
  return _App(repo, store, verify, controller, attempts);
}

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStorage storage;
  late InMemorySecureStorage secure;

  setUp(() async {
    _playStatus.clear();
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.open();
    await storage.setString(UserLocalDataIsolation.ownerKey, 'uid-a');
    secure = InMemorySecureStorage();
  });

  test('slow payment approved later: held without receipt or ack, then '
      'verified from the real receipt — one store purchase, no early grant',
      () async {
    final app = await _launch(storage, secure);
    app.play.onBuy = [_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.pending)];
    app.controller.selectPlan(PremiumPlanKind.monthly);

    final result = await app.controller.purchase();
    expect(result.outcome, PremiumPurchaseOutcome.pending);
    expect(app.controller.entitlement, PremiumEntitlementState.pending);
    expect(app.controller.pendingKind, PremiumPendingKind.store);
    expect(app.controller.isPremium, isFalse);
    expect(app.attempts.all().single.productId, PremiumStoreCatalog.monthlyId);
    expect(await app.repo.readPurchaseCredentials(), isNull,
        reason: 'no receipt exists while the store is pending');
    expect(app.play.completed, isEmpty, reason: 'PENDING is never acknowledged');
    // Only ever a status question about this owner's own token; Play says
    // pending, so nothing is granted.
    expect(app.verifier.tokens,
        everyElement('play-token-${PremiumStoreCatalog.monthlyId}'));

    app.controller.selectPlan(PremiumPlanKind.yearly);
    await app.controller.purchase();
    expect(app.play.buyCalls, 1, reason: 'plan switch cannot start a 2nd payment');

    app.play.emit([_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.purchased)]);
    await _settle();
    expect((await app.repo.readPurchaseCredentials())?.purchaseToken,
        'play-token-${PremiumStoreCatalog.monthlyId}');
    expect(app.attempts.all(), isEmpty);
    expect(app.controller.isPremium, isFalse, reason: 'not before verification');

    await app.controller.checkPendingStatus();
    expect(app.controller.entitlement, PremiumEntitlementState.active);
    // #44: acknowledged once, and only after the backend verified it.
    expect(app.play.completed, [PremiumStoreCatalog.monthlyId]);
    // Late delivery verify + active refresh: always this one receipt.
    expect(app.verifier.tokens, isNotEmpty);
    expect(app.verifier.tokens,
        everyElement('play-token-${PremiumStoreCatalog.monthlyId}'));
    expect(app.play.buyCalls, 1);
    expect(app.play.restoreCalls, 0);
  });

  test('slow payment declined later: hold released, nothing granted', () async {
    final app = await _launch(storage, secure);
    app.play.onBuy = [_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.pending)];
    app.controller.selectPlan(PremiumPlanKind.monthly);
    await app.controller.purchase();
    expect(app.controller.pendingKind, PremiumPendingKind.store);

    app.play.emit([_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.error)]);
    await _settle();
    expect(app.attempts.all(), isEmpty);
    await app.controller.forceReconcile();
    expect(app.controller.entitlement, PremiumEntitlementState.inactive);
    expect(app.controller.isPremium, isFalse);
    expect(app.play.completed, isEmpty);
  });

  test('no store answer past the purchase window is held, not failed', () async {
    final app = await _launch(storage, secure);
    app.controller.selectPlan(PremiumPlanKind.monthly);
    final result = await app.controller.purchase();
    expect(result.outcome, isNot(PremiumPurchaseOutcome.failed));
    expect(app.controller.entitlement, PremiumEntitlementState.pending);
    expect(app.controller.pendingKind, PremiumPendingKind.store);
    expect(app.attempts.all(), isNotEmpty);

    await app.controller.purchase();
    await app.controller.purchase();
    expect(app.play.buyCalls, 1);
  });

  test('a purchased event after the window still lands on the same purchase',
      () async {
    final app = await _launch(storage, secure);
    app.controller.selectPlan(PremiumPlanKind.monthly);
    await app.controller.purchase();
    expect(app.controller.pendingKind, PremiumPendingKind.store);

    app.play.emit([_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.purchased)]);
    await _settle();
    await app.controller.checkPendingStatus();
    expect(app.controller.entitlement, PremiumEntitlementState.active);
    expect(app.play.buyCalls, 1);
  });

  test('a cancelled sheet is not held', () async {
    final app = await _launch(storage, secure);
    app.play.onBuy = [_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.canceled)];
    app.controller.selectPlan(PremiumPlanKind.monthly);
    final result = await app.controller.purchase();
    expect(result.outcome, PremiumPurchaseOutcome.cancelled);
    expect(app.attempts.all(), isEmpty);
    expect(app.controller.entitlement, isNot(PremiumEntitlementState.pending));
  });

  test('double tap starts one store purchase', () async {
    final app = await _launch(storage, secure);
    app.play.onBuy = [_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.pending)];
    app.controller.selectPlan(PremiumPlanKind.monthly);
    await Future.wait([app.controller.purchase(), app.controller.purchase()]);
    expect(app.play.buyCalls, 1);
  });

  group('after a restart', () {
    Future<void> leavePending() async {
      final first = await _launch(storage, secure);
      first.play.onBuy = [
        _play(PremiumStoreCatalog.monthlyId, PurchaseStatus.pending),
      ];
      first.controller.selectPlan(PremiumPlanKind.monthly);
      await first.controller.purchase();
    }

    test('store still pending: held, no purchase reaches the store', () async {
      await leavePending();
      final play = _FakePlay()
        ..query = [_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.pending)];
      final app = await _launch(storage, secure, play: play);
      expect(app.controller.pendingKind, PremiumPendingKind.store);
      app.controller.selectPlan(PremiumPlanKind.yearly);
      await app.controller.purchase();
      expect(play.buyCalls, 0);
      expect(app.controller.isPremium, isFalse);
    });

    test('store finished it while the app was closed: receipt saved, '
        'acknowledged once, verified', () async {
      await leavePending();
      final play = _FakePlay()
        ..query = [
          _play(PremiumStoreCatalog.monthlyId, PurchaseStatus.purchased),
        ];
      final app = await _launch(storage, secure, play: play);
      expect(play.completed, [PremiumStoreCatalog.monthlyId]);
      expect(app.attempts.all(), isEmpty);
      expect(app.controller.entitlement, PremiumEntitlementState.active);
      expect(play.buyCalls, 0);
    });

    test('offline (store unreadable): the hold survives load and a check',
        () async {
      await leavePending();
      final play = _FakePlay()..query = null;
      final app = await _launch(storage, secure, play: play);
      expect(app.controller.pendingKind, PremiumPendingKind.store);
      await app.controller.checkPendingStatus();
      expect(app.controller.pendingKind, PremiumPendingKind.store);
      expect(app.attempts.all(), isNotEmpty);
    });

    test('an empty store answer is never a decline: not on load, not on '
        'one or two user checks apart in time', () async {
      await leavePending();
      final play = _FakePlay()..query = const [];
      final app = await _launch(storage, secure, play: play);
      expect(app.controller.pendingKind, PremiumPendingKind.store);
      await app.controller.checkPendingStatus();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await app.controller.checkPendingStatus();
      expect(app.controller.pendingKind, PremiumPendingKind.store);
      app.controller.selectPlan(PremiumPlanKind.yearly);
      await app.controller.purchase();
      expect(play.buyCalls, 0);
      expect(app.controller.isPremium, isFalse);
      expect(play.restoreCalls, 0);
    });

    test('an older acknowledged purchase is not silently restored', () async {
      await leavePending();
      final play = _FakePlay()
        ..query = [
          _play(
            PremiumStoreCatalog.yearlyId,
            PurchaseStatus.purchased,
            acknowledged: true,
          ),
        ];
      final app = await _launch(storage, secure, play: play);
      expect(play.completed, isEmpty);
      expect(await app.repo.readPurchaseCredentials(), isNull);
      expect(app.controller.isPremium, isFalse);
    });
  });

  test('account A -> B -> A: B never gets A\'s purchase; the device\'s '
      'unfinished Play payment still blocks a second charge', () async {
    final a = await _launch(storage, secure);
    a.play.onBuy = [_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.pending)];
    a.controller.selectPlan(PremiumPlanKind.monthly);
    await a.controller.purchase();
    expect(a.attempts.all(), isNotEmpty);

    // Account boundary wipe, exactly as UserLocalDataWipe runs it.
    await MockPremiumRepository.clearPersistedLocalState(
      storage,
      secureStorage: secure,
    );
    await storage.setString(UserLocalDataIsolation.ownerKey, 'uid-b');

    final devicePending = _FakePlay()
      ..query = [_play(PremiumStoreCatalog.monthlyId, PurchaseStatus.pending)];
    final b = await _launch(storage, secure, play: devicePending);
    expect(b.controller.isPremium, isFalse);
    expect(b.controller.pendingKind, PremiumPendingKind.store);
    b.controller.selectPlan(PremiumPlanKind.yearly);
    await b.controller.purchase();
    expect(devicePending.buyCalls, 0);

    await MockPremiumRepository.clearPersistedLocalState(
      storage,
      secureStorage: secure,
    );
    await storage.setString(UserLocalDataIsolation.ownerKey, 'uid-a');
    final backToA = await _launch(storage, secure, play: devicePending);
    expect(backToA.controller.pendingKind, PremiumPendingKind.store);
    expect(backToA.controller.isPremium, isFalse);
    expect(devicePending.buyCalls, 0);
  });

  test('the service refuses a new payment even when UI state is stale',
      () async {
    // Below any controller: an unfinished store record, then a saved but
    // unresolved receipt, each keep the store untouched.
    final repo = MockPremiumRepository(storage, secureStorage: secure);
    final play = _FakePlay();
    final attempts = PremiumPurchaseAttemptStore(storage, secure);
    final port = createStorePremiumPurchase(
      () => repo,
      client: play,
      attempts: attempts,
      currentOwnerUid: () => 'uid-a',
    );
    final service = PremiumService(
      repo,
      MockUserRepository(storage),
      port,
      _Verifier(),
    )..forceReleaseMode = true;
    await service.preparePurchase();

    await attempts.begin(
      PremiumPurchaseAttempt(
        ownerTag: PremiumPurchaseAttemptStore.ownerTag('uid-a'),
        platform: 'android',
        productId: PremiumStoreCatalog.monthlyId,
        attemptId: 'stale-ui',
        sinceUtc: DateTime.utc(2026, 10, 24),
      ),
    );
    final whileUnfinished = await service.purchase(PremiumPlanKind.yearly);
    expect(whileUnfinished.outcome, PremiumPurchaseOutcome.pending);
    expect(play.buyCalls, 0);

    await attempts.release((_) => true);
    await repo.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: PremiumStoreCatalog.monthlyId,
        purchaseToken: 'held',
        transactionId: 'GPA.held',
      ),
    );
    final whileUnverified = await service.purchase(PremiumPlanKind.yearly);
    expect(whileUnverified.outcome, PremiumPurchaseOutcome.pending);
    expect(play.buyCalls, 0);
  });

  test('a finished receipt awaiting the backend is the verification kind',
      () async {
    final verifier = _Verifier()..answer = PremiumVerifyResult.error('network');
    final app = await _launch(storage, secure, verifier: verifier);
    app.play.onBuy = [
      _play(PremiumStoreCatalog.monthlyId, PurchaseStatus.purchased),
    ];
    app.controller.selectPlan(PremiumPlanKind.monthly);
    await app.controller.purchase();
    expect(app.controller.entitlement, PremiumEntitlementState.pending);
    expect(app.controller.pendingKind, PremiumPendingKind.verification);
    expect(app.attempts.all(), isEmpty);
    expect(app.controller.isPremium, isFalse);
    await app.controller.purchase();
    expect(app.play.buyCalls, 1);
  });
}
