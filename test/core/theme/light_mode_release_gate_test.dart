/// Light mode release gate — Dark-only v1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/oracly_app.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/theme/app_appearance.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v1 appearance gate is Dark-only with reversible architecture', () {
    expect(AppAppearanceModeX.lightModeUserSelectable, isFalse);
    expect(AppAppearanceModeX.productionThemeMode, ThemeMode.dark);
    expect(AppTheme.light, isA<ThemeData>());
    expect(AppTheme.dark, isA<ThemeData>());
  });

  testWidgets('OraclyApp boots with ThemeMode.dark even when prefs ask for light',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_appearance': 'light',
      'settings_language': 'tr',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const OraclyApp();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(appThemeModeProvider), ThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}