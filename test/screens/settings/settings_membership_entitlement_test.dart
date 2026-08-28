/// Settings membership follows live Premium entitlement.
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
