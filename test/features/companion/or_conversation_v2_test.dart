/// OR Sohbet V2 — rolling turns, honest discovery, distinct voices.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/companion/services/companion_turn_window.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

void main() {
  test('welcome is not sent as conversation memory', () {
    final now = DateTime(2026, 8, 15);
    final turns = CompanionTurnWindow.fromMessages([
      AIMessage(
        id: 'welcome_1',
        role: AIMessageRole.assistant,
        content: 'Buradayım.',
        createdAt: now,
      ),
      AIMessage(
        id: 'u1',
        role: AIMessageRole.user,
        content: 'Bugün biraz kararsızım.',
        createdAt: now,
      ),
      AIMessage(
        id: 'a1',
        role: AIMessageRole.assistant,
        content: 'İş mi, yoksa başka bir yer mi?',
        createdAt: now,
      ),
    ]);
    expect(turns, hasLength(2));
    expect(turns.first.isUser, isTrue);
    expect(turns.last.isUser, isFalse);
  });

  test('follow-up keeps the prior user and OR turns', () {
    final now = DateTime(2026, 8, 15);
    final history = CompanionTurnWindow.fromMessages([
      AIMessage(
        id: 'u1',
        role: AIMessageRole.user,
        content: 'Son zamanlarda iş konusunda kararsızım.',
        createdAt: now,
      ),
      AIMessage(
        id: 'a1',
        role: AIMessageRole.assistant,
        content: 'Kalmakla değişmek arasında mı?',
        createdAt: now,
      ),
    ]);
    final messages = ChatPromptBuilder.messages(
      userMessage: 'Değişmek istiyorum ama korkuyorum.',
      turns: history,
      personality: 'direct',
    );
    expect(messages[1]['role'], 'user');
    expect(messages[1]['content'], contains('iş konusunda'));
    expect(messages[2]['role'], 'assistant');
    expect(messages[2]['content'], contains('değişmek'));
    expect(messages.last['content'], contains('korkuyorum'));
    expect(messages.first['content'], contains('DİREKT'));
    expect(messages.first['content'], contains('sıfırlama'));
  });

  test('empty discovery never invents themes', () {
    expect(DiscoveryOrContext.compact(PersonalDiscoveryProfile.empty), isNull);
    final messages = ChatPromptBuilder.messages(
      userMessage: 'Bugün biraz tuhaf hissediyorum.',
    );
    expect(messages.first['content'], isNot(contains('Gözlenen tekrarlar')));
  });

  test('four personalities stay distinct in the system line', () {
    final lines = [
      for (final style in AiPersonality.values)
        OrPersonality.conversationStyle(OrPersonality.chatKey(style)),
    ];
    expect(lines.toSet(), hasLength(4));
    expect(lines[AiPersonality.gentle.index], contains('SAKİN'));
    expect(lines[AiPersonality.mystical.index], contains('MİSTİK'));
    expect(lines[AiPersonality.poetic.index], contains('SAMİMİ'));
    expect(lines[AiPersonality.direct.index], contains('DİREKT'));
    expect(lines[AiPersonality.gentle.index], isNot(contains('atmosferik')));
    expect(lines[AiPersonality.mystical.index], contains('imge'));
    expect(lines[AiPersonality.poetic.index], contains('Anladım'));
    expect(lines[AiPersonality.direct.index], contains('Süs yok'));
  });

  test('chat payload has turns, no secrets, and a short-user cap', () {
    final request = OpenAiServiceRequests.chat(
      model: 'gpt-4.1-mini',
      userMessage: 'İş konusunda.',
      priorUser: const ['Bugün biraz kararsızım.'],
      personality: OrPersonality.chatKey(AiPersonality.gentle),
      turns: const [
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'Bugün biraz kararsızım.',
        ),
        ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'İş mi ağır geliyor?',
        ),
      ],
    );
    final blob = jsonEncode(request.payload);
    expect(request.payload['personality'], 'gentle');
    expect(request.payload['turns'], isA<List<dynamic>>());
    expect(blob, contains('assistant'));
    expect(blob, isNot(contains('sk-')));
    expect(blob, isNot(contains('Bearer')));
    expect(blob, isNot(contains('firebase')));
    final wall = List.filled(8, 'Uzun paragraf.').join('\n\n');
    final polished = ConversationResponseGuard.polish(
      wall,
      userMessage: 'İş konusunda.',
    );
    expect(
      RegExp('Uzun paragraf').allMatches(polished).length,
      lessThanOrEqualTo(3),
    );
  });
}

