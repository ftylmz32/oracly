/// iOS App Attest release guard — regression for Build 5.
///
/// Build 5 shipped with `AppleAppAttestWithDeviceCheckFallbackProvider`
/// selected at runtime while `Runner.entitlements` lacked the App Attest
/// entitlement, so the release binary could never mint an App Attest token
/// and every protected wallet/AI request fail-closed on a real device.
///
/// These checks read the native release configuration directly. They never
/// fake a successful App Check token as proof of readiness — a passing token
/// stub says nothing about whether the signed archive carries the entitlement.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/auth/firebase/firebase_app_check_bootstrap.dart';
import 'package:oracly_new/core/auth/firebase/firebase_app_check_policy.dart';
import 'package:oracly_new/core/auth/firebase/firebase_app_check_token.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_bootstrap.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_proxy_readiness.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_headers.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';

const _entitlementsPath = 'ios/Runner/Runner.entitlements';
const _pbxPath = 'ios/Runner.xcodeproj/project.pbxproj';
const _appAttestKey = 'com.apple.developer.devicecheck.appattest-environment';
const _bootstrapPath =
    'lib/core/auth/firebase/firebase_app_check_bootstrap.dart';

const _proxy = 'https://api.oracly.app/v1/ai/complete';
const _prod = AiRuntimeConfig(
  environment: AppEnvironment.production,
  proxyUrl: _proxy,
);

/// Reads [path] with CRLF normalised (Windows checkouts use autocrlf).
String _read(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

/// Top-level `<key>` → `<string>` pairs of a flat entitlements plist.
Map<String, String> _plistStrings(String xml) {
  final pairs = RegExp(
    r'<key>\s*([^<]+?)\s*</key>\s*<string>\s*([^<]*?)\s*</string>',
  ).allMatches(xml);
  return {for (final m in pairs) m.group(1)!: m.group(2)!};
}

/// `name → buildSettings body` for every config of the Runner app target.
Map<String, String> _runnerTargetConfigs(String pbx) {
  final list = RegExp(
    r'Build configuration list for PBXNativeTarget "Runner" \*/ = \{'
    r'[^}]*?buildConfigurations = \(([^)]*)\);',
  ).firstMatch(pbx);
  expect(list, isNotNull, reason: 'Runner target configuration list missing');
  final refs = RegExp(
    r'([0-9A-F]{24}) /\* (\w+) \*/',
  ).allMatches(list!.group(1)!);
  final configs = <String, String>{};
  for (final ref in refs) {
    final id = ref.group(1)!;
    final block = RegExp(
      '$id /\\* \\w+ \\*/ = \\{\\s*isa = XCBuildConfiguration;'
      r'[\s\S]*?buildSettings = \{([\s\S]*?)\n\t\t\t\};',
    ).firstMatch(pbx);
    expect(block, isNotNull, reason: 'buildSettings for $id missing');
    configs[ref.group(2)!] = block!.group(1)!;
  }
  return configs;
}

void main() {
  group('native release entitlement', () {
    test('1. Runner.entitlements declares the App Attest entitlement', () {
      final xml = _read(_entitlementsPath);
      expect(_plistStrings(xml), contains(_appAttestKey));
    });

    test('2. App Attest environment is production (App Store/TestFlight)', () {
      final values = _plistStrings(_read(_entitlementsPath));
      expect(values[_appAttestKey], 'production');
    });

    test('existing push entitlement is preserved', () {
      final values = _plistStrings(_read(_entitlementsPath));
      expect(values['aps-environment'], 'development');
    });

    test('3/4. Runner Release and Profile sign with Runner.entitlements', () {
      final configs = _runnerTargetConfigs(_read(_pbxPath));
      expect(configs.keys, containsAll(<String>['Release', 'Profile']));
      for (final name in ['Debug', 'Release', 'Profile']) {
        expect(
          configs[name],
          contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
          reason: '$name must embed the App Attest entitlement at signing',
        );
      }
    });

    test(
      'no xcconfig or CI step overrides or strips the entitlements file',
      () {
        for (final path in [
          'ios/Flutter/Release.xcconfig',
          'ios/Flutter/Debug.xcconfig',
          'ios/Podfile',
        ]) {
          final file = File(path);
          if (!file.existsSync()) continue;
          expect(
            file.readAsStringSync(),
            isNot(contains('CODE_SIGN_ENTITLEMENTS')),
            reason: '$path must not redirect Runner entitlements',
          );
        }
        final codemagic = _read('codemagic.yaml');
        expect(codemagic, isNot(contains('CODE_SIGN_ENTITLEMENTS')));
        expect(codemagic, isNot(contains('Runner.entitlements')));
        expect(codemagic, isNot(contains(_appAttestKey)));
      },
    );
  });

  group('runtime provider selection', () {
    final source = _read(_bootstrapPath);

    test('5. Android release provider remains Play Integrity', () {
      expect(
        source,
        contains(
          'providerAndroid: debug\n'
          '            ? const AndroidDebugProvider()\n'
          '            : const AndroidPlayIntegrityProvider(),',
        ),
      );
    });

    test('6. iOS release provider remains App Attest + DeviceCheck fallback', () {
      expect(
        source,
        contains(
          'providerApple: debug\n'
          '            ? const AppleDebugProvider()\n'
          '            : const AppleAppAttestWithDeviceCheckFallbackProvider(),',
        ),
      );
      expect(source, contains('setTokenAutoRefreshEnabled(true)'));
    });

    test('release-locked builds never select the debug provider', () {
      for (final env in AppEnvironment.values) {
        expect(
          FirebaseAppCheckPolicy.useDebugProvider(
            environment: env,
            releaseLocked: true,
          ),
          FirebaseAppCheckPolicy.forceDebugProvider,
        );
      }
    });
  });

  group('7. production fails closed without an App Check token', () {
    setUp(() {
      AiRequestGuard.shared.reset();
      FirebaseAppCheckBootstrap.reset();
      FirebaseAppCheckToken.debugOverride = null;
    });
    tearDown(() {
      FirebaseAppCheckBootstrap.reset();
      FirebaseAuthBootstrap.debugSetReady(false);
    });

    test('an un-activated App Check yields no token', () async {
      expect(FirebaseAppCheckBootstrap.isActivated, isFalse);
      expect(await FirebaseAppCheckToken.current(), isNull);
    });

    test('production proxy requires App Check', () {
      expect(ProxyAiHeaders.requiresAppCheck(_prod), isTrue);
    });

    test('proxy readiness reports appCheck, never proceeds', () async {
      FirebaseAuthBootstrap.debugSetReady(true);
      final failure = await AiProxyReadiness.ensure(
        config: _prod,
        accessToken: ({bool forceRefresh = false}) async => 'firebase-token',
        appCheckToken: ({bool forceRefresh = false}) async => null,
      );
      expect(failure?.kind, AiFailureKind.appCheck);
    });

    test('header build refuses to produce unattested headers', () async {
      final headers = await ProxyAiHeaders.build(
        config: _prod,
        request: const AiProxyRequest(operation: AiOperation.chat, payload: {}),
        accessToken: ({bool forceRefresh = false}) async => 'firebase-token',
        appCheckToken: ({bool forceRefresh = false}) async => null,
      );
      expect(headers, isNull);
    });
  });

  group('8. wallet does not bypass App Check', () {
    test('wallet gateway only talks through the shared reading sender', () {
      final gateway = _read(
        'lib/features/gems/services/gem_wallet_gateway.dart',
      );
      expect(gateway, contains('final ReadingOperationSender _send;'));
      expect(gateway, isNot(contains('package:http')));
      expect(gateway, isNot(contains('HttpClient')));
    });

    test('no gems source opens its own HTTP channel', () {
      final offenders = Directory('lib/features/gems')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
            final text = _read(f.path);
            return text.contains('package:http/') ||
                text.contains('HttpClient(');
          })
          .map((f) => f.path)
          .toList();
      expect(offenders, isEmpty);
    });

    test('shared sender gates on readiness and aborts on missing headers', () {
      final sender = _read(
        'lib/features/reading_operation/providers/reading_live_provider.dart',
      );
      final readiness = sender.indexOf('await AiProxyReadiness.ensure(');
      final headers = sender.indexOf('await ProxyAiHeaders.build(');
      final network = sender.indexOf('http.Client()');
      expect(readiness, greaterThan(0));
      expect(headers, greaterThan(readiness));
      expect(network, greaterThan(headers));
      expect(sender, contains('if (blocked != null) {'));
      expect(sender, contains('if (headers == null) return null;'));
      expect(
        sender,
        contains('FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh)'),
      );
    });

    test('wallet bootstrap activates App Check before readiness', () {
      final bootstrap = _read(
        'lib/features/gems/services/gem_wallet_bootstrap.dart',
      );
      final activate = bootstrap.indexOf(
        'FirebaseAppCheckBootstrap.tryActivate',
      );
      final ready = bootstrap.indexOf('AiProxyReadiness.ensure');
      expect(activate, greaterThan(0));
      expect(ready, greaterThan(activate));
    });
  });

  group('9. Tarot AI and deepen do not bypass App Check', () {
    late bool networkCalled;
    late OpenAiOraclyAiService ai;

    setUp(() {
      AiRequestGuard.shared.reset();
      networkCalled = false;
      ai = OpenAiOraclyAiService(
        config: _prod,
        transport: ProxyAiTransport(
          config: _prod,
          accessToken: ({bool forceRefresh = false}) async => 'firebase-token',
          appCheckToken: ({bool forceRefresh = false}) async => null,
          client: MockClient((_) async {
            networkCalled = true;
            return http.Response('{}', 200);
          }),
        ),
        guard: AiRequestGuard(),
      );
    });

    test('Tarot reading', () async {
      final outcome = await ai.generateTarotReading(
        cards: const [
          {'name': 'The Star', 'positionLabel': 'Now', 'reversed': false},
        ],
        spreadLabel: 'Single',
      );
      expect(networkCalled, isFalse);
      expect(outcome.failure?.kind, AiFailureKind.appCheck);
    });

    test('narrative Tarot reading', () async {
      final outcome = await ai.generateNarrativeTarotReading(
        payload: const {'cards': []},
        fingerprint: 'app-attest-guard',
      );
      expect(networkCalled, isFalse);
      expect(outcome.failure?.kind, AiFailureKind.appCheck);
    });

    test('Tarot deepen (OR askOracle with Tarot context)', () async {
      final outcome = await ai.askOracle(
        context: const TarotAiContext(
          sessionId: 'session-1',
          spreadLabel: 'Single',
          readingTitle: 'The Star',
          cardsSummary: 'The Star',
          interpretationSummary: 'Hope returns.',
        ),
        userMessage: 'Bu kart bana ne anlatiyor?',
      );
      expect(networkCalled, isFalse);
      expect(outcome.failure?.kind, AiFailureKind.appCheck);
    });
  });
}
