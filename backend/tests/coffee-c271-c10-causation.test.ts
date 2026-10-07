import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { coffeeClaimEnvelopeFailure } from '../src/ai/reading/coffee-claim-envelope.js';
import { buildCoffeeWriterPacketV2 } from '../src/ai/reading/coffee-meaning-map.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

/**
 * C2.7C.1 — exact C10 causation false-negative closure.
 *
 * The frozen C2.6 C10 provider narrative (docs/qa/coffee-c26-blind-provider-
 * 20261006.raw.json, results[C10].attempts[0].parsed) was recorded with
 * qualityFailure = null although its overall says the exchange proposition
 * ("paylaşımın") redirects the directional-change proposition ("mevcut
 * doğrultuyu başka bir tarafa çevirebileceğini") — an inter-proposition
 * causal edge the story plan never authorizes (every supporting relation is
 * co_occurring). The narrative is loaded verbatim from the immutable corpus.
 */
const qa = resolve(process.cwd(), 'docs/qa');
const manifest = JSON.parse(readFileSync(resolve(qa, 'coffee-c26-blind-provider-20261006.manifest.json'), 'utf8')) as {
  checks: CoffeeObservation['checks'];
  cases: Array<{ id: string; evidence: Array<ReadingEvidenceItem & { observationSource: string }> }>;
};
const corpus = JSON.parse(readFileSync(resolve(qa, 'coffee-c26-blind-provider-20261006.raw.json'), 'utf8')) as {
  results: Array<{
    caseId: string;
    attempts: Array<{ parsed: CoffeeNarrative; qualityFailure: string | null; bindFailure: string | null }>;
  }>;
};
const frozen = (id: string) => {
  const testCase = manifest.cases.find((value) => value.id === id)!;
  const obs: CoffeeObservation = {
    usable: true,
    reason: '',
    checks: manifest.checks,
    evidence: testCase.evidence.map(({ observationSource: _source, ...item }) => item),
  };
  const packet = buildCoffeeWriterPacketV2(obs, 'tr');
  if ('status' in packet) throw new Error(`${id} is a policy case`);
  const attempt = corpus.results.find((value) => value.caseId === id)!.attempts[0];
  return { obs, plan: packet.storyPlan, attempt };
};

const checks = {
  cupInteriorVisible: true,
  adequateFocusLight: true,
  residueVisible: true,
  milkFoamObstruction: false,
  usefulRegionsVisible: true,
};
const item = (id: string, resemblance: string): ReadingEvidenceItem => ({
  id, region: 'middle_wall', description: `clear ${resemblance} form`, resemblance, confidence: 'high', visibility: 'clear',
});
const planFor = (...evidence: ReadingEvidenceItem[]) => {
  const packet = buildCoffeeWriterPacketV2({ usable: true, reason: '', checks, evidence }, 'tr');
  if ('status' in packet) throw new Error(`expected ready, got ${packet.reason}`);
  return packet.storyPlan;
};
const section = (text: string, evidenceIds = ['e1']) => ({ text, evidenceIds });
const narrative = (overall: string): CoffeeNarrative => ({
  visualObservation: section('Anlamın iki yönü aynı çerçevede birleşiyor.'),
  overall: section(overall),
  love: section('', []), career: section('', []), money: section('', []), nearFuture: section('', []),
  takeaway: section('Bu anlam günlük hayatında kendine özgü bir karşılık bulabilir.'),
});
const exchangeAndDirection = () => planFor(item('e1', 'bird'), item('e2', 'road'));

describe('C2.7C.1 exact C10 unsupported proposition causation', () => {
  it('A: the exact frozen C2.6 C10 narrative (historically null) is now rejected for causation', () => {
    const { obs, plan, attempt } = frozen('C10');
    expect(attempt.qualityFailure).toBeNull();
    expect(attempt.parsed.overall.text).toContain('paylaşımın mevcut doğrultuyu başka bir tarafa çevirebileceğini');
    expect(plan.supporting.every((value) => value.relation === 'co_occurring')).toBe(true);
    expect(coffeeClaimEnvelopeFailure(attempt.parsed, plan)).toBe('unsupported_source_causation');
    expect(coffeeQualityFailure(attempt.parsed, 'tr', undefined, obs.evidence, plan)).toBe('unsupported_source_causation');
  });

  it('A: the exact frozen C10 overall alone carries the causal defect', () => {
    const { plan, attempt } = frozen('C10');
    expect(coffeeClaimEnvelopeFailure(narrative(attempt.parsed.overall.text), plan)).toBe('unsupported_source_causation');
  });

  it('B: exchange acting on direction is rejected when the two are only co_occurring', () => {
    expect(coffeeClaimEnvelopeFailure(
      narrative('Seninle çevren arasındaki paylaşım mevcut doğrultuyu başka bir tarafa çevirebilir.'),
      exchangeAndDirection(),
    )).toBe('unsupported_source_causation');
  });

  it.each([
    'Karşılıklı paylaşım çözüm alanını belirginleştiriyor.',
    'Bu haber yönünü başka bir tarafa döndürebilir.',
    'Bu paylaşımla yönün değişebilir.',
    'Konuşmanın etkisiyle hareket alanın genişleyebilir.',
  ])('B: other agent -> effect shapes between planned kinds are rejected: %s', (overall) => {
    const plan = planFor(item('e1', 'key'), item('e2', 'bird'), item('e3', 'road'));
    expect(coffeeClaimEnvelopeFailure(narrative(overall), plan)).toBe('unsupported_source_causation');
  });

  it('C: the ordinary word paylaşım without acting on another proposition is allowed', () => {
    expect(coffeeClaimEnvelopeFailure(
      narrative('Karşılıklı bir paylaşım ve yön değişimi aynı dönemde yan yana beliriyor; ikisi tek bir bütünün parçası gibi duruyor.'),
      exchangeAndDirection(),
    )).toBeNull();
  });

  it('D: directional language with no other proposition as its cause is allowed', () => {
    expect(coffeeClaimEnvelopeFailure(
      narrative('Hayatındaki doğrultu başka bir tarafa dönebilir ve karşılıklı bir paylaşım da bu tablonun içinde beliriyor.'),
      exchangeAndDirection(),
    )).toBeNull();
  });

  it('D: "ile birlikte" co-occurrence stays accepted (existing C10 unified realization)', () => {
    const plan = planFor(item('e1', 'key'), item('e2', 'bird'), item('e3', 'road'));
    expect(coffeeClaimEnvelopeFailure(
      narrative('Çözüm alanı iletişimle birlikte yön değiştiren tek bir hareket olarak beliriyor. Bu çözüm ve iletişim aynı hareketin içinde birbirini tamamlıyor.'),
      plan,
    )).toBeNull();
  });

  it('E: pure component serialization still returns component_serialization', () => {
    const plan = planFor(item('e1', 'key'), item('e2', 'bird'), item('e3', 'road'));
    expect(coffeeClaimEnvelopeFailure(
      narrative('Çözüm öne çıkıyor. İletişim hayatında belirleyici oluyor. Hareket alanı belirginleşiyor.'),
      plan,
    )).toBe('component_serialization');
  });

  it('F: unsupported chronology still returns unsupported_chronology', () => {
    expect(coffeeClaimEnvelopeFailure(
      narrative('İlk olarak netlik beliriyor; ardından hareket başka bir yöne açılıyor.'),
      planFor(item('e1', 'key'), item('e2', 'road')),
    )).toBe('unsupported_chronology');
  });

  it('G: causation wins over serialization when both defects exist', () => {
    const plan = planFor(item('e1', 'key'), item('e2', 'bird'), item('e3', 'road'));
    const both = narrative('Çözüm öne çıkıyor. İletişim hayatında belirleyici oluyor. Bu paylaşım mevcut doğrultuyu başka bir tarafa çevirebilir.');
    expect(coffeeClaimEnvelopeFailure(both, plan)).toBe('unsupported_source_causation');
  });

  it('H: the frozen C09 non-causal unified synthesis is not rejected for holding several propositions', () => {
    const { obs, plan, attempt } = frozen('C09');
    expect(plan.supporting.length).toBeGreaterThan(0);
    expect(coffeeClaimEnvelopeFailure(attempt.parsed, plan)).toBeNull();
    expect(coffeeQualityFailure(attempt.parsed, 'tr', undefined, obs.evidence, plan)).toBeNull();
  });

  it.each([
    ['road', 'Mevcut doğrultunu başka bir tarafa çevirebilir, hareketini yeni bir yöne açabilirsin.'],
    ['bird', 'Bir paylaşım hayatına yeni bir hareket getirebilir ve konuşmayı kolaylaştırabilir.'],
    ['key', 'Netlik, karşına çıkan çözümü daha görünür kılıyor ve açıklığı belirginleştiriyor.'],
  ])('I: a single-proposition (%s) reading is never rejected by the inter-proposition gate', (source, overall) => {
    // One sign alone is a zero-call policy case; two independent observations
    // of the same sign give a real single-proposition writer plan.
    const plan = planFor(item('e1', source), { ...item('e2', source), region: 'lower_wall' });
    expect(plan.supporting).toHaveLength(0);
    expect(coffeeClaimEnvelopeFailure(narrative(overall), plan)).not.toBe('unsupported_source_causation');
  });

  it('routes the exact C10 defect to a structured causation repair with locale, plan, no prose, no raw evidence', () => {
    const { obs, plan, attempt } = frozen('C10');
    const repair = buildCoffeeRepairPlan(attempt.parsed, 'unsupported_source_causation', plan, 'tr');
    expect(repair.defect.kind).toBe('unsupported_concretization');
    expect(repair.forbiddenClaimCategoriesTriggered).toContain('causation');
    expect(repair.locale).toBe('tr');
    expect(repair.storyPlan).toEqual(plan);
    const text = JSON.stringify(repair);
    for (const value of [attempt.parsed.overall.text, attempt.parsed.visualObservation.text, attempt.parsed.takeaway.text]) {
      expect(text).not.toContain(value);
    }
    expect(text).not.toMatch(/description|resemblance|sourceSlot|observationSource|region|confidence|visibility/);
    for (const evidence of obs.evidence) {
      expect(text).not.toContain(evidence.description);
      if (evidence.resemblance) expect(text).not.toContain(evidence.resemblance);
    }
  });
});
