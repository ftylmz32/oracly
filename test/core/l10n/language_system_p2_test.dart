/// Phase 2 — Language system: tr/en tables, persistence, locale resolve.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/universe/oracly_tab_labels.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppLocale normalizes legacy display labels', () {
    expect(AppLocale.normalize('Türkçe'), AppLocale.tr);
    expect(AppLocale.normalize('English'), AppLocale.en);
    expect(AppLocale.normalize('Русский'), AppLocale.ru);
    expect(AppLocale.normalize('en'), AppLocale.en);
    expect(AppLocale.normalize(null), AppLocale.tr);
    expect(AppLocale.displayName('en'), 'English');
    expect(AppLocale.displayName('tr'), 'Türkçe');
    expect(AppLocale.displayName('ru'), 'Русский');
  });

  test('OraclyL10n resolves each language from its own table', () {
    expect(
      OraclyL10n.t(L10nKeys.settingsTitle, languageCode: 'tr'),
      'AYARLAR',
    );
    expect(
      OraclyL10n.t(L10nKeys.settingsTitle, languageCode: 'en'),
      'SETTINGS',
    );
    expect(
      OraclyL10n.t(L10nKeys.home, languageCode: 'en'),
      'Home',
    );
    expect(
      OraclyL10n.t(L10nKeys.coffee, languageCode: 'tr'),
      'Kahve',
    );
    expect(
      OraclyL10n.t('settings.not_a_real_key', languageCode: 'en'),
      'settings.not_a_real_key',
    );
  });

  test('tab labels follow language code', () {
    expect(OraclyTab.home.labeled('en'), 'Home');
    expect(OraclyTab.starMap.labeled('tr'), 'Günlük');
    expect(OraclyTab.coffee.labeled('en'), 'OR');
    expect(OraclyTab.astrology.labeled('en'), 'Explore');
    expect(OraclyTab.starMap.labeled('en'), 'Journal');
  });

  test('language persists as tr/en/ru across repository reload', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = LocalSettingsRepository(storage);

    await repo.save(const PersonalizationSettings(language: 'English'));
    final loaded = await repo.load();
    expect(loaded.language, AppLocale.en);

    await repo.save(loaded.copyWith(language: 'tr'));
    final again = await repo.load();
    expect(again.language, AppLocale.tr);

    await repo.save(again.copyWith(language: 'ru'));
    final russian = await repo.load();
    expect(russian.language, AppLocale.ru);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), 'ru');
  });

  testWidgets('MaterialApp locale can be English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: AppLocale.toLocale('en'),
        supportedLocales: AppLocale.supportedLocales,
        home: Builder(
          builder: (context) {
            final code = Localizations.localeOf(context).languageCode;
            return Text(OraclyL10n.t(L10nKeys.language, languageCode: code));
          },
        ),
      ),
    );
    expect(find.text('Language'), findsOneWidget);
  });
}
