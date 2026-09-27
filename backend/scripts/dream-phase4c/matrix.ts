/**
 * Dream Phase 4C — the 36-run live matrix: 24 unique synthetic cases
 * (8 per language, one per category) plus 12 repeats (4 per language).
 * Payloads are the production client's own requests
 * (`test/features/dream/dream_phase4c_payload_test.dart`).
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export const PHASE4C_MAX_CALLS = 36;
export const PHASE4C_LANGUAGES = ['tr', 'en', 'ru'] as const;
export const PHASE4C_CATEGORIES = [
  'rich_negated_fear',
  'rich_mixed_emotion',
  'sparse_single_image',
  'surreal_absurd',
  'life_domain_supported',
  'no_domain_hallucination_temptation',
  'safe_connected_memory',
  'prior_dream_history',
] as const;

export type Phase4cClientRequest = {
  id: string;
  language: string;
  category: string;
  memorySource: string;
  model: string;
  payload: Record<string, unknown>;
};

export type Phase4cRun = {
  runId: string;
  caseId: string;
  language: string;
  category: string;
  repeatOf: string | null;
  attempt: 1 | 2;
  /** Distinct per attempt; the semantic payload is identical. */
  attemptKey: string;
  memorySource: string;
  clientModelHint: string;
  payload: Record<string, unknown>;
};

const fixture = (name: string) =>
  fileURLToPath(new URL(`../../tests/fixtures/${name}`, import.meta.url));

export function loadPhase4cInputs(): { repeats: string[]; requests: Phase4cClientRequest[] } {
  const corpus = JSON.parse(readFileSync(fixture('dream-phase4c-corpus.json'), 'utf8'));
  const payloads = JSON.parse(readFileSync(fixture('dream-phase4c-payloads.json'), 'utf8'));
  return { repeats: corpus.repeats, requests: payloads.requests };
}

function run(r: Phase4cClientRequest, attempt: 1 | 2): Phase4cRun {
  return {
    runId: attempt === 1 ? r.id : `${r.id}#r2`,
    caseId: r.id,
    language: r.language,
    category: r.category,
    repeatOf: attempt === 1 ? null : r.id,
    attempt,
    attemptKey: `qa-dream-4c-${r.id}-a${attempt}`,
    memorySource: r.memorySource,
    clientModelHint: r.model,
    payload: r.payload,
  };
}

/** Unique runs first, then repeats; throws on any matrix shape drift. */
export function buildPhase4cMatrix(
  requests: Phase4cClientRequest[],
  repeats: string[],
): Phase4cRun[] {
  const byId = new Map(requests.map((r) => [r.id, r]));
  if (byId.size !== 24 || requests.length !== 24) throw new Error('matrix: expected 24 unique cases');
  for (const language of PHASE4C_LANGUAGES) {
    const cats = requests.filter((r) => r.language === language).map((r) => r.category);
    const complete = PHASE4C_CATEGORIES.every((c) => cats.filter((x) => x === c).length === 1);
    if (cats.length !== 8 || !complete) throw new Error(`matrix: ${language} categories incomplete`);
    const reps = repeats.filter((id) => byId.get(id)?.language === language);
    if (reps.length !== 4) throw new Error(`matrix: ${language} needs 4 repeats`);
  }
  if (new Set(repeats).size !== 12 || repeats.some((id) => !byId.has(id))) {
    throw new Error('matrix: repeats must be 12 distinct known cases');
  }
  const runs = [
    ...requests.map((r) => run(r, 1)),
    ...repeats.map((id) => run(byId.get(id)!, 2)),
  ];
  if (runs.length !== PHASE4C_MAX_CALLS) throw new Error('matrix: expected 36 runs');
  return runs;
}
