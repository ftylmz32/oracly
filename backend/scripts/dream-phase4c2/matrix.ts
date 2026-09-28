/**
 * Dream Phase 4C.2 — 9 cases × 3 candidates = 27 attempts, one real call
 * each, no retries. Candidate order rotates per case so no model always
 * runs first (case 1: 4o → sol → astra, case 2: sol → astra → 4o, …).
 * Payloads are the production client's own requests
 * (`test/features/dream/dream_phase4c2_payload_test.dart`).
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { CANDIDATES, type CandidateId } from './candidates.js';

export const PHASE4C2_MAX_CALLS = 27;
export const PHASE4C2_CASES = [
  'tr-negated-fear',
  'en-negated-fear',
  'ru-negated-fear',
  'en-mixed-emotion',
  'tr-domain-work',
  'ru-domain-family',
  'ru-memory',
  'en-history',
  'tr-history',
] as const;

export type Phase4c2Request = {
  id: string;
  language: string;
  category: string;
  memorySource: string;
  model: string;
  payload: Record<string, unknown>;
};

export type Phase4c2Attempt = {
  attemptId: string;
  order: number;
  caseIndex: number;
  positionInCase: number;
  caseId: string;
  language: string;
  category: string;
  memorySource: string;
  clientModelHint: string;
  candidate: CandidateId;
  payload: Record<string, unknown>;
};

export const PHASE4C2_PAYLOADS = fileURLToPath(
  new URL('../../tests/fixtures/dream-phase4c2-payloads.json', import.meta.url),
);

export function loadPhase4c2Requests(path = PHASE4C2_PAYLOADS): Phase4c2Request[] {
  return JSON.parse(readFileSync(path, 'utf8')).requests;
}

export function rotation(caseIndex: number): CandidateId[] {
  const ids = CANDIDATES.map((c) => c.id);
  const k = caseIndex % ids.length;
  return [...ids.slice(k), ...ids.slice(0, k)];
}

/** Case order is fixed by [PHASE4C2_CASES]; throws on any shape drift. */
export function buildPhase4c2Matrix(requests: Phase4c2Request[]): Phase4c2Attempt[] {
  const byId = new Map(requests.map((r) => [r.id, r]));
  if (requests.length !== PHASE4C2_CASES.length || PHASE4C2_CASES.some((id) => !byId.has(id))) {
    throw new Error('matrix: expected exactly the nine 4C.2 cases');
  }
  const attempts = PHASE4C2_CASES.flatMap((id, caseIndex) =>
    rotation(caseIndex).map((candidate, positionInCase) => {
      const r = byId.get(id)!;
      return {
        attemptId: `${id}::${candidate}`,
        order: caseIndex * CANDIDATES.length + positionInCase + 1,
        caseIndex,
        positionInCase,
        caseId: id,
        language: r.language,
        category: r.category,
        memorySource: r.memorySource,
        clientModelHint: r.model,
        candidate,
        payload: r.payload,
      };
    }),
  );
  if (attempts.length !== PHASE4C2_MAX_CALLS) throw new Error('matrix: expected 27 attempts');
  return attempts;
}
