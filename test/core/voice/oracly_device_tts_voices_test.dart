/// Device TTS voice pick is gendered — not one pitch-shifted default.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/oracly_device_tts_voices.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';

void main() {
  const catalog = [
    {'name': 'tr-tr-x-tfb-local', 'locale': 'tr-TR', 'gender': 'female'},
    {'name': 'tr-tr-x-tmc-local', 'locale': 'tr-TR', 'gender': 'male'},
    {'name': 'pico', 'locale': 'tr-TR'},
  ];

  test('female identity prefers a woman voice', () {
    final picked = OraclyDeviceTtsVoices.choose(
      voices: catalog,
      locale: 'tr-TR',
      identity: OraclyVoiceId.bright,
    );
    expect(picked?['gender'], 'female');
  });

  test('network neural beats local and pico', () {
    final picked = OraclyDeviceTtsVoices.choose(
      voices: const [
        {'name': 'pico', 'locale': 'tr-TR', 'gender': 'female'},
        {'name': 'tr-tr-x-tfb-local', 'locale': 'tr-TR', 'gender': 'female'},
        {'name': 'tr-tr-x-tfb-network', 'locale': 'tr-TR', 'gender': 'female'},
      ],
      locale: 'tr-TR',
      identity: OraclyVoiceId.bright,
    );
    expect(picked?['name'], 'tr-tr-x-tfb-network');
  });
}
