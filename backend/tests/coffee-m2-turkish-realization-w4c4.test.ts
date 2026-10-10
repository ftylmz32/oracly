import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer, type CoffeeM2WriterPlan } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import {
  COFFEE_TURKISH_CLASS_WORDING,
  COFFEE_TURKISH_SCENARIO_CLUSTERS,
  COFFEE_TURKISH_SCENARIO_WORDING,
} from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
import {
  COFFEE_TURKISH_OCCURRENCE_FAMILIES,
  COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS,
  coffeeTurkishTokens,
  prepareCoffeeM2TurkishRealization,
  type CoffeeM2TurkishRealizationPayload,
} from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { checkCoffeeM2TurkishRealization, validateCoffeeM2ScenarioSelection } from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import {
  COFFEE_M2_W4P1_PROMPT,
  coffeeM2WriterPromptUncoveredFields,
  coffeeM2WriterSystemPrompt,
} from '../src/ai/reading/coffee-m2-writer-prompt.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

/**
 * W4C.4 — inside the rich opening + decision scenario beat the option word
 * ("seçenek" family) may occur at most twice in total (W4P3: three uses gave
 * natural Turkish 7 twice; two uses gave the premium sample). Surface only.
 */

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const W = 'secondary_option_gaining_weight';
const R = 'another_option_relevant';
const S = 'options_separating';
const sha = (v: unknown) => createHash('sha256').update(JSON.stringify(v)).digest('hex');
const planOf = (spec: M1FixtureSpec, intention: string | null) =>
  planCoffeeM2Writer(interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning).plan;
const realize = (spec: M1FixtureSpec, intention: string | null) => prepareCoffeeM2TurkishRealization(planOf(spec, intention));
const ritagPlan = () => planOf(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION);
const ritag = () => prepareCoffeeM2TurkishRealization(ritagPlan());
const limitsOf = (p: CoffeeM2TurkishRealizationPayload) => p.realization.beats.map((b) => b.lexicalOccurrenceLimits ?? null);
const optionCount = (text: string) => coffeeTurkishTokens(text).filter((t) => COFFEE_TURKISH_OCCURRENCE_FAMILIES.OPTION_SECENEK.includes(t)).length;
const codes = (texts: string[], items: string[][] = [[], [W, S]]) => {
  const p = ritag();
  return [...checkCoffeeM2TurkishRealization(p, texts), ...validateCoffeeM2ScenarioSelection(p, items)].map((v) => `${v.beat ?? '-'}:${v.code}:${v.detail}`);
};

const B1 = 'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.';
/** Exact W4P3 provider outputs (scratchpad w4p3/). */
const W4P3: Record<string, [string, string]> = {
  S1: [B1, 'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir ve seçenekler arasındaki fark daha net görünebilir.'],
  S2: ['Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.', 'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir, seçenekler arasındaki fark da daha net görünebilir.'],
  S3: ['Karar meselende yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.', 'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir ve aralarındaki fark daha net görünebilir.'],
};
/** W4P2 W + R outputs (closed by W4C.3). */
const W4P2_WR: [string, string] = [
  'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.',
  'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir, başka bir seçenek de gündeme gelebilir.',
];
const HISTORICAL: Array<[string, string]> = [
  ['Önündeki karar konusunda biraz daha ileride önün açılıyor; konu da yaklaşan dönemde kendi akışında ilerliyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  ['Önündeki karar konusunda konu yaklaşan dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  ['Vermen gereken kararda konu önümüzdeki dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  ['Önündeki karar konusunda konu önümüzdeki dönemde kendi akışında ilerliyor; biraz daha ileride önünü açan bir yol da beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
];
const MANUAL: [string, string] = [
  'Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.',
  'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
];

describe('W4C.4 occurrence counting (A–J)', () => {
  const b2 = (text: string) => codes([B1, text]).filter((c) => c.includes('LEXICAL_OCCURRENCE_LIMIT'));
  it('A/B/C: 0, 1 and 2 occurrences pass', () => {
    expect(b2('Yaklaşan günlerde birkaç ayrı ihtimal çıkıyor; biri gözünde ağırlık kazanabilir, aralarındaki fark da daha net görünebilir.')).toEqual([]);
    expect(b2('Yaklaşan günlerde birkaç seçenek çıkıyor; biri gözünde ağırlık kazanabilir, aralarındaki fark da daha net görünebilir.')).toEqual([]);
    expect(b2('Yaklaşan günlerde birkaç seçenek çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir, aralarındaki fark da daha net görünebilir.')).toEqual([]);
  });

  it('D/E: three occurrences fail; different inflections share one total', () => {
    expect(optionCount('seçenek seçeneklerden seçenekler')).toBe(3);
    expect(b2('Yaklaşan günlerde birkaç seçenek çıkıyor; seçeneklerden biri ağır basabilir, seçenekler arasındaki fark da netleşebilir.'))
      .toEqual(['B2:LEXICAL_OCCURRENCE_LIMIT:OPTION_SECENEK: 3 > 2']);
    expect(optionCount('Seçeneği, seçeneğe, seçeneklerin ve seçeneklerini')).toBe(4);
  });

  it('F/G/H: seçim, seçmek, seçici and substrings never count', () => {
    expect(optionCount('seçim seçmek seçici seçilebilir seçeneksiz seçenekçi xseçenek')).toBe(0);
    for (const word of ['seçim', 'seçmek', 'seçici', 'seç']) expect(COFFEE_TURKISH_OCCURRENCE_FAMILIES.OPTION_SECENEK).not.toContain(word);
    expect(b2('Yaklaşan günlerde birkaç seçenek çıkıyor; seçeneklerden biri ağır basabilir, seçimin farkı da netleşebilir.')).toEqual([]);
  });

  it('I: the limit applies only to the designated beat (B1 may say it three times without this rule firing)', () => {
    const b1 = 'Vermen gereken kararda seçenek seçenekler seçeneklerden yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.';
    expect(codes([b1, MANUAL[1]]).filter((c) => c.includes('LEXICAL_OCCURRENCE_LIMIT'))).toEqual([]);
  });

  it('J: the same three-option wording in another shape (GAZETA) is not checked by this rule', () => {
    const g = realize(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION);
    const texts = ['Önündeki karar konusunda yaklaşan dönemde önün açılırken birden fazla yol da beliriyor.', 'Bu seçeneklerden biri ağır basabilir, seçenekler arasındaki fark da seçenek seçenek netleşebilir.'];
    expect(checkCoffeeM2TurkishRealization(g, texts).filter((v) => v.code === 'LEXICAL_OCCURRENCE_LIMIT')).toEqual([]);
  });
});

describe('W4C.4 scope (K–Q)', () => {
  const NONE = (p: CoffeeM2TurkishRealizationPayload) => expect(limitsOf(p).every((l) => l === null)).toBe(true);

  it('K/L: the rich opening + decision shape gets OPTION_SECENEK max 2 on B2 only', () => {
    const p = ritag();
    expect(limitsOf(p)).toEqual([null, [{ family: 'OPTION_SECENEK', forms: [...COFFEE_TURKISH_OCCURRENCE_FAMILIES.OPTION_SECENEK], max: 2 }]]);
  });

  it('M/N: GAZETA and the old RITAG shape have none', () => {
    NONE(realize(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION));
    NONE(realize(c31Spec('C3F-RITAG'), DECISION));
  });

  it('O/P/Q: non-rich, rich non-opening and opening-without-decision-scenario controls have none', () => {
    const nonRich: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(ritagPlan()));
    nonRich.diagnostics.m2.capacity = 'multi_thread';
    NONE(prepareCoffeeM2TurkishRealization(nonRich));
    const nonOpening: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(ritagPlan()));
    nonOpening.beats[0].relation!.combination = 'course_opens_into_alternatives' as never;
    NONE(prepareCoffeeM2TurkishRealization(nonOpening));
    NONE(realize(c31Spec('C3F-RITAG', { clearAreas: true }), CANONICAL_INTENTION_TEXT.general));
  });

  it('no other subject gets it (money / career / love / POI / awaited)', () => {
    const intentions = [CANONICAL_INTENTION_TEXT.money_finance, CANONICAL_INTENTION_TEXT.career_work, CANONICAL_INTENTION_TEXT.love_relationships, CANONICAL_INTENTION_TEXT.person_of_interest, 'Bir yerden dönüş bekliyorum.'];
    const specs = [c31Spec('C3F-RITAG', { clearAreas: true }), c31Spec('C3F-GAZETA', { clearAreas: true }), ...Object.values(M1_QA_CUPS).map((c) => c.spec)];
    for (const spec of specs) {
      for (const intention of intentions) {
        const plan = planOf(spec, intention);
        if (plan.status === 'planned') NONE(prepareCoffeeM2TurkishRealization(plan));
      }
    }
  });
});

describe('W4C.4 replays (R–W)', () => {
  it('R/S: W4P3 samples 1 and 2 fail the occurrence rule (3 > 2)', () => {
    for (const id of ['S1', 'S2']) {
      expect(optionCount(W4P3[id][1]), id).toBe(3);
      expect(codes(W4P3[id]), id).toContain('B2:LEXICAL_OCCURRENCE_LIMIT:OPTION_SECENEK: 3 > 2');
    }
  });

  it('T: W4P3 sample 3 (two uses) stays accepted', () => {
    expect(optionCount(W4P3.S3[1])).toBe(2);
    expect(codes(W4P3.S3)).toEqual([]);
  });

  it('U: historical M2.2 / M2.3 samples stay rejected', () => {
    for (const texts of HISTORICAL) expect(codes(texts, [[], [W]]).length).toBeGreaterThan(0);
  });

  it('V: W4P2 W + R outputs stay rejected by the W4C.3 pair', () => {
    expect(codes(W4P2_WR, [[], [W, R]])).toContain('B2:SCENARIO_INCOMPATIBLE_PAIR:secondary_option_gaining_weight+another_option_relevant');
  });

  it('W: the manual premium reading stays accepted', () => {
    expect(optionCount(MANUAL[1])).toBe(1);
    expect(codes(MANUAL)).toEqual([]);
  });
});

describe('W4C.4 invariants and prompt contract', () => {
  it('bank, scenario grammar, M2 and W2 are unchanged; choose stays 2/2', () => {
    expect(COFFEE_TURKISH_SCENARIO_WORDING[S].forms.scenario).toEqual(['seçenekler birbirinden daha net ayrılabilir', 'hangi yolun ne olduğu daha açık seçilebilir', 'seçenekler arasındaki fark daha net görünebilir']);
    expect(COFFEE_TURKISH_SCENARIO_WORDING[W].forms.scenario).toEqual(['seçeneklerden biri ağır basmaya başlayabilir', 'bir seçenek diğerlerine göre daha ağır basabilir', 'seçeneklerden biri gözünde ağırlık kazanabilir']);
    expect(COFFEE_TURKISH_CLASS_WORDING.MULTIPLICITY.forms.predicate).toContain('birkaç seçenek birden ortaya çıkıyor');
    expect(COFFEE_TURKISH_SCENARIO_CLUSTERS[[W, R, S].join('|')]).toEqual({ mode: 'alternatives', choose: { min: 1, max: 2 } });
    expect(COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS.map((p) => p.pair.join('+'))[0]).toBe('another_option_relevant+options_separating');
    const meaning = interpretCoffeeM2(m1Map(c31Spec('C3F-RITAG', { clearAreas: true })), classifyCoffeeIntention(DECISION)).meaning;
    expect(meaning.threads).toHaveLength(2);
    expect(meaning.diagnostics).toMatchObject({ capacity: 'rich', groundedDevelopmentCount: 3 });
    const p = ritag();
    expect(p.beats[1].scenario?.manifestations).toEqual([W, R, S]);
    expect(p.wording.scenarioClusters.map((c) => c.choose)).toEqual([{ min: 2, max: 2 }]);
    expect(p.realization.beats[1].scenarioIncompatiblePairs).toEqual([[R, S], [W, R]]);
  });

  it('writer-safe: only a family id, closed forms and a number; meaning-only guard passes', () => {
    const p = ritag();
    expect(Object.keys(p.realization.beats[1].lexicalOccurrenceLimits![0])).toEqual(['family', 'forms', 'max']);
    expect(() => assertCoffeeV3MeaningOnly(p)).not.toThrow();
    expect(JSON.stringify(p).includes(DECISION)).toBe(false);
  });

  it('the prompt documents lexicalOccurrenceLimits in one appended line, after the unchanged W4P1 prompt, with no example word', () => {
    const prompt = coffeeM2WriterSystemPrompt();
    expect(prompt.startsWith(COFFEE_M2_W4P1_PROMPT)).toBe(true);
    const added = prompt.slice(COFFEE_M2_W4P1_PROMPT.length);
    expect(added.split('\r\n').filter(Boolean)).toHaveLength(1);
    expect(added).toMatch(/^- realization\.beats\[i\]\.lexicalOccurrenceLimits \(parçaya özgü realization kısıtı\)/);
    expect(added).toMatch(/TOPLAM en fazla/);
    expect(added).toMatch(/forms içindeki bütün biçimler aynı toplama sayılır/);
    expect(added).toMatch(/Kök çıkarma ve listede olmayan biçim ekleme/);
    expect(added).toMatch(/lisanslı bir anlamı düşürme/);
    expect(added).not.toMatch(/seçenek|OPTION_SECENEK|RITAG|GAZETA|8\/10|puan/i);
  });

  it('the manifest covers the new field and its nested keys; a new nested key fails', () => {
    const p = ritag();
    expect(coffeeM2WriterPromptUncoveredFields(p)).toEqual([]);
    const extra = JSON.parse(JSON.stringify(p));
    extra.realization.beats[1].lexicalOccurrenceLimits[0].min = 1;
    expect(coffeeM2WriterPromptUncoveredFields(extra)).toEqual(['lexicalOccurrenceLimit.min']);
  });

  it('protected payloads are byte-identical; RITAG V3G1 moves to its W4C.4 hash; same input → same bytes', () => {
    const pinned: Array<[M1FixtureSpec, string | null, string]> = [
      [c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION, 'ec28aae74989481586b6bf8512391f5b364ab14448592db1615375ec0038e4d3'],
      [c31Spec('C3F-RITAG'), DECISION, '58df7a0325d3c775cba7054c7a940bbe8f9defd2fd7334f78498c7bbd5feb7fd'],
      [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance, 'fa1eb6d78358d94806e40a555ae8023418e02c0a7c07158e8e8b840268e3b1cc'],
      [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance, 'add92bb5a61e4fc54c7587601fd7d43c669fce9d83ae95755c3d88f4539233d1'],
      [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work, 'd421b7f9006e707086edc8ff6e8fad5963a228e6130946b5d4c60caa1ae59992'],
    ];
    for (const [spec, intention, hash] of pinned) expect(sha(realize(spec, intention))).toBe(hash);
    expect(sha(ritag())).toBe('6170abd3110f2ca73e2d816d9958d3c469c9c2fe6b49832bfe44d03ddd6db9dd');
    expect(sha(ritag())).toBe(sha(ritag()));
  });
});
