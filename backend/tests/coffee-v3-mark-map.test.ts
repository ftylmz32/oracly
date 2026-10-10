import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  COFFEE_V3_MERGE_ANGLE_TOLERANCE,
  assertCoffeeV3MeaningOnly,
  buildCoffeeV3MarkMap,
  coffeeV3AngleDistance,
  coffeeV3HandleRelation,
  coffeeV3HandleRelativeAngle,
  coffeeV3PrivacyViolations,
  type CoffeeV3MarkMap,
} from '../src/ai/reading/coffee-v3-mark-map.js';
import {
  coffeeV2ObserverSystem,
  coffeeV3ObserverSystem,
  coffeeV3ObserverUser,
  coffeeV3SlotLabel,
} from '../src/ai/reading/observer-prompts.js';
import { COFFEE_V2_OBSERVER_SCHEMA, COFFEE_V3_OBSERVER_SCHEMA } from '../src/ai/reading/schemas.js';
import {
  COFFEE_V3_SLOTS,
  type CoffeeMultiViewObservationV3,
  type CoffeeV3Form,
  type CoffeeV3Mark,
  type CoffeeV3Sighting,
  type CoffeeV3Slot,
  type CoffeeV3View,
} from '../src/ai/reading/types.js';
import { COFFEE_V2_SLOTS, isCoffeeV2Slot } from '../src/reading/operation-staged-image-model.js';

// ---------------------------------------------------------------------------
// Fixture builders. The handle sits at 12 / 4 / 8 o'clock in the three cup
// frames, so one physical mark at cup angle θ appears at rimClock
// handleClock + θ/30 in each frame.
// ---------------------------------------------------------------------------

const view = (slot: CoffeeV3Slot, handleClock: number | null, extra: Partial<CoffeeV3View> = {}): CoffeeV3View => ({
  slot,
  surfaceVisible: true,
  focusLightAdequate: true,
  residueVisible: true,
  handleVisible: slot === 'saucer' ? null : handleClock !== null,
  handleClock: slot === 'saucer' ? null : handleClock,
  ...extra,
});
const VIEWS: CoffeeV3View[] = [
  view('cup_handle_far', 12),
  view('cup_turn_a', 4),
  view('cup_turn_b', 8),
  view('saucer', null),
];
const HANDLE_CLOCK: Record<Exclude<CoffeeV3Slot, 'saucer'>, number> = { cup_handle_far: 12, cup_turn_a: 4, cup_turn_b: 8 };
/** rimClock at which a mark at cup angle `hours` (clock hours from the handle) appears in `slot`. */
const rimAt = (slot: Exclude<CoffeeV3Slot, 'saucer'>, hours: number) => ((HANDLE_CLOCK[slot] + hours - 1) % 12) + 1;

const sighting = (
  id: string,
  slot: CoffeeV3Slot,
  rimClock: number | null,
  extra: Partial<CoffeeV3Sighting> = {},
): CoffeeV3Sighting => ({
  id,
  slot,
  surface: slot === 'saucer' ? 'saucer' : 'cup_wall',
  band: slot === 'saucer' ? 'unknown' : 'middle',
  rimClock,
  saucerZone: slot === 'saucer' ? 'center' : null,
  description: 'A dark compact mark with a soft edge.',
  visibility: 'clear',
  confidence: 'high',
  ...extra,
});
const FORM: CoffeeV3Form = {
  motion: 'unknown',
  verticalDirection: 'unknown',
  openness: 'unknown',
  course: 'unknown',
  posture: 'unknown',
  continuity: 'unknown',
  grouping: 'unknown',
};
const mark = (id: string, sightingIds: string[], extra: Partial<CoffeeV3Mark> = {}): CoffeeV3Mark => ({
  id,
  surface: 'cup_wall',
  sightingIds,
  form: { ...FORM },
  resemblances: [],
  ...extra,
});
const observation = (extra: Partial<CoffeeMultiViewObservationV3>): CoffeeMultiViewObservationV3 => ({
  contract: 'multi_view_marks_v3',
  usable: true,
  reason: null,
  views: VIEWS,
  sightings: [],
  marks: [],
  relations: [],
  ambiguities: [],
  saucer: { surfaceState: 'clean', flow: { present: false, direction: 'none' } },
  ...extra,
});
const okMap = (obs: CoffeeMultiViewObservationV3): CoffeeV3MarkMap => {
  const result = buildCoffeeV3MarkMap(obs);
  if (result.status !== 'ok') throw new Error(`expected ok, got ${JSON.stringify(result)}`);
  return result.map;
};

// ---------------------------------------------------------------------------

describe('V3 handle-relative angle (N, O)', () => {
  it('normalizes clock wraparound: 12 vs 1 and 11 vs 1 are close', () => {
    expect(coffeeV3HandleRelativeAngle(12, 12)).toBe(0);
    expect(coffeeV3HandleRelativeAngle(1, 12)).toBe(30);
    expect(coffeeV3HandleRelativeAngle(11, 12)).toBe(330);
    expect(coffeeV3AngleDistance(coffeeV3HandleRelativeAngle(12, 12), coffeeV3HandleRelativeAngle(1, 12))).toBe(30);
    expect(coffeeV3AngleDistance(coffeeV3HandleRelativeAngle(11, 12), coffeeV3HandleRelativeAngle(1, 12))).toBe(60);
    expect(coffeeV3AngleDistance(330, 30)).toBe(60);
    expect(coffeeV3AngleDistance(0, 359)).toBe(1);
  });

  it('cancels the camera rotation: the same cup angle from three frames agrees', () => {
    const angles = (['cup_handle_far', 'cup_turn_a', 'cup_turn_b'] as const).map((slot) =>
      coffeeV3HandleRelativeAngle(rimAt(slot, 6), HANDLE_CLOCK[slot]),
    );
    expect(angles).toEqual([180, 180, 180]);
  });

  it('derives near / opposite / neutral / unknown', () => {
    expect(coffeeV3HandleRelation(0)).toBe('handle_near');
    expect(coffeeV3HandleRelation(30)).toBe('handle_near');
    expect(coffeeV3HandleRelation(330)).toBe('handle_near');
    expect(coffeeV3HandleRelation(180)).toBe('handle_opposite');
    expect(coffeeV3HandleRelation(150)).toBe('handle_opposite');
    expect(coffeeV3HandleRelation(210)).toBe('handle_opposite');
    expect(coffeeV3HandleRelation(90)).toBe('neutral');
    expect(coffeeV3HandleRelation(270)).toBe('neutral');
    expect(coffeeV3HandleRelation(null)).toBe('unknown');
    // handle at 11, mark at 1 → two hours away → neutral, not near.
    expect(coffeeV3HandleRelation(coffeeV3HandleRelativeAngle(1, 11))).toBe('neutral');
  });

  it('maps marks to the right handle relation through the mark map', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 0)),
          sighting('s2', 'cup_handle_far', rimAt('cup_handle_far', 6)),
          sighting('s3', 'cup_turn_a', rimAt('cup_turn_a', 3)),
          sighting('s4', 'cup_turn_b', null),
        ],
        marks: [mark('M1', ['s1']), mark('M2', ['s2']), mark('M3', ['s3']), mark('M4', ['s4'])],
      }),
    );
    expect(map.cupMarks.map((m) => [m.id, m.handleRelation])).toEqual([
      ['M1', 'handle_near'],
      ['M2', 'handle_opposite'],
      ['M3', 'neutral'],
      ['M4', 'unknown'],
    ]);
  });
});

describe('V3 multi-view deduplication (A–E)', () => {
  it('A: one physical mark across two compatible views → one mark, two sightings, counted once', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 6)),
          sighting('s2', 'cup_turn_a', rimAt('cup_turn_a', 6)),
        ],
        marks: [mark('M1', ['s1', 's2'])],
      }),
    );
    expect(map.cupMarks).toHaveLength(1);
    expect(map.cupMarks[0]).toMatchObject({
      identity: 'certain',
      coverage: { count: 2, slots: ['cup_handle_far', 'cup_turn_a'] },
    });
    expect(map.distinctMarkCount).toBe(1);
    expect(map.audit.untrustedMergeIds).toEqual([]);
  });

  it('B: one physical mark across three compatible views (tolerating one clock hour) → one mark', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 5)),
          sighting('s2', 'cup_turn_a', rimAt('cup_turn_a', 6)),
          sighting('s3', 'cup_turn_b', rimAt('cup_turn_b', 7), { band: 'lower_base' }),
        ],
        marks: [mark('M1', ['s1', 's2', 's3'])],
      }),
    );
    expect(map.cupMarks).toHaveLength(1);
    expect(map.cupMarks[0].coverage.count).toBe(3);
    expect(map.cupMarks[0].handleRelation).toBe('handle_opposite');
    expect(map.distinctMarkCount).toBe(1);
  });

  it('C: two truly separate marks stay separate', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 0)),
          sighting('s2', 'cup_turn_a', rimAt('cup_turn_a', 6)),
        ],
        marks: [mark('M1', ['s1']), mark('M2', ['s2'])],
      }),
    );
    expect(map.cupMarks.map((m) => m.id)).toEqual(['M1', 'M2']);
    expect(map.cupMarks.every((m) => m.identity === 'certain')).toBe(true);
    expect(map.distinctMarkCount).toBe(2);
  });

  it('D: a claimed merge across incompatible angles is not trusted → split, kept, linked as possible_same_mark', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 0)),
          sighting('s2', 'cup_turn_a', rimAt('cup_turn_a', 6)),
        ],
        marks: [mark('M1', ['s1', 's2'], { resemblances: [{ label: 'a small arch', strength: 'strong' }] })],
      }),
    );
    expect(map.audit.untrustedMergeIds).toEqual(['M1']);
    expect(map.cupMarks.map((m) => [m.id, m.identity, m.coverage.count])).toEqual([
      ['M1#1', 'possible_same_mark', 1],
      ['M1#2', 'possible_same_mark', 1],
    ]);
    expect(new Set(map.cupMarks.map((m) => m.identityGroup)).size).toBe(1);
    // A possible-same pair counts once: no repeat / plural credit.
    expect(map.distinctMarkCount).toBe(1);
  });

  it.each([
    ['bands two steps apart', { s2: { band: 'lower_base' as const }, s1: { band: 'rim_upper' as const } }],
    ['an unknown band', { s2: { band: 'unknown' as const } }],
    ['no rim position', { s2: { rimClock: null } }],
  ])('D: a merge with %s is not trusted', (_name, patch) => {
    const result = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 6), patch.s1 ?? {}),
          sighting('s2', 'cup_turn_a', rimAt('cup_turn_a', 6), patch.s2 ?? {}),
        ],
        marks: [mark('M1', ['s1', 's2'])],
      }),
    );
    expect(result.audit.untrustedMergeIds).toEqual(['M1']);
    expect(result.distinctMarkCount).toBe(1);
  });

  it('D: a merge through a view without a visible handle is not trusted', () => {
    const map = okMap(
      observation({
        views: [view('cup_handle_far', 12), view('cup_turn_a', null), view('cup_turn_b', 8), view('saucer', null)],
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 6)),
          sighting('s2', 'cup_turn_a', 10),
        ],
        marks: [mark('M1', ['s1', 's2'])],
      }),
    );
    expect(map.audit.untrustedMergeIds).toEqual(['M1']);
  });

  it('D: an observer-declared ambiguity is preserved and counted once', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 6)),
          sighting('s2', 'cup_turn_a', rimAt('cup_turn_a', 6)),
        ],
        marks: [mark('M1', ['s1']), mark('M2', ['s2'])],
        ambiguities: [{ marks: ['M1', 'M2'], reason: 'possible_same_mark' }],
      }),
    );
    expect(map.cupMarks.map((m) => m.identity)).toEqual(['possible_same_mark', 'possible_same_mark']);
    expect(map.distinctMarkCount).toBe(1);
  });

  it('E: a claimed cup + saucer merge is a structural rejection', () => {
    const result = buildCoffeeV3MarkMap(
      observation({
        sightings: [sighting('s1', 'cup_handle_far', 6), sighting('s2', 'saucer', null)],
        marks: [mark('M1', ['s1', 's2'])],
      }),
    );
    expect(result).toEqual({ status: 'invalid', failure: 'cup_saucer_merge' });
  });
});

describe('V3 structural validation', () => {
  const base = {
    sightings: [sighting('s1', 'cup_handle_far', 6), sighting('s2', 'cup_turn_a', 2)],
    marks: [mark('M1', ['s1']), mark('M2', ['s2'])],
  };
  it.each([
    ['duplicate sighting id', { sightings: [sighting('s1', 'cup_handle_far', 6), sighting('s1', 'cup_turn_a', 2)], marks: [mark('M1', ['s1'])] }, 'duplicate_sighting_id'],
    ['duplicate mark id', { marks: [mark('M1', ['s1']), mark('M1', ['s2'])] }, 'duplicate_mark_id'],
    ['sighting in two marks', { marks: [mark('M1', ['s1', 's2']), mark('M2', ['s2'])] }, 'sighting_in_multiple_marks'],
    ['empty mark', { marks: [mark('M1', ['s1']), mark('M2', ['s2']), mark('M3', [])] }, 'empty_mark'],
    ['unknown sighting', { marks: [mark('M1', ['s1']), mark('M2', ['s2', 's9'])] }, 'unknown_sighting'],
    ['unassigned sighting', { marks: [mark('M1', ['s1'])] }, 'unassigned_sighting'],
    ['unknown relation mark', { relations: [{ a: 'M1', b: 'M9', kind: 'near' as const, confidence: 'high' as const }] }, 'unknown_relation_mark'],
    ['self relation', { relations: [{ a: 'M1', b: 'M1', kind: 'near' as const, confidence: 'high' as const }] }, 'self_relation'],
    [
      'duplicate unordered relation',
      {
        relations: [
          { a: 'M1', b: 'M2', kind: 'near' as const, confidence: 'high' as const },
          { a: 'M2', b: 'M1', kind: 'touching' as const, confidence: 'high' as const },
        ],
      },
      'duplicate_relation',
    ],
    ['unknown ambiguity mark', { ambiguities: [{ marks: ['M1', 'M9'] as [string, string], reason: 'possible_same_mark' as const }] }, 'unknown_ambiguity_mark'],
    ['self ambiguity', { ambiguities: [{ marks: ['M1', 'M1'] as [string, string], reason: 'possible_same_mark' as const }] }, 'self_ambiguity'],
    [
      'duplicate ambiguity pair',
      {
        ambiguities: [
          { marks: ['M1', 'M2'] as [string, string], reason: 'possible_same_mark' as const },
          { marks: ['M2', 'M1'] as [string, string], reason: 'possible_same_mark' as const },
        ],
      },
      'duplicate_ambiguity',
    ],
    ['saucer slot on cup surface', { sightings: [sighting('s1', 'saucer', null, { surface: 'cup_wall' }), sighting('s2', 'cup_turn_a', 2)] }, 'slot_surface_mismatch'],
    ['wrong contract', { contract: 'coffee_v2' as never }, 'wrong_contract'],
  ])('%s → invalid', (_name, patch, failure) => {
    expect(buildCoffeeV3MarkMap(observation({ ...base, ...patch }))).toEqual({ status: 'invalid', failure });
  });

  it('an unusable observation is reported as unusable, not as a sparse cup', () => {
    expect(buildCoffeeV3MarkMap(observation({ usable: false, reason: 'too dark' }))).toEqual({ status: 'unusable' });
  });
});

describe('V3 resemblance candidates and quality (F–J, T)', () => {
  const one = (resemblances: CoffeeV3Mark['resemblances'], visibility: CoffeeV3Sighting['visibility'] = 'clear') =>
    okMap(
      observation({
        sightings: [sighting('s1', 'cup_handle_far', 6, { visibility })],
        marks: [mark('M1', ['s1'], { resemblances })],
      }),
    ).cupMarks[0];

  it('F: no resemblance candidates is a valid mark', () => {
    expect(one([])).toMatchObject({ id: 'M1', candidates: [] });
  });

  it('G: one weak candidate is stored but not usable', () => {
    expect(one([{ label: 'a loose loop', strength: 'weak' }]).candidates).toEqual([{ label: 'a loose loop', usable: false }]);
  });

  it('H: one strong candidate + a clear sighting is usable, and stays free text (no meaning family)', () => {
    expect(one([{ label: 'a small arch', strength: 'strong' }]).candidates).toEqual([{ label: 'a small arch', usable: true }]);
  });

  it('I: two conflicting strong candidates → no usable sign', () => {
    expect(
      one([
        { label: 'a small arch', strength: 'strong' },
        { label: 'a hook', strength: 'strong' },
      ]).candidates.map((c) => c.usable),
    ).toEqual([false, false]);
  });

  it('J: partial-only sightings may carry form but never a sign', () => {
    const map = okMap(
      observation({
        sightings: [sighting('s1', 'cup_handle_far', 6, { visibility: 'partial' })],
        marks: [
          mark('M1', ['s1'], {
            form: { ...FORM, motion: 'moving', course: 'bending' },
            resemblances: [{ label: 'a small arch', strength: 'strong' }],
          }),
        ],
      }),
    );
    expect(map.cupMarks[0].form).toMatchObject({ motion: 'moving', course: 'bending' });
    expect(map.cupMarks[0].candidates).toEqual([{ label: 'a small arch', usable: false }]);
  });

  it('uncertain-only or all-low-confidence marks are not accepted', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', 6, { visibility: 'uncertain' }),
          sighting('s2', 'cup_turn_a', 2, { confidence: 'low' }),
          sighting('s3', 'cup_turn_b', 3),
        ],
        marks: [mark('M1', ['s1']), mark('M2', ['s2']), mark('M3', ['s3'])],
      }),
    );
    expect(map.cupMarks.map((m) => m.id)).toEqual(['M3']);
    expect(map.audit.rejectedMarkIds).toEqual(['M1', 'M2']);
  });

  it('T: confidence differences change nothing downstream, and no strength-like field exists', () => {
    const build = (confidence: 'high' | 'medium') =>
      okMap(
        observation({
          sightings: [
            sighting('s1', 'cup_handle_far', rimAt('cup_handle_far', 6), { confidence }),
            sighting('s2', 'cup_turn_a', rimAt('cup_turn_a', 6), { confidence }),
          ],
          marks: [mark('M1', ['s1', 's2'], { resemblances: [{ label: 'a small arch', strength: 'strong' }] })],
        }),
      );
    expect(build('high')).toEqual(build('medium'));
    const keys = JSON.stringify(build('high')).match(/"([A-Za-z]+)":/g) ?? [];
    expect(keys.filter((k) => /confidence|visibility|strength|weight|intensity|importance|score/i.test(k))).toEqual([]);
  });
});

describe('V3 placement, relations and saucer (K–S)', () => {
  it('K/L/M: rim_upper, middle and lower_base are retained', () => {
    const map = okMap(
      observation({
        sightings: [
          sighting('s1', 'cup_handle_far', 6, { band: 'rim_upper' }),
          sighting('s2', 'cup_turn_a', 2, { band: 'middle' }),
          sighting('s3', 'cup_turn_b', 3, { band: 'lower_base', surface: 'cup_base' }),
        ],
        marks: [mark('M1', ['s1']), mark('M2', ['s2']), mark('M3', ['s3'], { surface: 'cup_base' })],
      }),
    );
    expect(map.cupMarks.map((m) => [m.id, m.band, m.surface])).toEqual([
      ['M1', 'rim_upper', 'cup_wall'],
      ['M2', 'middle', 'cup_wall'],
      ['M3', 'lower_base', 'cup_base'],
    ]);
  });

  it('P: a visual relation is preserved (without its confidence); a low-confidence relation is not accepted', () => {
    const map = okMap(
      observation({
        sightings: [sighting('s1', 'cup_handle_far', 6), sighting('s2', 'cup_handle_far', 7), sighting('s3', 'cup_turn_a', 2)],
        marks: [mark('M1', ['s1']), mark('M2', ['s2']), mark('M3', ['s3'])],
        relations: [
          { a: 'M1', b: 'M2', kind: 'touching', confidence: 'medium' },
          { a: 'M2', b: 'M3', kind: 'near', confidence: 'low' },
        ],
      }),
    );
    expect(map.relations).toEqual([{ a: 'M1', b: 'M2', kind: 'touching' }]);
  });

  it('Q: a cup ↔ saucer relation is rejected', () => {
    const result = buildCoffeeV3MarkMap(
      observation({
        sightings: [sighting('s1', 'cup_handle_far', 6), sighting('s2', 'saucer', null)],
        marks: [mark('M1', ['s1']), mark('M2', ['s2'], { surface: 'saucer' })],
        relations: [{ a: 'M1', b: 'M2', kind: 'near', confidence: 'high' }],
      }),
    );
    expect(result).toEqual({ status: 'invalid', failure: 'cross_surface_relation' });
  });

  it('R: saucer marks stay separate, keep their zone, and have no band or handle relation', () => {
    const map = okMap(
      observation({
        sightings: [sighting('s1', 'cup_handle_far', 6), sighting('s2', 'saucer', null, { saucerZone: 'edge' })],
        marks: [mark('M1', ['s1']), mark('M2', ['s2'], { surface: 'saucer' })],
        saucer: { surfaceState: 'islands', flow: { present: true, direction: 'toward_edge' } },
      }),
    );
    expect(map.cupMarks.map((m) => m.id)).toEqual(['M1']);
    expect(map.saucerMarks).toEqual([
      expect.objectContaining({ id: 'M2', surface: 'saucer', saucerZone: 'edge', band: null, handleRelation: null }),
    ]);
    expect(map.saucer).toEqual({ surfaceState: 'islands', flow: { present: true, direction: 'toward_edge' } });
  });

  it('S / no padding: a clean saucer and a cup with zero or one mark are structurally valid', () => {
    const empty = okMap(observation({}));
    expect(empty).toMatchObject({ cupMarks: [], saucerMarks: [], distinctMarkCount: 0, saucer: { surfaceState: 'clean' } });
    const single = okMap(observation({ sightings: [sighting('s1', 'cup_turn_b', 3)], marks: [mark('M1', ['s1'])] }));
    expect(single.distinctMarkCount).toBe(1);
  });
});

describe('V3 privacy boundary (U)', () => {
  it('rejects a raw observation and a mark map', () => {
    const map = okMap(
      observation({
        sightings: [sighting('s1', 'cup_handle_far', 6)],
        marks: [mark('M1', ['s1'], { resemblances: [{ label: 'a small arch', strength: 'strong' }] })],
      }),
    );
    expect(() => assertCoffeeV3MeaningOnly(map)).toThrow(/coffee_v3_private_field_leak/);
    expect(() => assertCoffeeV3MeaningOnly(observation({}))).toThrow(/coffee_v3_private_field_leak/);
  });

  it.each([
    [{ notes: ['the stroke on the rim'] }],
    [{ threads: [{ where: 'handle_near' }] }],
    [{ threads: [{ text: 'Fincanında bir haber var.' }] }],
    [{ placement: { rimClock: 3 } }],
    [{ source: 'cup_turn_a' }],
    [{ quality: { confidence: 'high' } }],
  ])('rejects raw visual keys or tokens: %j', (value) => {
    expect(coffeeV3PrivacyViolations(value).length).toBeGreaterThan(0);
  });

  it('accepts a meaning-only payload', () => {
    expect(() =>
      assertCoffeeV3MeaningOnly({
        subject: 'general',
        threads: [{ development: 'communication', horizon: 'near_term', valence: 'positive', nuance: ['plural'] }],
      }),
    ).not.toThrow();
  });
});

describe('V3 schema and prompt', () => {
  type SchemaNode = { type?: unknown; properties?: Record<string, SchemaNode>; items?: SchemaNode; required?: string[]; additionalProperties?: unknown };
  const objects = (node: SchemaNode, path = '$'): Array<[string, SchemaNode]> => [
    ...(node.properties ? [[path, node] as [string, SchemaNode]] : []),
    ...Object.entries(node.properties ?? {}).flatMap(([key, child]) => objects(child, `${path}.${key}`)),
    ...(node.items ? objects(node.items, `${path}[]`) : []),
  ];

  it('is strict: additionalProperties false and every property required on every object', () => {
    const all = objects(COFFEE_V3_OBSERVER_SCHEMA as unknown as SchemaNode);
    expect(all.length).toBeGreaterThan(8);
    for (const [path, node] of all) {
      expect(node.additionalProperties, path).toBe(false);
      expect([...(node.required ?? [])].sort(), path).toEqual(Object.keys(node.properties ?? {}).sort());
    }
  });

  it('enforces the size limits', () => {
    const p = COFFEE_V3_OBSERVER_SCHEMA.properties;
    expect(p.sightings.maxItems).toBe(30);
    expect(p.marks.maxItems).toBe(16);
    expect(p.relations.maxItems).toBe(12);
    expect(p.marks.items.properties.resemblances.maxItems).toBe(2);
    expect(p.sightings.items.properties.description.maxLength).toBe(160);
    expect(p.marks.items.properties.resemblances.items.properties.label.maxLength).toBe(40);
    expect(p.sightings.items.properties.slot.enum).toEqual([...COFFEE_V3_SLOTS]);
  });

  it('anti-pareidolia: the V3 prompt names no symbol catalog and keeps the pass order', () => {
    const prompt = [coffeeV3ObserverSystem(), coffeeV3ObserverUser(), ...COFFEE_V3_SLOTS.map(coffeeV3SlotLabel)].join(' ');
    const catalog =
      /\b(birds?|fish|rings?|hearts?|trees?|keys?|roads?|paths?|snakes?|stars?|moons?|letters?|envelopes?|flowers?|mountains?|anchors?|horses?|eyes?|crosses|teapots?|houses?|persons?|faces?|kus|balik|yuzuk|kalp|agac|anahtar|yol)\b/i;
    expect(prompt.match(catalog)).toBeNull();
    const order = ['PASS 1', 'PASS 2', 'PASS 3', 'PASS 4', 'PASS 5', 'PASS 6'].map((p) => prompt.indexOf(p));
    expect(order.every((index) => index >= 0)).toBe(true);
    expect([...order].sort((a, b) => a - b)).toEqual(order);
    expect(prompt).toMatch(/No candidate is a correct and common answer/);
    expect(prompt).toMatch(/Never tell a fortune/);
  });
});

describe('V2 dark-path guarantee (V, W)', () => {
  it('V2 slots are exactly cup_primary, cup_secondary, saucer and reject every V3-only slot', () => {
    expect([...COFFEE_V2_SLOTS]).toEqual(['cup_primary', 'cup_secondary', 'saucer']);
    for (const slot of ['cup_handle_far', 'cup_turn_a', 'cup_turn_b']) expect(isCoffeeV2Slot(slot)).toBe(false);
  });

  it('the V2 schema and prompt are untouched by V3', () => {
    expect(COFFEE_V2_OBSERVER_SCHEMA.properties.evidence.items.properties.sourceSlot.enum).toEqual([
      'cup_primary',
      'cup_secondary',
      'saucer',
    ]);
    expect(COFFEE_V2_OBSERVER_SCHEMA.properties.evidence.items.required).toContain('region');
    expect(coffeeV2ObserverSystem()).not.toMatch(/multi_view_marks_v3|PASS 1|cup_handle_far/);
  });

  it('only the V3 pilot files and the dark M1 engine reference V3; no dispatch, pipeline, route, worker, billing or gem code does', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    const v3 = /coffeeV3|CoffeeV3|COFFEE_V3|multi_view_marks_v3|coffee-v3-mark-map|cup_handle_far|cup_turn_[ab]/;
    const users = walk(src)
      .filter((path) => v3.test(readFileSync(path, 'utf8')))
      .map((path) => path.slice(src.length + 1).replace(/\\/g, '/'))
      .sort();
    expect(users).toEqual([
      'ai/reading/coffee-m1-interpretation.ts',
      'ai/reading/coffee-m2-semantic-engine.ts',
      'ai/reading/coffee-m2-turkish-realization-policy.ts',
      'ai/reading/coffee-m2-turkish-surface-bank.ts',
      'ai/reading/coffee-m2-writer-beat-plan.ts',
      'ai/reading/coffee-m2-writer-prompt.ts',
      'ai/reading/coffee-v3-live-pipeline.ts',
      'ai/reading/coffee-v3-mark-map.ts',
      'ai/reading/observer-prompts.ts',
      'ai/reading/schemas.ts',
      'ai/reading/types.ts',
      'ai/service.ts',
      'config.ts',
      // LIS1 — the dark V3 four-view STAGING contract (data ownership only; no dispatch).
      'reading/operation-staged-image-model.ts',
      'reading/operation-staged-image-repository.ts',
      'reading/operation-staged-image-service.ts',
      // LIS2 — V3 now owned by contract: internal entry + bridge, worker dispatch, gem
      // completeness, the gated create route and the creation flag. The V2 pipeline stays V3-free.
      'reading/reading-processor-execute.ts',
      'reading/reading-processor.ts',
      'routes/gem-acceleration.ts',
      'routes/reading-operations.ts',
    ]);
  });

  it('the app still captures exactly the three V2 slots', () => {
    const dart = readFileSync(resolve(process.cwd(), '../lib/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart'), 'utf8');
    expect(dart).toMatch(/enum CoffeeV2PhotoSlot \{ cupPrimary, cupSecondary, saucer \}/);
    expect(dart).not.toMatch(/cup_handle_far|cup_turn_a|cup_turn_b/);
  });

  it('merge tolerance is the reviewed ±2 clock hours', () => {
    expect(COFFEE_V3_MERGE_ANGLE_TOLERANCE).toBe(60);
  });
});
