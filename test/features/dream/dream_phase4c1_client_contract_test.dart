// Dream Phase 4C.1 — client parity contracts: emotional-theme role grounding
// and Cyrillic cross-feature memory retrieval (no recall fallback).
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

const _harbour = 'I walked along a quiet harbour at dusk. When the boat '
    'finally arrived I felt relieved and happy, and a little heavy inside.';

DreamAnalysisFacts _facts(String narrative, List<String> feelings) =>
    DreamAnalysisFacts.from(
      narrative: narrative,
      understanding: DreamUnderstandingService()
          .build(narrative: narrative, selectedEmotions: const [], language: 'en'),
      tags: const [],
      statedFeelings: feelings,
      language: 'en',
    );

Future<OraclyMemoryRetriever> _retriever(
    List<(String, OraclyReadingType, String, List<String>)> rows) async {
  final store = OraclyMemoryStore(LocalStorage.ephemeral());
  for (final (id, type, summary, themes) in rows) {
    await store.upsert(OraclyMemory(
      id: 'reading:${type.name}:$id',
      kind: OraclyMemoryKind.reading,
      source: OraclyMemorySource(
          id: id, type: type, occurredAt: DateTime(2026, 9, 1)),
      summary: summary,
      themes: themes,
    ));
  }
  return OraclyMemoryRetriever(store);
}

String? _recall(OraclyMemoryRetriever r, String dream) =>
    r.forInterpretation(query: dream, currentType: OraclyReadingType.dream);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('emotional theme role grounding', () {
    final facts = _facts(_harbour, const ['relieved', 'happy']);
    const theme = 'A mix of relief, happiness and a gentle heaviness.';

    test('a stated-feeling paraphrase speaks only in the emotional theme', () {
      expect(
          DreamAnalysisGuard.isSpeakable(theme, facts,
              role: DreamGuardRole.emotionalTheme),
          isTrue);
      expect(DreamAnalysisGuard.isSpeakable('A gentle heaviness and a mix.', facts),
          isFalse);
    });

    test('an unstated feeling is refused in every role', () {
      const invented = 'A lingering sense of isolation and hope.';
      for (final role in DreamGuardRole.values) {
        expect(DreamAnalysisGuard.isSpeakable(invented, facts, role: role),
            isFalse,
            reason: role.name);
      }
    });
  });

  group('Cyrillic memory retrieval', () {
    const dream = 'Я шла сквозь густой туман к перекрёстку двух дорог.';

    test('overlapping non-Dream memory arrives through ordinary retrieval',
        () async {
      final r = await _retriever([
        ('t1', OraclyReadingType.tarot, 'Карта говорила о тумане и выборе дороги.',
            ['туман']),
      ]);
      final text = _recall(r, dream);
      expect(text, contains('[tarot|2026-09-01|t1]'));
      expect(dream.toLowerCase(), isNot(contains('remember')));
    });

    test('unrelated Russian memory and Dream memory stay out', () async {
      final r = await _retriever([
        ('c1', OraclyReadingType.coffee, 'Чашка говорила о работе и деньгах.',
            ['работа']),
        ('d1', OraclyReadingType.dream, 'Густой туман у перекрёстка дорог.',
            ['туман']),
      ]);
      expect(_recall(r, dream), isNull);
    });

    test('Turkish and English retrieval are unchanged', () async {
      final r = await _retriever([
        ('t2', OraclyReadingType.tarot, 'Kart sisli bir yol ayrımından söz etti.',
            ['sis']),
        ('t3', OraclyReadingType.tarot, 'The card spoke of a lighthouse and fog.',
            ['lighthouse']),
      ]);
      expect(_recall(r, 'Rüyamda sisli bir yol ayrımındaydım.'),
          contains('t2'));
      expect(_recall(r, 'I dreamed of a lighthouse in the fog.'),
          contains('t3'));
    });
  });
}
