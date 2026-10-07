import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacketV2, mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import { coffeeSemanticCapacity, mapCoffeePropositions } from '../src/ai/reading/coffee-semantic-propositions.js';
import { mapCoffeeSemanticCues } from '../src/ai/reading/coffee-semantic-cues.js';
import { coffeeActiveDevelopmentClasses } from '../src/ai/reading/coffee-public-language.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import { sanitizeCoffeeIntention } from '../src/reading/coffee-intention.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

const qa = resolve(process.cwd(), 'docs/qa');
const manifestBytes = readFileSync(resolve(qa, 'coffee-c212-decisive-blind-20261007.manifest.json'));
type Beat = { kind: string; cue: string; forbiddenSpecifics: string[] };
const manifest = JSON.parse(manifestBytes.toString('utf8')) as {
  architectureHead: string;
  checks: CoffeeObservation['checks'];
  cases: Array<{
    id: string;
    intention: string;
    evidence: Array<ReadingEvidenceItem & { observationSource: string }>;
    expectedFacets: string[];
    expectedPropositions: string[];
    expectedCues: string[];
    expectedCapacity: string;
    expectedLead?: string;
    expectedSupporting?: string[];
    expectedSynthesis?: string;
    expectedFortuneLead?: Beat;
    expectedFortuneSupporting?: Beat[];
    expectedDevelopmentClasses?: string[];
    expectedSubject?: { kind: string; requiredSection: string | null; declaredFacts: string[] };
    expectedAuthorizedSections?: string[];
    expectedForbiddenAssumptions?: string[];
    expectedLengthRequirements?: Record<string, number>;
    expectedOutcome?: { status: string; reason: string };
    expectedProviderPolicy: { writerEligible: boolean; maxWriterCalls: number; maxRepairCalls: number };
  }>;
};
const rawText = readFileSync(resolve(qa, 'coffee-c212-decisive-blind-20261007.raw.json'), 'utf8');
const corpus = JSON.parse(rawText) as {
  manifestSha256: string;
  architectureHead: string;
  model: string;
  reasoningEffort: string;
  totalProviderCalls: number;
  results: Array<{
    caseId: string;
    personalization: Record<string, unknown>;
    providerCallCount: number;
    writerAttemptCount: number;
    repairAttemptCount: number;
    writerPacket: Record<string, unknown>;
    attempts: Array<{
      role: 'writer' | 'repair';
      request: { model: string; messages: Array<{ role: string; content: unknown }> };
      outboundBody: Record<string, unknown>;
      parsed: CoffeeNarrative;
      qualityFailure: string | null;
      bindFailure: string | null;
    }>;
    repairPlan: Record<string, unknown> | null;
    repairPlanMatchesSent: boolean | null;
    repairAudit: { receivesNo: Record<string, boolean> } | null;
    pipelineResult: Record<string, unknown> | null;
    pipelineError: { code: string } | null;
    publicPayload: Record<string, unknown> | null;
  }>;
};

type Case = (typeof manifest.cases)[number];
const observation = (testCase: Case): CoffeeObservation => ({
  usable: true,
  reason: '',
  checks: manifest.checks,
  evidence: testCase.evidence.map(({ observationSource: _source, ...item }) => item),
});
const personalizationOf = (testCase: Case) =>
  personalizationFromUnknown({ personalization: { intention: testCase.intention } });
const readyPacket = (testCase: Case) => {
  const packet = buildCoffeeWriterPacketV2(observation(testCase), 'tr', personalizationOf(testCase));
  if ('status' in packet) throw new Error(`${testCase.id} is not writer-eligible`);
  return packet;
};
const resultFor = (id: string) => corpus.results.find((result) => result.caseId === id)!;
const textOf = (value: unknown) => JSON.stringify(value);
const writerCases = manifest.cases.filter((item) => item.expectedProviderPolicy.writerEligible);
const firstViolation = (attempt: { qualityFailure: string | null; bindFailure: string | null }) =>
  attempt.bindFailure === 'human_quality' ? (attempt.qualityFailure ?? 'human_quality') : attempt.bindFailure!;
const SECTIONS = ['visualObservation', 'overall', 'love', 'career', 'money', 'nearFuture', 'takeaway'] as const;
const publicText = (payload: Record<string, unknown>) => SECTIONS.map((s) => String(payload[s] ?? '')).join(' ');

/**
 * Manual product verdict (docs/qa/coffee-c212-decisive-blind-20261007.review.md).
 * Gate delivery is NOT product success: 9 readings were delivered, 0 pass the
 * product bar. Decisive verdict: FAIL.
 */
const MANUAL_PRODUCT_PASS: string[] = [];
const DECISIVE_VERDICT = 'FAIL';

describe('C2.12 frozen decisive blind real-provider corpus', () => {
  it('keeps the pre-provider manifest byte-for-byte frozen at the C2.11A.1 architecture head', () => {
    const hash = createHash('sha256').update(manifestBytes).digest('hex');
    expect(hash).toBe('e46e434e81b7c5f420be345ad4d200cd3e1fbd060462a063d2111cabe20a8d19');
    expect(corpus.manifestSha256).toBe(hash);
    expect(manifest.architectureHead).toBe('42168d36e77ce701d0fb2d1d7c8da3337cac41aa');
    expect(corpus.architectureHead).toBe(manifest.architectureHead);
    expect(manifestBytes.toString('utf8')).not.toMatch(/"parsed"|"raw"|"outboundBody"|"publicPayload"/);
  });

  it('records the production-intended provider configuration', () => {
    expect(corpus.model).toBe('gpt-5.6-sol');
    expect(corpus.reasoningEffort).toBe('low');
    for (const result of corpus.results) {
      for (const attempt of result.attempts) {
        expect(attempt.request.model).toBe('gpt-5.6-sol');
        expect(attempt.outboundBody).not.toHaveProperty('temperature');
        expect(attempt.outboundBody.reasoning_effort).toBe('low');
      }
    }
  });

  it('contains exactly fourteen writer cases, three policy cases, and 21 provider calls', () => {
    expect(writerCases).toHaveLength(14);
    expect(manifest.cases.filter((item) => !item.expectedProviderPolicy.writerEligible)).toHaveLength(3);
    expect(corpus.results).toHaveLength(17);
    expect(corpus.totalProviderCalls).toBe(21);
    expect(corpus.results.reduce((n, r) => n + r.writerAttemptCount, 0)).toBe(14);
    expect(corpus.results.reduce((n, r) => n + r.repairAttemptCount, 0)).toBe(7);
  });

  it.each(manifest.cases)('$id reproduces intention, subject, cues, propositions, beats, envelope, and length contract', (testCase) => {
    expect(sanitizeCoffeeIntention(testCase.intention)).toBe(testCase.intention);
    expect(personalizationOf(testCase)).toEqual({ intention: testCase.intention });
    const obs = observation(testCase);
    const propositions = mapCoffeePropositions(mapCoffeeMeanings(obs, 'tr'));
    expect(mapCoffeeMeanings(obs, 'tr').map((item) => item.family)).toEqual(testCase.expectedFacets);
    expect(propositions.map((item) => item.kind)).toEqual(testCase.expectedPropositions);
    expect(mapCoffeeSemanticCues(obs).map((item) => item.kind)).toEqual(testCase.expectedCues);
    expect(coffeeSemanticCapacity(propositions)).toBe(testCase.expectedCapacity);
    const packet = buildCoffeeWriterPacketV2(obs, 'tr', personalizationOf(testCase));
    if (testCase.expectedOutcome) {
      expect(packet).toEqual(testCase.expectedOutcome);
      expect(resultFor(testCase.id).pipelineResult).toEqual(testCase.expectedOutcome);
      return;
    }
    if ('status' in packet) throw new Error('expected writer packet');
    const plan = packet.storyPlan;
    expect({ kind: plan.subject?.kind, requiredSection: plan.subject?.requiredSection, declaredFacts: plan.subject?.declaredFacts })
      .toEqual(testCase.expectedSubject);
    expect(plan.subject?.intention).toBe(testCase.intention);
    expect(plan.subject?.intentionForbiddenAssumptions).toEqual(classifyCoffeeIntention(testCase.intention)!.intentionForbiddenAssumptions);
    expect(plan.lead.kind).toBe(testCase.expectedLead);
    expect(plan.supporting.map((item) => item.kind)).toEqual(testCase.expectedSupporting);
    expect(plan.synthesis.mode).toBe(testCase.expectedSynthesis);
    expect(plan.authorizedSections).toEqual(testCase.expectedAuthorizedSections);
    expect([...plan.claimEnvelope.forbiddenAssumptions].sort()).toEqual([...testCase.expectedForbiddenAssumptions!].sort());
    expect(packet.lengthRequirements).toEqual(testCase.expectedLengthRequirements);
    const view = (b: Beat) => ({ kind: b.kind, cue: b.cue, forbiddenSpecifics: b.forbiddenSpecifics });
    expect(view(plan.fortune!.lead)).toEqual(testCase.expectedFortuneLead);
    expect(plan.fortune!.supporting.map(view)).toEqual(testCase.expectedFortuneSupporting);
    expect([...coffeeActiveDevelopmentClasses(plan)]).toEqual(testCase.expectedDevelopmentClasses);
    expect(resultFor(testCase.id).writerPacket).toEqual(JSON.parse(JSON.stringify(packet)));
  });

  it('keeps every writer packet and request free of raw fields, evidence values, and raw sign nouns', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      expect(textOf(result.writerPacket)).not.toMatch(/description|resemblance|sourceSlot|observationSource|region|confidence|visibility|"family"/);
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

  it('reproduces every recorded quality and binding verdict with the frozen production gates', () => {
    for (const testCase of writerCases) {
      const obs = observation(testCase);
      const personalization = personalizationOf(testCase);
      const plan = readyPacket(testCase).storyPlan;
      for (const attempt of resultFor(testCase.id).attempts) {
        expect(coffeeQualityFailure(attempt.parsed, 'tr', personalization, obs.evidence, plan)).toBe(attempt.qualityFailure);
        expect(bindCoffeeNarrative(attempt.parsed, obs, 'tr', personalization, plan)).toBe(attempt.bindFailure);
      }
    }
  });

  it('records first-draft gate passes for exactly C01, C03, C04, C05, C06, C07, C12', () => {
    const passed = writerCases.filter((c) => resultFor(c.id).attempts[0].bindFailure === null).map((c) => c.id);
    expect(passed).toEqual(['C01', 'C03', 'C04', 'C05', 'C06', 'C07', 'C12']);
  });

  it('REPAIR AUDIT: every repair carries subject, beats, length, locale, evidence IDs and no rejected or raw prose', () => {
    let repairs = 0;
    for (const testCase of writerCases) {
      const result = resultFor(testCase.id);
      if (result.repairAttemptCount === 0) {
        expect(result.repairPlan).toBeNull();
        continue;
      }
      repairs += 1;
      expect(result.repairPlanMatchesSent).toBe(true);
      const packet = readyPacket(testCase);
      const first = result.attempts[0];
      const expected = buildCoffeeRepairPlan(first.parsed, firstViolation(first), packet.storyPlan, 'tr', packet.lengthRequirements);
      expect(result.repairPlan).toEqual(JSON.parse(JSON.stringify(expected)));
      expect(expected.locale).toBe('tr');
      expect(expected.subject?.intention).toBe(testCase.intention);
      expect(expected.storyPlan.fortune?.lead.kind).toBe(testCase.expectedFortuneLead!.kind);
      expect(expected.lengthRequirements).toEqual(packet.lengthRequirements);
      expect(expected.evidenceIds.length).toBeGreaterThan(0);
      expect(Object.values(result.repairAudit!.receivesNo).every(Boolean)).toBe(true);
      const repairRequest = textOf(result.attempts[1].request.messages);
      for (const section of SECTIONS) {
        const text = first.parsed[section].text.trim();
        if (text) expect(repairRequest).not.toContain(text);
      }
      // Repairs stay Turkish.
      expect(`${result.attempts[1].parsed.overall.text}`).toMatch(/[çğıöşü]/);
    }
    expect(repairs).toBe(7);
    expect(resultFor('C11').repairPlan).toMatchObject({ allowedDevelopments: ['people'], unsupportedDevelopmentsTriggered: ['communication'] });
  });

  it('enforces call policy and zero provider calls for C15, C16, and C17', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      expect(result.writerAttemptCount).toBe(testCase.expectedProviderPolicy.writerEligible ? 1 : 0);
      expect(result.repairAttemptCount).toBeLessThanOrEqual(testCase.expectedProviderPolicy.maxRepairCalls);
      expect(result.providerCallCount).toBe(result.writerAttemptCount + result.repairAttemptCount);
    }
    for (const id of ['C15', 'C16', 'C17']) {
      expect(resultFor(id).providerCallCount).toBe(0);
      expect(resultFor(id).publicPayload).toBeNull();
    }
  });

  it('records exactly nine gate-delivered readings; C02, C08, C09, C13, C14 fail closed', () => {
    const delivered = corpus.results.filter((result) => result.publicPayload).map((result) => result.caseId);
    expect(delivered).toEqual(['C01', 'C03', 'C04', 'C05', 'C06', 'C07', 'C10', 'C11', 'C12']);
    for (const id of ['C02', 'C08', 'C09', 'C13', 'C14']) {
      expect(resultFor(id).pipelineError?.code).toBe('quality_unavailable');
    }
    for (const id of delivered) {
      const testCase = manifest.cases.find((c) => c.id === id)!;
      const lane = testCase.expectedSubject!.requiredSection;
      if (lane) expect(String(resultFor(id).publicPayload![lane]).trim()).not.toBe('');
      expect(resultFor(id).publicPayload!.symbols).toEqual([]);
    }
  });

  it('delivered prose carries no cup/image vocabulary', () => {
    for (const result of corpus.results.filter((r) => r.publicPayload)) {
      expect(publicText(result.publicPayload!)).not.toMatch(/fincan|telve|tortu|sembol|simge|şekil|figür|leke|desen/iu);
    }
  });

  it('records the manual decisive verdict: 0/14 product pass, architecture FAIL', () => {
    expect(MANUAL_PRODUCT_PASS).toHaveLength(0);
    expect(DECISIVE_VERDICT).toBe('FAIL');
  });

  it('stores no credentials in the corpus artifacts', () => {
    for (const text of [rawText, manifestBytes.toString('utf8')]) {
      expect(text).not.toMatch(/sk-[A-Za-z0-9_-]{10,}|Bearer |Authorization|OPENAI_API_KEY/);
    }
  });
});
