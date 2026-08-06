/// RC-009 — Local intelligence repository — aggregates canonical stores.
library;

import '../../domain/models/conversation_record.dart';
import '../../domain/models/reading.dart';
import '../../domain/repositories/ai_conversation_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../../features/insights/services/personal_journey_service.dart';
import '../domain/models/favorite_card_ref.dart';
import '../domain/models/intelligence_facet_counts.dart';
import '../domain/models/intelligence_snapshot.dart';
import '../domain/models/reflection_entry.dart';
import '../domain/models/ritual_history_entry.dart';
import '../domain/repositories/intelligence_repository.dart';
import 'intelligence_index_store.dart';
import 'ritual_history_reader.dart';

class LocalIntelligenceRepository implements IntelligenceRepository {
  LocalIntelligenceRepository({
    required HistoryRepository history,
    required AiConversationRepository conversations,
    required RitualHistoryReader ritualHistory,
    required IntelligenceIndexStore indexStore,
    PersonalJourneyService journey = const PersonalJourneyService(),
  })  : _history = history,
        _conversations = conversations,
        _ritualHistory = ritualHistory,
        _indexStore = indexStore,
        _journey = journey;

  final HistoryRepository _history;
  final AiConversationRepository _conversations;
  final RitualHistoryReader _ritualHistory;
  final IntelligenceIndexStore _indexStore;
  final PersonalJourneyService _journey;

  @override
  Future<List<ReadingModel>> getReadings() => _history.getReadings();

  @override
  Future<List<FavoriteCardRef>> getFavoriteCards() async {
    final readings = await getReadings();
    return readings
        .where((reading) => reading.isFavorite)
        .map(
          (reading) => FavoriteCardRef(
            readingId: reading.id,
            cardName: reading.cardName,
            cardImageAsset: reading.cardImageAsset,
            favoritedAt: reading.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<List<ReflectionEntry>> getReflections() async {
    final entries = <ReflectionEntry>[];

    for (final reading in await getReadings()) {
      final note = reading.personalNote?.trim();
      if (note != null && note.isNotEmpty) {
        entries.add(
          ReflectionEntry(
            id: reading.id,
            source: JourneyReflectionSource.reading,
            recordedAt: reading.createdAt,
            text: note,
          ),
        );
      }
    }

    for (final ritual in _ritualHistory.readAll()) {
      final thought = ritual.personalThought?.trim();
      if (thought != null && thought.isNotEmpty) {
        entries.add(
          ReflectionEntry(
            id: 'ritual_${_dateKey(ritual.date)}',
            source: JourneyReflectionSource.ritual,
            recordedAt: ritual.date,
            text: thought,
          ),
        );
      }
    }

    entries.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return entries;
  }

  @override
  Future<List<ConversationRecord>> getConversations() =>
      _conversations.getAll();

  @override
  Future<List<RitualHistoryEntry>> getRitualHistory() async =>
      _ritualHistory.readAll();

  @override
  Future<IntelligenceSnapshot> loadSnapshot() async {
    final readings = await getReadings();
    final favoriteCards = await getFavoriteCards();
    final reflections = await getReflections();
    final conversations = await getConversations();
    final ritualDays = await getRitualHistory();
    final journey = _journey.compose(readings);

    final counts = IntelligenceFacetCounts(
      readings: readings.length,
      favoriteCards: favoriteCards.length,
      recurringThemes: journey.insightReport.recurringThemes.length,
      reflections: reflections.length,
      conversations: conversations.length,
      ritualDays: ritualDays.length,
    );

    final snapshot = IntelligenceSnapshot(
      builtAt: DateTime.now(),
      schemaVersion: IntelligenceSnapshot.currentSchemaVersion,
      counts: counts,
      journey: journey,
      favoriteCards: favoriteCards,
      reflections: reflections,
      conversations: conversations,
      ritualDays: ritualDays,
    );

    await _indexStore.save(
      IntelligenceIndexMeta(
        schemaVersion: snapshot.schemaVersion,
        builtAt: snapshot.builtAt,
        counts: counts,
      ),
    );

    return snapshot;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
