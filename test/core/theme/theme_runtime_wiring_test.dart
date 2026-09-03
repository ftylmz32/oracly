/// Theme runtime — production v1 forces Dark; Light architecture retained.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_appearance.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production gate keeps Light architecture but forces Dark ThemeMode', () {
    expect(AppAppearanceModeX.lightModeUserSelectable, isFalse);
    expect(AppAppearanceModeX.productionThemeMode, ThemeMode.dark);
    expect(
      AppAppearanceModeX.coerceForProduction(AppAppearanceMode.light),
      AppAppearanceMode.dark,
    );
    expect(
      AppAppearanceModeX.coerceForProduction(AppAppearanceMode.system),
      AppAppearanceMode.dark,
    );
    expect(AppAppearanceMode.light.themeMode, ThemeMode.light);
    expect(AppAppearanceMode.system.themeMode, ThemeMode.system);
  });

  testWidgets('persisted light cannot make the app light', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_appearance': 'light',
      'settings_dark': false,
      'settings_language': 'tr',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    OraclyL10n.bind('tr');

    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final mode = ref.watch(appThemeModeProvider);
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: const SettingsReferenceScreen(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(container.read(appThemeModeProvider), ThemeMode.dark);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Koyu'), findsOneWidget);
    expect(find.text('Açık'), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getString('settings_appearance'),
      'dark',
    );
  });

  testWidgets('persisted system cannot make the app light', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_appearance': 'system',
      'settings_language': 'tr',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    addTearDown(() {
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
    });
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final mode = ref.watch(appThemeModeProvider);
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: Builder(
                builder: (context) => Text(
                  Theme.of(context).brightness.name,
                  key: const Key('brightness'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(appThemeModeProvider), ThemeMode.dark);
    expect(find.text('dark'), findsOneWidget);
  });

  testWidgets('Settings does not offer Light/System selector', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_language': 'tr',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    OraclyL10n.bind('tr');

    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(appThemeModeProvider);
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: const SettingsReferenceScreen(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Koyu'), findsOneWidget);
    await tester.tap(find.text('Tema'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Açık'), findsNothing);
    expect(find.text('Sistem'), findsNothing);
  });

  testWidgets('saving light via API still resolves dark ThemeMode',
      (tester) async {
    SharedPreferences.setMockInitialValues({'settings_language': 'tr'});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(
            appearanceMode: AppAppearanceMode.light,
          ),
        );
    expect(container.read(appThemeModeProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_appearance'), 'dark');
  });

  test('legacy settings_dark=false migrates to dark for v1', () async {
    SharedPreferences.setMockInitialValues({'settings_dark': false});
    final storage = LocalStorage(await SharedPreferences.getInstance());

    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final settings = await container.read(settingsServiceProvider).load();
    expect(settings.appearanceMode, AppAppearanceMode.dark);
    expect(container.read(appThemeModeProvider), ThemeMode.dark);
  });
}