/// Long-term memory boundaries — FACT/OBSERVATION/INTERPRETATION/PREFERENCE.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/intelligence/domain/models/personal_memory_summary.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_or_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_persona_contract.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/models/memory.dart';
import 'package:oracly_new/features/companion/models/memory_permission.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/companion/services/or_long_term_memory_boundaries.dart';
import 'package:oracly_new/features/companion/services/or_response_finalize.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('tags keep epistemic kinds distinct', () {
    expect(
      OrLongTermMemoryBoundaries.tag(OrMemoryKind.fact, 'Ad: Fatih'),
      startsWith('FACT:'),
    );
    expect(
      OrLongTermMemoryBoundaries.tag(OrMemoryKind.observation, 'tema: değişim'),
      startsWith('OBSERVATION:'),
    );
    expect(
      OrLongTermMemoryBoundaries.tag(
        OrMemoryKind.interpretation,
        'Tarot: The Moon',
      ),
      startsWith('INTERPRETATION:'),
    );
    expect(
      OrLongTermMemoryBoundaries.tag(OrMemoryKind.preference, 'direct'),
      startsWith('PREFERENCE:'),
    );
  });

  test('styleHint adds boundaries only when long-term context is used', () {
    final withDiscovery = OrContextSelectionEngine.styleHint(
      currentMessage: 'İş konusunda sıkışıyorum.',
      recentMessages: const [],
      discoveryHint: 'Son keşiflerinde tekrar eden bir iz: kariyer.',
    );
    expect(withDiscovery, contains('OBSERVATION'));
    expect(withDiscovery.toLowerCase(), contains('sembolik'));
    expect(withDiscovery.toLowerCase(), isNot(contains('retrieval')));
    expect(withDiscovery.toLowerCase(), isNot(contains('database')));

    final bare = OrContextSelectionEngine.styleHint(
      currentMessage: 'Merhaba',
      recentMessages: const [],
    );
    // Thread guidance may exist; long-term boundary prompt should not.
    expect(bare.contains('FACT / OBSERVATION'), isFalse);
  });

  test('feature handoff is INTERPRETATION not FACT', () {
    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'Bu açılım hakkında konuşalım.',
      recentMessages: const [],
      reflection: const ReflectionContext(
        proactiveAcknowledgment: 'Tarot\nSoru: Ne yapmalıyım?\nThe Moon',
      ),
    );
    expect(hint, contains('INTERPRETATION'));
    expect(hint, isNot(contains('FACT: Tarot')));
  });

  test('saved note recall requires relevance; no invention', () {
    const or = CompanionResponder();
    final miss = or.respond(
      request: const InsightRequest(text: 'Bunu hatırlıyor musun?'),
      context: ReflectionContext(
        savedMemories: [
          Memory(
            id: '1',
            content: 'Patronla sınır konuşması',
            category: 'work',
            permission: MemoryPermission.saved,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );
    expect(miss.body.toLowerCase(), isNot(contains('patron')));
    expect(miss.body.toLowerCase(), contains('uydur'));

    final hit = or.respond(
      request: const InsightRequest(text: 'Patron sınır notumu hatırlıyor musun?'),
      context: ReflectionContext(
        savedMemories: [
          Memory(
            id: '1',
            content: 'Patronla sınır konuşması',
            category: 'work',
            permission: MemoryPermission.saved,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );
    expect(hit.body.toLowerCase(), contains('sınır'));
  });

  test('persona and memory copy forbid symbolic-as-fact and DB talk', () {
    final id = OrPersonaContract.identityTr.toLowerCase();
    expect(id, contains('fact'));
    expect(id, contains('anı uydurma'));
    final instr = PersonalMemoryOrCopy.instruction(
      const PersonalMemorySummary(sunSign: 'Aries', themes: []),
    )!;
    expect(instr.toLowerCase(), contains('observation'));
    expect(instr.toLowerCase(), contains('interpretation'));
    expect(instr.toLowerCase(), contains('preference'));
    expect(instr.toLowerCase(), contains('symbolic'));
    expect(instr.toLowerCase(), contains('databases'));
  });

  test('finalize strips database language from user-facing body', () {
    final out = OrResponseFinalize.forMessage(
      'Bu bir observation. Veritabanı kaydına göre böyle.',
    );
    expect(out.toLowerCase(), isNot(contains('veritabanı')));
    expect(out.toLowerCase(), isNot(contains('database')));
  });
}
