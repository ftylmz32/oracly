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
      OrContextLeakStrip.apply(
        'Keep short. No retrieval or styleHint talk.',
      ).toLowerCase(),
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

  test('empty memoryPromptHint leaves styleHint unchanged', () {
    final without = OrContextSelectionEngine.styleHint(
      currentMessage: 'Bugun nasilsin?',
      recentMessages: const [],
    );
    final withEmpty = OrContextSelectionEngine.styleHint(
      currentMessage: 'Bugun nasilsin?',
      recentMessages: const [],
      memoryPromptHint: '',
    );
    final withNull = OrContextSelectionEngine.styleHint(
      currentMessage: 'Bugun nasilsin?',
      recentMessages: const [],
      memoryPromptHint: null,
    );
    expect(withEmpty, without);
    expect(withNull, without);
  });

  test('non-empty memoryPromptHint enters as PREFERENCE soft guidance', () {
    const hintBody =
        'Cite a recurring observation only when the user message clearly '
        'touches it. Prefer silence over a memory dump.';
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'Bugun nasilsin?',
      recentMessages: const [],
      memoryPromptHint: hintBody,
    );
    expect(selected.preferenceHint, contains('PREFERENCE'));
    expect(selected.preferenceHint, contains('silence'));
    final style = selected.toStyleHint();
    expect(style, contains('PREFERENCE'));
    expect(style, contains('silence'));
  });

  test('feature handoff stays ahead of memoryPromptHint', () {
    const handoff = 'Tarot\nSoru: Ne yapmalıyım?\nThe Fool, The Moon';
    const prompt =
        'Cite a recurring observation only when the user message clearly '
        'touches it. Prefer silence over a memory dump.';
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'Bu açılım hakkında konuşalım.',
      recentMessages: const [],
      reflection: const ReflectionContext(proactiveAcknowledgment: handoff),
      memoryPromptHint: prompt,
    );
    expect(selected.featureSpecific, contains('Tarot'));
    expect(selected.relevantMemory, isNull);
    expect(selected.preferenceHint, contains('PREFERENCE'));
    final style = selected.toStyleHint();
    expect(
      style.indexOf('INTERPRETATION'),
      lessThan(style.indexOf('PREFERENCE')),
    );
    expect(style, contains('Tarot'));
  });

  test('discovery still wins over observation; promptHint stays soft', () {
    const prompt =
        'Cite a recurring observation only when the user message clearly '
        'touches it. Prefer silence over a memory dump.';
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'İş konusunda sıkışıyorum.',
      recentMessages: const [],
      discoveryHint: 'Son keşiflerinde tekrar eden bir iz: kariyer. Kısa tut.',
      reflection: const ReflectionContext(
        proactiveAcknowledgment:
            'Son dönemde değişim konusu birkaç farklı keşfinde yeniden '
            'karşına çıkıyor.',
      ),
      memoryPromptHint: prompt,
    );
    expect(selected.recentDiscovery, isNotNull);
    expect(selected.relevantMemory, isNull);
    expect(selected.preferenceHint, contains('silence'));
    final style = selected.toStyleHint();
    expect(style.toLowerCase(), contains('kariyer'));
    expect(style.toLowerCase(), isNot(contains('değişim konusu')));
  });

  test('skips promptHint when proactive observation already fills memory', () {
    const obs =
        'Son dönemde karar verme konusu birkaç farklı keşfinde yeniden '
        'karşına çıkıyor. Bunu tek bir sonuca bağlamazdım.';
    const prompt =
        'Cite a recurring observation only when the user message clearly '
        'touches it. Prefer silence over a memory dump.';
    final selected = OrContextSelectionEngine.select(
      currentMessage: 'Bu karar konusunda ne düşünüyorsun?',
      recentMessages: const [],
      reflection: const ReflectionContext(proactiveAcknowledgment: obs),
      memoryPromptHint: prompt,
    );
    expect(selected.relevantMemory, isNotNull);
    expect(selected.relevantMemory!.toLowerCase(), contains('karar'));
    expect(selected.preferenceHint, isNull);
  });
}

