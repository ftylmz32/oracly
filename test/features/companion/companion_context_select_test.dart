/// Context selection - relevant layers only, never a memory dump.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_relevance.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/services/companion_context_select.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';

void main() {
  test('irrelevant observation is dropped from styleHint', () {
    final hint = CompanionContextSelect.assemble(
      userMessage: 'Bugun hava nasil?',
      turns: const [],
      discoveryHint: null,
      proactiveAcknowledgment:
          'Son donemde degisim konusu birkac farkli kesfinde yeniden '
          'karsina cikiyor.',
    );
    expect(hint.toLowerCase(), isNot(contains('degisim')));
  });

  test('relevant observation may enter when discovery is silent', () {
    final obs =
        'Son donemde karar verme konusu birkac farkli kesfinde yeniden '
        'karsina cikiyor. Bunu tek sonuca baglamazdim.';
    expect(
      PersonalMemoryRelevance.filterObservation(
        obs,
        'Bu karar konusunda ne dusunuyorsun?',
      ),
      isNotNull,
    );
    final hint = CompanionContextSelect.assemble(
      userMessage: 'Bu karar konusunda ne dusunuyorsun?',
      turns: const [],
      discoveryHint: null,
      proactiveAcknowledgment: obs,
    );
    expect(hint.toLowerCase(), contains('karar'));
  });

  test('discovery wins over observation - no double dump', () {
    final hint = CompanionContextSelect.assemble(
      userMessage: 'Is konusunda sikisiyorum.',
      turns: const [],
      discoveryHint:
          'Son kesiflerinde tekrar eden bir iz: kariyer. Keep short.',
      proactiveAcknowledgment:
          'Son donemde degisim konusu birkac farkli kesfinde yeniden '
          'karsina cikiyor.',
    );
    expect(hint.toLowerCase(), contains('kariyer'));
    expect(hint.toLowerCase(), isNot(contains('degisim konusu')));
  });

  test('with prior turns, merge omits duplicated user recap', () {
    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Isimi birakmayi dusunuyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Ne zamandir?',
      ),
    ];
    final merged = CompanionThreadMemory.merge(
      discovery: null,
      turns: turns,
      current: 'Bir yildir.',
    );
    expect(merged, isNot(contains('Son kullan')));
  });

  test('topic switch instructs not to invent a single story', () {
    final mem = CompanionThreadMemory(
      topic: 'ruya',
      switched: true,
      hadPriorTopic: true,
      lastAssistant: 'Asil sikisma ne?',
    );
    expect(mem.instruction, contains('tek hik'));
    expect(mem.instruction, contains('uydurma'));
    expect(mem.instruction.toLowerCase(), contains('mekanik'));
    expect(mem.instruction.toLowerCase(), isNot(contains('retrieval')));
  });

  test('assemble empty memoryPromptHint matches prior assemble', () {
    final base = CompanionContextSelect.assemble(
      userMessage: 'Bugun hava nasil?',
      turns: const [],
    );
    final empty = CompanionContextSelect.assemble(
      userMessage: 'Bugun hava nasil?',
      turns: const [],
      memoryPromptHint: '',
    );
    expect(empty, base);
  });

  test('assemble can surface non-empty memoryPromptHint as PREFERENCE', () {
    const prompt =
        'Cite a recurring observation only when the user message clearly '
        'touches it. Prefer silence over a memory dump.';
    final hint = CompanionContextSelect.assemble(
      userMessage: 'Bugun hava nasil?',
      turns: const [],
      memoryPromptHint: prompt,
    );
    expect(hint, contains('PREFERENCE'));
    expect(hint, contains('silence'));
  });
}
