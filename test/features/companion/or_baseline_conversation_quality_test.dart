/// Spec: docs/project_execution/OR_BASELINE_CONVERSATION_QUALITY.md
/// OR baseline conversation qualities — human thread, no encyclopedia, no fake memory.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/core/personality/or_knowledge_depth.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';

void main() {
  const or = CompanionResponder();
  setUp(() => OraclyL10n.bind('tr'));

  CompanionResponse say(
    String text, {
    List<ConversationTurn> turns = const [],
    String personality = 'direct',
  }) {
    return or.respond(
      request: InsightRequest(text: text),
      context: const ReflectionContext(),
      turns: turns,
      personality: personality,
    );
  }

  test('1-3 greeting follow-up context: connects iş by the fourth turn', () {
    final t1 = say('Selam.');
    expect(t1.body.trim(), isNotEmpty);
    expect(t1.body.length, lessThan(80));
    expect(t1.body.split(RegExp(r'[.!?]+')).where((p) => p.trim().isNotEmpty),
        hasLength(lessThanOrEqualTo(2)));
    expect(OrCore.looksTherapistScript(t1.body), isFalse);
    expect(OrCore.soundsAlive(t1.body), isTrue);
    expect(OrCore.looksMetaAi(t1.body), isFalse);
    expect(OrCore.looksCustomerService(t1.body), isFalse);

    var turns = [
      const ConversationTurn(role: ConversationTurn.userRole, text: 'Selam.'),
      ConversationTurn(role: ConversationTurn.assistantRole, text: t1.body),
    ];
    final t2 = say('Bugün kafam karışık.', turns: turns);
    expect(t2.body, contains('?'));
    expect(t2.body.toLowerCase(), isNot(contains('üzgünüm')));
    expect(OrCore.looksTherapistScript(t2.body), isFalse);

    turns = [
      ...turns,
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Bugün kafam karışık.',
      ),
      ConversationTurn(role: ConversationTurn.assistantRole, text: t2.body),
    ];
    final t3 = say('İş konusunda.', turns: turns);
    expect(t3.body.toLowerCase(), contains('iş'));

    turns = [
      ...turns,
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İş konusunda.',
      ),
      ConversationTurn(role: ConversationTurn.assistantRole, text: t3.body),
    ];
    final t4 = say('Değişmekten korkuyorum.', turns: turns);
    expect(t4.body.toLowerCase(), allOf(contains('iş'), contains('kork')));
    expect(t4.body.toLowerCase(), isNot(contains('selam. nasılsın')));
  });

  test('4-6 short long disagreement: stays, detail stays on the thread, fortune is symbolic', () {
    expect(say('Selam.').body.length, lessThan(80));
    final job = <ConversationTurn>[
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İşimi bırakmayı düşünüyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Ne zamandır?',
      ),
    ];
    final scared = say('Korkuyorum.', turns: job);
    expect(scared.body.toLowerCase(), contains('iş'));
    final fortune = say('Kahve falıma bak.', personality: 'gentle');
    expect(fortune.body.trim(), isNotEmpty);
    expect(fortune.body.toLowerCase(), isNot(contains('kesin gelecek')));
    // Knowledge depth lives on the live provider path — no local topic FAQs.
    final knowledgeLocal = say("Python'da async nasıl çalışıyor?");
    expect(knowledgeLocal.body.toLowerCase(), isNot(contains('event loop')));
    expect(ChatPromptBuilder.system, contains(OrKnowledgeDepth.promptTr));
    expect(say('Herkes iş değiştirmeli.').body, contains('Katılmıyorum'));
  });

  test('7-8 uncertainty casual: forced empathy and memory stays honest', () {
    final cleaned = ConversationResponseGuard.polish(
      "I'm sorry you're feeling that way. Let's talk about work.",
      userMessage: 'Korkuyorum.',
    );
    expect(cleaned.toLowerCase(), isNot(contains("i'm sorry you're feeling")));
    expect(cleaned.toLowerCase(), contains('work'));
    expect(say('Bunu hatırlıyor musun?').body.toLowerCase(),
        isNot(contains('sabah')));
    expect(ChatPromptBuilder.system.toLowerCase(), contains('sohbeti sıfırlama'));
    expect(ChatPromptBuilder.system.toLowerCase(), contains("i'm sorry"));
    expect(ChatPromptBuilder.system.toLowerCase(), isNot(contains('kısa yazdıysa')));
  });

  test('personal context uses at most three real themes', () {
    CrossDiscoveryInsight rec(String theme) => CrossDiscoveryInsight(
          theme: theme,
          sources: const ['tarot', 'coffee'],
          confidence: DiscoveryThemeStrength.recurring,
          lastObserved: DateTime(2026, 8, 10),
          sourceCount: 2,
          discoveryCount: 4,
          recencyWeight: 1,
        );
    final ctx = DiscoveryOrContext.compact(
      PersonalDiscoveryProfile(
        crossInsights: [
          rec('değişim'),
          rec('sınırlar'),
          rec('iletişim'),
          rec('aile'),
        ],
      ),
    )!;
    expect(ctx, allOf(contains('değişim'), contains('sınırlar'), contains('iletişim')));
    expect(ctx, isNot(contains('aile')));
  });

  test('welcome line and filler strip stay casual', () {
    expect(CompanionCopy.welcomeLine().trim(), isNotEmpty);
    final cleanedTr = ConversationResponseGuard.polish(
      'Elbette, size yardımcı olabilirim. Buradayım.',
      userMessage: 'Selam',
    );
    expect(cleanedTr.toLowerCase(), isNot(contains('elbette')));
    expect(cleanedTr.toLowerCase(), isNot(contains('yardımcı olabilirim')));
    expect(OrCore.looksCustomerService(cleanedTr), isFalse);
  });
}
