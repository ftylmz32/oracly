/// Reading-commerce payment safety (#44, approved 26 Oct 2026).
///
/// 1. The reading listener handles only the reading products (coffee, palm,
///    coffee pack). Premium and unknown products never reach it.
/// 2. Unfinished reading purchases are kept in secure storage, per owner
///    (the same opaque owner tag Premium sends to the store), never as
///    plain text in SharedPreferences.
/// 3. A purchase launched by account A is never verified, credited or
///    finished while account B is signed in; A gets it back.
/// 4. A real unfinished purchase is not lost: it stays unfinished at the
///    store (nothing is finished before a verified grant) and is routed to
///    its owner again from the store's own record.
/// 5. No completePurchase (acknowledge / consume) without a backend grant.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/premium_purchase_attempt_store.dart';
import 'package:oracly_new/features/reading_commerce/models/reading_commerce_view.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_commerce_buyer.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_disk.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_monitor.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _tagA = PremiumPurchaseAttemptStore.ownerTag('uid-account-a');
final _tagB = PremiumPurchaseAttemptStore.ownerTag('uid-account-b');
const _legacyKey = 'reading_commerce_unfinished_v1';

PurchaseDetails _play(
  String productId,
  String token, {
  String? accountTag,
  PurchaseStateWrapper state = PurchaseStateWrapper.purchased,
}) => GooglePlayPurchaseDetails.fromPurchase(
  PurchaseWrapper(
    orderId: 'GPA.$token',
    packageName: 'app.oracly',
    purchaseTime: 1,
    purchaseToken: token,
    signature: 'sig',
    products: [productId],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: false,
    purchaseState: state,
    obfuscatedAccountId: accountTag,
  ),
).single;

/// A store event without an account tag (iOS StoreKit as read by this app,
/// or an Android purchase launched before this fix).
PurchaseDetails _untagged(String productId, String token) => PurchaseDetails(
  purchaseID: 'tx-$token',
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: token,
    source: 'app_store',
  ),
  transactionDate: '1',
  status: PurchaseStatus.purchased,
);

ReadingPurchaseUpdate _update(
  String productId,
  String token, {
  String? ownerTag,
  ReadingPurchaseStatus status = ReadingPurchaseStatus.purchased,
}) => ReadingPurchaseUpdate(
  productId: productId,
  token: token,
  purchaseId: 'GPA.$token',
  status: status,
  ownerTag: ownerTag,
);

/// The device: secure storage, prefs, who is signed in, and the server.
class _Device {
  final secure = InMemorySecureStorage();
  String? signedIn = 'uid-account-a';
  ReadingVerifyOutcome Function(ReadingPurchaseUpdate) verdict =
      (_) => ReadingVerifyOutcome.granted;
  final verified = <String>[]; // "<owner tag>:<token>"
  final completed = <String>[]; // tokens finished at the store

  String? get tag =>
      signedIn == null ? null : PremiumPurchaseAttemptStore.ownerTag(signedIn!);

  SecureReadingPurchases memory() =>
      SecureReadingPurchases(secure: secure, currentOwnerTag: () => tag);

  /// A fresh app start: new tracker over the same storage.
  ReadingPurchaseTracker tracker() => ReadingPurchaseTracker(
    memory: memory(),
    currentOwnerTag: () => tag,
    verify: (u) async {
      verified.add('${tag == _tagA ? 'A' : tag == _tagB ? 'B' : '?'}:${u.token}');
      return verdict(u);
    },
    complete: (u) async => completed.add(u.token),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Device d;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    d = _Device();
  });

  group('1. only reading products reach the reading listener', () {
    for (final premium in [
      'app.oracly.premium.monthly',
      'app.oracly.premium.yearly',
      'app.oracly.premium.lifetime',
      'app.oracly.unknown',
    ]) {
      test('$premium is dropped (Android and untagged/iOS)', () {
        expect(
          ReadingCommerceBuyer.readingUpdatesOf([
            _play(premium, 'p1', accountTag: _tagA),
            _untagged(premium, 'p2'),
          ]),
          isEmpty,
        );
      });
    }

    test('coffee, palm and the coffee pack pass, with the store account tag',
        () {
      final out = ReadingCommerceBuyer.readingUpdatesOf([
        _play(ReadingCommerceView.coffeeId, 'c1', accountTag: _tagA),
        _play(ReadingCommerceView.palmId, 'p1', accountTag: _tagB),
        _untagged(ReadingCommerceView.packId, 'k1'),
      ]);
      expect(out.map((u) => u.productId), [
        ReadingCommerceView.coffeeId,
        ReadingCommerceView.palmId,
        ReadingCommerceView.packId,
      ]);
      expect(out.map((u) => u.ownerTag), [_tagA, _tagB, null]);
    });

    test('a launched reading purchase names its owner to the store', () {
      final param = ReadingCommerceBuyer.purchaseParamFor(
        ProductDetails(
          id: ReadingCommerceView.coffeeId,
          title: 'Coffee',
          description: 'Coffee',
          price: '₺1',
          rawPrice: 1,
          currencyCode: 'TRY',
        ),
        ownerTag: _tagA,
      );
      expect(param.applicationUserName, _tagA);
    });

    test('a Premium event on the stream never reaches reading listeners',
        () async {
      final store = StreamController<List<PurchaseDetails>>();
      final monitor = ReadingPurchaseMonitor(
        tracker: d.tracker(),
        updates: store.stream.map(ReadingCommerceBuyer.readingUpdatesOf),
        buyProduct: (_) async => true,
        storePrices: () async => const {},
      );
      final seen = <String>[];
      monitor.addListener((kind, id) => seen.add('${kind.name}:$id'));
      await monitor.start();
      store.add([_play('app.oracly.premium.yearly', 'prem', accountTag: _tagA)]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(seen, isEmpty);
      expect(d.verified, isEmpty);
      expect(d.completed, isEmpty);
      await store.close();
      await monitor.dispose();
    });
  });

  group('2. secure, owner-scoped storage', () {
    test('an unfinished purchase is kept in secure storage, never in prefs',
        () async {
      d.verdict = (_) => ReadingVerifyOutcome.unavailable;
      await d.tracker().accept(
        _update(ReadingCommerceView.coffeeId, 'raw-token-1', ownerTag: _tagA),
      );
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        expect('${prefs.get(key)}', isNot(contains('raw-token-1')),
            reason: 'prefs key $key');
      }
      expect(await d.memory().load(), hasLength(1));
    });

    test('the old plain-text record is cleared: Premium/unknown entries '
        'dropped, reading entries not handed to whoever is signed in',
        () async {
      SharedPreferences.setMockInitialValues({
        _legacyKey: [
          'purchased\u0000app.oracly.premium.yearly\u0000GPA.x\u0000prem-token',
          'purchased\u0000app.oracly.reading.coffee\u0000GPA.y\u0000legacy-coffee',
        ],
      });
      expect(await d.memory().load(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_legacyKey), isFalse);
    });
  });

  group('3. account A → B → A', () {
    test('A\'s purchase finishing while B is signed in is not verified, '
        'credited or finished for B; A gets it on return', () async {
      d.signedIn = 'uid-account-b';
      final kind = await d.tracker().accept(
        _update(ReadingCommerceView.coffeeId, 'a-coffee', ownerTag: _tagA),
      );
      expect(kind, ReadingBuyKind.pending);
      expect(d.verified, isEmpty);
      expect(d.completed, isEmpty);
      expect(await d.memory().load(), isEmpty, reason: 'B sees nothing of A');

      d.signedIn = 'uid-account-a';
      await d.tracker().resume();
      expect(d.verified, ['A:a-coffee']);
      expect(d.completed, ['a-coffee']);
    });

    test('A\'s unfinished record is not re-sent under B after a switch',
        () async {
      d.verdict = (_) => ReadingVerifyOutcome.unavailable;
      await d.tracker().accept(
        _update(ReadingCommerceView.coffeeId, 'a-coffee', ownerTag: _tagA),
      );
      d.signedIn = 'uid-account-b';
      d.verdict = (_) => ReadingVerifyOutcome.granted;
      await d.tracker().resume();
      expect(d.verified, ['A:a-coffee'], reason: 'only A\'s first attempt');
      expect(d.completed, isEmpty);
    });

    test('signed out: a delivery is left with the store, nothing verified',
        () async {
      d.signedIn = null;
      final kind = await d.tracker().accept(
        _update(ReadingCommerceView.coffeeId, 'nobody', ownerTag: _tagA),
      );
      expect(kind, ReadingBuyKind.pending);
      expect(d.verified, isEmpty);
      expect(d.completed, isEmpty);
    });
  });

  group('4. a real unfinished purchase is not lost', () {
    test('wiped local record (account switch): the store\'s redelivery is '
        'routed to its owner again and verified once', () async {
      d.verdict = (_) => ReadingVerifyOutcome.unavailable;
      await d.tracker().accept(
        _update(ReadingCommerceView.coffeeId, 'a-coffee', ownerTag: _tagA),
      );
      await d.secure.deleteAll(); // what the account wipe does
      d.verdict = (_) => ReadingVerifyOutcome.granted;
      // The store still holds it unfinished (never completed) and hands it
      // back, tagged for A.
      await d.tracker().accept(
        _update(ReadingCommerceView.coffeeId, 'a-coffee', ownerTag: _tagA),
      );
      expect(d.completed, ['a-coffee']);
    });

    test("at start the monitor routes the store's unfinished purchases: "
        "the owner's is finished, another account's is left alone", () async {
      final monitor = ReadingPurchaseMonitor(
        tracker: d.tracker(),
        updates: const Stream.empty(),
        buyProduct: (_) async => true,
        storePrices: () async => const {},
        storeUnfinished: () async => [
          _update(ReadingCommerceView.coffeeId, 'mine', ownerTag: _tagA),
          _update(ReadingCommerceView.palmId, 'theirs', ownerTag: _tagB),
        ],
      );
      await monitor.start();
      expect(d.completed, ['mine']);
      expect(d.verified, ['A:mine']);
      await monitor.dispose();
    });

    test('offline across restarts: kept, retried for its owner, finished once '
        'when the backend grants', () async {
      d.verdict = (_) => ReadingVerifyOutcome.unavailable;
      await d.tracker().accept(
        _update(ReadingCommerceView.palmId, 'palm-1', ownerTag: _tagA),
      );
      await d.tracker().resume();
      expect(d.completed, isEmpty);
      d.verdict = (_) => ReadingVerifyOutcome.granted;
      await d.tracker().resume();
      await d.tracker().resume();
      expect(d.completed, ['palm-1']);
      expect(await d.memory().load(), isEmpty);
    });

    test('an untagged Play purchase (launched before owner tags) is credited '
        'to the signed-in account, as before; StoreKit fails closed instead '
        '(reading_commerce_ios_owner_test.dart)', () async {
      await d.tracker().accept(_update(ReadingCommerceView.coffeeId, 'ios-1'));
      expect(d.verified, ['A:ios-1']);
      expect(d.completed, ['ios-1']);
    });
  });

  group('Android regression through the buyer', () {
    test('a Play purchase without an account tag (launched before owner '
        'tags) still goes to the signed-in account, verified first', () async {
      final update = ReadingCommerceBuyer.readingUpdatesOf([
        _play(ReadingCommerceView.coffeeId, 'old-play'),
      ]).single;
      expect(update.requiresOwnerProof, isFalse);
      expect(await d.tracker().accept(update), ReadingBuyKind.granted);
      expect(d.verified, ['A:old-play']);
      expect(d.completed, ['old-play']);
    });

    test('a tagged Play purchase for another account is left for its owner',
        () async {
      final update = ReadingCommerceBuyer.readingUpdatesOf([
        _play(ReadingCommerceView.coffeeId, 'b-play', accountTag: _tagB),
      ]).single;
      expect(await d.tracker().accept(update), ReadingBuyKind.pending);
      expect(d.completed, isEmpty);
    });
  });

  group('5. nothing finished at the store without a backend grant', () {
    for (final (label, verdict) in [
      ('rejected', ReadingVerifyOutcome.rejected),
      ('unavailable (App Check / offline)', ReadingVerifyOutcome.unavailable),
    ]) {
      test('$label: no completePurchase', () async {
        d.verdict = (_) => verdict;
        await d.tracker().accept(
          _update(ReadingCommerceView.coffeeId, 'c', ownerTag: _tagA),
        );
        expect(d.completed, isEmpty);
      });
    }

    test('store PENDING: stored for its owner, never verified or finished',
        () async {
      await d.tracker().accept(_update(ReadingCommerceView.coffeeId, 'slow',
          ownerTag: _tagA, status: ReadingPurchaseStatus.pending));
      expect(d.verified, isEmpty);
      expect(d.completed, isEmpty);
      expect((await d.memory().load()).single.status,
          ReadingPurchaseStatus.pending);
    });
  });
}
