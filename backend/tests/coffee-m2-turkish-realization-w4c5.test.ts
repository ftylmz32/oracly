import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer, type CoffeeM2WriterPlan } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { COFFEE_TURKISH_SCENARIO_CLUSTERS } from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
import {
  COFFEE_TURKISH_LEXICAL_FAMILIES,
  COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS,
  coffeeTurkishTokens,
  prepareCoffeeM2TurkishRealization,
  type CoffeeM2TurkishRealizationPayload,
} from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { checkCoffeeM2TurkishRealization, validateCoffeeM2ScenarioSelection } from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { coffeeM2WriterPromptSha256, coffeeM2WriterPromptUncoveredFields } from '../src/ai/reading/coffee-m2-writer-prompt.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

/**
 * W4C.5 — one-pass lexical overlap audit of the rich opening + decision
 * composition. QA ONLY: the ledger and token table below are not runtime
 * policy; they prove every content word the two beats can share was
 * reviewed, and they fail when the reachable surface gains an unreviewed one.
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
const codes = (texts: string[], items: string[][] = [[], [W, S]]) => {
  const p = ritag();
  return [...checkCoffeeM2TurkishRealization(p, texts), ...validateCoffeeM2ScenarioSelection(p, items)].map((v) => `${v.beat ?? '-'}:${v.code}:${v.detail}`);
};

// ---------------------------------------------------------------------------
// Writer-visible surface of each beat (from the payload, never from outputs)
// ---------------------------------------------------------------------------

/** Every phrase a beat may draw on: its classes in their legal roles, horizons, tokens, relation, scenarios, context, domain, referents. */
function beatSurface(p: CoffeeM2TurkishRealizationPayload, i: number): string[] {
  const beat = p.beats[i];
  const rb = p.realization.beats[i];
  const out: string[] = [];
  for (const { cls, roles } of rb.groupRoles) {
    const row = p.wording.classes[cls] as Record<string, string[] | undefined>;
    for (const role of roles) out.push(...(row?.[role] ?? []));
  }
  for (const g of beat.groups) {
    if (g.horizon && p.wording.horizons[g.horizon]) out.push(...p.wording.horizons[g.horizon]);
    for (const t of g.tokens) out.push(...Object.entries(p.wording.tokens[t] ?? {}).filter(([k]) => k !== 'avoid').flatMap(([, v]) => v ?? []));
  }
  if (beat.relation) out.push(...(p.wording.relations[beat.relation.combination].relational ?? []));
  for (const m of beat.scenario?.manifestations ?? []) out.push(...(p.wording.scenarios[m].lead ?? []), ...(p.wording.scenarios[m].scenario ?? []));
  for (const c of beat.qualifiers.context) {
    const ctx = p.wording.contexts[c.binding];
    out.push(...(rb.contextWording?.[c.binding] ?? [...(ctx.lead ?? []), ...(ctx.modifier ?? [])]));
  }
  if (beat.qualifiers.domain) out.push(...(p.wording.domains[beat.qualifiers.domain.domain] ?? []));
  out.push(...(rb.referent?.referents ?? []), ...Object.values(rb.domainWording).flat());
  return out;
}

// ---------------------------------------------------------------------------
// QA token → family table (closed, manual; not a stemmer)
// ---------------------------------------------------------------------------

const FUNCTION_WORDS = new Set(['bir', 'biri', 'birkaç', 'birden', 'fazla', 'tek', 'de', 'da', 'ne', 'hangi', 'olduğu', 'göre']);

const TOKEN_FAMILY: Readonly<Record<string, readonly string[]>> = {
  // shared by both beats
  FRONT_ON: ['önümüzdeki', 'önün', 'önünde', 'önündeki', 'önünü'],
  PREDICATE_BELIR: ['beliriyor'],
  PREDICATE_ACIL: ['açan', 'açılan', 'açılıyor'],
  YOL: ['yol', 'yolun', 'yoluna', 'yolunda', 'yolda'],
  HORIZON_PERIOD: ['dönemde', 'günlerde', 'zamanda', 'zamanlarda', 'bundan', 'sonraki', 'yaklaşan', 'uzak'],
  DAHA: ['daha'],
  DECISION_CONTEXT: ['karar', 'kararda', 'konusunda', 'vermen', 'gereken', 'meselende'],
  // one beat only (B1)
  ILER: ['ileride', 'ilerleyen', 'ilerliyor'],
  GENERIC_CARRIER: ['konu', 'gidişat'],
  FORWARD_LEXEMES: ['adım', 'akışında', 'devam', 'eden', 'ediyor', 'istikrarla', 'kendi', 'saymadan', 'saymıyor', 'yerinde', 'yürüyor'],
  OPENING_LEXEMES: ['gelişme'],
  DEGREE_BIRAZ: ['biraz'],
  // one beat only (B2)
  OPTION_SECENEK: ['seçenek', 'seçenekler', 'seçeneklerden'],
  IHTIMAL: ['ihtimal', 'ihtimale'],
  AYRI: ['ayrı', 'ayrılabilir', 'ayrılan', 'ayrılıyor', 'birbirinden'],
  ADJ_ACIK: ['açık'],
  SEC_DISCERN: ['seçilebilir'],
  WEIGHT: ['ağır', 'ağırlık', 'basabilir', 'basan', 'basmaya', 'kazanabilir', 'kazanan'],
  OPTION_SCENARIO_LEXEMES: ['aklına', 'arasındaki', 'başka', 'başlayabilir', 'diğerlerine', 'düşebilir', 'fark', 'farklı', 'gelebilir', 'gelen', 'görünebilir', 'gözünde', 'gündeme', 'masaya', 'net'],
  MULTIPLICITY_LEXEMES: ['kalmıyor', 'ortaya', 'çıkıyor', 'yöne'],
};
const familyOf = new Map(Object.entries(TOKEN_FAMILY).flatMap(([f, toks]) => toks.map((t) => [t, f] as const)));

type Classification = 'BLOCK' | 'ALLOW_BRIDGE' | 'ALLOW_NEUTRAL' | 'ALREADY_BLOCKED';

/** The audit ledger: every family the two beats can share, plus the explicitly checked one-beat families. */
const LEDGER: Readonly<Record<string, { classification: Classification; reason: string }>> = {
  FRONT_ON: { classification: 'ALREADY_BLOCKED', reason: 'W4C.2 not_in_both: "önün açılıyor" and "önündeki günlerde / önünde … ihtimal" stacked the same root (M2.3 samples).' },
  PREDICATE_BELIR: { classification: 'ALREADY_BLOCKED', reason: 'W4C.2 not_in_both: "beliriyor" closing both beats read as a template (M2.3 samples 2–3).' },
  PREDICATE_ACIL: { classification: 'BLOCK', reason: 'B1 OPENING ("önün açılıyor", "önünü açan") and B2 MULTIPLICITY ("ihtimale açılıyor") are distinct layers that sound like one opening said twice (W4P4 sample 3, natural 7).' },
  YOL: { classification: 'ALLOW_BRIDGE', reason: 'B1 "yolun" and B2 "birden fazla yol / hangi yolun" carry one road image from the user\'s path to the options; W4P4 samples 1 and 2 used it and were premium.' },
  HORIZON_PERIOD: { classification: 'ALLOW_NEUTRAL', reason: 'Both beats legitimately carry a horizon; "önümüzdeki dönemde" + "yaklaşan dönemde" stayed natural in premium W4P4 samples 1–2; an identical phrase twice is already barred by the prompt.' },
  DAHA: { classification: 'ALLOW_NEUTRAL', reason: 'Comparative particle ("biraz daha ileride" / "daha net"); both appear in the premium manual reading without any loss.' },
  DECISION_CONTEXT: { classification: 'ALLOW_NEUTRAL', reason: 'B1 introduces the decision, B2 has it as implied (the prompt says not to name it again); this is the existing mention contract, not a word-family defect.' },
};
/** Families audited and found reachable in ONE beat only (no cross-beat risk). */
const ONE_BEAT_ONLY: Readonly<Record<string, string>> = {
  ILER: 'B1 only (FORWARD "ilerliyor", further_out "ileride / ilerleyen"); B2 has no iler- wording.',
  IHTIMAL: 'B2 only (MULTIPLICITY).',
  OPTION_SECENEK: 'B2 only; capped at 2 inside B2 by W4C.4.',
  ADJ_ACIK: 'B2 only ("açık seçilebilir"); an adjective, deliberately NOT part of PREDICATE_ACIL.',
  GENERIC_CARRIER: 'B1 only (FORWARD leads); forbidden there by W4C.2 forbiddenGenericSubjects.',
};

function sharedFamilies(p: CoffeeM2TurkishRealizationPayload) {
  const unknown: string[] = [];
  const fams = [0, 1].map((i) => {
    const set = new Set<string>();
    for (const tok of coffeeTurkishTokens(beatSurface(p, i).join(' '))) {
      if (FUNCTION_WORDS.has(tok)) continue;
      const f = familyOf.get(tok);
      if (f) set.add(f);
      else unknown.push(`B${i + 1}:${tok}`);
    }
    return set;
  });
  return { b1: fams[0], b2: fams[1], shared: [...fams[0]].filter((f) => fams[1].has(f)).sort(), unknown: [...new Set(unknown)].sort() };
}

/** The coverage guard: every reachable word is in the table, every shared family is in the ledger. */
function auditGaps(p: CoffeeM2TurkishRealizationPayload): string[] {
  const { shared, unknown, b1, b2 } = sharedFamilies(p);
  return [
    ...unknown.map((t) => `unreviewed token ${t}`),
    ...shared.filter((f) => !LEDGER[f]).map((f) => `unreviewed shared family ${f}`),
    ...Object.keys(ONE_BEAT_ONLY).filter((f) => b1.has(f) && b2.has(f)).map((f) => `one-beat family now shared ${f}`),
  ];
}

// ---------------------------------------------------------------------------

const W4P4: Record<string, [string, string]> = {
  S1: ['Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.', 'Yaklaşan dönemde birden fazla yol beliriyor; bir seçenek diğerlerine göre daha ağır basabilir ve seçenekler arasındaki fark daha net görünebilir.'],
  S2: ['Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.', 'Yaklaşan dönemde birden fazla yol beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir, hangi yolun ne olduğu da daha açık seçilebilir.'],
  S3: ['Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.', 'Yaklaşan dönemde birkaç ayrı ihtimale açılıyor; seçeneklerden biri gözünde ağırlık kazanabilir ve seçenekler arasındaki fark daha net görünebilir.'],
};
const W4P3_OVER: Array<[string, string]> = [
  ['Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.', 'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir ve seçenekler arasındaki fark daha net görünebilir.'],
  ['Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.', 'Yaklaşan dönemde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir, seçenekler arasındaki fark da daha net görünebilir.'],
];
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

describe('W4C.5 one-pass lexical overlap audit (A–I)', () => {
  it('A/B: the current shape\'s shared families are exactly the ledger, each classified with a reason; no unreviewed word', () => {
    const { shared, unknown } = sharedFamilies(ritag());
    expect(unknown).toEqual([]);
    expect(shared).toEqual(Object.keys(LEDGER).sort());
    for (const [f, e] of Object.entries(LEDGER)) {
      expect(['BLOCK', 'ALLOW_BRIDGE', 'ALLOW_NEUTRAL', 'ALREADY_BLOCKED'], f).toContain(e.classification);
      expect(e.reason.length, f).toBeGreaterThan(20);
    }
    expect(auditGaps(ritag())).toEqual([]);
  });

  it('C/D/F: FRONT_ON and PREDICATE_BELIR are already blocked; PREDICATE_ACIL is blocked; exactly these reach the payload', () => {
    expect(LEDGER.FRONT_ON.classification).toBe('ALREADY_BLOCKED');
    expect(LEDGER.PREDICATE_BELIR.classification).toBe('ALREADY_BLOCKED');
    expect(LEDGER.PREDICATE_ACIL.classification).toBe('BLOCK');
    const blocked = Object.entries(LEDGER).filter(([, e]) => e.classification === 'BLOCK' || e.classification === 'ALREADY_BLOCKED').map(([f]) => f).sort();
    expect(ritag().realization.crossBeat.lexicalCollisionFamilies?.map((f) => f.family).sort()).toEqual(blocked);
  });

  it('E: OPTION_SECENEK is B2-only and handled inside B2 by the W4C.4 cap', () => {
    const { b1, b2 } = sharedFamilies(ritag());
    expect(b1.has('OPTION_SECENEK')).toBe(false);
    expect(b2.has('OPTION_SECENEK')).toBe(true);
    expect(ritag().realization.beats[1].lexicalOccurrenceLimits).toEqual([expect.objectContaining({ family: 'OPTION_SECENEK', max: 2 })]);
    expect(Object.keys(ONE_BEAT_ONLY)).toEqual(expect.arrayContaining(['ILER', 'IHTIMAL', 'OPTION_SECENEK', 'ADJ_ACIK']));
  });

  it('G/H: YOL is an allowed bridge and the horizon / period family is allowed; neither is ever a collision family', () => {
    expect(LEDGER.YOL.classification).toBe('ALLOW_BRIDGE');
    expect(LEDGER.HORIZON_PERIOD.classification).toBe('ALLOW_NEUTRAL');
    const families = Object.keys(COFFEE_TURKISH_LEXICAL_FAMILIES);
    for (const allowed of ['YOL', 'HORIZON_PERIOD', 'DAHA', 'DECISION_CONTEXT']) expect(families).not.toContain(allowed);
    // Their premium precedents stay clean.
    expect(codes(W4P4.S1)).toEqual([]);
    expect(codes(W4P4.S2)).toEqual([]);
  });

  it('I: a new unreviewed shared word, or an unknown word, fails the coverage guard', () => {
    const shared = JSON.parse(JSON.stringify(ritag()));
    shared.wording.classes.MULTIPLICITY.predicate.push('kendi akışında birkaç yöne ayrılıyor');
    expect(auditGaps(shared)).toEqual(['unreviewed shared family FORWARD_LEXEMES']);
    const unknownWord = JSON.parse(JSON.stringify(ritag()));
    unknownWord.wording.classes.MULTIPLICITY.predicate.push('birkaç kola çatallanıyor');
    expect(auditGaps(unknownWord)).toEqual(['unreviewed token B2:kola', 'unreviewed token B2:çatallanıyor']);
    const nowShared = JSON.parse(JSON.stringify(ritag()));
    nowShared.wording.classes.MULTIPLICITY.predicate.push('birkaç ayrı ihtimale doğru ilerliyor');
    expect(auditGaps(nowShared)).toContain('one-beat family now shared ILER');
  });
});

describe('W4C.5 PREDICATE_ACIL and replays (J–R)', () => {
  it('J: the family is verbal only — never açık / açıklık / açıkça', () => {
    const forms = COFFEE_TURKISH_LEXICAL_FAMILIES.PREDICATE_ACIL;
    for (const adj of ['açık', 'açıklık', 'açıkça', 'açıklar', 'seçilebilir']) expect(forms).not.toContain(adj);
    for (const verb of ['açılıyor', 'açılabilir', 'açılır', 'açılan', 'açılacak', 'açılmaya', 'açılırken', 'açıldıkça', 'açıldı', 'açılmış', 'açılıp', 'açan']) expect(forms).toContain(verb);
  });

  it('K/L: W4P4 samples 1 and 2 stay checker-clean', () => {
    expect(codes(W4P4.S1)).toEqual([]);
    expect(codes(W4P4.S2)).toEqual([]);
  });

  it('M: W4P4 sample 3 fails the PREDICATE_ACIL cross-beat collision', () => {
    expect(codes(W4P4.S3)).toEqual(['-:CROSS_BEAT_LEXICAL_COLLISION:PREDICATE_ACIL: B1+B2']);
  });

  it('N: "açık seçilebilir" in B2 does not trip PREDICATE_ACIL next to B1 "açılıyor"', () => {
    expect(coffeeTurkishTokens(W4P4.S2[1])).toContain('açık');
    expect(checkCoffeeM2TurkishRealization(ritag(), W4P4.S2).filter((v) => v.detail.startsWith('PREDICATE_ACIL'))).toEqual([]);
  });

  it('O: the manual premium reading stays clean', () => {
    expect(codes(MANUAL)).toEqual([]);
  });

  it('P/Q/R: historical, W4P2 W + R and W4P3 option-word readings stay rejected', () => {
    for (const texts of HISTORICAL) expect(codes(texts, [[], [W]]).length).toBeGreaterThan(0);
    expect(codes(W4P2_WR, [[], [W, R]])).toContain('B2:SCENARIO_INCOMPATIBLE_PAIR:secondary_option_gaining_weight+another_option_relevant');
    for (const texts of W4P3_OVER) expect(codes(texts)).toContain('B2:LEXICAL_OCCURRENCE_LIMIT:OPTION_SECENEK: 3 > 2');
  });
});

describe('W4C.5 invariants (S–Z)', () => {
  it('S/T/U: choose 2/2, pair rules and the OPTION_SECENEK cap are unchanged', () => {
    const p = ritag();
    expect(p.wording.scenarioClusters.map((c) => c.choose)).toEqual([{ min: 2, max: 2 }]);
    expect(COFFEE_TURKISH_SCENARIO_CLUSTERS[[W, R, S].join('|')]).toEqual({ mode: 'alternatives', choose: { min: 1, max: 2 } });
    expect(p.realization.beats[1].scenarioIncompatiblePairs).toEqual([[R, S], [W, R]]);
    expect(COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS).toHaveLength(4);
    expect(p.realization.beats[1].lexicalOccurrenceLimits?.map((l) => [l.family, l.max])).toEqual([['OPTION_SECENEK', 2]]);
    expect(p.realization.beats[0].lexicalOccurrenceLimits).toBeUndefined();
  });

  it('V/W: the prompt is unchanged and still covers every field', () => {
    expect(coffeeM2WriterPromptSha256()).toBe('bc1b618baa26e2e113e995cc3c02f9e09e5e40d844e6c6b35c6880f599cc9e48');
    expect(coffeeM2WriterPromptUncoveredFields(ritag())).toEqual([]);
  });

  it('X/Y: protected payloads are byte-identical; RITAG V3G1 moves to its W4C.5 hash', () => {
    const pinned: Array<[M1FixtureSpec, string | null, string]> = [
      [c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION, 'ec28aae74989481586b6bf8512391f5b364ab14448592db1615375ec0038e4d3'],
      [c31Spec('C3F-RITAG'), DECISION, '58df7a0325d3c775cba7054c7a940bbe8f9defd2fd7334f78498c7bbd5feb7fd'],
      [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance, 'fa1eb6d78358d94806e40a555ae8023418e02c0a7c07158e8e8b840268e3b1cc'],
      [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance, 'add92bb5a61e4fc54c7587601fd7d43c669fce9d83ae95755c3d88f4539233d1'],
      [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work, 'd421b7f9006e707086edc8ff6e8fad5963a228e6130946b5d4c60caa1ae59992'],
      [{ marks: [{ id: 'T1', label: null, band: 'middle', form: { continuity: 'broken' }, bandCoverage: ['middle', 'lower_base'] }, { id: 'C1', label: null, kind: 'clear_area', band: 'middle' }] } as M1FixtureSpec, null, '11f18ff287e32e54d5db8260968720977cabb42c454bf04cfae6f89c6b2c06b1'],
      [{ marks: [{ id: 'L1', label: null, band: 'middle', topology: 'closed_loop', form: { continuity: 'continuous', course: 'bending', openness: 'closed' } }] } as M1FixtureSpec, null, 'cf45b1efb6b0510456337d73f4bc97c3223e8d15b8fb782cba89b24978b7b085'],
    ];
    for (const [spec, intention, hash] of pinned) expect(sha(realize(spec, intention))).toBe(hash);
    expect(sha(ritag())).toBe('44728784bb4bc6777dd34e6243eaf90f3beea6d8d4ca1d81c74a3d09c891798a');
  });

  it('controls never receive the rich-shape families', () => {
    const none = (p: CoffeeM2TurkishRealizationPayload) => expect(p.realization.crossBeat.lexicalCollisionFamilies).toBeUndefined();
    none(realize(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION));
    none(realize(c31Spec('C3F-RITAG'), DECISION));
    const nonRich: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(ritagPlan()));
    nonRich.diagnostics.m2.capacity = 'multi_thread';
    none(prepareCoffeeM2TurkishRealization(nonRich));
    const nonOpening: CoffeeM2WriterPlan = JSON.parse(JSON.stringify(ritagPlan()));
    nonOpening.beats[0].relation!.combination = 'course_opens_into_alternatives' as never;
    none(prepareCoffeeM2TurkishRealization(nonOpening));
    none(realize(c31Spec('C3F-RITAG', { clearAreas: true }), CANONICAL_INTENTION_TEXT.general));
  });

  it('Z: nothing live imports the policy (only the dark checker and prompt)', () => {
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
});
