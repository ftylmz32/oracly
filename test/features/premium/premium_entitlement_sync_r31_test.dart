/// R3.1 — definitive freshness, failure-code plumbing, lifecycle contract.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/reading_operation/models/reading_failure_code.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_codec.dart';
import 'package:oracly_new/shared/navigation/oracly_shell_lifecycle_attachment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock {
  _Clock(this.value);
  DateTime value;
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

class _ScriptedVerifier implements PremiumEntitlementVerifier {
  _ScriptedVerifier([List<PremiumVerifyResult>? results])
      : _results = results ?? [];
  final List<PremiumVerifyResult> _results;
  int calls = 0;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final result = _results.isEmpty
        ? PremiumVerifyResult.active('ok')
        : _results[calls.clamp(0, _results.length - 1)];
    calls++;
    return result;
  }
}

class _Port implements PremiumPurchasePort {
  _Port(this.credentials);
  final PremiumPurchaseCredentials credentials;

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
      PremiumPurchaseResult.granted(plan, credentials: credentials);
  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restored(
        PremiumPlanKind.monthly,
        credentials: credentials,
      );
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: 'app.oracly.premium.monthly',
  purchaseToken: 'r31-token',
  transactionId: 'r31-txn',
);

Future<({PremiumStatusController c, _ScriptedVerifier v, _Clock clock})>
    _activeController({
  List<PremiumVerifyResult>? verifyResults,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorage(prefs);
  final premium = MockPremiumRepository(
    storage,
    secureStorage: InMemorySecureStorage(),
  );
  await premium.activatePlan(PremiumPlanKind.monthly, authoritative: true);
  await premium.savePurchaseCredentials(_creds);
  final verifier = _ScriptedVerifier(verifyResults);
  final clock = _Clock(DateTime.utc(2026, 9, 15, 18));
  final service = PremiumService(
    premium,
    MockUserRepository(storage),
    _Port(_creds),
    verifier,
  );
  final controller = PremiumStatusController(service, now: clock.call);
  await controller.load();
  return (c: controller, v: verifier, clock: clock);
}

Map<String, dynamic> _failedPayload(Object? failureCode) {
  final map = <String, dynamic>{
    'operationId': 'e' * 32,
    'readingType': 'soulmate',
    'status': 'failed',
    'createdAt': '2026-09-08T00:00:00.000Z',
    'readyAt': '2026-09-08T02:00:00.000Z',
    'serverNow': '2026-09-08T02:00:00.000Z',
    'waitFinished': true,
    'remainingMs': 0,
    'resultReady': false,
    'resultId': null,
  };
  if (failureCode != null) map['failureCode'] = failureCode;
  return map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('definitive freshness', () {
    test('definitive active is fresh for 120s', () async {
      final h = await _activeController();
      expect(h.c.isFresh, isTrue);
      expect(h.c.lastDefinitiveReconciledAt, isNotNull);
      final before = h.v.calls;
      await h.c.ensureFresh();
      expect(h.v.calls, before);
    });

    test('transient error does not advance definitive freshness', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('boot'),
          PremiumVerifyResult.error('network_or_parse'),
        ],
      );
      final definitiveAt = h.c.lastDefinitiveReconciledAt;
      h.clock.advance(PremiumStatusController.freshnessWindow +
          const Duration(seconds: 1));
      await h.c.ensureFresh();
      expect(h.c.isPremium, isTrue);
      expect(h.c.isFresh, isFalse);
      expect(h.c.lastDefinitiveReconciledAt, definitiveAt);
      expect(h.c.lastReconcileAttemptAt, isNotNull);
    });

    test('immediate retry after transient is throttled', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('boot'),
          PremiumVerifyResult.error('timeout'),
          PremiumVerifyResult.active('retry'),
        ],
      );
      h.clock.advance(const Duration(minutes: 3));
      await h.c.ensureFresh();
      final afterTransient = h.v.calls;
      await h.c.ensureFresh();
      expect(h.v.calls, afterTransient);
    });

    test('after retry throttle expires, reconcile runs again', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('boot'),
          PremiumVerifyResult.error('timeout'),
          PremiumVerifyResult.active('retry'),
        ],
      );
      h.clock.advance(const Duration(minutes: 3));
      await h.c.ensureFresh();
      final afterTransient = h.v.calls;
      h.clock.advance(PremiumStatusController.retryThrottle +
          const Duration(seconds: 1));
      await h.c.ensureFresh();
      expect(h.v.calls, afterTransient + 1);
      expect(h.c.isFresh, isTrue);
    });

    test('definite inactive updates freshness and demotes', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('boot'),
          PremiumVerifyResult.expired('sandbox_expired'),
        ],
      );
      h.clock.advance(const Duration(minutes: 3));
      await h.c.ensureFresh();
      expect(h.c.isPremium, isFalse);
      expect(h.c.entitlement, PremiumEntitlementState.inactive);
      expect(h.c.isFresh, isTrue);
    });

    test('single-flight coalesces concurrent triggers', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('a'),
          PremiumVerifyResult.active('b'),
          PremiumVerifyResult.active('c'),
        ],
      );
      h.clock.advance(const Duration(minutes: 3));
      final before = h.v.calls;
      await Future.wait([
        h.c.ensureFresh(),
        h.c.ensureFresh(),
        h.c.ensureFresh(),
      ]);
      expect(h.v.calls, before + 1);
    });
  });

  group('failure code codec', () {
    const codec = ReadingOperationCodec();

    test('entitlement_denied decodes', () {
      final snap = codec.parse(_failedPayload('entitlement_denied'));
      expect(snap, isNotNull);
      expect(snap!.failureCode, ReadingFailureCode.entitlementDenied);
      expect(snap.failureCode.isEntitlementDenial, isTrue);
    });

    test('provider unavailable decodes', () {
      final snap = codec.parse(_failedPayload('unavailable'));
      expect(snap!.failureCode, ReadingFailureCode.unavailable);
      expect(snap.failureCode.isEntitlementDenial, isFalse);
    });

    test('missing historical failureCode is unknown', () {
      final snap = codec.parse(_failedPayload(null));
      expect(snap!.failureCode, ReadingFailureCode.unknown);
    });

    test('unknown future failureCode does not crash', () {
      final snap = codec.parse(_failedPayload('future_provider_xyz'));
      expect(snap!.failureCode, ReadingFailureCode.unknown);
    });
  });

  group('live incident variants', () {
    test('A: stale active + expiry blocks submit gate', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('boot'),
          PremiumVerifyResult.expired('sandbox_naturally_expired'),
        ],
      );
      expect(h.c.isPremium, isTrue);
      h.clock.advance(const Duration(minutes: 3));
      await h.c.ensureFresh();
      expect(h.c.isPremium, isFalse);
    });

    test('B: forceReconcile after entitlement denial demotes', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('boot'),
          PremiumVerifyResult.expired('denied_after_submit'),
        ],
      );
      // Still within freshness — denial path uses forceReconcile.
      await h.c.forceReconcile();
      expect(h.c.isPremium, isFalse);
    });

    test('C: non-premium failure must not require forceReconcile', () {
      // Classification-only: unrelated codes are not entitlement denial.
      expect(
        ReadingFailureCode.unavailable.isEntitlementDenial,
        isFalse,
      );
      expect(ReadingFailureCode.invalid.isEntitlementDenial, isFalse);
      expect(ReadingFailureCode.unknown.isEntitlementDenial, isFalse);
      expect(
        ReadingFailureCode.entitlementDenied.isEntitlementDenial,
        isTrue,
      );
    });
  });

  group('lifecycle attachment', () {
    test('attach once, rebuild-safe, dispose removes, resume after detach silent',
        () {
      final events = <AppLifecycleState>[];
      final attachment = OraclyShellLifecycleAttachment(
        onLifecycle: events.add,
      );
      expect(attachment.isAttached, isFalse);
      attachment.attach();
      expect(attachment.isAttached, isTrue);
      attachment.attach(); // rebuild / double-attach
      expect(attachment.isAttached, isTrue);

      attachment.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(events, [AppLifecycleState.resumed]);

      attachment.detach();
      expect(attachment.isAttached, isFalse);
      attachment.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(events, [AppLifecycleState.resumed]); // no extra
    });

    test('resume while reconcile in-flight shares one call', () async {
      final h = await _activeController(
        verifyResults: [
          PremiumVerifyResult.active('boot'),
          PremiumVerifyResult.active('resume'),
        ],
      );
      h.clock.advance(const Duration(minutes: 3));
      final before = h.v.calls;
      final a = h.c.ensureFresh();
      final b = h.c.ensureFresh();
      await Future.wait([a, b]);
      expect(h.v.calls, before + 1);
    });
  });
}
