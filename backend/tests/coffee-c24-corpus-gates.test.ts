import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacket, mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

const qa = resolve(process.cwd(), 'docs/qa');
const manifestBytes = readFileSync(resolve(qa, 'coffee-c24-blind-provider-20261006.manifest.json'));
const manifest = JSON.parse(manifestBytes.toString('utf8')) as {
  checks: CoffeeObservation['checks'];
  cases: Array<{
    id: string;
    evidence: ReadingEvidenceItem[];
    expectedFamilies: string[];
    expectedPlan?: {
      specificity: string;
      lead: string;
      supporting: Array<{ family: string; relation: string }>;
      authorizedContexts: string[];
      authorizedTiming: string;
      authorizedSections: string[];
    };
    expectedOutcome?: { status: string; reason: string };
    expectedProviderCalls?: number;
  }>;
};
const corpus = JSON.parse(readFileSync(resolve(qa, 'coffee-c24-blind-provider-20261006.raw.json'), 'utf8')) as {
  manifestSha256: string;
  results: Array<{
    caseId: string;
    providerCallCount: number;
    mappedFacets: Array<{ family: string }>;
    writerPacket: Record<string, unknown>;
    attempts: Array<{
      role: 'writer' | 'repair';
      request: { messages: Array<{ role: string; content: unknown }> };
      parsed: CoffeeNarrative | null;
      qualityFailure: string | null;
      bindFailure: string | null;
    }>;
    pipelineResult: { status: string; reason?: string } | null;
    publicPayload: Record<string, unknown> | null;
  }>;
};

const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({
  usable: true,
  reason: '',
  checks: manifest.checks,
  evidence,
});
const resultFor = (id: string) => corpus.results.find((result) => result.caseId === id)!;
const textOf = (value: unknown) => JSON.stringify(value);

describe('C2.4 frozen blind-provider corpus', () => {
  it('keeps the pre-provider manifest byte-for-byte frozen', () => {
    const hash = createHash('sha256').update(manifestBytes).digest('hex');
    expect(hash).toBe('14ff38fb97ac8c0f5b6fdb4ce8f76fc0548ce24872c932d492ecdee6d09fc1fd');
    expect(corpus.manifestSha256).toBe(hash);
  });

  it.each(manifest.cases)('$id maps only the frozen families and story-plan shape', (testCase) => {
    const obs = observation(testCase.evidence);
    expect(mapCoffeeMeanings(obs, 'tr').map((facet) => facet.family)).toEqual(testCase.expectedFamilies);
    const packet = buildCoffeeWriterPacket(obs, 'tr');
    if (testCase.expectedOutcome) {
      expect(packet).toEqual(testCase.expectedOutcome);
      return;
    }
    expect('status' in packet).toBe(false);
    if ('status' in packet || !testCase.expectedPlan) throw new Error('expected frozen ready plan');
    expect(packet.storyPlan).toMatchObject({
      specificity: testCase.expectedPlan.specificity,
      lead: { family: testCase.expectedPlan.lead },
      supporting: testCase.expectedPlan.supporting,
      authorizedContexts: testCase.expectedPlan.authorizedContexts,
      authorizedTiming: testCase.expectedPlan.authorizedTiming,
      authorizedSections: testCase.expectedPlan.authorizedSections,
    });
  });

  it('never placed raw observation fields or raw evidence values in a writer request', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      for (const attempt of result.attempts) {
        const request = textOf(attempt.request.messages);
        const userRequest = textOf(attempt.request.messages.find((message) => message.role === 'user')?.content);
        expect(userRequest).not.toMatch(/description|resemblance|region|confidence|visibility|privateObservation/);
        for (const evidence of testCase.evidence) {
          expect(request).not.toContain(evidence.description);
          if (evidence.resemblance) expect(request).not.toContain(evidence.resemblance);
          expect(request).not.toContain(evidence.region);
        }
      }
    }
  });

  it('gave repairs only the safe plan and violation code, never raw or rejected prose', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      const rejected = result.attempts[0]?.parsed;
      for (const repair of result.attempts.filter((attempt) => attempt.role === 'repair')) {
        const request = textOf(repair.request.messages);
        expect(request).toContain('storyPlan');
        expect(request).toContain('Violation codes:');
        expect(request).not.toContain('Rejected narrative JSON');
        if (rejected) expect(request).not.toContain(rejected.overall.text);
        for (const evidence of testCase.evidence) expect(request).not.toContain(evidence.description);
      }
    }
  });

  it('reproduces every recorded quality and binding result', () => {
    for (const testCase of manifest.cases) {
      const obs = observation(testCase.evidence);
      const packet = buildCoffeeWriterPacket(obs, 'tr');
      const plan = 'status' in packet ? undefined : packet.storyPlan;
      for (const attempt of resultFor(testCase.id).attempts) {
        expect(attempt.parsed).not.toBeNull();
        if (!attempt.parsed) continue;
        expect(coffeeQualityFailure(attempt.parsed, 'tr', undefined, testCase.evidence, plan)).toBe(attempt.qualityFailure);
        expect(bindCoffeeNarrative(attempt.parsed, obs, 'tr', undefined, plan)).toBe(attempt.bindFailure);
      }
    }
  });

  it('keeps optional lanes unauthorized and empty in every public result', () => {
    for (const result of corpus.results) {
      if (!result.publicPayload) continue;
      for (const lane of ['love', 'career', 'money', 'nearFuture']) {
        expect(result.publicPayload[lane]).toBe('');
      }
    }
  });

  it('keeps all narrative evidence IDs valid and public symbols empty', () => {
    for (const testCase of manifest.cases) {
      const allowed = new Set(testCase.evidence.map((item) => item.id));
      const result = resultFor(testCase.id);
      for (const attempt of result.attempts) {
        if (!attempt.parsed) continue;
        for (const section of Object.values(attempt.parsed)) {
          for (const id of section.evidenceIds) expect(allowed.has(id)).toBe(true);
        }
      }
      if (result.publicPayload) expect(result.publicPayload.symbols).toEqual([]);
    }
  });

  it('returns the exact C13 typed outcome with zero provider calls', () => {
    const c13 = resultFor('C13');
    expect(c13.providerCallCount).toBe(0);
    expect(c13.pipelineResult).toEqual({
      status: 'insufficient_semantic_signal',
      reason: 'no_safe_semantic_facets',
    });
    expect(textOf(c13.pipelineResult)).not.toMatch(/umbrella|c13-unknown/);
  });
});
