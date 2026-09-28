/// G1 — SoulMate screen harness over the flaky transport, with a Premium
/// verifier that can lapse mid-session.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_input_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

const g1Png = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

const g1SoulmateResult = {
  'personality': 'p',
  'dynamic': 'd',
  'attraction': 'a',
  'challenge': 'c',
  'meeting': 'm',
  'feeling': 'f',
};

class G1Verifier implements PremiumEntitlementVerifier {
  bool active = true;
  Completer<void>? hold;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    await hold?.future;
    return active
        ? PremiumVerifyResult.active('g1')
        : PremiumVerifyResult.expired('g1');
  }
}

class G1SoulMateHarness {
  G1SoulMateHarness._(this.storage, this.users, this.service, this.status);

  final LocalStorage storage;
  final MockUserRepository users;
  final PremiumService service;
  final PremiumStatusController status;
  final verifier = G1Verifier();
  final backend = FakeReadingOperationBackend(immediatelyEligible: false);
  late final transport = G1FlakyTransport(backend);
  DateTime now = DateTime(2026, 9, 1);

  static Future<G1SoulMateHarness> open() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final premium =
        MockPremiumRepository(storage, secureStorage: InMemorySecureStorage());
    final users = MockUserRepository(storage);
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'token',
      ),
    );
    late G1SoulMateHarness harness;
    final service = PremiumService(
      premium,
      users,
      const _NoStore(),
      _Delegating(() => harness.verifier),
    );
    final status = PremiumStatusController(service, now: () => harness.now);
    harness = G1SoulMateHarness._(storage, users, service, status);
    await status.load();
    expect(status.isPremium, isTrue);
    return harness;
  }

  /// The last definitive entitlement check is too old to trust.
  void stale() => now = now.add(PremiumStatusController.freshnessWindow * 2);

  /// The store now says "expired" and the next gate must re-check.
  void lapse() {
    verifier.active = false;
    stale();
  }

  List<Override> overrides() => [
        localStorageProvider.overrideWithValue(storage),
        secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
        premiumServiceProvider.overrideWithValue(service),
        premiumStatusProvider.overrideWith((ref) => status),
        userRepositoryProvider.overrideWithValue(users),
        readingFeatureRunnerProvider.overrideWithValue(transport.runner()),
        readingOperationInputGatewayProvider.overrideWithValue(
          ReadingOperationInputGateway(send: transport.send),
        ),
      ];

  Widget screen({String? operationId, List<Override> extra = const []}) =>
      ProviderScope(
        overrides: [...overrides(), ...extra],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 1400),
            disableAnimations: true,
          ),
          child: MaterialApp(home: SoulMateDrawScreen(operationId: operationId)),
        ),
      );

  void completeServerSide(String operationId) {
    backend.setSoulmatePortrait(operationId, imageBase64: base64Encode(g1Png));
    backend.completeServerSide(
      operationId,
      resultId: 'soulmate_$operationId',
      result: g1SoulmateResult,
    );
  }

  Future<String?> activeOperationId() async {
    final wire = await backend.send(
      'GET',
      '/v1/reading-flow/active?readingType=soulmate',
      null,
    );
    final data = wire?.json?['data'];
    final operation = data is Map ? data['operation'] : null;
    return operation is Map ? operation['operationId'] as String? : null;
  }

  /// A durable operation the screen never submitted itself.
  Future<String> seedOperation(String sourceRequestId) async {
    final created = await backend.send('POST', '/v1/reading-operations', {
      'readingType': 'soulmate',
      'sourceRequestId': sourceRequestId,
      'language': 'tr',
      'executionMode': 'durable',
    });
    final id = (created!.json!['data'] as Map)['operationId'] as String;
    await backend.send('POST', '/v1/reading-operations/$id/input', {
      'name': 'Ada',
      'birthIso': '1995-03-02',
    });
    return id;
  }
}

Future<void> g1FillSoulMateForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Ada');
  await tester.tap(find.text(SoulMateCopy.birthHint));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final ok = find.text('OK');
  await tester.tap(ok.evaluate().isNotEmpty ? ok : find.text('Tamam'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(find.text(SoulMateCopy.drawCta));
  await tester.pump();
}

class _Delegating implements PremiumEntitlementVerifier {
  _Delegating(this._target);
  final PremiumEntitlementVerifier Function() _target;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) =>
      _target().verify(
        platform: platform,
        productId: productId,
        purchaseToken: purchaseToken,
        transactionId: transactionId,
      );
}

class _NoStore implements PremiumPurchasePort {
  const _NoStore();
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
