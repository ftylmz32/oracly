/// Memory deletion hard test — real data, no ghost state after restart.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_relevance.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_service.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_aggregator.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../personal_discovery/pde_test_fixtures.dart';

const _ghost = 'ZEPHYRKITE77';
const _theme = 'karar verme';
const _orQuestion =
    'Karar vermekte zorlanıyorum; keşiflerimde ne görüyordun?';

Future<({List<ReadingModel> readings, List<CoffeeReading> coffee})> _sources(
  LocalStorage storage,
) async {
  return (
    readings: await MockHistoryRepository(storage).getReadings(),
    coffee: CoffeeReadingStore(storage).all(),
  );
}

Future<PersonalDiscoveryProfile> _profileAsync(
  LocalStorage storage, {
  required DateTime now,
}) async {
  final src = await _sources(storage);
  return PersonalDiscoveryProfileBuilder.from(
    PersonalDiscoverySources(readings: src.readings, coffee: src.coffee),
    now: now,
  );
}

Future<List<DiscoveryJournalEntry>> _journalAsync(LocalStorage storage) async {
  final src = await _sources(storage);
  return DiscoveryJournalAggregator.merge(
    readings: src.readings,
    coffee: src.coffee,
  );
}

Future<void> _removeCoffee(LocalStorage storage, String id) async {
  final keep = CoffeeReadingStore(storage)
      .all()
      .where((c) => c.id != id)
      .map((c) => jsonEncode(c.toJson()))
      .toList();
  await storage.setStringList(CoffeeReadingStore.key, keep);
}

void _expectNoGhostToken(String blob) {
  expect(blob.toLowerCase(), isNot(contains(_ghost.toLowerCase())));
}

void _expectNoDiscoveryMemory({
  required PersonalDiscoveryProfile profile,
  required PersonalMemoryService memoryService,
}) {
  expect(profile.observedRecurringLabels, isNot(contains(_theme)));
  expect(DiscoveryOrContext.compact(profile), isNull);
  expect(
    PersonalMemoryRelevance.hintForMessage(profile, _orQuestion),
    isNull,
  );
  _expectNoGhostToken(jsonEncode(memoryService.load().toJson()));
  expect(memoryService.observationalLine(), isNull);
}

void main() {
  final now = DateTime(2026, 8, 20, 10);

  group('MEMORY DELETION HARD TEST', () {
    late SharedPreferences prefs;
    late LocalStorage storage;
    late HistoryService history;
    late PersonalMemoryService memory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorage(prefs);
      history = HistoryService(MockHistoryRepository(storage));
      memory = PersonalMemoryService(PersonalMemoryStore(storage));
    });

    test('create delete restart — no ghost memory in journal profile OR', () async {
      var deletePass = false;
      var noGhostPass = false;
      var persistencePass = false;

      // —— CREATE discovery ——
      final repo = MockHistoryRepository(storage);
      await repo.saveReading(
        pdeTarot('r1', '$_ghost Karar vermek zor.', at: now),
      );
      await repo.saveReading(
        pdeTarot('r2', 'Bu karar alma süreci netleşiyor $_ghost.', at: now),
      );
      await CoffeeReadingStore(storage).save(
        pdeCoffee('c1', 'Karar verip ilerlemek $_ghost.', at: now),
      );

      var profile = await _profileAsync(storage, now: now);
      await memory.reconcile(profile, preferredName: 'Fatih', now: now);

      // —— VERIFY memory exists ——
      expect(profile.observedRecurringLabels, contains(_theme));
      expect(DiscoveryOrContext.compact(profile), isNotNull);
      expect(
        PersonalMemoryRelevance.hintForMessage(profile, _orQuestion),
        isNotNull,
      );
      final journalBefore = await _journalAsync(storage);
      expect(journalBefore.map((e) => e.id), containsAll(['r1', 'r2', 'c1']));
      expect(memory.load().isEmpty, isFalse);

      // —— DELETE relevant history ——
      await history.remove('r1');
      await history.remove('r2');
      await _removeCoffee(storage, 'c1');
      expect(await history.getAll(), isEmpty);
      deletePass = true;

      // Simulate provider reload after PersonalDiscoveryRefresh.invalidate.
      profile = await _profileAsync(storage, now: now);
      await memory.reconcile(profile, preferredName: 'Fatih', now: now);

      // —— VERIFY journal profile OR context ——
      final journalAfter = await _journalAsync(storage);
      expect(journalAfter, isEmpty);
      expect(profile.hasHistory, isFalse);
      _expectNoDiscoveryMemory(profile: profile, memoryService: memory);

      const or = CompanionResponder();
      expect(
        DiscoveryOrContext.compactForMessage(profile, _orQuestion),
        isNull,
      );
      final mergedHint = CompanionThreadMemory.merge(
        discovery: null,
        turns: const [],
        current: _orQuestion,
      );
      _expectNoGhostToken(mergedHint);
      expect(mergedHint.toLowerCase(), isNot(contains('tekrar etmiş')));

      final orReply = or.respond(
        request: const InsightRequest(text: _orQuestion),
        context: ReflectionContext(
          recurringThemes: DiscoveryOrContext.themeLabels(profile),
          proactiveAcknowledgment: memory.observationalLine(),
        ),
      );
      _expectNoGhostToken(orReply.body);
      expect(orReply.body.toLowerCase(), isNot(contains('son keşif')));
      expect(orReply.body.toLowerCase(), isNot(contains('tekrar etmiş')));

      noGhostPass = true;

      // —— RESTART app (new service instances, same prefs) ——
      final restartedStorage = LocalStorage(prefs);
      final restartedHistory = HistoryService(MockHistoryRepository(restartedStorage));
      final restartedMemory =
          PersonalMemoryService(PersonalMemoryStore(restartedStorage));

      expect(await restartedHistory.getAll(), isEmpty);
      final restartedProfile =
          await _profileAsync(restartedStorage, now: now);
      await restartedMemory.reconcile(restartedProfile, now: now);

      expect(restartedProfile.observedRecurringLabels, isNot(contains(_theme)));
      _expectNoDiscoveryMemory(
        profile: restartedProfile,
        memoryService: restartedMemory,
      );
      _expectNoGhostToken(storage.getString(PersonalMemoryStore.key) ?? '');

      final restartedJournal = await _journalAsync(restartedStorage);
      expect(restartedJournal, isEmpty);

      persistencePass = true;

      // —— FINAL GATES ——
      expect(deletePass, isTrue, reason: 'DELETE');
      expect(noGhostPass, isTrue, reason: 'NO GHOST MEMORY');
      expect(persistencePass, isTrue, reason: 'PERSISTENCE');
    });
  });
}
