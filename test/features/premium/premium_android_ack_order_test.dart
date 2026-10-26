/// #44 — Android Premium: the app never acknowledges a Play purchase before
/// the backend has verified it and bound it to the signed-in account.
///
/// `completePurchase` acknowledges on Android, so it may only follow a
/// verify answer of `active`. The backend says whether Play already holds
/// the purchase acknowledged (it acknowledges itself after binding): then
/// the app finishes nothing. When the backend's own acknowledge failed
/// (`pending`), or an older backend says nothing, the app acknowledges the
/// now verified purchase itself, once. Without an `active` verdict nothing
/// is acknowledged, nothing is granted, the receipt stays saved and no
/// second payment can start. A purchase left unacknowledged when the app
/// died is picked up from Play on the next launch, even for an account
/// that is already Premium.
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
const _token = 'play-token-a';

PurchaseDetails _play(
  String? accountTag,
  PurchaseStateWrapper state, {
  String productId = PremiumStoreCatalog.monthlyId,
  String token = _token,
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

/// Every verify and every store completion, in the order they happened.
final _events = <String>[];

class _FakePlay implements StoreIapClient, StorePurchaseQueryClient {
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();
  List<PurchaseDetails> Function(String? accountTag) onBuy = (_) => const [];
  List<PurchaseDetails>? query = const [];
  bool completeThrows = false;
  int buyCalls = 0;

  int get completions =>
      _events.where((e) => e.startsWith('complete:')).length;

  void deliver(List<PurchaseDetails> purchases) => _stream.add(purchases);

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
    final emits = onBuy(purchaseParam.applicationUserName);
    if (emits.isNotEmpty) scheduleMicrotask(() => _stream.add(emits));
    return true;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (completeThrows) throw StateError('BillingClient disconnected');
    _events.add('complete:${purchase.verificationData.serverVerificationData}');
  }

  @override
  Future<List<PurchaseDetails>?> queryPurchases() async => query;
}

class _Backend implements PremiumEntitlementVerifier {
  PremiumVerifyResult answer = PremiumVerifyResult.verified('subscription_active', PremiumStoreAcknowledgement.acknowledged);
  int get verifies => _events.where((e) => e.startsWith('verify:')).length;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    _events.add('verify:$purchaseToken');
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

  Future<PremiumStatusController> launch() async {
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
    return controller;
  }

  /// A signs in and buys monthly; Play answers PURCHASED (unacknowledged).
  Future<PremiumStatusController> buy({String uid = _uidA}) async {
    await signIn(uid);
    final c = await launch();
    play.onBuy = (tag) => [_play(tag, PurchaseStateWrapper.purchased)];
    c.selectPlan(PremiumPlanKind.monthly);
    await c.purchase();
    return c;
  }
}

void _expectNoCompletionBeforeVerify() {
  final firstVerify = _events.indexWhere((e) => e.startsWith('verify:'));
  final firstComplete = _events.indexWhere((e) => e.startsWith('complete:'));
  if (firstComplete >= 0) {
    expect(firstVerify, isNonNegative, reason: 'completed with no verify');
    expect(firstComplete, greaterThan(firstVerify),
        reason: 'store completion (Android acknowledge) before verify: $_events');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Device device;

  setUp(() async {
    _events.clear();
    SharedPreferences.setMockInitialValues({});
    device = _Device(await LocalStorage.open(), InMemorySecureStorage());
  });

  test('the backend acknowledged it: the app never acknowledges', () async {
    final c = await device.buy();
    expect(c.isPremium, isTrue);
    expect(device.backend.verifies, greaterThanOrEqualTo(1));
    expect(device.play.completions, 0, reason: '$_events');
  });

  for (final (label, answer) in [
    (
      'the backend\'s own acknowledge failed (queue/outbox holds it)',
      PremiumVerifyResult.verified('subscription_active', PremiumStoreAcknowledgement.pending),
    ),
    (
      'an older backend says nothing about acknowledgement',
      PremiumVerifyResult.active('subscription_active'),
    ),
  ]) {
    test('$label: the app acknowledges once, only after verify', () async {
      device.backend.answer = answer;
      final c = await device.buy();
      expect(c.isPremium, isTrue);
      expect(device.play.completions, 1, reason: '$_events');
      _expectNoCompletionBeforeVerify();
      expect(_events.first, 'verify:$_token');
    });
  }

  for (final (label, answer) in [
    ('backend unreachable', PremiumVerifyResult.error('network_or_parse')),
    ('Play still settling', PremiumVerifyResult.pending('subscription_pending')),
    ('verification unavailable', PremiumVerifyResult.unverified('auth_required')),
    ('cancelled at Play', PremiumVerifyResult.inactive('subscription_canceled')),
    (
      'bound to another account',
      PremiumVerifyResult.unverified('purchase_bound_to_other_account'),
    ),
  ]) {
    test('$label: nothing acknowledged, nothing granted', () async {
      device.backend.answer = answer;
      final c = await device.buy();
      expect(device.backend.verifies, greaterThanOrEqualTo(1));
      expect(device.play.completions, 0, reason: '$_events');
      expect(c.isPremium, isFalse);
    });
  }

  test('verify failed: the receipt stays, no second payment, and a later '
      'active verdict acknowledges it once', () async {
    device.backend.answer = PremiumVerifyResult.error('network_or_parse');
    final c = await device.buy();
    expect(c.isPremium, isFalse);
    await c.purchase();
    expect(device.play.buyCalls, 1, reason: 'a second payment started');
    device.backend.answer = PremiumVerifyResult.verified('subscription_active', PremiumStoreAcknowledgement.pending);
    await c.checkPendingStatus();
    expect(c.isPremium, isTrue);
    expect(device.play.completions, 1, reason: '$_events');
    _expectNoCompletionBeforeVerify();
  });

  test('a store PENDING purchase is never acknowledged', () async {
    device.backend.answer = PremiumVerifyResult.pending('subscription_pending');
    await device.signIn(_uidA);
    final c = await device.launch();
    device.play.onBuy = (tag) => [_play(tag, PurchaseStateWrapper.pending)];
    c.selectPlan(PremiumPlanKind.monthly);
    await c.purchase();
    expect(device.play.completions, 0);
    expect(c.isPremium, isFalse);
  });

  test('the app died before verify: the next launch verifies, then '
      'acknowledges once', () async {
    device.backend.answer = PremiumVerifyResult.error('network_or_parse');
    await device.buy();
    expect(device.play.completions, 0);
    device.play.query = [
      _play(PremiumPurchaseAttemptStore.ownerTag(_uidA),
          PurchaseStateWrapper.purchased),
    ];
    device.backend.answer = PremiumVerifyResult.verified('subscription_active', PremiumStoreAcknowledgement.pending);
    final relaunched = await device.launch();
    expect(relaunched.isPremium, isTrue);
    expect(device.play.completions, 1, reason: '$_events');
    _expectNoCompletionBeforeVerify();
  });

  test('already Premium with a purchase Play still holds unacknowledged: '
      'the next launch verifies it and acknowledges it', () async {
    device.backend.answer = PremiumVerifyResult.verified('subscription_active', PremiumStoreAcknowledgement.pending);
    device.play.completeThrows = true;
    final c = await device.buy();
    expect(c.isPremium, isTrue, reason: 'a failed client ack revokes nothing');
    expect(device.play.completions, 0);
    device.play.completeThrows = false;
    device.play.query = [
      _play(PremiumPurchaseAttemptStore.ownerTag(_uidA),
          PurchaseStateWrapper.purchased),
    ];
    _events.clear();
    final relaunched = await device.launch();
    expect(relaunched.isPremium, isTrue);
    expect(device.play.completions, 1, reason: '$_events');
    _expectNoCompletionBeforeVerify();
  });

  test('the same purchase delivered twice is acknowledged at most once',
      () async {
    device.backend.answer = PremiumVerifyResult.verified('subscription_active', PremiumStoreAcknowledgement.pending);
    final c = await device.buy();
    device.play.deliver([
      _play(PremiumPurchaseAttemptStore.ownerTag(_uidA),
          PurchaseStateWrapper.purchased),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await c.load();
    expect(device.play.completions, 1, reason: '$_events');
  });

  test('another account\'s purchase finishing here is not acknowledged until '
      'its owner is verified', () async {
    await device.signIn(_uidB);
    await device.launch();
    device.play.deliver([
      _play(PremiumPurchaseAttemptStore.ownerTag(_uidA),
          PurchaseStateWrapper.purchased),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(device.play.completions, 0, reason: 'parked proof acknowledged');
    expect(device.backend.verifies, 0);
  });
}
