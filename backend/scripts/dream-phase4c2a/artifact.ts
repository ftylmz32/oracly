/**
 * Dream Phase 4C.2a — builds the offline reclassification of the 27
 * immutable Phase 4C.2 live outputs (read-only; no provider call). Writes
 * ONLY the new 4C.2a file:
 *
 *   npx tsx scripts/dream-phase4c2a/artifact.ts
 *
 * The client columns join the Flutter 4C.2a replay when present
 * (`PHASE4C2A_WRITE_CLIENT=1 flutter test test/features/dream/dream_phase4c2a_client_replay_test.dart`).
 */
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { FROZEN_EVIDENCE, PHASE4C2_ARTIFACT_PATH, PHASE4C2_CLIENT_REPLAY_PATH } from '../dream-phase4c2/artifact.js';
import { buildPhase4c2Matrix, loadPhase4c2Requests } from '../dream-phase4c2/matrix.js';
import type { Phase4c2Record } from '../dream-phase4c2/record.js';
import { PHASE4C2A_SCHEMA, reclassifyAttempt, summarize, type ClientVerdict } from './reclassify.js';

const doc = (name: string) => fileURLToPath(new URL(`../../../docs/product/dream/evals/${name}`, import.meta.url));
export const PHASE4C2A_ARTIFACT_PATH = doc('DREAM_PHASE4C2A_OFFLINE_RECLASSIFICATION_20260928.json');
export const PHASE4C2A_CLIENT_REPLAY_PATH = doc('DREAM_PHASE4C2A_CLIENT_REPLAY_20260928.json');

export const sha256 = (text: string) => createHash('sha256').update(text, 'utf8').digest('hex');

function clientVerdicts(): Map<string, ClientVerdict> | null {
  if (!existsSync(PHASE4C2A_CLIENT_REPLAY_PATH)) return null;
  const rows = JSON.parse(readFileSync(PHASE4C2A_CLIENT_REPLAY_PATH, 'utf8')).replays as Array<ClientVerdict & { runId: string }>;
  return new Map(rows.map((r) => [r.runId, { clientResult: r.clientResult, clientGap: r.clientGap ?? null }]));
}

export function buildPhase4c2aReclassification() {
  const frozenText = readFileSync(PHASE4C2_ARTIFACT_PATH, 'utf8');
  const replayText = readFileSync(PHASE4C2_CLIENT_REPLAY_PATH, 'utf8');
  const records = JSON.parse(frozenText).attempts as Phase4c2Record[];
  const matrix = buildPhase4c2Matrix(loadPhase4c2Requests());
  const client = clientVerdicts();
  const rows = records.map((r, i) => reclassifyAttempt(r, matrix[i]!, client));
  return {
    schema: PHASE4C2A_SCHEMA,
    source: {
      artifact: basename(PHASE4C2_ARTIFACT_PATH),
      artifactSha256: sha256(frozenText),
      clientReplay: basename(PHASE4C2_CLIENT_REPLAY_PATH),
      clientReplaySha256: sha256(replayText),
      rawProviderTextSha256: sha256(records.map((r) => r.rawProviderText ?? '').join('\u0000')),
    },
    method: {
      providerCalls: 0,
      writerRevision: '4c1 (unchanged)',
      productionModelChanged: false,
      pipeline: 'parse → output safety (raw body) → symbol filtering + prose leak → Phase 2 → Phase 4A → Phase 4B (sanitized body) → client offline delivery',
      old: 'the frozen 4C.2 backend verdict and client replay',
      newClient: 'Phase 4C.2a client replay (source-aware Dream guard) of the sanitized body for new backend PASS attempts; NOT_DELIVERED otherwise',
      changeReason: 'the 4C.2a fix owning the old first failure; provider_ai_style_guard when only the client verdict moved; unchanged otherwise',
      important:
        'Counts are gate outcomes, not the semantic ranking. The model choice rests on the independent semantic review ' +
        '(DREAM_PHASE4C2_INDEPENDENT_REVIEW_20260928.json). No target pass count was set.',
    },
    summary: summarize(rows),
    attempts: rows,
  };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const frozen = new Set([PHASE4C2_ARTIFACT_PATH, PHASE4C2_CLIENT_REPLAY_PATH, ...FROZEN_EVIDENCE]);
  if (frozen.has(PHASE4C2A_ARTIFACT_PATH)) throw new Error('refusing to write a frozen file');
  const next = buildPhase4c2aReclassification();
  writeFileSync(PHASE4C2A_ARTIFACT_PATH, `${JSON.stringify(next, null, 2)}\n`);
  console.log(`reclassified attempts=${next.attempts.length} changed=${next.summary.changed}`);
}
