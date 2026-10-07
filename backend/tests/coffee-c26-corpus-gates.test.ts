import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacketV2, mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import { coffeeSemanticCapacity, mapCoffeePropositions } from '../src/ai/reading/coffee-semantic-propositions.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

const qa = resolve(process.cwd(), 'docs/qa');
const manifestBytes = readFileSync(resolve(qa, 'coffee-c26-blind-provider-20261006.manifest.json'));
const manifest = JSON.parse(manifestBytes.toString('utf8')) as {
  architectureHead: string;
  checks: CoffeeObservation['checks'];
  cases: Array<{
    id: string;
    evidence: Array<ReadingEvidenceItem & { observationSource: string }>;
    expectedFacets: string[];
    expectedPropositions: string[];
    expectedCapacity: string;
    expectedLead?: string;
    expectedSupporting?: string[];
    expectedSynthesis?: string;
    expectedAuthorizedSections?: string[];
    expectedForbiddenAssumptions?: string[];
    expectedOutcome?: { status: string; reason: string };
    expectedProviderPolicy: { writerEligible: boolean; maxWriterCalls: number; maxRepairCalls: number };
  }>;
};
const corpus = JSON.parse(readFileSync(resolve(qa, 'coffee-c26-blind-provider-20261006.raw.json'), 'utf8')) as {
  manifestSha256: string;
  architectureHead: string;
  totalProviderCalls: number;
  results: Array<{
    caseId: string;
    providerCallCount: number;
    writerAttemptCount: number;
    repairAttemptCount: number;
    writerPacket: Record<string, unknown>;
    attempts: Array<{
      role: 'writer' | 'repair';
      request: { messages: Array<{ role: string; content: unknown }> };
      parsed: CoffeeNarrative | null;
      qualityFailure: string | null;
      bindFailure: string | null;
    }>;
    repairPlan: Record<string, unknown> | null;
    pipelineResult: Record<string, unknown> | null;
    publicPayload: Record<string, unknown> | null;
  }>;
};

const observation = (testCase: (typeof manifest.cases)[number]): CoffeeObservation => ({
  usable: true,
  reason: '',
  checks: manifest.checks,
  evidence: testCase.evidence.map(({ observationSource: _source, ...item }) => item),
});
const resultFor = (id: string) => corpus.results.find((result) => result.caseId === id)!;
const textOf = (value: unknown) => JSON.stringify(value);
const stringValues = (value: unknown): string[] => {
  if (typeof value === 'string') return [value];
  if (Array.isArray(value)) return value.flatMap(stringValues);
  if (value && typeof value === 'object') return Object.values(value).flatMap(stringValues);
  return [];
};

describe('C2.6 frozen blind-provider proposition corpus', () => {
  it('keeps the pre-provider manifest byte-for-byte frozen at the C2.5 architecture head', () => {
    const hash = createHash('sha256').update(manifestBytes).digest('hex');
    expect(hash).toBe('52bc57535ed0c7bffdde06f60528be3d2b6281066916b2a89e1f5dde7691cdc0');
    expect(corpus.manifestSha256).toBe(hash);
    expect(manifest.architectureHead).toBe('487d3a7c49f05ef12f4b606fb5e4fc7fe3cc9058');
    expect(corpus.architectureHead).toBe(manifest.architectureHead);
  });

  it('contains exactly eleven writer cases and three policy cases', () => {
    expect(manifest.cases.filter((item) => item.expectedProviderPolicy.writerEligible)).toHaveLength(11);
    expect(manifest.cases.filter((item) => !item.expectedProviderPolicy.writerEligible)).toHaveLength(3);
    expect(corpus.results).toHaveLength(14);
    expect(corpus.totalProviderCalls).toBe(20);
  });

  it.each(manifest.cases)('$id reproduces facets, propositions, capacity, plan, and claim envelope', (testCase) => {
    const obs = observation(testCase);
    const facets = mapCoffeeMeanings(obs, 'tr');
    const propositions = mapCoffeePropositions(facets);
    expect(facets.map((item) => item.family)).toEqual(testCase.expectedFacets);
    expect(propositions.map((item) => item.kind)).toEqual(testCase.expectedPropositions);
    expect(coffeeSemanticCapacity(propositions)).toBe(testCase.expectedCapacity);
    const packet = buildCoffeeWriterPacketV2(obs, 'tr');
    if (testCase.expectedOutcome) {
      expect(packet).toEqual(testCase.expectedOutcome);
      expect(resultFor(testCase.id).pipelineResult).toEqual(testCase.expectedOutcome);
      return;
    }
    expect('status' in packet).toBe(false);
    if ('status' in packet) return;
    expect(packet.storyPlan.semanticCapacity).toBe(testCase.expectedCapacity);
    expect(packet.storyPlan.lead.kind).toBe(testCase.expectedLead);
    expect(packet.storyPlan.supporting.map((item) => item.kind)).toEqual(testCase.expectedSupporting);
    expect(packet.storyPlan.synthesis.mode).toBe(testCase.expectedSynthesis);
    expect(packet.storyPlan.authorizedSections).toEqual(testCase.expectedAuthorizedSections);
    expect(packet.storyPlan.claimEnvelope.allowedPropositionKinds).toEqual(testCase.expectedPropositions);
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).toEqual(testCase.expectedForbiddenAssumptions);
    // C2.9 added the additive authoritative `lengthRequirements` to the
    // packet; the frozen artifact predates it. Every other field must match.
    // C2.11 likewise added the additive private `storyPlan.fortune` beats.
    const { lengthRequirements, ...historicalPacket } = packet;
    const { fortune, ...historicalPlan } = historicalPacket.storyPlan;
    expect(lengthRequirements.combinedLeadMinWords).toBe(42);
    expect(fortune?.lead.role).toBe('main_development');
    expect(resultFor(testCase.id).writerPacket).toEqual({ ...historicalPacket, storyPlan: historicalPlan });
  });

  it('gives repeated-support cases two genuine accepted IDs merged into one independently-supported proposition', () => {
    for (const id of ['C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C11', 'C12']) {
      const testCase = manifest.cases.find((item) => item.id === id)!;
      const propositions = mapCoffeePropositions(mapCoffeeMeanings(observation(testCase), 'tr'));
      expect(propositions).toHaveLength(1);
      expect(propositions[0].support).toBe('independent_repeat');
      expect(propositions[0].evidenceIds).toHaveLength(2);
      const sources = testCase.evidence
        .filter((item) => propositions[0].evidenceIds.includes(item.id))
        .map((item) => item.observationSource);
      expect(new Set(sources).size).toBe(2);
    }
  });

  it('keeps writer packets and requests free of raw fields, evidence values, family enums, and prior-corpus wording', () => {
    const families = new Set([
      'communication', 'movement', 'opportunity', 'emotional_relevance', 'bond',
      'solution', 'growth', 'social_relevance', 'home_close_circle', 'choice',
    ]);
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      const packetText = textOf(result.writerPacket);
      expect(packetText).not.toMatch(/description|resemblance|sourceSlot|observationSource|region|confidence|visibility|"family"/);
      expect(stringValues(result.writerPacket).some((value) => families.has(value))).toBe(false);
      for (const evidence of testCase.evidence) {
        expect(packetText).not.toContain(evidence.description);
        if (evidence.resemblance) expect(packetText).not.toContain(evidence.resemblance);
      }
      for (const attempt of result.attempts) {
        const request = textOf(attempt.request.messages);
        for (const evidence of testCase.evidence) {
          expect(request).not.toContain(evidence.description);
          if (evidence.resemblance) expect(request).not.toContain(evidence.resemblance);
          expect(request).not.toContain(evidence.region);
          expect(request).not.toContain(evidence.observationSource);
        }
      }
    }
  });

  /**
   * Intentional deterministic corrections of a historically recorded verdict.
   * The raw artifact is immutable; only the CURRENT expectation differs, and
   * each entry asserts its historical value too so history is never rewritten.
   * C2.7C.1: C10's frozen writer narrative was accepted (null/null) although
   * its overall makes the exchange proposition redirect the directional one
   * ("paylaşımın mevcut doğrultuyu başka bir tarafa çevirebileceğini") —
   * an unsupported inter-proposition causal edge. Bind reports the existing
   * public mapping of that quality code.
   */
  const CORRECTED_VERDICTS: Record<string, {
    historical: { qualityFailure: string | null; bindFailure: string | null };
    current: { qualityFailure: string; bindFailure: string };
  }> = {
    'C10#0': {
      historical: { qualityFailure: null, bindFailure: null },
      current: { qualityFailure: 'unsupported_source_causation', bindFailure: 'human_quality' },
    },
  };

  it('reproduces every recorded quality and binding result, except documented deterministic corrections', () => {
    const corrected = new Set<string>();
    for (const testCase of manifest.cases) {
      const obs = observation(testCase);
      const packet = buildCoffeeWriterPacketV2(obs, 'tr');
      const plan = 'status' in packet ? undefined : packet.storyPlan;
      resultFor(testCase.id).attempts.forEach((attempt, index) => {
        expect(attempt.parsed).not.toBeNull();
        if (!attempt.parsed) return;
        const correction = CORRECTED_VERDICTS[`${testCase.id}#${index}`];
        if (correction) {
          corrected.add(`${testCase.id}#${index}`);
          expect({ qualityFailure: attempt.qualityFailure, bindFailure: attempt.bindFailure })
            .toEqual(correction.historical);
        }
        const expected = correction?.current ?? attempt;
        expect(coffeeQualityFailure(attempt.parsed, 'tr', undefined, obs.evidence, plan)).toBe(expected.qualityFailure);
        expect(bindCoffeeNarrative(attempt.parsed, obs, 'tr', undefined, plan)).toBe(expected.bindFailure);
      });
    }
    expect([...corrected]).toEqual(Object.keys(CORRECTED_VERDICTS));
  });

  it('records structured repairs with no rejected prose or raw evidence', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      const first = result.attempts[0];
      if (result.repairAttemptCount === 0) {
        expect(result.repairPlan).toBeNull();
        continue;
      }
      expect(result.repairAttemptCount).toBe(1);
      expect(first.parsed).not.toBeNull();
      if (!first.parsed) continue;
      const packet = buildCoffeeWriterPacketV2(observation(testCase), 'tr');
      if ('status' in packet) throw new Error('repair cannot be a policy case');
      const violation = first.qualityFailure ?? first.bindFailure ?? 'human_quality';
      const { fortune: _fortune, ...historicalStoryPlan } = packet.storyPlan;
      const expected = buildCoffeeRepairPlan(first.parsed, violation, historicalStoryPlan);
      // Frozen provider artifacts predate C2.7C's additive actionable
      // lengthDeficits field. Preserve the historical artifact verbatim
      // while comparing every field that existed at capture time.
      // C2.9 likewise adds the additive authoritative `lengthRequirements`.
      const { lengthDeficits: _newLengthContract, lengthRequirements: _requirements, ...historicalShape } = expected;
      const historicalExpected = violation === 'section_redundancy' || violation === 'insight_collapse'
        ? { ...historicalShape, defect: { ...historicalShape.defect, kind: 'privacy_or_contract' } }
        : historicalShape;
      expect(result.repairPlan).toEqual(historicalExpected);
      if (violation === 'section_redundancy' || violation === 'insight_collapse') {
        expect(expected.defect.kind).toBe('synthesis_redundancy');
      }
      if (violation === 'too_short') {
        expect(_newLengthContract).toBeDefined();
        expect(_newLengthContract?.length).toBeGreaterThan(0);
      }
      const repairText = textOf(result.repairPlan);
      expect(repairText).not.toContain(first.parsed.overall.text);
      expect(repairText).not.toMatch(/description|resemblance|sourceSlot|observationSource|region|confidence|visibility/);
      for (const evidence of testCase.evidence) {
        expect(repairText).not.toContain(evidence.description);
        if (evidence.resemblance) expect(repairText).not.toContain(evidence.resemblance);
      }
    }
  });

  it('enforces call policy and preserves zero-call C07, C13, and C14 outcomes', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      expect(result.writerAttemptCount).toBe(testCase.expectedProviderPolicy.writerEligible ? 1 : 0);
      expect(result.repairAttemptCount).toBeLessThanOrEqual(testCase.expectedProviderPolicy.maxRepairCalls);
      expect(result.providerCallCount).toBe(result.writerAttemptCount + result.repairAttemptCount);
    }
    expect(resultFor('C07').providerCallCount).toBe(0);
    expect(resultFor('C13').providerCallCount).toBe(0);
    expect(resultFor('C14').providerCallCount).toBe(0);
  });

  it('keeps all narrative evidence IDs valid, optional lanes unauthorized, and public symbols empty', () => {
    for (const testCase of manifest.cases) {
      const allowed = new Set(testCase.evidence.map((item) => item.id));
      const result = resultFor(testCase.id);
      for (const attempt of result.attempts) {
        if (!attempt.parsed) continue;
        for (const section of Object.values(attempt.parsed)) {
          for (const id of section.evidenceIds) expect(allowed.has(id)).toBe(true);
        }
        for (const lane of ['love', 'career', 'money', 'nearFuture'] as const) {
          expect(attempt.parsed[lane].text).toBe('');
        }
      }
      if (result.publicPayload) expect(result.publicPayload.symbols).toEqual([]);
    }
  });
});
