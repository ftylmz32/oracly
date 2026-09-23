/// Phase 4D shadow — storage loader + enricher integration (no live Tarot path).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../narrative_evidence/narrative_evidence_test_support.dart';
import 'tarot_4c_test_support.dart';
import 'tarot_narrative_history_corpus_support.dart';
import 'tarot_narrative_storage_enrichment_shadow_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final phase3 = loadEvidenceCorpus();
  final relBase = (phase3['scenarios'] as List).cast<Map>().firstWhere(
    (s) => s['id'] == 'three_belonging_isolation_tr',
  );
  final foolBase = (phase3['scenarios'] as List).cast<Map>().firstWhere(
    (s) => s['id'] == 'single_open_fool_en',
  );
  final now = DateTime.parse('2026-09-23T12:00:00.000Z');

  test('A owner A valid history → enrichment appears', () async {
    SharedPreferences.setMockInitialValues({});
    final h = Phase4cHarness(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    await seedRichHistory(h, ownerId: 'A');
    final loaded = await h.loader().load(currentOwnerId: 'A');
    expect(loaded.privacyBlocked, isFalse);
    final out = TarotNarrativeRequestEnricher.enrich(
      base: buildBaseFromPhase3(Map<String, dynamic>.from(relBase)),
      history: loaded.snapshot,
      currentOwnerId: 'A',
      now: now,
    );
    expect(out.memory.included, isTrue);
    expect(
      out.recurringThemes.map((e) => e.evidenceId),
      contains('rec_theme_01'),
    );
    expect(out.memory.entries.map((e) => e.evidenceRef), contains('mem_01'));
  });

  test('B owner mismatch → privacyBlocked enrich → empty', () async {
    SharedPreferences.setMockInitialValues({});
    final h = Phase4cHarness(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    await seedRichHistory(h, ownerId: 'A');
    final loaded = await h.loader().load(currentOwnerId: 'B');
    final out = TarotNarrativeRequestEnricher.enrich(
      base: buildBaseFromPhase3(Map<String, dynamic>.from(relBase)),
      history: loaded.snapshot,
      currentOwnerId: 'B',
      now: now,
      privacyBlocked: loaded.privacyBlocked,
    );
    expect(out.recurringCards, isEmpty);
    expect(out.recurringThemes, isEmpty);
    expect(out.memory.omitReason, 'privacy');
  });

  test('C delete Tarot → recurrence gone after reload', () async {
    SharedPreferences.setMockInitialValues({});
    final h = Phase4cHarness(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    await seedRichHistory(h);
    final base = buildBaseFromPhase3(Map<String, dynamic>.from(foolBase));
    var snap = (await h.loader().load(currentOwnerId: null)).snapshot;
    expect(
      TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: snap,
        currentOwnerId: null,
        now: now,
      ).recurringCards.map((e) => e.evidenceId),
      contains('rec_card_01'),
    );
    await h.deletion().deleteReading('hist_s1');
    snap = (await h.loader().load(currentOwnerId: null)).snapshot;
    expect(
      TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: snap,
        currentOwnerId: null,
        now: now,
      ).recurringCards,
      isEmpty,
    );
  });

  test('D delete coffee source → theme gone, coffee memory gone', () async {
    SharedPreferences.setMockInitialValues({});
    final h = Phase4cHarness(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    await seedRichHistory(h);
    await CoffeeReadingStore(h.storage, memory: h.memory).delete('coffee_1');
    final out = TarotNarrativeRequestEnricher.enrich(
      base: buildBaseFromPhase3(Map<String, dynamic>.from(relBase)),
      history: (await h.loader().load(currentOwnerId: null)).snapshot,
      currentOwnerId: null,
      now: now,
    );
    expect(out.recurringThemes, isEmpty);
    expect(out.memory.entries.any((e) => e.sourceType == 'coffee'), isFalse);
  });

  test('E restart after delete preserves absence + ghost wipe', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final h = Phase4cHarness(LocalStorage(prefs));
    await seedRichHistory(h);
    await h.deletion().deleteReading('hist_s1');
    await CoffeeReadingStore(h.storage, memory: h.memory).delete('coffee_1');
    await h.memory.removeBySourceAndType('dream_1', OraclyReadingType.dream);
    final out = TarotNarrativeRequestEnricher.enrich(
      base: buildBaseFromPhase3(Map<String, dynamic>.from(relBase)),
      history: (await Phase4cHarness(
        LocalStorage(prefs),
      ).loader().load(currentOwnerId: null)).snapshot,
      currentOwnerId: null,
      now: now,
    );
    expect(out.recurringCards, isEmpty);
    expect(out.recurringThemes, isEmpty);
    expect(out.memory.entries, isEmpty);
  });
}
