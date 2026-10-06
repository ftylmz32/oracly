import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacket } from '../src/ai/reading/coffee-meaning-map.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import type { CoffeeNarrative, CoffeeObservation } from '../src/ai/reading/types.js';

type Attempt = {
  role: 'writer' | 'repair';
  request: { messages: Array<{ role: string; content: unknown }> };
  parsed: CoffeeNarrative | null;
  qualityFailure: string | null;
  bindFailure: string | null;
};

type CorpusCase = {
  caseId: string;
  privateObservation: CoffeeObservation;
  mappedMeaningPacket: unknown;
  attempts: Attempt[];
};

type HistoricalPacket = {
  locale: string;
  facets: Array<{ family: string; evidenceIds: string[] }>;
};

const corpus = JSON.parse(
  readFileSync('./docs/qa/coffee-c22-real-provider-20261006.raw.json', 'utf8'),
) as { results: CorpusCase[] };

describe('C2.2 real-provider corpus — current C2.1 privacy and binding gates', () => {
  it('contains the complete required 14-case matrix', () => {
    expect(corpus.results.map((item) => item.caseId)).toEqual(
      Array.from({ length: 14 }, (_, index) => `C${String(index + 1).padStart(2, '0')}`),
    );
  });

  it.each(corpus.results)('$caseId historical mapping and current story plan remain semantically equivalent', (item) => {
    const packet = buildCoffeeWriterPacket(item.privateObservation, 'tr');
    const historical = item.mappedMeaningPacket as HistoricalPacket;
    expect(historical.locale).toBe('tr');
    expect(Array.isArray(historical.facets)).toBe(true);
    const historicalSemantics = historical.facets
      .map((facet) => [facet.family, [...facet.evidenceIds].sort()] as const)
      .sort(([a], [b]) => a.localeCompare(b));
    if ('status' in packet) {
      expect(historicalSemantics).toEqual([]);
      expect(packet).toEqual({
        status: 'insufficient_semantic_signal',
        reason: 'no_safe_semantic_facets',
      });
    } else {
      const currentSemantics = [packet.storyPlan.lead, ...packet.storyPlan.supporting]
        .map((component) => [component.family, [...component.evidenceIds].sort()] as const)
        .sort(([a], [b]) => a.localeCompare(b));
      expect(currentSemantics).toEqual(historicalSemantics);
    }
    const encoded = JSON.stringify(packet);
    for (const rawField of ['region', 'description', 'resemblance', 'confidence', 'visibility']) {
      expect(encoded).not.toContain(`"${rawField}"`);
    }
    expect(encoded).not.toContain('implication');
  });

  it.each(corpus.results)('$caseId provider requests expose no raw observation fields', (item) => {
    for (const attempt of item.attempts) {
      const user = JSON.stringify(attempt.request.messages[1]?.content ?? '');
      expect(user).toContain('facets');
      for (const rawField of ['region', 'description', 'resemblance', 'confidence', 'visibility']) {
        expect(user).not.toContain(`\\"${rawField}\\"`);
      }
      if (attempt.role === 'repair') expect(user).not.toContain('Rejected narrative JSON');
    }
  });

  it.each(corpus.results)('$caseId recorded gate results reproduce exactly', (item) => {
    for (const attempt of item.attempts) {
      if (!attempt.parsed) continue;
      expect(
        coffeeQualityFailure(attempt.parsed, 'tr', undefined, item.privateObservation.evidence),
      ).toBe(attempt.qualityFailure);
      expect(bindCoffeeNarrative(attempt.parsed, item.privateObservation, 'tr')).toBe(
        attempt.bindFailure,
      );
    }
  });
});
