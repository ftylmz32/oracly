/// OR voice selection — four expressions, real preview, persisted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/core/voice/oracly_tts_gate.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_copy.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late RecordingTts tts;

  setUp(() async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    storage = LocalStorage(await SharedPreferences.getInstance());
    tts = RecordingTts();
    OraclyL10n.bind('tr');
  });

  tearDown(() {
    OraclyTtsGate.engine = null;
    OraclyTtsGate.speaking.value = false;
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclyTtsProvider.overrideWithValue(tts),
          oraclySoundServiceProvider.overrideWithValue(SilentSound()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ref.watch(appThemeModeProvider),
              home: const SettingsReferenceScreen(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('four OR voice expressions are offered with a listen control', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text('SICAK'), findsOneWidget);
    expect(find.text('SAKİN'), findsOneWidget);
    expect(find.text('PARLAK'), findsOneWidget);
    expect(find.text('YAVAŞ'), findsOneWidget);
    expect(find.text('NORMAL'), findsOneWidget);
    expect(find.text('HIZLI'), findsOneWidget);
    expect(find.byKey(const ValueKey('or-voice-deep')), findsOneWidget);
    expect(
      find.text('Aynı OR. Dört ifade — dört karakter değil.'),
      findsOneWidget,
    );
    expect(
      find.text('OR’ın sıcak ifadesi — yakın ve açık.'),
      findsOneWidget,
    );
    expect(
      find.text('OR’ın derin ifadesi — alçak ve dengeli.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('or-voice-preview-calm')), findsOneWidget);
  });

  testWidgets('preview speaks the greeting with that identity, not a ding', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('or-voice-deep')));
    await tester.tap(find.byKey(const ValueKey('or-voice-preview-deep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tts.spoken, ['Selam. Buradayım. Şimdi nasılsın?']);
    expect(tts.voices, [OraclyVoiceId.deep]);
    expect(
      OraclyVoiceCopy.previewPhrase('tr'),
      'Selam. Buradayım. Şimdi nasılsın?',
    );
  });

  testWidgets('selected voice persists without changing OR style', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ...settingsTestLanguagePrefs,
      'settings_ai_personality': AiPersonality.direct.index,
    });
    storage = LocalStorage(await SharedPreferences.getInstance());
    await pumpSettings(tester);
    expect(OraclyTtsGate.personality, AiPersonality.direct);

    await tester.ensureVisible(find.text('SAKİN'));
    await tester.tap(find.text('SAKİN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_or_voice'), 'calm');
    expect(prefs.getInt('settings_ai_personality'), AiPersonality.direct.index);
    expect(OraclyTtsGate.voice, OraclyVoiceId.calm);
    expect(OraclyTtsGate.personality, AiPersonality.direct);
  });

  testWidgets('speech speed preference persists', (tester) async {
    await pumpSettings(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('or-speech-speed-fast')));
    await tester.tap(find.byKey(const ValueKey('or-speech-speed-fast')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_or_speech_speed'), 'fast');
    expect(OraclyTtsGate.speechSpeed, OrSpeechSpeed.fast);
  });

  testWidgets('legacy gendered voice ids migrate to expressions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ...settingsTestLanguagePrefs,
      'settings_or_voice': 'male_calm',
    });
    storage = LocalStorage(await SharedPreferences.getInstance());
    await pumpSettings(tester);
    expect(OraclyTtsGate.voice, OraclyVoiceId.calm);
    expect(find.text('SAKİN'), findsOneWidget);
  });
}
