import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeV3MarkMap } from '../src/ai/reading/coffee-m1-interpretation.js';
import {
  COFFEE_M2_CONTRACT_GAPS,
  COFFEE_M2_MODIFIER_FACET,
  coffeeM2StructureMeaning,
  interpretCoffeeM2,
} from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import {
  COFFEE_TURKISH_CLASS_WORDING,
  COFFEE_TURKISH_RELATION_WORDING,
  COFFEE_TURKISH_SCENARIO_WORDING,
} from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
import { prepareCoffeeM2TurkishRealization } from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { assertCoffeeV3MeaningOnly, buildCoffeeV3MarkMap } from '../src/ai/reading/coffee-v3-mark-map.js';
import { COFFEE_V2_OBSERVER_SCHEMA, COFFEE_V3_OBSERVER_SCHEMA } from '../src/ai/reading/schemas.js';
import type { CoffeeV3Form } from '../src/ai/reading/types.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { M1_QA_CUPS, m1Map, m1Observation, type M1FixtureSpec, type M1MarkSpec } from './fixtures/coffee-m1-fixtures.js';

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const m2 = (spec: M1FixtureSpec, intention: string | null = null) =>
  interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null);
const threadsOf = (spec: M1FixtureSpec) => m2(spec).meaning.threads;
const residue = (id: string, form: Partial<CoffeeV3Form>, extra: Partial<M1MarkSpec> = {}): M1MarkSpec => ({ id, label: null, band: 'middle', form, ...extra });
const clear = (id: string, extra: Partial<M1MarkSpec> = {}): M1MarkSpec => ({ id, label: null, kind: 'clear_area', band: 'middle', ...extra });
const invalid = (spec: M1FixtureSpec) => {
  const r = buildCoffeeV3MarkMap(m1Observation(spec));
  return r.status === 'invalid' ? r.failure : r.status;
};
const SPAN3 = ['rim_upper', 'middle', 'lower_base'] as Array<'rim_upper' | 'middle' | 'lower_base'>;

describe('V3G1 clear areas (A–F)', () => {
  it('A: a clear area is accepted as a first-class physical feature with no candidate', () => {
    const map = m1Map({ marks: [clear('C1', { slots: ['cup_handle_far', 'cup_turn_a'] })] });
    expect(map.cupMarks).toHaveLength(1);
    expect(map.cupMarks[0]).toMatchObject({ kind: 'clear_area', topology: 'unknown', candidates: [], coverage: { count: 2 } });
  });

  it('B: a clear area can never carry a resemblance, a topology, or a possible-same link to residue', () => {
    expect(invalid({ marks: [clear('C1', { label: 'a bird' })] })).toBe('clear_area_resemblance');
    expect(invalid({ marks: [clear('C1', { topology: 'pool' })] })).toBe('clear_area_topology');
    expect(invalid({ marks: [clear('C1'), residue('R1', {})], ambiguities: [['C1', 'R1']] })).toBe('cross_kind_ambiguity');
  });

  it('C: a clear area never enters the M1 object lane (nor do relations touching it)', () => {
    const spec: M1FixtureSpec = { marks: [{ id: 'B1', label: 'a bird' }, clear('C1')], relations: [{ a: 'C1', b: 'B1', kind: 'contained_by' }] };
    const m1 = interpretCoffeeV3MarkMap(m1Map(spec), null);
    const without = interpretCoffeeV3MarkMap(m1Map({ marks: [{ id: 'B1', label: 'a bird' }] }), null);
    expect(m1.meaning).toEqual(without.meaning);
    expect(m1.audit.unmappedGroups).toBe(0);
    expect(m1.audit.ignoredRelationKinds).toEqual([]);
  });

  it('D: a cup clear area grounds opening_clarity', () => {
    expect(threadsOf({ marks: [clear('C1')] })).toMatchObject([{ lane: 'structure', developments: ['opening_clarity'], modifiers: [] }]);
  });

  it('E: an explicitly contained clear area adds room_within; a merely near one, or the reverse containment, does not', () => {
    const pool = residue('P1', { openness: 'closed' }, { band: 'lower_base', topology: 'pool' });
    const inside = threadsOf({ marks: [pool, clear('C1', { band: 'lower_base' })], relations: [{ a: 'C1', b: 'P1', kind: 'contained_by' }] });
    expect(inside).toMatchObject([{ developments: ['opening_clarity'], modifiers: ['room_within'] }]);
    const near = threadsOf({ marks: [pool, clear('C1', { band: 'lower_base' })], relations: [{ a: 'C1', b: 'P1', kind: 'near' }] });
    expect(near[0].modifiers).toEqual([]);
    const reverse = threadsOf({ marks: [pool, clear('C1', { band: 'lower_base' })], relations: [{ a: 'P1', b: 'C1', kind: 'contained_by' }] });
    expect(reverse[0].modifiers).toEqual([]);
  });

  it('F: no opening from missing data, an open residue mark, a pool, or the saucer', () => {
    expect(threadsOf({ marks: [residue('R1', { openness: 'open' }, { band: 'lower_base' })] })).toEqual([]);
    expect(threadsOf({ marks: [residue('R1', { openness: 'open' }, { topology: 'pool' })] })).toEqual([]);
    expect(threadsOf({ marks: [{ id: 'S1', label: null, saucer: true, kind: 'clear_area' }] })).toEqual([]);
    expect(m2({ marks: [] }).meaning.diagnostics.capacity).toBe('insufficient');
  });
});

describe('V3G1 wall loop topology (G–L)', () => {
  const loopForm: Partial<CoffeeV3Form> = { continuity: 'continuous', course: 'bending', openness: 'closed' };

  it('G: openness=closed alone, or a pool, is NOT a wall loop', () => {
    expect(threadsOf({ marks: [residue('R1', { openness: 'closed', continuity: 'continuous', course: 'bending' })] })[0].modifiers).not.toContain('within_one_phase');
    expect(threadsOf({ marks: [residue('R1', loopForm, { topology: 'pool' })] })).toEqual([]);
  });

  it('H: a blob / patch is NOT a wall loop and makes no thread', () => {
    expect(threadsOf({ marks: [residue('R1', loopForm, { topology: 'patch' })] })).toEqual([]);
  });

  it('I: an explicit cup-wall closed loop adds within_one_phase to a structure that already qualifies', () => {
    const t = threadsOf({ marks: [residue('L1', loopForm, { topology: 'closed_loop' })] });
    expect(t).toMatchObject([{ developments: ['course_turn'], modifiers: ['within_one_phase'] }]);
    expect(t[0].facets.map((f) => f.cls)).toContain('PHASE');
    // A closed loop on the cup BASE surface is not a wall loop.
    const base = threadsOf({ marks: [residue('L1', loopForm, { topology: 'closed_loop', surface: 'cup_base', band: 'lower_base' })] });
    expect(base[0].modifiers).not.toContain('within_one_phase');
  });

  it('J: a closed loop with no grounded core development makes no standalone thread', () => {
    expect(threadsOf({ marks: [residue('L1', { openness: 'closed' }, { topology: 'closed_loop' })] })).toEqual([]);
  });

  it('K: a saucer loop is ignored', () => {
    expect(threadsOf({ marks: [{ id: 'S1', label: null, saucer: true, topology: 'closed_loop', form: loopForm }] })).toEqual([]);
    const unal = m2(c31Spec('C3F-UNAL', { clearAreas: true }));
    expect(unal.meaning.threads).toEqual([]);
  });

  it('L: a strong object-owned closed loop is never double-counted by the structure lane', () => {
    const { meaning, audit } = m2({ marks: [{ id: 'R1', label: 'a ring', topology: 'closed_loop', form: loopForm }] });
    expect(audit.objectOwnedGroups).toEqual(['R1']);
    expect(audit.structureOwnedGroups).toEqual([]);
    expect(meaning.threads.map((t) => t.lane)).toEqual(['object']);
    expect(meaning.threads[0].modifiers).not.toContain('within_one_phase');
  });
});

describe('V3G1 explicit line span (M–U)', () => {
  it('M: an explicit cross-band span qualifies a line as a course', () => {
    expect(threadsOf({ marks: [residue('T1', { continuity: 'continuous' }, { bandCoverage: ['middle', 'lower_base'] })] })[0].developments).toEqual(['steady_course']);
  });

  it('N: the same line without explicit span does NOT qualify from verticalDirection', () => {
    for (const verticalDirection of ['rising', 'descending'] as const) {
      expect(threadsOf({ marks: [residue('T1', { continuity: 'continuous', verticalDirection })] })).toEqual([]);
    }
  });

  it('O: rising and descending give the identical result', () => {
    const r = threadsOf({ marks: [residue('T1', { continuity: 'continuous', verticalDirection: 'rising' }, { bandCoverage: SPAN3 })] });
    const d = threadsOf({ marks: [residue('T1', { continuity: 'continuous', verticalDirection: 'descending' }, { bandCoverage: SPAN3 })] });
    expect(r).toEqual(d);
  });

  it('P: a rim-only continuous / bending feature stays context, whether span is stated or not', () => {
    expect(threadsOf({ marks: [residue('T1', { continuity: 'continuous', course: 'bending' }, { band: 'rim_upper' })] })).toEqual([]);
    expect(threadsOf({ marks: [residue('T1', { continuity: 'continuous', course: 'bending' }, { band: 'rim_upper', bandCoverage: ['rim_upper'] })] })).toEqual([]);
  });

  it('Q: rim-to-middle / rim-to-base explicit spans qualify', () => {
    for (const span of [['rim_upper', 'middle'], ['rim_upper', 'lower_base'], SPAN3] as Array<Array<'rim_upper' | 'middle' | 'lower_base'>>) {
      expect(threadsOf({ marks: [residue('T1', { continuity: 'continuous' }, { band: 'rim_upper', bandCoverage: span })] })[0].developments, span.join('+')).toEqual(['steady_course']);
    }
  });

  it('R: the normalized span is the deduped union of explicit sighting coverage, rim → base; never invented', () => {
    const obs = m1Observation({ marks: [residue('T1', { continuity: 'continuous' }, { slots: ['cup_handle_far', 'cup_turn_a'] })] });
    obs.sightings[0].bandCoverage = ['lower_base', 'middle'];
    obs.sightings[1].bandCoverage = ['rim_upper', 'middle'];
    const r = buildCoffeeV3MarkMap(obs);
    expect(r.status).toBe('ok');
    if (r.status === 'ok') expect(r.map.cupMarks[0].bandSpan).toEqual(['rim_upper', 'middle', 'lower_base']);
    // No stated coverage → null (a merge of adjacent bands never becomes a span).
    const plain = m1Map({ marks: [residue('T1', {}, { slots: ['cup_handle_far', 'cup_turn_a'] })] });
    expect(plain.cupMarks[0].bandSpan).toBeNull();
  });

  it('S: invalid span is rejected (duplicate, unknown, missing the primary band)', () => {
    expect(invalid({ marks: [residue('T1', {}, { bandCoverage: ['middle', 'middle'] })] })).toBe('invalid_band_coverage');
    expect(invalid({ marks: [residue('T1', {}, { bandCoverage: ['unknown' as never, 'middle'] })] })).toBe('invalid_band_coverage');
    expect(invalid({ marks: [residue('T1', {}, { band: 'middle', bandCoverage: ['rim_upper', 'lower_base'] })] })).toBe('invalid_band_coverage');
  });

  it('T: a saucer sighting cannot carry cup band coverage', () => {
    const obs = m1Observation({ marks: [{ id: 'S1', label: null, saucer: true }] });
    obs.sightings[0].bandCoverage = ['middle'];
    expect(buildCoffeeV3MarkMap(obs)).toEqual({ status: 'invalid', failure: 'saucer_band_coverage' });
  });

  it('U: explicit pool / patch topology blocks an accidental course or web classification', () => {
    for (const topology of ['pool', 'patch'] as const) {
      expect(coffeeM2StructureMeaning({ band: 'middle', form: { ...m1Map({ marks: [residue('X', {})] }).cupMarks[0].form, continuity: 'continuous', course: 'bending' }, topology })).toBeNull();
      expect(threadsOf({ marks: [residue('W1', { course: 'branching' }, { topology })] })).toEqual([]);
    }
    expect(threadsOf({ marks: [residue('W1', { course: 'branching' }, { topology: 'line' })] })[0].developments).toEqual(['possibilities_branch']);
  });
});

describe('V3G1 compatibility, privacy, determinism (V–Y)', () => {
  it('V: M1 meanings of the object-sign QA cups are unchanged by V3G1 fields', () => {
    for (const [name, cup] of Object.entries(M1_QA_CUPS)) {
      const plain = interpretCoffeeV3MarkMap(m1Map(cup.spec), null).meaning;
      const annotated = interpretCoffeeV3MarkMap(
        m1Map({ ...cup.spec, marks: cup.spec.marks.map((m: M1MarkSpec) => (m.saucer ? m : { ...m, kind: 'residue' as const, topology: 'line' as const })) }),
        null,
      ).meaning;
      expect(annotated, name).toEqual(plain);
    }
  });

  it('W: no private field crosses the meaning boundary; the contract gaps are closed', () => {
    for (const spec of [c31Spec('C3F-RITAG', { clearAreas: true }), c31Spec('C3F-GAZETA', { clearAreas: true }), { marks: [residue('L1', { continuity: 'continuous', course: 'bending' }, { topology: 'closed_loop' as const })] }]) {
      const { meaning } = m2(spec, DECISION);
      expect(() => assertCoffeeV3MeaningOnly(meaning)).not.toThrow();
      expect(JSON.stringify(meaning)).not.toMatch(/"(bandSpan|bandCoverage|topology|band|form|candidates|identityGroup)"/);
    }
    expect(COFFEE_M2_CONTRACT_GAPS).toEqual([]);
  });

  it('X: the same observation gives a byte-identical map and M2 result', () => {
    for (const spec of [c31Spec('C3F-RITAG', { clearAreas: true }), c31Spec('C3F-GAZETA', { clearAreas: true }), c31Spec('C3F-HALIL')]) {
      expect(JSON.stringify(m1Map(spec))).toBe(JSON.stringify(m1Map(JSON.parse(JSON.stringify(spec)))));
      expect(JSON.stringify(m2(spec, DECISION))).toBe(JSON.stringify(m2(JSON.parse(JSON.stringify(spec)), DECISION)));
    }
  });

  it('Y: the V3 observer schema carries the new physical fields strictly; the V2 contract is untouched', () => {
    const p = COFFEE_V3_OBSERVER_SCHEMA.properties;
    expect(p.marks.items.properties.kind.enum).toEqual(['residue', 'clear_area']);
    expect(p.marks.items.properties.topology.enum).toEqual(['line', 'closed_loop', 'pool', 'patch', 'unknown']);
    expect(p.sightings.items.properties.bandCoverage.items.enum).toEqual(['rim_upper', 'middle', 'lower_base']);
    expect(JSON.stringify(COFFEE_V2_OBSERVER_SCHEMA)).not.toMatch(/bandCoverage|topology|clear_area/);
  });
});

describe('V3G1 C3.1 replay + opening combinations + frozen writer coverage (Z)', () => {
  it('RITAG: explicit clear crescent (contained) + explicit climbing span → opening_moves_forward + room_within; possibilities stay separate', () => {
    const { meaning } = m2(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION);
    expect(meaning.threads.map((t) => [t.developments, t.combination, t.modifiers])).toEqual([
      [['opening_clarity', 'steady_course'], 'opening_moves_forward', ['room_within']],
      [['possibilities_branch'], null, []],
    ]);
    expect(meaning.diagnostics).toMatchObject({ capacity: 'rich', groundedDevelopmentCount: 3 });
  });

  it('HALIL: the rim-to-base trail is a course from explicit span (same meaning as before, no vertical surrogate)', () => {
    const t = m2(c31Spec('C3F-HALIL', { clearAreas: true }), 'İşim ve kariyerim hakkında').meaning.threads;
    expect(t).toMatchObject([{ developments: ['steady_course'], domain: 'career', depth: 'thin' }]);
  });

  it('GAZETA: the grouped enclosed clear area grounds opening_clarity ONCE; thin → deep, single → multi', () => {
    const before = m2(c31Spec('C3F-GAZETA'), DECISION).meaning;
    const after = m2(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION);
    expect(before.diagnostics).toMatchObject({ capacity: 'single_thread', maxDepth: 'thin' });
    expect(after.meaning.diagnostics).toMatchObject({ capacity: 'multi_thread', groundedDevelopmentCount: 2, maxDepth: 'deep' });
    expect(after.audit.threadEvidence.T1).toEqual(['P1', 'P1C']);
    expect(after.meaning.threads[0].combination).toBe('possibilities_become_visible');
  });

  it('BASAK / UNAL: no false course from the rim web or the rim stain; pools, blobs and the saucer loop stay context', () => {
    const basak = m2(c31Spec('C3F-BASAK', { clearAreas: true }), 'Maddi durumum hakkında');
    expect(basak.meaning.threads.map((t) => t.developments)).toEqual([['possibilities_branch']]);
    expect(basak.audit.contextGroups).toEqual(['P2', 'P3']);
    expect(m2(c31Spec('C3F-UNAL', { clearAreas: true })).meaning.diagnostics.capacity).toBe('insufficient');
  });

  it('evidence inflation: one clear area in several views, or several clear areas, is ONE opening family', () => {
    const many = m2({ marks: [clear('C1', { slots: ['cup_handle_far', 'cup_turn_a', 'cup_turn_b'] }), clear('C2', { hours: 9 })] });
    expect(many.meaning.threads).toHaveLength(1);
    expect(many.meaning.diagnostics).toMatchObject({ capacity: 'single_thread', groundedDevelopmentCount: 1 });
  });

  it('opening combinations fire only from explicit grounded sources; separated families stay separate', () => {
    const course = residue('T1', { continuity: 'broken' }, { bandCoverage: ['middle', 'lower_base'] });
    expect(threadsOf({ marks: [course, clear('C1')] })[0].combination).toBe('stalled_course_finds_room');
    const steady = residue('T1', { continuity: 'continuous', course: 'straight' });
    expect(threadsOf({ marks: [steady, clear('C1')] })[0].combination).toBe('opening_moves_forward');
    expect(threadsOf({ marks: [steady, clear('C1')], relations: [{ a: 'C1', b: 'T1', kind: 'separated' }] }).map((t) => t.combination)).toEqual([null, null]);
    expect(threadsOf({ marks: [residue('W1', { course: 'branching' }), clear('C1')] })[0].combination).toBe('possibilities_become_visible');
    // Without an explicit clear area the same cups have no opening at all.
    expect(threadsOf({ marks: [steady] })[0].combination).toBeNull();
  });

  it('Z: every newly reachable meaning is covered by the FROZEN writer stack (W2 → W4A → W4C.1), no edits', () => {
    const shapes: M1FixtureSpec[] = [
      c31Spec('C3F-RITAG', { clearAreas: true }),
      c31Spec('C3F-GAZETA', { clearAreas: true }),
      { marks: [residue('T1', { continuity: 'broken' }, { bandCoverage: ['middle', 'lower_base'] }), clear('C1')] },
      { marks: [residue('T1', { continuity: 'continuous', course: 'straight' }), clear('C1')] },
      { marks: [residue('L1', { continuity: 'continuous', course: 'bending', openness: 'closed' }, { topology: 'closed_loop' })] },
      { marks: [clear('C1'), residue('P1', {}, { topology: 'pool' })], relations: [{ a: 'C1', b: 'P1', kind: 'contained_by' }] },
    ];
    for (const intention of [null, DECISION, 'Maddi durumum hakkında', 'Aşk ve ilişkilerim hakkında', 'İşim ve kariyerim hakkında']) {
      for (const spec of shapes) {
        const { meaning } = m2(spec, intention);
        for (const t of meaning.threads) {
          for (const m of t.modifiers) if (COFFEE_M2_MODIFIER_FACET[m]) expect(COFFEE_TURKISH_CLASS_WORDING[COFFEE_M2_MODIFIER_FACET[m].cls], m).toBeDefined();
        }
        const plan = planCoffeeM2Writer(meaning).plan;
        expect(plan.status).toBe('planned');
        for (const b of plan.beats) {
          for (const g of b.groups) if (g.kind !== 'scenario') expect(COFFEE_TURKISH_CLASS_WORDING[g.cls], g.cls).toBeDefined();
          if (b.relation) expect(COFFEE_TURKISH_RELATION_WORDING[b.relation.combination], b.relation.combination).toBeDefined();
          for (const m of b.scenario?.manifestations ?? []) expect(COFFEE_TURKISH_SCENARIO_WORDING[m], m).toBeDefined();
        }
        const r = prepareCoffeeM2TurkishRealization(plan);
        expect(() => assertCoffeeV3MeaningOnly(r)).not.toThrow();
      }
    }
  });
});
