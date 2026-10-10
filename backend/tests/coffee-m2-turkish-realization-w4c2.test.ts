import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer, type CoffeeM2WriterPlan } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import {
  COFFEE_TURKISH_GLOBAL_AVOID,
  COFFEE_TURKISH_RELATION_WORDING,
  COFFEE_TURKISH_SCENARIO_CLUSTERS,
  COFFEE_TURKISH_SCENARIO_WORDING,
} from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
import {
  COFFEE_TURKISH_CONTEXT_GENERIC_SUBJECTS,
  COFFEE_TURKISH_LEXICAL_FAMILIES,
  coffeeM2RichOpeningDecisionShape,
  prepareCoffeeM2TurkishRealization,
} from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import {
  checkCoffeeM2TurkishRealization,
  validateCoffeeM2ScenarioSelection,
} from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

/**
 * W4A.2 / W4C.2 — closes the R3 surface space of the rich opening + decision
 * composition (M2.3): generic relation carrier, "ön-" / "belir-" cross-beat
 * repetition, and a single-item concrete layer. Language / policy only.
 */

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const W = 'secondary_option_gaining_weight';
const R = 'another_option_relevant';
const S = 'options_separating';
const fold = (s: string) =>
  s.normalize('NFC').toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/â/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u');
const sha = (v: unknown) => createHash('sha256').update(JSON.stringify(v)).digest('hex');
const planOf = (spec: M1FixtureSpec, intention: string | null) =>
  planCoffeeM2Writer(interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning).plan;
const realize = (spec: M1FixtureSpec, intention: string | null) => prepareCoffeeM2TurkishRealization(planOf(spec, intention));
const ritag = () => realize(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION);
const codes = (texts: string[], items: string[][] = [[], [W, S]]) => {
  const p = ritag();
  return [...checkCoffeeM2TurkishRealization(p, texts), ...validateCoffeeM2ScenarioSelection(p, items)].map((v) => `${v.beat ?? '-'}:${v.code}:${v.detail}`);
};
const clusterOf = (p: ReturnType<typeof ritag>) =>
  p.wording.scenarioClusters.find((c) => JSON.stringify(c.manifestations) === JSON.stringify([W, R, S]))?.choose;

/** Exact provider outputs on the current M2.1 payload (scratchpad m22/ and m23/). */
const OBSERVED: Record<string, [string, string]> = {
  S0: ['Önündeki karar konusunda biraz daha ileride önün açılıyor; konu da yaklaşan dönemde kendi akışında ilerliyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S1: ['Önündeki karar konusunda konu yaklaşan dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S2: ['Vermen gereken kararda konu önümüzdeki dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S3: ['Önündeki karar konusunda konu önümüzdeki dönemde kendi akışında ilerliyor; biraz daha ileride önünü açan bir yol da beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
};

/** Manual premium ceiling (zero provider): B2 realizes W + S. */
const MANUAL: [string, string] = [
  'Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.',
  'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
];

const movesForward = COFFEE_TURKISH_RELATION_WORDING.opening_moves_forward.forms.relational!;

describe('W4A.2 opening_moves_forward row', () => {
  it('no generic carrier, no horizon, no simultaneity, no belir-, both components, no causation, no visual wording', () => {
    expect(movesForward).toEqual([
      'yolun yerinde saymıyor; önün de açılıyor',
      'yolun adım adım ilerliyor; önün de açılıyor',
      'yolun yerinde saymıyor; açılıyor da',
      'yolun adım adım ilerliyor; açılıyor da',
    ]);
    for (const f of movesForward) {
      const t = fold(f);
      expect(t, f).not.toMatch(/\b(konu|isler|gidisat)\b/);
      expect(t, f).not.toMatch(/\b(yakin\w*|ileri(de|ki)|ilerleyen|donem\w*|zaman\w*|gunler\w*|gecmeden)\b/);
      expect(t, f).not.toMatch(/\w+(ir|ur|ar|er|yor)ken\b|\b(ayni anda|eszamanli|o sirada|birlikte|bir yandan)\b/);
      expect(t, f).not.toMatch(/\bbelir/);
      expect(t, `${f}: FORWARD`).toMatch(/yerinde saymi|adim adim ilerl/);
      expect(t, `${f}: OPENING`).toMatch(/acil(iyor)/);
      expect(t, f).not.toMatch(/sayesinde|yuzunden|bu yuzden|boylece|dolayisiyla|sonucunda|sagla|neden ol|\w+(dikca|dikce)\b/);
      expect(t, f).not.toMatch(/\b(fincan|telve|alan|bosluk|aciklik|cizgi|sekil|iz|leke)\b/);
      for (const banned of COFFEE_TURKISH_GLOBAL_AVOID) expect(t.includes(fold(banned)), `${f} ~ ${banned}`).toBe(false);
      expect(f.split(';'), f).toHaveLength(2);
    }
    // Forms that do not need "ön-" exist, so B1 can leave the family to B2.
    expect(movesForward.filter((f) => !/ön/.test(f)).length).toBeGreaterThanOrEqual(2);
  });
});

describe('W4C.2 generic context subject (A–D)', () => {
  const b1 = (subject: string) => `Vermen gereken kararda ${subject} yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.`;
  it('A/B/C: standalone konu / işler / gidişat fail on the decision-framed opening_moves_forward beat', () => {
    expect(ritag().realization.beats[0].forbiddenGenericSubjects).toEqual([...COFFEE_TURKISH_CONTEXT_GENERIC_SUBJECTS.opening_moves_forward]);
    expect(codes([b1('konu'), MANUAL[1]])).toEqual(['B1:GENERIC_CONTEXT_SUBJECT:konu']);
    expect(codes([b1('işler'), MANUAL[1]])).toEqual(['B1:GENERIC_CONTEXT_SUBJECT:işler']);
    expect(codes([b1('gidişat'), MANUAL[1]])).toEqual(['B1:GENERIC_CONTEXT_SUBJECT:gidişat']);
  });

  it('D: "karar konusunda" is not the token "konu"', () => {
    expect(codes(['Vermen gereken karar konusunda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.', MANUAL[1]])).toEqual([]);
  });

  it('the decision surface is beat-local: B1 offers the non-"ön" forms and avoids "önündeki karar"; the global row is untouched', () => {
    const p = ritag();
    expect(p.realization.beats[0].contextWording).toEqual({ user_decision: ['vermen gereken kararda', 'karar meselende'] });
    expect(p.realization.beats[0].avoidWording).toEqual(['önündeki karar', 'kararın ilerl', 'kararın netleş', 'kararın kesinleş', 'doğru karar']);
    expect(p.wording.contexts.user_decision.modifier).toEqual(['önündeki karar konusunda', 'vermen gereken kararda', 'karar meselende']);
    expect(p.realization.beats[1].forbiddenGenericSubjects).toBeUndefined();
    expect(p.realization.beats[1].contextWording).toBeUndefined();
  });

  it('without a decision the relation carries no context rule', () => {
    const p = realize(c31Spec('C3F-RITAG', { clearAreas: true }), CANONICAL_INTENTION_TEXT.general);
    const rel = p.realization.beats.find((_, i) => p.beats[i].relation?.combination === 'opening_moves_forward')!;
    expect(rel.forbiddenGenericSubjects).toBeUndefined();
    expect(rel.contextWording).toBeUndefined();
    expect(rel.avoidWording).toEqual([]);
  });
});

describe('W4C.2 observed R3 readings are rejected (E–H)', () => {
  const expected: Record<string, string[]> = {
    S0: ['B1:BEAT_AVOID:önündeki karar', 'B1:GENERIC_CONTEXT_SUBJECT:konu', 'B2:SAME_OPENER_AS_PREVIOUS:onundeki', '-:CROSS_BEAT_LEXICAL_COLLISION:FRONT_ON: B1+B2', 'B2:SCENARIO_TOO_FEW:1 < 2'],
    S1: ['B1:BEAT_AVOID:önündeki karar', 'B1:GENERIC_CONTEXT_SUBJECT:konu', 'B2:SAME_OPENER_AS_PREVIOUS:onundeki', '-:CROSS_BEAT_LEXICAL_COLLISION:FRONT_ON: B1+B2', 'B2:SCENARIO_TOO_FEW:1 < 2'],
    S2: ['B1:GENERIC_CONTEXT_SUBJECT:konu', '-:CROSS_BEAT_LEXICAL_COLLISION:FRONT_ON: B1+B2', '-:CROSS_BEAT_LEXICAL_COLLISION:PREDICATE_BELIR: B1+B2', 'B2:SCENARIO_TOO_FEW:1 < 2'],
    S3: ['B1:BEAT_AVOID:önündeki karar', 'B1:GENERIC_CONTEXT_SUBJECT:konu', '-:CROSS_BEAT_LEXICAL_COLLISION:FRONT_ON: B1+B2', '-:CROSS_BEAT_LEXICAL_COLLISION:PREDICATE_BELIR: B1+B2', 'B2:SCENARIO_TOO_FEW:1 < 2'],
  };
  for (const [id, texts] of Object.entries(OBSERVED)) {
    it(`${id}: fails deterministic acceptance; the checker alone also rejects it`, () => {
      expect(codes(texts, [[], [W]])).toEqual(expected[id]);
      expect(checkCoffeeM2TurkishRealization(ritag(), texts).length).toBeGreaterThan(0);
    });
  }
});

describe('W4C.2 cross-beat word families (I–L)', () => {
  it('I: "ön-" in both beats is a collision', () => {
    expect(codes(['Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride önün de açılıyor.', MANUAL[1]]))
      .toEqual(['-:CROSS_BEAT_LEXICAL_COLLISION:FRONT_ON: B1+B2']);
  });

  it('J: "ön-" in only one beat passes (B2 here; B1 alone too)', () => {
    expect(codes(MANUAL)).toEqual([]);
    expect(codes([
      'Vermen gereken kararda yolun önümüzdeki dönemde yerinde saymıyor; biraz daha ileride açılıyor da.',
      'Yaklaşan günlerde birkaç seçenek birden ortaya çıkıyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
    ])).toEqual([]);
  });

  it('K: "belir-" in both beats is a collision', () => {
    expect(codes([
      'Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride bir yol da beliriyor.',
      'Bundan sonraki zamanda birkaç ayrı ihtimal beliriyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
    ])).toEqual(['-:CROSS_BEAT_LEXICAL_COLLISION:PREDICATE_BELIR: B1+B2']);
  });

  it('L: "belir-" in only one beat passes; "belirli" is not in the family', () => {
    expect(codes([
      MANUAL[0],
      'Önündeki günlerde birkaç ayrı ihtimal beliriyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
    ])).toEqual([]);
    expect(COFFEE_TURKISH_LEXICAL_FAMILIES.PREDICATE_BELIR).not.toContain('belirli');
    expect(COFFEE_TURKISH_LEXICAL_FAMILIES.FRONT_ON).not.toContain('önce');
    expect(ritag().realization.crossBeat.lexicalCollisionFamilies?.map((f) => [f.family, f.beats, f.rule])).toEqual([
      ['FRONT_ON', [1, 2], 'not_in_both'],
      ['PREDICATE_BELIR', [1, 2], 'not_in_both'],
    ]);
  });
});

describe('W4C.2 scoped two-item scenario (M–V)', () => {
  it('M: the rich opening + decision shape narrows its own cluster to exactly two', () => {
    const plan = planOf(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION);
    expect(coffeeM2RichOpeningDecisionShape(plan)).toEqual({ relation: 0, scenario: 1 });
    expect(clusterOf(prepareCoffeeM2TurkishRealization(plan))).toEqual({ min: 2, max: 2 });
  });

  it('N: the same plan without rich capacity keeps 1–2 (detection is semantic, not by fixture)', () => {
    const plan: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(planOf(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION)));
    plan.diagnostics.m2.capacity = 'multi_thread';
    expect(coffeeM2RichOpeningDecisionShape(plan)).toBeNull();
    expect(clusterOf(prepareCoffeeM2TurkishRealization(plan))).toEqual({ min: 1, max: 2 });
    // A lone decision branching cup keeps the global contract too.
    const lone = realize({ marks: [{ id: 'W1', label: null, band: 'middle', form: { course: 'branching' } }] }, DECISION);
    expect(lone.realization.crossBeat.lexicalCollisionFamilies).toBeUndefined();
    for (const c of lone.wording.scenarioClusters) expect(c.choose).toEqual(COFFEE_TURKISH_SCENARIO_CLUSTERS[c.manifestations.join('|')].choose);
  });

  it('O/P: GAZETA and the old RITAG shape keep min 1 / max 2 and no word-family rule', () => {
    for (const p of [realize(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION), realize(c31Spec('C3F-RITAG'), DECISION)]) {
      expect(clusterOf(p)).toEqual({ min: 1, max: 2 });
      expect(p.realization.crossBeat.lexicalCollisionFamilies).toBeUndefined();
    }
    expect(COFFEE_TURKISH_SCENARIO_CLUSTERS[[W, R, S].join('|')]).toEqual({ mode: 'alternatives', choose: { min: 1, max: 2 } });
  });

  it('Q: the incompatible pair still fails', () => {
    expect(codes(MANUAL, [[], [R, S]])).toEqual(['B2:SCENARIO_INCOMPATIBLE_PAIR:another_option_relevant+options_separating']);
  });

  it('R/S: W + S passes; W + R is closed by the W4C.3 shape-scoped pair', () => {
    expect(codes(MANUAL, [[], [W, R]])).toEqual(['B2:SCENARIO_INCOMPATIBLE_PAIR:secondary_option_gaining_weight+another_option_relevant']);
    expect(codes(MANUAL, [[], [W, S]])).toEqual([]);
  });

  it('T: one item now fails SCENARIO_TOO_FEW; three fail SCENARIO_TOO_MANY', () => {
    expect(codes(MANUAL, [[], [W]])).toEqual(['B2:SCENARIO_TOO_FEW:1 < 2']);
    expect(codes(MANUAL, [[], [W, R, S]])).toEqual([
      'B2:SCENARIO_TOO_MANY:3 > 2',
      'B2:SCENARIO_INCOMPATIBLE_PAIR:another_option_relevant+options_separating',
      'B2:SCENARIO_INCOMPATIBLE_PAIR:secondary_option_gaining_weight+another_option_relevant',
    ]);
  });

  it('U/V: no permission changes and no new scenario ID — only choose narrows', () => {
    const p = ritag();
    const [b1, b2] = p.beats;
    expect(b1.scenario).toBeNull();
    expect(b2.scenario?.manifestations).toEqual([W, R, S]);
    expect(b2.scenario?.forbidden).toEqual(['option_identity', 'correct_option']);
    expect(Object.keys(p.wording.scenarios)).toEqual([W, R, S]);
    for (const id of Object.keys(p.wording.scenarios)) expect(COFFEE_TURKISH_SCENARIO_WORDING[id]).toBeDefined();
    expect(p.wording.scenarioClusters).toEqual([{ manifestations: [W, R, S], mode: 'alternatives', choose: { min: 2, max: 2 } }]);
    expect(p.realization.beats[1].scenarioIncompatiblePairs).toEqual([[R, S], [W, R]]); // [W, R] added by W4C.3
  });
});

describe('W4C.2 freeze protection (W–X) and guards (Y–Z)', () => {
  const PINNED = {
    GAZETA_V3G1: [c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION, 'ec28aae74989481586b6bf8512391f5b364ab14448592db1615375ec0038e4d3'],
    RITAG_OLD: [c31Spec('C3F-RITAG'), DECISION, '58df7a0325d3c775cba7054c7a940bbe8f9defd2fd7334f78498c7bbd5feb7fd'],
    BASAK: [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance, 'fa1eb6d78358d94806e40a555ae8023418e02c0a7c07158e8e8b840268e3b1cc'],
    MONEY_OBJECT: [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance, 'add92bb5a61e4fc54c7587601fd7d43c669fce9d83ae95755c3d88f4539233d1'],
    CAREER: [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work, 'd421b7f9006e707086edc8ff6e8fad5963a228e6130946b5d4c60caa1ae59992'],
  } as const;
  for (const [id, [spec, intention, hash]] of Object.entries(PINNED)) {
    it(`W/X: ${id} provider payload is byte-identical`, () => {
      expect(sha(realize(spec as M1FixtureSpec, intention))).toBe(hash);
    });
  }

  it('the manual premium reading passes every deterministic gate', () => {
    expect(codes(MANUAL, [[], [W, S]])).toEqual([]);
  });

  it('Y: meaning-only guard passes; no raw user text, no audit', () => {
    const p = ritag();
    expect(() => assertCoffeeV3MeaningOnly(p)).not.toThrow();
    const raw = JSON.stringify(p);
    expect(raw.includes(DECISION)).toBe(false);
    expect(raw).not.toMatch(/"(omitted|diagnostics|audit|threadId|capacity|why|jointUnder|requiresToken|requiresContext)"/);
  });

  it('Z: nothing live imports the realization policy or checker', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    expect(
      walk(src)
        .filter((p) => /coffee-m2-turkish-realization-(policy|check)/.test(readFileSync(p, 'utf8')))
        .map((p) => p.slice(src.length + 1).replace(/\\/g, '/'))
        .sort(),
    ).toEqual(['ai/reading/coffee-m2-turkish-realization-check.ts', 'ai/reading/coffee-m2-writer-prompt.ts']);
  });

  it('same input → byte-identical payload', () => {
    expect(sha(ritag())).toBe(sha(ritag()));
  });
});
