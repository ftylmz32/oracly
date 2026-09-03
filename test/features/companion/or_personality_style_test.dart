/// OR conversation style — local preference, default MİSTİK.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('default personality is mystical and labels match product styles', () {
    expect(PersonalizationSettings().aiPersonality, AiPersonality.mystical);
    expect(OrPersonality.label(AiPersonality.gentle), 'SAKİN');
    expect(OrPersonality.label(AiPersonality.mystical), 'MİSTİK');
    expect(OrPersonality.label(AiPersonality.poetic), 'SAMİMİ');
    expect(OrPersonality.label(AiPersonality.direct), 'DİREKT');
  });

  test('style instruction is local and never a second AI system', () {
    final hint = OrPersonality.styleInstruction(AiPersonality.direct);
    expect(hint, contains('DİREKT'));
    expect(hint.toLowerCase(), isNot(contains('yapay zek')));
    final messages = ChatPromptBuilder.messages(
      userMessage: 'Merhaba',
      styleHint: hint,
    );
    expect(messages.first['role'], 'system');
    expect(messages.first['content'], contains(hint));
  });

  test(
    'chat payload carries personality without secrets or a new transport',
    () {
      final request = OpenAiServiceRequests.chat(
        model: 'gpt-4.1-mini',
        userMessage: 'Merhaba',
        priorUser: const [],
        personality: OrPersonality.chatKey(AiPersonality.mystical),
        styleHint: OrPersonality.styleInstruction(AiPersonality.mystical),
      );
      expect(request.payload['personality'], 'mystical');
      expect(request.payload['styleHint'], contains('MİSTİK'));
      expect(request.payload['userMessage'], 'Merhaba');
    },
  );

  test('settings store persists the selected OR style', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalSettingsRepository(await LocalStorage.open());
    final loaded = await repo.load();
    expect(loaded.aiPersonality, AiPersonality.mystical);
    await repo.save(loaded.copyWith(aiPersonality: AiPersonality.direct));
    final again = await repo.load();
    expect(again.aiPersonality, AiPersonality.direct);
    expect(OrPersonality.label(again.aiPersonality), 'DİREKT');
  });
}

