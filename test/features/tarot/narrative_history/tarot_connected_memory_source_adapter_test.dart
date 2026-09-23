/// Phase 4C — connected memory adapter + source-existence firewall.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_source_adapter.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_source_adapter.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_live_source_index.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../personal_discovery/pde_test_fixtures.dart';
import 'tarot_4c_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase4cHarness h;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    h = Phase4cHarness(LocalStorage(await SharedPreferences.getInstance()));
  });

  Future<List<TarotConnectedMemoryRecord>> loadMem() async {
    final historyResult = await TarotHistorySourceAdapter(
      history: h.history,
      tarotRepository: h.tarot,
    ).load(currentOwnerId: null);
    final live = await TarotLiveSourceIndex.build(
      storage: h.storage,
      tarotIds: historyResult.liveTarotSourceIds,
      dreams: h.dreams,
      birthCharts: h.birthCharts,
    );
    return TarotConnectedMemorySourceAdapter(
      memory: h.memory,
    ).load(liveSources: live).memories;
  }

  test('themes pass through OraclyMemory.themes only', () async {
    await CoffeeReadingStore(
      h.storage,
      memory: h.memory,
    ).save(pdeCoffee('c1', 'Fincan'));
    await h.memory.upsert(
      readingMemory(
        sourceId: 'c1',
        type: OraclyReadingType.coffee,
        themes: const ['karar', 'ilişki'],
        summary: '  Fincanda   karar  ',
      ),
    );
    final rows = await loadMem();
    expect(rows, hasLength(1));
    expect(rows.single.themeIds, ['karar', 'ilişki']);
    expect(rows.single.summary, 'Fincanda karar');
    expect(rows.single.epistemic, MemoryEvidenceEpistemic.interpretation);
    expect(rows.single.sourceType, TarotConnectedMemorySourceType.coffee);
  });

  test('stale memories excluded for every allowed type', () async {
    for (final type in OraclyReadingType.values) {
      if (type == OraclyReadingType.astrology ||
          type == OraclyReadingType.orConversation) {
        continue;
      }
      await h.memory.upsert(
        readingMemory(sourceId: 'stale_${type.name}', type: type),
      );
    }
    expect(await loadMem(), isEmpty);
  });

  test('live coffee/palm/dream appear; astrology excluded', () async {
    await CoffeeReadingStore(
      h.storage,
      memory: h.memory,
    ).save(pdeCoffee('c-live', 'Kahve'));
    await PalmReadingStore(
      h.storage,
      memory: h.memory,
    ).save(pdePalm('p-live', 'Avuç'));
    await h.dreams.save(pdeDream('d-live', 'Rüya'));
    await h.memory.upsert(
      readingMemory(sourceId: 'c-live', type: OraclyReadingType.coffee),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'p-live', type: OraclyReadingType.palm),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'd-live', type: OraclyReadingType.dream),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'a1', type: OraclyReadingType.astrology),
    );

    final rows = await loadMem();
    expect(rows.map((e) => e.sourceId).toSet(), {'c-live', 'p-live', 'd-live'});
  });

  test('soulmate requires authoritative interpretation', () async {
    await writeSoulMateMeta(h.storage, id: 'sm1', authoritative: false);
    await h.memory.upsert(
      readingMemory(sourceId: 'sm1', type: OraclyReadingType.soulmate),
    );
    expect(await loadMem(), isEmpty);

    await writeSoulMateMeta(h.storage, id: 'sm1', authoritative: true);
    final rows = await loadMem();
    expect(rows.single.sourceId, 'sm1');
    expect(rows.single.sourceType, TarotConnectedMemorySourceType.soulmate);
  });

  test('birth chart requires journey-ready mapped chart', () async {
    await h.memory.upsert(
      readingMemory(sourceId: 'bc1', type: OraclyReadingType.birthChart),
    );
    expect(await loadMem(), isEmpty);

    await saveJourneyChart(h.storage, 'bc1');
    expect((await loadMem()).single.sourceId, 'bc1');
  });

  test('tarot memory live via ReadingModel id or session id', () async {
    await h.readings.saveReading(
      journalReading(id: 'journal_1', sessionId: 'session_1'),
    );
    await h.tarot.saveSession(completedSession(id: 'session_1'));
    await h.memory.upsert(
      readingMemory(sourceId: 'journal_1', type: OraclyReadingType.tarot),
    );
    expect((await loadMem()).single.sourceId, 'journal_1');
  });
}
