/** Shared evidence types for the production Coffee/Palm two-stage reading. */

export type EvidenceConfidence = 'high' | 'medium' | 'low';

export type VisibilityState = 'clear' | 'partial' | 'uncertain';

export type ReadingEvidenceItem = {
  id: string;
  region: string;
  description: string;
  confidence: EvidenceConfidence;
  visibility: VisibilityState;
  /** Optional cautious resemblance only — never asserted as fact. */
  resemblance?: string | null;
};

export type CoffeeObservation = {
  usable: boolean;
  reason?: string;
  checks: {
    cupInteriorVisible: boolean;
    adequateFocusLight: boolean;
    residueVisible: boolean;
    milkFoamObstruction: boolean;
    usefulRegionsVisible: boolean;
  };
  evidence: ReadingEvidenceItem[];
};

/**
 * Coffee V2 (three-photo reading) — additive, dedicated observation
 * contract. Never used by legacy single-image Coffee, which keeps
 * `CoffeeObservation` above unchanged. One observation covers all three
 * photos of the SAME cup/saucer, not three separate observations.
 */
export type CoffeeV2SourceSlot = 'cup_primary' | 'cup_secondary' | 'saucer';

export function isCoffeeV2SourceSlot(value: unknown): value is CoffeeV2SourceSlot {
  return value === 'cup_primary' || value === 'cup_secondary' || value === 'saucer';
}

export type CoffeeV2CupPhotoChecks = {
  cupInteriorVisible: boolean;
  adequateFocusLight: boolean;
  residueVisible: boolean;
  usefulRegionsVisible: boolean;
};

export type CoffeeV2SaucerPhotoChecks = {
  saucerVisible: boolean;
  adequateFocusLight: boolean;
  residueOrFlowVisible: boolean;
  usefulRegionsVisible: boolean;
};

/** Every V2 evidence item carries which of the three photos it came from. */
export type CoffeeV2EvidenceItem = ReadingEvidenceItem & {
  sourceSlot: CoffeeV2SourceSlot;
};

export type CoffeeV2Observation = {
  usable: boolean;
  reason?: string;
  photoChecks: {
    cupPrimary: CoffeeV2CupPhotoChecks;
    cupSecondary: CoffeeV2CupPhotoChecks;
    saucer: CoffeeV2SaucerPhotoChecks;
  };
  evidence: CoffeeV2EvidenceItem[];
};

export type PalmObservation = {
  usable: boolean;
  reason?: string;
  checks: {
    onePalmFacing: boolean;
    majorLinesVisible: boolean;
    adequateFocusLight: boolean;
    overlapOcclusion: boolean;
    dorsal: boolean;
  };
  evidence: ReadingEvidenceItem[];
};

export type NarrativeSection = {
  text: string;
  evidenceIds: string[];
};

export type CoffeeNarrative = {
  visualObservation: NarrativeSection;
  overall: NarrativeSection;
  love: NarrativeSection;
  career: NarrativeSection;
  money: NarrativeSection;
  nearFuture: NarrativeSection;
  takeaway: NarrativeSection;
};

export type PalmNarrative = {
  visualObservation: NarrativeSection;
  overall: NarrativeSection;
  lifeLine: NarrativeSection;
  headLine: NarrativeSection;
  heartLine: NarrativeSection;
  fateLine: NarrativeSection;
  takeaway: NarrativeSection;
};

export type StageKind = 'observer' | 'writer' | 'repair';

/**
 * BATCH 3A.1 — small, bounded, optional personalization context. Every
 * field is optional and independently omittable; a reading must remain
 * fully valid with none of them present. Never a raw Journal dump — just
 * short, pre-summarized signals the client already trusts.
 */
export type ReadingPersonalization = {
  /** First name only — never a full name, never repeated mechanically. */
  firstName?: string;
  /** The user's current stated question/intention for this reading. */
  intention?: string;
  /** A few short recurring theme labels (e.g. "career change", "iş değişikliği") — never raw diary text. */
  relevantThemes?: string[];
  /** One short, pre-summarized sentence of genuinely relevant continuity — never a raw memory/journal dump. */
  memorySummary?: string;
};

/**
 * Coffee Observer V3 — multi-view physical mark map. ADDITIVE AND DARK: no
 * live dispatch, slot, route or worker produces or consumes this contract
 * yet. Machine-only observation; never sent to a writer or a user.
 */
export const COFFEE_V3_CONTRACT = 'multi_view_marks_v3' as const;

/**
 * The live three-photo capture: two genuine views of the SAME cup interior
 * (the second turned roughly half a circle), then the saucer. Geometry is
 * anchored per frame by the handle clock, so it never assumes a turn angle.
 */
export const COFFEE_V3_SLOTS = ['cup_view_a', 'cup_view_b', 'saucer'] as const;
export type CoffeeV3LiveSlot = (typeof COFFEE_V3_SLOTS)[number];

/**
 * Retired four-view vocabulary. Never requested, never sent to the observer;
 * kept (under its historical type name `CoffeeV3Slot`) only so the
 * deterministic map still reads the frozen M1/V3G1 fixtures unchanged. The
 * map is slot-name agnostic: geometry comes from frame-local handle/rim clocks.
 */
export const COFFEE_V3_RETIRED_FOUR_VIEW_SLOTS = ['cup_handle_far', 'cup_turn_a', 'cup_turn_b', 'saucer'] as const;
export type CoffeeV3Slot = (typeof COFFEE_V3_RETIRED_FOUR_VIEW_SLOTS)[number];

/** Every slot name the map accepts, in canonical tie-break order (cups first, saucer last). */
export const COFFEE_V3_MAP_SLOTS = ['cup_handle_far', 'cup_turn_a', 'cup_turn_b', 'cup_view_a', 'cup_view_b', 'saucer'] as const;
export type CoffeeV3MapSlot = (typeof COFFEE_V3_MAP_SLOTS)[number];

export type CoffeeV3Surface = 'cup_wall' | 'cup_base' | 'saucer';
export type CoffeeV3Band = 'rim_upper' | 'middle' | 'lower_base' | 'unknown';
/** A known cup band (V3G1 band coverage never contains `unknown`). */
export type CoffeeV3CupBand = Exclude<CoffeeV3Band, 'unknown'>;
/**
 * V3G1 — what a physical mark IS. `clear_area` is a positive observed empty
 * space free of residue (never an absence inferred from missing data); it
 * never carries a resemblance. Missing = residue (pre-V3G1 observations).
 */
export type CoffeeV3MarkKind = 'residue' | 'clear_area';
/**
 * V3G1 — physical topology of a residue mark: line (a line, trail or band),
 * closed_loop (a closed loop of residue), pool (a filled pool), patch (a blob
 * or patch), unknown. Missing = unknown. Never derived from a resemblance.
 */
export type CoffeeV3Topology = 'line' | 'closed_loop' | 'pool' | 'patch' | 'unknown';
export type CoffeeV3HandleRelation = 'handle_near' | 'handle_opposite' | 'neutral' | 'unknown';
export type CoffeeV3SaucerZone = 'center' | 'middle_ring' | 'edge' | 'unknown';

export type CoffeeV3View = {
  slot: CoffeeV3MapSlot;
  /** Cup interior (cup slots) or the saucer itself (saucer slot) is visible. */
  surfaceVisible: boolean;
  focusLightAdequate: boolean;
  residueVisible: boolean;
  /** Cup slots only; null for the saucer. */
  handleVisible: boolean | null;
  /** 1–12: where the handle sits on the rim in THIS frame (12 = top of frame). */
  handleClock: number | null;
};

/** One appearance of a physical mark in one photograph. */
export type CoffeeV3Sighting = {
  id: string;
  slot: CoffeeV3MapSlot;
  surface: CoffeeV3Surface;
  band: CoffeeV3Band;
  /** 1–12: position along the rim in THIS frame; null when not placeable (saucer). */
  rimClock: number | null;
  /** Saucer sightings only; null on the cup. */
  saucerZone: CoffeeV3SaucerZone | null;
  /**
   * V3G1 — every cup band this photo shows the mark crossing. Cup only;
   * must include `band` when that is known; [] or missing = not stated.
   */
  bandCoverage?: CoffeeV3CupBand[];
  /** Literal visual description. Private. */
  description: string;
  visibility: VisibilityState;
  confidence: EvidenceConfidence;
};

export type CoffeeV3Form = {
  motion: 'moving' | 'still' | 'unknown';
  verticalDirection: 'rising' | 'descending' | 'level' | 'unknown';
  openness: 'open' | 'closed' | 'unknown';
  course: 'straight' | 'bending' | 'branching' | 'unknown';
  posture: 'upright' | 'tilted' | 'unknown';
  continuity: 'continuous' | 'broken' | 'unknown';
  grouping: 'isolated' | 'clustered' | 'unknown';
};

export type CoffeeV3Resemblance = { label: string; strength: 'strong' | 'weak' };

/** One PHYSICAL residue mark; `sightingIds` are the photos the observer is certain show it. */
export type CoffeeV3Mark = {
  id: string;
  surface: CoffeeV3Surface;
  /** V3G1; missing = residue. */
  kind?: CoffeeV3MarkKind;
  /** V3G1; missing = unknown. A clear area's topology is always unknown. */
  topology?: CoffeeV3Topology;
  sightingIds: string[];
  form: CoffeeV3Form;
  /** 0–2 cautious candidates; empty is a valid, common answer. */
  resemblances: CoffeeV3Resemblance[];
};

export type CoffeeV3RelationKind =
  | 'near'
  | 'touching'
  | 'connected'
  | 'crossing'
  | 'contained_by'
  | 'continuation_of'
  | 'separated';

/** Purely visual relation between two marks on the same surface family. */
export type CoffeeV3Relation = { a: string; b: string; kind: CoffeeV3RelationKind; confidence: EvidenceConfidence };

export type CoffeeV3Ambiguity = { marks: [string, string]; reason: 'possible_same_mark' };

export type CoffeeV3Saucer = {
  surfaceState: 'clean' | 'film' | 'islands' | 'flow' | 'unclear';
  flow: { present: boolean; direction: 'toward_center' | 'toward_edge' | 'around' | 'none' | 'unknown' };
};

export type CoffeeMultiViewObservationV3 = {
  contract: typeof COFFEE_V3_CONTRACT;
  usable: boolean;
  reason: string | null;
  views: CoffeeV3View[];
  sightings: CoffeeV3Sighting[];
  marks: CoffeeV3Mark[];
  relations: CoffeeV3Relation[];
  ambiguities: CoffeeV3Ambiguity[];
  saucer: CoffeeV3Saucer;
};
