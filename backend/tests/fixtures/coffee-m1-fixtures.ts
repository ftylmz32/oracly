import { buildCoffeeV3MarkMap, type CoffeeV3MarkMap } from '../../src/ai/reading/coffee-v3-mark-map.js';
import type {
  CoffeeMultiViewObservationV3,
  CoffeeV3Band,
  CoffeeV3Form,
  CoffeeV3Mark,
  CoffeeV3Relation,
  CoffeeV3Saucer,
  CoffeeV3Sighting,
  CoffeeV3Slot,
  CoffeeV3View,
} from '../../src/ai/reading/types.js';

/**
 * Handcrafted V3 fixtures for the dark M1 engine. Every fixture goes through
 * the real buildCoffeeV3MarkMap, so M1 only ever sees a normalized map.
 * The handle sits at 12 / 4 / 8 o'clock in the three cup frames; a mark
 * `hours` clock-hours from the handle appears at handleClock + hours.
 */
type CupSlot = Exclude<CoffeeV3Slot, 'saucer'>;
const HANDLE_CLOCK: Record<CupSlot, number> = { cup_handle_far: 12, cup_turn_a: 4, cup_turn_b: 8 };
const rimAt = (slot: CupSlot, hours: number) => ((HANDLE_CLOCK[slot] + hours - 1) % 12) + 1;

const VIEWS: CoffeeV3View[] = [
  { slot: 'cup_handle_far', surfaceVisible: true, focusLightAdequate: true, residueVisible: true, handleVisible: true, handleClock: 12 },
  { slot: 'cup_turn_a', surfaceVisible: true, focusLightAdequate: true, residueVisible: true, handleVisible: true, handleClock: 4 },
  { slot: 'cup_turn_b', surfaceVisible: true, focusLightAdequate: true, residueVisible: true, handleVisible: true, handleClock: 8 },
  { slot: 'saucer', surfaceVisible: true, focusLightAdequate: true, residueVisible: true, handleVisible: null, handleClock: null },
];
const FORM: CoffeeV3Form = {
  motion: 'unknown',
  verticalDirection: 'unknown',
  openness: 'unknown',
  course: 'unknown',
  posture: 'unknown',
  continuity: 'unknown',
  grouping: 'unknown',
};

export type M1MarkSpec = {
  id: string;
  /** Shorthand for one strong candidate; null = no candidate. */
  label?: string | null;
  resemblances?: CoffeeV3Mark['resemblances'];
  band?: CoffeeV3Band;
  /** Clock hours from the handle (0 = handle side, 6 = opposite). Default 3 (neutral). */
  hours?: number;
  slots?: CupSlot[];
  visibility?: CoffeeV3Sighting['visibility'];
  confidence?: CoffeeV3Sighting['confidence'];
  form?: Partial<CoffeeV3Form>;
  saucer?: boolean;
};

export type M1FixtureSpec = {
  marks: M1MarkSpec[];
  relations?: Array<Omit<CoffeeV3Relation, 'confidence'> & { confidence?: CoffeeV3Relation['confidence'] }>;
  ambiguities?: Array<[string, string]>;
  saucer?: CoffeeV3Saucer;
};

export function m1Observation(spec: M1FixtureSpec): CoffeeMultiViewObservationV3 {
  const sightings: CoffeeV3Sighting[] = [];
  const marks: CoffeeV3Mark[] = [];
  for (const m of spec.marks) {
    const slots: CoffeeV3Slot[] = m.saucer ? ['saucer'] : (m.slots ?? ['cup_handle_far']);
    const ids = slots.map((slot) => `${m.id}-${slot}`);
    slots.forEach((slot, index) =>
      sightings.push({
        id: ids[index],
        slot,
        surface: slot === 'saucer' ? 'saucer' : 'cup_wall',
        band: slot === 'saucer' ? 'unknown' : (m.band ?? 'middle'),
        rimClock: slot === 'saucer' ? null : rimAt(slot, m.hours ?? 3),
        saucerZone: slot === 'saucer' ? 'center' : null,
        description: 'A dark compact residue mark with a soft edge.',
        visibility: m.visibility ?? 'clear',
        confidence: m.confidence ?? 'high',
      }),
    );
    marks.push({
      id: m.id,
      surface: m.saucer ? 'saucer' : 'cup_wall',
      sightingIds: ids,
      form: { ...FORM, ...m.form },
      resemblances: m.resemblances ?? (m.label ? [{ label: m.label, strength: 'strong' }] : []),
    });
  }
  return {
    contract: 'multi_view_marks_v3',
    usable: true,
    reason: null,
    views: VIEWS,
    sightings,
    marks,
    relations: (spec.relations ?? []).map((r) => ({ confidence: 'high', ...r })),
    ambiguities: (spec.ambiguities ?? []).map((pair) => ({ marks: pair, reason: 'possible_same_mark' })),
    saucer: spec.saucer ?? { surfaceState: 'clean', flow: { present: false, direction: 'none' } },
  };
}

export function m1Map(spec: M1FixtureSpec): CoffeeV3MarkMap {
  const result = buildCoffeeV3MarkMap(m1Observation(spec));
  if (result.status !== 'ok') throw new Error(`fixture is not a valid V3 map: ${JSON.stringify(result)}`);
  return result.map;
}

/** Eight representative cups for the QA private-meaning inspection. */
export const M1_QA_CUPS = {
  money_fish_tree: {
    subject: 'money_finance' as const,
    spec: {
      marks: [
        { id: 'M1', label: 'a fish leaping clear', band: 'rim_upper' as const, form: { motion: 'moving' as const, verticalDirection: 'rising' as const } },
        { id: 'M2', label: 'a young tree', form: { course: 'branching' as const, posture: 'upright' as const } },
      ],
      relations: [{ a: 'M1', b: 'M2', kind: 'near' as const }],
    },
  },
  general_two_birds: {
    subject: null,
    spec: {
      marks: [
        { id: 'M1', label: 'a bird gliding', band: 'rim_upper' as const, form: { motion: 'moving' as const, openness: 'open' as const } },
        { id: 'M2', label: 'a bird diving', hours: 9, form: { motion: 'moving' as const, verticalDirection: 'descending' as const } },
      ],
    },
  },
  love_ring_heart: {
    subject: 'love_relationships' as const,
    spec: {
      marks: [
        { id: 'M1', label: 'a plain band ring', form: { openness: 'closed' as const, grouping: 'isolated' as const } },
        { id: 'M2', label: 'a heart on its side', hours: 0, form: { posture: 'tilted' as const } },
      ],
      relations: [{ a: 'M1', b: 'M2', kind: 'touching' as const }],
    },
  },
  person_bird: {
    subject: 'person_of_interest' as const,
    spec: {
      marks: [{ id: 'M1', label: 'a bird with folded wings', form: { motion: 'still' as const, openness: 'closed' as const } }],
    },
  },
  career_key_path: {
    subject: 'career_work' as const,
    spec: {
      marks: [
        { id: 'M1', label: 'a small key', form: { openness: 'open' as const } },
        { id: 'M2', label: 'a path bending away', band: 'lower_base' as const, form: { course: 'bending' as const } },
      ],
      relations: [{ a: 'M1', b: 'M2', kind: 'connected' as const }],
    },
  },
  general_rich_three: {
    subject: null,
    spec: {
      marks: [
        { id: 'M1', label: 'a fish', band: 'rim_upper' as const, form: { motion: 'moving' as const } },
        { id: 'M2', label: 'a ring', form: { openness: 'closed' as const } },
        { id: 'M3', label: 'a winding path', band: 'lower_base' as const, form: { course: 'bending' as const } },
      ],
    },
  },
  general_letter_broken: {
    subject: null,
    spec: {
      marks: [
        { id: 'M1', label: 'a folded letter', form: { continuity: 'broken' as const } },
        { id: 'M2', label: 'a folded letter', hours: 8, form: { continuity: 'broken' as const } },
      ],
    },
  },
  sparse_unmapped_saucer_flow: {
    subject: null,
    spec: {
      marks: [
        { id: 'M1', label: 'a small arch' },
        { id: 'M2', label: 'a bird', saucer: true },
      ],
      saucer: { surfaceState: 'flow' as const, flow: { present: true, direction: 'toward_edge' as const } },
    },
  },
} satisfies Record<string, { subject: 'general' | 'love_relationships' | 'career_work' | 'money_finance' | 'person_of_interest' | null; spec: M1FixtureSpec }>;
