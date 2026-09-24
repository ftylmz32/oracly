/// Phase 6C — relationship / recurrence / memory / policy prompt DTO parts.
library;

final class NarrativePromptRelationship {
  const NarrativePromptRelationship({
    required this.leftCardId,
    required this.rightCardId,
    required this.leftPositionKey,
    required this.rightPositionKey,
    required this.kind,
    required this.strength,
  });

  final String leftCardId;
  final String rightCardId;
  final String leftPositionKey;
  final String rightPositionKey;
  final String kind;
  final double strength;
}

final class NarrativePromptOccurrence {
  const NarrativePromptOccurrence({
    required this.occurredAtUtc,
    required this.spreadId,
    required this.positionKey,
    required this.orientationKnown,
    required this.isReversed,
    this.intentionSummary,
  });

  final String occurredAtUtc;
  final String spreadId;
  final String positionKey;
  final bool orientationKnown;
  final bool? isReversed;
  final String? intentionSummary;
}

final class NarrativePromptRecurringCard {
  NarrativePromptRecurringCard({
    required this.canonicalCardId,
    required this.occurrenceCount,
    required this.contextsOverlap,
    required this.overlapSummaryKey,
    required List<NarrativePromptOccurrence> occurrences,
  }) : occurrences =
           List<NarrativePromptOccurrence>.unmodifiable(occurrences);

  final String canonicalCardId;
  final int occurrenceCount;
  final bool contextsOverlap;
  final String? overlapSummaryKey;
  final List<NarrativePromptOccurrence> occurrences;
}

final class NarrativePromptRecurringTheme {
  NarrativePromptRecurringTheme({
    required this.themeIdOrLabel,
    required this.supportCount,
    required List<String> relatedCardIds,
    required this.relevanceToCurrentAsk,
  }) : relatedCardIds = List<String>.unmodifiable(relatedCardIds);

  final String themeIdOrLabel;
  final int supportCount;
  final List<String> relatedCardIds;
  final double relevanceToCurrentAsk;
}

final class NarrativePromptMemoryEntry {
  const NarrativePromptMemoryEntry({
    required this.kind,
    required this.contentForModel,
    this.sourceType,
    this.occurredAtUtc,
    this.confidence,
    this.epistemic,
  });

  final String kind;
  final String contentForModel;
  final String? sourceType;
  final String? occurredAtUtc;
  final double? confidence;
  final String? epistemic;
}

final class NarrativePromptMemory {
  NarrativePromptMemory({
    required this.included,
    required this.priorReadingCount,
    required List<NarrativePromptMemoryEntry> entries,
  }) : entries = List<NarrativePromptMemoryEntry>.unmodifiable(entries);

  final bool included;
  final int priorReadingCount;
  final List<NarrativePromptMemoryEntry> entries;
}

final class NarrativePromptPolicy {
  NarrativePromptPolicy({
    required this.version,
    required List<String> rules,
  }) : rules = List<String>.unmodifiable(rules);

  final String version;
  final List<String> rules;

  static final v1 = NarrativePromptPolicy(
    version: 'narrative_policy_v1',
    rules: const [
      'do_not_invent_cards',
      'do_not_invent_position_roles',
      'do_not_invent_relationships',
      'do_not_invent_recurrence',
      'do_not_invent_memory_or_history',
      'no_deterministic_prophecy',
      'distinguish_evidence_from_reflective_guidance',
      'answer_in_requested_language',
      'do_not_expose_internal_identifiers',
    ],
  );
}
