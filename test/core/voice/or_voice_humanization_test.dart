/// Original OR voices — not celebrity clones, not phone TTS.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/ai/production/openai/openai_tts_voices.dart';

void main() {
  test('four identities stay original and distinct', () {
    final styles = {
      for (final id in OraclyVoiceId.values)
        id: OpenAiTtsVoices.resolve(
          personality: 'mystical',
          language: 'tr',
          voiceId: id.wire,
        ),
    };
    expect(styles.length, 4);
    expect(styles.values.map((s) => s.voice).toSet().length, 4);
    expect(styles.values.map((s) => s.instructions).toSet().length, 4);
    for (final style in styles.values) {
      final text = style.instructions.toLowerCase();
      expect(text, contains('one presence'));
      expect(text, contains('original'));
      expect(text, contains('never imitate'));
      expect(style.instructions, contains('phone TTS'));
      expect(style.instructions, contains('ulama'));
      expect(style.instructions, contains('nasılsın'));
      expect(style.instructions, contains('metronome'));
      expect(style.instructions, isNot(contains('<')));
    }
  });

  test('instructions never name a real person or SSML', () {
    const banned = [
      'ataturk',
      'atatürk',
      'adele',
      'freeman',
      'streep',
      'tarkan',
      'ajda',
      'nova',
      'alloy',
      'shimmer',
      'onyx',
      'fable',
      'ssml',
      'speak>',
    ];
    for (final id in OraclyVoiceId.values) {
      final blob = OpenAiTtsVoices.resolve(
        personality: 'gentle',
        language: 'tr',
        voiceId: id.wire,
      ).instructions.toLowerCase();
      for (final name in banned) {
        expect(blob, isNot(contains(name)), reason: '${id.wire} named $name');
      }
    }
  });

  test('written chat still commits the bubble before TTS', () {
    final source = File(
      'lib/features/companion/controllers/companion_controller.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    expect(
      source.contains(
        '_safeNotify();\n      if (_disposed || token != _sendGeneration) return;\n'
        '      try {\n        await _output.speakIfVoice',
      ),
      isTrue,
    );
    expect(source.contains('OrSpeechProsody'), isFalse);
    final output = File(
      'lib/features/companion/controllers/companion_output_controller.dart',
    ).readAsStringSync();
    expect(output.contains('Future<void>.delayed(Duration.zero)'), isTrue);
  });
}
