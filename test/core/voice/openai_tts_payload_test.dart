/// Proxy TTS request must never carry keys or provider voice names.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/or_speech_grant.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_results.dart';
import 'package:oracly_new/features/ai/production/openai/openai_tts_request.dart';
import 'package:oracly_new/features/ai/production/openai/openai_tts_voices.dart';

void main() {
  setUp(OrSpeechGrant.clear);

  test('TTS proxy payload has identity, not OpenAI voices or keys', () {
    final request = OpenAiTtsRequest.create(
      text: 'selam',
      personality: 'gentle',
      language: 'tr',
      voiceId: OraclyVoiceId.calm.wire,
    );
    expect(request.toJson()['operation'], 'tts');
    expect(
      request.payload.keys,
      unorderedEquals([
        'text',
        'language',
        'personality',
        'voiceId',
        'speechSpeed',
      ]),
    );
    expect(request.payload['text'], 'selam');
    expect(request.payload['voiceId'], 'calm');
    expect(request.payload.containsKey('voice'), isFalse);
    expect(request.payload.containsKey('model'), isFalse);
    expect(jsonEncode(request.toJson()), isNot(contains('sk-')));
    expect(jsonEncode(request.toJson()), isNot(contains('openai')));
    expect(jsonEncode(request.toJson()), isNot(contains('coral')));
  });

  test('personality does not replace OR identity', () {
    final identities = {
      for (final key in ['gentle', 'mystical', 'poetic', 'direct'])
        OpenAiTtsVoices.resolve(
          personality: key,
          language: 'tr',
          voiceId: 'deep',
        ).voice,
    };
    expect(identities, {'cedar'});
  });

  test('legacy voice ids normalize on the wire', () {
    final request = OpenAiTtsRequest.create(
      text: 'selam',
      personality: 'gentle',
      voiceId: 'female_natural',
    );
    expect(request.payload['voiceId'], 'warm');
  });

  test('chat success remembers the server speech grant', () {
    OpenAiServiceResults.chat(
      AiOutcome.success({
        'text': 'Sakin bir yansıma.',
        'speechGrant': 'abc123',
      }),
      'gpt-4o',
    );
    expect(OrSpeechGrant.current, 'abc123');
  });

  test('a server speech grant rides with the spoken reply', () {
    OrSpeechGrant.remember('abc123');
    final request = OpenAiTtsRequest.create(
      text: 'Sakin bir yansıma.',
      personality: 'gentle',
    );
    expect(request.payload['speechGrant'], 'abc123');
    expect(request.payload.containsKey('feature'), isFalse);
  });
}
