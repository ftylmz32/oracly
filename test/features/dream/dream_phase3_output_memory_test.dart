// Dream Phase 3 — client output firewall (one call, fail closed, nothing
// stored) and sensitive connected-memory omission.
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

DreamAiAnalysis _with(String extra) => DreamAiAnalysis(
      summary: phase2AllAccepted.summary,
      symbols: phase2AllAccepted.symbols,
      emotionalTheme: phase2AllAccepted.emotionalTheme,
      interpretation: phase2AllAccepted.interpretation,
      dailyLifeReflection: '${phase2AllAccepted.dailyLifeReflection} $extra',
      conclusion: phase2AllAccepted.conclusion,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final unsafe in [
    'Bu rüya şizofren olduğunu gösteriyor.',
    'Stop taking your medication; the dream shows you are healed.',
    'Сон подтверждает, что за тобой следят.',
    'Yaşadığın istismar karman yüzünden bir sebeple oldu.',
    'Bu rüya yakında öleceksin demek.',
  ]) {
    test('unsafe output fails closed after one call: $unsafe', () async {
      final ai = ScriptedDreamAi(_with(unsafe));
      final repo = MemDreamRepository();
      final service = DreamExperienceService(
        repository: repo,
        owner: testDreamOwner(),
        ai: ai,
      );
      await expectLater(
        service.analyze(narrative: phase2Narrative),
        throwsA(isA<AiRequestException>().having(
          (e) => e.failure.kind,
          'kind',
          AiFailureKind.invalidResponse,
        )),
      );
      expect(ai.contexts, hasLength(1));
      expect(await repo.getAll(), isEmpty);
    });
  }

  test('safe negations pass the client firewall', () async {
    final ai = ScriptedDreamAi(_with(
      'Rüyada ölüm görmek gerçek hayatta öleceğin anlamına gelmez. '
      'Bu rüya dış dünyada bir tehdidin gerçek olduğunu kanıtlamaz.',
    ));
    final repo = MemDreamRepository();
    final result = await DreamExperienceService(
      repository: repo,
      owner: testDreamOwner(),
      ai: ai,
    ).analyze(narrative: phase2Narrative);
    expect(result.dream.fromAi, isTrue);
    expect(await repo.getAll(), hasLength(1));
    expect(ai.contexts, hasLength(1));
  });

  test('sensitive memory is omitted from the request, never deleted',
      () async {
    Future<(String?, OraclyMemoryStore)> sent(String summary) async {
      final memory = OraclyMemoryStore(LocalStorage.ephemeral());
      await memory.upsert(OraclyMemory(
        id: 'reading:birthChart:chart-choice',
        kind: OraclyMemoryKind.reading,
        source: OraclyMemorySource(
          id: 'chart-choice',
          type: OraclyReadingType.birthChart,
          occurredAt: DateTime(2026, 9, 9),
        ),
        summary: summary,
        themes: const ['decision', 'communication'],
      ));
      final ai = ScriptedDreamAi.grounded();
      await DreamExperienceService(
        repository: MemDreamRepository(),
        owner: testDreamOwner(),
        ai: ai,
        memory: OraclyMemoryRetriever(memory),
      ).analyze(
        narrative:
            'I stood between two paths and tried to communicate my decision.',
      );
      expect(ai.contexts, hasLength(1));
      return (ai.contexts.single.memorySummary, memory);
    }

    final (safe, _) =
        await sent('A decision becomes clearer through communication.');
    expect(safe, contains('chart-choice'));

    final (omitted, store) = await sent(
      'A decision felt heavy; they wrote about suicide after communication broke.',
    );
    expect(omitted, isNull);
    expect(store.all(), hasLength(1));
  });
}
