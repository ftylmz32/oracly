/// RC-009 — Intelligence layer foundation tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/ritual_journal_metadata.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/domain/models/intelligence_snapshot.dart';
import 'package:oracly_new/core/intelligence/domain/models/journey_facet.dart';
import 'package:oracly_new/core/intelligence/domain/models/reflection_entry.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RitualHistoryReader', () {
    late LocalStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'daily_ritual_reflection_2026-08-01': true,
        'daily_ritual_card_2026-08-01': true,
        'daily_ritual_thought_2026-08-02': 'Sakin bir sabah.',
      });
      storage = LocalStorage(await SharedPreferences.getInstance());
    });

    test('reads engaged ritual days from existing keys', () {
      final reader = RitualHistoryReader(storage);
      final entries = reader.readAll();

      expect(entries.length, 2);
      expect(entries.first.date, DateTime(2026, 8, 2));
      expect(entries.first.personalThought, 'Sakin bir sabah.');
      expect(entries.last.reflectionRead, isTrue);
      expect(entries.last.cardDrawn, isTrue);
    });
  });

  group('LocalIntelligenceRepository', () {
    late LocalStorage storage;
    late LocalIntelligenceRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'daily_ritual_thought_2026-08-06': 'Bugün meraklıyım.',
      });
      storage = LocalStorage(await SharedPreferences.getInstance());
      final history = MockHistoryRepository(storage);
      await history.saveReading(
        ReadingModel(
          id: 'r1',
          cardId: 1,
          cardName: 'The Fool',
          cardImageAsset: 'assets/fool.png',
          spreadType: 'Tek Kart',
          aiSummary: 'Yeni bir başlangıç.',
          createdAt: DateTime(2026, 8, 1),
          journal: const RitualJournalMetadata(
            isFavorite: true,
            personalNote: 'İlk notum.',
            tags: ['insight:love'],
          ),
        ),
      );
      await history.saveReading(
        ReadingModel(
          id: 'r2',
          cardId: 2,
          cardName: 'The Magician',
          cardImageAsset: 'assets/magician.png',
          spreadType: 'Tek Kart',
          aiSummary: 'Aşk ve niyet bir arada.',
          createdAt: DateTime(2026, 8, 3),
          journal: const RitualJournalMetadata(
            tags: ['insight:love'],
          ),
        ),
      );
      await history.saveReading(
        ReadingModel(
          id: 'r3',
          cardId: 3,
          cardName: 'The Lovers',
          cardImageAsset: 'assets/lovers.png',
          spreadType: 'Tek Kart',
          aiSummary: 'Sevgi ve bağ üzerine.',
          createdAt: DateTime(2026, 8, 5),
          journal: const RitualJournalMetadata(
            tags: ['insight:love'],
          ),
        ),
      );

      final conversations = LocalAiConversationRepository(storage);
      await conversations.save(
        ConversationRecord(
          id: 'c1',
          title: 'Oracle',
          kind: 'oracle',
          messagesJson: const [
            {'role': 'user', 'text': 'Merhaba'},
          ],
          createdAt: DateTime(2026, 8, 4),
          updatedAt: DateTime(2026, 8, 4),
        ),
      );

      repository = LocalIntelligenceRepository(
        history: history,
        conversations: conversations,
        ritualHistory: RitualHistoryReader(storage),
        indexStore: IntelligenceIndexStore(storage),
      );
    });

    test('aggregates readings, favorites, reflections, themes, ritual, chat', () async {
      final snapshot = await repository.loadSnapshot();

      expect(snapshot.schemaVersion, IntelligenceSnapshot.currentSchemaVersion);
      expect(snapshot.counts.readings, 3);
      expect(snapshot.counts.favoriteCards, 1);
      expect(snapshot.counts.reflections, 2);
      expect(snapshot.counts.conversations, 1);
      expect(snapshot.counts.ritualDays, 1);
      expect(snapshot.counts.recurringThemes, 1);
      expect(snapshot.journey.totalReadings, 3);
      expect(snapshot.hasJourneyMemory, isTrue);
    });

    test('reflections include reading notes and ritual thoughts', () async {
      final reflections = await repository.getReflections();

      expect(reflections.length, 2);
      expect(
        reflections.any(
          (entry) =>
              entry.source == JourneyReflectionSource.reading &&
              entry.text == 'İlk notum.',
        ),
        isTrue,
      );
      expect(
        reflections.any(
          (entry) =>
              entry.source == JourneyReflectionSource.ritual &&
              entry.text == 'Bugün meraklıyım.',
        ),
        isTrue,
      );
    });

    test('persists index metadata after snapshot build', () async {
      await repository.loadSnapshot();
      final index = IntelligenceIndexStore(storage).load();

      expect(index, isNotNull);
      expect(index!.counts.readings, 3);
      expect(index.counts.conversations, 1);
    });

    test('facet counts map to journey dimensions', () async {
      final snapshot = await repository.loadSnapshot();

      expect(
        snapshot.counts.countFor(JourneyFacet.readings),
        snapshot.counts.readings,
      );
      expect(
        snapshot.counts.countFor(JourneyFacet.ritualHistory),
        snapshot.counts.ritualDays,
      );
    });
  });

  group('IntelligenceLayerService', () {
    test('delegates to repository without AI coupling', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final repository = LocalIntelligenceRepository(
        history: MockHistoryRepository(storage),
        conversations: LocalAiConversationRepository(storage),
        ritualHistory: RitualHistoryReader(storage),
        indexStore: IntelligenceIndexStore(storage),
      );
      final service = IntelligenceLayerService(repository);

      final snapshot = await service.snapshot();
      expect(snapshot.counts.isEmpty, isTrue);
      expect(await service.readings(), isEmpty);
    });
  });
}
