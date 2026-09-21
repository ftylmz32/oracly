/// Home tile taps must open the correct chamber — never silent Tarot hijack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_entry_gate.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

class _ColdStartActiveVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async => PremiumVerifyResult.active('cold_start_active');
}

class _ColdStartStorePort implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;

  @override
  bool get canAttemptRestore => true;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.unavailable();

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreUnavailable();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  Future<void> pumpHome(WidgetTester tester) async {
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: MediaQuery(
            data: const MediaQueryData(
              size: size,
              padding: EdgeInsets.only(bottom: 34),
            ),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapModule(WidgetTester tester, OraclyFeatureId id) async {
    final title = HomeDiscoveryCopy.title(id);
    // Titles sit on the tile art; ensure the module grid is scrolled into view.
    final titleFinder = find.text(title);
    expect(
      titleFinder,
      findsWidgets,
      reason: 'missing Home tile title for $id ($title)',
    );
    await tester.ensureVisible(titleFinder.first);
    await tester.pump();
    await tester.tap(titleFinder.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('Coffee tile opens Coffee, never Tarot', (tester) async {
    await pumpHome(tester);
    await tapModule(tester, OraclyFeatureId.coffee);
    expect(find.byType(CoffeeV2EntryGate), findsOneWidget);
    expect(find.byType(TarotModuleNavigator), findsNothing);
  });

  testWidgets('Palm tile opens Palm, never Tarot', (tester) async {
    await pumpHome(tester);
    await tapModule(tester, OraclyFeatureId.palm);
    expect(find.byType(PalmReferenceScreen), findsOneWidget);
    expect(find.byType(TarotModuleNavigator), findsNothing);
  });

  testWidgets('Soul Mate tile opens Premium gate, never Tarot', (tester) async {
    await pumpHome(tester);
    await tapModule(tester, OraclyFeatureId.soulMate);
    expect(find.text(PremiumCopy.gateTitle), findsOneWidget);
    expect(find.byType(TarotModuleNavigator), findsNothing);
    expect(find.byType(SoulMateDrawScreen), findsNothing);
  });

  testWidgets(
    'cold-start entitled Soul Mate tap awaits Premium load then opens Soul Mate, never paywall/Tarot',
    (tester) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'or_premium_active': true,
        'or_premium_authoritative': true,
        'or_premium_plan': PremiumPlanKind.yearly.index,
        'or_premium_platform': 'android',
        'or_premium_product_id': 'app.oracly.premium.yearly',
        'or_premium_purchase_token': 'cold-start-valid-token',
      });
      final storage = await LocalStorage.open();
      final premiumRepo = MockPremiumRepository(storage);
      final service = PremiumService(
        premiumRepo,
        MockUserRepository(storage),
        _ColdStartStorePort(),
        _ColdStartActiveVerifier(),
      )..forceReleaseMode = true;
      final status = PremiumStatusController(service);
      expect(status.loaded, isFalse);

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [
            premiumStatusProvider.overrideWith((ref) => status),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => OraclyFeatureNavigation.open(
                    context,
                    OraclyFeatureId.soulMate,
                  ),
                  child: const Text('OPEN_SOULMATE'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN_SOULMATE'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(status.loaded, isTrue);
      expect(status.isPremium, isTrue);
      expect(find.byType(SoulMateDrawScreen), findsOneWidget);
      expect(find.text(PremiumCopy.gateTitle), findsNothing);
      expect(find.byType(TarotModuleNavigator), findsNothing);
    },
  );

  testWidgets('Tarot tile opens Tarot only', (tester) async {
    await pumpHome(tester);
    await tapModule(tester, OraclyFeatureId.tarot);
    expect(find.byType(TarotModuleNavigator), findsOneWidget);
    expect(find.byType(CoffeeV2EntryGate), findsNothing);
    expect(find.byType(PalmReferenceScreen), findsNothing);
  });

  testWidgets(
    'Premium entry stays reachable on iPhone viewport and opens Premium',
    (tester) async {
      await pumpHome(tester);
      expect(find.byType(HomeMasterPremium), findsOneWidget);

      if (find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          find.byType(HomeMasterPremium),
          80,
          scrollable: find
              .descendant(
                of: find.byType(HomeMasterPage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pump();
      }

      await tester.tap(find.byType(HomeMasterPremium));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PremiumReferenceScreen), findsOneWidget);
      // UnavailablePremiumPurchase harness — honest CTA, screen still visible.
      expect(find.byType(PremiumReferenceScreen), findsOneWidget);
    },
  );
}
