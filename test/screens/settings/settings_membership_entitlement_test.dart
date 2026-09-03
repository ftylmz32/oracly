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
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/screens/settings/reference/settings_membership_badge.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: 'app.oracly.premium.yearly',
  purchaseToken: 'verified-token',
);

class _ActiveVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async => PremiumVerifyResult.active('authoritative');
}

class _ResultVerifier implements PremiumEntitlementVerifier {
  _ResultVerifier(this.result);
  final PremiumVerifyResult result;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async => result;
}

class _ConfiguredPort implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => isConfigured;

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

Future<(LocalStorage, MockPremiumRepository, MockUserRepository)>
_open() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  return (storage, MockPremiumRepository(storage), MockUserRepository(storage));
}

Future<void> _seedAuthoritative(MockPremiumRepository premium) async {
  await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
  await premium.savePurchaseCredentials(_creds);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  test(
    'authoritative grant with credentials stays active after load',
    () async {
      final (_, premium, users) = await _open();
      await _seedAuthoritative(premium);
      final status = PremiumStatusController(
        PremiumService(premium, users, _ConfiguredPort(), _ActiveVerifier()),
      );
      await status.load();
      expect(status.entitlement, PremiumEntitlementState.active);
      expect(status.isPremium, isTrue);
      expect(premium.wasAuthoritativelyVerified, isTrue);
    },
  );

  test('non-authoritative local cache does not unlock Premium', () async {
    final (_, premium, users) = await _open();
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: false);
    await premium.savePurchaseCredentials(_creds);
    final status = PremiumStatusController(
      PremiumService(premium, users, _ConfiguredPort(), _ActiveVerifier())
        ..forceReleaseMode = true,
    );
    await status.load();
    expect(status.isPremium, isFalse);
    expect(status.entitlement, PremiumEntitlementState.unverified);
  });

  test('expired verification demotes Premium on refresh', () async {
    final (_, premium, users) = await _open();
    await _seedAuthoritative(premium);
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        _ConfiguredPort(),
        _ResultVerifier(PremiumVerifyResult.expired('expired')),
      ),
    );
    await status.load();
    expect(status.isPremium, isFalse);
    expect(status.entitlement, PremiumEntitlementState.inactive);
    expect(await premium.isPremiumActive(), isFalse);
  });

  test('revoked verification demotes Premium on refresh', () async {
    final (_, premium, users) = await _open();
    await _seedAuthoritative(premium);
    final status = PremiumStatusController(
      PremiumService(
        premium,
        users,
        _ConfiguredPort(),
        _ResultVerifier(PremiumVerifyResult.inactive('revoked')),
      ),
    );
    await status.load();
    expect(status.isPremium, isFalse);
    expect(status.entitlement, PremiumEntitlementState.inactive);
  });

  testWidgets('membership matches canonical entitlement when active', (
    tester,
  ) async {
    final (storage, premium, users) = await _open();
    await _seedAuthoritative(premium);
    final service = PremiumService(
      premium,
      users,
      _ConfiguredPort(),
      _ActiveVerifier(),
    );
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

  testWidgets('membership shows free when entitlement inactive', (
    tester,
  ) async {
    final (storage, premium, users) = await _open();
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
