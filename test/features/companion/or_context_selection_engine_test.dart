/// Context Selection Engine — relevant buckets only, no dumps, no leaks.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/models/memory.dart';
import 'package:oracly_new/features/companion/models/memory_permission.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/companion/services/or_selected_context.dart';

void main() {
  test('buckets stay separate and styleHint omits unused layers', () {
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'İş konusunda sıkışıyorum.',
      recentMessages: const [],
      discoveryHint: 'Son keşiflerinde tekrar eden bir iz: kariyer. Kısa tut.',
      reflection: const ReflectionContext(
        userName: 'Fatih',
        proactiveAcknowledgment:
            'Son dönemde değişim konusu birkaç farklı keşfinde yeniden '
            'karşına çıkıyor.',
      ),
    );
    expect(selected.recentDiscovery, isNotNull);
    expect(selected.relevantMemory, isNull); // discovery wins
    expect(selected.stableUserFacts, isNull); // not a greeting
    expect(selected.currentMessage, contains('İş'));
    final hint = selected.toStyleHint();
    expect(hint.toLowerCase(), contains('kariyer'));
    expect(hint, contains('OBSERVATION'));
    expect(hint.toLowerCase(), contains('fact'));
    expect(hint.toLowerCase(), isNot(contains('değişim konusu')));
    expect(hint.toLowerCase(), isNot(contains('retrieval')));
    expect(hint.toLowerCase(), isNot(contains('stylehint')));
  });

  test('stable name fact only on greeting', () {
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'Selam',
      recentMessages: const [],
      reflection: const ReflectionContext(userName: 'Fatih'),
    );
    expect(selected.stableUserFacts, contains('Fatih'));
  });

  test('feature handoff is preferred as featureSpecific bucket', () {
    const handoff = 'Tarot\nSoru: Ne yapmalıyım?\nThe Fool, The Moon';
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'Bu açılım hakkında konuşalım.',
      recentMessages: const [],
      reflection: const ReflectionContext(proactiveAcknowledgment: handoff),
    );
    expect(selected.featureSpecific, contains('Tarot'));
    expect(selected.relevantMemory, isNull);
  });

  test('saved memory is one note max and only when overlapping', () {
    final note = Memory(
      id: '1',
      content: 'İş değişikliği için iki hafta düşüneceğim.',
      category: 'general',
      permission: MemoryPermission.saved,
      createdAt: DateTime(2026, 1, 1),
    );
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'İş değişikliği konusunda ne demiştim?',
      recentMessages: const [],
      reflection: ReflectionContext(savedMemories: [note]),
    );
    expect(selected.relevantMemory, isNotNull);
    expect(selected.relevantMemory!.toLowerCase(), contains('iş'));
    expect(selected.toStyleHint().length, lessThanOrEqualTo(480));
  });

  test('leak strip removes internal vocabulary', () {
    expect(
      OrContextLeakStrip.apply('Keep short. No retrieval or styleHint talk.'),
      isNot(contains('retrieval')),
    );
    expect(
      OrContextLeakStrip.apply('Keep short. No retrieval or styleHint talk.')
          .toLowerCase(),
      isNot(contains('stylehint')),
    );
  });

  test('recent messages are windowed not dumped into hint', () {
    final turns = [
      for (var i = 0; i < 12; i++)
        ConversationTurn(
          role: i.isEven
              ? ConversationTurn.userRole
              : ConversationTurn.assistantRole,
          text: 'Mesaj numarası $i ve biraz daha metin burada.',
        ),
    ];
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'Devam.',
      recentMessages: turns,
    );
    expect(selected.recentMessages.length, lessThanOrEqualTo(8));
    final hint = selected.toStyleHint();
    expect(hint.length, lessThanOrEqualTo(480));
    // Mid-window filler should not dominate; digest stays bounded.
    expect(hint, isNot(contains('Mesaj numarası 6')));
  });
}
