/// Runtime language wiring — provider → Settings + bottom nav (OraclyL10n).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/universe/oracly_tab_labels.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLocale.debugDeviceLocale = () => const Locale('tr');
    OraclyL10n.bind(AppLocale.tr);
  });
  tearDown(() => AppLocale.debugDeviceLocale = null);

  testWidgets('saving English updates appLocaleProvider and Settings title',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());

    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            // Watch so this tree rebuilds when language changes.
            final locale = ref.watch(appLocaleProvider);
            OraclyL10n.bind(locale.languageCode);
            return MaterialApp(
              locale: AppLocale.materialLocale(locale.languageCode),
              supportedLocales: const [Locale('en'), Locale('ru')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => OraclyLocaleScope(
                code: locale.languageCode,
                child: child ?? const SizedBox.shrink(),
              ),
              home: const SettingsReferenceScreen(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AYARLAR'), findsOneWidget);

    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(language: 'en'),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(appLocaleProvider).languageCode, 'en');
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
    // OR output is a three-way mode (text / voice replies / conversation),
    // not the legacy binary "Text / Voice" switch label.
    expect(find.text('OR reply mode'), findsOneWidget);
    expect(find.text('Speaking style'), findsOneWidget);
    expect(find.text('Atmospheric music'), findsOneWidget);
    expect(find.text('Atmosphere'), findsOneWidget);
    expect(find.text('Manage your profile.'), findsOneWidget);
    expect(find.text('Explore Premium access'), findsOneWidget);
    expect(find.text('Cancer'), findsOneWidget);
    expect(find.text('MYSTIC'), findsOneWidget);
    expect(find.text('Soon'), findsNothing);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), 'en');
  });

  testWidgets('bottom nav labels follow appLocaleProvider', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_language': 'en',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(appLocaleProvider);
            return MaterialApp(
              locale: const Locale('en'),
              supportedLocales: const [Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(
                body: const SizedBox.shrink(),
                bottomNavigationBar: OraclyBottomBar(
                  currentIndex: 0,
                  onDestinationSelected: (_) {},
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('OR'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  test('English tab labels match product copy', () {
    expect(OraclyTab.home.labeled('en'), 'Home');
    expect(OraclyTab.coffee.labeled('en'), 'OR');
    expect(OraclyTab.astrology.labeled('en'), 'Explore');
    expect(OraclyTab.starMap.labeled('en'), 'Journal');
    expect(OraclyTab.profile.labeled('en'), 'Profile');
    expect(
      OraclyL10n.t(L10nKeys.sectionLanguage, languageCode: 'en'),
      'LANGUAGE',
    );
  });
}
