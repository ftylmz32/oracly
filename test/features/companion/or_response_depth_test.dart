/// OR response depth — length cap only, never padding.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _wall(int sentences) =>
    [for (var i = 1; i <= sentences; i++) 'Cümle $i.'].join(' ');

int _sentenceCount(String text) => text
    .split(RegExp(r'(?<=[.!?])\s+'))
    .where((p) => p.trim().isNotEmpty)
    .length;

void main() {
  test('SHORT caps at four sentences', () {
    final out = ConversationResponseGuard.polish(
      _wall(12),
      userMessage: 'Selam',
      depth: OrResponseDepth.short,
    );
    expect(_sentenceCount(out), 4);
  });

  test('BALANCED caps at eight sentences', () {
    final out = ConversationResponseGuard.polish(
      _wall(12),
      userMessage: 'Selam',
      depth: OrResponseDepth.balanced,
    );
    expect(_sentenceCount(out), 8);
  });

  test('DEEP caps at sixteen sentences', () {
    final out = ConversationResponseGuard.polish(
      _wall(20),
      userMessage: 'Uzun bir mesele anlatıyorum çünkü durduğum yer karışık.',
      depth: OrResponseDepth.deep,
    );
    expect(_sentenceCount(out), 16);
  });

  test('NO PADDING keeps a one-sentence deep reply', () {
    const one = 'Asıl duran yer iş.';
    expect(
      ConversationResponseGuard.polish(
        one,
        userMessage: 'İş konusunda ne düşünüyorsun?',
        depth: OrResponseDepth.deep,
      ),
      one,
    );
  });

  test('voice cap is shorter than deep text', () {
    expect(OrResponseDepth.deep.voiceMaxSentences, lessThan(16));
    expect(OrResponseDepth.deep.sentenceCap(spoken: true), 8);
    final spoken = OrResponseDepth.deep.cap(_wall(16), spoken: true);
    expect(_sentenceCount(spoken), 8);
  });

  test('prompt and payload carry depth, not personality change', () {
    final messages = ChatPromptBuilder.messages(
      userMessage: 'Selam',
      personality: 'direct',
      depth: OrResponseDepth.deep,
    );
    final system = messages.first['content'] as String;
    expect(system, contains('Uzunluk tercihi: deep'));
    expect(system, contains('Kişiliği'));
    expect(system, contains('DİREKT'));
    expect(system.toLowerCase(), isNot(contains('kısa yazdıysa 1–2')));
    final request = OpenAiServiceRequests.chat(
      model: 'gpt-4.1-mini',
      userMessage: 'Selam.',
      priorUser: const [],
      depth: OrResponseDepth.short,
      spoken: true,
    );
    expect(request.payload['depth'], 'short');
    expect(request.payload['spoken'], isTrue);
  });

  test('depth persists independently of personality', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalSettingsRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    await repo.save(
      const PersonalizationSettings(
        orResponseDepth: OrResponseDepth.deep,
        aiPersonality: AiPersonality.gentle,
      ),
    );
    final loaded = await repo.load();
    expect(loaded.orResponseDepth, OrResponseDepth.deep);
    expect(loaded.aiPersonality, AiPersonality.gentle);
    expect(const PersonalizationSettings().orResponseDepth, OrResponseDepth.balanced);
  });
}

