/// Pumps the real Premium screen on iOS over a [FakeStoreKit].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../test_helpers/provider_scope_harness.dart';
import 'ios_storekit_fake.dart';

Future<void> pumpIosPremium(WidgetTester tester, FakeStoreKit iap) async {
  await tester.binding.setSurfaceSize(const Size(390, 2400));
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      purchasePort: StorePremiumPurchase(client: iap),
      child: const MaterialApp(home: PremiumReferenceScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void iosPremiumTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });
}
