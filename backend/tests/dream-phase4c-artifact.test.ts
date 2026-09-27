// Dream Phase 4C — the committed live artifact, re-derived offline. No
// provider call is possible here: global fetch is stubbed to fail.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import { validatePhase4cArtifact, type Phase4cArtifact } from '../scripts/dream-phase4c/artifact.js';
import { loadReplays, PHASE4C_ARTIFACT_PATH, withAnalysis } from '../scripts/dream-phase4c/analyze.js';
import { buildPhase4cMatrix, loadPhase4cInputs } from '../scripts/dream-phase4c/matrix.js';
import { deployedOpenAiEnv } from '../scripts/dream-phase4c/production-config.js';
import { classifyDreamOutput } from '../scripts/dream-phase4c/stages.js';

const text = readFileSync(PHASE4C_ARTIFACT_PATH, 'utf8');
const artifact = JSON.parse(text) as Phase4cArtifact;
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

  it('every stage verdict re-derives offline from the raw provider text', () => {
    for (const r of artifact.runs) {
      const run = matrix.get(r.runId)!;
      const validated = validateAiBody({ operation: 'dream_analysis', payload: run.payload, model: run.clientModelHint });
      if (validated.operation !== 'dream_analysis') throw new Error('operation');
      expect(classifyDreamOutput(r.rawProviderText!, validated.payload, validated.language as AppLanguage), r.runId)
        .toEqual(r.stages);
    }
  });

  it('observations and the client join re-derive exactly', () => {
    const recomputed = JSON.parse(JSON.stringify(withAnalysis(artifact, loadReplays())));
    expect(recomputed).toEqual(artifact);
  });

  it('carries no secret-like text', () => {
    expect(text).not.toMatch(/sk-[A-Za-z0-9_-]{8,}|Bearer\s|authorization/i);
  });
});
