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
