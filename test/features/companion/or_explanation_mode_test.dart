/// OR explanation mode — shape + domain, never a new personality.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_explanation_mode.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/companion/services/contextual_followup_policy.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';

void main() {
  test('parses the four explanation shapes', () {
    expect(OrExplanationMode.parseShape('Detaylı anlat'), ExplanationShape.detailed);
    expect(OrExplanationMode.parseShape('Basit anlat'), ExplanationShape.simple);
    expect(OrExplanationMode.parseShape('Örnek ver'), ExplanationShape.example);
    expect(
      OrExplanationMode.parseShape('Adım adım anlat'),
      ExplanationShape.stepByStep,
    );
    expect(OrExplanationMode.parseShape('Selam'), isNull);
  });

  test('domain stays technical, life, or fortune without mixing', () {
    expect(
      OrExplanationMode.resolveDomain(
        "Python'da async nasıl çalışıyor?",
        const [],
      ),
      ExplanationDomain.technical,
    );
    expect(
      OrExplanationMode.resolveDomain(
        'Detaylı anlat',
        const [
          ConversationTurn(
            role: ConversationTurn.userRole,
            text: 'Kahve falıma bak.',
          ),
        ],
      ),
      ExplanationDomain.fortune,
    );
    expect(
      OrExplanationMode.resolveDomain(
        'Basit anlat',
        const [
          ConversationTurn(
            role: ConversationTurn.userRole,
            text: 'İş konusunda kararsızım.',
          ),
        ],
      ),
      ExplanationDomain.life,
    );
  });

  test('hint adapts shape and domain and forbids personality switch', () {
    final tech = OrExplanationMode.hintFor(
      'Adım adım anlat',
      const [
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: "Python'da async nasıl çalışıyor?",
        ),
      ],
    )!;
    expect(tech, contains('adım adım'));
    expect(tech, contains('Teknik'));
    expect(tech, contains('sembolik'));
    expect(tech, contains('Kişilik'));

    final fortune = OrExplanationMode.hintFor(
      'Örnek ver',
      const [
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'Kahve falımda ne görüyorsun?',
        ),
      ],
    )!;
    expect(fortune, contains('örnek'));
    expect(fortune, contains('sembol'));
    expect(fortune, isNot(contains('Teknik')));
  });

  test('personality line stays separate from explanation hint', () {
    final voice = OrPersonality.conversationStyle('direct');
    final hint = OrExplanationMode.hintFor('Detaylı anlat', const [])!;
    expect(voice, contains('DİREKT'));
    expect(hint, isNot(contains('DİREKT')));
    expect(hint, contains('Kişilik'));
  });

  test('explanation requests skip clarifying questions', () {
    final thread = CompanionThreadMemory.read(const [], 'Detaylı anlat');
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'Detaylı anlat',
      thread: thread,
    );
    expect(decision.mode.name, 'answerOnly');
  });

  test('prompt and payload can carry explanation hint', () {
    expect(
      ChatPromptBuilder.system.toLowerCase(),
      contains('detaylı anlat'),
    );
    final hint = OrExplanationMode.hintFor('Basit anlat', const [])!;
    final messages = ChatPromptBuilder.messages(
      userMessage: 'Basit anlat',
      personality: 'gentle',
      styleHint: hint,
    );
    final system = messages.first['content'] as String;
    expect(system, contains('SAKİN'));
    expect(system, contains('basit anlat'));
    final request = OpenAiServiceRequests.chat(
      model: 'gpt-4.1-mini',
      userMessage: 'Basit anlat',
      priorUser: const [],
      personality: 'gentle',
      styleHint: hint,
    );
    expect(request.payload['styleHint'], contains('basit anlat'));
    expect(request.payload['personality'], 'gentle');
  });

  test('mergeHint preserves discovery context', () {
    final merged = OrExplanationMode.mergeHint(
      'Gözlenen tema: iş.',
      message: 'Örnek ver',
      turns: const [],
    );
    expect(merged, contains('Gözlenen tema'));
    expect(merged, contains('örnek'));
  });
}

