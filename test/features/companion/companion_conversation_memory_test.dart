/// Conversation memory, topic continuity, and honest personalization.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/ai/services/followup_question_resolve.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/memory.dart';
import 'package:oracly_new/features/companion/models/memory_permission.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_observation.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

const _job = [
  ConversationTurn(role: ConversationTurn.userRole, text: 'İşimi değiştirmeyi düşünüyorum.'),
  ConversationTurn(role: ConversationTurn.assistantRole, text: 'Ne zamandır?'),
  ConversationTurn(role: ConversationTurn.userRole, text: 'Üç aydır.'),
  ConversationTurn(role: ConversationTurn.assistantRole, text: 'iş tamam. Asıl sıkışma ne?'),
];

void main() {
  const or = CompanionResponder();
  setUp(() => OraclyL10n.bind('tr'));

  String say(String text, {List<ConversationTurn> turns = const []}) => or
      .respond(
        request: InsightRequest(text: text),
        context: const ReflectionContext(),
        turns: turns,
        personality: 'direct',
      )
      .body;

  test('short chat keeps a time span on the job thread', () {
    final thread = CompanionThreadMemory.read(_job.take(2).toList(), 'Üç aydır.');
    expect(thread.answeringPrompt, isTrue);
    expect(thread.topic, 'iş');
    expect(say('Üç aydır.', turns: _job.take(2).toList()).toLowerCase(), contains('iş'));
  });

  test('long chat keeps iş after the 8-turn provider window', () {
    final all = [
      ..._job.take(2),
      for (var i = 0; i < 18; i++)
        ConversationTurn(
          role: i.isEven ? ConversationTurn.userRole : ConversationTurn.assistantRole,
          text: i.isEven ? 'Evet, duruyor $i.' : 'Devam $i?',
        ),
    ];
    final window = ConversationTurn.takeRecent(all);
    expect(window.length, 8);
    expect(window.any((t) => t.text.contains('İşimi')), isFalse);
    final thread = CompanionThreadMemory.read(all, 'Değişmekten korkuyorum.');
    expect(thread.topic, 'iş');
    expect(thread.continuing, isTrue);
    expect((OpenAiServiceRequests.chat(
      model: 'm',
      userMessage: 'Değişmekten korkuyorum.',
      priorUser: const [],
      turns: all,
    ).payload['turns'] as List).length, 8);
  });

  test('topic switch and follow-up stay distinct', () {
    expect(CompanionThreadMemory.read(_job, 'Rüya gördüm.').switched, isTrue);
    expect(CompanionThreadMemory.read(_job, 'Rüya gördüm.').topic, 'rüya');
    expect(
      FollowupQuestionResolve.expand(
        current: 'Rüya gördüm.',
        priorUser: const ['Üç aydır.'],
        switched: true,
      ),
      'Rüya gördüm.',
    );
    final later = say('Değişmekten korkuyorum.', turns: _job);
    expect(later.toLowerCase(), allOf(contains('iş'), contains('kork')));
  });

  test('disagreement, advice, and prediction stay grounded', () {
    expect(say('Herkes iş değiştirmeli.'), contains('Katılmıyorum'));
    expect(say('Bu kesin olacak mı?'), contains('Bunu kesin söyleyemem'));
    expect(say('Ne yapmalıyım?', turns: _job).toLowerCase(), contains('iş'));
    expect(ChatPromptBuilder.system, contains('katılma'));
  });

  test('memory is cited only when saved, asked, and relevant', () {
    final known = or.respond(
      request: const InsightRequest(text: 'Sabah yürüyüşümü hatırlıyor musun?'),
      context: ReflectionContext(
        savedMemories: [
          Memory(
            id: '1',
            content: 'Sabah yürüyüşü',
            category: 'ritual',
            permission: MemoryPermission.saved,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      ),
    );
    expect(known.body, contains('Sabah yürüyüşü'));
    final vague = or.respond(
      request: const InsightRequest(text: 'Bunu hatırlıyor musun?'),
      context: ReflectionContext(
        savedMemories: [
          Memory(
            id: '1',
            content: 'Sabah yürüyüşü',
            category: 'ritual',
            permission: MemoryPermission.saved,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      ),
    );
    expect(vague.body.toLowerCase(), isNot(contains('sabah')));
    expect(say('Bunu hatırlıyor musun?').toLowerCase(), isNot(contains('sabah')));
  });

  test('empty profile stays silent; real labels stay at three', () {
    expect(DiscoveryOrContext.compact(PersonalDiscoveryProfile.empty), isNull);
    CrossDiscoveryInsight rec(String theme) => CrossDiscoveryInsight(
          theme: theme,
          sources: const ['tarot', 'coffee'],
          confidence: DiscoveryThemeStrength.recurring,
          lastObserved: DateTime(2026, 8, 10),
          sourceCount: 2,
          discoveryCount: 9,
          recencyWeight: 0.9,
        );
    final ctx = DiscoveryOrContext.compact(
      PersonalDiscoveryProfile(
        preferredOrStyle: AiPersonality.direct,
        crossInsights: [rec('değişim'), rec('sınırlar'), rec('iletişim')],
        observations: [
          DiscoveryObservation(source: 'dream', theme: 'aile', observedAt: DateTime(2026, 8, 1)),
        ],
      ),
    )!;
    expect(ctx, allOf(contains('değişim'), contains('sınırlar'), contains('iletişim')));
    expect(ctx, isNot(contains('aile')));
    expect(ctx, isNot(contains('discoveryCount')));
    expect(ctx, contains('DİREKT'));
  });
}
