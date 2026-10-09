import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2, type CoffeeM2Meaning, type CoffeeM2Thread } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import {
  COFFEE_M2_WRITER_CONSTRAINTS,
  planCoffeeM2Writer,
  toCoffeeM2WriterPayload,
  type CoffeeM2WriterBeat,
  type CoffeeM2WriterPlan,
} from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import { c31Spec, C31_SET_IDS } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const meaningOf = (spec: M1FixtureSpec, intention: string | null) =>
  interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning;

/** The W1–W1.3 writer QA cases (same cups, same intentions). */
const CASES = {
  RITAG: () => meaningOf(c31Spec('C3F-RITAG'), DECISION),
  BASAK: () => meaningOf(c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance),
  MONEY_OBJECT: () => meaningOf(M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance),
  CAREER: () => meaningOf(M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work),
  LOVE: () => meaningOf(M1_QA_CUPS.love_ring_heart.spec, 'İlişkim hakkında merak ediyorum.'),
  PERSON: () => meaningOf(M1_QA_CUPS.person_bird.spec, CANONICAL_INTENTION_TEXT.person_of_interest),
  HALIL: () => meaningOf(c31Spec('C3F-HALIL'), CANONICAL_INTENTION_TEXT.career_work),
  UNAL: () => meaningOf(c31Spec('C3F-UNAL'), CANONICAL_INTENTION_TEXT.general),
};
const plan = (id: keyof typeof CASES) => planCoffeeM2Writer(CASES[id]());

/** Broad sweep: every committed cup under every intention family. */
const INTENTIONS = [
  null,
  DECISION,
  'İlişkim hakkında merak ediyorum.',
  'Bir yerden dönüş bekliyorum.',
  ...Object.values(CANONICAL_INTENTION_TEXT),
];
const SWEEP: Array<[string, CoffeeM2Meaning]> = [
  ...C31_SET_IDS.map((id) => [id, c31Spec(id)] as const),
  ...Object.entries(M1_QA_CUPS).map(([id, cup]) => [id, cup.spec] as const),
].flatMap(([id, spec]) => INTENTIONS.map((intention) => [`${id}|${intention}`, meaningOf(spec, intention)] as [string, CoffeeM2Meaning]));

const classes = (beat: CoffeeM2WriterBeat) => beat.groups.map((g) => g.cls);
const PURPOSES = new Set(['relation', 'development', 'scenario', 'elaboration']);

function forEachPlan(fn: (name: string, meaning: CoffeeM2Meaning, plan: CoffeeM2WriterPlan) => void) {
  for (const [name, meaning] of SWEEP) fn(name, meaning, planCoffeeM2Writer(meaning).plan);
}

// ---------------------------------------------------------------------------
// Synthetic M2 meanings (planner input is M2 MEANING ONLY)
// ---------------------------------------------------------------------------

function thread(partial: Partial<CoffeeM2Thread> & Pick<CoffeeM2Thread, 'developments' | 'facets'>): CoffeeM2Thread {
  return {
    id: 'T1',
    lane: 'object',
    combination: null,
    horizon: 'coming_period',
    developmentHorizons: partial.developments.map((development) => ({ development, horizon: 'coming_period' as const })),
    valence: 'neutral',
    modifiers: [],
    contextBindings: [],
    domain: null,
    conjecture: [],
    forbiddenSpecifics: ['unsupported_causation', 'chronology'],
    contextForbidden: [],
    depth: 'developed',
    scenario: null,
    ...partial,
  };
}
function synthetic(threads: CoffeeM2Thread[]): CoffeeM2Meaning {
  return {
    subject: 'general',
    declaredContext: [],
    intentReference: { kind: 'none' },
    threads,
    diagnostics: {
      capacity: threads.length ? 'multi_thread' : 'insufficient',
      groundedDevelopmentCount: threads.length,
      distinctFacetCount: Math.max(0, ...threads.map((t) => t.facets.length)),
      maxDepth: threads.length ? 'developed' : null,
      scenarioAvailable: threads.some((t) => t.scenario),
    },
  };
}

// ---------------------------------------------------------------------------
// Core invariants
// ---------------------------------------------------------------------------

describe('W2 core invariants (A–X)', () => {
  it('A: insufficient → status insufficient, zero beats, and no provider payload exists', () => {
    const { plan: p } = plan('UNAL');
    expect(p).toMatchObject({ status: 'insufficient', beats: [] });
    expect(() => toCoffeeM2WriterPayload(p)).toThrow('coffee_m2_writer_plan_insufficient');
    expect(planCoffeeM2Writer(synthetic([])).plan).toMatchObject({ status: 'insufficient', beats: [] });
  });

  it('B/C: every beat holds 1–2 independent groups (sweep)', () => {
    forEachPlan((name, _m, p) => {
      for (const beat of p.beats) {
        expect(beat.groups.length, `${name} ${beat.id}`).toBeGreaterThanOrEqual(1);
        expect(beat.groups.length, `${name} ${beat.id}`).toBeLessThanOrEqual(2);
      }
    });
  });

  it('D: an equivalence class is publicly consumed at most once per plan (sweep)', () => {
    forEachPlan((name, _m, p) => {
      const used = p.beats.flatMap(classes).filter((c) => c !== 'SCENARIO');
      expect(new Set(used).size, name).toBe(used.length);
    });
    const { audit } = plan('MONEY_OBJECT');
    expect(new Set(audit.consumedFacetClasses).size).toBe(audit.consumedFacetClasses.length);
  });

  it('E/F: a scenario cluster appears at most once, on exactly one beat, never split (sweep)', () => {
    forEachPlan((name, meaning, p) => {
      for (const t of meaning.threads.filter((x) => x.scenario)) {
        const holders = p.beats.filter((b) => b.threadId === t.id && b.scenario);
        expect(holders.length, name).toBeLessThanOrEqual(1);
        for (const m of t.scenario!.manifestations) {
          const carrying = p.beats.filter((b) => JSON.stringify(b.scenario?.manifestations ?? []).includes(`"${m}"`));
          expect(carrying.length, `${name} ${m}`).toBeLessThanOrEqual(1);
        }
      }
      for (const b of p.beats) {
        if (b.scenario?.placement === 'fused') expect(classes(b)).not.toContain('SCENARIO');
        if (b.scenario && b.scenario.placement !== 'fused') expect(classes(b).filter((c) => c === 'SCENARIO')).toHaveLength(1);
        if (!b.scenario) expect(classes(b)).not.toContain('SCENARIO');
      }
    });
  });

  it('G: a scenario that only restates a consumed class is omitted deterministically (HALIL)', () => {
    const { plan: p, audit } = plan('HALIL');
    expect(p.beats.some((b) => b.scenario)).toBe(false);
    expect(p.omitted).toEqual([{ threadId: 'T1', cls: 'SCENARIO', reason: 'scenario_redundant' }]);
    expect(audit.scenarioConsumed).toEqual([{ threadId: 'T1', placement: 'omitted_redundant', source: 'FORWARD', beatId: null }]);
  });

  it('H: a scenario adding concrete realization is retained (BASAK)', () => {
    const { plan: p } = plan('BASAK');
    expect(p.beats[0].scenario).toMatchObject({ placement: 'shared', realizes: 'MULTIPLICITY', manifestations: ['additional_financial_possibility', 'option_affecting_money_setup'] });
  });

  it('I: a distinct curated relation is represented exactly once, on a beat with its components (sweep)', () => {
    forEachPlan((name, meaning, p) => {
      for (const t of meaning.threads.filter((x) => x.combination && x.combination !== 'contact_in_relationship')) {
        const holders = p.beats.filter((b) => b.threadId === t.id && b.relation);
        const componentsConsumed = p.omitted.some((o) => o.threadId === t.id && o.reason === 'relation_components_consumed');
        expect(holders.length, name).toBe(componentsConsumed ? 0 : 1);
        if (holders[0]) expect(holders[0].relation!.combination, name).toBe(t.combination);
      }
      expect(p.beats.filter((b) => b.relation).length, name).toBeLessThanOrEqual(meaning.threads.length);
    });
  });

  it('I: a co-theme combination keeps its components together without a relation token', () => {
    const t = thread({
      developments: ['contact', 'commitment'],
      combination: 'contact_in_relationship',
      conjecture: ['news', 'lasting_bond_possibility', 'communication_in_relationship'],
      facets: [
        { category: 'core_development', cls: 'COMMUNICATION' },
        { category: 'core_development', cls: 'COMMITMENT' },
        { category: 'relational', cls: 'RELATION_contact_in_relationship' },
      ],
    });
    const { plan: p } = planCoffeeM2Writer(synthetic([t]));
    expect(p.beats).toHaveLength(1);
    expect(p.beats[0]).toMatchObject({ purpose: 'development', relation: null });
    expect(classes(p.beats[0])).toEqual(['COMMUNICATION', 'COMMITMENT']);
    expect(p.omitted).toContainEqual({ threadId: 'T1', cls: 'RELATION_contact_in_relationship', reason: 'relation_not_distinct' });
  });

  it('J: a relation never becomes causation permission', () => {
    forEachPlan((_n, _m, p) => {
      for (const b of p.beats) {
        expect(b.constraints.noCausation).toBe(true);
        if (b.relation) expect(b.relation.mode).toBe('co_development');
      }
      if (p.status === 'planned') expect(p.forbidden.specifics).toContain('unsupported_causation');
    });
    expect(JSON.stringify(toCoffeeM2WriterPayload(plan('RITAG').plan))).not.toMatch(/caus(e|al)"\s*:\s*true|allowCausation/i);
  });

  it('K: no advice permission anywhere', () => {
    forEachPlan((_n, _m, p) => p.beats.forEach((b) => expect(b.constraints.noAdvice).toBe(true)));
    for (const id of Object.keys(CASES) as Array<keyof typeof CASES>) {
      const { plan: p } = plan(id);
      if (p.status !== 'planned') continue;
      const raw = JSON.stringify(toCoffeeM2WriterPayload(p));
      // The only advice key is the prohibition itself; no granting key or advice token exists.
      expect(raw.match(/"\w*advice\w*"/gi)).toEqual(p.beats.map(() => '"noAdvice"'));
      expect(raw).toMatch(/"noAdvice":true/);
      expect(raw).not.toMatch(/"noAdvice":false|"(bekle|acele|sabir|dikkat)/i);
    }
  });

  it('L: no summary / conclusion / closing / payoff beat exists', () => {
    forEachPlan((name, _m, p) => p.beats.forEach((b) => expect(PURPOSES.has(b.purpose), name).toBe(true)));
    expect(COFFEE_M2_WRITER_CONSTRAINTS.noSummary).toBe(true);
  });

  it('M: each horizon stays on its own development (CAREER, MONEY_OBJECT); elaborations carry none', () => {
    const career = plan('CAREER').plan.beats[0].groups;
    expect(career.map((g) => [g.cls, g.horizon])).toEqual([['OPENING', 'coming_period'], ['CHANGE', 'further_out']]);
    const money = plan('MONEY_OBJECT').plan;
    expect(money.beats[0].groups.map((g) => [g.cls, g.horizon])).toEqual([['OPPORTUNITY', 'nearer_term'], ['GROWTH', 'coming_period']]);
    for (const b of money.beats.slice(1)) b.groups.forEach((g) => expect(g.horizon).toBeNull());
  });

  it('N: domain and user context stay qualifiers, never filler beats or groups (sweep)', () => {
    forEachPlan((name, _m, p) => {
      for (const g of p.beats.flatMap((b) => b.groups)) {
        expect(g.cls, name).not.toMatch(/^(DOMAIN_|CONTEXT_|HORIZON|RELATION_)/);
      }
    });
    const ritag = plan('RITAG').plan;
    expect(ritag.beats.map((b) => b.qualifiers.context)).toEqual([
      [{ binding: 'user_decision', mention: 'introduce' }],
      [{ binding: 'user_decision', mention: 'implied' }],
    ]);
  });

  it('O: valence is a tone hint only and never creates or removes a beat', () => {
    const base = CASES.BASAK();
    const shapes = (['positive', 'neutral', 'cautionary'] as const).map((valence) => {
      const p = planCoffeeM2Writer({ ...base, threads: base.threads.map((t) => ({ ...t, valence })) }).plan;
      expect(p.beats.every((b) => b.qualifiers.tone === valence)).toBe(true);
      return JSON.stringify(p.beats.map((b) => [b.purpose, classes(b)]));
    });
    expect(new Set(shapes).size).toBe(1);
  });

  it('P/Q: the planner never changes M2 capacity, depth or the meaning object itself', () => {
    forEachPlan((name, meaning, p) => {
      expect(p.diagnostics.m2, name).toEqual(meaning.diagnostics);
    });
    const meaning = CASES.LOVE();
    const before = JSON.stringify(meaning);
    const deepFreeze = (v: unknown): unknown => {
      if (v && typeof v === 'object') {
        Object.values(v).forEach(deepFreeze);
        Object.freeze(v);
      }
      return v;
    };
    expect(() => planCoffeeM2Writer(deepFreeze(meaning) as CoffeeM2Meaning)).not.toThrow();
    expect(JSON.stringify(meaning)).toBe(before);
  });

  it('R: the planner never creates a development, class or token M2 did not license (sweep)', () => {
    forEachPlan((name, meaning, p) => {
      for (const b of p.beats) {
        const t = meaning.threads.find((x) => x.id === b.threadId)!;
        const licensed = new Set([...t.developments, ...t.modifiers, ...t.conjecture, ...(t.scenario?.manifestations ?? [])]);
        const facetClasses = new Set(t.facets.map((f) => f.cls));
        for (const g of b.groups) {
          if (g.kind !== 'scenario') expect(facetClasses.has(g.cls), `${name} ${g.cls}`).toBe(true);
          g.tokens.forEach((tok) => expect(licensed.has(tok), `${name} ${tok}`).toBe(true));
          if (g.kind === 'core_development') {
            expect(g.tokens.filter((tok) => !t.modifiers.includes(tok) && !t.conjecture.includes(tok)).every((d) => t.developments.includes(d))).toBe(true);
          }
        }
        if (b.relation) expect(b.relation.combination).toBe(t.combination);
        if (b.scenario) expect(b.scenario.manifestations).toEqual(t.scenario!.manifestations);
      }
    });
  });

  it('S/T: forbiddenSpecifics and contextForbidden are preserved for the writer (sweep)', () => {
    forEachPlan((name, meaning, p) => {
      for (const t of meaning.threads) {
        t.forbiddenSpecifics.forEach((f) => expect(p.forbidden.specifics, name).toContain(f));
        t.contextForbidden.forEach((f) => expect(p.forbidden.context, name).toContain(f));
      }
      for (const b of p.beats.filter((x) => x.scenario)) {
        const t = meaning.threads.find((x) => x.id === b.threadId)!;
        expect(b.scenario!.forbidden).toEqual(t.scenario!.forbidden);
      }
    });
  });

  it('U/V/W: the provider payload excludes the audit, passes the meaning-only boundary and carries no raw V3 field', () => {
    for (const id of Object.keys(CASES) as Array<keyof typeof CASES>) {
      const { plan: p } = plan(id);
      if (p.status !== 'planned') continue;
      const payload = toCoffeeM2WriterPayload(p);
      const raw = JSON.stringify(payload);
      expect(() => assertCoffeeV3MeaningOnly(payload)).not.toThrow();
      expect(raw).not.toMatch(/"(omitted|diagnostics|audit|threadId|consumedFacetClasses|omittedReasons|scenarioConsumed|relationConsumed|beatGroupCounts|contractGaps|userDeclaredIntention|intentReference)"/);
      expect(raw).not.toMatch(/"(band|form|rimClock|handleClock|sightingIds|candidates|identityGroup|marks?|evidence|label|description|saucer\w*)"/);
      expect(Object.keys(payload).sort()).toEqual(['beats', 'forbidden', 'subject']);
    }
    // The guard is live inside the boundary: a smuggled private key fails closed.
    const p = plan('RITAG').plan;
    const tampered = { ...p, beats: p.beats.map((b) => ({ ...b, groups: b.groups.map((g) => ({ ...g, tokens: [...g.tokens, 'fincanda'] })) })) };
    expect(() => toCoffeeM2WriterPayload(tampered)).toThrow(/coffee_v3_private_field_leak/);
  });

  it('X: deterministic — the same M2 meaning, serialized repeatedly, gives a byte-identical plan', () => {
    forEachPlan((name, meaning) => {
      const a = JSON.stringify(planCoffeeM2Writer(JSON.parse(JSON.stringify(meaning))));
      const b = JSON.stringify(planCoffeeM2Writer(JSON.parse(JSON.stringify(meaning))));
      expect(a, name).toBe(b);
    });
  });
});

// ---------------------------------------------------------------------------
// Synthetic composition edge cases
// ---------------------------------------------------------------------------

describe('W2 composition edge cases', () => {
  it('a class consumed by an earlier thread is never restated by a later thread', () => {
    const t1 = thread({ id: 'T1', developments: ['steady_course'], facets: [{ category: 'core_development', cls: 'FORWARD' }] });
    const t2 = thread({
      id: 'T2',
      developments: ['gradual_growth'],
      modifiers: ['steady'],
      facets: [{ category: 'core_development', cls: 'GROWTH' }, { category: 'trajectory', cls: 'FORWARD' }],
    });
    const { plan: p } = planCoffeeM2Writer(synthetic([t1, t2]));
    expect(p.beats.map(classes)).toEqual([['FORWARD'], ['GROWTH']]);
    expect(p.omitted).toEqual([{ threadId: 'T2', cls: 'FORWARD', reason: 'class_already_consumed' }]);
  });

  it('a consequence on a two-development thread has no exposed owner and is omitted, never invented', () => {
    const t = thread({
      developments: ['direction_change', 'gradual_growth'],
      combination: 'direction_with_growth',
      conjecture: ['new_direction', 'gradual_development', 'developing_change', 'heart_inclines'],
      facets: [
        { category: 'core_development', cls: 'CHANGE' },
        { category: 'core_development', cls: 'GROWTH' },
        { category: 'relational', cls: 'RELATION_direction_with_growth' },
        { category: 'consequence', cls: 'LEANING' },
      ],
    });
    const { plan: p } = planCoffeeM2Writer(synthetic([t]));
    expect(p.beats).toHaveLength(1);
    expect(p.omitted).toContainEqual({ threadId: 'T1', cls: 'LEANING', reason: 'consequence_owner_ambiguous' });
  });

  it('a second thread with the identical scenario cluster does not repeat it', () => {
    const scenario = { context: 'general' as const, specificity: 'S1' as const, manifestations: ['matter_opening'], forbidden: [] };
    const t1 = thread({ id: 'T1', developments: ['opportunity'], scenario, facets: [{ category: 'core_development', cls: 'OPPORTUNITY' }] });
    const t2 = thread({ id: 'T2', developments: ['social_presence'], scenario, facets: [{ category: 'core_development', cls: 'PEOPLE' }] });
    const { plan: p } = planCoffeeM2Writer(synthetic([t1, t2]));
    expect(p.omitted).toContainEqual({ threadId: 'T2', cls: 'SCENARIO', reason: 'scenario_duplicate' });
  });
});

// ---------------------------------------------------------------------------
// Known regression cases (W1–W1.3 corpus)
// ---------------------------------------------------------------------------

describe('W2 known cases', () => {
  const shape = (p: CoffeeM2WriterPlan) => p.beats.map((b) => [b.purpose, classes(b), b.relation?.combination ?? null, b.scenario?.placement ?? null]);

  it('RITAG: one relational beat (FORWARD + MULTIPLICITY), then the decision scenario; nothing else', () => {
    const { plan: p } = plan('RITAG');
    expect(shape(p)).toEqual([
      ['relation', ['FORWARD', 'MULTIPLICITY'], 'course_opens_into_alternatives', null],
      ['scenario', ['SCENARIO'], null, 'own_beat'],
    ]);
    expect(p.beats[0].groups.map((g) => g.horizon)).toEqual(['coming_period', 'coming_period']);
    expect(p.beats[1].scenario).toMatchObject({ context: 'decision', realizes: 'MULTIPLICITY' });
    expect(p.forbidden.context).toEqual(expect.arrayContaining(['option_identity', 'correct_option']));
  });

  it('BASAK: MULTIPLICITY + money scenario, then UNEVEN on its own; financial + near qualifiers; no chronology', () => {
    const { plan: p } = plan('BASAK');
    expect(shape(p)).toEqual([
      ['development', ['MULTIPLICITY', 'SCENARIO'], null, 'shared'],
      ['elaboration', ['UNEVEN'], null, null],
    ]);
    expect(p.beats[0].groups[0].horizon).toBe('nearer_term');
    expect(p.beats.map((b) => b.qualifiers.domain)).toEqual([
      { domain: 'financial', mention: 'introduce' },
      { domain: 'financial', mention: 'implied' },
    ]);
    expect(p.beats[1].groups[0]).toMatchObject({ about: 'MULTIPLICITY', horizon: null });
    expect(p.beats.every((b) => b.constraints.noChronology && b.constraints.noAdvice && b.constraints.noCausation)).toBe(true);
  });

  it('MONEY_OBJECT: kısmet + growth as one relation (scenario fused with the kısmet), then two elaborations; no explosion', () => {
    const { plan: p } = plan('MONEY_OBJECT');
    expect(shape(p)).toEqual([
      ['relation', ['OPPORTUNITY', 'GROWTH'], 'opportunity_with_gradual_growth', 'fused'],
      ['elaboration', ['MOMENTUM'], null, null],
      ['elaboration', ['FORWARD', 'MULTI_STREAM'], null, null],
    ]);
    expect(p.beats[0].relation!.conjecture).toEqual(['growing_kismet']);
    expect(p.beats[0].groups[0].tokens).toEqual(expect.arrayContaining(['kismet', 'beautiful_kismet']));
    expect(p.beats[0].scenario).toMatchObject({ realizes: 'OPPORTUNITY', context: 'money' });
    expect(p.beats.map((b) => b.groups.map((g) => g.about))).toEqual([[null, null], ['OPPORTUNITY'], ['GROWTH', 'GROWTH']]);
  });

  it('CAREER: access-through-direction relation once (own horizons), career scenario once; no "alıştığın" presupposition', () => {
    const { plan: p } = plan('CAREER');
    expect(shape(p)).toEqual([
      ['relation', ['OPENING', 'CHANGE'], 'access_through_direction', null],
      ['scenario', ['SCENARIO'], null, 'own_beat'],
    ]);
    expect(p.beats[1].scenario).toMatchObject({ context: 'career', realizes: 'OPENING' });
    expect(JSON.stringify(p)).not.toMatch(/accustomed|usual|al[ıi]st[ıi]g|previous|again/i);
    expect(p.beats.every((b) => b.constraints.noPresupposition)).toBe(true);
  });

  it('LOVE: bond + feeling relation once, the overlapping scenario fused with the bond (one use), no beat > 2 groups', () => {
    const { plan: p } = plan('LOVE');
    expect(shape(p)).toEqual([
      ['relation', ['COMMITMENT', 'FEELING'], 'commitment_with_emotion', 'fused'],
      ['elaboration', ['SINGULAR', 'DURABLE'], null, null],
      ['elaboration', ['LEANING'], null, null],
    ]);
    expect(p.beats[0].scenario).toMatchObject({ realizes: 'COMMITMENT', manifestations: ['declared_relationship_more_serious', 'bond_more_visible'] });
    expect(p.beats.filter((b) => b.scenario)).toHaveLength(1);
    expect(p.beats.filter((b) => b.relation)).toHaveLength(1);
    expect(p.omitted).toEqual([{ threadId: 'T1', cls: 'CLOSE_CIRCLE', reason: 'modifier_owner_ambiguous' }]);
    expect(p.forbidden.context).toEqual(expect.arrayContaining(['partner_feelings', 'partner_action', 'relationship_outcome']));
  });

  it('PERSON: one limited beat; Contract B forbiddens preserved', () => {
    const { plan: p } = plan('PERSON');
    expect(shape(p)).toEqual([['development', ['COMMUNICATION', 'QUIET'], null, 'fused']]);
    expect(p.beats[0].qualifiers.context).toEqual([{ binding: 'chosen_person', mention: 'introduce' }]);
    expect(p.beats[0].scenario!.forbidden).toEqual(expect.arrayContaining(['they_message', 'they_call', 'they_return', 'they_miss_user', 'they_love_user', 'reconciliation', 'invented_history']));
    expect(p.forbidden.specifics).toEqual(expect.arrayContaining(['other_person_feelings', 'other_person_intent', 'other_person_action', 'guaranteed_contact']));
    expect(p.beats[0].qualifiers.domain).toBeNull();
  });

  it('HALIL: one honest beat; the steady-progress scenario is omitted as redundant', () => {
    const { plan: p } = plan('HALIL');
    expect(shape(p)).toEqual([['development', ['FORWARD'], null, null]]);
    expect(p.beats[0].qualifiers.domain).toEqual({ domain: 'career', mention: 'introduce' });
  });

  it('UNAL: zero beats', () => {
    expect(plan('UNAL').plan.beats).toEqual([]);
  });

  it('known-case totals: max 2 groups/beat, no duplicated relation or scenario', () => {
    for (const id of Object.keys(CASES) as Array<keyof typeof CASES>) {
      const { plan: p } = plan(id);
      expect(Math.max(0, ...p.beats.map((b) => b.groups.length))).toBeLessThanOrEqual(2);
      expect(p.beats.filter((b) => b.relation).length).toBeLessThanOrEqual(1);
      expect(p.beats.filter((b) => b.scenario).length).toBeLessThanOrEqual(1);
    }
  });
});

// ---------------------------------------------------------------------------
// Dark path
// ---------------------------------------------------------------------------

describe('W2 dark path', () => {
  const src = resolve(process.cwd(), 'src');
  const walk = (dir: string): string[] =>
    readdirSync(dir).flatMap((name) => {
      const path = join(dir, name);
      return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
    });
  const users = (pattern: RegExp) =>
    walk(src)
      .filter((path) => pattern.test(readFileSync(path, 'utf8')))
      .map((path) => path.slice(src.length + 1).replace(/\\/g, '/'))
      .sort();

  it('nothing live imports the W2 planner (no routing, pipeline, worker, writer or public API); only the dark W4A bank and W4C policy do', () => {
    expect(users(/coffee-m2-writer-beat-plan/)).toEqual(['ai/reading/coffee-m2-turkish-realization-policy.ts', 'ai/reading/coffee-m2-turkish-surface-bank.ts']);
  });

  it('only the dark W2 planner imports M2', () => {
    expect(users(/coffee-m2-semantic-engine/)).toEqual(['ai/reading/coffee-m2-writer-beat-plan.ts']);
  });

  it('the planner reads M2 meaning only: no audit, evidence or observer access', () => {
    const planner = readFileSync(join(src, 'ai/reading/coffee-m2-writer-beat-plan.ts'), 'utf8');
    expect(planner).not.toMatch(/\.audit\b|threadEvidence|identityGroup|cupMarks|saucerMarks|CoffeeV3MarkMap|CoffeeMultiViewObservationV3|interpretCoffeeM2\(|\.band\b|\.form\b/);
  });
});
