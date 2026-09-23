/// Phase 4D — enricher idempotence / privacy / immutability unit tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import 'tarot_history_test_support.dart';
import 'tarot_narrative_request_enricher_fixtures.dart';

void main() {
  final now = nowFixed;

  group('TarotNarrativeRequestEnricher idempotence', () {
    test('re-enrichment is idempotent', () {
      final base = baseRequest();
      final history = enricherRichHistory(base, now);
      final a = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: history,
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      final b = TarotNarrativeRequestEnricher.enrich(
        base: a,
        history: history,
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(b.recurringCards.map((e) => e.evidenceId).toList(), [
        for (final e in a.recurringCards) e.evidenceId,
      ]);
      expect(b.memory.entries.map((e) => e.evidenceRef).toList(), [
        for (final e in a.memory.entries) e.evidenceRef,
      ]);
      expect(b.recurringThemes.map((e) => e.evidenceId).toList(), [
        for (final e in a.recurringThemes) e.evidenceId,
      ]);
      expect(b.memory.priorReadingCount, a.memory.priorReadingCount);
    });

    test('privacy revocation clears previously enriched evidence', () {
      final base = baseRequest();
      final history = enricherRichHistory(base, now);
      final enriched = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: history,
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(enriched.recurringCards, isNotEmpty);
      final wiped = TarotNarrativeRequestEnricher.enrich(
        base: enriched,
        history: history,
        currentOwnerId: null,
        privacyBlocked: true,
        now: now,
      );
      expect(wiped.memory.omitReason, 'privacy');
      expect(wiped.recurringCards, isEmpty);
      expect(wiped.recurringThemes, isEmpty);
      expect(wiped.memory.entries, isEmpty);
      expect(identical(wiped.question, base.question), isTrue);
    });

    test('result collections reject mutation', () {
      final base = baseRequest();
      final out = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: enricherRichHistory(base, now),
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(
        () => out.recurringCards.add(
          const TarotRecurringCardEvidence(
            evidenceId: 'x',
            canonicalCardId: 'y',
            occurrenceCount: 1,
            occurrences: [],
            contextsOverlap: false,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => out.recurringThemes.add(
          const TarotRecurringThemeEvidence(
            evidenceId: 'x',
            themeIdOrLabel: 'y',
            supportCount: 1,
            supportingReadingIds: [],
            relatedCardIds: [],
            relevanceToCurrentAsk: 0.5,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => out.memory.entries.add(
          const MemoryEvidenceEntry(
            evidenceRef: 'mem_99',
            kind: MemoryEvidenceKind.memorySummary,
            contentForModel: 'x',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('evidence namespaces do not collide with rel_', () {
      final base = baseRequest();
      final out = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: enricherRichHistory(base, now),
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(out.recurringCards.first.evidenceId, 'rec_card_01');
      expect(out.recurringThemes.first.evidenceId, 'rec_theme_01');
      expect(out.memory.entries.first.evidenceRef, 'mem_01');
    });
  });
}
