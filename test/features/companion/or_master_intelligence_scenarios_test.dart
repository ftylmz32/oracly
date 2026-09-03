/// OR master intelligence scenarios.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/data/companion_intent.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/companion_thread_digest.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/companion/services/contextual_followup_policy.dart';
import 'package:oracly_new/features/companion/services/or_adaptive_conversation.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/companion/services/or_discovery_handoff_quality.dart';

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

  test('scenario A greeting is short and not helpdesk', () {
    final body = say('Selam');
    expect(body.length, lessThan(120));
    expect(body.toLowerCase(), isNot(contains('nasıl yardımcı')));
  });

  test('scenario C job fear continues across follow-ups', () {
    expect(
      CompanionIntent.isJobChange(
        'Işimden ayrılmayı düşünüyorum ama korkuyorum.',
      ),
      isTrue,
    );
    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Işimden ayrılmayı düşünüyorum ama korkuyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Asıl zorlayan isi istememek mi, yanlis karar korkusu mu?',
      ),
    ];
    final fear = CompanionThreadMemory.read(
      turns,
      'Yanlış karar vermekten korkuyorum.',
    );
    expect(fear.topic, 'iş');
    expect(fear.answeringPrompt || fear.continuing, isTrue);
    final whyTurns = [
      ...turns,
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Yanlış karar vermekten korkuyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Yanlis karar korkusu seni yerinde tutuyor gibi.',
      ),
    ];
    final why = CompanionThreadMemory.read(
      whyTurns,
      'Neden korktugumu bilmiyorum.',
    );
    expect(why.topic, 'iş');
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'Neden korktugumu bilmiyorum.',
      thread: why,
    );
    expect(decision.mode, isNot(FollowUpMode.ask));
    final body = say('Peki simdi ne yapayim?', turns: whyTurns);
    expect(body.toLowerCase(), contains('iş'));
    expect(body.toLowerCase(), isNot(contains('nasıl yardımcı')));
  });

  test('short follow-ups do not reset topic', () {
    final jobTurns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Iş konusunda ne yapacağımı bilmiyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Işi istememek mi, yanlis karar korkusu mu?',
      ),
    ];
    for (final cue in ['peki?', 'neden?', 'devam', 'emin misin?']) {
      expect(CompanionIntent.isShortFollowUp(cue), isTrue, reason: cue);
      final thread = CompanionThreadMemory.read(jobTurns, cue);
      expect(thread.topic, 'iş', reason: cue);
      final body = say(cue, turns: jobTurns);
      expect(body.toLowerCase(), contains('iş'), reason: cue);
    }
  });

  test('long conversation digest preserves older topic without dump', () {
    final long = <ConversationTurn>[
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Işimi değiştirmeyi düşünüyorum uzun zamandır.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Ne zamandir?',
      ),
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Uc aydir karar veremiyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Is ipi duruyor.',
      ),
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Yanlis karar vermekten korkuyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Korku kararın kendisinden ayrı.',
      ),
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Belki sabah daha net olur.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Bir gece ara vermek de secenek.',
      ),
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Bugun hava guzel.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Guzel bir ara.',
      ),
    ];
    final digest = CompanionThreadDigest.fromOlder(long);
    expect(digest, isNotNull);
    expect(digest!.toLowerCase(), contains('iş'));
    expect(digest.toLowerCase(), contains('invent nothing'));
    expect(digest.length, lessThanOrEqualTo(CompanionThreadDigest.maxChars));
    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'Peki?',
      recentMessages: ConversationTurn.takeRecent(long),
      fullHistory: long,
    );
    expect(hint.toLowerCase(), contains('earlier'));
    expect(hint.toLowerCase(), isNot(contains('memory id')));
  });

  test('tarot handoff stays compact and id-free', () {
    final compact = OrDiscoveryHandoffQuality.compact(
      const OracleReadingContext(
        sessionId: 's1',
        spreadLabel: 'Uc Kart',
        deckId: 'classic',
        deckName: 'Classic',
        readingTitle: 'Acilim',
        cardsSummary: 'The Fool · id:abc-123',
        interpretationSummary: 'Yeni bir baslangic temasi.',
        userQuestion: 'Ne yapmaliyim?',
        cardNames: ['The Fool'],
        kind: OracleReadingKind.tarot,
        sourceLabel: 'Tarot',
      ),
    );
    expect(compact.length, lessThanOrEqualTo(400));
    expect(compact.toLowerCase(), contains('tarot'));
    expect(compact, isNot(contains('abc-123')));
  });

  test('adaptive length short follow-up is concise', () {
    final short = OrAdaptiveConversation.sense('peki?');
    expect(short.registers, contains(OrConversationRegister.concise));
  });

  test('prompt forbids fake memory and stock empathy restart', () {
    final s = ChatPromptBuilder.system.toLowerCase();
    expect(s, contains('anı uydurma'));
    expect(s, contains('kısa takip'));
    expect(s, contains('seni anlıyorum'));
  });
}

