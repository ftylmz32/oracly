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
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import { M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

const run = (spec: M1FixtureSpec, subject: Parameters<typeof interpretCoffeeV3MarkMap>[1] = null) =>
  interpretCoffeeV3MarkMap(m1Map(spec), subject);
const only = (spec: M1FixtureSpec, subject: Parameters<typeof interpretCoffeeV3MarkMap>[1] = null): CoffeeFortuneThread => {
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
      valence: 'neutral',
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
      const result = interpretCoffeeV3MarkMap(m1Map(cup.spec), cup.subject);
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
    const importers = walk(src).filter((path) => /coffee-m1-interpretation/.test(readFileSync(path, 'utf8')));
    expect(importers).toEqual([]);
    const engine = readFileSync(join(src, 'ai/reading/coffee-m1-interpretation.ts'), 'utf8');
    expect(engine).not.toMatch(/CoffeeMultiViewObservationV3|\.description|\.confidence|\.visibility|rimClock|handleClock/);
  });
});
