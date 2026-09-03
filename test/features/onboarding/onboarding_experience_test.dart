/// First-launch: one quiet intro, optional hello, no permissions, persist once.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/features/onboarding/presentation/widgets/onboarding_setup_form.dart';
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
      'OR',
    ]);
    expect(OnboardingCopy.pages, hasLength(1));
  });

  test('birth date is explained only for Sky and Yıldızname', () {
    expect(OnboardingCopy.birthHelp, contains('Gökyüzü'));
    expect(OnboardingCopy.birthHelp, contains('Yıldızname'));
    expect(OnboardingCopy.birthHelp.toLowerCase(), contains('gerekmez'));
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

  testWidgets('intro shows skip and a single continue', (tester) async {
    await _pumpOnboarding(tester);
    expect(find.text('ORACLY'), findsOneWidget);
    expect(find.text(OnboardingCopy.tagline), findsOneWidget);
    for (final label in OnboardingCopy.windows) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text(OnboardingCopy.orHint), findsOneWidget);
    expect(find.text(OnboardingCopy.honesty), findsOneWidget);
    expect(find.text(OnboardingCopy.gemsWhisper), findsOneWidget);
    expect(find.text(OnboardingCopy.skip), findsOneWidget);
    expect(find.text(OnboardingCopy.meetLabel), findsOneWidget);
    expect(find.text(OnboardingCopy.setupTitle), findsNothing);
  });

  testWidgets('setup asks only name, birth, language, style — and skip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingSetupForm(
            language: 'tr',
            style: AiPersonality.mystical,
            onSkip: ({required language, required style}) {},
            onContinue: ({
              required name,
              birthDate,
              required language,
              required style,
              birthPlace,
            }) {},
          ),
        ),
      ),
    );
    expect(find.text(OnboardingCopy.nameLabel), findsOneWidget);
    expect(find.text(OnboardingCopy.birthLabel), findsOneWidget);
    expect(find.text(OnboardingCopy.languageLabel), findsOneWidget);
    expect(find.text(OnboardingCopy.styleLabel), findsOneWidget);
    expect(find.text(OnboardingCopy.birthHelp), findsOneWidget);
    await _scrollToSkip(tester);
    expect(find.text(OnboardingCopy.skip), findsOneWidget);
  });

  testWidgets('meet opens the skippable hello', (tester) async {
    await _pumpOnboarding(tester);
    await tester.tap(find.text(OnboardingCopy.meetLabel));
    await tester.pump();
    expect(find.text(OnboardingCopy.setupTitle), findsOneWidget);
    await _scrollToSkip(tester);
    expect(find.text(OnboardingCopy.skip), findsOneWidget);
  });
}

/// The skip action sits at the end of the setup list — scroll it into view.
Future<void> _scrollToSkip(WidgetTester tester) async {
  final skip = find.text(OnboardingCopy.skip);
  for (var i = 0; i < 6 && skip.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -320));
    await tester.pump();
  }
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
