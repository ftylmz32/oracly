/// iOS reading-commerce owner safety (#44, approved 27 Oct 2026).
///
/// StoreKit 2 (the plugin default) stores the owner only as a UUID
/// `appAccountToken`; a non-UUID value is silently dropped by the native
/// side (`UUID(uuidString:)`). StoreKit 1 echoes `applicationUsername`.
/// A StoreKit event whose owner cannot be read is never verified, credited
/// or finished for whoever is signed in: it stays unfinished, so StoreKit
/// redelivers it, and only its owner can take it.
///
/// Dart/unit proof only: the StoreKit transaction objects are the plugin's
/// own Dart types, built here. No native StoreKit, Xcode or device runs on
/// Windows; real iOS behavior is not proven by these tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/reading_commerce/models/reading_commerce_view.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_commerce_buyer.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_owner_token.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_disk.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Owner tokens as StoreKit hands them back (Swift uuidString: upper case).
const _uuidA = '0F1E2D3C-4B5A-5978-8A6B-5C4D3E2F1A0B';
const _uuidB = '9A8B7C6D-5E4F-5321-9876-1A2B3C4D5E6F';

PurchaseVerificationData _data(String token) => PurchaseVerificationData(
  localVerificationData: 'jws',
  serverVerificationData: token,
  source: 'app_store',
);

PurchaseDetails _sk2(
  String productId,
  String token, {
  String? account,
  PurchaseStatus status = PurchaseStatus.purchased,
}) => SK2PurchaseDetails(
  productID: productId,
  purchaseID: 'tx-$token',
  verificationData: _data(token),
  transactionDate: '1',
  status: status,
  appAccountToken: account,
);

PurchaseDetails _sk1(
  String productId,
  String token, {
  String? account,
  PurchaseStatus status = PurchaseStatus.purchased,
}) => AppStorePurchaseDetails(
  purchaseID: 'tx-$token',
  productID: productId,
  verificationData: _data(token),
  transactionDate: '1',
  status: status,
  skPaymentTransaction: SKPaymentTransactionWrapper(
    payment: SKPaymentWrapper(productIdentifier: productId, applicationUsername: account),
    transactionState: SKPaymentTransactionStateWrapper.purchased,
    transactionIdentifier: 'tx-$token',
  ),
);

class _Device {
  final secure = InMemorySecureStorage();
  String? owner = _uuidA.toLowerCase();
  ReadingVerifyOutcome verdict = ReadingVerifyOutcome.granted;
  final verified = <String>[];
  final completed = <String>[];

  ReadingPurchaseTracker tracker() => ReadingPurchaseTracker(
    memory: SecureReadingPurchases(secure: secure, currentOwnerTag: () => owner),
    currentOwnerTag: () => owner,
    verify: (u) async {
      verified.add(u.token);
      return verdict;
    },
    complete: (u) async => completed.add(u.token),
  );

  Future<ReadingBuyKind> deliver(PurchaseDetails purchase) async {
    final updates = ReadingCommerceBuyer.readingUpdatesOf([purchase]);
    expect(updates, hasLength(1));
    return tracker().accept(updates.single);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Device d;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    d = _Device();
  });

  group('the owner is read back from StoreKit', () {
    test('StoreKit 2 appAccountToken (any case) is the owner tag', () {
      final u = ReadingCommerceBuyer.readingUpdatesOf([
        _sk2(ReadingCommerceView.coffeeId, 't', account: _uuidA),
      ]).single;
      expect(u.ownerTag, _uuidA.toLowerCase());
    });

    test('StoreKit 1 applicationUsername is the owner tag', () {
      final u = ReadingCommerceBuyer.readingUpdatesOf([
        _sk1(ReadingCommerceView.palmId, 't', account: _uuidA),
      ]).single;
      expect(u.ownerTag, _uuidA.toLowerCase());
    });
  });

  group('fail closed: no readable owner on iOS', () {
    for (final (label, purchase) in [
      ('StoreKit 2 without appAccountToken', _sk2(ReadingCommerceView.coffeeId, 'sk2-none')),
      ('StoreKit 1 without applicationUsername', _sk1(ReadingCommerceView.coffeeId, 'sk1-none')),
    ]) {
      test('$label: not verified, credited or finished for the signed-in '
          'account; left unfinished for StoreKit to redeliver', () async {
        final kind = await d.deliver(purchase);
        expect(kind, ReadingBuyKind.pending);
        expect(d.verified, isEmpty);
        expect(d.completed, isEmpty);
      });
    }
  });

  group('A → B → A on iOS', () {
    for (final (label, build) in [
      ('StoreKit 2', _sk2),
      ('StoreKit 1', _sk1),
    ]) {
      test('$label: A\'s purchase is not taken by B; A gets it', () async {
        d.owner = _uuidB.toLowerCase();
        expect(
          await d.deliver(build(ReadingCommerceView.coffeeId, 'a-coffee', account: _uuidA)),
          ReadingBuyKind.pending,
        );
        expect(d.verified, isEmpty);
        expect(d.completed, isEmpty);
        d.owner = _uuidA.toLowerCase();
        await d.tracker().resume();
        expect(d.verified, ['a-coffee']);
        expect(d.completed, ['a-coffee']);
      });
    }

    test('the owner\'s own purchase is verified and finished exactly once',
        () async {
      await d.deliver(_sk2(ReadingCommerceView.packId, 'mine', account: _uuidA));
      await d.deliver(_sk2(ReadingCommerceView.packId, 'mine', account: _uuidA));
      expect(d.completed.where((t) => t == 'mine'), hasLength(2),
          reason: 'StoreKit redelivered it; the tracker is not the dedupe');
    });
  });

  group('the owner token StoreKit 2 accepts', () {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('is a valid UUID (StoreKit 2 drops anything else), deterministic, '
        'distinct per account and free of the uid', () {
      final a = ReadingOwnerToken.forUid('uid-account-a');
      expect(a, matches(uuid));
      expect(ReadingOwnerToken.forUid('uid-account-a'), a);
      expect(ReadingOwnerToken.forUid('uid-account-b'), isNot(a));
      expect(a, isNot(contains('uid-account-a')));
    });

    test('matches the server readingOwnerToken byte for byte', () {
      // Same vector as backend/tests/reading-commerce-ios.test.ts: the
      // server refuses an iOS purchase whose token differs from this.
      expect(
        ReadingOwnerToken.forUid('user-a'),
        '434d797f-ce86-5c5e-8548-7bdd52c63fbc',
      );
    });

    test('is what a launched reading purchase sends to the store', () {
      final token = ReadingOwnerToken.forUid('uid-account-a');
      final param = ReadingCommerceBuyer.purchaseParamFor(
        ProductDetails(
          id: ReadingCommerceView.coffeeId,
          title: 'Coffee',
          description: 'Coffee',
          price: '₺1',
          rawPrice: 1,
          currencyCode: 'TRY',
        ),
        ownerTag: token,
      );
      expect(param.applicationUserName, token);
    });

    test('round trip: the token sent comes back as the same owner on both '
        'StoreKit paths and Play', () {
      final token = ReadingOwnerToken.forUid('uid-account-a');
      final back = ReadingCommerceBuyer.readingUpdatesOf([
        _sk2(ReadingCommerceView.coffeeId, 's2', account: token.toUpperCase()),
        _sk1(ReadingCommerceView.coffeeId, 's1', account: token),
      ]);
      expect(back.map((u) => u.ownerTag), [token, token]);
    });
  });

  group('more iOS lifecycles', () {
    final mine = _uuidA;

    test('restored (StoreKit) with the owner token: verified and finished',
        () async {
      await d.deliver(_sk2(ReadingCommerceView.coffeeId, 'r1',
          account: mine, status: PurchaseStatus.restored));
      expect(d.completed, ['r1']);
    });

    test('pending (Ask to Buy): kept for its owner, never verified', () async {
      expect(
        await d.deliver(_sk1(ReadingCommerceView.coffeeId, 'ask',
            account: mine, status: PurchaseStatus.pending)),
        ReadingBuyKind.pending,
      );
      expect(d.verified, isEmpty);
      expect(d.completed, isEmpty);
    });

    for (final premium in [
      'app.oracly.premium.monthly',
      'app.oracly.premium.yearly',
    ]) {
      test('$premium on StoreKit never reaches the reading listener', () {
        expect(
          ReadingCommerceBuyer.readingUpdatesOf([
            _sk2(premium, 'p2', account: mine),
            _sk1(premium, 'p1', account: mine),
          ]),
          isEmpty,
        );
      });
    }

    test('backend unavailable, then 400 (rejected): never finished; the '
        'record is dropped only on the definitive answer', () async {
      d.verdict = ReadingVerifyOutcome.unavailable;
      await d.deliver(_sk2(ReadingCommerceView.palmId, 'flaky', account: mine));
      await d.tracker().resume();
      expect(d.verified, ['flaky', 'flaky']);
      d.verdict = ReadingVerifyOutcome.rejected;
      await d.tracker().resume();
      expect(d.completed, isEmpty);
      expect(await SecureReadingPurchases(secure: d.secure, currentOwnerTag: () => d.owner).load(),
          isEmpty);
    });

    test('signed out: nothing verified or finished', () async {
      d.owner = null;
      expect(
        await d.deliver(_sk2(ReadingCommerceView.coffeeId, 'nobody', account: mine)),
        ReadingBuyKind.pending,
      );
      expect(d.verified, isEmpty);
      expect(d.completed, isEmpty);
    });

    test("account deletion wipes the local copy; StoreKit's redelivery is "
        'still taken only by its owner', () async {
      d.verdict = ReadingVerifyOutcome.unavailable;
      await d.deliver(_sk2(ReadingCommerceView.coffeeId, 'kept', account: mine));
      await d.secure.deleteAll();
      d.owner = _uuidB.toLowerCase();
      d.verdict = ReadingVerifyOutcome.granted;
      await d.deliver(_sk2(ReadingCommerceView.coffeeId, 'kept', account: mine));
      expect(d.completed, isEmpty, reason: 'B never takes it');
      d.owner = mine.toLowerCase();
      await d.deliver(_sk2(ReadingCommerceView.coffeeId, 'kept', account: mine));
      expect(d.completed, ['kept']);
    });
  });
}
