/// OR speech tempo stays natural; fast stays intelligible.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/features/ai/production/openai/openai_tts_request.dart';
import 'package:oracly_new/features/ai/production/openai/openai_tts_voices.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fast proxy speed stays within an intelligible band', () {
    for (final personality in ['gentle', 'mystical', 'poetic', 'direct']) {
      final voice = OpenAiTtsVoices.resolve(
        personality: personality,
        language: 'tr',
        voiceId: 'warm',
        speechSpeed: 'fast',
      );
      expect(voice.speed, lessThanOrEqualTo(1.15));
      expect(voice.speed, greaterThan(1.0));
      expect(voice.hdSpeed, voice.speed);
    }
    expect(OrSpeechSpeed.fast.applyProxy(1.02), lessThanOrEqualTo(1.15));
    expect(OrSpeechSpeed.slow.applyProxy(0.98), greaterThanOrEqualTo(0.85));
  });

  test('device rates stay conversational after tempo', () {
    expect(OrSpeechSpeed.fast.applyDevice(0.53), lessThanOrEqualTo(0.62));
    expect(OrSpeechSpeed.slow.applyDevice(0.48), greaterThanOrEqualTo(0.28));
    expect(OrSpeechSpeed.normal.applyDevice(0.50), closeTo(0.50, 0.001));
  });

  test('speech speed preference persists as normal by default', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalSettingsRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final loaded = await repo.load();
    expect(loaded.orSpeechSpeed, OrSpeechSpeed.normal);
    await repo.save(loaded.copyWith(orSpeechSpeed: OrSpeechSpeed.fast));
    final again = await repo.load();
    expect(again.orSpeechSpeed, OrSpeechSpeed.fast);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_or_speech_speed'), 'fast');
  });

  test('TTS payload includes speechSpeed without provider voice names', () {
    final request = OpenAiTtsRequest.create(
      text: 'selam',
      personality: 'gentle',
      speechSpeed: 'fast',
    );
    expect(request.payload['speechSpeed'], 'fast');
    expect(request.payload['voiceId'], 'warm');
    expect(request.payload.containsKey('voice'), isFalse);
  });
}
