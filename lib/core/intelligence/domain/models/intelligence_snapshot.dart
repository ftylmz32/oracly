/// RC-009 — Unified journey snapshot composed from canonical stores.
library;

import '../../../../features/insights/models/personal_journey_snapshot.dart';
import 'favorite_card_ref.dart';
import 'intelligence_facet_counts.dart';
import 'reflection_entry.dart';
import 'ritual_history_entry.dart';
import '../../../domain/models/conversation_record.dart';

/// Read-only aggregate — no AI, no predictions. Built from persisted history.
class IntelligenceSnapshot {
  const IntelligenceSnapshot({
    required this.builtAt,
    required this.schemaVersion,
    required this.counts,
    required this.journey,
    required this.favoriteCards,
    required this.reflections,
    required this.conversations,
    required this.ritualDays,
  });

  static const int currentSchemaVersion = 1;

  final DateTime builtAt;
  final int schemaVersion;
  final IntelligenceFacetCounts counts;
  final PersonalJourneySnapshot journey;
  final List<FavoriteCardRef> favoriteCards;
  final List<ReflectionEntry> reflections;
  final List<ConversationRecord> conversations;
  final List<RitualHistoryEntry> ritualDays;

  bool get hasJourneyMemory => !counts.isEmpty;
}
