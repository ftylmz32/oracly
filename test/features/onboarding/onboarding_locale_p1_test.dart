/// First-launch locale: device for fresh installs; saved language always wins.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/onboarding/data/onboarding_setup_draft.dart';
import 'package:oracly_new/features/onboarding/data/onboarding_setup_draft_store.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/features/onboarding/services/onboarding_language.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AppLocale.debugDeviceLocale = null;
    OraclyL10n.bind(AppLocale.tr);
  });

  void setDevice(Locale locale) {
    AppLocale.debugDeviceLocale = () => locale;
  }

  Future<PersonalizationSettings> loadFresh(Locale device) async {
    setDevice(device);
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    return LocalSettingsRepository(storage).load();
  }

  Widget pumpRoot(LocalStorage storage, void Function(ProviderContainer) grab) {
    return buildProviderScopeHarness(
      storage: storage,
      child: Builder(
        builder: (context) {
          grab(ProviderScope.containerOf(context));
          return Consumer(
            builder: (context, ref, _) {
              final appLocale = ref.watch(appLocaleProvider);
              OraclyL10n.bind(appLocale.languageCode);
              return MaterialApp(
                locale: AppLocale.materialLocale(appLocale.languageCode),
                supportedLocales: const [Locale('en'), Locale('ru')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => OraclyLocaleScope(
                  code: appLocale.languageCode,
                  child: child ?? const SizedBox.shrink(),
                ),
                home: const OnboardingScreen(),
              );
            },
          );
        },
      ),
    );
  }

  test('fresh TR device -> tr', () async {
    final s = await loadFresh(const Locale('tr'));
    expect(s.language, AppLocale.tr);
  });

  test('fresh EN device -> en', () async {
    final s = await loadFresh(const Locale('en', 'US'));
    expect(s.language, AppLocale.en);
  });

  test('fresh RU device -> ru', () async {
    final s = await loadFresh(const Locale('ru'));
    expect(s.language, AppLocale.ru);
  });

  test('unsupported device locale -> tr fallback', () async {
    final s = await loadFresh(const Locale('de'));
    expect(s.language, AppLocale.tr);
    expect(AppLocale.fromDeviceLocale(const Locale('ja')), AppLocale.tr);
  });

  test('saved locale wins over device locale', () async {
    setDevice(const Locale('en'));
    SharedPreferences.setMockInitialValues({'settings_language': 'ru'});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final loaded = await LocalSettingsRepository(storage).load();
    expect(loaded.language, AppLocale.ru);

    setDevice(const Locale('de'));
    final again = await LocalSettingsRepository(storage).load();
    expect(again.language, AppLocale.ru);
  });

  test('AppLocale.resolvePreferred prefers stored over device', () {
    expect(
      AppLocale.resolvePreferred(
        stored: 'en',
        device: const Locale('tr'),
      ),
      AppLocale.en,
    );
    expect(
      AppLocale.resolvePreferred(
        stored: null,
        device: const Locale('ru'),
      ),
      AppLocale.ru,
    );
    expect(
      AppLocale.resolvePreferred(
        stored: '  ',
        device: const Locale('fr'),
      ),
      AppLocale.tr,
    );
  });

  testWidgets('language switch rerenders setup immediately', (tester) async {
    setDevice(const Locale('tr'));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    late ProviderContainer container;

    await tester.pumpWidget(pumpRoot(storage, (c) => container = c));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await container.read(settingsProvider.future);

    await tester.tap(find.text(OnboardingCopy.meetLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text(OraclyL10n.t('onboard.setup_title', languageCode: 'tr')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 800));
    await tester.pump();

    expect(
      find.text(OraclyL10n.t('onboard.setup_title', languageCode: 'en')),
      findsOneWidget,
    );
    expect(container.read(appLocaleProvider).languageCode, AppLocale.en);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), AppLocale.en);
  });

  testWidgets('selected language survives Skip', (tester) async {
    setDevice(const Locale('tr'));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    late ProviderContainer container;

    await tester.pumpWidget(pumpRoot(storage, (c) => container = c));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await container.read(settingsProvider.future);

    await tester.tap(find.text(OnboardingCopy.meetLabel));
    await tester.pump();
    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _scrollToSkip(tester);
    await tester.tap(find.text(OnboardingCopy.skip).last);
    await tester.pump();
    // Skip navigates to shell; prefs must already be committed.
    await tester.pump(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), AppLocale.en);
    expect(container.read(appLocaleProvider).languageCode, AppLocale.en);
  });

  testWidgets('selected language survives interrupted-onboarding restart',
      (tester) async {
    setDevice(const Locale('tr'));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await OnboardingSetupDraftStore(storage).save(
      const OnboardingSetupDraft(
        updatedAtMillis: 1,
        language: AppLocale.ru,
        style: AiPersonality.gentle,
      ),
    );

    late ProviderContainer container;
    await tester.pumpWidget(pumpRoot(storage, (c) => container = c));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await container.read(settingsProvider.future);
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(OraclyL10n.t('onboard.setup_title', languageCode: 'ru')),
      findsOneWidget,
    );
    expect(container.read(appLocaleProvider).languageCode, AppLocale.ru);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), AppLocale.ru);
  });

  testWidgets('selected language survives Continue', (tester) async {
    setDevice(const Locale('tr'));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    late ProviderContainer container;

    await tester.pumpWidget(pumpRoot(storage, (c) => container = c));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await container.read(settingsProvider.future);

    await tester.tap(find.text(OnboardingCopy.meetLabel));
    await tester.pump();
    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final continueLabel =
        OraclyL10n.t('onboard.start', languageCode: AppLocale.en);
    await tester.ensureVisible(find.text(continueLabel));
    await tester.tap(find.text(continueLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), AppLocale.en);
    expect(container.read(appLocaleProvider).languageCode, AppLocale.en);
  });

  testWidgets('intro Skip persists device language', (tester) async {
    setDevice(const Locale('en', 'US'));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    late ProviderContainer container;

    await tester.pumpWidget(pumpRoot(storage, (c) => container = c));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await container.read(settingsProvider.future);

    await tester.tap(find.text(OnboardingCopy.skip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), AppLocale.en);
    expect(container.read(appLocaleProvider).languageCode, AppLocale.en);
  });

  test('Material chrome locale follows selected language', () {
    expect(AppLocale.materialLocale(AppLocale.en), const Locale('en'));
    expect(AppLocale.materialLocale(AppLocale.ru), const Locale('ru'));
    // Flutter has no tr Material strings — chrome uses en, copy stays tr.
    expect(AppLocale.materialLocale(AppLocale.tr), const Locale('en'));
  });

  test('draft language wins over unresolved settings when nothing stored', () {
    AppLocale.debugDeviceLocale = () => const Locale('tr');
    final storage = LocalStorage.ephemeral();
    final code = OnboardingLanguage.resolve(
      storage: storage,
      draft: const OnboardingSetupDraft(
        updatedAtMillis: 1,
        language: AppLocale.ru,
        style: AiPersonality.gentle,
      ),
      settings: const PersonalizationSettings(language: AppLocale.tr),
    );
    expect(code, AppLocale.ru);
  });
}

Future<void> _scrollToSkip(WidgetTester tester) async {
  final skip = find.text(OnboardingCopy.skip);
  for (var i = 0; i < 8 && skip.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -320));
    await tester.pump();
  }
}