/// Conversation continuity — remember in-thread facts, no fabricate/repeat.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_conversation_continuity.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/companion/services/contextual_followup_policy.dart';

const _job = [
  ConversationTurn(
    role: ConversationTurn.userRole,
    text: 'İşimi değiştirmeyi düşünüyorum.',
  ),
  ConversationTurn(
    role: ConversationTurn.assistantRole,
    text: 'Ne zamandır?',
  ),
  ConversationTurn(
    role: ConversationTurn.userRole,
    text: 'Üç aydır.',
  ),
  ConversationTurn(
    role: ConversationTurn.assistantRole,
    text: 'iş tamam. Asıl sıkışma ne?',
  ),
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

  test('known time span is recorded and not re-asked', () {
    final thread = CompanionThreadMemory.read(_job, 'Asıl mesele belirsizlik.');
    expect(thread.knownTimeSpan, isTrue);
    expect(thread.topic, 'iş');
    expect(thread.continuityHint.toLowerCase(), contains('süre'));
    expect(thread.continuityHint.toLowerCase(), contains('yeniden sorma'));

    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'İşimi değiştirmeyi düşünüyorum.',
      thread: thread,
    );
    expect(decision.localKind, isNot(FollowUpLocalKind.jobTimeline));
  });

  test('facts extract anchors without dumping full transcript', () {
    final facts = CompanionConversationContinuity.facts(_job, 'Devam.');
    expect(facts.hasTimeSpan, isTrue);
    expect(facts.timeSpan!.toLowerCase(), contains('üç'));
    expect(facts.anchors.length, lessThanOrEqualTo(3));
    for (final a in facts.anchors) {
      expect(a.length, lessThanOrEqualTo(72));
    }
    expect(facts.promptHint.toLowerCase(), contains('icat etme'));
  });

  test('greeting mid-thread is interrupt and preserves topic', () {
    final thread = CompanionThreadMemory.read(_job, 'Selam');
    expect(thread.interrupted, isTrue);
    expect(thread.topic, 'iş');
    expect(thread.continuing, isFalse);
    final body = say('Selam', turns: _job);
    expect(body.toLowerCase(), contains('iş'));
    expect(body.toLowerCase(), isNot(contains('nasıl yardımcı')));
    expect(body.trim().endsWith('?'), isFalse);
  });

  test('resume after interrupt reflects topic without restart quiz', () {
    final turns = [
      ..._job,
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Selam',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Selam. iş ipi duruyor — devam mı?',
      ),
    ];
    final thread = CompanionThreadMemory.read(turns, 'İş konusunda devam.');
    expect(thread.resuming, isTrue);
    expect(thread.topic, 'iş');
    final body = say('İş konusunda devam.', turns: turns);
    expect(body.toLowerCase(), contains('iş'));
    expect(body.toLowerCase(), isNot(contains('ne zamandır')));
  });

  test('chat prompt encodes continuity without fabrication', () {
    final s = ChatPromptBuilder.system.toLowerCase();
    expect(s, contains('hatırla'));
    expect(s, contains('yeniden sorma'));
    expect(s, contains('anı uydurma'));
  });
}

