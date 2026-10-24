/// #44 — an unfinished purchase belongs to the account that started it.
/// The attempt is written durably BEFORE the store sheet opens (no record,
/// no sheet). A purchase account A started and Play finishes while B is
/// signed in is parked for A only: B gets no token, save, verify or grant,
/// yet the device stays locked against a second charge. A recovers and
/// verifies it on return. Only a store answer matched to the transaction
/// releases the lock; an empty or failed store read never does.
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
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
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

/// A real Play delivery, including the obfuscated account it was bought for.
PurchaseDetails _playFor(
  String? accountTag,
  PurchaseStateWrapper state, {
  String productId = PremiumStoreCatalog.monthlyId,
  String token = 'play-token-a',
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

class _FakePlay implements StoreIapClient, StorePurchaseQueryClient {
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();
  List<PurchaseDetails> Function(String? accountTag) onBuy = (_) => const [];
  List<PurchaseDetails>? query = const [];
  int buyCalls = 0;
  final accountTags = <String?>[];
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
  Future<void> restorePurchases() async {}
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalls++;
    accountTags.add(purchaseParam.applicationUserName);
    final emits = onBuy(purchaseParam.applicationUserName);
    _remember(emits);
    if (emits.isNotEmpty) scheduleMicrotask(() => _stream.add(emits));
    return true;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.verificationData.serverVerificationData);
  @override
  Future<List<PurchaseDetails>?> queryPurchases() async {
    _remember(query ?? const []);
    return query;
  }
}

class _Verifier implements PremiumEntitlementVerifier {
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
    return _playVerdict(purchaseToken) ??
        PremiumVerifyResult.active('subscription_active');
  }
}

class _Device {
  _Device(this.storage, this.secure, this.play);
  final LocalStorage storage;
  final InMemorySecureStorage secure;
  final _FakePlay play;
  StorePremiumPurchase? _port;
  late PremiumPurchaseAttemptStore attempts = PremiumPurchaseAttemptStore(
    storage,
    secure,
  );

  /// Signs [uid] in the way the app does: wipe the previous owner's local
  /// Premium state, then commit the new owner marker.
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

  Future<(PremiumStatusController, MockPremiumRepository, _Verifier)> launch({
    _Verifier? verifier,
  }) async {
    final repo = MockPremiumRepository(storage, secureStorage: secure);
    final verify = verifier ?? _Verifier();
    // A relaunch is a new process: the previous one stops listening.
    await _port?.dispose();
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
      verify,
    )..forceReleaseMode = true;
    final controller = PremiumStatusController(service);
    await controller.load();
    return (controller, repo, verify);
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
    device = _Device(
      await LocalStorage.open(),
      InMemorySecureStorage(),
      _FakePlay(),
    );
  });

  test('the attempt cannot be written: the store sheet never opens', () async {
    // The owner is already signed in; only the new attempt write fails.
    SharedPreferences.setMockInitialValues({
      UserLocalDataIsolation.ownerKey: _uidA,
    });
    final storage = _UnwritableStorageSeeded(await SharedPreferences.getInstance());
    final dev = _Device(storage, InMemorySecureStorage(), _FakePlay());
    final (c, _, _) = await dev.launch();
    c.selectPlan(PremiumPlanKind.monthly);
    final result = await c.purchase();
    expect(dev.play.buyCalls, 0, reason: 'no durable lock, no store sheet');
    expect(result.granted, isFalse);
    expect(result.outcome, PremiumPurchaseOutcome.failed);
    expect(c.isPremium, isFalse);
  });

  test('the store sheet carries an obfuscated account tag, never the raw uid',
      () async {
    await device.signIn(_uidA);
    final (c, _, _) = await device.launch();
    device.play.onBuy = (tag) => [_playFor(tag, PurchaseStateWrapper.pending)];
    c.selectPlan(PremiumPlanKind.monthly);
    await c.purchase();
    expect(device.play.accountTags.single,
        PremiumPurchaseAttemptStore.ownerTag(_uidA));
    expect(device.play.accountTags.single, isNot(contains(_uidA)));
  });

  test('A pays, B is signed in when Play finishes it: B gets 0 token, save, '
      'verify or grant and cannot pay; A verifies it on return', () async {
    await device.signIn(_uidA);
    final (a, _, _) = await device.launch();
    device.play.onBuy = (tag) => [_playFor(tag, PurchaseStateWrapper.pending)];
    a.selectPlan(PremiumPlanKind.monthly);
    await a.purchase();
    expect(a.pendingKind, PremiumPendingKind.store);

    await device.signIn(_uidB);
    final verifierB = _Verifier();
    final (b, repoB, _) = await device.launch(verifier: verifierB);
    device.play.emit([
      _playFor(
        PremiumPurchaseAttemptStore.ownerTag(_uidA),
        PurchaseStateWrapper.purchased,
      ),
    ]);
    await _settle();
    await b.forceReconcile();

    expect(await repoB.readPurchaseCredentials(), isNull);
    expect(verifierB.tokens, isEmpty);
    expect(b.isPremium, isFalse);
    expect(b.pendingKind, PremiumPendingKind.store,
        reason: 'the device still holds a paid-for, unrecovered purchase');
    b.selectPlan(PremiumPlanKind.yearly);
    await b.purchase();
    expect(device.play.buyCalls, 1);
    expect(device.play.completed, ['play-token-a'],
        reason: 'acknowledged once its proof is parked for A, so Play keeps it');

    await device.signIn(_uidA);
    final verifierA = _Verifier();
    final (backToA, repoA, _) = await device.launch(verifier: verifierA);
    expect(backToA.entitlement, PremiumEntitlementState.active);
    expect((await repoA.readPurchaseCredentials())?.purchaseToken,
        'play-token-a');
    expect(verifierA.tokens, everyElement('play-token-a'));
    expect(verifierA.tokens, isNotEmpty);
    expect(device.play.buyCalls, 1);
  });

  test('a delivery with no account tag goes to the account whose attempt it '
      'matches, never to whoever is signed in', () async {
    await device.signIn(_uidA);
    final (a, _, _) = await device.launch();
    device.play.onBuy = (_) => [_playFor(null, PurchaseStateWrapper.pending)];
    a.selectPlan(PremiumPlanKind.monthly);
    await a.purchase();

    await device.signIn(_uidB);
    final verifierB = _Verifier();
    final (b, repoB, _) = await device.launch(verifier: verifierB);
    device.play.emit([_playFor(null, PurchaseStateWrapper.purchased)]);
    await _settle();
    await b.forceReconcile();
    expect(await repoB.readPurchaseCredentials(), isNull);
    expect(verifierB.tokens, isEmpty);
    expect(b.isPremium, isFalse);
  });

  test('a delivery no attempt or tag can place is left unfinished, not given '
      'to the signed-in account', () async {
    await device.signIn(_uidB);
    final verifierB = _Verifier();
    final (b, repoB, _) = await device.launch(verifier: verifierB);
    device.play.emit([_playFor(null, PurchaseStateWrapper.purchased)]);
    await _settle();
    await b.forceReconcile();
    expect(await repoB.readPurchaseCredentials(), isNull);
    expect(verifierB.tokens, isEmpty);
    expect(device.play.completed, isEmpty, reason: 'fail closed, no ack');
  });

  group('the lock is released only by a store answer for this transaction',
      () {
    Future<PremiumStatusController> pendingA() async {
      await device.signIn(_uidA);
      final (a, _, _) = await device.launch();
      device.play.onBuy = (tag) => [
        _playFor(tag, PurchaseStateWrapper.pending, token: 'pending-a'),
      ];
      a.selectPlan(PremiumPlanKind.monthly);
      await a.purchase();
      return a;
    }

    for (final (label, query) in <(String, List<PurchaseDetails>?)>[
      ('empty once', const []),
      ('store unreadable', null),
      ('another Google account pending',
          [_playFor('someone-else', PurchaseStateWrapper.pending, token: 'x')]),
    ]) {
      test('user check, $label: lock kept, 1 purchase, 0 grant', () async {
        final a = await pendingA();
        device.play.query = query;
        await a.checkPendingStatus();
        await a.checkPendingStatus();
        expect(a.pendingKind, PremiumPendingKind.store);
        await a.purchase();
        expect(device.play.buyCalls, 1);
        expect(a.isPremium, isFalse);
      });
    }

    test('a cancel for another transaction does not release it', () async {
      final a = await pendingA();
      device.play.emit([
        _playFor(
          PremiumPurchaseAttemptStore.ownerTag(_uidA),
          PurchaseStateWrapper.unspecified_state,
          token: 'some-other-token',
        )..status = PurchaseStatus.canceled,
      ]);
      await _settle();
      await a.forceReconcile();
      expect(a.pendingKind, PremiumPendingKind.store);
    });

    test('a cancel for this transaction releases it, granting nothing',
        () async {
      final a = await pendingA();
      device.play.emit([
        _playFor(
          PremiumPurchaseAttemptStore.ownerTag(_uidA),
          PurchaseStateWrapper.unspecified_state,
          token: 'pending-a',
        )..status = PurchaseStatus.canceled,
      ]);
      await _settle();
      await a.forceReconcile();
      expect(a.entitlement, PremiumEntitlementState.inactive);
      expect(a.isPremium, isFalse);
    });

    test('the user cancels the sheet itself: no lock remains', () async {
      await device.signIn(_uidA);
      final (a, _, _) = await device.launch();
      device.play.onBuy = (tag) => [
        _playFor(tag, PurchaseStateWrapper.unspecified_state, token: '')
          ..status = PurchaseStatus.canceled,
      ];
      a.selectPlan(PremiumPlanKind.monthly);
      final result = await a.purchase();
      expect(result.outcome, PremiumPurchaseOutcome.cancelled);
      expect(device.attempts.all(), isEmpty);
      expect(a.entitlement, isNot(PremiumEntitlementState.pending));
    });
  });

  test('deleting account A forgets only A\'s attempts and parked proof',
      () async {
    await device.signIn(_uidA);
    final (a, _, _) = await device.launch();
    device.play.onBuy = (tag) => [_playFor(tag, PurchaseStateWrapper.pending)];
    a.selectPlan(PremiumPlanKind.monthly);
    await a.purchase();
    expect(device.attempts.all(), hasLength(1));
    await device.attempts.forgetOwner(_uidA);
    expect(device.attempts.all(), isEmpty);
  });
}

/// Real prefs for reads (owner already set); every new write is refused.
class _UnwritableStorageSeeded extends LocalStorage {
  _UnwritableStorageSeeded(super.prefs);
  @override
  Future<bool> setString(String key, String value) async => false;
}
