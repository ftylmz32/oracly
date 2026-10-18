/// First-launch: one quiet intro, optional hello, no permissions, persist once.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/onboarding/data/onboarding_setup_draft.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    AppLocale.debugDeviceLocale = () => const Locale('tr');
  });

  tearDown(() => AppLocale.debugDeviceLocale = null);

  test('intro names ORACLY, one line, six windows', () {
    expect(OnboardingCopy.title, 'ORACLY');
    expect(
      OnboardingCopy.tagline,
      'Kendini farklı pencerelerden keşfet.',
    );
    expect(OnboardingCopy.windows, [
      'Kahve',
      'El',
      'Gökyüzü',
      'Yıldızname',
      'Tarot',
      'Luna',
    ]);
    expect(OnboardingCopy.pages, hasLength(1));
  });

  test('birth date is explained only for Sky and Yıldızname', () {
    expect(OnboardingCopy.birthHelp, contains('Gökyüzü'));
    expect(OnboardingCopy.birthHelp, contains('Yıldızname'));
    expect(OnboardingCopy.birthHelp.toLowerCase(), contains('gerekmez'));
  });

  test('unknown birth time is stored as unknown, never a guessed hour', () {
    const draft = OnboardingSetupDraft(
      updatedAtMillis: 1,
      language: 'tr',
      style: AiPersonality.mystical,
    );
    expect(draft.birthTimeKnown, isFalse);
    expect(draft.birthTime, isNull);
    final restored = OnboardingSetupDraft.fromJson({
      'updatedAtMillis': 1,
      'language': 'tr',
      'style': 'mystical',
      'name': 'Deniz',
      'birthTimeKnown': false,
      'birthHour': 12,
    });
    expect(restored.birthTime, isNull);
    expect(restored.scene, 1);
  });

  test('first launch is incomplete; later launch stays complete', () async {
    SharedPreferences.setMockInitialValues({});
    final first = LocalOnboardingRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    expect(await first.isCompleted(), isFalse);
    await first.markCompleted();

    final later = LocalOnboardingRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    expect(await later.isCompleted(), isTrue);
  });

  test('onboarding never asks camera, gallery, or microphone', () {
    final dir = Directory('lib/features/onboarding');
    final dart = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in dart) {
      final source = file.readAsStringSync().toLowerCase();
      expect(source, isNot(contains('permission.')), reason: file.path);
      expect(source, isNot(contains('permission_handler')), reason: file.path);
      expect(source, isNot(contains('microphone')), reason: file.path);
    }
  });

  test('splash shows onboarding once, then the app shell', () {
    final splash = File(
      'lib/screens/splash/splash_screen.dart',
    ).readAsStringSync();
    final dest = File(
      'lib/screens/splash/splash_destination.dart',
    ).readAsStringSync();
    expect(splash, contains('LocalOnboardingRepository.completedKey'));
    expect(dest, contains('OnboardingScreen'));
    expect(dest, contains('OraclyAppShell'));
    expect(splash.toLowerCase(), isNot(contains('permission.camera')));
    expect(splash.toLowerCase(), isNot(contains('permission.microphone')));
  });

  testWidgets('intro shows the gate, not a survey', (tester) async {
    await _pumpOnboarding(tester);
    expect(find.text(OnboardingCopy.gateTitle), findsOneWidget);
    expect(find.text(OnboardingCopy.gateSubtitle), findsOneWidget);
    expect(find.text(OnboardingCopy.meetLabel), findsOneWidget);
    expect(find.text(OnboardingCopy.exploreLabel), findsOneWidget);
    expect(find.text(OnboardingCopy.styleLabel), findsNothing);
    expect(find.text(OnboardingCopy.setupTitle), findsNothing);
  });

  testWidgets('meet opens the name scene without a Luna voice choice', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await tester.tap(find.text(OnboardingCopy.meetLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(OnboardingCopy.nameTitle), findsOneWidget);
    expect(find.text(OnboardingCopy.styleLabel), findsNothing);
    expect(find.text(OnboardingCopy.passLabel), findsOneWidget);
  });
}

Future<void> _pumpOnboarding(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: const MaterialApp(home: OnboardingScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
