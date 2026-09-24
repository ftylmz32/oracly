/// Phase 6C — request evidence → prompt DTO field mappers.
library;

import '../../../../core/l10n/l10n_triple.dart';
import '../evidence/narrative_card_evidence.dart';
import '../evidence/narrative_memory_evidence.dart';
import '../evidence/narrative_recurrence_evidence.dart';
import '../evidence/narrative_relationship_evidence.dart';
import '../evidence/narrative_spread_semantics.dart';
import 'narrative_tarot_prompt_evidence_parts.dart';
import 'narrative_tarot_prompt_parts.dart';

abstract final class NarrativeTarotPromptMappers {
  NarrativeTarotPromptMappers._();

  static NarrativePromptSpread spread(SpreadSemanticDefinition s) {
    final positions = [...s.positions]
      ..sort((a, b) => a.index.compareTo(b.index));
    return NarrativePromptSpread(
      spreadId: s.spreadId,
      cardCount: s.cardCount,
      geometryHook: s.geometryHook.name,
      lengthBand: s.lengthBand.name,
      interpretationOrder: s.interpretationOrder,
      positions: [
        for (final p in positions)
          NarrativePromptPosition(
            positionKey: p.positionKey,
            index: p.index,
            role: p.role.name,
            temporal: p.temporal.name,
          ),
      ],
    );
  }

  static NarrativePromptCard card(
    TarotNarrativeCardEvidence c,
    String lang,
  ) {
    final s = c.profileSlice;
    return NarrativePromptCard(
      canonicalCardId: c.canonicalCardId,
      displayName: c.displayName,
      isReversed: c.isReversed,
      positionKey: c.positionKey,
      positionIndex: c.positionIndex,
      coreMeaning: s.coreMeaning.of(lang),
      orientationExpression: s.orientationExpression.of(lang),
      keywordIds: s.keywordIds,
      symbolTags: s.symbolTags,
      transforms: [for (final t in s.transforms) t.name],
      light: _loc(s.light, lang),
      shadow: _loc(s.shadow, lang),
      tension: _loc(s.tension, lang),
      desire: _loc(s.desire, lang),
      fear: _loc(s.fear, lang),
      relationshipDynamic: _loc(s.relationshipDynamic, lang),
      decisionDynamic: _loc(s.decisionDynamic, lang),
      actionDirection: _loc(s.actionDirection, lang),
    );
  }

  static NarrativePromptRelationship relationship(
    TarotNarrativeRelationshipEvidence r,
  ) {
    return NarrativePromptRelationship(
      leftCardId: r.leftCardId,
      rightCardId: r.rightCardId,
      leftPositionKey: r.leftPositionKey,
      rightPositionKey: r.rightPositionKey,
      kind: r.kind.name,
      strength: r.strength,
    );
  }

  static NarrativePromptRecurringCard recurringCard(
    TarotRecurringCardEvidence r,
  ) {
    return NarrativePromptRecurringCard(
      canonicalCardId: r.canonicalCardId,
      occurrenceCount: r.occurrenceCount,
      contextsOverlap: r.contextsOverlap,
      overlapSummaryKey: r.overlapSummaryKey,
      occurrences: [
        for (final o in r.occurrences)
          NarrativePromptOccurrence(
            occurredAtUtc: o.at.toUtc().toIso8601String(),
            spreadId: o.spreadId,
            positionKey: o.positionKey,
            orientationKnown: o.orientationKnown,
            isReversed: o.orientationKnown ? o.isReversed : null,
            intentionSummary: o.intentionSummary,
          ),
      ],
    );
  }

  static NarrativePromptRecurringTheme recurringTheme(
    TarotRecurringThemeEvidence t,
  ) {
    return NarrativePromptRecurringTheme(
      themeIdOrLabel: t.themeIdOrLabel,
      supportCount: t.supportCount,
      relatedCardIds: t.relatedCardIds,
      relevanceToCurrentAsk: t.relevanceToCurrentAsk,
    );
  }

  static NarrativePromptMemory memory(TarotNarrativeMemoryEvidence m) {
    if (!m.included) {
      return NarrativePromptMemory(
        included: false,
        priorReadingCount: m.priorReadingCount,
        entries: const [],
      );
    }
    return NarrativePromptMemory(
      included: true,
      priorReadingCount: m.priorReadingCount,
      entries: [
        for (final e in m.entries)
          NarrativePromptMemoryEntry(
            kind: e.kind.name,
            contentForModel: e.contentForModel,
            sourceType: e.sourceType,
            occurredAtUtc: e.occurredAt?.toUtc().toIso8601String(),
            confidence: e.confidence,
            epistemic: e.epistemic?.name,
          ),
      ],
    );
  }

  static String? _loc(L10nTriple? t, String lang) => t?.of(lang);
}
