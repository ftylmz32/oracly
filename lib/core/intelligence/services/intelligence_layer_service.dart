/// RC-009 — Intelligence layer facade for future personalization features.
library;

import '../../domain/models/conversation_record.dart';
import '../../domain/models/reading.dart';
import '../domain/models/favorite_card_ref.dart';
import '../domain/models/intelligence_snapshot.dart';
import '../domain/models/reflection_entry.dart';
import '../domain/models/ritual_history_entry.dart';
import '../domain/repositories/intelligence_repository.dart';

/// Entry point for Personal Insights, Reflection Timeline, Theme Analysis,
/// and Growth Journey — not wired to UI in RC-009.
class IntelligenceLayerService {
  const IntelligenceLayerService(this._repository);

  final IntelligenceRepository _repository;

  Future<IntelligenceSnapshot> snapshot() => _repository.loadSnapshot();

  Future<List<ReadingModel>> readings() => _repository.getReadings();

  Future<List<FavoriteCardRef>> favoriteCards() =>
      _repository.getFavoriteCards();

  Future<List<ReflectionEntry>> reflections() =>
      _repository.getReflections();

  Future<List<ConversationRecord>> conversations() =>
      _repository.getConversations();

  Future<List<RitualHistoryEntry>> ritualHistory() =>
      _repository.getRitualHistory();
}
