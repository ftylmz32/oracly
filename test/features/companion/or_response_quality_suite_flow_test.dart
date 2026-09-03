/// OR response quality suite B — follow-up, long thread, handoff, memory, depth.
/// Behavior regression only; never exact prose.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_persona_contract.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/models/memory.dart';
import 'package:oracly_new/features/companion/models/memory_permission.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/or_adaptive_conversation.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/companion/services/or_response_length_intelligence.dart';
import 'or_response_quality_harness.dart';

void main() {
  final h = OrQualityHarness();
  setUp(() => OraclyL10n.bind('tr'));

  test('follow-up keeps the thread without restarting', () {
    final t1 = h.say('Selam.');
    var turns = h.append(const [], 'Selam.', t1.body);
    final t2 = h.say('İş konusunda sıkışıyorum.', turns: turns);
    h.expectKeepsThread(t2.body, ['iş']);
    turns = h.append(turns, 'İş konusunda sıkışıyorum.', t2.body);
    final t3 = h.say('Devam edelim.', turns: turns);
    h.expectHumanChamber(t3.body);
    h.expectAvoids(t3.body, ['selam. nasılsın']);
  });

  test('long conversation stays continuous', () {
    var turns = <ConversationTurn>[];
    const beats = [
      'İş değiştirmeyi düşünüyorum.',
      'Yaklaşık üç aydır.',
      'Korkuyorum.',
      'Maddi taraf da var.',
    ];
    String last = '';
    for (final beat in beats) {
      final reply = h.say(beat, turns: turns);
      h.expectHumanChamber(reply.body);
      turns = h.append(turns, beat, reply.body);
      last = reply.body;
    }
    expect(turns.length, greaterThanOrEqualTo(8));
    expect(
      last.toLowerCase(),
      anyOf(contains('iş'), contains('maddi'), contains('kork')),
    );
    h.expectAvoids(last, ['selam. nasılsın', 'size nasıl yardımcı']);
  });

  test('discovery handoff lands as interpretation context', () {
    const handoff =
        'Tarot\nSoru: Ne yapmalıyım?\nThe Moon\nKüçük bir adım yeterli.';
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'Bu kartlara göre ne diyorsun?',
      recentMessages: const [],
      reflection: const ReflectionContext(proactiveAcknowledgment: handoff),
    );
    expect(selected.featureSpecific, isNotNull);
    final hint = selected.toStyleHint();
    expect(hint, contains('INTERPRETATION'));
    expect(hint.toLowerCase(), contains('moon'));
    expect(hint.toLowerCase(), isNot(contains('retrieval')));
    expect(hint.toLowerCase(), isNot(contains('stylehint')));
  });

  test('memory reference uses real overlap only', () {
    final known = h.say(
      'Sabah yuruyus aliskanligimi hatirliyor musun?',
      context: ReflectionContext(
        savedMemories: [
          Memory(
            id: '1',
            content: 'Sabah yuruyus aliskanligi her gun',
            category: 'ritual',
            permission: MemoryPermission.saved,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      ),
    );
    expect(known.body.toLowerCase(), contains('yuruyus'));
    final unknown = h.say('Bunu hatırlıyor musun?');
    h.expectAvoids(unknown.body, ['yuruyus', 'sabah yürüyüş']);
  });

  test('short response request stays concise', () {
    const msg = 'Kısaca söyle.';
    expect(
      OrAdaptiveConversation.sense(msg).registers,
      contains(OrConversationRegister.concise),
    );
    final depth = OrResponseLengthIntelligence.select(
      userMessage: msg,
      preference: OrResponseDepth.deep,
    );
    expect(depth.rank, lessThanOrEqualTo(OrResponseDepth.short.rank));
  });

  test('deep response request can deepen within preference', () {
    const msg = 'Bunu derinlemesine anlat.';
    expect(
      OrAdaptiveConversation.sense(msg).registers,
      contains(OrConversationRegister.deep),
    );
    final depth = OrResponseLengthIntelligence.select(
      userMessage: msg,
      preference: OrResponseDepth.deep,
    );
    expect(depth, OrResponseDepth.deep);
    expect(ChatPromptBuilder.system, contains(OrPersonaContract.identityTr));
  });
}

