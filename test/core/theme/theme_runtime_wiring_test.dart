/// Theme runtime wiring — settings_appearance → MaterialApp themeMode.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/oracly_light_sanctuary_background.dart';
import 'package:oracly_new/core/theme/app_appearance.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('persisted light appearance applies on cold start', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_appearance': 'light',
      'settings_dark': false,
    });
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
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(appThemeModeProvider), ThemeMode.light);
    expect(find.byType(OraclyLightSanctuaryBackground), findsWidgets);
    expect(find.text('Açık'), findsOneWidget);
  });

  testWidgets('system appearance maps to ThemeMode.system', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
            appearanceMode: AppAppearanceMode.system,
          ),
        );
    expect(container.read(appThemeModeProvider), ThemeMode.system);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_appearance'), 'system');
  });

  testWidgets('system appearance follows OS brightness at runtime',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_appearance': 'system',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    addTearDown(() {
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;

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

    expect(find.text('dark'), findsOneWidget);

    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('light'), findsOneWidget);
  });

  testWidgets('picking Açık in Settings updates Material brightness',
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
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Tema'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Açık').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(appThemeModeProvider), ThemeMode.light);
    expect(Theme.of(tester.element(find.text('Tema'))).brightness,
        Brightness.light);
    expect(find.byType(OraclyLightSanctuaryBackground), findsWidgets);
    expect(
      (await SharedPreferences.getInstance()).getString('settings_appearance'),
      'light',
    );
  });

  test('legacy settings_dark migrates when appearance key missing', () async {
    SharedPreferences.setMockInitialValues({'settings_dark': false});
    final storage = LocalStorage(await SharedPreferences.getInstance());

    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final settings = await container.read(settingsServiceProvider).load();
    expect(settings.appearanceMode, AppAppearanceMode.light);
  });
}
