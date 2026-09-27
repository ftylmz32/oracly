import type { DreamHistoryItem } from './dream-history.js';
import { dreamHistoryClaimViolation, type DreamHistoryClaimFailure } from './dream-history-quality.js';
import {
  evaluateDreamPremiumQuality,
  type DreamPremiumFailure,
  type DreamPremiumInput,
} from './dream-premium-quality.js';
import { evaluateDreamQuality, type DreamQualityFailure } from './dream-quality.js';
import type { DreamData } from './parse-provider.js';

export type DreamAcceptanceInput = DreamPremiumInput & {
  history?: DreamHistoryItem[];
};

export type DreamAcceptanceFailure =
  | DreamQualityFailure
  | DreamHistoryClaimFailure
  | DreamPremiumFailure;

/**
 * Post-safety acceptance, in fixed order: Phase 2 grounding → Phase 4A
 * saved-history attribution → Phase 4B premium narrative. The first failure
 * wins; the reason is internal (the route only ever says invalid_response).
 */
export function dreamAcceptanceFailure(
  data: DreamData,
  input: DreamAcceptanceInput,
): DreamAcceptanceFailure | null {
  const { narrative, language } = input;
  return (
    evaluateDreamQuality(data, input) ??
    dreamHistoryClaimViolation(data, { narrative, history: input.history, language }) ??
    evaluateDreamPremiumQuality(data, input)
  );
}
