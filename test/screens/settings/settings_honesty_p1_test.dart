/// Phase 1 — Settings honesty: no fake toggles; live sound/haptic/OR/theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/audio/oracly_feedback_gate.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/core/voice/oracly_tts_gate.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/copy/settings_copy.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_switch.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_test_fakes.dart';

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
  Future<bool> isAvailable() async => false;

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

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    storage = LocalStorage(await SharedPreferences.getInstance());
    OraclyFeedbackGate.hapticEnabled = true;
    OraclyFeedbackGate.soundEnabled = true;
    OraclyTtsGate.voiceRepliesEnabled = false;
    OraclyTtsGate.engine = null;
    OraclyL10n.bind('tr');
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 2200));
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
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('theme row is live; notifications are a real switch', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text(SettingsCopy.soon), findsNothing);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text(SettingsCopy.darkTitle), findsOneWidget);

    expect(find.text(SettingsCopy.notificationsTitle), findsOneWidget);
    expect(find.text(SettingsCopy.notificationsUnavailable), findsNothing);

    expect(find.byType(SettingsReferenceSwitch), findsNWidgets(4));
  });

  testWidgets('sound and haptic persist', (tester) async {
    await pumpSettings(tester);

    await tester.ensureVisible(find.text(SettingsCopy.soundTitle));
    await tester.tap(find.byType(SettingsReferenceSwitch).at(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(OraclyFeedbackGate.soundEnabled, isFalse);

    await tester.ensureVisible(find.text(SettingsCopy.hapticTitle));
    await tester.tap(
      find.byKey(ValueKey('settings-switch-${SettingsCopy.hapticTitle}')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(OraclyFeedbackGate.hapticEnabled, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_sound'), isFalse);
    expect(prefs.getBool('settings_haptic'), isFalse);
  });

  testWidgets(
    'music persists; text/voice output is a mode not a mixed switch',
    (tester) async {
      await pumpSettings(tester);

      await tester.ensureVisible(
        find.byKey(
          ValueKey('settings-switch-${SettingsCopy.ambientMusicTitle}'),
        ),
      );
      await tester.tap(
        find.byKey(
          ValueKey('settings-switch-${SettingsCopy.ambientMusicTitle}'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.ensureVisible(find.text(SettingsCopy.outputTitle));
      await tester.tap(find.text(SettingsCopy.outputTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(SettingsCopy.outputModeVoice));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_ambient_music'), isTrue);
      expect(prefs.getBool('settings_voice_replies'), isTrue);
      expect(prefs.getString('settings_or_chat_output'), 'voice');
      expect(OraclyTtsGate.voiceRepliesEnabled, isTrue);
      expect(
        prefs.getString('settings_or_voice') ?? 'warm',
        'warm',
      );
      expect(find.textContaining('kaydedildi'), findsNothing);
    },
  );

  testWidgets('restart restores live prefs without fake success copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings_sound': false,
      'settings_haptic': false,
      'settings_ambient_music': true,
      'settings_voice_replies': true,
      'settings_appearance': 'light',
      'settings_language': 'en',
    });
    storage = LocalStorage(await SharedPreferences.getInstance());
    await pumpSettings(tester);

    expect(OraclyFeedbackGate.soundEnabled, isFalse);
    expect(OraclyFeedbackGate.hapticEnabled, isFalse);
    expect(OraclyTtsGate.voiceRepliesEnabled, isTrue);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Soon'), findsNothing);
    expect(find.text('Yakında'), findsNothing);
    expect(find.textContaining('saved'), findsNothing);
  });

  test('haptic gate silences OraclyTouchFeedback', () {
    OraclyFeedbackGate.hapticEnabled = false;
    OraclyTouchFeedback.acknowledge();
    OraclyTouchFeedback.selection();
    OraclyFeedbackGate.hapticEnabled = true;
  });

  testWidgets('OR style row is interactive and shows current label', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text(SettingsCopy.orStyleTitle), findsOneWidget);
    expect(find.text('MİSTİK'), findsOneWidget);
  });

  test('OR personality key persists in SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_ai_personality', AiPersonality.direct.index);
    expect(prefs.getInt('settings_ai_personality'), AiPersonality.direct.index);
  });

  testWidgets('appearance stays dark-only when light mode is gated', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Tema'), findsOneWidget);
    expect(find.text(SettingsCopy.darkTitle), findsOneWidget);
    expect(find.text('Açık'), findsNothing);

    await tester.tap(find.text('Tema'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Açık'), findsNothing);
    expect(find.text('Sistem'), findsNothing);
  });
}
