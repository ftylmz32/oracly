import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import {
  COFFEE_M2_CONTRACT_GAPS,
  coffeeM2CombineStructural,
  coffeeM2Depth,
  coffeeM2Scenario,
  coffeeM2StructureMeaning,
  interpretCoffeeM2,
  type CoffeeM2StructuralUnit,
  type CoffeeM2Thread,
} from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import type { CoffeeV3Form } from '../src/ai/reading/types.js';
import { COFFEE_V2_SLOTS } from '../src/reading/operation-staged-image-model.js';
import { c31Spec, C31_SET_IDS } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec, type M1MarkSpec } from './fixtures/coffee-m1-fixtures.js';

const ctx = (text: string) => classifyCoffeeIntention(text);
const run = (spec: M1FixtureSpec, intention: string | null = null) => interpretCoffeeM2(m1Map(spec), intention ? ctx(intention) : null);
const only = (spec: M1FixtureSpec, intention: string | null = null): CoffeeM2Thread => {
  const { meaning } = run(spec, intention);
  expect(meaning.threads).toHaveLength(1);
  return meaning.threads[0];
};
const struct = (id: string, form: Partial<CoffeeV3Form>, band: M1MarkSpec['band'] = 'middle', extra: Partial<M1MarkSpec> = {}): M1MarkSpec => ({
  id, label: null, band, form, hours: 3, ...extra,
});
const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const FORBIDDEN_TOKEN = /offer|promotion|salary|payment|bonus|amount|lottery|inheritance|debt|marriage|infidel|they_|sender|reply|employer|company|firing/;

describe('M2 structure lane (A–J)', () => {
  it('A: continuous straight → steady_course', () => {
    expect(only({ marks: [struct('M1', { continuity: 'continuous', course: 'straight' })] })).toMatchObject({
      lane: 'structure', developments: ['steady_course'], valence: 'positive',
    });
  });

  it('B: continuous bending → course_turn', () => {
    expect(only({ marks: [struct('M1', { continuity: 'continuous', course: 'bending' })] }).developments).toEqual(['course_turn']);
  });

  it('C: broken → stop_start_course (cautionary)', () => {
    expect(only({ marks: [struct('M1', { continuity: 'broken', course: 'straight' })] })).toMatchObject({
      developments: ['stop_start_course'], valence: 'cautionary',
    });
  });

  it('D: branching → possibilities_branch (rim placement allowed; broken branching keeps ONE meaning)', () => {
    const t = only({ marks: [struct('M1', { course: 'branching', continuity: 'broken' }, 'rim_upper')] });
    expect(t).toMatchObject({ developments: ['possibilities_branch'], modifiers: ['stop_start'], horizon: 'nearer_term' });
  });

  it('E: branching networks never multiply into several developments', () => {
    const { meaning } = run({ marks: [struct('M1', { course: 'branching' }), struct('M2', { course: 'branching' }, 'middle', { hours: 8 })] });
    expect(meaning.threads).toHaveLength(1);
    expect(meaning.diagnostics.groundedDevelopmentCount).toBe(1);
  });

  it.each([
    ['F: base pool', struct('M1', { openness: 'closed', grouping: 'isolated' }, 'lower_base')],
    ['G: blob', struct('M1', { openness: 'closed', grouping: 'isolated', posture: 'tilted' }, 'middle')],
    ['H: partial band (course unknown)', struct('M1', { continuity: 'continuous' }, 'lower_base')],
    ['I: rim stain band', struct('M1', { continuity: 'continuous', course: 'bending' }, 'rim_upper')],
    ['speckle cluster alone', struct('M1', { grouping: 'clustered' }, 'middle')],
  ])('%s → no thread (context only)', (_name, mark) => {
    const { meaning, audit } = run({ marks: [mark] });
    expect(meaning.threads).toEqual([]);
    expect(meaning.diagnostics.capacity).toBe('insufficient');
    expect(audit.contextGroups).toEqual(['M1']);
  });

  it('J: a trail\'s vertical direction value changes nothing (it is only span evidence)', () => {
    const rising = only({ marks: [struct('M1', { continuity: 'continuous', verticalDirection: 'rising' })] });
    const descending = only({ marks: [struct('M1', { continuity: 'continuous', verticalDirection: 'descending' })] });
    expect(rising).toEqual(descending);
    expect(rising.developments).toEqual(['steady_course']);
    // Without a known course or span evidence there is no course at all.
    expect(run({ marks: [struct('M1', { continuity: 'continuous', verticalDirection: 'level' })] }).meaning.threads).toEqual([]);
    expect(coffeeM2StructureMeaning({ band: 'lower_base', form: { ...EMPTY_FORM, continuity: 'continuous', verticalDirection: 'rising' } })).toBeNull();
  });

  it('saucer material is ignored (saucer lane not implemented)', () => {
    const { meaning } = run({ marks: [{ id: 'S1', label: null, saucer: true, form: { course: 'branching', continuity: 'continuous' } }] });
    expect(meaning.threads).toEqual([]);
  });
});

const EMPTY_FORM: CoffeeV3Form = {
  motion: 'unknown', verticalDirection: 'unknown', openness: 'unknown', course: 'unknown',
  posture: 'unknown', continuity: 'unknown', grouping: 'unknown',
};

describe('M2 ownership (K–N)', () => {
  it('K: a strong object sign owns its mark', () => {
    const { meaning, audit } = run({ marks: [{ id: 'M1', label: 'a bird', form: { continuity: 'continuous', course: 'straight' } }] });
    expect(audit.objectOwnedGroups).toEqual(['M1']);
    expect(meaning.threads.map((t) => [t.lane, t.developments])).toEqual([['object', ['contact']]]);
    // Closed compatibility: a continuous contact mark gains `continuing`, not a course thread.
    expect(meaning.threads[0].modifiers).toContain('continuing');
  });

  it('L: a direction object with a line form produces no duplicate structure thread', () => {
    const { meaning } = run({ marks: [{ id: 'M1', label: 'a winding road', form: { continuity: 'continuous', course: 'bending' } }] });
    expect(meaning.threads).toHaveLength(1);
    expect(meaning.threads[0]).toMatchObject({ lane: 'object', developments: ['direction_change'] });
  });

  it('M: an ambiguous object candidate does not steal the mark from the structure lane', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird or a fish', band: 'middle', form: { course: 'branching' } }] });
    expect(t).toMatchObject({ lane: 'structure', developments: ['possibilities_branch'] });
  });

  it('N: a possible-same identity group is one source (no recurring)', () => {
    const t = only({
      marks: [struct('M1', { course: 'branching' }), struct('M2', { course: 'branching' }, 'middle', { hours: 8 })],
      ambiguities: [['M1', 'M2']],
    });
    expect(t.modifiers).not.toContain('recurring');
  });
});

describe('M2 structural combinations (O–S)', () => {
  const unit = (meaning: CoffeeM2StructuralUnit['meaning'], group: string): CoffeeM2StructuralUnit => ({
    meaning, groups: [group], bands: ['middle'], modifiers: [], closeCircle: false,
  });
  it.each([
    ['O', 'opening_clarity', 'steady_course', 'opening_moves_forward', 'positive'],
    ['P', 'opening_clarity', 'possibilities_branch', 'possibilities_become_visible', 'neutral'],
    ['Q', 'steady_course', 'possibilities_branch', 'course_opens_into_alternatives', 'neutral'],
    ['R', 'stop_start_course', 'opening_clarity', 'stalled_course_finds_room', 'neutral'],
  ] as const)('%s: %s + %s → %s', (_l, a, b, combination, valence) => {
    const [only1] = coffeeM2CombineStructural([unit(a, 'G1'), unit(b, 'G2')]);
    expect(only1).toMatchObject({ combination, valence });
  });

  it('Q (real map): course + possibilities combine into one thread', () => {
    const t = only({ marks: [struct('M1', { continuity: 'continuous', course: 'straight' }), struct('M2', { course: 'branching' }, 'middle', { hours: 8 })] });
    expect(t).toMatchObject({ combination: 'course_opens_into_alternatives', developments: ['steady_course', 'possibilities_branch'] });
  });

  it('S: unlisted pairs stay separate (an object contact and a structural course)', () => {
    const { meaning } = run({ marks: [{ id: 'M1', label: 'a bird' }, struct('M2', { continuity: 'continuous', course: 'straight' }, 'middle', { hours: 8 })] });
    expect(meaning.threads.map((t) => t.combination)).toEqual([null, null]);
  });

  it('separated keeps a curated structural pair apart; no boundary + opening exists', () => {
    const { meaning } = run({
      marks: [struct('M1', { continuity: 'continuous', course: 'straight' }), struct('M2', { course: 'branching' }, 'middle', { hours: 8 })],
      relations: [{ a: 'M1', b: 'M2', kind: 'separated' }],
    });
    expect(meaning.threads.map((t) => t.combination)).toEqual([null, null]);
  });
});

describe('M2 structural domain / context (T–X)', () => {
  const course = { marks: [struct('M1', { continuity: 'continuous', course: 'straight' })] };
  const branching = { marks: [struct('M1', { course: 'branching' })] };
  it('T: career + course → career_progression', () => {
    const t = only(course, CANONICAL_INTENTION_TEXT.career_work);
    expect(t).toMatchObject({ domain: 'career' });
    expect(t.conjecture).toContain('career_progression');
  });
  it('U: money + possibilities → financial_possibilities', () => {
    const t = only(branching, CANONICAL_INTENTION_TEXT.money_finance);
    expect(t).toMatchObject({ domain: 'financial' });
    expect(t.conjecture).toContain('financial_possibilities');
  });
  it('V: decision + branching → decision binding', () => {
    const t = only(branching, DECISION);
    expect(t).toMatchObject({ contextBindings: ['user_decision'], contextForbidden: ['option_identity', 'correct_option'] });
    expect(t.conjecture).toContain('decision_options');
  });
  it('W: person_of_interest gets no structural binding or domain', () => {
    expect(only(branching, CANONICAL_INTENTION_TEXT.person_of_interest)).toMatchObject({ contextBindings: [], domain: null });
  });
  it('X: awaiting_response gets no structural binding', () => {
    expect(only(course, 'Bir yerden dönüş bekliyorum.')).toMatchObject({ contextBindings: [], domain: null });
  });
});

describe('M2 facets / depth (Y–AD)', () => {
  it('Y: duplicate FORWARD semantics count once', () => {
    const t = only({
      marks: [struct('M1', { continuity: 'continuous', course: 'straight' }), struct('M2', { continuity: 'continuous', course: 'straight' }, 'middle', { hours: 8 })],
      relations: [{ a: 'M1', b: 'M2', kind: 'connected' }],
    });
    expect(t.modifiers).toEqual(expect.arrayContaining(['continuing', 'recurring']));
    expect(t.facets.filter((f) => f.cls === 'FORWARD')).toHaveLength(1);
  });
  it('Z: thin', () => {
    expect(only({ marks: [struct('M1', { continuity: 'continuous', course: 'straight' })] }, CANONICAL_INTENTION_TEXT.career_work).depth).toBe('thin');
  });
  it('AA: developed', () => {
    const t = only({ marks: [struct('M1', { course: 'branching' }, 'rim_upper')] }, DECISION);
    expect(t.facets.map((f) => f.category)).toEqual(['core_development', 'horizon', 'user_context']);
    expect(t.depth).toBe('developed');
  });
  it('AB: deep', () => {
    expect(only({ marks: [struct('M1', { course: 'branching', continuity: 'broken' }, 'rim_upper')] }, CANONICAL_INTENTION_TEXT.money_finance).depth).toBe('deep');
  });
  it('AB: >= 4 facets without a domain / context / combination anchor is only developed', () => {
    expect(coffeeM2Depth([
      { category: 'core_development', cls: 'A' }, { category: 'trajectory', cls: 'B' },
      { category: 'horizon', cls: 'C' }, { category: 'scope', cls: 'D' },
    ])).toBe('developed');
  });
  it('AC: valence never counts as a facet', () => {
    const pos = only({ marks: [struct('M1', { continuity: 'continuous', course: 'straight' })] });
    const caut = only({ marks: [struct('M1', { continuity: 'broken', course: 'straight' })] });
    expect(pos.facets.length).toBe(caut.facets.length);
    expect(JSON.stringify(pos.facets)).not.toMatch(/valence|positive|cautionary/);
  });
  it('AD: scenario never changes depth, facets, capacity, horizon or domain', () => {
    const t = only({ marks: [struct('M1', { course: 'branching' })] }, DECISION);
    expect(t.scenario).not.toBeNull();
    expect(t.depth).toBe(coffeeM2Depth(t.facets));
    expect(JSON.stringify(t.facets)).not.toMatch(/secondary_option|options_separating/);
  });
});

describe('M2 scenario permissions (AE–AO)', () => {
  it('AE: career opening', () => {
    const t = run(M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work).meaning.threads[0];
    expect(t.scenario).toMatchObject({ context: 'career', specificity: 'S2', manifestations: ['new_responsibility', 'different_role', 'different_way_of_working'] });
  });
  it('AF: career steady course cannot say new job', () => {
    const t = only({ marks: [struct('M1', { continuity: 'continuous', course: 'straight' })] }, CANONICAL_INTENTION_TEXT.career_work);
    expect(t.scenario?.manifestations).toEqual(['steady_professional_progress']);
    expect(t.scenario?.manifestations.join(' ')).not.toMatch(/new_|role|responsibility/);
  });
  it('AG: money opportunity', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a fish' }] }, CANONICAL_INTENTION_TEXT.money_finance);
    expect(t.scenario).toMatchObject({ context: 'money', manifestations: ['new_financial_opportunity', 'another_earning_channel', 'financial_side_strengthened'] });
  });
  it('AH: love without a declared relationship never assumes a partner', () => {
    const t = only(M1_QA_CUPS.love_ring_heart.spec, CANONICAL_INTENTION_TEXT.love_relationships);
    expect(t.scenario).toMatchObject({ context: 'love', manifestations: ['new_connection_becoming_serious_or_existing_bond_clearer'] });
    expect(t.scenario?.forbidden).toContain('partner_exists_assumed');
  });
  it('AI: love with a declared current relationship', () => {
    const t = only(M1_QA_CUPS.love_ring_heart.spec, 'İlişkim hakkında merak ediyorum.');
    expect(t.scenario).toMatchObject({ context: 'love_current_relationship', manifestations: ['declared_relationship_more_serious', 'bond_more_visible'] });
    expect(t.scenario?.forbidden).toEqual(expect.arrayContaining(['partner_feelings', 'partner_actions', 'shared_plan']));
  });
  it('AJ: decision', () => {
    expect(only({ marks: [struct('M1', { course: 'branching' })] }, DECISION).scenario).toMatchObject({
      context: 'decision', manifestations: ['secondary_option_gaining_weight', 'another_option_relevant', 'options_separating'],
    });
  });
  it('AK: awaiting response', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a folded letter' }] }, 'Bir yerden dönüş bekliyorum.');
    expect(t.scenario).toMatchObject({ context: 'awaited_topic', manifestations: ['communication_around_awaited_matter', 'written_information_relevant'] });
    expect(t.scenario?.forbidden).toEqual(['reply_arrives', 'positive_reply', 'sender', 'timing', 'content']);
  });
  it('AL: person of interest (Contract B)', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, CANONICAL_INTENTION_TEXT.person_of_interest);
    expect(t.scenario).toMatchObject({ context: 'chosen_person', manifestations: ['communication_around_chosen_person', 'conversation_about_person_relevant'] });
    expect(t.scenario?.forbidden).toEqual(expect.arrayContaining(['they_message', 'they_return', 'they_love_user', 'invented_history']));
  });
  it('AM: general invents no domain', () => {
    expect(only({ marks: [{ id: 'M1', label: 'a fish' }] }).scenario).toMatchObject({ context: 'general', specificity: 'S1', manifestations: ['matter_opening'] });
    expect(only({ marks: [{ id: 'M1', label: 'a bird' }] }).scenario).toBeNull();
    expect(only({ marks: [struct('M1', { continuity: 'continuous', course: 'straight' })] }).scenario).toBeNull();
  });
  it('AN: one cluster per thread, at most three manifestations', () => {
    const fixtures = [M1_QA_CUPS.general_rich_three.spec, M1_QA_CUPS.money_fish_tree.spec, M1_QA_CUPS.career_key_path.spec];
    for (const spec of fixtures) {
      for (const t of run(spec, CANONICAL_INTENTION_TEXT.money_finance).meaning.threads) {
        if (t.scenario) expect(t.scenario.manifestations.length).toBeGreaterThanOrEqual(1);
        if (t.scenario) expect(t.scenario.manifestations.length).toBeLessThanOrEqual(3);
      }
    }
  });
  it('AO: forbidden specifics never appear as permitted manifestations', () => {
    const developments = ['contact', 'written_contact', 'opportunity', 'commitment', 'emotional_movement', 'access_opening',
      'direction_change', 'gradual_growth', 'choice_clarification', 'social_presence', 'steady_course', 'course_turn',
      'stop_start_course', 'possibilities_branch', 'opening_clarity'];
    const variants = [
      { contextBindings: [], domain: null },
      { contextBindings: [], domain: 'career' as const },
      { contextBindings: [], domain: 'financial' as const },
      { contextBindings: [], domain: 'love' as const },
      { contextBindings: ['current_relationship' as const], domain: 'love' as const },
      { contextBindings: ['user_decision' as const], domain: null },
      { contextBindings: ['awaited_topic' as const], domain: null },
      { contextBindings: ['chosen_person' as const], domain: null },
    ];
    for (const development of developments) {
      for (const v of variants) {
        const s = coffeeM2Scenario({ developments: [development], ...v });
        if (!s) continue;
        expect(s.manifestations.join(' ')).not.toMatch(FORBIDDEN_TOKEN);
        expect(s.manifestations.some((m) => s.forbidden.includes(m))).toBe(false);
      }
    }
  });
});

describe('M2 fail closed (AP–AQ)', () => {
  it('AP/AQ: an insufficient cup stays insufficient with any intention; scenarios cannot rescue it', () => {
    for (const intention of [null, DECISION, CANONICAL_INTENTION_TEXT.career_work, 'Bir yerden dönüş bekliyorum.']) {
      const { meaning } = run(c31Spec('C3F-UNAL'), intention);
      expect(meaning.threads).toEqual([]);
      expect(meaning.diagnostics).toMatchObject({ capacity: 'insufficient', groundedDevelopmentCount: 0, scenarioAvailable: false, maxDepth: null });
    }
  });
});

describe('M2 C3.1 replay (committed annotations)', () => {
  it('every committed C3.1 set is replayable', () => {
    expect(C31_SET_IDS).toEqual(['C3F-RITAG', 'C3F-HALIL', 'C3F-GAZETA', 'C3F-BASAK', 'C3F-UNAL']);
  });
  it('RITAG + decision: course + possibilities → deep', () => {
    const t = only(c31Spec('C3F-RITAG'), DECISION);
    expect(t).toMatchObject({ combination: 'course_opens_into_alternatives', contextBindings: ['user_decision'], depth: 'deep' });
  });
  it('HALIL + career: steady course stays thin', () => {
    const t = only(c31Spec('C3F-HALIL'), CANONICAL_INTENTION_TEXT.career_work);
    expect(t).toMatchObject({ developments: ['steady_course'], domain: 'career', depth: 'thin' });
  });
  it('GAZETA + decision: possibilities; room_within is a CONTRACT GAP so depth is thin, not developed', () => {
    const t = only(c31Spec('C3F-GAZETA'), 'Önümdeki seçenekler arasında ne yapacağımı düşünüyorum.');
    expect(t).toMatchObject({ developments: ['possibilities_branch'], contextBindings: ['user_decision'], depth: 'thin' });
    expect(t.modifiers).not.toContain('room_within');
    expect(COFFEE_M2_CONTRACT_GAPS).toContain('clear_area_not_representable');
  });
  it('BASAK + money: possibilities + uneven + near + financial → deep', () => {
    const t = only(c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance);
    expect(t).toMatchObject({ developments: ['possibilities_branch'], modifiers: ['stop_start'], horizon: 'nearer_term', domain: 'financial', depth: 'deep' });
  });
  it('UNAL: insufficient', () => {
    expect(run(c31Spec('C3F-UNAL')).meaning.diagnostics.capacity).toBe('insufficient');
  });
});

describe('M2 privacy and dark path (AR–AW)', () => {
  it('AR/AS: every M2 meaning passes the V3 meaning-only boundary and carries no raw visual field', () => {
    const specs: Array<[M1FixtureSpec, string | null]> = [
      ...C31_SET_IDS.map((id) => [c31Spec(id), DECISION] as [M1FixtureSpec, string]),
      ...Object.values(M1_QA_CUPS).map((c) => [c.spec, CANONICAL_INTENTION_TEXT.money_finance] as [M1FixtureSpec, string]),
      [{ marks: [{ id: 'M1', label: 'a bird' }] }, 'Telve ve kulp tarafında ne görünüyor merak ediyorum.'],
    ];
    for (const [spec, intention] of specs) {
      const { meaning } = run(spec, intention);
      expect(() => assertCoffeeV3MeaningOnly(meaning)).not.toThrow();
      expect(JSON.stringify(meaning)).not.toMatch(/"(band|form|rimClock|handleClock|sightingIds|candidates|identityGroup)"/);
    }
  });

  it('AT/AU: no live source (routing, pipeline, worker or writer) imports M2', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    expect(walk(src).filter((p) => /coffee-m2-semantic-engine/.test(readFileSync(p, 'utf8')))).toEqual([]);
  });

  it('AV: V2 slots unchanged', () => {
    expect([...COFFEE_V2_SLOTS]).toEqual(['cup_primary', 'cup_secondary', 'saucer']);
  });
});

describe('M2 combination valence override', () => {
  it('a cautionary course still overrides course_opens_into_alternatives', () => {
    const t = only({ marks: [struct('M1', { continuity: 'broken', course: 'straight' }), struct('M2', { course: 'branching' }, 'middle', { hours: 8 })] });
    expect(t).toMatchObject({ combination: 'course_opens_into_alternatives', valence: 'cautionary' });
  });
});
