/// Phase 6C.2 — canonical bounds cannot loosen policy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  test('above-defaults request bounds rejected', () {
    final base = buildFromCorpusId('single_open_fool_en');
    final d = RequestBounds.defaults;
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          base,
          bounds: RequestBounds(
            maxPriorReadingsScanned: d.maxPriorReadingsScanned,
            maxRecurringOccurrencesListed: d.maxRecurringOccurrencesListed,
            maxRelationships: d.maxRelationships,
            maxMemoryChars: d.maxMemoryChars + 1,
            maxThemeLabels: d.maxThemeLabels,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('stricter non-negative bounds pass', () {
    final base = buildFromCorpusId('single_open_fool_en');
    final input = NarrativeTarotPromptSerializer.serialize(
      copyRequest(
        base,
        bounds: const RequestBounds(
          maxPriorReadingsScanned: 5,
          maxRecurringOccurrencesListed: 2,
          maxRelationships: 3,
          maxMemoryChars: 200,
          maxThemeLabels: 2,
        ),
      ),
    );
    expect(input.cards, isNotEmpty);
  });

  test('empty session/reading id rejected', () {
    final base = buildFromCorpusId('single_open_fool_en');
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(base, sessionId: '  '),
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(base, readingId: ''),
      ),
      throwsArgumentError,
    );
  });
}
