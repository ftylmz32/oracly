/// WAVE 2.14 / 2.15 — release config fail-closed startup.
///
/// Mandatory release config is OraclyRuntimeConfig.missingMandatoryReleaseKeys
/// (ORACLY_AI_PROXY_URL, ORACLY_BILLING_VERIFY_URL). Contract: a
/// release-locked PRODUCTION build whose mandatory config is missing or
/// rejected must NOT start the normal product; it shows a terminal surface
/// that never reveals a configuration value. Development, internal, staging
/// and a correctly configured release start normally.
///
/// The startup root is chosen exactly as main() does:
/// `ReleaseStartupGate.blockedRoot(config) ?? OraclyApp`, and a
/// structural check pins main() to consult the gate before the product.
/// Release semantics use the existing hooks: OraclyRuntimeConfig.testEnv +
/// resolve(releaseLocked: true), and AiRuntimeConfig(simulateReleaseBuild:
/// true) for the release-locked proxy policy. No network / provider calls.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/oracly_app.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/config/oracly_runtime_config.dart';
import 'package:oracly_new/core/config/oracly_runtime_keys.dart';
import 'package:oracly_new/core/config/release_startup_gate.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/premium/providers/premium_entitlement_verifier_provider.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/screens/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-shaped public HTTPS endpoints (the app's own internal service).
const _validProxy = OraclyRuntimeConfig.internalAiProxyUrl;
const _validBilling = OraclyRuntimeConfig.internalBillingVerifyUrl;
const _placeholderProxy = 'https://REPLACE_WITH_PRODUCTION_HOST/v1/ai/complete';

OraclyRuntimeConfig _resolve(Map<String, String> env, {bool locked = true}) {
  OraclyRuntimeConfig.testEnv = env;
  return OraclyRuntimeConfig.resolve(releaseLocked: locked);
}

class _Boot {
  _Boot(this.container);
  final ProviderContainer? container;

  bool get productStarted => find.byType(SplashScreen).evaluate().isNotEmpty;
  bool get failureShown =>
      find.byType(ReleaseConfigFailureApp).evaluate().isNotEmpty;

  bool get senderNull =>
      container!.read(readingOperationSenderProvider) == null;
  bool get billingRemote => container!
      .read(premiumEntitlementVerifierProvider)
      .isRemoteVerifierConfigured;

  String impact() => container == null
      ? 'impact: no product providers created'
      : 'impact: readingSender=${senderNull ? 'null' : 'set'} '
          'billingVerifier=${billingRemote ? 'remote' : 'local-only'}';
}

/// Same root selection as main(): the gate first, the product otherwise.
Future<_Boot> _start(
  WidgetTester tester,
  OraclyRuntimeConfig config, {
  required String? rawProxy,
}) async {
  final blocked = ReleaseStartupGate.blockedRoot(config);
  if (blocked != null) {
    await tester.pumpWidget(blocked);
    await tester.pump();
    return _Boot(null);
  }
  SharedPreferences.setMockInitialValues({'settings_language': 'tr'});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        aiRuntimeConfigProvider.overrideWithValue(
          AiRuntimeConfig(
            environment: config.environment,
            proxyUrl: rawProxy,
            simulateReleaseBuild: config.releaseLocked,
          ),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return const OraclyApp();
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return _Boot(container);
}

List<String> _visibleTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .where((t) => t.isNotEmpty)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyRuntimeConfig.testEnv = null);
  tearDown(() => OraclyRuntimeConfig.testEnv = null);

  group('misconfigured PRODUCTION release must not start the product', () {
    final cases = <String, (Map<String, String>, List<String>)>{
      'A. AI proxy missing': (
        {
          OraclyRuntimeKeys.appEnv: 'production',
          OraclyRuntimeKeys.billingVerifyUrl: _validBilling,
        },
        [OraclyRuntimeKeys.aiProxyUrl],
      ),
      'B. AI proxy invalid (placeholder host rejected)': (
        {
          OraclyRuntimeKeys.appEnv: 'production',
          OraclyRuntimeKeys.aiProxyUrl: _placeholderProxy,
          OraclyRuntimeKeys.billingVerifyUrl: _validBilling,
        },
        [OraclyRuntimeKeys.aiProxyUrl],
      ),
      'C. billing verify URL missing': (
        {
          OraclyRuntimeKeys.appEnv: 'production',
          OraclyRuntimeKeys.aiProxyUrl: _validProxy,
        },
        [OraclyRuntimeKeys.billingVerifyUrl],
      ),
      'D. both mandatory keys missing': (
        {OraclyRuntimeKeys.appEnv: 'production'},
        [OraclyRuntimeKeys.aiProxyUrl, OraclyRuntimeKeys.billingVerifyUrl],
      ),
    };

    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        final (env, expectedMissing) = entry.value;
        final config = _resolve(env);
        expect(config.environment, AppEnvironment.production);
        expect(config.isReleaseConfigComplete, isFalse,
            reason: 'precondition: release config is incomplete');
        expect(config.missingMandatoryReleaseKeys, expectedMissing);
        expect(ReleaseStartupGate.evaluate(config),
            ReleaseStartupDecision.blockMisconfiguredRelease);

        final boot = await _start(
          tester,
          config,
          rawProxy: env[OraclyRuntimeKeys.aiProxyUrl],
        );

        expect(boot.productStarted, isFalse,
            reason: 'release with missing ${config.missingMandatoryReleaseKeys} '
                'started the normal product (Splash). ${boot.impact()}');
        expect(find.byType(OraclyApp), findsNothing,
            reason: 'no product root: no reading or purchase UI reachable');
        expect(boot.failureShown, isTrue, reason: 'terminal surface shown');
        expect(find.text(ReleaseConfigFailureApp.message), findsOneWidget);
        expect(find.byType(GestureDetector), findsNothing,
            reason: 'no retry / no actions: config is fixed at build time');

        // Secret safety: nothing on screen reveals a configuration value.
        final texts = _visibleTexts(tester).join('\n');
        for (final value in env.values) {
          expect(texts.contains(value), isFalse, reason: 'leaked "$value"');
        }
        for (final marker in ['http', '://', 'REPLACE', 'token', 'run.app']) {
          expect(texts.toLowerCase().contains(marker.toLowerCase()), isFalse,
              reason: 'leaked "$marker"');
        }
      });
    }
  });

  group('controls (must start normally)', () {
    testWidgets('VALID production release starts the product', (tester) async {
      final config = _resolve({
        OraclyRuntimeKeys.appEnv: 'production',
        OraclyRuntimeKeys.aiProxyUrl: _validProxy,
        OraclyRuntimeKeys.billingVerifyUrl: _validBilling,
      });
      expect(config.isReleaseConfigComplete, isTrue);
      expect(config.missingMandatoryReleaseKeys, isEmpty);
      expect(ReleaseStartupGate.evaluate(config), ReleaseStartupDecision.allow);

      final boot = await _start(tester, config, rawProxy: _validProxy);

      expect(boot.productStarted, isTrue);
      expect(boot.failureShown, isFalse);
      expect(boot.senderNull, isFalse, reason: boot.impact());
      expect(boot.billingRemote, isTrue, reason: boot.impact());
    });

    testWidgets('DEVELOPMENT (not release-locked) is never blocked',
        (tester) async {
      final config = _resolve(
        {OraclyRuntimeKeys.appEnv: 'development'},
        locked: false,
      );
      expect(config.environment, AppEnvironment.development);
      expect(ReleaseStartupGate.evaluate(config), ReleaseStartupDecision.allow);

      final boot = await _start(tester, config, rawProxy: null);

      expect(boot.productStarted, isTrue);
      expect(boot.failureShown, isFalse);
    });

    testWidgets('INTERNAL build resolves its fixed endpoints and starts',
        (tester) async {
      final config = _resolve({OraclyRuntimeKeys.appEnv: 'internal'});
      expect(config.aiProxyUrl, _validProxy);
      expect(config.billingVerifyUrl, _validBilling);
      expect(config.isReleaseConfigComplete, isTrue);
      expect(ReleaseStartupGate.evaluate(config), ReleaseStartupDecision.allow);

      final boot = await _start(tester, config, rawProxy: config.aiProxyUrl);

      expect(boot.productStarted, isTrue);
      expect(boot.senderNull, isFalse, reason: boot.impact());
    });

    testWidgets('STAGING keeps its current behaviour (starts; no new policy)',
        (tester) async {
      final config = _resolve({OraclyRuntimeKeys.appEnv: 'staging'});
      expect(config.environment, AppEnvironment.staging);
      expect(config.isReleaseConfigComplete, isFalse);
      expect(ReleaseStartupGate.evaluate(config), ReleaseStartupDecision.allow);

      final boot = await _start(tester, config, rawProxy: null);

      expect(boot.productStarted, isTrue);
      expect(boot.failureShown, isFalse);
    });
  });

  test('main() consults the gate before creating any product state', () {
    final source = File('lib/main.dart').readAsStringSync();
    final gate = source.indexOf('ReleaseStartupGate.blockedRoot(');
    expect(gate, isNonNegative, reason: 'main() must consult the gate');
    for (final later in [
      'LocalStorage.ephemeral()',
      'ProviderContainer(',
      'const OraclyApp()',
      '_deferredStartup(container',
    ]) {
      final at = source.indexOf(later);
      expect(at, greaterThan(gate), reason: '$later must come after the gate');
    }
  });

  test('a non-release-locked production config is never blocked', () {
    final config = _resolve(
      {OraclyRuntimeKeys.appEnv: 'production'},
      locked: false,
    );
    expect(config.releaseLocked, isFalse);
    expect(ReleaseStartupGate.evaluate(config), ReleaseStartupDecision.allow);
  });
}
