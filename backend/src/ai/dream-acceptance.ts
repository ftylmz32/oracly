import type { DreamHistoryItem } from './dream-history.js';
import { dreamHistoryClaimViolation, type DreamHistoryClaimFailure } from './dream-history-quality.js';
import {
  evaluateDreamPremiumQuality,
  type DreamPremiumFailure,
  type DreamPremiumInput,
} from './dream-premium-quality.js';
import { evaluateDreamQuality, type DreamQualityFailure } from './dream-quality.js';
import { groundDreamSymbols, leakedSymbol } from './dream-symbol-grounding.js';
import type { DreamData } from './parse-provider.js';

export type DreamAcceptanceInput = DreamPremiumInput & {
  history?: DreamHistoryItem[];
};

export type DreamAcceptanceFailure =
  | DreamQualityFailure
  | DreamHistoryClaimFailure
  | DreamPremiumFailure;

export type DreamAcceptance =
  | { data: DreamData; failure: null }
  | { data: null; failure: DreamAcceptanceFailure };

/**
 * Post-safety acceptance, in fixed order: provider symbols filtered to the
 * strictly grounded items (a removed item named in prose → invented_symbol)
 * → Phase 2 grounding → Phase 4A saved-history attribution → Phase 4B
 * premium narrative, all on the sanitized body. The first failure wins; the
 * reason is internal (the route only ever says invalid_response). Only the
 * sanitized body is ever returned.
 */
export function acceptDreamData(raw: DreamData, input: DreamAcceptanceInput): DreamAcceptance {
  const { data, removed } = groundDreamSymbols(raw, input);
  const { narrative, language } = input;
  const failure =
    (leakedSymbol(removed, data, input) ? 'invented_symbol' : null) ??
    evaluateDreamQuality(data, input) ??
    dreamHistoryClaimViolation(data, { narrative, history: input.history, language }) ??
    evaluateDreamPremiumQuality(data, input);
  return failure ? { data: null, failure } : { data, failure: null };
}

export function dreamAcceptanceFailure(
  data: DreamData,
  input: DreamAcceptanceInput,
): DreamAcceptanceFailure | null {
  return acceptDreamData(data, input).failure;
}
