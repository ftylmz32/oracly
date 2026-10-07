import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacketV2, mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import { coffeeSemanticCapacity, mapCoffeePropositions } from '../src/ai/reading/coffee-semantic-propositions.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import { sanitizeCoffeeIntention } from '../src/reading/coffee-intention.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

const qa = resolve(process.cwd(), 'docs/qa');
const manifestBytes = readFileSync(resolve(qa, 'coffee-c28-intention-blind-20261007.manifest.json'));
const manifest = JSON.parse(manifestBytes.toString('utf8')) as {
  architectureHead: string;
  checks: CoffeeObservation['checks'];
  cases: Array<{
    id: string;
    intention: string;
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
    expectedPersonalization: { intention: string };
    expectedProviderPolicy: { writerEligible: boolean; maxWriterCalls: number; maxRepairCalls: number };
  }>;
};
const rawText = readFileSync(resolve(qa, 'coffee-c28-intention-blind-20261007.raw.json'), 'utf8');
const corpus = JSON.parse(rawText) as {
  manifestSha256: string;
  architectureHead: string;
  model: string;
  reasoningEffort: string;
  totalProviderCalls: number;
  results: Array<{
    caseId: string;
    intention: string;
    personalization: Record<string, unknown>;
    providerCallCount: number;
    writerAttemptCount: number;
    repairAttemptCount: number;
    writerPacket: Record<string, unknown>;
    attempts: Array<{
      role: 'writer' | 'repair';
      request: { model: string; reasoningEffort?: string; temperature?: number; messages: Array<{ role: string; content: unknown }> };
      outboundBody: Record<string, unknown>;
      parsed: CoffeeNarrative | null;
      qualityFailure: string | null;
      bindFailure: string | null;
    }>;
    repairPlan: Record<string, unknown> | null;
    pipelineResult: Record<string, unknown> | null;
    pipelineError: { code: string } | null;
    publicPayload: Record<string, unknown> | null;
  }>;
};

const observation = (testCase: (typeof manifest.cases)[number]): CoffeeObservation => ({
  usable: true,
  reason: '',
  checks: manifest.checks,
  evidence: testCase.evidence.map(({ observationSource: _source, ...item }) => item),
});
const personalizationOf = (testCase: (typeof manifest.cases)[number]) =>
  personalizationFromUnknown({ personalization: { intention: testCase.intention } });
const resultFor = (id: string) => corpus.results.find((result) => result.caseId === id)!;
const textOf = (value: unknown) => JSON.stringify(value);
const stringValues = (value: unknown): string[] => {
  if (typeof value === 'string') return [value];
  if (Array.isArray(value)) return value.flatMap(stringValues);
  if (value && typeof value === 'object') return Object.values(value).flatMap(stringValues);
  return [];
};
const writerCases = manifest.cases.filter((item) => item.expectedProviderPolicy.writerEligible);

/**
 * C2.9 intentional CURRENT plan corrections. The frozen manifest/raw keep the
 * historical C2.8 envelope; only today's expectation differs:
 * - a Love CATEGORY choice no longer proves an existing relationship;
 * - the person intention now always forbids relationship and reciprocity.
 */
const CURRENT_FORBIDDEN_ADDITIONS: Record<string, string[]> = {
  C02: ['existing_relationship'],
  C03: ['existing_relationship'],
  C07: ['existing_relationship', 'reciprocal_feeling'],
  C10: ['existing_relationship'],
};

describe('C2.8 frozen blind intention-aware real-provider corpus', () => {
  it('keeps the pre-provider manifest byte-for-byte frozen at the C2.7C.1 architecture head', () => {
    const hash = createHash('sha256').update(manifestBytes).digest('hex');
    expect(hash).toBe('5e799e5fe229a6a1600e92054fc014ca251d4a4204bb1a0508471d6fda46adec');
    expect(corpus.manifestSha256).toBe(hash);
    expect(manifest.architectureHead).toBe('535d9c250de06ac5f1616b94b3b9223cadca381b');
    expect(corpus.architectureHead).toBe(manifest.architectureHead);
    expect(manifestBytes.toString('utf8')).not.toMatch(/"parsed"|"raw"|"outboundBody"/);
  });

  it('records the production-intended provider configuration', () => {
    expect(corpus.model).toBe('gpt-5.6-sol');
    expect(corpus.reasoningEffort).toBe('low');
    for (const result of corpus.results) {
      for (const attempt of result.attempts) {
        expect(attempt.request.model).toBe('gpt-5.6-sol');
        expect(attempt.request.reasoningEffort).toBe('low');
        expect(attempt.outboundBody).not.toHaveProperty('temperature');
        expect(attempt.outboundBody.reasoning_effort).toBe('low');
      }
    }
  });

  it('contains exactly twelve writer cases and three policy cases', () => {
    expect(writerCases).toHaveLength(12);
    expect(manifest.cases.filter((item) => !item.expectedProviderPolicy.writerEligible)).toHaveLength(3);
    expect(corpus.results).toHaveLength(15);
    expect(corpus.totalProviderCalls).toBe(24);
  });

  it.each(manifest.cases)('$id reproduces intention, facets, propositions, capacity, plan, and claim envelope', (testCase) => {
    expect(sanitizeCoffeeIntention(testCase.intention)).toBe(testCase.intention);
    expect(personalizationOf(testCase)).toEqual(testCase.expectedPersonalization);
    const obs = observation(testCase);
    const facets = mapCoffeeMeanings(obs, 'tr');
    const propositions = mapCoffeePropositions(facets);
    expect(facets.map((item) => item.family)).toEqual(testCase.expectedFacets);
    expect(propositions.map((item) => item.kind)).toEqual(testCase.expectedPropositions);
    expect(coffeeSemanticCapacity(propositions)).toBe(testCase.expectedCapacity);
    const packet = buildCoffeeWriterPacketV2(obs, 'tr', personalizationOf(testCase));
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
    expect(packet.storyPlan.authorizedTiming).toBe('unspecified');
    expect(packet.storyPlan.claimEnvelope.allowedPropositionKinds).toEqual(testCase.expectedPropositions);
    const added = CURRENT_FORBIDDEN_ADDITIONS[testCase.id] ?? [];
    expect([...packet.storyPlan.claimEnvelope.forbiddenAssumptions].sort()).toEqual([
      ...testCase.expectedForbiddenAssumptions,
      ...added,
    ].sort());
    // Additive C2.9 fields (subject, lengthRequirements) and the documented
    // envelope correction are the ONLY differences from the frozen packet.
    const { lengthRequirements: _requirements, ...currentPacket } = packet;
    const { subject: _subject, fortune: _fortune, ...currentPlan } = currentPacket.storyPlan;
    expect(resultFor(testCase.id).writerPacket).toEqual({
      ...currentPacket,
      storyPlan: {
        ...currentPlan,
        claimEnvelope: {
          ...currentPlan.claimEnvelope,
          forbiddenAssumptions: testCase.expectedForbiddenAssumptions,
        },
      },
    });
  });

  it('gives every modest case two accepted IDs from different cup views merged into one proposition', () => {
    for (const testCase of manifest.cases.filter((item) => item.expectedCapacity === 'modest')) {
      const propositions = mapCoffeePropositions(mapCoffeeMeanings(observation(testCase), 'tr'));
      expect(propositions).toHaveLength(1);
      expect(propositions[0].support).toBe('independent_repeat');
      const sources = testCase.evidence
        .filter((item) => propositions[0].evidenceIds.includes(item.id))
        .map((item) => item.observationSource);
      expect(new Set(sources).size).toBe(2);
    }
  });

  it('transports ONLY the frozen trusted intention to the writer', () => {
    for (const testCase of writerCases) {
      const result = resultFor(testCase.id);
      expect(result.personalization).toEqual({ intention: testCase.intention });
      expect(result.writerPacket.personalization).toEqual({ intention: testCase.intention });
      const request = textOf(result.attempts[0].request.messages[1].content);
      expect(request).toContain(testCase.intention);
      expect(request).not.toMatch(/firstName|memorySummary|relevantThemes|history|luna|oracle/i);
    }
  });

  it('keeps writer packets and requests free of raw fields, evidence values, and family enums', () => {
    const families = new Set([
      'communication', 'movement', 'opportunity', 'emotional_relevance', 'bond',
      'solution', 'growth', 'social_relevance', 'home_close_circle', 'choice',
    ]);
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      const packetText = textOf(result.writerPacket);
      expect(packetText).not.toMatch(/description|resemblance|sourceSlot|observationSource|region|confidence|visibility|"family"/);
      expect(stringValues(result.writerPacket).some((value) => families.has(value))).toBe(false);
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
   * C2.9 intentional deterministic corrections of recorded verdicts (raw JSON
   * untouched). The three readings C2.8 delivered narrated the reading or
   * the synthesis rules ("Bu yorumun odağında", "Biri diğerini yaratmadan,
   * ikisi aynı bütün içinde yan yana duruyor", "Genel izlenim … anlatıyor",
   * "Bu iki eğilim … yan yana duruyor"); C11's draft explained its synthesis
   * ("… tek bir gelişme halinde beliriyor") before its serialization.
   * C2.11 precedence (privacy → unsupported claims → subject → meta →
   * parroting → restatement → style/length) re-labels further attempts; every
   * change is fail→more-serious-fail or pass→fail, never a new pass.
   */
  const CORRECTED_VERDICTS: Record<string, {
    historical: { qualityFailure: string | null; bindFailure: string | null };
    current: { qualityFailure: string; bindFailure: string };
  }> = {
      'C01#1': { historical: { qualityFailure: 'section_redundancy', bindFailure: 'section_redundancy' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    // C2.11A: its first sentence is a label-led opening ("Aşk hayatında … bir duygu belirginleşiyor").
    'C02#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C02#1': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'missing_intention_subject', bindFailure: 'human_quality' } },
    'C03#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C03#1': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'unsupported_existing_fact', bindFailure: 'human_quality' } },
    'C04#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C04#1': { historical: { qualityFailure: 'abstract_reading', bindFailure: 'human_quality' }, current: { qualityFailure: 'missing_intention_subject', bindFailure: 'human_quality' } },
    'C05#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'unsupported_existing_fact', bindFailure: 'human_quality' } },
    'C05#1': { historical: { qualityFailure: 'unsupported_source_causation', bindFailure: 'human_quality' }, current: { qualityFailure: 'unsupported_existing_fact', bindFailure: 'human_quality' } },
    'C06#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_subject_drift', bindFailure: 'human_quality' } },
    'C06#1': { historical: { qualityFailure: 'generic_closing', bindFailure: 'generic_closing' }, current: { qualityFailure: 'missing_intention_subject', bindFailure: 'human_quality' } },
    'C07#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'unsupported_existing_fact', bindFailure: 'human_quality' } },
    'C07#1': { historical: { qualityFailure: 'possibility_menu', bindFailure: 'human_quality' }, current: { qualityFailure: 'unsupported_other_agency', bindFailure: 'human_quality' } },
    // C2.11A: label-led opening ("Aklındaki kişiyle ilgili duygun, … daha güçlü … anlam").
    'C08#0': { historical: { qualityFailure: 'abstract_reading', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C08#1': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'missing_intention_subject', bindFailure: 'human_quality' } },
    'C09#0': { historical: { qualityFailure: 'observation_heavy', bindFailure: 'human_quality' }, current: { qualityFailure: 'semantic_restatement', bindFailure: 'human_quality' } },
    'C10#0': { historical: { qualityFailure: 'section_redundancy', bindFailure: 'section_redundancy' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C10#1': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'missing_intention_subject', bindFailure: 'human_quality' } },
    'C11#0': { historical: { qualityFailure: 'component_serialization', bindFailure: 'human_quality' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C12#0': { historical: { qualityFailure: 'observation_heavy', bindFailure: 'human_quality' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C12#1': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'missing_intention_subject', bindFailure: 'human_quality' } },
  };

  it('reproduces every recorded quality and binding result, except documented C2.9/C2.11 corrections', () => {
    const corrected = new Set<string>();
    for (const testCase of writerCases) {
      const obs = observation(testCase);
      const personalization = personalizationOf(testCase);
      const packet = buildCoffeeWriterPacketV2(obs, 'tr', personalization);
      if ('status' in packet) throw new Error('writer case cannot be a policy case');
      resultFor(testCase.id).attempts.forEach((attempt, index) => {
        expect(attempt.parsed).not.toBeNull();
        if (!attempt.parsed) return;
        const key = `${testCase.id}#${index}`;
        const correction = CORRECTED_VERDICTS[key];
        if (correction) {
          corrected.add(key);
          expect({ qualityFailure: attempt.qualityFailure, bindFailure: attempt.bindFailure }).toEqual(correction.historical);
        }
        const expected = correction?.current ?? attempt;
        expect(coffeeQualityFailure(attempt.parsed, 'tr', personalization, obs.evidence, packet.storyPlan))
          .toBe(expected.qualityFailure);
        expect(bindCoffeeNarrative(attempt.parsed, obs, 'tr', personalization, packet.storyPlan))
          .toBe(expected.bindFailure);
      });
    }
    expect([...corrected].sort()).toEqual(Object.keys(CORRECTED_VERDICTS).sort());
  });

  it('keeps the C2.7C.1 causation gate active on the recorded C2.8 outputs', () => {
    const causation = corpus.results.flatMap((result) =>
      result.attempts
        .map((attempt, index) => ({ key: `${result.caseId}#${index}`, failure: attempt.qualityFailure }))
        .filter((item) => item.failure === 'unsupported_source_causation')
        .map((item) => item.key));
    expect(causation).toEqual(['C05#1', 'C11#1']);
  });

  it('records Turkish structured repairs with no rejected prose, raw evidence, or intention', () => {
    for (const testCase of writerCases) {
      const result = resultFor(testCase.id);
      expect(result.repairAttemptCount).toBe(1);
      const first = result.attempts[0];
      if (!first.parsed) throw new Error('missing first attempt');
      const packet = buildCoffeeWriterPacketV2(observation(testCase), 'tr', personalizationOf(testCase));
      if ('status' in packet) throw new Error('repair cannot be a policy case');
      const violation = first.bindFailure === 'human_quality'
        ? (first.qualityFailure ?? 'human_quality')
        : first.bindFailure!;
      // Historical reproduction against the frozen plan the repair received;
      // C2.9's additive lengthRequirements is the only new field.
      const historicalPlan = (result.repairPlan as { storyPlan: typeof packet.storyPlan }).storyPlan;
      const { lengthRequirements: _requirements, ...expected } =
        buildCoffeeRepairPlan(first.parsed, violation, historicalPlan, 'tr');
      expect(result.repairPlan).toEqual(expected);
      expect(expected.locale).toBe('tr');
      if (violation === 'too_short') expect(expected.lengthDeficits?.length).toBeGreaterThan(0);
      if (violation === 'section_redundancy' || violation === 'component_serialization') {
        expect(expected.defect.kind).toBe('synthesis_redundancy');
      }
      const repairText = textOf(result.attempts[1].request.messages);
      for (const section of ['overall', 'takeaway', 'visualObservation'] as const) {
        expect(repairText).not.toContain(first.parsed[section].text);
      }
      expect(textOf(result.repairPlan)).not.toMatch(/description|resemblance|sourceSlot|observationSource|region|confidence|visibility/);
      for (const evidence of testCase.evidence) {
        expect(repairText).not.toContain(evidence.description);
        if (evidence.resemblance) expect(repairText).not.toContain(evidence.resemblance);
      }
      // Systemic finding #1 as RECORDED in C2.8: the repair packet carried no
      // trusted intention. C2.9 closes it — today's repair plan carries it.
      expect(repairText).not.toContain(testCase.intention);
      const current = buildCoffeeRepairPlan(first.parsed, violation, packet.storyPlan, 'tr', packet.lengthRequirements);
      expect(current.subject?.intention).toBe(testCase.intention);
      expect(current.lengthRequirements).toEqual(packet.lengthRequirements);
      const repaired = result.attempts[1].parsed!;
      expect(`${repaired.overall.text} ${repaired.takeaway.text}`).toMatch(/[çğıöşü]/);
    }
  });

  it('enforces call policy and zero provider calls for C13, C14, and C15', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      expect(result.writerAttemptCount).toBe(testCase.expectedProviderPolicy.writerEligible ? 1 : 0);
      expect(result.repairAttemptCount).toBeLessThanOrEqual(testCase.expectedProviderPolicy.maxRepairCalls);
      expect(result.providerCallCount).toBe(result.writerAttemptCount + result.repairAttemptCount);
    }
    for (const id of ['C13', 'C14', 'C15']) expect(resultFor(id).providerCallCount).toBe(0);
  });

  it('records exactly C03, C10, and C12 as gate-delivered; all others fail closed', () => {
    const delivered = corpus.results.filter((result) => result.publicPayload).map((result) => result.caseId);
    expect(delivered).toEqual(['C03', 'C10', 'C12']);
    for (const testCase of writerCases) {
      const result = resultFor(testCase.id);
      if (delivered.includes(testCase.id)) expect(result.pipelineError).toBeNull();
      else expect(result.pipelineError?.code).toBe('quality_unavailable');
    }
  });

  it('keeps narrative evidence IDs valid, unauthorized lanes empty, and public symbols empty', () => {
    for (const testCase of writerCases) {
      const allowed = new Set(testCase.evidence.map((item) => item.id));
      const authorized = new Set(testCase.expectedAuthorizedSections);
      const result = resultFor(testCase.id);
      for (const attempt of result.attempts) {
        if (!attempt.parsed) continue;
        for (const [name, section] of Object.entries(attempt.parsed)) {
          if (name === 'symbols') continue;
          for (const id of (section as { evidenceIds: string[] }).evidenceIds) expect(allowed.has(id)).toBe(true);
        }
        for (const lane of ['love', 'career', 'money', 'nearFuture'] as const) {
          if (!authorized.has(lane)) expect(attempt.parsed[lane].text).toBe('');
        }
      }
      if (result.publicPayload) expect(result.publicPayload.symbols).toEqual([]);
    }
  });

  it('stores no credentials in the corpus artifacts', () => {
    for (const text of [rawText, manifestBytes.toString('utf8')]) {
      expect(text).not.toMatch(/sk-[A-Za-z0-9_-]{10,}|Bearer |Authorization|OPENAI_API_KEY/);
    }
  });
});
