/// OR conversation quality master — behavior constraints, not prose snapshots.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_quality_addon.dart';
import 'package:oracly_new/features/ai/services/conversation_filler_guard.dart';
import 'package:oracly_new/features/companion/data/companion_correction.dart';
import 'package:oracly_new/features/companion/data/companion_intent.dart';
import 'package:oracly_new/features/companion/services/companion_conversation_continuity.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/companion/services/contextual_followup_policy.dart';
import 'package:oracly_new/features/companion/services/or_adaptive_conversation.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('correction cues are detected', () {
    expect(CompanionIntent.isCorrection('Yanlış anladın.'), isTrue);
    expect(
      CompanionIntent.isCorrection('Hayır, onu demek istemedim.'),
      isTrue,
    );
    expect(CompanionIntent.isCorrection('Selam'), isFalse);
  });

  test('correction continues thread without quiz', () {
    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İş konusunda kararsızım.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'İşi istememek mi, yanlış karar korkusu mu?',
      ),
    ];
    final current = 'Yanlış anladın. Korku değil, yorgunluk.';
    final thread = CompanionThreadMemory.read(turns, current);
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: current,
      thread: thread,
    );
    expect(decision.mode, isNot(FollowUpMode.ask));
    final hint = CompanionConversationContinuity.guidance(
      thread: thread,
      facts: CompanionConversationContinuity.facts(turns, current),
      current: current,
    );
    expect(hint, contains('düzeltme'));
  });

  test('short follow-ups include sonra / sen olsan / yani diyorsun', () {
    for (final cue in [
      'sonra?',
      'yani diyorsun ki?',
      'Sen olsan ne yapardın?',
      'bunu nasıl yapacağım?',
    ]) {
      expect(CompanionIntent.isShortFollowUp(cue), isTrue, reason: cue);
    }
  });

  test('adaptive length: greeting concise, advice not padded short', () {
    final greet = OrAdaptiveConversation.sense('Selam');
    expect(greet.registers, contains(OrConversationRegister.concise));
    final advice = OrAdaptiveConversation.sense('Ne yapmalıyım?');
    expect(advice.registers, contains(OrConversationRegister.deep));
    expect(advice.registers, isNot(contains(OrConversationRegister.concise)));
  });

  test('prompt includes quality addon and bans stock helpdesk', () {
    final system = ChatPromptBuilder.system;
    expect(system, contains(ChatPromptQualityAddon.tr.substring(0, 24)));
    expect(system.toLowerCase(), contains('düzeltme'));
    expect(system.toLowerCase(), isNot(contains('nasıl yardımcı olabilirim?')));
  });

  test('filler guard strips stock openers and closings', () {
    expect(
      ConversationFillerGuard.shape('Anlıyorum, bugün zor geçmiş.'),
      isNot(startsWith('Anlıyorum')),
    );
    expect(
      ConversationFillerGuard.shape('Bence biraz ara ver. Buradayım.'),
      isNot(contains('Buradayım')),
    );
  });

  test('correction style hint is memory-honest', () {
    expect(CompanionCorrection.styleHintTr.toLowerCase(), contains('savunma'));
    expect(CompanionCorrection.styleHintTr.toLowerCase(), isNot(contains('geçen ay')));
  });
}

