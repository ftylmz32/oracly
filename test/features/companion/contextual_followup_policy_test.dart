/// Contextual follow-up — ask only when context genuinely needs it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/companion/services/contextual_followup_policy.dart';

void main() {
  const or = CompanionResponder();

  test('job change without timeline asks once', () {
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'İşimi bırakmayı düşünüyorum.',
      thread: CompanionThreadMemory.read(const [], 'İşimi bırakmayı düşünüyorum.'),
    );
    expect(decision.mode, FollowUpMode.ask);
    expect(decision.localKind, FollowUpLocalKind.jobTimeline);
  });

  test('fear on continuing thread asks a specific clarifier', () {
    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İş konusunda.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Asıl sıkışma ne?',
      ),
    ];
    final thread = CompanionThreadMemory.read(turns, 'Değişmekten korkuyorum.');
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'Değişmekten korkuyorum.',
      thread: thread,
    );
    expect(decision.mode, FollowUpMode.ask);
    expect(decision.localKind, FollowUpLocalKind.fearClarify);
  });

  test('detailed turn reflects without trailing question', () {
    final long =
        'Son aylarda iş yerinde yönetici değişti, ekip dağıldı ve '
        'her gün eve yorgun dönüyorum; ayrılmayı düşünüyorum ama '
        'ekonomik endişem de var.';
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: long,
      thread: CompanionThreadMemory.read(const [], long),
    );
    expect(decision.mode, FollowUpMode.reflect);
    expect(decision.allowTrailingQuestion, isFalse);
  });

  test('greeting closes without forcing a question', () {
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'Selam',
      thread: CompanionThreadMemory.read(const [], 'Selam'),
    );
    expect(decision.mode, FollowUpMode.answerOnly);
    expect(decision.allowTrailingQuestion, isFalse);
  });

  test('guard strips mechanical trailing probes even when ask allowed', () {
    final cleaned = ConversationResponseGuard.polish(
      'Burada bir eşik var. Ne düşünüyorsun?',
      allowTrailingQuestion: true,
    );
    expect(cleaned.toLowerCase(), isNot(contains('düşünüyorsun')));
    expect(cleaned.toLowerCase(), contains('eşik'));
  });

  test('guard blocks repeating isterse probe from prior turn', () {
    final cleaned = ConversationResponseGuard.polish(
      'Konu iş tarafında duruyor. İstersen buradan devam edelim?',
      allowTrailingQuestion: true,
      priorAssistant: 'İstersen biraz daha anlatır mısın?',
    );
    expect(cleaned.toLowerCase(), isNot(contains('istersen')));
  });

  test('guard strips generic trailing question when not allowed', () {
    final cleaned = ConversationResponseGuard.polish(
      'İş tarafında zor bir dönem. İstersen biraz daha anlatır mısın?',
      allowTrailingQuestion: false,
    );
    expect(cleaned.toLowerCase(), isNot(contains('anlatır mısın')));
    expect(cleaned.toLowerCase(), contains('iş'));
  });

  test('exploration cue may ask once', () {
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'Biraz konuşmak istiyorum.',
      thread: CompanionThreadMemory.read(const [], 'Biraz konuşmak istiyorum.'),
    );
    expect(decision.mode, FollowUpMode.ask);
    expect(decision.localKind, FollowUpLocalKind.explore);
  });

  test('after OR asked, brief answer reflects without another question', () {
    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İşimi bırakmayı düşünüyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Ne zamandır bunu düşünüyorsun?',
      ),
    ];
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'Üç aydır.',
      thread: CompanionThreadMemory.read(turns, 'Üç aydır.'),
    );
    expect(decision.allowTrailingQuestion, isFalse);
  });

  test('quality script: fear turn uses clarifier not generic probe', () {
    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İş konusunda.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Asıl sıkışma ne?',
      ),
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Değişmekten korkuyorum.',
      ),
    ];
    final reply = or.respond(
      request: const InsightRequest(text: 'Değişmekten korkuyorum.'),
      context: const ReflectionContext(),
      turns: turns,
      personality: 'direct',
    );
    expect(reply.body.toLowerCase(), anyOf(contains('yanlış'), contains('değiş')));
    expect(reply.body.toLowerCase(), isNot(contains('anlatır mısın')));
    expect(reply.body.toLowerCase(), isNot(contains('nasıl hissediyorsun')));
  });
}

