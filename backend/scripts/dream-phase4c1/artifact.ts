/**
 * Dream Phase 4C.1 — builds the offline reclassification artifact from the
 * frozen Phase 4C live run (read-only). Writes ONLY the new 4C.1 file:
 *
 *   npx tsx scripts/dream-phase4c1/artifact.ts
 *
 * The client columns join the Flutter 4C.1 client replay when present
 * (`PHASE4C1_WRITE_CLIENT=1 flutter test test/features/dream/dream_phase4c1_client_replay_test.dart`).
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PHASE4C_ARTIFACT_PATH, PHASE4C_CLIENT_REPLAY_PATH } from '../dream-phase4c/analyze.js';
import { PHASE4C1_SCHEMA, reclassifyRun, sha256, summarize, type FrozenRecord } from './reclassify.js';

const doc = (name: string) => fileURLToPath(new URL(`../../../docs/product/dream/evals/${name}`, import.meta.url));
export const PHASE4C1_ARTIFACT_PATH = doc('DREAM_PHASE4C1_OFFLINE_RECLASSIFICATION_20260928.json');
export const PHASE4C1_CLIENT_REPLAY_PATH = doc('DREAM_PHASE4C1_CLIENT_REPLAY_20260928.json');

type ReplayRow = { runId: string; clientResult: string };

function clientResults(path: string, key: 'replays'): Map<string, string> | null {
  if (!existsSync(path)) return null;
  const rows = JSON.parse(readFileSync(path, 'utf8'))[key] as ReplayRow[];
  return new Map(rows.map((r) => [r.runId, r.clientResult]));
}

export function buildReclassification() {
  const frozenText = readFileSync(PHASE4C_ARTIFACT_PATH, 'utf8');
  const replayText = readFileSync(PHASE4C_CLIENT_REPLAY_PATH, 'utf8');
  const runs = JSON.parse(frozenText).runs as FrozenRecord[];
  const client = {
    old: clientResults(PHASE4C_CLIENT_REPLAY_PATH, 'replays') ?? new Map<string, string>(),
    next: clientResults(PHASE4C1_CLIENT_REPLAY_PATH, 'replays'),
  };
  const rows = runs.map((r) => reclassifyRun(r, client));
  return {
    schema: PHASE4C1_SCHEMA,
    source: {
      artifact: basename(PHASE4C_ARTIFACT_PATH),
      artifactSha256: sha256(frozenText),
      clientReplay: basename(PHASE4C_CLIENT_REPLAY_PATH),
      clientReplaySha256: sha256(replayText),
      rawProviderTextSha256: sha256(runs.map((r) => r.rawProviderText ?? '').join('\u0000')),
    },
    method: {
      providerCalls: 0,
      pipeline: 'parse → output safety (raw body, raw symbols) → symbol filtering + prose leak → Phase 2 → Phase 4A → Phase 4B (sanitized body)',
      historyOld: 'frozen 4C diagnostic Phase 4A verdict',
      historyNew: 'Phase 4A on the sanitized body, evaluated independently',
      emotionOld: 'emotion_contradiction when the frozen 4C diagnostic Phase 4B verdict was emotion_contradiction, else NOT_FLAGGED',
      emotionNew: 'per-section contradiction (emotionalTheme, summary) on the sanitized body',
      clientOld: 'frozen 4C client replay for old backend PASS runs; NOT_DELIVERED otherwise',
      clientNew: 'Phase 4C.1 client replay of the sanitized body for new backend PASS runs; NOT_DELIVERED otherwise',
      changeReason: 'the 4C.1 fix that removed the old first failure; unchanged when the verdict and first failure are the same',
      important:
        'The new pass count is not proof of writer quality: every body came from the old 4b gpt-4o prompt. ' +
        'It only shows which rejections were gate false positives. No target pass rate was set.',
    },
    summary: summarize(rows),
    runs: rows,
  };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const frozen = new Set([PHASE4C_ARTIFACT_PATH, PHASE4C_CLIENT_REPLAY_PATH]);
  if (frozen.has(PHASE4C1_ARTIFACT_PATH)) throw new Error('refusing to write a frozen Phase 4C file');
  const next = buildReclassification();
  writeFileSync(PHASE4C1_ARTIFACT_PATH, `${JSON.stringify(next, null, 2)}\n`);
  console.log(`reclassified runs=${next.runs.length} newPass=${next.summary.newOfflineBackendPass}`);
}
