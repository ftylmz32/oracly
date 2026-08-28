/// OR reply TTS gate — settings + SESLİ.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/core/voice/oracly_tts_gate.dart';
import 'package:oracly_new/core/voice/oracly_tts_personality.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTts implements OraclyTtsPort {
  final spoken = <String>[];
  var stopCount = 0;
  var available = true;
  var speaking = false;

  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => speaking;

  @override
  bool get lastSpeakFailed => false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {
    speaking = true;
    spoken.add(text);
    speaking = false;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    speaking = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    OraclyTtsGate.engine = null;
    OraclyTtsGate.voiceRepliesEnabled = false;
    OraclyTtsGate.speaking.value = false;
    OraclyTtsGate.unavailable.value = false;
  });

  test('voice replies default OFF', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final loaded = await LocalSettingsRepository(storage).load();
    expect(loaded.voiceRepliesEnabled, isFalse);
  });

  test('voice replies persist', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = LocalSettingsRepository(storage);
    await repo.save(const PersonalizationSettings(voiceRepliesEnabled: true));
    final loaded = await repo.load();
    expect(loaded.voiceRepliesEnabled, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('settings_voice_replies'),
      isTrue,
    );
  });

  test('OFF and empty never speak', () async {
    final fake = _FakeTts();
    OraclyTtsGate.bind(
      service: fake,
      enabled: false,
      style: AiPersonality.gentle,
      language: 'tr',
    );
    await OraclyTtsGate.speakReply('Merhaba');
    await OraclyTtsGate.speakReply('   ');
    await OraclyTtsGate.speakChat('Sessiz sohbet');
    expect(fake.spoken, isEmpty);

    OraclyTtsGate.voiceRepliesEnabled = true;
    await OraclyTtsGate.speakReply('');
    await OraclyTtsGate.speakReply(null);
    expect(fake.spoken, isEmpty);
  });

  test('ON speaks successful reply and stop interrupts', () async {
    final fake = _FakeTts();
    OraclyTtsGate.bind(
      service: fake,
      enabled: true,
      style: AiPersonality.direct,
      language: 'tr',
    );
    await OraclyTtsGate.speakReply('  OR yanıtı  ');
    expect(fake.spoken, ['OR yanıtı']);
    expect(fake.stopCount, 1); // speakReply stops prior first
    await OraclyTtsGate.stop();
    expect(fake.stopCount, 2);
  });

  test('new reply interrupts prior utterance', () async {
    final fake = _FakeTts();
    OraclyTtsGate.bind(
      service: fake,
      enabled: true,
      style: AiPersonality.poetic,
      language: 'tr',
    );
    await OraclyTtsGate.speakReply('Birinci');
    await OraclyTtsGate.speakReply('İkinci');
    expect(fake.spoken, ['Birinci', 'İkinci']);
    expect(fake.stopCount, 2);
  });

  test('unavailable engine stays silent (text-only fallback)', () async {
    final fake = _FakeTts()..available = false;
    OraclyTtsGate.bind(
      service: fake,
      enabled: true,
      style: AiPersonality.mystical,
      language: 'tr',
    );
    await OraclyTtsGate.speakReply('Görünür metin');
    expect(fake.spoken, isEmpty);
    expect(OraclyTtsGate.unavailable.value, isTrue);
  });

  test('personality rates stay conversational, not metronomic', () {
    expect(OraclyTtsPersonality.rate(AiPersonality.gentle), lessThan(0.55));
    expect(
      OraclyTtsPersonality.rate(AiPersonality.gentle),
      lessThan(OraclyTtsPersonality.rate(AiPersonality.direct)),
    );
    expect(OraclyTtsPersonality.rate(AiPersonality.direct), greaterThan(0.5));
    expect(OraclyTtsPersonality.volume(AiPersonality.mystical), lessThan(0.9));
  });

  test('settingsNotifier binds voice replies from persistence', () async {
    SharedPreferences.setMockInitialValues({
      'settings_voice_replies': true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final fake = _FakeTts();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyTtsProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    expect(OraclyTtsGate.voiceRepliesEnabled, isTrue);
    expect(OraclyTtsGate.engine, same(fake));

    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(voiceRepliesEnabled: false),
        );
    expect(OraclyTtsGate.voiceRepliesEnabled, isFalse);
    await OraclyTtsGate.speakReply('Sessiz');
    expect(fake.spoken, isEmpty);
  });

  test('OR style persist binds TTS personality', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final fake = _FakeTts();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyTtsProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(aiPersonality: AiPersonality.direct),
        );
    expect(OraclyTtsGate.personality, AiPersonality.direct);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('settings_ai_personality'), AiPersonality.direct.index);
  });

  test('OR voice identity persist binds TTS timbre', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final fake = _FakeTts();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyTtsProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(orVoiceId: 'calm'),
        );
    expect(OraclyTtsGate.voice, OraclyVoiceId.calm);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_or_voice'), 'calm');
  });

  test('TTS engine failure never throws into chat', () async {
    OraclyTtsGate.bind(
      service: _ThrowingTts(),
      enabled: true,
      style: AiPersonality.gentle,
      language: 'tr',
    );
    await OraclyTtsGate.speakChat('Selam, bugün nasılsın?');
    expect(OraclyTtsGate.speaking.value, isFalse);
    expect(OraclyTtsGate.unavailable.value, isTrue);
  });

  test('legacy chat output key migrates to voice replies', () async {
    SharedPreferences.setMockInitialValues({
      OrChatOutputMode.storageKey: OrChatOutputMode.voice.name,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final loaded = await LocalSettingsRepository(storage).load();
    expect(loaded.voiceRepliesEnabled, isTrue);
  });
}

class _ThrowingTts implements OraclyTtsPort {
  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => false;

  @override
  bool get lastSpeakFailed => true;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {
    throw StateError('tts');
  }

  @override
  Future<void> stop() async {}
}
