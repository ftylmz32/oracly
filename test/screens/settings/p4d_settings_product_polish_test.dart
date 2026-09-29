/// P4D — Settings dispose safety and honest Premium cold open.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/domain/repositories/settings_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_switch.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/services/settings_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/screens/settings/reference/settings_membership_badge.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';
import 'settings_test_fakes.dart';

class _HeldSound extends SilentSound {
  Completer<void>? gate;
  int atmospheres = 0;

  void hold() => gate = Completer<void>();

  @override
  Future<OraclyApplyOutcome> setAtmosphere(ZodiacSignId sign) async {
    atmospheres++;
    final pending = gate;
    if (pending != null) await pending.future;
    return OraclyApplyOutcome.success;
  }
}

class _HeldSettings implements SettingsRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<PersonalizationSettings> load() async {
    await gate.future;
    return const PersonalizationSettings(language: 'tr');
  }

  @override
  Future<void> save(PersonalizationSettings settings) async {}
}

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

class _QuietPort implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;

  @override
  bool get canAttemptRestore => false;

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

  testWidgets('disposed settings load does not setState or snackbar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    final held = _HeldSettings();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          settingsServiceProvider.overrideWithValue(SettingsService(held)),
          oraclySoundServiceProvider.overrideWithValue(SilentSound()),
          oraclyTtsProvider.overrideWithValue(SilentTts()),
        ],
        child: const MaterialApp(home: SettingsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    held.gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets(
    'unresolved premium does not claim Standard, then shows Premium',
    (tester) async {
      final harness = await _premiumHarness(active: true);
      expect(harness.status.loaded, isFalse);
      expect(harness.status.isPremium, isFalse);

      await _pumpSettings(tester, harness);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SettingsMembershipBadge), findsNothing);
      expect(find.text('STANDARD'), findsNothing);
      expect(find.text('STANDART'), findsNothing);

      await harness.status.load();
      await tester.pump();
      expect(harness.status.loaded, isTrue);
      expect(harness.status.isPremium, isTrue);
      final badge = tester.widget<SettingsMembershipBadge>(
        find.byType(SettingsMembershipBadge),
      );
      expect(badge.isPremium, isTrue);
      expect(find.text('STANDARD'), findsNothing);
    },
  );

  testWidgets('unresolved premium settles to Standard when inactive', (
    tester,
  ) async {
    final harness = await _premiumHarness(active: false);
    await _pumpSettings(tester, harness);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('STANDARD'), findsNothing);

    await harness.status.load();
    await tester.pump();
    expect(harness.status.loaded, isTrue);
    expect(harness.status.isPremium, isFalse);
    final badge = tester.widget<SettingsMembershipBadge>(
      find.byType(SettingsMembershipBadge),
    );
    expect(badge.isPremium, isFalse);
    expect(find.text('STANDART'), findsOneWidget);
  });

  testWidgets('settings chrome fits 320 and large text', (tester) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          oraclySoundServiceProvider.overrideWithValue(SilentSound()),
          oraclyTtsProvider.overrideWithValue(SilentTts()),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.4),
            ),
            child: child!,
          ),
          home: const SettingsReferenceScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(find.text('AYARLAR'), findsOneWidget);
  });

  testWidgets('an older settings save cannot overwrite a newer toggle', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    final sound = _HeldSound();
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          oraclySoundServiceProvider.overrideWithValue(sound),
          oraclyTtsProvider.overrideWithValue(SilentTts()),
        ],
        child: const MaterialApp(home: SettingsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final soundSwitch = find.byType(SettingsReferenceSwitch).first;
    await tester.ensureVisible(soundSwitch);
    final before = sound.atmospheres;
    sound.hold();
    await tester.tap(soundSwitch);
    await tester.pump();
    expect(sound.atmospheres, before + 1);
    expect(tester.widget<SettingsReferenceSwitch>(soundSwitch).value, isFalse);

    await tester.tap(soundSwitch);
    await tester.pump();
    sound.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<SettingsReferenceSwitch>(soundSwitch).value, isTrue);
  });

  testWidgets('review access uses canonical isPremium once loaded', (
    tester,
  ) async {
    final harness = await _premiumHarness(active: false, reviewGranted: true);
    await _pumpSettings(tester, harness);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('STANDARD'), findsNothing);

    await harness.status.load();
    await tester.pump();
    expect(harness.status.isReviewAccessActive, isTrue);
    expect(harness.status.isPremium, isTrue);
    final badge = tester.widget<SettingsMembershipBadge>(
      find.byType(SettingsMembershipBadge),
    );
    expect(badge.isPremium, isTrue);
    expect(find.text('STANDARD'), findsNothing);
  });
}

class _PremiumHarness {
  _PremiumHarness(this.storage, this.status);

  final LocalStorage storage;
  final PremiumStatusController status;
}

Future<_PremiumHarness> _premiumHarness({
  required bool active,
  bool reviewGranted = false,
}) async {
  SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
  final storage = await LocalStorage.open();
  final premium = MockPremiumRepository(storage);
  final users = MockUserRepository(storage);
  if (active) {
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(_creds);
  }
  if (reviewGranted) {
    await storage.setBool(ReviewAccessRepository.grantedKey, true);
  }
  final service = PremiumService(
    premium,
    users,
    _QuietPort(),
    active ? _ActiveVerifier() : null,
    reviewGranted
        ? ReviewAccessRepository(
            storage,
            secureStorage: InMemorySecureStorage(),
          )
        : null,
  );
  if (!active) service.forceReleaseMode = true;
  return _PremiumHarness(storage, PremiumStatusController(service));
}

Future<void> _pumpSettings(WidgetTester tester, _PremiumHarness harness) {
  return tester.pumpWidget(
    buildProviderScopeHarness(
      storage: harness.storage,
      overrides: [
        premiumServiceProvider.overrideWithValue(
          PremiumService(
            MockPremiumRepository(harness.storage),
            MockUserRepository(harness.storage),
            _QuietPort(),
          ),
        ),
        premiumStatusProvider.overrideWith((ref) => harness.status),
        oraclySoundServiceProvider.overrideWithValue(SilentSound()),
        oraclyTtsProvider.overrideWithValue(SilentTts()),
      ],
      child: const MaterialApp(home: SettingsReferenceScreen()),
    ),
  );
}
