import {
  COFFEE_V3_CONTRACT,
  COFFEE_V3_MAP_SLOTS,
  type CoffeeMultiViewObservationV3,
  type CoffeeV3Band,
  type CoffeeV3CupBand,
  type CoffeeV3Form,
  type CoffeeV3MarkKind,
  type CoffeeV3Topology,
  type CoffeeV3HandleRelation,
  type CoffeeV3Mark,
  type CoffeeV3RelationKind,
  type CoffeeV3Saucer,
  type CoffeeV3SaucerZone,
  type CoffeeV3Sighting,
  type CoffeeV3MapSlot,
  type CoffeeV3Surface,
  type CoffeeV3View,
} from './types.js';

/**
 * Coffee Observer V3 — deterministic mark map. ADDITIVE AND DARK: no live
 * path calls this yet. It validates and normalizes a multi-view observation;
 * it never interprets fortune, never maps a resemblance to a meaning family,
 * and never turns confidence or visibility into strength.
 */

export type CoffeeV3StructuralFailure =
  | 'wrong_contract'
  | 'duplicate_view'
  | 'duplicate_sighting_id'
  | 'unknown_view'
  | 'slot_surface_mismatch'
  | 'duplicate_mark_id'
  | 'empty_mark'
  | 'unknown_sighting'
  | 'sighting_in_multiple_marks'
  | 'unassigned_sighting'
  | 'cup_saucer_merge'
  | 'too_many_resemblances'
  | 'unknown_relation_mark'
  | 'self_relation'
  | 'cross_surface_relation'
  | 'duplicate_relation'
  | 'unknown_ambiguity_mark'
  | 'self_ambiguity'
  | 'duplicate_ambiguity'
  // V3G1
  | 'clear_area_resemblance'
  | 'clear_area_topology'
  | 'invalid_band_coverage'
  | 'saucer_band_coverage'
  | 'cross_kind_ambiguity';

/** One accepted physical mark, machine-only. No observer prose except the candidate labels M1 will read. */
export type CoffeeV3MapMark = {
  id: string;
  /** Marks sharing a group MAY be one physical mark; count a group once. */
  identityGroup: string;
  identity: 'certain' | 'possible_same_mark';
  surface: CoffeeV3Surface;
  coverage: { count: number; slots: CoffeeV3MapSlot[] };
  /** Cup only; null on the saucer. */
  band: CoffeeV3Band | null;
  /** Cup only; null on the saucer. */
  handleRelation: CoffeeV3HandleRelation | null;
  /** Saucer only; null on the cup. */
  saucerZone: CoffeeV3SaucerZone | null;
  /** V3G1: residue or an observed clear area (a clear area never has a usable candidate). */
  kind: CoffeeV3MarkKind;
  /** V3G1: physical topology; `unknown` when not stated. */
  topology: CoffeeV3Topology;
  /**
   * V3G1: the cup bands this physical mark is EXPLICITLY seen to cross: the
   * union of its sightings' stated bandCoverage, in rim → base order. Null
   * when no sighting states coverage (never invented by a merge). Cup only.
   */
  bandSpan: CoffeeV3CupBand[] | null;
  form: CoffeeV3Form;
  /** Stored candidates; `usable` is the only quality outcome that leaves this module. */
  candidates: Array<{ label: string; usable: boolean }>;
};

export type CoffeeV3MarkMap = {
  contract: typeof COFFEE_V3_CONTRACT;
  cupMarks: CoffeeV3MapMark[];
  saucerMarks: CoffeeV3MapMark[];
  relations: Array<{ a: string; b: string; kind: CoffeeV3RelationKind }>;
  /** Physical marks after deduplication: a possible-same group counts once. */
  distinctMarkCount: number;
  saucer: CoffeeV3Saucer;
  audit: { untrustedMergeIds: string[]; rejectedMarkIds: string[] };
};

export type CoffeeV3MarkMapResult =
  | { status: 'ok'; map: CoffeeV3MarkMap }
  | { status: 'unusable' }
  | { status: 'invalid'; failure: CoffeeV3StructuralFailure };

// ---------------------------------------------------------------------------
// Handle-relative angle
// ---------------------------------------------------------------------------

/** Two sightings of one mark must agree on the cup angle within this many degrees (±2 clock hours). */
export const COFFEE_V3_MERGE_ANGLE_TOLERANCE = 60;

export function coffeeV3ClockValid(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 1 && value <= 12;
}

/**
 * Cup angle in degrees, [0, 360), of a rim position measured clockwise from
 * the handle. Both clocks are read in the SAME frame, so the camera's
 * rotation cancels out; wraparound (12 → 1, 11 → 1) is normalized.
 */
export function coffeeV3HandleRelativeAngle(rimClock: number, handleClock: number): number {
  return ((((rimClock - handleClock) % 12) + 12) % 12) * 30;
}

/** Shortest distance between two angles on the circle, in degrees [0, 180]. */
export function coffeeV3AngleDistance(a: number, b: number): number {
  const d = Math.abs(a - b) % 360;
  return Math.min(d, 360 - d);
}

export function coffeeV3HandleRelation(angle: number | null): CoffeeV3HandleRelation {
  if (angle === null) return 'unknown';
  if (coffeeV3AngleDistance(angle, 0) <= 45) return 'handle_near';
  if (coffeeV3AngleDistance(angle, 180) <= 45) return 'handle_opposite';
  return 'neutral';
}

function circularMean(angles: number[]): number {
  const x = angles.reduce((sum, a) => sum + Math.cos((a * Math.PI) / 180), 0);
  const y = angles.reduce((sum, a) => sum + Math.sin((a * Math.PI) / 180), 0);
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

// ---------------------------------------------------------------------------
// Structural validation
// ---------------------------------------------------------------------------

const isSaucer = (surface: CoffeeV3Surface) => surface === 'saucer';
const pairKey = (a: string, b: string) => (a < b ? `${a}|${b}` : `${b}|${a}`);

function structuralFailure(obs: CoffeeMultiViewObservationV3): CoffeeV3StructuralFailure | null {
  const viewSlots = new Set<CoffeeV3MapSlot>();
  for (const view of obs.views) {
    if (viewSlots.has(view.slot)) return 'duplicate_view';
    viewSlots.add(view.slot);
  }
  const sightings = new Map<string, CoffeeV3Sighting>();
  for (const sighting of obs.sightings) {
    if (sightings.has(sighting.id)) return 'duplicate_sighting_id';
    if (!viewSlots.has(sighting.slot)) return 'unknown_view';
    if ((sighting.slot === 'saucer') !== isSaucer(sighting.surface)) return 'slot_surface_mismatch';
    const coverage = sighting.bandCoverage ?? [];
    if (coverage.length) {
      if (isSaucer(sighting.surface)) return 'saucer_band_coverage';
      if (coverage.some((b) => !(b in BAND_ORDER)) || new Set(coverage).size !== coverage.length) return 'invalid_band_coverage';
      if (sighting.band !== 'unknown' && !coverage.includes(sighting.band)) return 'invalid_band_coverage';
    }
    sightings.set(sighting.id, sighting);
  }
  const markIds = new Set<string>();
  const owner = new Map<string, string>();
  const surfaceOf = new Map<string, CoffeeV3Surface>();
  const kindOf = new Map(obs.marks.map((m) => [m.id, m.kind ?? 'residue']));
  for (const mark of obs.marks) {
    if (markIds.has(mark.id)) return 'duplicate_mark_id';
    markIds.add(mark.id);
    surfaceOf.set(mark.id, mark.surface);
    if (mark.sightingIds.length === 0) return 'empty_mark';
    if (mark.resemblances.length > 2) return 'too_many_resemblances';
    if (mark.kind === 'clear_area' && mark.resemblances.length > 0) return 'clear_area_resemblance';
    if (mark.kind === 'clear_area' && (mark.topology ?? 'unknown') !== 'unknown') return 'clear_area_topology';
    for (const id of mark.sightingIds) {
      const sighting = sightings.get(id);
      if (!sighting) return 'unknown_sighting';
      if (owner.has(id)) return 'sighting_in_multiple_marks';
      owner.set(id, mark.id);
      if (isSaucer(sighting.surface) !== isSaucer(mark.surface)) return 'cup_saucer_merge';
    }
  }
  if (owner.size !== sightings.size) return 'unassigned_sighting';
  const relationPairs = new Set<string>();
  for (const relation of obs.relations) {
    const a = surfaceOf.get(relation.a);
    const b = surfaceOf.get(relation.b);
    if (!a || !b) return 'unknown_relation_mark';
    if (relation.a === relation.b) return 'self_relation';
    if (isSaucer(a) !== isSaucer(b)) return 'cross_surface_relation';
    const key = pairKey(relation.a, relation.b);
    if (relationPairs.has(key)) return 'duplicate_relation';
    relationPairs.add(key);
  }
  const ambiguityPairs = new Set<string>();
  for (const ambiguity of obs.ambiguities) {
    const [a, b] = ambiguity.marks;
    if (!markIds.has(a) || !markIds.has(b)) return 'unknown_ambiguity_mark';
    if (a === b) return 'self_ambiguity';
    if ((kindOf.get(a) ?? 'residue') !== (kindOf.get(b) ?? 'residue')) return 'cross_kind_ambiguity';
    const key = pairKey(a, b);
    if (ambiguityPairs.has(key)) return 'duplicate_ambiguity';
    ambiguityPairs.add(key);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Multi-view merge trust
// ---------------------------------------------------------------------------

const BAND_ORDER: Record<Exclude<CoffeeV3Band, 'unknown'>, number> = { rim_upper: 0, middle: 1, lower_base: 2 };
const SLOT_ORDER = new Map<CoffeeV3MapSlot, number>(COFFEE_V3_MAP_SLOTS.map((slot, index) => [slot, index]));
const VISIBILITY_ORDER = { clear: 0, partial: 1, uncertain: 2 } as const;

function sightingAngle(sighting: CoffeeV3Sighting, views: Map<CoffeeV3MapSlot, CoffeeV3View>): number | null {
  if (isSaucer(sighting.surface)) return null;
  const view = views.get(sighting.slot);
  if (!view?.handleVisible || !coffeeV3ClockValid(view.handleClock) || !coffeeV3ClockValid(sighting.rimClock)) {
    return null;
  }
  return coffeeV3HandleRelativeAngle(sighting.rimClock, view.handleClock);
}

/**
 * A claimed multi-sighting mark is trusted only when every pair of its
 * sightings comes from a different, readable, handle-anchored view, sits on
 * the same surface, agrees on band within one step, and agrees on the
 * handle-relative angle. Any unknown makes the merge untrusted: the system
 * never invents certainty.
 */
function mergeTrusted(sightings: CoffeeV3Sighting[], views: Map<CoffeeV3MapSlot, CoffeeV3View>): boolean {
  if (sightings.length < 2) return true;
  if (new Set(sightings.map((s) => s.slot)).size !== sightings.length) return false;
  if (new Set(sightings.map((s) => s.surface)).size !== 1) return false;
  for (const s of sightings) {
    const view = views.get(s.slot);
    if (!view?.surfaceVisible || !view.focusLightAdequate) return false;
  }
  for (let i = 0; i < sightings.length; i += 1) {
    for (let j = i + 1; j < sightings.length; j += 1) {
      const [a, b] = [sightings[i], sightings[j]];
      if (a.band === 'unknown' || b.band === 'unknown') return false;
      if (Math.abs(BAND_ORDER[a.band] - BAND_ORDER[b.band]) > 1) return false;
      const angleA = sightingAngle(a, views);
      const angleB = sightingAngle(b, views);
      if (angleA === null || angleB === null) return false;
      if (coffeeV3AngleDistance(angleA, angleB) > COFFEE_V3_MERGE_ANGLE_TOLERANCE) return false;
    }
  }
  return true;
}

// ---------------------------------------------------------------------------
// Normalization
// ---------------------------------------------------------------------------

type WorkingMark = CoffeeV3Mark & { sourceId: string };

const foldLabel = (label: string) => label.trim().toLocaleLowerCase('en-US').replace(/\s+/g, ' ');

function markBand(sightings: CoffeeV3Sighting[]): CoffeeV3Band {
  const bands = new Set(sightings.map((s) => s.band));
  if (bands.size === 1) return sightings[0].band;
  // Adjacent bands on a trusted merge: the best-seen sighting places the mark.
  const best = [...sightings].sort(
    (a, b) =>
      VISIBILITY_ORDER[a.visibility] - VISIBILITY_ORDER[b.visibility] ||
      (SLOT_ORDER.get(a.slot) ?? 0) - (SLOT_ORDER.get(b.slot) ?? 0),
  )[0];
  return best.band;
}

/** V3G1: union of the sightings' explicit band coverage, rim → base; null when none states it. */
function bandSpan(sightings: CoffeeV3Sighting[]): CoffeeV3CupBand[] | null {
  const stated = sightings.flatMap((s) => s.bandCoverage ?? []);
  if (stated.length === 0) return null;
  return [...new Set(stated)].sort((a, b) => BAND_ORDER[a] - BAND_ORDER[b]);
}

function candidates(mark: CoffeeV3Mark, sightings: CoffeeV3Sighting[]): CoffeeV3MapMark['candidates'] {
  // Partial-only marks may carry form, never a sign; two different strong
  // candidates conflict and neither is usable.
  const hasClear = sightings.some((s) => s.visibility === 'clear');
  const strong = new Set(mark.resemblances.filter((r) => r.strength === 'strong').map((r) => foldLabel(r.label)));
  return mark.resemblances.map((r) => ({
    label: r.label.trim(),
    usable: hasClear && r.strength === 'strong' && strong.size === 1,
  }));
}

function identityGroups(markIds: string[], pairs: Array<[string, string]>): Map<string, string> {
  const parent = new Map(markIds.map((id) => [id, id]));
  const find = (id: string): string => {
    const p = parent.get(id) ?? id;
    if (p === id) return id;
    const root = find(p);
    parent.set(id, root);
    return root;
  };
  for (const [a, b] of pairs) {
    const [ra, rb] = [find(a), find(b)];
    if (ra !== rb) parent.set(ra < rb ? rb : ra, ra < rb ? ra : rb);
  }
  return new Map(markIds.map((id) => [id, find(id)]));
}

export function buildCoffeeV3MarkMap(obs: CoffeeMultiViewObservationV3): CoffeeV3MarkMapResult {
  if (obs.contract !== COFFEE_V3_CONTRACT) return { status: 'invalid', failure: 'wrong_contract' };
  if (!obs.usable) return { status: 'unusable' };
  const failure = structuralFailure(obs);
  if (failure) return { status: 'invalid', failure };

  const views = new Map(obs.views.map((view) => [view.slot, view]));
  const sightings = new Map(obs.sightings.map((s) => [s.id, s]));
  const sightingsOf = (mark: CoffeeV3Mark) =>
    mark.sightingIds
      .map((id) => sightings.get(id)!)
      .sort((a, b) => (SLOT_ORDER.get(a.slot) ?? 0) - (SLOT_ORDER.get(b.slot) ?? 0) || (a.id < b.id ? -1 : 1));

  // 1) Untrusted merges are split, one part per sighting, never deleted; the
  //    parts are linked as possible_same_mark.
  const working: WorkingMark[] = [];
  const partsOf = new Map<string, string[]>();
  const ambiguityPairs: Array<[string, string]> = obs.ambiguities.map((a) => [a.marks[0], a.marks[1]]);
  const untrustedMergeIds: string[] = [];
  for (const mark of obs.marks) {
    const own = sightingsOf(mark);
    if (mergeTrusted(own, views)) {
      working.push({ ...mark, sightingIds: own.map((s) => s.id), sourceId: mark.id });
      partsOf.set(mark.id, [mark.id]);
      continue;
    }
    untrustedMergeIds.push(mark.id);
    const parts = own.map((s, index) => ({
      ...mark,
      id: `${mark.id}#${index + 1}`,
      surface: s.surface,
      sightingIds: [s.id],
      sourceId: mark.id,
    }));
    working.push(...parts);
    partsOf.set(mark.id, parts.map((p) => p.id));
    for (let i = 0; i < parts.length; i += 1) {
      for (let j = i + 1; j < parts.length; j += 1) ambiguityPairs.push([parts[i].id, parts[j].id]);
    }
  }
  const expand = (id: string) => partsOf.get(id) ?? [id];

  // 2) Quality gate: structural acceptance only. Confidence/visibility never
  //    leave this module except as acceptance and candidate usability.
  const rejectedMarkIds: string[] = [];
  const accepted = working.filter((mark) => {
    const own = sightingsOf(mark);
    const seen = own.some((s) => s.visibility === 'clear' || s.visibility === 'partial');
    const ok = seen && !own.every((s) => s.confidence === 'low');
    if (!ok) rejectedMarkIds.push(mark.id);
    return ok;
  });
  const acceptedIds = new Set(accepted.map((m) => m.id));

  const pairs = ambiguityPairs
    .flatMap(([a, b]) => expand(a).flatMap((pa) => expand(b).map((pb): [string, string] => [pa, pb])))
    .filter(([a, b]) => a !== b && acceptedIds.has(a) && acceptedIds.has(b));
  const groups = identityGroups([...acceptedIds], pairs);
  const groupSize = new Map<string, number>();
  for (const group of groups.values()) groupSize.set(group, (groupSize.get(group) ?? 0) + 1);

  const mapMarks = accepted.map((mark): CoffeeV3MapMark => {
    const own = sightingsOf(mark);
    const saucer = isSaucer(mark.surface);
    const angles = own.map((s) => sightingAngle(s, views)).filter((a): a is number => a !== null);
    const group = groups.get(mark.id) ?? mark.id;
    return {
      id: mark.id,
      identityGroup: group,
      identity: (groupSize.get(group) ?? 1) > 1 ? 'possible_same_mark' : 'certain',
      surface: mark.surface,
      coverage: { count: own.length, slots: own.map((s) => s.slot) },
      band: saucer ? null : markBand(own),
      handleRelation: saucer ? null : coffeeV3HandleRelation(angles.length ? circularMean(angles) : null),
      saucerZone: saucer ? (own[0].saucerZone ?? 'unknown') : null,
      kind: mark.kind ?? 'residue',
      topology: mark.topology ?? 'unknown',
      bandSpan: saucer ? null : bandSpan(own),
      form: { ...mark.form },
      candidates: candidates(mark, own),
    };
  });

  // 3) Relations: low-confidence relations are not accepted; split marks
  //    carry the relation on every part; one relation per unordered pair.
  const relationSeen = new Set<string>();
  const relations: CoffeeV3MarkMap['relations'] = [];
  for (const relation of obs.relations) {
    if (relation.confidence === 'low') continue;
    for (const a of expand(relation.a)) {
      for (const b of expand(relation.b)) {
        if (!acceptedIds.has(a) || !acceptedIds.has(b) || a === b) continue;
        const key = pairKey(a, b);
        if (relationSeen.has(key)) continue;
        relationSeen.add(key);
        relations.push({ a, b, kind: relation.kind });
      }
    }
  }

  return {
    status: 'ok',
    map: {
      contract: COFFEE_V3_CONTRACT,
      cupMarks: mapMarks.filter((m) => !isSaucer(m.surface)),
      saucerMarks: mapMarks.filter((m) => isSaucer(m.surface)),
      relations,
      distinctMarkCount: new Set(groups.values()).size,
      saucer: { surfaceState: obs.saucer.surfaceState, flow: { ...obs.saucer.flow } },
      audit: { untrustedMergeIds, rejectedMarkIds },
    },
  };
}

// ---------------------------------------------------------------------------
// Privacy boundary (future writer handoff)
// ---------------------------------------------------------------------------

/** Keys that only exist on the private observation / mark-map side. */
const PRIVATE_KEYS = new Set([
  'description', 'resemblance', 'resemblances', 'label', 'candidates', 'slot', 'slots', 'sourceSlot',
  'rimClock', 'handleClock', 'band', 'confidence', 'visibility', 'sighting', 'sightings', 'sightingIds',
  'mark', 'marks', 'markIds', 'cupMarks', 'saucerMarks', 'saucer', 'saucerZone', 'surface', 'coverage',
  'handleRelation', 'form', 'identityGroup', 'views', 'evidence', 'evidenceIds', 'region', 'geometry',
]);

/**
 * M1.3 — inflection-safe private vocabulary. Matched on whole folded tokens,
 * never on substrings:
 * - private enum / slot values: the exact token;
 * - English words: the word or its plain plural (cups, handles);
 * - Turkish nouns: a stem plus a bounded nominal suffix chain (plural,
 *   possessive, case, -ki, copula), so "fincanımda", "kulpunda", "telveye",
 *   "tabakta" match while "tabaka" (layer) and "fincancı" do not.
 */
const PRIVATE_ENUM_TOKENS = new Set<string>([
  ...COFFEE_V3_MAP_SLOTS, 'cup_wall', 'cup_base', 'rim_upper', 'lower_base', 'middle_ring', 'handle_near',
  'handle_opposite', 'possible_same_mark', COFFEE_V3_CONTRACT,
]);
const PRIVATE_ENGLISH_WORDS = [
  'cup', 'saucer', 'residue', 'grounds', 'rim', 'handle', 'sighting', 'stroke', 'smear', 'blob', 'outline',
  'geometry', 'silhouette',
];
/**
 * Turkish private nouns (folded). `vowelStem` is the consonant-mutated stem
 * used before a vowel-initial suffix (tabak → tabağı, kulp → kulbu); when it
 * is set, the plain stem only takes consonant-initial suffixes, which keeps
 * "tabaka" (layer) out. kulp also keeps its colloquial unmutated vowel forms.
 */
const PRIVATE_TURKISH_NOUNS: ReadonlyArray<{ stem: string; vowelStem?: string; plainVowelSuffixes?: boolean }> = [
  { stem: 'fincan' },
  { stem: 'telve' },
  { stem: 'kulp', vowelStem: 'kulb', plainVowelSuffixes: true },
  { stem: 'tabak', vowelStem: 'tabag' },
];
/** Bounded nominal suffix chain on folded text: plural? possessive? case/-ki? copula? */
const TURKISH_NOMINAL_SUFFIX =
  /^(l[ae]r)?([iu]|s[iu]|[iu]m|[iu]n|[iu]m[iu]z|[iu]n[iu]z|l[ae]r[iu])?([ny]?[iu]n|[nsy]?[iu]|[ny]?[ae]|n?[dt][ae]|n?[dt][ae]n|y?l[ae]|n?[dt][ae]ki|ki)?([dt][iu]r)?$/;
const VOWEL = /^[aeiou]/;

function foldPrivacy(value: string): string {
  return value
    .normalize('NFC')
    .toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i')
    .replace(/ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/ş/g, 's')
    .replace(/ö/g, 'o')
    .replace(/ç/g, 'c')
    .replace(/[âà]/g, 'a')
    .replace(/[îì]/g, 'i')
    .replace(/[ûù]/g, 'u');
}

function privateTurkishNoun(token: string): boolean {
  return PRIVATE_TURKISH_NOUNS.some(({ stem, vowelStem, plainVowelSuffixes }) => {
    if (token.startsWith(stem)) {
      const rest = token.slice(stem.length);
      if (vowelStem && !plainVowelSuffixes && VOWEL.test(rest)) return false;
      return TURKISH_NOMINAL_SUFFIX.test(rest);
    }
    if (vowelStem && token.startsWith(vowelStem)) {
      const rest = token.slice(vowelStem.length);
      return VOWEL.test(rest) && TURKISH_NOMINAL_SUFFIX.test(rest);
    }
    return false;
  });
}

function privateValueToken(token: string): boolean {
  if (PRIVATE_ENUM_TOKENS.has(token)) return true;
  if (PRIVATE_ENGLISH_WORDS.some((word) => token === word || token === `${word}s` || token === `${word}es`)) return true;
  return privateTurkishNoun(token);
}

/**
 * The ONE structural key that may carry user-provided text (M1.2). It is the
 * user's own words, not observer output, so its content is not scanned for
 * visual tokens; it must still be a plain string.
 */
const USER_PROVIDED_TEXT_KEY = 'userDeclaredIntention';

/** Every path at which a raw V3 visual field or token would cross a meaning-only boundary. */
export function coffeeV3PrivacyViolations(value: unknown, path = '$'): string[] {
  if (typeof value === 'string') {
    const tokens = foldPrivacy(value).match(/[\p{L}\p{N}_]+/gu) ?? [];
    return tokens.filter(privateValueToken).map((t) => `${path}~${t}`);
  }
  if (Array.isArray(value)) return value.flatMap((item, index) => coffeeV3PrivacyViolations(item, `${path}[${index}]`));
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([key, item]) => {
      if (key === USER_PROVIDED_TEXT_KEY) return typeof item === 'string' ? [] : [`${path}.${key}`];
      return [
        ...(PRIVATE_KEYS.has(key) ? [`${path}.${key}`] : []),
        ...coffeeV3PrivacyViolations(item, `${path}.${key}`),
      ];
    });
  }
  return [];
}

/** Throws when anything raw/visual would cross the meaning-only boundary. V3-only; not applied to V2. */
export function assertCoffeeV3MeaningOnly(value: unknown): void {
  const violations = coffeeV3PrivacyViolations(value);
  if (violations.length > 0) {
    throw new Error(`coffee_v3_private_field_leak: ${violations.slice(0, 8).join(', ')}`);
  }
}
