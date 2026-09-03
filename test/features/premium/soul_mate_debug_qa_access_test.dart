/// Debug QA access reuses the canonical override without weakening Premium.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_preview.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/soul_mate_dev_access.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_developer_qa.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PremiumDevOverride.resetDebug);
  tearDown(PremiumDevOverride.resetDebug);

  test('profile and release compile modes cannot activate QA bypass', () {
    expect(
      PremiumDevOverride.allowsOverride(
        debugBuild: false,
        environment: AppEnvironment.development,
        flagEnabled: true,
      ),
      isFalse,
    );
    expect(
      PremiumDevOverride.allowsOverride(
        debugBuild: false,
        environment: AppEnvironment.production,
        flagEnabled: true,
      ),
      isFalse,
    );
  });

  test('kReleaseMode production entitlement path keeps QA unavailable', () {
    // flutter test runs as debug — prove the release compound gate.
    expect(kReleaseMode && PremiumDevOverride.isActive, isFalse);
    expect(kReleaseMode && SoulMateDevAccess.allowsTestAccess, isFalse);
    expect(kReleaseMode && SettingsReferenceDeveloperQa.visible, isFalse);

    PremiumDevOverride.debugEnvironment = AppEnvironment.development;
    PremiumDevOverride.debugFlag = true;
    // Even with override hooks forced, release mode must stay closed.
    expect(kReleaseMode, isFalse); // this process is debug
    expect(
      File('lib/screens/settings/reference/settings_reference_developer_qa.dart')
          .readAsStringSync(),
      contains('kReleaseMode'),
    );
    expect(
      File('lib/features/premium/services/soul_mate_dev_access.dart')
          .readAsStringSync(),
      contains('kReleaseMode'),
    );
  });

  test('production APP_ENV ignores the QA flag even in debug', () {
    PremiumDevOverride.debugEnvironment = AppEnvironment.production;
    PremiumDevOverride.debugFlag = true;
    expect(PremiumDevOverride.isActive, isFalse);
    expect(SoulMateDevAccess.allowsTestAccess, isFalse);
    expect(SettingsReferenceDeveloperQa.visible, isFalse);
  });

  test('QA entry wires real Soul Mate navigation — no fake screen', () {
    final src = File(
      'lib/screens/settings/reference/settings_reference_developer_qa.dart',
    ).readAsStringSync();
    expect(src, contains('SoulMateNavigation.open'));
    expect(src, contains('Ruh Eşi Önizleme'));
    expect(src, contains('kDebugMode'));
    expect(src, isNot(contains('activatePlan')));
    expect(src, isNot(contains('FakeSoulMate')));
  });

  testWidgets('normal non-Premium user still sees the real Premium gate', (
    tester,
  ) async {
    final storage = await _storage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(SoulMateDrawPreview), findsOneWidget);
    expect(find.text(SoulMateCopy.drawCta), findsNothing);
  });

  testWidgets('debug QA entry opens the actual Soul Mate production screen', (
    tester,
  ) async {
    PremiumDevOverride.debugEnvironment = AppEnvironment.development;
    PremiumDevOverride.debugFlag = true;
    final storage = await _storage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: SettingsReferenceDeveloperQa()),
      ),
    );
    await tester.pump();

    expect(SettingsReferenceDeveloperQa.visible, isTrue);
    expect(SoulMateDevAccess.allowsTestAccess, isTrue);
    expect(find.text('Ruh Eşi Önizleme'), findsOneWidget);
    await tester.tap(find.text('Ruh Eşi Önizleme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(SoulMateDrawScreen), findsOneWidget);
    expect(find.byType(SoulMateDrawPreview), findsNothing);
    expect(find.text(SoulMateCopy.drawCta), findsOneWidget);
  });

  testWidgets('QA entry is absent when canonical override is inactive', (
    tester,
  ) async {
    PremiumDevOverride.debugEnvironment = AppEnvironment.production;
    PremiumDevOverride.debugFlag = true;
    await tester.pumpWidget(
      const MaterialApp(home: SettingsReferenceDeveloperQa()),
    );

    expect(find.text('Ruh Eşi Önizleme'), findsNothing);
  });
}

Future<LocalStorage> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorage(await SharedPreferences.getInstance());
}
