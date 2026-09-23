/// Exit referential integrity for enriched narrative requests (Phase 4D).
library;

import '../evidence/narrative_request.dart';
import 'tarot_connected_memory_eligibility.dart';
import 'tarot_historical_eligibility.dart';
import 'tarot_historical_models.dart';
import 'tarot_memory_evidence_engine.dart';

abstract final class TarotNarrativeEnrichmentValidation {
  TarotNarrativeEnrichmentValidation._();

  static void validate({
    required TarotNarrativeRequest request,
    required TarotHistoricalSnapshot history,
    required String? currentOwnerId,
    required DateTime now,
  }) {
    final eligibleTarot = TarotHistoricalEligibility.eligibleTarotReadings(
      readings: history.tarotReadings,
      currentReadingId: request.readingId,
      currentSessionId: request.sessionId,
      currentOwnerId: currentOwnerId,
      now: now,
      bounds: request.bounds,
    );
    final eligibleMem = TarotConnectedMemoryEligibility.eligible(
      records: history.connectedMemories,
      base: request,
      now: now,
    );
    final tarotIds = {for (final r in eligibleTarot) r.readingId};
    final memRefs = {for (final m in eligibleMem) m.typedSourceRef};
    final currentCards = {for (final c in request.cards) c.canonicalCardId};

    final cardIds = <String>{};
    for (final c in request.recurringCards) {
      if (!cardIds.add(c.evidenceId)) _fail();
      if (!currentCards.contains(c.canonicalCardId)) _fail();
      if (c.occurrences.length > request.bounds.maxRecurringOccurrencesListed) {
        _fail();
      }
      for (final o in c.occurrences) {
        if (!tarotIds.contains(o.readingId)) _fail();
      }
    }
    if (request.recurringCards.length > request.cards.length) _fail();

    final themeIds = <String>{};
    for (final t in request.recurringThemes) {
      if (!themeIds.add(t.evidenceId)) _fail();
      for (final id in t.relatedCardIds) {
        if (!currentCards.contains(id)) _fail();
      }
      for (final ref in t.supportingReadingIds) {
        if (!memRefs.contains(ref)) _fail();
      }
    }
    if (request.recurringThemes.length > request.bounds.maxThemeLabels) {
      _fail();
    }

    final memIds = <String>{};
    var memChars = 0;
    for (final e in request.memory.entries) {
      if (!memIds.add(e.evidenceRef)) _fail();
      if (e.contentForModel.length > 220) _fail();
      memChars += e.contentForModel.length;
      final st = e.sourceType;
      final sid = e.sourceId;
      if (st == null || sid == null) _fail();
      if (!memRefs.contains('$st:$sid')) _fail();
    }
    if (request.memory.entries.length >
        TarotMemoryEvidenceEngine.maxMemoryEntries) {
      _fail();
    }
    if (memChars > request.bounds.maxMemoryChars) _fail();

    final all = <String>{
      ...request.relationships.map((r) => r.evidenceId),
      ...memIds,
      ...cardIds,
      ...themeIds,
    };
    final expected =
        request.relationships.length +
        memIds.length +
        cardIds.length +
        themeIds.length;
    if (all.length != expected) _fail();
    for (final id in all) {
      final ok =
          id.startsWith('rel_') ||
          id.startsWith('mem_') ||
          id.startsWith('rec_card_') ||
          id.startsWith('rec_theme_');
      if (!ok) _fail();
    }
  }

  static Never _fail() =>
      throw StateError('tarot narrative enrichment invalid');
}
