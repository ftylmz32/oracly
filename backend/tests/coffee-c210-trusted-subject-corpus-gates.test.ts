import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacketV2, mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import { coffeeSemanticCapacity, mapCoffeePropositions } from '../src/ai/reading/coffee-semantic-propositions.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { coffeeClaimEnvelopeFailure } from '../src/ai/reading/coffee-claim-envelope.js';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { coffeeLengthDeficits } from '../src/ai/reading/coffee-length-contract.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import { sanitizeCoffeeIntention } from '../src/reading/coffee-intention.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

const qa = resolve(process.cwd(), 'docs/qa');
const manifestBytes = readFileSync(resolve(qa, 'coffee-c210-trusted-subject-blind-20261007.manifest.json'));
const manifest = JSON.parse(manifestBytes.toString('utf8')) as {
  architectureHead: string;
  checks: CoffeeObservation['checks'];
  c14TrustedStateContractAudit: {
    probeSentence: string;
    classifierDeclaredFacts: string[];
    claimEnvelopeVerdictOnLiteralRestatement: string | null;
    trustedStateContractInconsistency: boolean;
  };
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
    expectedSubject?: { kind: string; requiredSection: string | null; declaredFacts: string[] };
    expectedAuthorizedSections?: string[];
    expectedForbiddenAssumptions?: string[];
    expectedLengthRequirements?: Record<string, number>;
    expectedOutcome?: { status: string; reason: string };
    expectedProviderPolicy: { writerEligible: boolean; maxWriterCalls: number; maxRepairCalls: number };
  }>;
};
const rawText = readFileSync(resolve(qa, 'coffee-c210-trusted-subject-blind-20261007.raw.json'), 'utf8');
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
      request: { model: string; reasoningEffort?: string; messages: Array<{ role: string; content: unknown }> };
      outboundBody: Record<string, unknown>;
      parsed: CoffeeNarrative;
      qualityFailure: string | null;
      bindFailure: string | null;
    }>;
    repairPlan: Record<string, unknown> | null;
    repairPlanMatchesSent: boolean | null;
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

/**
 * C2.11 intentional CURRENT corrections (frozen manifest/raw untouched):
 * C14's literal "…dönüş bekliyorum" now declares the granular
 * awaiting_response fact, which lifts ONLY awaited_topic.
 */
const CURRENT_SUBJECT: Record<string, { declaredFacts: string[]; liftedForbidden: string[] }> = {
  C14: { declaredFacts: ['awaiting_response'], liftedForbidden: ['awaited_topic'] },
};

/**
 * C2.11 precedence + realization gates re-label recorded verdicts. Every
 * change is fail→more-serious-fail or pass→fail (never a new pass): the five
 * delivered readings (C02, C05, C09, C10, C13) are all rejected now.
 */
const CORRECTED_VERDICTS: Record<string, {
  historical: { qualityFailure: string | null; bindFailure: string | null };
  current: { qualityFailure: string; bindFailure: string };
}> = {
    'C01#1': { historical: { qualityFailure: 'section_redundancy', bindFailure: 'section_redundancy' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C02#0': { historical: { qualityFailure: 'possibility_menu', bindFailure: 'human_quality' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C02#1': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'semantic_restatement', bindFailure: 'human_quality' } },
    'C03#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'unsupported_existing_fact', bindFailure: 'human_quality' } },
    'C04#0': { historical: { qualityFailure: 'abstract_reading', bindFailure: 'human_quality' }, current: { qualityFailure: 'presumed_user_state', bindFailure: 'human_quality' } },
    'C04#1': { historical: { qualityFailure: 'abstract_reading', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C05#0': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C05#1': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'unsupported_existing_fact', bindFailure: 'human_quality' } },
    'C06#0': { historical: { qualityFailure: 'caution_voice', bindFailure: 'human_quality' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C06#1': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C07#0': { historical: { qualityFailure: 'section_redundancy', bindFailure: 'section_redundancy' }, current: { qualityFailure: 'unsupported_existing_fact', bindFailure: 'human_quality' } },
    'C07#1': { historical: { qualityFailure: 'too_short', bindFailure: 'human_quality' }, current: { qualityFailure: 'unsupported_other_agency', bindFailure: 'human_quality' } },
    'C08#0': { historical: { qualityFailure: 'abstract_reading', bindFailure: 'human_quality' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C08#1': { historical: { qualityFailure: 'section_redundancy', bindFailure: 'section_redundancy' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C09#0': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C10#0': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C11#1': { historical: { qualityFailure: 'observation_heavy', bindFailure: 'human_quality' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C12#0': { historical: { qualityFailure: 'section_redundancy', bindFailure: 'section_redundancy' }, current: { qualityFailure: 'intention_parroting', bindFailure: 'human_quality' } },
    'C12#1': { historical: { qualityFailure: 'component_serialization', bindFailure: 'human_quality' }, current: { qualityFailure: 'meta_narration', bindFailure: 'human_quality' } },
    'C13#0': { historical: { qualityFailure: null, bindFailure: null }, current: { qualityFailure: 'semantic_restatement', bindFailure: 'human_quality' } },
    'C14#1': { historical: { qualityFailure: 'section_redundancy', bindFailure: 'section_redundancy' }, current: { qualityFailure: 'unsupported_certainty', bindFailure: 'human_quality' } },
};

describe('C2.10 frozen blind trusted-subject real-provider corpus', () => {
  it('keeps the pre-provider manifest byte-for-byte frozen at the C2.9 architecture head', () => {
    const hash = createHash('sha256').update(manifestBytes).digest('hex');
    expect(hash).toBe('a3f395792d9d34fb1acb7966d738ee1e710e09e732b271b8530337422e52a99d');
    expect(corpus.manifestSha256).toBe(hash);
    expect(manifest.architectureHead).toBe('9bb535465f5e979eb6697964af3e8be9334c87d4');
    expect(corpus.architectureHead).toBe(manifest.architectureHead);
    expect(manifestBytes.toString('utf8')).not.toMatch(/"parsed"|"raw"|"outboundBody"/);
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

  it('contains exactly fourteen writer cases and three policy cases', () => {
    expect(writerCases).toHaveLength(14);
    expect(manifest.cases.filter((item) => !item.expectedProviderPolicy.writerEligible)).toHaveLength(3);
    expect(corpus.results).toHaveLength(17);
    expect(corpus.totalProviderCalls).toBe(25);
  });

  it.each(manifest.cases)('$id reproduces intention, subject, facets, propositions, capacity, plan, envelope, and length contract', (testCase) => {
    expect(sanitizeCoffeeIntention(testCase.intention)).toBe(testCase.intention);
    expect(personalizationOf(testCase)).toEqual({ intention: testCase.intention });
    const obs = observation(testCase);
    const propositions = mapCoffeePropositions(mapCoffeeMeanings(obs, 'tr'));
    expect(mapCoffeeMeanings(obs, 'tr').map((item) => item.family)).toEqual(testCase.expectedFacets);
    expect(propositions.map((item) => item.kind)).toEqual(testCase.expectedPropositions);
    expect(coffeeSemanticCapacity(propositions)).toBe(testCase.expectedCapacity);
    const packet = buildCoffeeWriterPacketV2(obs, 'tr', personalizationOf(testCase));
    if (testCase.expectedOutcome) {
      expect(packet).toEqual(testCase.expectedOutcome);
      expect(resultFor(testCase.id).pipelineResult).toEqual(testCase.expectedOutcome);
      return;
    }
    if ('status' in packet) throw new Error('expected writer packet');
    const plan = packet.storyPlan;
    const context = classifyCoffeeIntention(testCase.intention)!;
    const correction = CURRENT_SUBJECT[testCase.id];
    expect({ kind: plan.subject?.kind, requiredSection: plan.subject?.requiredSection, declaredFacts: plan.subject?.declaredFacts })
      .toEqual(correction ? { ...testCase.expectedSubject, declaredFacts: correction.declaredFacts } : testCase.expectedSubject);
    expect(plan.subject?.intention).toBe(testCase.intention);
    expect(plan.subject?.intentionForbiddenAssumptions).toEqual(context.intentionForbiddenAssumptions);
    expect(plan.semanticCapacity).toBe(testCase.expectedCapacity);
    expect(plan.lead.kind).toBe(testCase.expectedLead);
    expect(plan.supporting.map((item) => item.kind)).toEqual(testCase.expectedSupporting);
    expect(plan.synthesis.mode).toBe(testCase.expectedSynthesis);
    expect(plan.authorizedSections).toEqual(testCase.expectedAuthorizedSections);
    const lifted = new Set(correction?.liftedForbidden ?? []);
    expect([...plan.claimEnvelope.forbiddenAssumptions].sort())
      .toEqual(testCase.expectedForbiddenAssumptions!.filter((item) => !lifted.has(item)).sort());
    expect(packet.lengthRequirements).toEqual(testCase.expectedLengthRequirements);
    // C2.11 additive private fortune beats are the only other packet difference.
    const { fortune, ...currentPlan } = plan;
    expect(fortune?.lead.role).toBe('main_development');
    const recorded = resultFor(testCase.id).writerPacket as { storyPlan: Record<string, unknown> };
    if (correction) {
      expect(recorded.storyPlan.claimEnvelope).not.toEqual(currentPlan.claimEnvelope);
    } else {
      expect(recorded).toEqual({ ...packet, storyPlan: currentPlan });
    }
  });

  it('separates the Love category (C02/C03/C10) from a literally declared relationship (C13)', () => {
    for (const id of ['C02', 'C03', 'C10']) {
      expect(readyPacket(manifest.cases.find((item) => item.id === id)!).storyPlan.claimEnvelope.forbiddenAssumptions)
        .toEqual(expect.arrayContaining(['existing_relationship', 'reciprocal_feeling', 'specific_other_person']));
    }
    const c13 = readyPacket(manifest.cases.find((item) => item.id === 'C13')!).storyPlan;
    expect(c13.subject?.declaredFacts).toEqual(['current_relationship']);
    expect(c13.claimEnvelope.forbiddenAssumptions).not.toContain('existing_relationship');
    expect(c13.claimEnvelope.forbiddenAssumptions).toContain('reciprocal_feeling');
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
      expect(request).toContain('lengthRequirements');
      expect(request).not.toMatch(/firstName|memorySummary|relevantThemes|luna|oracle/i);
    }
  });

  it('keeps every writer and repair request free of raw fields and evidence values', () => {
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

  it('reproduces every recorded quality and binding result, except documented C2.11 corrections', () => {
    const corrected = new Set<string>();
    for (const testCase of writerCases) {
      const obs = observation(testCase);
      const personalization = personalizationOf(testCase);
      const plan = readyPacket(testCase).storyPlan;
      resultFor(testCase.id).attempts.forEach((attempt, index) => {
        const key = `${testCase.id}#${index}`;
        const correction = CORRECTED_VERDICTS[key];
        if (correction) {
          corrected.add(key);
          expect({ qualityFailure: attempt.qualityFailure, bindFailure: attempt.bindFailure }).toEqual(correction.historical);
        }
        const expected = correction?.current ?? attempt;
        expect(coffeeQualityFailure(attempt.parsed, 'tr', personalization, obs.evidence, plan)).toBe(expected.qualityFailure);
        expect(bindCoffeeNarrative(attempt.parsed, obs, 'tr', personalization, plan)).toBe(expected.bindFailure);
      });
    }
    expect([...corrected].sort()).toEqual(Object.keys(CORRECTED_VERDICTS).sort());
    for (const id of ['C02', 'C05', 'C09', 'C10', 'C13']) {
      const final = resultFor(id).attempts.at(-1)!;
      expect(CORRECTED_VERDICTS[`${id}#${resultFor(id).attempts.length - 1}`]?.current.bindFailure).toBe('human_quality');
      expect(final.bindFailure).toBeNull();
    }
  });

  it('records first-draft gate passes for exactly C09, C10, and C13', () => {
    const passed = writerCases
      .filter((testCase) => resultFor(testCase.id).attempts[0].bindFailure === null)
      .map((testCase) => testCase.id);
    expect(passed).toEqual(['C09', 'C10', 'C13']);
  });

  it('REPAIR PARITY: every repair carries the same subject, plan, length contract, and locale with no rejected or raw prose', () => {
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
      const violation = firstViolation(first);
      // Reproduce against the frozen plan the repair actually received.
      const recordedPlan = (result.repairPlan as { storyPlan: typeof packet.storyPlan }).storyPlan;
      const expected = buildCoffeeRepairPlan(first.parsed, violation, recordedPlan, 'tr', packet.lengthRequirements);
      expect(result.repairPlan).toEqual(expected);
      expect(expected.locale).toBe('tr');
      expect(recordedPlan.lead).toEqual(packet.storyPlan.lead);
      expect(expected.lengthRequirements).toEqual(packet.lengthRequirements);
      expect(expected.subject).toMatchObject({
        intention: testCase.intention,
        kind: testCase.expectedSubject!.kind,
        requiredSection: testCase.expectedSubject!.requiredSection,
        declaredFacts: testCase.expectedSubject!.declaredFacts,
      });
      // Today's repair plan additionally carries the fortune beats and the current subject.
      const current = buildCoffeeRepairPlan(first.parsed, violation, packet.storyPlan, 'tr', packet.lengthRequirements);
      expect(current.storyPlan.fortune?.lead.evidenceIds.length).toBeGreaterThan(0);
      expect(current.subject?.intention).toBe(testCase.intention);
      expect(expected.evidenceIds.length).toBeGreaterThan(0);
      if (violation === 'too_short') {
        expect(expected.lengthDeficits?.length).toBeGreaterThan(0);
        expect(expected.lengthDeficits).toEqual(coffeeLengthDeficits(first.parsed, packet.lengthRequirements));
      }
      const repairRequest = textOf(result.attempts[1].request.messages);
      expect(repairRequest).toContain(testCase.intention);
      for (const section of ['visualObservation', 'overall', 'takeaway'] as const) {
        expect(repairRequest).not.toContain(first.parsed[section].text);
      }
      for (const evidence of testCase.evidence) {
        expect(repairRequest).not.toContain(evidence.description);
        if (evidence.resemblance) expect(repairRequest).not.toContain(evidence.resemblance);
      }
      const repaired = result.attempts[1].parsed;
      expect(`${repaired.overall.text} ${repaired.takeaway.text}`).toMatch(/[çğıöşü]/);
      const lane = testCase.expectedSubject!.requiredSection as 'love' | 'career' | 'money' | null;
      if (lane) expect(repaired[lane].text.trim()).not.toBe('');
    }
    expect(repairs).toBe(11);
  });

  it('enforces call policy and zero provider calls for C15, C16, and C17', () => {
    for (const testCase of manifest.cases) {
      const result = resultFor(testCase.id);
      expect(result.writerAttemptCount).toBe(testCase.expectedProviderPolicy.writerEligible ? 1 : 0);
      expect(result.repairAttemptCount).toBeLessThanOrEqual(testCase.expectedProviderPolicy.maxRepairCalls);
      expect(result.providerCallCount).toBe(result.writerAttemptCount + result.repairAttemptCount);
    }
    for (const id of ['C15', 'C16', 'C17']) expect(resultFor(id).providerCallCount).toBe(0);
  });

  it('records exactly C02, C05, C09, C10, and C13 as gate-delivered; all others fail closed', () => {
    const delivered = corpus.results.filter((result) => result.publicPayload).map((result) => result.caseId);
    expect(delivered).toEqual(['C02', 'C05', 'C09', 'C10', 'C13']);
    for (const testCase of writerCases) {
      const result = resultFor(testCase.id);
      if (delivered.includes(testCase.id)) {
        expect(result.pipelineError).toBeNull();
        const lane = testCase.expectedSubject!.requiredSection;
        if (lane) expect(String(result.publicPayload![lane]).trim()).not.toBe('');
      } else {
        expect(result.pipelineError?.code).toBe('quality_unavailable');
      }
    }
  });

  it('keeps narrative evidence IDs valid, unauthorized lanes empty, and public symbols empty', () => {
    for (const testCase of writerCases) {
      const allowed = new Set(testCase.evidence.map((item) => item.id));
      const authorized = new Set(testCase.expectedAuthorizedSections);
      const result = resultFor(testCase.id);
      for (const attempt of result.attempts) {
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

  it('C14: the recorded TRUSTED STATE CONTRACT INCONSISTENCY is closed by C2.11; invented outcome stays forbidden', () => {
    const audit = manifest.c14TrustedStateContractAudit;
    expect(audit.classifierDeclaredFacts).toEqual(['stated_condition']);
    expect(audit.claimEnvelopeVerdictOnLiteralRestatement).toBe('presumed_user_state');
    expect(audit.trustedStateContractInconsistency).toBe(true);
    const c14 = manifest.cases.find((item) => item.id === 'C14')!;
    const plan = readyPacket(c14).storyPlan;
    expect(plan.subject?.declaredFacts).toEqual(['awaiting_response']);
    expect(plan.claimEnvelope.forbiddenAssumptions).not.toContain('awaited_topic');
    expect(plan.claimEnvelope.forbiddenAssumptions).toContain('guaranteed_outcome');
    const [writer, repair] = resultFor('C14').attempts;
    // The literal waiting restatement is no longer contradicted …
    expect(coffeeClaimEnvelopeFailure(writer.parsed, plan)).not.toBe('presumed_user_state');
    expect(coffeeQualityFailure(writer.parsed, 'tr', personalizationOf(c14), observation(c14).evidence, plan)).toBe('section_redundancy');
    // … while "… bir sonuç taşıyor" (the response arrives and turns into a dialogue) stays forbidden.
    expect(coffeeClaimEnvelopeFailure(repair.parsed, plan)).toBe('unsupported_certainty');
  });

  it('records the C07 person violations that earlier style/length gates masked', () => {
    const c07 = manifest.cases.find((item) => item.id === 'C07')!;
    const plan = readyPacket(c07).storyPlan;
    const [writer, repair] = resultFor('C07').attempts;
    expect(writer.qualityFailure).toBe('section_redundancy');
    expect(coffeeClaimEnvelopeFailure(writer.parsed, plan)).toBe('unsupported_existing_fact');
    expect(repair.qualityFailure).toBe('too_short');
    expect(coffeeClaimEnvelopeFailure(repair.parsed, plan)).toBe('unsupported_other_agency');
    // C2.11 precedence: the unsupported relationship/agency now WINS over
    // section_redundancy and too_short in the production verdict.
    const personalization = personalizationOf(c07);
    expect(coffeeQualityFailure(writer.parsed, 'tr', personalization, observation(c07).evidence, plan)).toBe('unsupported_existing_fact');
    expect(coffeeQualityFailure(repair.parsed, 'tr', personalization, observation(c07).evidence, plan)).toBe('unsupported_other_agency');
  });

  it('stores no credentials in the corpus artifacts', () => {
    for (const text of [rawText, manifestBytes.toString('utf8')]) {
      expect(text).not.toMatch(/sk-[A-Za-z0-9_-]{10,}|Bearer |Authorization|OPENAI_API_KEY/);
    }
  });
});
