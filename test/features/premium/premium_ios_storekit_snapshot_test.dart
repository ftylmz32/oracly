/// iOS StoreKit outcomes stay distinct in the safe catalogue snapshot.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/features/premium/models/store_catalog_snapshot.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase.dart';

import 'support/ios_storekit_fake.dart';

Future<(StorePremiumPurchase, StoreCatalogSnapshot)> _snap(
  FakeStoreKit iap,
) async {
  final port = StorePremiumPurchase(client: iap);
  await port.prepare();
  return (port, port.catalogSnapshot!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const iosIds = {PremiumStoreCatalog.monthlyId, PremiumStoreCatalog.yearlyId};

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('no snapshot before the first prepare', () {
    expect(StorePremiumPurchase(client: FakeStoreKit()).catalogSnapshot, isNull);
  });

  test('notFoundIDs: the exact ids StoreKit reported are preserved', () async {
    final (port, s) = await _snap(FakeStoreKit(products: [monthlyProduct]));
    expect(port.isConfigured, isTrue);
    expect(s.storeAvailable, isTrue);
    expect(s.attempt, 1);
    expect(s.requestedIds.toSet(), iosIds);
    expect(s.returnedIds, [PremiumStoreCatalog.monthlyId]);
    expect(s.notFoundIds, [PremiumStoreCatalog.yearlyId]);
    expect(s.errorCode, isNull);
    expect(s.queryTimedOut, isFalse);
    expect(s.queryExceptionType, isNull);
  });

  test('zero returned: both ids not found after the single retry', () async {
    final (_, s) = await _snap(FakeStoreKit());
    expect(s.attempt, 2);
    expect(s.returnedIds, isEmpty);
    expect(s.notFoundIds.toSet(), iosIds);
  });

  test('StoreKit error: code and capped message are preserved', () async {
    final (port, s) = await _snap(
      FakeStoreKit(
        products: [monthlyProduct, yearlyProduct],
        queryError: IAPError(
          source: 'app_store',
          code: 'storekit2_failed_to_fetch_product',
          message: 'simulated\n\n  failure ${'x' * 400}',
        ),
      ),
    );
    expect(port.isConfigured, isFalse);
    expect(s.errorCode, 'storekit2_failed_to_fetch_product');
    expect(s.errorMessage, startsWith('simulated failure x'));
    expect(
      s.errorMessage!.length,
      lessThanOrEqualTo(StoreCatalogSnapshot.maxMessageLength + 1),
    );
    expect(s.queryExceptionType, isNull);
  });

  test('StoreKit exception: only the exception TYPE is preserved', () async {
    final (port, s) = await _snap(FakeStoreKit(queryThrows: true));
    expect(port.isConfigured, isFalse);
    expect(port.canAttemptRestore, isTrue);
    expect(s.queryExceptionType, 'StateError');
    expect(s.errorMessage, isNull, reason: 'exception text is never kept');
    expect(s.notFoundIds, isEmpty, reason: 'not disguised as not-found');
  });

  test('store unavailable: no query, availability recorded', () async {
    final (port, s) = await _snap(FakeStoreKit(available: false));
    expect(port.canAttemptRestore, isFalse);
    expect(s.storeAvailable, isFalse);
    expect(s.attempt, 0);
    expect(s.availabilityTimedOut, isFalse);
    expect(s.availabilityExceptionType, isNull);
  });

  test('availability exception: type recorded, store unavailable', () async {
    final (_, s) = await _snap(FakeStoreKit(availabilityThrows: true));
    expect(s.storeAvailable, isFalse);
    expect(s.availabilityExceptionType, 'UnsupportedError');
  });

  test('outcomes that used to collapse are now distinguishable', () async {
    final (_, notFound) = await _snap(FakeStoreKit());
    final (_, error) = await _snap(
      FakeStoreKit(
        queryError: IAPError(source: 'app_store', code: 'c', message: 'm'),
      ),
    );
    final (_, thrown) = await _snap(FakeStoreKit(queryThrows: true));
    expect(notFound.errorCode, isNull);
    expect(notFound.queryExceptionType, isNull);
    expect(error.errorCode, 'c');
    expect(thrown.queryExceptionType, 'StateError');
  });
}
