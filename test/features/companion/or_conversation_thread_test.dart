/// Thread memory, greetings, and compact discovery for OR chat.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/services/followup_question_resolve.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';

void main() {
  test('selam is not glued onto the previous topic', () {
    expect(
      FollowupQuestionResolve.expand(
        current: 'selam',
        priorUser: const ['Bugün biraz kararsızım.'],
      ),
      'selam',
    );
  });

  test('short answer after a question stays on the thread', () {
    final thread = CompanionThreadMemory.read(const [
      ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Bugün biraz kararsızım.',
      ),
      ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Daha çok iş konusunda mı, yoksa genel olarak mı?',
      ),
    ], 'İş konusunda.');
    expect(thread.answeringPrompt, isTrue);
    expect(thread.topic, 'iş');
    expect(thread.switched, isFalse);
    expect(thread.instruction, contains('netleştirmeye'));
  });

  test('fear of change stays on the remembered job thread', () {
    final thread = CompanionThreadMemory.read(const [
      ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Bugün biraz kararsızım.',
      ),
      ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Daha çok iş konusunda mı, yoksa genel olarak mı?',
      ),
      ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İş konusunda.',
      ),
      ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'iş tamam. Asıl sıkışma ne?',
      ),
    ], 'Değişmekten korkuyorum.');
    expect(thread.answeringPrompt, isFalse);
    expect(thread.continuing, isTrue);
    expect(thread.switched, isFalse);
    expect(thread.topic, 'iş');
    expect(thread.recap, contains('kararsızım'));
    expect(thread.recap, contains('İş konusunda'));
    expect(thread.instruction, contains('devam eden'));
  });

  test('blank follow-up is empty, not glued onto the last topic', () {
    expect(
      FollowupQuestionResolve.expand(
        current: '   ',
        priorUser: const ['İş konusunda.'],
      ),
      '',
    );
  });

  test('a new domain is a topic switch', () {
    final thread = CompanionThreadMemory.read(const [
      ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İş konusunda kararsızım.',
      ),
      ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Asıl sıkışma ne?',
      ),
    ], 'Dün gece durmayan bir rüya gördüm, yılan evin içinden geçti.');
    expect(thread.switched, isTrue);
    expect(thread.topic, 'rüya');
  });

  test('discovery context stays at most three real themes', () {
    CrossDiscoveryInsight rec(String theme) => CrossDiscoveryInsight(
      theme: theme,
      sources: const ['tarot', 'coffee'],
      confidence: DiscoveryThemeStrength.recurring,
      lastObserved: DateTime(2026, 8, 10),
      sourceCount: 2,
      discoveryCount: 3,
      recencyWeight: 0.9,
    );
    final ctx = DiscoveryOrContext.compact(
      PersonalDiscoveryProfile(
        crossInsights: [
          rec('değişim'),
          rec('iletişim'),
          rec('karar verme'),
          rec('aile'),
        ],
      ),
    )!;
    expect(ctx, contains('değişim'));
    expect(ctx, contains('iletişim'));
    expect(ctx, contains('karar verme'));
    expect(ctx, isNot(contains('aile')));
    expect(ctx, isNot(contains('uydurma anı')));
  });
}
