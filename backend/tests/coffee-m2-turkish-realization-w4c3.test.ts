import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer, type CoffeeM2WriterPlan } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { COFFEE_TURKISH_SCENARIO_CLUSTERS } from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
import {
  COFFEE_TURKISH_RICH_DECISION_REDUNDANT_PAIR,
  COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS,
  coffeeM2RichOpeningDecisionShape,
  prepareCoffeeM2TurkishRealization,
} from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { checkCoffeeM2TurkishRealization, validateCoffeeM2ScenarioSelection } from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { coffeeM2WriterPromptSha256, coffeeM2WriterPromptUncoveredFields } from '../src/ai/reading/coffee-m2-writer-prompt.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

/**
 * W4C.3 — in the rich opening + decision shape, "another option" next to the
 * beat's own MULTIPLICITY core restates plurality (W4P2: the W + R pair gave
 * the same subpremium B2 twice). Shape-scoped realization pair only.
 */

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const W = 'secondary_option_gaining_weight';
const R = 'another_option_relevant';
const S = 'options_separating';
const CLUSTER = [W, R, S];
const sha = (v: unknown) => createHash('sha256').update(JSON.stringify(v)).digest('hex');
const planOf = (spec: M1FixtureSpec, intention: string | null) =>
  planCoffeeM2Writer(interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning).plan;
const realize = (spec: M1FixtureSpec, intention: string | null) => prepareCoffeeM2TurkishRealization(planOf(spec, intention));
const ritagPlan = () => planOf(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION);
const ritag = () => prepareCoffeeM2TurkishRealization(ritagPlan());
const pairsOf = (p: ReturnType<typeof ritag>) => p.realization.beats.map((b) => b.scenarioIncompatiblePairs);
const hasRedundantPair = (p: ReturnType<typeof ritag>) => pairsOf(p).some((pairs) => pairs.some((x) => x.join('|') === [W, R].join('|')));
const acceptance = (texts: string[], items: string[][]) => {
  const p = ritag();
  return [...checkCoffeeM2TurkishRealization(p, texts), ...validateCoffeeM2ScenarioSelection(p, items)].map((v) => `${v.beat ?? '-'}:${v.code}:${v.detail}`);
};

/** Exact W4P2 provider outputs (scratchpad w4p2/), with their declared scenarioItems. */
const W4P2: Record<string, { texts: [string, string]; items: string[] }> = {
  S1: {
    texts: [
      'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.',
      'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir, başka bir seçenek de gündeme gelebilir.',
    ],
    items: [W, R],
  },
  S2: {
    texts: [
      'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.',
      'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir ve aralarındaki fark daha net görünebilir.',
    ],
    items: [W, S],
  },
  S3: {
    texts: [
      'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.',
      'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir, başka bir seçenek de gündeme gelebilir.',
    ],
    items: [W, R],
  },
};

/** Historical M2.2 / M2.3 outputs (old prompt), each with its single declared item. */
const HISTORICAL: Record<string, [string, string]> = {
  S0: ['Önündeki karar konusunda biraz daha ileride önün açılıyor; konu da yaklaşan dönemde kendi akışında ilerliyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S1: ['Önündeki karar konusunda konu yaklaşan dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S2: ['Vermen gereken kararda konu önümüzdeki dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S3: ['Önündeki karar konusunda konu önümüzdeki dönemde kendi akışında ilerliyor; biraz daha ileride önünü açan bir yol da beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
};

const MANUAL: [string, string] = [
  'Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.',
  'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
];

describe('W4C.3 shape-scoped pair (A–E, I–K)', () => {
  it('A/B/C/D: the scenario beat gains W + R after the existing R + S; the relation beat gains nothing', () => {
    const p = ritag();
    expect(coffeeM2RichOpeningDecisionShape(ritagPlan())).toEqual({ relation: 0, scenario: 1 });
    expect(COFFEE_TURKISH_RICH_DECISION_REDUNDANT_PAIR).toEqual([W, R]);
    expect(pairsOf(p)).toEqual([[], [[R, S], [W, R]]]);
  });

  it('E: choose stays exactly 2 / 2', () => {
    expect(ritag().wording.scenarioClusters).toEqual([{ manifestations: CLUSTER, mode: 'alternatives', choose: { min: 2, max: 2 } }]);
  });

  it('I/J/K: W + S is the only legal selection; one item is too few, three too many', () => {
    const valid = [[W, R], [W, S], [R, S]].filter((pair) => validateCoffeeM2ScenarioSelection(ritag(), [[], pair]).length === 0);
    expect(valid).toEqual([[W, S]]);
    expect(acceptance(MANUAL, [[], [W]])).toEqual(['B2:SCENARIO_TOO_FEW:1 < 2']);
    for (const one of [[R], [S]]) expect(acceptance(MANUAL, [[], one])).toEqual(['B2:SCENARIO_TOO_FEW:1 < 2']);
    expect(acceptance(MANUAL, [[], [W, R, S]])).toContain('B2:SCENARIO_TOO_MANY:3 > 2');
  });
});

describe('W4C.3 W4P2 replays (F–H)', () => {
  it('F: W4P2 sample 1 (W + R) fails SCENARIO_INCOMPATIBLE_PAIR', () => {
    // (Since W4C.4 its triple "seçenek" also trips LEXICAL_OCCURRENCE_LIMIT; the pair violation is pinned.)
    expect(acceptance(W4P2.S1.texts, [[], W4P2.S1.items])).toContain('B2:SCENARIO_INCOMPATIBLE_PAIR:secondary_option_gaining_weight+another_option_relevant');
  });

  it('G: W4P2 sample 2 (W + S) passes the scenario validator and the checker', () => {
    expect(validateCoffeeM2ScenarioSelection(ritag(), [[], W4P2.S2.items])).toEqual([]);
    expect(checkCoffeeM2TurkishRealization(ritag(), W4P2.S2.texts)).toEqual([]);
  });

  it('H: W4P2 sample 3 (W + R) fails SCENARIO_INCOMPATIBLE_PAIR', () => {
    expect(acceptance(W4P2.S3.texts, [[], W4P2.S3.items])).toContain('B2:SCENARIO_INCOMPATIBLE_PAIR:secondary_option_gaining_weight+another_option_relevant');
  });
});

describe('W4C.3 grammar untouched (L–O)', () => {
  it('L: the global incompatible-pair table is unchanged', () => {
    expect(COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS.map((p) => p.pair.join('+'))).toEqual([
      'another_option_relevant+options_separating',
      'new_financial_opportunity+financial_side_strengthened',
      'communication_around_chosen_person+conversation_about_person_relevant',
      'professional_direction_change+other_professional_route',
    ]);
  });

  it('M: the global scenario cluster is unchanged', () => {
    expect(COFFEE_TURKISH_SCENARIO_CLUSTERS[CLUSTER.join('|')]).toEqual({ mode: 'alternatives', choose: { min: 1, max: 2 } });
  });

  it('N/O: M2 and W2 still expose all three manifestations', () => {
    const meaning = interpretCoffeeM2(m1Map(c31Spec('C3F-RITAG', { clearAreas: true })), classifyCoffeeIntention(DECISION)).meaning;
    expect(meaning.threads[1].developments).toEqual(['possibilities_branch']);
    const plan = ritagPlan();
    expect(plan.beats[1].scenario?.manifestations).toEqual(CLUSTER);
    expect(Object.keys(ritag().wording.scenarios)).toEqual(CLUSTER);
  });
});

describe('W4C.3 controls never receive the pair (P–T)', () => {
  it('P/Q: GAZETA (possibilities_become_visible) keeps 1–2, only the global pair, and its exact payload', () => {
    const g = realize(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION);
    expect(hasRedundantPair(g)).toBe(false);
    expect(pairsOf(g)).toEqual([[], [[R, S]]]);
    expect(g.wording.scenarioClusters.map((c) => c.choose)).toEqual([{ min: 1, max: 2 }]);
    expect(sha(g)).toBe('ec28aae74989481586b6bf8512391f5b364ab14448592db1615375ec0038e4d3');
  });

  it('R: non-rich controls with the same cluster (old RITAG shape; RITAG V3G1 below rich)', () => {
    const old = realize(c31Spec('C3F-RITAG'), DECISION);
    expect(old.wording.scenarioClusters.map((c) => c.manifestations)).toEqual([CLUSTER]);
    expect(hasRedundantPair(old)).toBe(false);
    const plan: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(ritagPlan()));
    plan.diagnostics.m2.capacity = 'multi_thread';
    expect(hasRedundantPair(prepareCoffeeM2TurkishRealization(plan))).toBe(false);
  });

  it('S: a rich plan whose relation is not opening_moves_forward (synthetic detector control)', () => {
    const plan: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(ritagPlan()));
    plan.beats[0].relation!.combination = 'course_opens_into_alternatives' as never;
    expect(coffeeM2RichOpeningDecisionShape(plan)).toBeNull();
    expect(hasRedundantPair(prepareCoffeeM2TurkishRealization(plan))).toBe(false);
  });

  it('T: opening_moves_forward without the separate decision MULTIPLICITY scenario', () => {
    const general = realize(c31Spec('C3F-RITAG', { clearAreas: true }), CANONICAL_INTENTION_TEXT.general);
    expect(general.beats.some((b) => b.relation?.combination === 'opening_moves_forward')).toBe(true);
    expect(hasRedundantPair(general)).toBe(false);
    const plan: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(ritagPlan()));
    plan.beats[1].scenario!.manifestations = [W, R] as never;
    expect(coffeeM2RichOpeningDecisionShape(plan)).toBeNull();
  });
});

describe('W4C.3 replays, prompt contract and guards (U–Z)', () => {
  it('U: the historical four bad outputs stay rejected', () => {
    for (const [id, texts] of Object.entries(HISTORICAL)) {
      const codes = acceptance(texts, [[], [W]]);
      expect(codes, id).toContain('B1:GENERIC_CONTEXT_SUBJECT:konu');
      expect(codes, id).toContain('B2:SCENARIO_TOO_FEW:1 < 2');
    }
  });

  it('V: the manual premium reading (W + S) stays accepted', () => {
    expect(acceptance(MANUAL, [[], [W, S]])).toEqual([]);
  });

  it('W/X: the W4P1 prompt is unchanged and still covers every writer-visible field', () => {
    // W4C.4 appended one documented contract line (W4P1 09f22bd6… stays the exact prefix).
    expect(coffeeM2WriterPromptSha256()).toBe('bc1b618baa26e2e113e995cc3c02f9e09e5e40d844e6c6b35c6880f599cc9e48');
    expect(coffeeM2WriterPromptUncoveredFields(ritag())).toEqual([]);
  });

  it('W4E primary payloads, STALLED and WALL_LOOP stay byte-identical; RITAG V3G1 moves to its W4C.3 hash', () => {
    const pinned: Array<[M1FixtureSpec, string | null, string]> = [
      [c31Spec('C3F-RITAG'), DECISION, '58df7a0325d3c775cba7054c7a940bbe8f9defd2fd7334f78498c7bbd5feb7fd'],
      [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance, 'fa1eb6d78358d94806e40a555ae8023418e02c0a7c07158e8e8b840268e3b1cc'],
      [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance, 'add92bb5a61e4fc54c7587601fd7d43c669fce9d83ae95755c3d88f4539233d1'],
      [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work, 'd421b7f9006e707086edc8ff6e8fad5963a228e6130946b5d4c60caa1ae59992'],
      [{ marks: [{ id: 'T1', label: null, band: 'middle', form: { continuity: 'broken' }, bandCoverage: ['middle', 'lower_base'] }, { id: 'C1', label: null, kind: 'clear_area', band: 'middle' }] } as M1FixtureSpec, null, '11f18ff287e32e54d5db8260968720977cabb42c454bf04cfae6f89c6b2c06b1'],
      [{ marks: [{ id: 'L1', label: null, band: 'middle', topology: 'closed_loop', form: { continuity: 'continuous', course: 'bending', openness: 'closed' } }] } as M1FixtureSpec, null, 'cf45b1efb6b0510456337d73f4bc97c3223e8d15b8fb782cba89b24978b7b085'],
    ];
    for (const [spec, intention, hash] of pinned) expect(sha(realize(spec, intention))).toBe(hash);
    expect(sha(ritag())).toBe('6170abd3110f2ca73e2d816d9958d3c469c9c2fe6b49832bfe44d03ddd6db9dd'); // + W4C.4 occurrence limit
  });

  it('Y: nothing live imports the policy', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    expect(
      walk(src)
        .filter((p) => /coffee-m2-turkish-realization-policy/.test(readFileSync(p, 'utf8')))
        .map((p) => p.slice(src.length + 1).replace(/\\/g, '/'))
        .sort(),
    ).toEqual(['ai/reading/coffee-m2-turkish-realization-check.ts', 'ai/reading/coffee-m2-writer-prompt.ts']);
  });

  it('Z: same input → byte-identical result, and the plan is never mutated', () => {
    const plan = ritagPlan();
    const before = JSON.stringify(plan);
    expect(sha(prepareCoffeeM2TurkishRealization(plan))).toBe(sha(prepareCoffeeM2TurkishRealization(plan)));
    expect(JSON.stringify(plan)).toBe(before);
  });
});
