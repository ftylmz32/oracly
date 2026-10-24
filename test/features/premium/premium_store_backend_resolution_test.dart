/// #44 — a Play purchase whose token the app has seen (it reported PENDING)
/// is resolved by asking the backend, which reads Play's own record of that
/// token (Developer API). Only Play's definitive "this pending purchase was
/// cancelled" releases the lock; a pending, unknown, failed, not-found or
/// other-account answer keeps it; an active one is saved for its owner and
/// granted once. Only the signed-in owner's own tokens are ever sent. A
/// lock with no token (no store transaction seen) cannot be resolved this
/// way and stays. Tokens are kept in secure storage, never in prefs.
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

import 'support/ios_storekit_fake.dart' show lifetimeProduct, monthlyProduct;

const _uidA = 'uid-account-a';
const _uidB = 'uid-account-b';
const _pendingToken = 'play-pending-token-a';

PurchaseDetails _play(
  String? accountTag,
  PurchaseStateWrapper state, {
  String productId = PremiumStoreCatalog.monthlyId,
  String token = _pendingToken,
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

class _FakePlay implements StoreIapClient, StorePurchaseQueryClient {
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();
  List<PurchaseDetails> Function(String? accountTag) onBuy = (_) => const [];
  bool throwOnBuy = false;
  List<PurchaseDetails>? query = const [];
  int buyCalls = 0;

  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [monthlyProduct, lifetimeProduct],
        notFoundIDs: const [],
      );
  @override
  Future<void> restorePurchases() async {}
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalls++;
    if (throwOnBuy) throw StateError('process died before the store answered');
    final emits = onBuy(purchaseParam.applicationUserName);
    if (emits.isNotEmpty) scheduleMicrotask(() => _stream.add(emits));
    return true;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
  @override
  Future<List<PurchaseDetails>?> queryPurchases() async => query;
}

/// The backend's answer per token, recording every token it is asked about.
class _Backend implements PremiumEntitlementVerifier {
  PremiumVerifyResult answer = PremiumVerifyResult.pending('subscription_pending');
  final asked = <String>[];

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    asked.add(purchaseToken);
    return answer;
  }
}

class _Device {
  _Device(this.storage, this.secure);
  final LocalStorage storage;
  final InMemorySecureStorage secure;
  final play = _FakePlay();
  final backend = _Backend();
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

  Future<(PremiumStatusController, MockPremiumRepository)> launch() async {
    await _port?.dispose();
    final repo = MockPremiumRepository(storage, secureStorage: secure);
    final port = createStorePremiumPurchase(
      () => repo,
      client: play,
      answerWindow: const Duration(milliseconds: 40),
      attempts: attempts,
      currentOwnerUid: () => storage.getString(UserLocalDataIsolation.ownerKey),
    );
    _port = port;
    final service = PremiumService(
      repo,
      MockUserRepository(storage),
      port,
      backend,
    )..forceReleaseMode = true;
    final controller = PremiumStatusController(service);
    await controller.load();
    return (controller, repo);
  }

  /// A launches a monthly purchase that Play reports PENDING (token seen).
  Future<PremiumStatusController> pendingWithToken({
    String productId = PremiumStoreCatalog.monthlyId,
    PremiumPlanKind plan = PremiumPlanKind.monthly,
  }) async {
    await signIn(_uidA);
    final (c, _) = await launch();
    play.onBuy = (tag) => [
      _play(tag, PurchaseStateWrapper.pending, productId: productId),
    ];
    c.selectPlan(plan);
    await c.purchase();
    expect(c.pendingKind, PremiumPendingKind.store);
    return c;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Device device;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    device = _Device(await LocalStorage.open(), InMemorySecureStorage());
  });

  test('the pending token lives in secure storage, never in prefs', () async {
    await device.pendingWithToken();
    for (final key in device.storage.keys) {
      expect('${device.storage.getString(key)}', isNot(contains(_pendingToken)),
          reason: 'prefs key $key must not hold a purchase token');
    }
  });

  for (final (label, reason, productId, plan) in [
    (
      'subscription pending purchase cancelled',
      'subscription_state_pending_purchase_canceled',
      PremiumStoreCatalog.monthlyId,
      PremiumPlanKind.monthly,
    ),
    (
      'one-time product cancelled',
      'product_canceled',
      PremiumStoreCatalog.lifetimeId,
      PremiumPlanKind.lifetime,
    ),
  ]) {
    test('Play says $label: the lock is released, nothing granted', () async {
      final c = await device.pendingWithToken(productId: productId, plan: plan);
      device.backend.answer = PremiumVerifyResult.inactive(reason);
      await c.checkPendingStatus();
      expect(device.backend.asked, contains(_pendingToken));
      expect(device.attempts.all(), isEmpty);
      expect(c.entitlement, PremiumEntitlementState.inactive);
      expect(c.isPremium, isFalse);
    });
  }

  for (final (label, answer) in [
    ('still pending', PremiumVerifyResult.pending('subscription_pending')),
    ('not found (may be propagation)', PremiumVerifyResult.inactive('not_found')),
    ('backend unreachable', PremiumVerifyResult.error('network_or_parse')),
    ('bound to another account',
        PremiumVerifyResult.unverified('purchase_bound_to_other_account')),
    ('on hold', PremiumVerifyResult.inactive('subscription_state_on_hold')),
  ]) {
    test('Play/backend says $label: the lock stays, nothing granted', () async {
      final c = await device.pendingWithToken();
      device.backend.answer = answer;
      await c.checkPendingStatus();
      await c.checkPendingStatus();
      expect(device.attempts.all(), isNotEmpty);
      expect(c.pendingKind, PremiumPendingKind.store);
      expect(c.isPremium, isFalse);
      await c.purchase();
      expect(device.play.buyCalls, 1);
    });
  }

  test('Play says the purchase completed: saved for its owner, granted once',
      () async {
    final c = await device.pendingWithToken();
    device.backend.answer = PremiumVerifyResult.active('subscription_active');
    await c.checkPendingStatus();
    expect(c.entitlement, PremiumEntitlementState.active);
    expect(device.attempts.all(), isEmpty);
    expect(device.play.buyCalls, 1);
  });

  test('the resolution also runs on the next app start', () async {
    await device.pendingWithToken();
    device.backend.answer = PremiumVerifyResult.inactive(
      'subscription_state_pending_purchase_canceled',
    );
    final (relaunched, _) = await device.launch();
    expect(device.attempts.all(), isEmpty);
    expect(relaunched.entitlement, PremiumEntitlementState.inactive);
  });

  test('another account\'s pending token is never sent to the backend',
      () async {
    await device.pendingWithToken();
    device.backend.asked.clear();
    await device.signIn(_uidB);
    final (b, _) = await device.launch();
    await b.checkPendingStatus();
    expect(device.backend.asked, isNot(contains(_pendingToken)));
    expect(b.pendingKind, PremiumPendingKind.store);
    expect(b.isPremium, isFalse);
  });

  test('no token was ever seen (store never answered): nothing to ask Play, '
      'the lock stays', () async {
    await device.signIn(_uidA);
    final (c, _) = await device.launch();
    c.selectPlan(PremiumPlanKind.monthly);
    await c.purchase();
    device.backend.asked.clear();
    await c.checkPendingStatus();
    expect(device.backend.asked, isEmpty);
    expect(c.pendingKind, PremiumPendingKind.store);
  });

  test('the process died before the store accepted the purchase: the lock '
      'stays and nothing is sent', () async {
    await device.signIn(_uidA);
    final (c, _) = await device.launch();
    device.play.throwOnBuy = true;
    c.selectPlan(PremiumPlanKind.monthly);
    await c.purchase();
    final (relaunched, _) = await device.launch();
    expect(device.attempts.all(), isNotEmpty);
    expect(relaunched.isPremium, isFalse);
    expect(device.backend.asked, isEmpty);
    await relaunched.purchase();
    expect(device.play.buyCalls, 1);
  });
}
