/// Proxy TTS request must never carry keys or provider voice names.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/or_speech_grant.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_results.dart';
import 'package:oracly_new/features/ai/production/openai/openai_tts_request.dart';
import 'package:oracly_new/features/ai/production/openai/openai_tts_voices.dart';

void main() {
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
    expect(request.payload.containsKey('speechGrant'), isFalse);
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

  test('a reply keeps its own speech grant', () {
    final first = OpenAiServiceResults.chat(
      AiOutcome.success({
        'text': 'Birinci yansıma.',
        'speechGrant': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      }),
      'gpt-4o',
    );
    final second = OpenAiServiceResults.chat(
      AiOutcome.success({
        'text': 'Ikinci yansıma.',
        'speechGrant': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      }),
      'gpt-4o',
    );
    final firstGrant = first.when(
      success: (reply) => reply.speechGrant,
      error: (_) => null,
    );
    final secondGrant = second.when(
      success: (reply) => reply.speechGrant,
      error: (_) => null,
    );
    expect(firstGrant, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    expect(secondGrant, 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
  });

  test('speech uses the grant of the opened message', () {
    final older = AIMessage(
      id: 'older',
      role: AIMessageRole.assistant,
      content: 'Birinci yansıma.',
      createdAt: DateTime.utc(2026, 10, 19),
      metadata: const {'speechGrant': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'},
    );
    final newer = AIMessage(
      id: 'newer',
      role: AIMessageRole.assistant,
      content: 'Ikinci yansıma.',
      createdAt: DateTime.utc(2026, 10, 19, 0, 1),
      metadata: const {'speechGrant': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'},
    );
    final olderRequest = OpenAiTtsRequest.create(
      text: older.content,
      personality: 'gentle',
      speechGrant: OrSpeechGrant.of(older.metadata),
    );
    final newerRequest = OpenAiTtsRequest.create(
      text: newer.content,
      personality: 'gentle',
      speechGrant: OrSpeechGrant.of(newer.metadata),
    );
    expect(olderRequest.payload['speechGrant'], older.metadata['speechGrant']);
    expect(newerRequest.payload['speechGrant'], newer.metadata['speechGrant']);
    expect(
      olderRequest.payload['speechGrant'],
      isNot(newerRequest.payload['speechGrant']),
    );
  });
}
