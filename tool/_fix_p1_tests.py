from pathlib import Path

Path("test/features/premium/premium_paywall_privacy_test.dart").write_text(
    """/// Paywall footer exposes the existing Privacy destination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_links.dart';
import 'package:oracly_new/features/privacy/presentation/screens/privacy_control_center_screen.dart';
import 'package:oracly_new/screens/privacy/privacy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  testWidgets('paywall links open existing Privacy route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          routes: {
            OraclyRoutes.privacy: (_) => const PrivacyScreen(),
          },
          home: const Scaffold(body: PremiumReferenceLinks()),
        ),
      ),
    );

    expect(find.text(OraclyL10n.t(L10nKeys.privacy)), findsOneWidget);
    await tester.tap(find.text(OraclyL10n.t(L10nKeys.privacy)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.byType(PrivacyControlCenterScreen), findsOneWidget);
  });
}
""",
    encoding="utf-8",
    newline="\n",
)

Path("test/screens/settings/settings_membership_entitlement_test.dart").write_text(
    """/// Settings membership follows live Premium entitlement.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/screens/settings/reference/settings_membership_badge.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

class _ConfiguredPort implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;

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

  testWidgets('membership matches canonical entitlement when active',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final premium = MockPremiumRepository(storage);
    final users = MockUserRepository(storage);
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    final service = PremiumService(premium, users, _ConfiguredPort());
    final status = PremiumStatusController(service);
    await status.load();
    expect(status.isPremium, isTrue);

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          premiumServiceProvider.overrideWithValue(service),
          premiumStatusProvider.overrideWith((ref) => status),
          userRepositoryProvider.overrideWithValue(users),
        ],
        child: const MaterialApp(home: SettingsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final badge = tester.widget<SettingsMembershipBadge>(
      find.byType(SettingsMembershipBadge),
    );
    expect(badge.isPremium, isTrue);
  });

  testWidgets('membership shows free when entitlement inactive', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final premium = MockPremiumRepository(storage);
    final users = MockUserRepository(storage);
    final service = PremiumService(premium, users, _ConfiguredPort())
      ..forceReleaseMode = true;
    final status = PremiumStatusController(service);
    await status.load();
    expect(status.isPremium, isFalse);

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          premiumServiceProvider.overrideWithValue(service),
          premiumStatusProvider.overrideWith((ref) => status),
          userRepositoryProvider.overrideWithValue(users),
        ],
        child: const MaterialApp(home: SettingsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final badge = tester.widget<SettingsMembershipBadge>(
      find.byType(SettingsMembershipBadge),
    );
    expect(badge.isPremium, isFalse);
  });
}
""",
    encoding="utf-8",
    newline="\n",
)

print("ok")
