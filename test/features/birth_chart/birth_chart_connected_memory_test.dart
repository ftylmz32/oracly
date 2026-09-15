import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_insight.dart';
import 'package:oracly_new/features/birth_chart/services/birth_chart_experience_service.dart';
import 'package:oracly_new/features/birth_chart/services/chart_insight_generator.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

class _IncompleteInsights extends ChartInsightGenerator {
  const _IncompleteInsights();

  @override
  List<ChartInsight> generate(BirthChart chart) => const [];
}

class _ThrowingMemoryStore extends OraclyMemoryStore {
  _ThrowingMemoryStore() : super(LocalStorage.ephemeral());

  @override
  Future<void> upsert(OraclyMemory memory) =>
      Future<void>.error(StateError('memory unavailable'));
}

BirthProfile _profile(int year, int month, int day) => BirthProfile(
  birthDate: DateTime(year, month, day),
  birthPlace: 'Istanbul',
  birthTimeKnown: false,
);

OraclyMemory _unrelated(DateTime at) => OraclyMemory(
  id: 'reading:dream:keep',
  kind: OraclyMemoryKind.reading,
  source: OraclyMemorySource(
    id: 'keep',
    type: OraclyReadingType.dream,
    occurredAt: at,
  ),
  summary: 'Deniz kenarinda sakinlik.',
  themes: const ['huzur'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Birth Chart/Yildizname authoritative memory seam', () {
    test(
      'incomplete interpretation is neither persisted nor indexed',
      () async {
        final storage = LocalStorage.ephemeral();
        final repository = LocalBirthChartRepository(storage);
        final memory = OraclyMemoryStore(storage);
        final service = BirthChartExperienceService(
          repository: repository,
          insightGenerator: const _IncompleteInsights(),
          memory: memory,
        );

        await expectLater(
          service.generate(_profile(1995, 8, 15)),
          throwsStateError,
        );

        expect(await repository.getLatest(), isNull);
        expect(memory.all(), isEmpty);
      },
    );

    test('completed interpretation writes bounded attributed memory', () async {
      final storage = LocalStorage.ephemeral();
      final repository = LocalBirthChartRepository(storage);
      final memory = OraclyMemoryStore(storage);
      final result = await BirthChartExperienceService(
        repository: repository,
        memory: memory,
      ).generate(_profile(1995, 8, 15));

      final item = memory.all().single;
      expect(item.source.id, result.chart.id);
      expect(item.source.type, OraclyReadingType.birthChart);
      expect(item.source.resultRef, result.chart.id);
      expect(item.summary, isNotEmpty);
      expect(item.summary.length, lessThanOrEqualTo(300));
      expect(item.summary, isNot(contains('Istanbul')));
    });

    test('memory failure cannot suppress completed chart', () async {
      final storage = LocalStorage.ephemeral();
      final repository = LocalBirthChartRepository(storage);
      final result = await BirthChartExperienceService(
        repository: repository,
        memory: _ThrowingMemoryStore(),
      ).generate(_profile(1992, 11, 10));

      expect(result.chart.insights, isNotEmpty);
      expect((await repository.getLatest())?.id, result.chart.id);
    });

    test(
      'same source upserts and replacement removes only superseded memory',
      () async {
        final storage = LocalStorage.ephemeral();
        final memory = OraclyMemoryStore(storage);
        final service = BirthChartExperienceService(
          repository: LocalBirthChartRepository(storage),
          memory: memory,
        );
        await memory.upsert(_unrelated(DateTime(2026, 9, 9)));

        final first = await service.generate(_profile(1995, 8, 15));
        await service.generate(_profile(1995, 8, 15));
        expect(
          memory.all().where((m) => m.source.id == first.chart.id),
          hasLength(1),
        );

        final second = await service.generate(_profile(1992, 11, 10));
        expect(memory.all().any((m) => m.source.id == first.chart.id), isFalse);
        expect(memory.all().any((m) => m.source.id == second.chart.id), isTrue);
        expect(memory.all().any((m) => m.source.id == 'keep'), isTrue);
      },
    );

    test(
      'clear removes source memory, preserves unrelated, and survives restart',
      () async {
        final storage = LocalStorage.ephemeral();
        final memory = OraclyMemoryStore(storage);
        final service = BirthChartExperienceService(
          repository: LocalBirthChartRepository(storage),
          memory: memory,
        );
        await memory.upsert(_unrelated(DateTime(2026, 9, 9)));
        final result = await service.generate(_profile(1995, 8, 15));

        final restarted = OraclyMemoryStore(storage);
        expect(
          restarted.all().any((m) => m.source.id == result.chart.id),
          isTrue,
        );

        await service.clearSavedData();
        expect(
          restarted.all().any((m) => m.source.id == result.chart.id),
          isFalse,
        );
        expect(restarted.all().any((m) => m.source.id == 'keep'), isTrue);
      },
    );

    test(
      'existing completed source is backfilled on load after upgrade',
      () async {
        final storage = LocalStorage.ephemeral();
        final repository = LocalBirthChartRepository(storage);
        final original = await BirthChartExperienceService(
          repository: repository,
        ).generate(_profile(1995, 8, 15));
        final memory = OraclyMemoryStore(storage);
        expect(memory.all(), isEmpty);

        final loaded = await BirthChartExperienceService(
          repository: repository,
          memory: memory,
        ).loadSaved();

        expect(loaded.chart?.id, original.chart.id);
        expect(memory.all().single.source.id, original.chart.id);
      },
    );
  });

  group('canonical cross-feature retrieval policy', () {
    test(
      'OR and Tarot retrieve related source but reject unrelated recall',
      () async {
        final now = DateTime(2026, 9, 9);
        final store = OraclyMemoryStore(LocalStorage.ephemeral());
        await store.upsert(
          OraclyMemory(
            id: 'reading:birthChart:chart-decision',
            kind: OraclyMemoryKind.reading,
            source: OraclyMemorySource(
              id: 'chart-decision',
              type: OraclyReadingType.birthChart,
              occurredAt: now,
              resultRef: 'chart-decision',
            ),
            summary:
                'Kararlari tartip acik iletisimle netlestirme ihtiyaci one cikti.',
            themes: const ['karar', 'iletisim'],
          ),
        );
        final retriever = OraclyMemoryRetriever(store);

        expect(
          retriever
              .retrieve(
                query: 'Daha once karar verme konusunda ne cikmisti?',
                now: now,
              )
              .items
              .single
              .memory
              .source
              .id,
          'chart-decision',
        );
        expect(
          retriever.forInterpretation(
            query: 'Iliskimde karar veremiyorum',
            currentType: OraclyReadingType.tarot,
          ),
          contains('chart-decision'),
        );
        expect(
          retriever.retrieve(query: 'Dun kahve ictim mi?', now: now).items,
          isEmpty,
        );
      },
    );

    test(
      'Coffee/Palm require current evidence before candidate injection',
      () async {
        final store = OraclyMemoryStore(LocalStorage.ephemeral());
        await store.upsert(
          OraclyMemory(
            id: 'reading:birthChart:chart-1',
            kind: OraclyMemoryKind.reading,
            source: OraclyMemorySource(
              id: 'chart-1',
              type: OraclyReadingType.birthChart,
              occurredAt: DateTime(2026, 9, 9),
            ),
            summary: 'Bir karar iki secenek arasinda netlesiyor.',
            themes: const ['karar'],
          ),
        );
        final retriever = OraclyMemoryRetriever(store);

        expect(
          retriever.forInterpretation(
            query: '',
            currentType: OraclyReadingType.coffee,
          ),
          isNull,
        );
        expect(
          retriever.forInterpretation(
            query: '',
            currentType: OraclyReadingType.palm,
            currentEvidence: const ['karar veren ikiye ayrilan cizgi'],
          ),
          contains('chart-1'),
        );
      },
    );

    test(
      'daily Astrology and calendar Star Map catalogue do not write memory',
      () {
        final store = OraclyMemoryStore(LocalStorage.ephemeral());
        final sign = AstrologyContentCatalogue.signs.first;

        AstrologyDailyReadingService.build(sign, now: DateTime(2026, 9, 9));
        StarMapReadingService.build(now: DateTime(2026, 9, 9));

        expect(store.all(), isEmpty);
      },
    );
  });
}
