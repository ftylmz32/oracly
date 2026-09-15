import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_dream_repository.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/services/soul_mate_connected_memory.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';

import 'dream_honesty_fakes.dart';

class _CapturingDreamAi extends LiveDreamAiStub {
  DreamAiContext? context;
  int calls = 0;

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext value) async {
    calls++;
    context = value;
    return super.analyzeDream(value);
  }
}

class _ThrowingStorage extends LocalStorage {
  _ThrowingStorage() : super.ephemeral();

  @override
  List<String>? getStringList(String key) => throw StateError('unavailable');
}

OraclyMemory _memory({
  required String id,
  required OraclyReadingType type,
  required String summary,
  required List<String> themes,
}) => OraclyMemory(
  id: 'reading:${type.name}:$id',
  kind: OraclyMemoryKind.reading,
  source: OraclyMemorySource(
    id: id,
    type: type,
    occurredAt: DateTime(2026, 9, 9),
  ),
  summary: summary,
  themes: themes,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dream read-side connected memory', () {
    test(
      'current narrative selects cross-feature memory in the same AI call',
      () async {
        final memory = OraclyMemoryStore(LocalStorage.ephemeral());
        await memory.upsert(
          _memory(
            id: 'chart-choice',
            type: OraclyReadingType.birthChart,
            summary: 'A decision becomes clearer through communication.',
            themes: const ['decision', 'communication'],
          ),
        );
        await memory.upsert(
          _memory(
            id: 'old-dream',
            type: OraclyReadingType.dream,
            summary: 'Another dream about a decision.',
            themes: const ['decision'],
          ),
        );
        final ai = _CapturingDreamAi();

        await DreamExperienceService(
          repository: MemDreamRepository(),
          ai: ai,
          memory: OraclyMemoryRetriever(memory),
        ).analyze(
          narrative:
              'I stood between two paths and tried to communicate my decision.',
        );

        expect(ai.calls, 1);
        expect(ai.context?.memorySummary, contains('chart-choice'));
        expect(ai.context?.memorySummary, isNot(contains('old-dream')));
      },
    );

    test(
      'unrelated, unusable, and failed retrieval export no history',
      () async {
        final memory = OraclyMemoryStore(LocalStorage.ephemeral());
        await memory.upsert(
          _memory(
            id: 'career',
            type: OraclyReadingType.tarot,
            summary: 'A career decision is approaching.',
            themes: const ['career', 'decision'],
          ),
        );

        final unrelatedAi = _CapturingDreamAi();
        await DreamExperienceService(
          repository: MemDreamRepository(),
          ai: unrelatedAi,
          memory: OraclyMemoryRetriever(memory),
        ).analyze(narrative: 'A quiet house was surrounded by warm firelight.');
        expect(unrelatedAi.context?.memorySummary, isNull);

        final shortAi = _CapturingDreamAi();
        await DreamExperienceService(
          repository: MemDreamRepository(),
          ai: shortAi,
          memory: OraclyMemoryRetriever(memory),
        ).analyze(narrative: 'house');
        expect(shortAi.context?.memorySummary, isNull);

        final failingAi = _CapturingDreamAi();
        final result = await DreamExperienceService(
          repository: MemDreamRepository(),
          ai: failingAi,
          memory: OraclyMemoryRetriever(OraclyMemoryStore(_ThrowingStorage())),
        ).analyze(narrative: 'I had to communicate a difficult decision.');
        expect(result.dream.isAnalyzed, isTrue);
        expect(failingAi.calls, 1);
        expect(failingAi.context?.memorySummary, isNull);
      },
    );

    test(
      'Dream writer remains fail-soft when canonical storage fails',
      () async {
        final sourceStorage = LocalStorage.ephemeral();
        final repository = LocalDreamRepository(
          sourceStorage,
          memory: OraclyMemoryStore(_ThrowingStorage()),
        );

        final result = await DreamExperienceService(
          repository: repository,
          ai: _CapturingDreamAi(),
        ).analyze(narrative: 'A quiet window opened into a familiar room.');

        expect(await repository.getById(result.dream.id), isNotNull);
      },
    );
  });

  group('Soulmate read-side boundary', () {
    test(
      'explicit intention selects relevant non-Soulmate memory only',
      () async {
        final store = OraclyMemoryStore(LocalStorage.ephemeral());
        await store.upsert(
          _memory(
            id: 'coffee-communication',
            type: OraclyReadingType.coffee,
            summary: 'Open communication supports the relationship decision.',
            themes: const ['communication', 'relationship'],
          ),
        );
        await store.upsert(
          _memory(
            id: 'old-soulmate',
            type: OraclyReadingType.soulmate,
            summary: 'A relationship needs communication.',
            themes: const ['communication', 'relationship'],
          ),
        );

        final selected = SoulMateConnectedMemory.select(
          retriever: OraclyMemoryRetriever(store),
          intention: 'I want open communication in my relationship.',
        );

        expect(selected, contains('coffee-communication'));
        expect(selected, isNot(contains('old-soulmate')));
        expect(
          SoulMateConnectedMemory.select(
            retriever: OraclyMemoryRetriever(store),
            intention: 'A calm portrait with warm colors.',
          ),
          isNull,
        );
        expect(
          SoulMateConnectedMemory.select(
            retriever: OraclyMemoryRetriever(
              OraclyMemoryStore(_ThrowingStorage()),
            ),
            intention: 'I want open communication in my relationship.',
          ),
          isNull,
        );
      },
    );

    test(
      'memory is absent from portrait request and bounded to text request',
      () {
        final portrait = OpenAiPaidRequests.soulMateDraw(
          name: 'Ada',
          birthDate: '1990-01-01',
          intention: 'Open communication in a relationship',
        );
        final interpretation = OpenAiPaidRequests.soulMateInterpretation(
          name: 'Ada',
          birthDate: '1990-01-01',
          intention: 'Open communication in a relationship',
          memorySummary: '[coffee|2026-09-09|c1] Communication mattered.',
        );

        expect(portrait.payload, isNot(contains('memorySummary')));
        expect(interpretation.payload['memorySummary'], contains('[coffee|'));
      },
    );

    test(
      'Tarot, Coffee, and Palm participate only through matching intent',
      () async {
        for (final candidate in <(OraclyReadingType, String)>[
          (OraclyReadingType.tarot, 'messages'),
          (OraclyReadingType.coffee, 'boundaries'),
          (OraclyReadingType.palm, 'patience'),
        ]) {
          final store = OraclyMemoryStore(LocalStorage.ephemeral());
          await store.upsert(
            _memory(
              id: candidate.$1.name,
              type: candidate.$1,
              summary: 'The ${candidate.$2} theme was explicit.',
              themes: [candidate.$2],
            ),
          );
          final selected = SoulMateConnectedMemory.select(
            retriever: OraclyMemoryRetriever(store),
            intention:
                'I want to understand ${candidate.$2} in a relationship.',
          );
          expect(selected, contains(candidate.$1.name));
        }
      },
    );

    test(
      'non-authoritative result does not create canonical continuity',
      () async {
        final storage = LocalStorage.ephemeral();
        final memory = OraclyMemoryStore(storage);
        final documents = await Directory.systemTemp.createTemp('oracly-soul-');
        addTearDown(() => documents.delete(recursive: true));
        final saved = await SoulMateResultService(storage, memory: memory)
            .saveSuccessfulDraw(
              request: SoulMateDrawRequest(
                name: 'Ada',
                birthDate: DateTime(1990, 1, 1),
                intention: 'Open communication in a relationship',
              ),
              imageBytes: const [1, 2, 3, 4],
              documents: documents,
              parts: const SoulMateReadingParts(
                energy: 'partial',
                attraction: '',
                dynamics: '',
                feeling: '',
                yourSide: '',
                authoritative: false,
              ),
            );

        expect(saved, isNotNull);
        expect(saved?.hasAuthoritativeInterpretation, isFalse);
        expect(memory.all(), isEmpty);

        final authoritative =
            await SoulMateResultService(
              LocalStorage.ephemeral(),
              memory: OraclyMemoryStore(_ThrowingStorage()),
            ).saveSuccessfulDraw(
              request: SoulMateDrawRequest(
                name: 'Ada',
                birthDate: DateTime(1990, 1, 1),
                intention: 'Open communication in a relationship',
              ),
              imageBytes: const [5, 6, 7, 8],
              documents: documents,
              recordId: 'authoritative',
              parts: const SoulMateReadingParts(
                energy: 'Grounded energy with room for reflection.',
                attraction: 'Attraction grows through careful attention.',
                dynamics: 'The dynamic favors direct communication.',
                feeling: 'The overall feeling is calm and open.',
                yourSide: 'Clear boundaries remain important.',
                meeting: 'Meeting energy stays symbolic.',
                authoritative: true,
              ),
            );
        expect(authoritative?.hasAuthoritativeInterpretation, isTrue);
      },
    );
  });
}
