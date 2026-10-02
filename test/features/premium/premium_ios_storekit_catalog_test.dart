/// iOS StoreKit catalogue path — port-level states, timeout and diagnostics.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase.dart';

import 'support/ios_storekit_fake.dart';

typedef _PortState = (bool configured, bool restore, String?, String?);

Future<_PortState> _prepared(FakeStoreKit iap) async {
  final port = StorePremiumPurchase(client: iap);
  await port.prepare();
  return (
    port.isConfigured,
    port.canAttemptRestore,
    port.priceLabel(PremiumPlanKind.monthly),
    port.priceLabel(PremiumPlanKind.yearly),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const iosIds = {PremiumStoreCatalog.monthlyId, PremiumStoreCatalog.yearlyId};

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS queries exactly monthly + yearly, never lifetime', () async {
    final iap = FakeStoreKit(
      products: [monthlyProduct, yearlyProduct, lifetimeProduct],
    );
    final state = await _prepared(iap);
    expect(iap.queriedIds, [iosIds]);
    expect(iap.queriedIds.single, isNot(contains(PremiumStoreCatalog.lifetimeId)));
    expect(state, (true, true, 'STORE-MONTHLY', 'STORE-YEARLY'));
  });

  test('zero products: one retry, then unconfigured but restorable', () async {
    final iap = FakeStoreKit();
    final state = await _prepared(iap);
    expect(iap.queriedIds, [iosIds, iosIds]);
    expect(iap.responses.last.notFoundIDs.toSet(), iosIds);
    expect(state, (false, true, null, null));
  });

  test('store unavailable: no query, not configured, not restorable', () async {
    final iap = FakeStoreKit(available: false, products: [yearlyProduct]);
    final state = await _prepared(iap);
    expect(iap.queriedIds, isEmpty);
    expect(state, (false, false, null, null));
  });

  testWidgets('query timeout: gives up after 8s + 0.3s + 8s, then recovers', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final iap = FakeStoreKit(
      products: [monthlyProduct, yearlyProduct],
      queryHangs: true,
    );
    final port = StorePremiumPurchase(client: iap);
    var done = false;
    port.prepare().then((_) => done = true);
    await tester.pump(const Duration(seconds: 8));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 8400));
    expect(done, isTrue);
    expect(iap.queriedIds.length, 2);
    expect(port.isConfigured, isFalse);
    expect(port.canAttemptRestore, isTrue);
    final timedOut = port.catalogSnapshot!;
    expect(timedOut.queryTimedOut, isTrue);
    expect(timedOut.attempt, 2);
    expect(timedOut.notFoundIds, isEmpty, reason: 'store gave no answer');
    expect(timedOut.requestedIds.toSet(), iosIds);

    iap.queryHangs = false;
    await port.prepare();
    expect(port.isConfigured, isTrue);
    expect(port.priceLabel(PremiumPlanKind.yearly), 'STORE-YEARLY');
    expect(port.catalogSnapshot!.queryTimedOut, isFalse);
    expect(port.catalogSnapshot!.attempt, 1);
    debugDefaultTargetPlatformOverride = null;
  });
}
