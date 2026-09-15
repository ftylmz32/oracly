/// Regression: when the store/plugin is reachable but the product catalogue
/// hasn't loaded yet (`purchaseConfigured == false` while
/// `canAttemptRestore == true`, e.g. a catalogue query timeout), the OR
/// paywall's CTA shows a "Try the store again" retry action. It must reload
/// the catalogue (`PremiumStatusController.load`) — not silently attempt a
/// purchase restore, which is a mismatched action for that label and does
/// nothing to fix the actual problem (no catalogue loaded).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_paywall_host.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store/plugin is reachable (`canAttemptRestore`) but the product
/// catalogue hasn't loaded (`isConfigured` false) — a realistic transient
/// state, not the fully-unavailable store.
class _CatalogNotLoadedYetPort implements PremiumPurchasePort {
  bool configured = false;
  bool succeedNextPrepare = false;
  int prepareCalls = 0;
  int restoreCalls = 0;

  @override
  bool get isConfigured => configured;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {
    prepareCalls++;
    // Catalogue query times out until the test explicitly arms a
    // successful retry — mirrors the real reported scenario.
    if (succeedNextPrepare) {
      configured = true;
      succeedNextPrepare = false;
    }
  }

  @override
  String? priceLabel(PremiumPlanKind plan) => null;
  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.failed();
  @override
  Future<PremiumPurchaseResult> restore() async {
    restoreCalls++;
    return PremiumPurchaseResult.restoreFailed();
  }

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'OR paywall retry-store action reloads the catalogue, not a purchase restore',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();
      final port = _CatalogNotLoadedYetPort();
      final service = PremiumService(
        MockPremiumRepository(storage, secureStorage: secure),
        MockUserRepository(storage),
        port,
        null,
        ReviewAccessRepository(storage, secureStorage: secure),
        null,
      );
      final container = ProviderContainer(
        overrides: [premiumServiceProvider.overrideWithValue(service)],
      );
      await container.read(premiumStatusProvider).load();
      expect(container.read(premiumStatusProvider).purchaseConfigured, isFalse);
      final prepareCallsAfterInitialLoad = port.prepareCalls;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanionReferenceOrPaywallHost(showHero: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(PremiumCopy.ctaRetryStore), findsOneWidget);

      port.succeedNextPrepare = true;
      await tester.ensureVisible(find.text(PremiumCopy.ctaRetryStore));
      await tester.pump();
      await tester.tap(find.text(PremiumCopy.ctaRetryStore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(port.prepareCalls, greaterThan(prepareCallsAfterInitialLoad));
      expect(port.restoreCalls, 0);
      container.dispose();
    },
  );
}
