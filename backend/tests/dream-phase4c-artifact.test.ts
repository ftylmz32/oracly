// Dream Phase 4C — the committed (frozen) live artifact, re-derived offline.
// No provider call is possible here: global fetch is stubbed to fail.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import { validatePhase4cArtifact, type Phase4cArtifact } from '../scripts/dream-phase4c/artifact.js';
import { loadReplays, PHASE4C_ARTIFACT_PATH, withAnalysis } from '../scripts/dream-phase4c/analyze.js';
import { buildPhase4cMatrix, loadPhase4cInputs } from '../scripts/dream-phase4c/matrix.js';
import { deployedOpenAiEnv } from '../scripts/dream-phase4c/production-config.js';
import { classifyDreamOutput } from '../scripts/dream-phase4c/stages.js';
import { PHASE4C1_ARTIFACT_PATH } from '../scripts/dream-phase4c1/artifact.js';

const text = readFileSync(PHASE4C_ARTIFACT_PATH, 'utf8');
const artifact = JSON.parse(text) as Phase4cArtifact;
const reclassified = JSON.parse(readFileSync(PHASE4C1_ARTIFACT_PATH, 'utf8')) as {
  runs: Array<{ runId: string; oldBackendFinal: string }>;
};

/** Observation fields computed by the (since remediated) gates. */
const GATE_DEPENDENT = [
  ['observations', 'gateTriggers'],
  ['observations', 'distributions', 'unsupportedDomainFlags'],
  ['observations', 'perReading', '0', 'emotionContradiction'],
  ['observations', 'perReading', '0', 'unsupportedDomain'],
  ['observations', 'perReading', '0', 'addressedDomain'],
  ['observations', 'repeats', '0', 'emotionsPreserved'],
  ['observations', 'repeats', '0', 'inventedDomain'],
];
type Json = Record<string, unknown>;
const pick = (o: unknown, path: string[]) => path.reduce<unknown>((v, k) => (v as Json | undefined)?.[k], o);

function stripGateDependent(a: unknown) {
  const copy = JSON.parse(JSON.stringify(a)) as { observations: Json };
  const obs = copy.observations;
  delete obs.gateTriggers;
  delete (obs.distributions as Json).unsupportedDomainFlags;
  for (const r of obs.perReading as Json[]) for (const k of ['emotionContradiction', 'unsupportedDomain', 'addressedDomain']) delete r[k];
  for (const r of obs.repeats as Json[]) for (const k of ['emotionsPreserved', 'inventedDomain']) delete r[k];
  return copy;
}
const { requests, repeats } = loadPhase4cInputs();
const matrix = new Map(buildPhase4cMatrix(requests, repeats).map((r) => [r.runId, r]));

beforeAll(() => {
  vi.stubGlobal('fetch', () => {
    throw new Error('no provider calls in regression');
  });
});
afterAll(() => vi.unstubAllGlobals());

describe('Phase 4C committed live artifact', () => {
  it('validates, spent at most 36 calls, one per run, no retries', () => {
    expect(validatePhase4cArtifact(artifact)).toEqual([]);
    expect(artifact.runs).toHaveLength(36);
    expect(artifact.budget).toEqual({ max: 36, used: 36, retries: 0, judgeCalls: 0 });
    expect(artifact.runs.every((r) => r.providerCallOccurred)).toBe(true);
    expect([...matrix.keys()].sort()).toEqual(artifact.runs.map((r) => r.runId).sort());
  });

  it('recorded the production Dream config', () => {
    const env = deployedOpenAiEnv();
    expect(artifact.config).toMatchObject({
      resolvedModel: env.OPENAI_MODEL,
      endpoint: `${env.OPENAI_BASE_URL}/chat/completions`,
      temperature: 0.6,
      reasoningEffort: null,
      responseFormat: { type: 'json_object' },
      transportRetries: 0,
    });
    for (const r of artifact.runs) expect(r.provider?.request.model).toBe(env.OPENAI_MODEL);
  });

  // Frozen since Phase 4C.1: the gates moved on, so the stored gate verdicts
  // are 4C-era evidence. Parse and output safety still re-derive exactly; the
  // 4C.1 verdicts live in the offline reclassification artifact.
  it('parse and output safety re-derive; gate verdicts match the reclassification old columns', () => {
    const old = new Map(reclassified.runs.map((r) => [r.runId, r]));
    for (const r of artifact.runs) {
      const run = matrix.get(r.runId)!;
      const validated = validateAiBody({ operation: 'dream_analysis', payload: run.payload, model: run.clientModelHint });
      if (validated.operation !== 'dream_analysis') throw new Error('operation');
      const now = classifyDreamOutput(r.rawProviderText!, validated.payload, validated.language as AppLanguage);
      expect([now?.parseSuccess, now?.parsed, now?.outputSafety], r.runId)
        .toEqual([r.stages?.parseSuccess, r.stages?.parsed, r.stages?.outputSafety]);
      expect(old.get(r.runId)?.oldBackendFinal, r.runId).toBe(r.backendFinal);
    }
  });

  it('observations and the client join re-derive, apart from gate-dependent fields', () => {
    const recomputed = JSON.parse(JSON.stringify(withAnalysis(artifact, loadReplays())));
    for (const path of GATE_DEPENDENT) expect(pick(artifact, path), path.join('.')).toBeDefined();
    expect(stripGateDependent(recomputed)).toEqual(stripGateDependent(artifact));
  });

  it('carries no secret-like text', () => {
    expect(text).not.toMatch(/sk-[A-Za-z0-9_-]{8,}|Bearer\s|authorization/i);
  });
});
