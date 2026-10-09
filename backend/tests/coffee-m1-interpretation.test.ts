import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  COFFEE_M1_FORM_GRAMMAR,
  coffeeM1LabelSign,
  coffeeM1MarkSign,
  interpretCoffeeV3MarkMap,
  type CoffeeFortuneThread,
} from '../src/ai/reading/coffee-m1-interpretation.js';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { assertCoffeeV3MeaningOnly, coffeeV3PrivacyViolations } from '../src/ai/reading/coffee-v3-mark-map.js';
import {
  M12_RELEVANCE_CUPS,
  M1_QA_CUPS,
  canonicalIntention,
  m1Map,
  type CanonicalSubject,
  type M1FixtureSpec,
} from './fixtures/coffee-m1-fixtures.js';

/** A canonical subject kind runs through the REAL classifier; a context is used as given. */
type SubjectInput = CanonicalSubject | Parameters<typeof interpretCoffeeV3MarkMap>[1];
const context = (subject: SubjectInput) => (typeof subject === 'string' ? canonicalIntention(subject) : subject);
const run = (spec: M1FixtureSpec, subject: SubjectInput = null) => interpretCoffeeV3MarkMap(m1Map(spec), context(subject));
const only = (spec: M1FixtureSpec, subject: SubjectInput = null): CoffeeFortuneThread => {
  const { meaning } = run(spec, subject);
  expect(meaning.threads).toHaveLength(1);
  return meaning.threads[0];
};

describe('M1 private sign vocabulary', () => {
  it.each([
    ['a bird gliding', 'incoming_contact'],
    ['a seabird', 'incoming_contact'],
    ['a folded letter', 'written_contact'],
    ['a message slip', 'written_contact'],
    ['an envelope', 'written_contact'],
    ['a bird carrying a letter', 'written_contact'],
    ['a fish', 'opportunity'],
    ['a plain band ring', 'commitment'],
    ['a heart', 'emotion'],
    ['a small key', 'access'],
    ['a winding road', 'direction'],
    ['a fork in a path', 'choice'],
    ['two diverging strokes', 'choice'],
    ['a young tree', 'growth'],
    ['a standing figure', 'social_presence'],
    ['a small arch', null],
    ['a coiled spring', null],
    ['a keyhole', null],
    ['a bird or a fish', 'ambiguous'],
  ] as const)('%s → %s', (label, sign) => {
    expect(coffeeM1LabelSign(label)).toBe(sign);
  });

  it('two usable candidates: same sign classifies, different signs are ambiguous (no first-wins)', () => {
    expect(coffeeM1MarkSign({ candidates: [{ label: 'a bird', usable: true }, { label: 'a small bird', usable: true }] })).toBe('incoming_contact');
    expect(coffeeM1MarkSign({ candidates: [{ label: 'a leaf', usable: true }, { label: 'a bird', usable: true }] })).toBe('incoming_contact');
    expect(coffeeM1MarkSign({ candidates: [{ label: 'a ring', usable: true }, { label: 'a fish', usable: true }] })).toBe('ambiguous');
    expect(coffeeM1MarkSign({ candidates: [{ label: 'a ring', usable: false }] })).toBeNull();
  });
});

describe('M1 fixture matrix', () => {
  it('A: bird only → one contact thread', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] });
    expect(t).toMatchObject({ developments: ['contact'], combination: null, valence: 'neutral' });
    expect(t.conjecture).toEqual(['news', 'communication_movement']);
    expect(run({ marks: [{ id: 'M1', label: 'a bird' }] }).meaning.capacity).toBe('single_thread');
  });

  it('B: two distinct bird marks → recurring contact, nothing stronger', () => {
    const one = only({ marks: [{ id: 'M1', label: 'a bird' }] });
    const two = only({ marks: [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a bird', hours: 8 }] });
    expect(two.modifiers).toEqual(['recurring']);
    expect({ ...two, modifiers: [] }).toEqual({ ...one, modifiers: [] });
    expect(run({ marks: [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a bird', hours: 8 }] }).meaning.capacity).toBe('single_thread');
  });

  it('C: one bird seen in three views → still one development, not recurring', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird', slots: ['cup_handle_far', 'cup_turn_a', 'cup_turn_b'] }] });
    expect(t.developments).toEqual(['contact']);
    expect(t.modifiers).not.toContain('recurring');
  });

  it('D: letter/message-like → written_contact, distinct from incoming contact', () => {
    expect(only({ marks: [{ id: 'M1', label: 'a folded letter' }] }).developments).toEqual(['written_contact']);
    const both = run({ marks: [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a message slip', hours: 8 }] }).meaning;
    expect(both.threads.map((t) => t.developments)).toEqual([['contact'], ['written_contact']]);
  });

  it('E: fish + rim_upper + moving → near-term active opportunity, beautiful kısmet permitted', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a fish', band: 'rim_upper', form: { motion: 'moving' } }] });
    expect(t).toMatchObject({ developments: ['opportunity'], horizon: 'nearer_term', valence: 'positive', modifiers: ['active'] });
    expect(t.conjecture).toEqual(['kismet', 'opportunity', 'beautiful_kismet']);
    const plain = only({ marks: [{ id: 'M1', label: 'a fish' }] });
    expect(plain.conjecture).not.toContain('beautiful_kismet');
  });

  it('F: fish + tree → one opportunity-with-gradual-growth thread', () => {
    const t = only(M1_QA_CUPS.money_fish_tree.spec, 'money_finance');
    expect(t).toMatchObject({
      developments: ['opportunity', 'gradual_growth'],
      combination: 'opportunity_with_gradual_growth',
      linkage: 'co_present',
      horizon: 'coming_period',
      valence: 'positive',
    });
    expect(t.conjecture).toEqual(expect.arrayContaining(['beautiful_kismet', 'abundance', 'growing_kismet']));
    expect(t.modifiers).toEqual(expect.arrayContaining(['active', 'gaining_momentum', 'multi_stream', 'steady']));
  });

  it('G: ring + heart → one relationship theme (commitment with emotion)', () => {
    const t = only(M1_QA_CUPS.love_ring_heart.spec, 'love_relationships');
    expect(t).toMatchObject({ developments: ['commitment', 'emotional_movement'], combination: 'commitment_with_emotion', linkage: 'linked' });
    expect(t.conjecture).toEqual(
      expect.arrayContaining(['serious_heart_kismet_possibility', 'heart_inclines', 'heartfelt_lasting_bond_possibility']),
    );
    expect(t.modifiers).toEqual(expect.arrayContaining(['whole_durable', 'singular_focus', 'leaning', 'close_circle']));
  });

  it('G: commitment in a career cup never claims a heart kısmet', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a ring' }] }, 'career_work');
    expect(t.conjecture).toEqual(['lasting_bond_possibility']);
  });

  it('H: key + bending path → an opening through a change of direction', () => {
    const t = only(M1_QA_CUPS.career_key_path.spec, 'career_work');
    expect(t).toMatchObject({
      developments: ['access_opening', 'direction_change'],
      combination: 'access_through_direction',
      linkage: 'linked',
      // M1.1: curated combination valence (was "the more careful component wins").
      valence: 'positive',
    });
    expect(t.conjecture).toEqual(expect.arrayContaining(['path_opening', 'new_beginning', 'opening_through_new_direction']));
    expect(t.forbiddenSpecifics).toEqual(expect.arrayContaining(['prior_problem', 'travel_or_relocation']));
  });

  it('I: person-of-interest + contact → subject-bound communication, no other-person permissions', () => {
    const t = only(M1_QA_CUPS.person_bird.spec, 'person_of_interest');
    expect(t.subjectBinding).toBe('person_of_interest');
    expect(t.conjecture).toContain('communication_about_chosen_person');
    expect(t.conjecture.join(' ')).not.toMatch(/return|miss|love|think|reconcil|intend|will_|call|text/);
    expect(t.forbiddenSpecifics).toEqual(
      expect.arrayContaining([
        'other_person_action',
        'other_person_feelings',
        'other_person_intent',
        'relationship_history',
        'guaranteed_contact',
        'sender_identity',
      ]),
    );
    expect(only(M1_QA_CUPS.person_bird.spec, null).subjectBinding).toBeNull();
  });

  it('J: conflicting sign candidates → no sign-specific thread from that mark', () => {
    const result = run({ marks: [{ id: 'M1', label: 'a bird or a fish' }] });
    expect(result.meaning.threads).toEqual([]);
    expect(result.meaning.capacity).toBe('insufficient');
    expect(result.audit.ambiguousGroups).toBe(1);
    const conflict = run({
      marks: [{ id: 'M1', resemblances: [{ label: 'a ring', strength: 'strong' }, { label: 'a fish', strength: 'strong' }] }],
    });
    expect(conflict.meaning.threads).toEqual([]);
  });

  it('K: partial-only candidate → no sign-specific fortune', () => {
    expect(run({ marks: [{ id: 'M1', label: 'a fish', visibility: 'partial', form: { motion: 'moving' } }] }).meaning.threads).toEqual([]);
  });

  it('K: weak candidate → no sign-specific fortune', () => {
    expect(run({ marks: [{ id: 'M1', resemblances: [{ label: 'a fish', strength: 'weak' }] }] }).meaning.threads).toEqual([]);
  });

  it('L: an unknown resemblance invents no sign', () => {
    const result = run({ marks: [{ id: 'M1', label: 'a small arch' }] });
    expect(result.meaning.threads).toEqual([]);
    expect(result.audit.unmappedGroups).toBe(1);
  });

  it('M: connected compatible signs → linked combination', () => {
    const t = only({ ...M1_QA_CUPS.money_fish_tree.spec, relations: [{ a: 'M1', b: 'M2', kind: 'connected' }] }, 'money_finance');
    expect(t).toMatchObject({ combination: 'opportunity_with_gradual_growth', linkage: 'linked' });
  });

  it('N: connected but unlisted signs stay separate; the relation gets no meaning', () => {
    const result = run({
      marks: [{ id: 'M1', label: 'a fish' }, { id: 'M2', label: 'a ring', hours: 8 }],
      relations: [{ a: 'M1', b: 'M2', kind: 'connected' }],
    });
    expect(result.meaning.threads.map((t) => [t.developments, t.combination])).toEqual([
      [['opportunity'], null],
      [['commitment'], null],
    ]);
    expect(result.audit.ignoredRelationKinds).toEqual(['connected']);
  });

  it('N: contact + heart combine only for a relationship subject', () => {
    const spec: M1FixtureSpec = { marks: [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a heart', hours: 8 }] };
    expect(run(spec, null).meaning.threads).toHaveLength(2);
    expect(run(spec, 'love_relationships').meaning.threads.map((t) => t.combination)).toEqual(['contact_in_relationship']);
  });

  it('N: separated keeps a curated pair as two independent threads', () => {
    const result = run({ ...M1_QA_CUPS.money_fish_tree.spec, relations: [{ a: 'M1', b: 'M2', kind: 'separated' }] }, 'money_finance');
    expect(result.meaning.threads.map((t) => t.combination)).toEqual([null, null]);
  });

  it('O: crossing creates no conflict meaning', () => {
    const result = run({
      marks: [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a fish', hours: 8 }],
      relations: [{ a: 'M1', b: 'M2', kind: 'crossing' }],
    });
    expect(result.meaning.threads).toHaveLength(1);
    expect(result.meaning.threads[0]).toMatchObject({ combination: 'contact_with_opportunity', linkage: 'co_present' });
    expect(JSON.stringify(result.meaning)).not.toMatch(/conflict|tension|obstacle|block/);
    expect(result.audit.ignoredRelationKinds).toEqual(['crossing']);
  });

  it('P: handle_near → close-circle modifier only', () => {
    const near = only({ marks: [{ id: 'M1', label: 'a bird', hours: 0 }] });
    const neutral = only({ marks: [{ id: 'M1', label: 'a bird', hours: 3 }] });
    expect(near.modifiers).toEqual(['close_circle']);
    expect({ ...near, modifiers: [] }).toEqual({ ...neutral, modifiers: [] });
  });

  it('Q: handle_opposite → no invented meaning', () => {
    const opposite = only({ marks: [{ id: 'M1', label: 'a bird', hours: 6 }] });
    const neutral = only({ marks: [{ id: 'M1', label: 'a bird', hours: 3 }] });
    expect(opposite).toEqual(neutral);
  });

  it('R: band → broad horizon only (no date field exists)', () => {
    expect(only({ marks: [{ id: 'M1', label: 'a bird', band: 'lower_base' }] }).horizon).toBe('further_out');
    expect(only({ marks: [{ id: 'M1', label: 'a bird', band: 'rim_upper' }] }).horizon).toBe('nearer_term');
    expect(only({ marks: [{ id: 'M1', label: 'a bird', band: 'middle' }] }).horizon).toBe('coming_period');
    const t = only({ marks: [{ id: 'M1', label: 'a bird', band: 'lower_base' }] });
    expect(Object.keys(t)).not.toEqual(expect.arrayContaining(['date']));
    expect(t.forbiddenSpecifics).toContain('date');
  });

  it('S: confidence cannot affect meaning; no strength-like field exists', () => {
    const high = run({ marks: [{ id: 'M1', label: 'a fish', confidence: 'high' }, { id: 'M2', label: 'a tree', confidence: 'high', hours: 8 }] });
    const medium = run({ marks: [{ id: 'M1', label: 'a fish', confidence: 'medium' }, { id: 'M2', label: 'a tree', confidence: 'medium', hours: 8 }] });
    expect(high).toEqual(medium);
    expect(JSON.stringify(high.meaning)).not.toMatch(/confidence|visibility|strength|intensity|importance|certainty|score/i);
  });

  it('T: saucer-only flow → no fortune in this iteration', () => {
    const result = run(M1_QA_CUPS.sparse_unmapped_saucer_flow.spec);
    expect(result.meaning.threads).toEqual([]);
    expect(result.meaning.capacity).toBe('insufficient');
    expect(result.audit.saucerContext).toBe('flow');
  });

  it('U: a possible-same-mark group gets no repeat credit', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a bird', hours: 8 }], ambiguities: [['M1', 'M2']] });
    expect(t.modifiers).not.toContain('recurring');
  });

  it('V: a single-theme cup is never rich, however many views and modifiers', () => {
    const result = run({
      marks: [
        { id: 'M1', label: 'a bird', band: 'rim_upper', hours: 0, slots: ['cup_handle_far', 'cup_turn_a', 'cup_turn_b'], form: { motion: 'moving', openness: 'open' } },
        { id: 'M2', label: 'a bird', band: 'lower_base', hours: 6, form: { verticalDirection: 'descending' } },
        { id: 'M3', label: 'a bird', hours: 9 },
      ],
      relations: [{ a: 'M1', b: 'M2', kind: 'continuation_of' }],
    });
    expect(result.meaning.capacity).toBe('single_thread');
    expect(result.meaning.threads[0].modifiers).toEqual(expect.arrayContaining(['recurring', 'continuing', 'reaching']));
  });

  it('W: three genuinely distinct threads with useful modifiers → rich', () => {
    const result = run(M1_QA_CUPS.general_rich_three.spec);
    expect(result.meaning.capacity).toBe('rich');
    expect(result.meaning.threads.map((t) => t.developments[0])).toEqual(['opportunity', 'commitment', 'direction_change']);
  });

  it('W: two developments (a fork-in-a-path label is one choice sign, not two) is multi_thread, not rich', () => {
    const result = run({ marks: [{ id: 'M1', label: 'a fish', form: { motion: 'moving' } }, { id: 'M2', label: 'a fork in a path', hours: 8 }] });
    expect(result.meaning.capacity).toBe('multi_thread');
  });

  it('cautionary valence comes only from its curated row', () => {
    const t = only(M1_QA_CUPS.general_letter_broken.spec);
    expect(t).toMatchObject({ valence: 'cautionary', modifiers: ['intermittent', 'recurring'] });
  });

  it('contradicting forms across marks cancel instead of picking one', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird', form: { motion: 'moving' } }, { id: 'M2', label: 'a bird', hours: 8, form: { motion: 'still' } }] });
    expect(t.modifiers).toEqual(['recurring']);
  });

  it('the form grammar is closed and sign-specific (no generic rising = success)', () => {
    expect(COFFEE_M1_FORM_GRAMMAR.choice).toEqual([]);
    const rising = Object.entries(COFFEE_M1_FORM_GRAMMAR).filter(([, rules]) => rules.some((r) => r.value === 'rising'));
    expect(rising.map(([sign]) => sign).sort()).toEqual(['direction', 'opportunity']);
  });
});

describe('M1 privacy and dark path (X)', () => {
  it('X: every M1 meaning output passes the V3 meaning-only assertion; audit carries the ids', () => {
    for (const [name, cup] of Object.entries(M1_QA_CUPS)) {
      const result = interpretCoffeeV3MarkMap(m1Map(cup.spec), context(cup.subject));
      expect(() => assertCoffeeV3MeaningOnly(result.meaning), name).not.toThrow();
      expect(JSON.stringify(result.meaning), name).not.toMatch(/"M\d|identityGroup|evidence/);
    }
    expect(run(M1_QA_CUPS.money_fish_tree.spec).audit.threadEvidence.T1.identityGroups).toEqual(['M1', 'M2']);
  });

  it('M1 is unrouted: nothing in src imports it, and it consumes only the normalized map', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    const importers = walk(src)
      .filter((path) => /coffee-m1-interpretation/.test(readFileSync(path, 'utf8')))
      .map((path) => path.slice(src.length + 1).replace(/\\/g, '/'));
    // Only the equally dark M2 engine may build on M1.
    expect(importers).toEqual(['ai/reading/coffee-m2-semantic-engine.ts']);
    const engine = readFileSync(join(src, 'ai/reading/coffee-m1-interpretation.ts'), 'utf8');
    expect(engine).not.toMatch(/CoffeeMultiViewObservationV3|\.description|\.confidence|\.visibility|rimClock|handleClock/);
  });
});

describe('M1.1 component horizons', () => {
  const fishTree = (fishBand: 'rim_upper' | 'middle' | 'lower_base' | 'unknown', treeBand: 'rim_upper' | 'middle' | 'lower_base' | 'unknown') =>
    only({ marks: [{ id: 'M1', label: 'a fish', band: fishBand }, { id: 'M2', label: 'a tree', band: treeBand, hours: 8 }] }, 'money_finance');

  it('1: opportunity near + growth middle preserves BOTH horizons', () => {
    const t = fishTree('rim_upper', 'middle');
    expect(t.developmentHorizons).toEqual([
      { development: 'opportunity', horizon: 'nearer_term' },
      { development: 'gradual_growth', horizon: 'coming_period' },
    ]);
    expect(t.horizon).toBe('coming_period');
  });

  it('2: opportunity near + growth lower preserves BOTH horizons', () => {
    expect(fishTree('rim_upper', 'lower_base').developmentHorizons).toEqual([
      { development: 'opportunity', horizon: 'nearer_term' },
      { development: 'gradual_growth', horizon: 'further_out' },
    ]);
  });

  it('3: a same-band combination keeps equal horizons and the shared aggregate', () => {
    const t = fishTree('rim_upper', 'rim_upper');
    expect(t.developmentHorizons.map((d) => d.horizon)).toEqual(['nearer_term', 'nearer_term']);
    expect(t.horizon).toBe('nearer_term');
  });

  it('4: an unknown band stays unspecified for that development only', () => {
    expect(fishTree('rim_upper', 'unknown').developmentHorizons).toEqual([
      { development: 'opportunity', horizon: 'nearer_term' },
      { development: 'gradual_growth', horizon: 'unspecified' },
    ]);
  });

  it('single-development threads carry one deterministic component horizon', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird', band: 'lower_base' }] });
    expect(t.developmentHorizons).toEqual([{ development: 'contact', horizon: 'further_out' }]);
  });

  it('5/6: no date token anywhere and the meaning-only assertion still passes', () => {
    for (const cup of Object.values(M1_QA_CUPS)) {
      const { meaning } = interpretCoffeeV3MarkMap(m1Map(cup.spec), context(cup.subject));
      expect(() => assertCoffeeV3MeaningOnly(meaning)).not.toThrow();
      const text = JSON.stringify(meaning.threads.map(({ forbiddenSpecifics: _f, ...rest }) => rest));
      expect(text).not.toMatch(/date|day|week|month|ocak|subat|mart|nisan|haziran|\d{4}/i);
    }
  });

  it('a near-term component still counts as useful placement for capacity', () => {
    const result = run({
      marks: [
        { id: 'M1', label: 'a fish', band: 'rim_upper' },
        { id: 'M2', label: 'a tree', hours: 8 },
        { id: 'M3', label: 'a ring', hours: 6 },
      ],
    });
    expect(result.meaning.capacity).toBe('rich');
  });
});

describe('M1.1 curated combination valence', () => {
  it('commitment + emotion is a POSITIVE possibility for general / love / person', () => {
    for (const subject of [null, 'love_relationships', 'person_of_interest'] as const) {
      const t = only({ marks: [{ id: 'M1', label: 'a ring' }, { id: 'M2', label: 'a heart', hours: 8 }] }, subject);
      expect(t).toMatchObject({ combination: 'commitment_with_emotion', valence: 'positive' });
      expect(t.conjecture).toEqual(expect.arrayContaining(['lasting_bond_possibility', 'heartfelt_lasting_bond_possibility']));
      expect(t.forbiddenSpecifics).toEqual(
        expect.arrayContaining(['guaranteed_outcome', 'relationship_history', 'other_person_feelings', 'other_person_intent', 'exact_event']),
      );
    }
  });

  it.each([
    ['opportunity_with_gradual_growth', [{ id: 'M1', label: 'a fish' }, { id: 'M2', label: 'a tree', hours: 8 }], null, 'positive'],
    ['access_through_direction', [{ id: 'M1', label: 'a key' }, { id: 'M2', label: 'a road', hours: 8 }], null, 'positive'],
    ['choice_with_direction', [{ id: 'M1', label: 'a crossroad' }, { id: 'M2', label: 'a road', hours: 8 }], null, 'neutral'],
    ['direction_with_growth', [{ id: 'M1', label: 'a road' }, { id: 'M2', label: 'a tree', hours: 8 }], null, 'positive'],
    ['contact_with_opportunity', [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a fish', hours: 8 }], null, 'positive'],
    ['written_contact_with_opportunity', [{ id: 'M1', label: 'a letter' }, { id: 'M2', label: 'a fish', hours: 8 }], null, 'positive'],
    ['contact_in_relationship', [{ id: 'M1', label: 'a bird' }, { id: 'M2', label: 'a heart', hours: 8 }], 'love_relationships', 'neutral'],
  ] as const)('%s → %s valence per the curated table', (combination, marks, subject, valence) => {
    const t = only({ marks: [...marks] }, subject);
    expect(t).toMatchObject({ combination, valence });
  });

  it('intermittent written contact still overrides a positive combination to cautionary', () => {
    const t = only({
      marks: [
        { id: 'M1', label: 'a letter', form: { continuity: 'broken' } },
        { id: 'M2', label: 'a fish', hours: 8, form: { motion: 'moving' } },
      ],
    });
    expect(t).toMatchObject({ combination: 'written_contact_with_opportunity', valence: 'cautionary' });
  });

  it('not everything is positive: single neutral signs stay neutral', () => {
    expect(only({ marks: [{ id: 'M1', label: 'a bird' }] }).valence).toBe('neutral');
    expect(only({ marks: [{ id: 'M1', label: 'a crossroad' }] }).valence).toBe('neutral');
  });
});

describe('M1.2 trusted intention depth', () => {
  const ctx = (text: string) => {
    const c = classifyCoffeeIntention(text);
    if (!c) throw new Error('no context');
    return c;
  };
  const forbiddenOverreach = /partner|their_|they_|response_will|positive_response|which_option|employer|boss|ex_|debt|interview|will_answer|return/;

  it('A: general + bird → no invented personal context', () => {
    const { meaning } = run({ marks: [{ id: 'M1', label: 'a bird' }] }, 'general');
    expect(meaning).toMatchObject({ subject: 'general', declaredContext: [], intentReference: { kind: 'canonical_choice' } });
    expect(meaning.threads[0]).toMatchObject({ contextBindings: [], domain: null, contextForbidden: [] });
  });

  it('B: person_of_interest + bird → chosen-person binding with Contract B bans intact', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, 'person_of_interest');
    expect(t).toMatchObject({ subjectBinding: 'person_of_interest', contextBindings: ['chosen_person'], domain: null });
    expect(t.conjecture).toContain('communication_about_chosen_person');
    expect(t.conjecture.join(' ')).not.toMatch(/return|miss|love_development|think|reconcil|intend|call|text/);
    expect(t.forbiddenSpecifics).toEqual(
      expect.arrayContaining(['other_person_action', 'other_person_feelings', 'other_person_intent', 'relationship_history', 'guaranteed_contact']),
    );
  });

  it('C: custom decision + choice → decision-bound thread', () => {
    const decision = ctx('Bir karar vermem gerekiyor.');
    expect(decision).toMatchObject({ subjectKind: 'custom_decision', declaredFacts: ['decision_exists'] });
    const t = only({ marks: [{ id: 'M1', label: 'a crossroad' }] }, decision);
    expect(t).toMatchObject({ subject: 'custom_decision', contextBindings: ['user_decision'] });
    expect(t.conjecture).toContain('decision_clarity');
    expect(t.contextForbidden).toEqual(['option_identity', 'correct_option']);
    expect(t.forbiddenSpecifics).toContain('invented_options');
  });

  it('D: custom decision + direction → decision-direction permission', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a road', form: { course: 'bending' } }] }, ctx('Bir karar vermem gerekiyor.'));
    expect(t.contextBindings).toEqual(['user_decision']);
    expect(t.conjecture).toEqual(expect.arrayContaining(['new_direction', 'new_beginning', 'decision_direction']));
  });

  it('E: custom decision + an unrelated bird stays ordinary contact', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, ctx('Bir karar vermem gerekiyor.'));
    expect(t).toMatchObject({ developments: ['contact'], contextBindings: [], contextForbidden: [] });
    expect(t.conjecture).toEqual(['news', 'communication_movement']);
  });

  it('F: awaiting_response + written contact → awaited-topic binding', () => {
    const awaiting = ctx('Bir yerden dönüş bekliyorum.');
    expect(awaiting).toMatchObject({ subjectKind: 'custom_other', declaredFacts: ['awaiting_response'] });
    const t = only({ marks: [{ id: 'M1', label: 'a folded letter' }] }, awaiting);
    expect(t.contextBindings).toEqual(['awaited_topic']);
    expect(t.conjecture).toContain('written_news_on_awaited_topic');
    expect(t.contextForbidden).toEqual(['response_certainty', 'positive_response', 'response_content', 'response_timing']);
    expect(t.forbiddenSpecifics).toEqual(expect.arrayContaining(['sender_identity', 'guaranteed_contact', 'date']));
  });

  it('G: awaiting_response + bird → communication-on-awaited-topic binding', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, ctx('Bir yerden dönüş bekliyorum.'));
    expect(t.contextBindings).toEqual(['awaited_topic']);
    expect(t.conjecture).toContain('communication_on_awaited_topic');
  });

  it('H: awaiting_response + fish only → the fish is NOT a response', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a fish' }] }, ctx('Bir yerden dönüş bekliyorum.'));
    expect(t).toMatchObject({ developments: ['opportunity'], contextBindings: [], contextForbidden: [] });
    expect(t.conjecture.join(' ')).not.toMatch(/awaited/);
  });

  it('I: current relationship + ring/heart → current-relationship theme', () => {
    const current = ctx('İlişkim hakkında merak ediyorum.');
    expect(current).toMatchObject({ subjectKind: 'love_relationships', declaredFacts: ['current_relationship'] });
    const t = only(M1_QA_CUPS.love_ring_heart.spec, current);
    expect(t).toMatchObject({ combination: 'commitment_with_emotion', contextBindings: ['current_relationship'], domain: 'love' });
    expect(t.conjecture).toEqual(expect.arrayContaining(['current_relationship_theme', 'love_development']));
  });

  it('J: current relationship + contact → relationship communication theme', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, ctx('Sevgilimle aramızdaki iletişimi merak ediyorum.'));
    expect(t.contextBindings).toEqual(['current_relationship']);
    expect(t.conjecture).toContain('communication_in_current_relationship');
  });

  it('K: current relationship never authorizes partner feelings or actions', () => {
    const t = only(M1_QA_CUPS.love_ring_heart.spec, ctx('İlişkim hakkında merak ediyorum.'));
    expect(t.contextForbidden).toEqual(['partner_feelings', 'partner_action', 'relationship_outcome', 'infidelity', 'marriage_fact']);
    expect(t.forbiddenSpecifics).toEqual(expect.arrayContaining(['other_person_feelings', 'other_person_intent', 'other_person_action']));
    expect(t.conjecture.join(' ')).not.toMatch(forbiddenOverreach);
  });

  it('L: money subject + fish/tree → financial opening/growth permissions', () => {
    const t = only(M1_QA_CUPS.money_fish_tree.spec, 'money_finance');
    expect(t.domain).toBe('financial');
    expect(t.conjecture).toEqual(expect.arrayContaining(['financial_opening', 'financial_growth']));
  });

  it('M: career subject + key/path → career opening/direction permissions', () => {
    const t = only(M1_QA_CUPS.career_key_path.spec, 'career_work');
    expect(t.domain).toBe('career');
    expect(t.conjecture).toEqual(expect.arrayContaining(['career_opening', 'career_direction']));
  });

  it('M: an incompatible sign is not pulled into the domain (career + bird)', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, 'career_work');
    expect(t.domain).toBeNull();
    expect(t.conjecture).toEqual(['news', 'communication_movement']);
  });

  it('N: love subject + ring/heart → love-development permission', () => {
    const t = only(M1_QA_CUPS.love_ring_heart.spec, 'love_relationships');
    expect(t).toMatchObject({ domain: 'love', contextBindings: [] });
    expect(t.conjecture).toContain('love_development');
  });

  it('O: general ring/heart keeps the conventional love possibility but invents no current relationship', () => {
    const t = only(M1_QA_CUPS.love_ring_heart.spec, 'general');
    expect(t.conjecture).toContain('serious_heart_kismet_possibility');
    expect(t).toMatchObject({ domain: null, contextBindings: [] });
    expect(t.conjecture.join(' ')).not.toMatch(/current_relationship/);
  });

  it('P: custom_other text is kept as USER-PROVIDED context and adds no fact', () => {
    const other = ctx('Telve ve kulp tarafında ne görünüyor merak ediyorum.');
    expect(other).toMatchObject({ subjectKind: 'custom_other', declaredFacts: [] });
    const { meaning } = run({ marks: [{ id: 'M1', label: 'a fish' }] }, other);
    expect(meaning).toMatchObject({
      subject: 'custom_other',
      declaredContext: [],
      intentReference: { kind: 'user_provided', userDeclaredIntention: other.intention },
    });
    expect(meaning.threads[0]).toMatchObject({ contextBindings: [], domain: null });
    // The user's own words may mention the cup; only that structural key is exempt.
    expect(() => assertCoffeeV3MeaningOnly(meaning)).not.toThrow();
    expect(() => assertCoffeeV3MeaningOnly({ note: other.intention })).toThrow();
    expect(() => assertCoffeeV3MeaningOnly({ userDeclaredIntention: { band: 'rim_upper' } })).toThrow();
  });

  it('Q: a canonical choice carries no redundant raw text', () => {
    const { meaning } = run(M1_QA_CUPS.money_fish_tree.spec, 'money_finance');
    expect(meaning.intentReference).toEqual({ kind: 'canonical_choice' });
    expect(JSON.stringify(meaning)).not.toMatch(/Maddi durumum/);
  });

  it('R/S: every M1.2 output keeps the common forbidden specifics and passes the privacy assertion', () => {
    for (const cup of Object.values(M12_RELEVANCE_CUPS)) {
      const { meaning } = interpretCoffeeV3MarkMap(m1Map(cup.spec), ctx(cup.intention));
      expect(() => assertCoffeeV3MeaningOnly(meaning)).not.toThrow();
      for (const t of meaning.threads) {
        expect(t.forbiddenSpecifics).toEqual(
          expect.arrayContaining([
            'exact_person', 'employer_or_company', 'monetary_amount', 'salary_or_debt', 'payment_event', 'exact_event',
            'relationship_history', 'other_person_feelings', 'other_person_intent', 'other_person_action',
            'guaranteed_outcome', 'date', 'chronology', 'unsupported_causation',
          ]),
        );
        expect(t.conjecture.join(' ')).not.toMatch(forbiddenOverreach);
      }
    }
  });

  it('declared facts come only from the classifier: a canonical choice declares nothing extra', () => {
    expect(run({ marks: [{ id: 'M1', label: 'a ring' }] }, 'love_relationships').meaning.declaredContext).toEqual([]);
    expect(run({ marks: [{ id: 'M1', label: 'a bird' }] }, 'person_of_interest').meaning.declaredContext).toEqual(['person_in_mind']);
  });

  it('"İş değiştirmeli miyim?" is classified career_work (no decision word), so no decision binding is invented', () => {
    const job = ctx('İş değiştirmeli miyim?');
    expect(job).toMatchObject({ subjectKind: 'career_work', declaredFacts: [] });
    const t = only(M1_QA_CUPS.career_key_path.spec, job);
    expect(t).toMatchObject({ domain: 'career', contextBindings: [] });
  });

  it('T: no live source imports M1 (M1.2 included)', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    // Only the equally dark M2 engine may build on M1.
    expect(
      walk(src)
        .filter((path) => /coffee-m1-interpretation/.test(readFileSync(path, 'utf8')))
        .map((path) => path.slice(src.length + 1).replace(/\\/g, '/')),
    ).toEqual(['ai/reading/coffee-m2-semantic-engine.ts']);
  });
});

describe('M1.3 trusted authorizedSections domain', () => {
  const ctx = (text: string) => {
    const c = classifyCoffeeIntention(text);
    if (!c) throw new Error('no context');
    return c;
  };
  const keyPath = M1_QA_CUPS.career_key_path.spec;

  it('A: a custom decision that names work keeps the decision AND the career domain', () => {
    const decision = ctx('İşim hakkında bir karar vermem gerekiyor.');
    expect(decision).toMatchObject({ subjectKind: 'custom_decision', declaredFacts: ['decision_exists'], authorizedSections: ['career'] });
    const t = only(keyPath, decision);
    expect(t).toMatchObject({ contextBindings: ['user_decision'], domain: 'career', combination: 'access_through_direction' });
    expect(t.conjecture).toEqual(expect.arrayContaining(['decision_clarity', 'decision_direction', 'career_opening', 'career_direction']));
  });

  it('A: "İşimle ilgili…" gets NO career section from the classifier, so M1 invents none', () => {
    const decision = ctx('İşimle ilgili bir karar vermem gerekiyor.');
    expect(decision).toMatchObject({ subjectKind: 'custom_decision', authorizedSections: [] });
    const t = only(keyPath, decision);
    expect(t).toMatchObject({ contextBindings: ['user_decision'], domain: null });
    expect(t.conjecture.join(' ')).not.toMatch(/career_/);
  });

  it('B: the same decision intention + a bird forces neither decision nor domain', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, ctx('İşim hakkında bir karar vermem gerekiyor.'));
    expect(t).toMatchObject({ developments: ['contact'], contextBindings: [], domain: null });
    expect(t.conjecture).toEqual(['news', 'communication_movement']);
  });

  it('C: a custom intention with one money section binds a fish to the financial domain', () => {
    const money = ctx('Param hakkında bir karar vermem gerekiyor.');
    expect(money).toMatchObject({ subjectKind: 'custom_decision', authorizedSections: ['money'] });
    const t = only({ marks: [{ id: 'M1', label: 'a fish' }] }, money);
    expect(t).toMatchObject({ domain: 'financial', contextBindings: [] });
    expect(t.conjecture).toContain('financial_opening');
  });

  it('C: custom_other with one money section (typed context; unreachable via the classifier) binds the same way', () => {
    const typed = { ...ctx('Bir yerden dönüş bekliyorum.'), authorizedSections: ['money' as const] };
    expect(only({ marks: [{ id: 'M1', label: 'a fish' }] }, typed)).toMatchObject({ subject: 'custom_other', domain: 'financial' });
  });

  it('D: a custom intention with no authorized section gets no domain', () => {
    const t = only({ marks: [{ id: 'M1', label: 'a fish' }] }, ctx('Bir yerden dönüş bekliyorum.'));
    expect(t.domain).toBeNull();
    expect(t.conjecture.join(' ')).not.toMatch(/financial_|career_|love_/);
  });

  it('E: several authorized sections never invent a single domain where more than one fits', () => {
    const multi = ctx('İşim ve param hakkında merak ediyorum.');
    expect(multi).toMatchObject({ subjectKind: 'custom_other', authorizedSections: ['career', 'money'] });
    // An opportunity fits both money and career → unbound.
    expect(only({ marks: [{ id: 'M1', label: 'a fish' }] }, multi).domain).toBeNull();
    expect(only(M1_QA_CUPS.money_fish_tree.spec, multi).domain).toBeNull();
    // A direction fits only career among the authorized sections → career, no priority invented.
    expect(only({ marks: [{ id: 'M1', label: 'a road' }] }, multi)).toMatchObject({ domain: 'career' });
    // A heart fits neither → no domain.
    expect(only({ marks: [{ id: 'M1', label: 'a heart' }] }, multi).domain).toBeNull();
  });

  it('incompatible signs stay ordinary: career + bird, money + heart', () => {
    expect(only({ marks: [{ id: 'M1', label: 'a bird' }] }, 'career_work').domain).toBeNull();
    expect(only({ marks: [{ id: 'M1', label: 'a heart' }] }, 'money_finance').domain).toBeNull();
  });

  it('F: canonical money / career / love behaviour is unchanged', () => {
    expect(only(M1_QA_CUPS.money_fish_tree.spec, 'money_finance')).toMatchObject({ domain: 'financial' });
    expect(only(keyPath, 'career_work')).toMatchObject({ domain: 'career' });
    expect(only(M1_QA_CUPS.love_ring_heart.spec, 'love_relationships')).toMatchObject({ domain: 'love' });
    expect(only({ marks: [{ id: 'M1', label: 'a bird' }] }, 'general').domain).toBeNull();
  });

  it('G: person_of_interest stays domain-free under Contract B even though its section is love', () => {
    const person = canonicalIntention('person_of_interest');
    expect(person?.authorizedSections).toEqual(['love']);
    const t = only({ marks: [{ id: 'M1', label: 'a bird' }] }, 'person_of_interest');
    expect(t).toMatchObject({ domain: null, contextBindings: ['chosen_person'], subjectBinding: 'person_of_interest' });
    expect(t.conjecture).not.toContain('love_development');
  });
});

describe('M1.3 inflection-safe privacy', () => {
  it.each([
    'Fincanımda güzel bir kısmet var.',
    'Fincanın dibinde bir haber görünüyor.',
    'Fincana yakın bir yerde kısmet var.',
    'Fincandan bir haber çıkıyor.',
    'Kulpa yakın bir kısmet var.',
    'Kulpunda bir hareket var.',
    'Kulbunda bir hareket var.',
    'Tabakta bereket görünüyor.',
    'Tabağında bereket görünüyor.',
    'Telveye bakınca yeni bir başlangıç var.',
    'Telvenin içinde bir haber var.',
    'Fincanındaki iz yeni bir yön gösteriyor.',
    'FİNCANIMDA KISMET VAR.',
    'The cups show news.',
    'Near the handles there is news.',
    'Strokes on the rim.',
    'It sits at rim_upper near cup_turn_a.',
  ])('rejects visual language outside userDeclaredIntention: %s', (text) => {
    expect(coffeeV3PrivacyViolations({ line: text }).length).toBeGreaterThan(0);
    expect(() => assertCoffeeV3MeaningOnly({ threads: [{ note: text }] })).toThrow(/coffee_v3_private_field_leak/);
  });

  it.each([
    'Duyguların derin bir tabakası var.',
    'Her tabakada ayrı bir kısmet var.',
    'Kısmet, haber, iletişim, aşk, kariyer, para, yeni başlangıç, yakın dönem, gönül.',
    'Telefonla gelen bir haber, televizyonda değil, kulağına gelir.',
    'Kulübe dönüş, kullanılmış bir kapı değil; yepyeni bir kısmet.',
    'Fincancı gibi değil, kendi yolunda bir kısmet.',
    'Primed and trimmed, the opportunity cupboard is open.',
  ])('keeps ordinary meaning prose clean: %s', (text) => {
    expect(coffeeV3PrivacyViolations({ line: text })).toEqual([]);
  });

  it('userDeclaredIntention may carry the user\'s own visual words; anywhere else they fail', () => {
    const own = 'Fincanım hakkında merak ettiğim şey kulpunda bir şey var mı?';
    expect(() => assertCoffeeV3MeaningOnly({ intentReference: { kind: 'user_provided', userDeclaredIntention: own } })).not.toThrow();
    expect(() => assertCoffeeV3MeaningOnly({ intentReference: { kind: 'user_provided', note: own } })).toThrow();
    expect(() => assertCoffeeV3MeaningOnly({ threads: [{ text: own }] })).toThrow();
  });

  it('every M1 / M1.2 / M1.3 meaning output still passes', () => {
    for (const cup of Object.values(M1_QA_CUPS)) {
      expect(() => assertCoffeeV3MeaningOnly(run(cup.spec, cup.subject).meaning)).not.toThrow();
    }
    for (const cup of Object.values(M12_RELEVANCE_CUPS)) {
      const c = classifyCoffeeIntention(cup.intention);
      expect(() => assertCoffeeV3MeaningOnly(interpretCoffeeV3MarkMap(m1Map(cup.spec), c).meaning)).not.toThrow();
    }
  });
});
