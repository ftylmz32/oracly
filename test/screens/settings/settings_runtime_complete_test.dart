/// Settings runtime — language, output vs voice identity, persistence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/theme/app_appearance.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/oracly_voice_copy.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/copy/settings_copy.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentSound extends OraclySoundService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> ensureSfxReady() async {}

  @override
  Future<void> syncAmbientEnabled(bool enabled) async {}

  @override
  Future<void> setAtmosphere(ZodiacSignId sign) async {}
}

class _SilentTts implements OraclyTtsPort {
  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => false;

  @override
  bool get lastSpeakFailed => false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind(AppLocale.tr));
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  Future<void> pump({
    required WidgetTester tester,
    required LocalStorage storage,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclyTtsProvider.overrideWithValue(_SilentTts()),
          oraclySoundServiceProvider.overrideWithValue(_SilentSound()),
          oraclyNotificationPortProvider.overrideWithValue(
            MemoryNotificationPort(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(appThemeModeProvider);
            final locale = ref.watch(appLocaleProvider);
            OraclyL10n.bind(locale.languageCode);
            return MaterialApp(
              locale: locale,
              supportedLocales: AppLocale.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
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
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('picker offers Türkçe, English, and Русский', () {
    expect(AppLocale.pickerOptions, AppLocale.displayOptions);
    expect(AppLocale.pickerOptions.map((e) => e.$1), [
      AppLocale.tr,
      AppLocale.en,
      AppLocale.ru,
    ]);
  });

  test('OR voice copy is complete in Russian — not English fallback', () {
    expect(OraclyVoiceCopy.sectionTitle('ru'), 'Голос OR');
    expect(
      OraclyVoiceCopy.title(OraclyVoiceId.warm, 'ru').toLowerCase(),
      contains('тёпл'),
    );
    expect(OraclyVoiceCopy.previewPhrase('ru'), isNot(contains('Hello')));
    expect(OraclyVoiceCopy.previewPhrase('ru'), isNot(contains('Selam')));
  });

  testWidgets('Russian selection changes visible Settings chrome', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    await pump(tester: tester, storage: storage);

    await tester.ensureVisible(find.text(SettingsCopy.languageTitle));
    await tester.tap(find.text(SettingsCopy.languageTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Русский'), findsWidgets);
    await tester.tap(find.text('Русский').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('НАСТРОЙКИ'), findsOneWidget);
    expect(find.text('AYARLAR'), findsNothing);
    expect(find.text('SETTINGS'), findsNothing);
    expect(find.text('Голос OR'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_language'), AppLocale.ru);
  });

  testWidgets('restart restores Russian without mixed chrome', (tester) async {
    SharedPreferences.setMockInitialValues({'settings_language': 'ru'});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    await pump(tester: tester, storage: storage);
    expect(find.text('НАСТРОЙКИ'), findsOneWidget);
    expect(find.text('AYARLAR'), findsNothing);
    expect(find.text('SETTINGS'), findsNothing);
    expect(find.text('Soon'), findsNothing);
    expect(find.text('STANDART'), findsNothing);
    expect(find.text('СТАНДАРТ'), findsOneWidget);
    expect(find.byType(SettingsReferenceSwitch), findsNWidgets(4));
  });

  testWidgets('English restart has no Turkish leftovers', (tester) async {
    SharedPreferences.setMockInitialValues({'settings_language': 'en'});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    await pump(tester: tester, storage: storage);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('AYARLAR'), findsNothing);
    expect(find.text('STANDART'), findsNothing);
    expect(find.text('Yolcu'), findsNothing);
    expect(find.text('STANDARD'), findsOneWidget);
    expect(find.text('Traveler'), findsOneWidget);
    expect(find.text(SettingsCopy.notificationsUnavailable), findsNothing);
    expect(find.text(SettingsCopy.soon), findsNothing);
  });

  test('runtime themes are only dark, light, and system', () {
    expect(AppAppearanceMode.values, [
      AppAppearanceMode.dark,
      AppAppearanceMode.light,
      AppAppearanceMode.system,
    ]);
  });
}
