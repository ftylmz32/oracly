/// #44 — a purchase attempt the store never gave a token for (the app died
/// while launching, or the store never answered) can never be proven
/// unpaid: an empty purchase list and elapsed time are not evidence. It is
/// never released on its own. Instead:
///  * a later store query that shows a transaction for the same account
///    and product attaches its token, so the backend can settle it;
///  * after a successful store query that shows nothing for that product,
///    and only after the attempt is old enough, the user may retry the SAME
///    plan only (other plans stay blocked), so the store's own duplicate
///    protection stands between a lost first attempt and a second charge;
///  * a retry the store accepts supersedes the lost attempt; a store error
///    withdraws the retry until a new clean store check.
/// Every release is written to an audit trail without tokens.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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
import 'package:oracly_new/features/premium/models/premium_store_pending.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/providers/premium_purchase_port_provider.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_iap_client.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/ios_storekit_fake.dart' show monthlyProduct, yearlyProduct;

const _uidA = 'uid-account-a';
const _uidB = 'uid-account-b';

PurchaseDetails _play(
  String? accountTag,
  PurchaseStateWrapper state, {
  String productId = PremiumStoreCatalog.monthlyId,
  String token = 'tok-1',
}) => GooglePlayPurchaseDetails.fromPurchase(
  PurchaseWrapper(
    orderId: state == PurchaseStateWrapper.purchased ? 'GPA.1' : '',
    packageName: 'app.oracly',
    purchaseTime: 1,
    purchaseToken: token,
    signature: 'sig',
    products: [productId],
    isAutoRenewing: true,
    originalJson: '{}',
    isAcknowledged: false,
    purchaseState: state,
    obfuscatedAccountId: accountTag,
  ),
).single;

final _playStatus = <String, PurchaseStatus>{};

class _FakePlay implements StoreIapClient, StorePurchaseQueryClient {
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();
  List<PurchaseDetails> Function(String? accountTag) onBuy = (_) => const [];
  bool launchResult = true;
  bool throwOnBuy = false;
  List<PurchaseDetails>? query = const [];
  final bought = <String>[];

  void emit(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      _playStatus[p.verificationData.serverVerificationData] = p.status;
    }
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
  Future<void> restorePurchases() async {}
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought.add(purchaseParam.productDetails.id);
    if (throwOnBuy) throw StateError('process died while launching');
    if (!launchResult) return false;
    final emits = onBuy(purchaseParam.applicationUserName);
    if (emits.isNotEmpty) scheduleMicrotask(() => emit(emits));
    return true;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
  @override
  Future<List<PurchaseDetails>?> queryPurchases() async {
    for (final p in query ?? const <PurchaseDetails>[]) {
      _playStatus[p.verificationData.serverVerificationData] = p.status;
    }
    return query;
  }
}

class _Backend implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;
  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final status = _playStatus[purchaseToken];
    if (status == PurchaseStatus.pending) {
      return PremiumVerifyResult.pending('subscription_pending');
    }
    if (status == PurchaseStatus.purchased) {
      return PremiumVerifyResult.active('subscription_active');
    }
    return PremiumVerifyResult.inactive('not_found');
  }
}

class _Device {
  _Device(this.storage, this.secure);
  final LocalStorage storage;
  final InMemorySecureStorage secure;
  final play = _FakePlay();
  DateTime now = DateTime.utc(2026, 10, 24, 12);
  StorePremiumPurchase? _port;
  late final attempts = PremiumPurchaseAttemptStore(storage, secure);

  Future<void> signIn(String uid) async {
    final previous = storage.getString(UserLocalDataIsolation.ownerKey);
    if (previous != null && previous != uid) {
      await MockPremiumRepository.clearPersistedLocalState(
        storage,
        secureStorage: secure,
      );
    }
    await storage.setString(UserLocalDataIsolation.ownerKey, uid);
  }

  /// [productionDefault] wires the port exactly as the app does, without
  /// naming the retry setting, so the shipped default is what is tested.
  Future<PremiumStatusController> launch({bool productionDefault = false}) async {
    await _port?.dispose();
    final repo = MockPremiumRepository(storage, secureStorage: secure);
    String? owner() => storage.getString(UserLocalDataIsolation.ownerKey);
    final port = productionDefault
        ? createStorePremiumPurchase(
            () => repo,
            client: play,
            answerWindow: const Duration(milliseconds: 30),
            attempts: attempts,
            currentOwnerUid: owner,
            clock: () => now,
          )
        : createStorePremiumPurchase(
            () => repo,
            client: play,
            answerWindow: const Duration(milliseconds: 30),
            attempts: attempts,
            currentOwnerUid: owner,
            clock: () => now,
            tokenlessRetryEnabled: true,
          );
    _port = port;
    final controller = PremiumStatusController(
      PremiumService(repo, MockUserRepository(storage), port, _Backend())
        ..forceReleaseMode = true,
    );
    await controller.load();
    return controller;
  }

  /// A launches monthly and the store never answers (or the app dies).
  Future<PremiumStatusController> lostAttempt({bool dies = false}) async {
    await signIn(_uidA);
    final c = await launch();
    play.throwOnBuy = dies;
    c.selectPlan(PremiumPlanKind.monthly);
    await c.purchase();
    play.throwOnBuy = false;
    expect(attempts.all().single.storeRef, isNull, reason: 'no token seen');
    return c;
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Device device;

  setUp(() async {
    _playStatus.clear();
    SharedPreferences.setMockInitialValues({});
    device = _Device(await LocalStorage.open(), InMemorySecureStorage());
  });

  group('definitive failures leave no lock', () {
    test('the store refuses to open the sheet', () async {
      await device.signIn(_uidA);
      final c = await device.launch();
      device.play.launchResult = false;
      c.selectPlan(PremiumPlanKind.monthly);
      await c.purchase();
      expect(device.attempts.all(), isEmpty);
    });

    test('the user cancels the sheet', () async {
      await device.signIn(_uidA);
      final c = await device.launch();
      device.play.onBuy = (tag) => [
        _play(tag, PurchaseStateWrapper.unspecified_state, token: '')
          ..status = PurchaseStatus.canceled,
      ];
      c.selectPlan(PremiumPlanKind.monthly);
      await c.purchase();
      expect(device.attempts.all(), isEmpty);
    });
  });

  test('right after a lost attempt nothing can be bought, not even the same '
      'plan', () async {
    final c = await device.lostAttempt(dies: true);
    final relaunched = await device.launch();
    expect(relaunched.pendingKind, PremiumPendingKind.store);
    expect(relaunched.retryablePlan, isNull);
    await relaunched.retrySamePlan();
    await c.purchase();
    expect(device.play.bought, hasLength(1));
  });

  test('old enough + a clean store check: only the same plan may be retried',
      () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(minutes: 11));
    final c = await device.launch();
    expect(c.retryablePlan, PremiumPlanKind.monthly);

    c.selectPlan(PremiumPlanKind.yearly);
    await c.purchase();
    expect(device.play.bought, hasLength(1), reason: 'another plan stays blocked');

    device.play.onBuy = (tag) => [
      _play(tag, PurchaseStateWrapper.purchased, token: 'tok-retry'),
    ];
    await c.retrySamePlan();
    await _settle();
    expect(device.play.bought, [
      PremiumStoreCatalog.monthlyId,
      PremiumStoreCatalog.monthlyId,
    ]);
    await c.checkPendingStatus();
    expect(c.entitlement, PremiumEntitlementState.active);
    expect(device.attempts.all(), isEmpty, reason: 'retry superseded the lost one');
  });

  test('production default: no retry is offered and nothing can be bought, '
      'even when every retry condition holds', () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(minutes: 11));
    final c = await device.launch(productionDefault: true);
    expect(c.pendingKind, PremiumPendingKind.store);
    expect(c.retryablePlan, isNull);
    await c.retrySamePlan();
    await c.purchase();
    expect(device.play.bought, hasLength(1));
    expect(device.attempts.all(), hasLength(1), reason: 'the lock stays');
  });

  test('below any UI, the service refuses every plan but the retryable one',
      () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(minutes: 11));
    final repo = MockPremiumRepository(device.storage, secureStorage: device.secure);
    final port = createStorePremiumPurchase(
      () => repo,
      client: device.play,
      answerWindow: const Duration(milliseconds: 30),
      attempts: device.attempts,
      currentOwnerUid: () =>
          device.storage.getString(UserLocalDataIsolation.ownerKey),
      clock: () => device.now,
      tokenlessRetryEnabled: true,
    );
    final service = PremiumService(
      repo,
      MockUserRepository(device.storage),
      port,
      _Backend(),
    )..forceReleaseMode = true;
    await service.preparePurchase();
    await service.reconcile(scanStore: true);
    expect(await service.retryablePlan(), PremiumPlanKind.monthly);
    final other = await service.purchase(PremiumPlanKind.yearly);
    expect(other.granted, isFalse);
    expect(device.play.bought, hasLength(1), reason: 'yearly never launched');
    await port.dispose();
  });

  test('time alone is not enough: an unreadable store gives no retry', () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(hours: 2));
    device.play.query = null;
    final c = await device.launch();
    expect(c.retryablePlan, isNull);
    expect(c.pendingKind, PremiumPendingKind.store);
  });

  test('a later query showing this account\'s pending purchase attaches its '
      'token; the backend can then settle it', () async {
    await device.lostAttempt();
    device.play.query = [
      _play(
        PremiumPurchaseAttemptStore.ownerTag(_uidA),
        PurchaseStateWrapper.pending,
      ),
    ];
    device.now = device.now.add(const Duration(minutes: 30));
    final c = await device.launch();
    expect(device.attempts.all(), hasLength(1));
    expect(device.attempts.all().single.storeRef, isNotNull);
    expect(c.retryablePlan, isNull, reason: 'a real transaction exists');
  });

  test('a later query showing the purchase completed grants it once', () async {
    await device.lostAttempt();
    device.play.query = [
      _play(
        PremiumPurchaseAttemptStore.ownerTag(_uidA),
        PurchaseStateWrapper.purchased,
      ),
    ];
    final c = await device.launch();
    expect(c.entitlement, PremiumEntitlementState.active);
    expect(device.attempts.all(), isEmpty);
    expect(device.play.bought, hasLength(1));
  });

  test('a retry the store rejects withdraws the retry until a new clean check',
      () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(minutes: 11));
    final c = await device.launch();
    device.play.onBuy = (tag) => [
      _play(tag, PurchaseStateWrapper.unspecified_state, token: '')
        ..status = PurchaseStatus.error,
    ];
    await c.retrySamePlan();
    await _settle();
    expect(c.retryablePlan, isNull);
    expect(device.attempts.all(), hasLength(1));
  });

  test('a retry the store holds as pending supersedes the lost attempt and '
      'cannot be retried again', () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(minutes: 11));
    final c = await device.launch();
    device.play.onBuy = (tag) => [
      _play(tag, PurchaseStateWrapper.pending, token: 'tok-retry'),
    ];
    await c.retrySamePlan();
    await _settle();
    expect(device.attempts.all(), hasLength(1));
    expect(device.attempts.all().single.storeRef, isNotNull);
    expect(c.retryablePlan, isNull);
  });

  test('another account never gets the retry and stays blocked', () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(minutes: 11));
    await device.signIn(_uidB);
    final b = await device.launch();
    expect(b.retryablePlan, isNull);
    b.selectPlan(PremiumPlanKind.monthly);
    await b.purchase();
    expect(device.play.bought, hasLength(1));
  });

  test('every release is audited, without a raw token', () async {
    await device.lostAttempt();
    device.now = device.now.add(const Duration(minutes: 11));
    final c = await device.launch();
    device.play.onBuy = (tag) => [
      _play(tag, PurchaseStateWrapper.purchased, token: 'tok-retry'),
    ];
    await c.retrySamePlan();
    await _settle();
    final audit = device.attempts.auditTrail();
    expect(audit, isNotEmpty);
    expect(audit.map((e) => e['why']), contains('superseded_by_retry'));
    expect(audit.toString(), isNot(contains('tok-retry')));
  });
}
