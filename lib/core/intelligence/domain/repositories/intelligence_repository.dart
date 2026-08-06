/// RC-009 — Intelligence layer repository — storage only, never AI.
library;

import '../../../domain/models/conversation_record.dart';
import '../../../domain/models/reading.dart';
import '../models/intelligence_snapshot.dart';
import '../models/reflection_entry.dart';
import '../models/ritual_history_entry.dart';
import '../models/favorite_card_ref.dart';

/// Canonical read surface for long-term personalization data.
///
/// Implementations aggregate existing stores. AI services must not write here
/// directly — they persist through domain repositories (history, ritual, chat).
abstract class IntelligenceRepository {
  /// Composes a full snapshot from all journey facets.
  Future<IntelligenceSnapshot> loadSnapshot();

  Future<List<ReadingModel>> getReadings();

  Future<List<FavoriteCardRef>> getFavoriteCards();

  Future<List<ReflectionEntry>> getReflections();

  Future<List<ConversationRecord>> getConversations();

  Future<List<RitualHistoryEntry>> getRitualHistory();
}
