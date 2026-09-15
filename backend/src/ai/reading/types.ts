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
