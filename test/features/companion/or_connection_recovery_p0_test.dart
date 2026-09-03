/// P0 - OR opens offline; loopback proxy is not auto-claimed on phones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/config/oracly_runtime_config.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_connection_strip.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/home/master/home_master_or.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local proxy addresses are platform-specific helpers', () {
    expect(
      AiRuntimeConfig.devProxyAutoDefaultUrl(
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      AiRuntimeConfig.androidEmulatorDevProxyUrl,
    );
    expect(
      AiRuntimeConfig.devProxyAutoDefaultUrl(
        platform: TargetPlatform.iOS,
        isWeb: false,
      ),
      AiRuntimeConfig.localDevProxyUrl,
    );
    expect(
      AiRuntimeConfig.devProxyAutoDefaultUrl(
        platform: TargetPlatform.windows,
        isWeb: false,
      ),
      AiRuntimeConfig.localDevProxyUrl,
    );
    expect(
      AiRuntimeConfig.loopbackProxyAutoDefaultAllowed(
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      isFalse,
    );
  });

  test('unset debug environment does not silently select localhost', () {
    OraclyRuntimeConfig.testEnv = const {};
    addTearDown(() => OraclyRuntimeConfig.testEnv = null);
    final config = AiRuntimeConfig.resolve();
    expect(config.environment, AppEnvironment.development);
    expect(config.resolvedProxyUrl, isNull);
    expect(config.isConfigured, isFalse);
  });

  test('explicit LOCAL selects Android emulator loopback', () {
    OraclyRuntimeConfig.testEnv = const {'APP_ENV': 'local'};
    addTearDown(() => OraclyRuntimeConfig.testEnv = null);
    final config = AiRuntimeConfig.resolve();
    expect(config.resolvedProxyUrl, AiRuntimeConfig.androidEmulatorDevProxyUrl);
    expect(config.safeEnvironmentLabel, 'LOCAL');
    expect(config.safeTransportLabel, 'local-proxy');
  });

  test('INTERNAL is pinned to R3.1B HTTPS and ignores endpoint override', () {
    OraclyRuntimeConfig.testEnv = const {
      'APP_ENV': 'internal',
      'ORACLY_AI_PROXY_URL': 'http://10.0.2.2:8787/v1/ai/complete',
    };
    addTearDown(() => OraclyRuntimeConfig.testEnv = null);
    final config = AiRuntimeConfig.resolve();
    expect(config.environment, AppEnvironment.staging);
    expect(config.resolvedProxyUrl, OraclyRuntimeConfig.internalAiProxyUrl);
    expect(config.safeEnvironmentLabel, 'INTERNAL');
    expect(
      config.safeHostLabel,
      'r31b-200bc15b---oracly-api-uya7zqzwra-ew.a.run.app',
    );
    expect(config.safeTransportLabel, 'remote-proxy');
  });

  test('production rejects loopback hosts in resolvedProxyUrl', () {
    const cfg = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: AiRuntimeConfig.localDevProxyUrl,
    );
    expect(cfg.resolvedProxyUrl, isNull);
    expect(cfg.usesProxy, isFalse);
  });

  testWidgets('Home OR opens chat shell without network wall', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: const MediaQuery(
            data: MediaQueryData(size: Size(360, 800)),
            child: HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HomeMasterOr), findsOneWidget);
    await tester.tap(find.byType(HomeMasterOr));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    // Shell mounts; free users see paywall dock, premium users see composer.
    // Either way there is no full-screen offline wall.
    expect(find.textContaining('baglanti yok'), findsNothing);
    expect(OraclyRoutes.chat, '/chat');
  });

  testWidgets('offline strip does not replace composer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CompanionConnectionStrip(
                status: CompanionLinkStatus.offline,
                onRetry: () {},
              ),
              Expanded(
                child: CompanionReferenceInputBar(
                  controller: TextEditingController(),
                  onSend: () {},
                  enabled: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(CompanionCopy.offline), findsOneWidget);
    expect(find.byType(CompanionReferenceInputBar), findsOneWidget);
  });
}
