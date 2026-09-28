/**
 * Dream Phase 4C.2 — the shape of one attempt's evidence record. Never
 * carries headers, key material or identity.
 */
import type { DreamData } from '../../src/ai/parse-provider.js';
import type { CandidateId } from './candidates.js';
import type { Phase4c2Attempt } from './matrix.js';
import type { Phase4c2Stages } from './stages.js';

export type WireFacts = { bodyKeys: string[]; serviceTier: string | null };
export type BackendFinal = 'PASS' | 'REJECT' | 'TRANSPORT_ERROR' | 'PARAMETER_ERROR';
export const PENDING_REVIEW = 'PENDING_INDEPENDENT_REVIEW' as const;

export type Phase4c2Record = Omit<Phase4c2Attempt, 'payload' | 'candidate'> & {
  candidateModel: CandidateId;
  requestedModel: string;
  resolvedModel: string | null;
  endpoint: string;
  writerRevision: string;
  parameters: {
    reasoningEffort: unknown;
    temperaturePresent: boolean;
    temperature: unknown;
    topPPresent: boolean;
    logprobsPresent: boolean;
    topLogprobsPresent: boolean;
    responseFormat: unknown;
    bodyKeys: string[];
  };
  providerCallOccurred: true;
  latencyMs: number;
  httpStatus: number | null;
  httpClass: string;
  finishReason: string | null;
  serviceTier: string | null;
  usage: {
    inputTokens: number | null;
    outputTokens: number | null;
    reasoningTokens: number | null;
    cachedTokens: number | null;
    cacheWriteTokens: number | null;
    raw: Record<string, unknown> | null;
  };
  estimatedCostUsd: number | null;
  costNullReason: string | null;
  narrative: string;
  symbolsSent: unknown;
  emotionsSent: unknown;
  memorySummarySent: string | null;
  history: unknown;
  rawProviderText: string | null;
  parseSuccess: boolean;
  parsed: DreamData | null;
  rawSymbols: string[];
  filteredSymbols: string[];
  outputSafety: string;
  symbolFilter: string;
  phase2: string;
  phase4A: string;
  phase4B: string;
  firstFailure: string | null;
  failureStage: string | null;
  diagnostic: Phase4c2Stages['diagnostic'];
  backendFinal: BackendFinal;
  errorCode: string | null;
  providerErrorMessage: string | null;
  productionAgreement: boolean;
  clientResult: string | null;
  clientFailureReason: string | null;
  inventedConcreteSceneContent: typeof PENDING_REVIEW;
  inventedConcreteSceneItems: string[];
};
