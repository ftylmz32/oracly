/// Clean install — empty prefs, no dotenv, bundled assets, routes, defaults.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_config.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/config/environment_config.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    AppLocale.debugDeviceLocale = () => const Locale('tr');
    AppConfig.reset();
  });

  tearDown(() => AppLocale.debugDeviceLocale = null);

  test('release-safe AppConfig boots without prior dotenv.load', () async {
    await AppConfig.initialize();
    expect(AppConfig.isInitialized, isTrue);
    expect(AppConfig.instance.apiBaseUrl, isNotEmpty);
    expect(AppConfig.instance.environment, isA<AppEnvironment>());
  });

  test('EnvironmentConfig.fromEnv tolerates empty and missing dotenv', () {
    final empty = EnvironmentConfig.fromEnv(const {});
    expect(empty.apiBaseUrl, isNotEmpty);
    final cold = EnvironmentConfig.fromEnv();
    expect(cold.apiBaseUrl, isNotEmpty);
  });

  test('empty prefs: onboarding incomplete, language from device, dark default',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final onboarding = LocalOnboardingRepository(storage);
    final settings = await LocalSettingsRepository(storage).load();
    final expected = AppLocale.fromDeviceLocale(AppLocale.readDeviceLocale());

    expect(await onboarding.isCompleted(), isFalse);
    expect(settings.language, expected);
    expect(AppLocale.productionCodes, ['tr', 'en', 'ru']);
    expect(settings.darkAppearance, isTrue);
    expect(settings.notificationsEnabled, isFalse);
  });

  test('AI runtime resolves without dotenv — no crash', () {
    final cfg = AiRuntimeConfig.resolve();
    expect(cfg.environment, isA<AppEnvironment>());
  });

  test('feature routes resolve without seed history', () {
    const routes = [
      OraclyRoutes.home,
      OraclyRoutes.tarot,
      OraclyRoutes.chat,
      OraclyRoutes.coffee,
      OraclyRoutes.palm,
      OraclyRoutes.dream,
      OraclyRoutes.astrology,
      OraclyRoutes.starMap,
      OraclyRoutes.profile,
      OraclyRoutes.settings,
      OraclyRoutes.gems,
      OraclyRoutes.readingHistory,
      OraclyRoutes.discoveryJournal,
      OraclyRoutes.privacy,
      OraclyRoutes.onboarding,
    ];
    for (final name in routes) {
      final route = OraclyRouteGenerator.onGenerateRoute(
        RouteSettings(name: name),
      );
      expect(route, isNotNull, reason: name);
    }
  });

  test('bundled tarot + home assets exist on disk (no machine-local deps)', () {
    expect(File('.env.example').existsSync(), isTrue);
    expect(Directory('lib/assets/images/home').existsSync(), isTrue);
    expect(
      Directory('lib/assets/images/tarot/major_arcana')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.webp'))
          .length,
      22,
    );
    for (final suit in ['cups', 'pentacles', 'swords', 'wands']) {
      final full = Directory('lib/assets/images/tarot/minor_arcana/$suit')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.webp'))
          .length;
      final thumbs = Directory(
        'lib/assets/images/tarot/thumbs/minor_arcana/$suit',
      )
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.webp'))
          .length;
      expect(full, 14, reason: suit);
      expect(thumbs, 14, reason: 'thumbs/$suit');
    }
    expect(
      Directory('lib/assets/images/tarot/thumbs/major_arcana')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.webp'))
          .length,
      22,
    );

    final dartTree = Directory('lib');
    for (final file in dartTree.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final src = file.readAsStringSync();
      expect(src, isNot(contains(r'C:\Users')), reason: file.path);
      expect(src, isNot(contains('/Users/FAT')), reason: file.path);
    }
  });

  testWidgets('clean prefs: first screen is onboarding, no permission prompts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    expect(await LocalOnboardingRepository(storage).isCompleted(), isFalse);

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ORACLY'), findsOneWidget);
    expect(find.text(OnboardingCopy.skip), findsOneWidget);
    expect(find.text(OnboardingCopy.meetLabel), findsOneWidget);
    expect(find.textContaining('İzin'), findsNothing);
    expect(find.textContaining('Permission'), findsNothing);

    await LocalOnboardingRepository(storage).markCompleted();
    expect(await LocalOnboardingRepository(storage).isCompleted(), isTrue);
  });
}
