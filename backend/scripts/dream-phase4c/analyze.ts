/**
 * Dream Phase 4C — offline analysis of the captured live artifact (no
 * provider call). Joins the Flutter client replay onto each run and writes
 * deterministic mechanical observations back into the artifact.
 *
 *   npx tsx scripts/dream-phase4c/analyze.ts
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { validatePhase4cArtifact, type Phase4cArtifact } from './artifact.js';
import { BOILERPLATE_MIN_DREAMS, boilerplate, distributions, repeatPairs } from './observe-corpus.js';
import { observeReading, ROLE_SIMILARITY_FLAG } from './observe-reading.js';
import { gateTriggers } from './observe-triggers.js';

const doc = (name: string) => fileURLToPath(new URL(`../../../docs/product/dream/evals/${name}`, import.meta.url));
export const PHASE4C_ARTIFACT_PATH = doc('DREAM_PHASE4C_LIVE_RUN_20260928.json');
export const PHASE4C_CLIENT_REPLAY_PATH = doc('DREAM_PHASE4C_CLIENT_REPLAY_20260928.json');

type Replay = { runId: string; clientResult: string; clientGap?: string; fields?: Record<string, { layer: string | null; rewrite: string }> };

type Replays = { replays: Replay[]; diagnosticRejectedReplays: Replay[] };

function layerCounts(rows: Replay[]) {
  const counts: Record<string, number> = {};
  for (const r of rows) for (const f of Object.values(r.fields ?? {})) if (f.layer) counts[f.layer] = (counts[f.layer] ?? 0) + 1;
  return counts;
}

export function computeObservations(artifact: Phase4cArtifact, all: Replays) {
  const replays = all.replays;
  const client = new Map(replays.map((r) => [r.runId, r]));
  const rejected = all.diagnosticRejectedReplays;
  const obs = new Map(artifact.runs.map((r) => [r.runId, observeReading(r)]));
  const passes = artifact.runs.filter((r) => r.backendFinal === 'PASS');
  const clientFails = passes.flatMap((r) => {
    const c = client.get(r.runId);
    if (!c || c.clientResult === 'PASS') return [];
    const layers = Object.entries(c.fields ?? {}).filter(([, f]) => f.layer).map(([field, f]) => ({ field, layer: f.layer }));
    return [{ runId: r.runId, clientResult: c.clientResult, clientGap: c.clientGap ?? null, layers }];
  });
  const rewrites = replays.flatMap((c) =>
    Object.entries(c.fields ?? {}).map(([field, f]) => ({ runId: c.runId, field, rewrite: f.rewrite })));
  return {
    method: {
      boilerplateMinDreams: BOILERPLATE_MIN_DREAMS,
      roleSimilarityFlag: ROLE_SIMILARITY_FLAG,
      note: 'Mechanical string facts only. Semantic quality verdict: PENDING INDEPENDENT REVIEW.',
    },
    distributions: distributions(artifact.runs, obs),
    gateTriggers: gateTriggers(artifact.runs),
    perReading: [...obs.values()],
    boilerplate: Object.fromEntries(['tr', 'en', 'ru'].map((l) => [l, boilerplate(artifact.runs, l)])),
    repeats: repeatPairs(artifact.runs, obs, client),
    client: {
      backendPass: passes.length,
      replayed: replays.length,
      backendPassClientFail: clientFails,
      rewrites: rewrites.reduce<Record<string, number>>((m, x) => ({ ...m, [x.rewrite]: (m[x.rewrite] ?? 0) + 1 }), {}),
      changedFields: rewrites.filter((x) => x.rewrite !== 'unchanged'),
      diagnosticBackendRejects: {
        note: 'Bodies the backend refused never reach a client; replayed only to locate guard disagreement.',
        replayed: rejected.length,
        clientResult: rejected.reduce<Record<string, number>>((m, r) => ({ ...m, [r.clientResult]: (m[r.clientResult] ?? 0) + 1 }), {}),
        backendRejectClientPass: rejected.filter((r) => r.clientResult === 'PASS').map((r) => {
          const run = artifact.runs.find((x) => x.runId === r.runId)!;
          return { runId: r.runId, backendDiagnostic: run.stages?.diagnostic ?? null };
        }),
        clientLayers: layerCounts(rejected),
      },
    },
  };
}

export function loadReplays(): Replays {
  if (!existsSync(PHASE4C_CLIENT_REPLAY_PATH)) return { replays: [], diagnosticRejectedReplays: [] };
  const file = JSON.parse(readFileSync(PHASE4C_CLIENT_REPLAY_PATH, 'utf8'));
  return { replays: file.replays, diagnosticRejectedReplays: file.diagnosticRejectedReplays ?? [] };
}

export function withAnalysis(artifact: Phase4cArtifact, all: Replays): Phase4cArtifact {
  const client = new Map(all.replays.map((r) => [r.runId, r]));
  const runs = artifact.runs.map((r) => ({ ...r, client: client.get(r.runId) ?? null }));
  const { observations: _o, ...rest } = artifact;
  return { ...rest, runs, observations: computeObservations({ ...rest, runs }, all) };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const artifact = JSON.parse(readFileSync(PHASE4C_ARTIFACT_PATH, 'utf8')) as Phase4cArtifact;
  const next = withAnalysis(artifact, loadReplays());
  const errors = validatePhase4cArtifact(next);
  if (errors.length) throw new Error(`schema: ${errors.join('; ')}`);
  writeFileSync(PHASE4C_ARTIFACT_PATH, `${JSON.stringify(next, null, 2)}\n`);
  console.log(`analyzed runs=${next.runs.length} replays=${loadReplays().replays.length}`);
}
