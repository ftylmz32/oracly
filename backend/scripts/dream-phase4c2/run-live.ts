/**
 * Dream Phase 4C.2 — the one live model comparison. HARD CAP 27 real calls
 * (9 cases × 3 models), no retries, no repair, no judge model.
 *
 *   PHASE4C2_LIVE=1 PHASE4C_ENV_FILE=<backend .env> npx tsx \
 *     scripts/dream-phase4c2/run-live.ts
 *
 * The key comes from this process env or that file only; it is never
 * printed or stored. Refuses to overwrite an existing artifact.
 */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { assertDreamInputSafe } from '../../src/ai/dream-safety.js';
import { buildChatCompletionBody } from '../../src/ai/openai-transport.js';
import { readEnvFileValue } from '../dream-phase4c/env-file.js';
import { describeDreamConfig, phase4cConfig } from '../dream-phase4c/production-config.js';
import {
  FROZEN_EVIDENCE, PHASE4C2_ARTIFACT_PATH, PHASE4C2_SCHEMA, validatePhase4c2Artifact, type Phase4c2Artifact,
} from './artifact.js';
import { CANDIDATES, completeOptions } from './candidates.js';
import { COMPATIBILITY } from './compatibility.js';
import { runPhase4c2, validated } from './harness.js';
import { buildPhase4c2Matrix, loadPhase4c2Requests, PHASE4C2_MAX_CALLS } from './matrix.js';
import { PENDING_REVIEW } from './record.js';

const git = (...args: string[]) => execFileSync('git', args, { encoding: 'utf8' }).trim();
const hashes = () => FROZEN_EVIDENCE.map((p) => createHash('sha256').update(readFileSync(p)).digest('hex'));

function blocked(reason: string): never {
  console.error(`PHASE 4C.2 LIVE INFRASTRUCTURE BLOCKED: ${reason}`);
  console.error('REAL PROVIDER CALLS: 0');
  process.exit(2);
}

async function main() {
  if (process.env.PHASE4C2_LIVE !== '1') blocked('PHASE4C2_LIVE=1 not set (explicit opt-in required)');
  const envFile = process.env.PHASE4C_ENV_FILE;
  const apiKey =
    process.env.OPENAI_API_KEY?.trim() || (envFile ? readEnvFileValue(envFile, 'OPENAI_API_KEY') : undefined);
  if (!apiKey) blocked('OPENAI_API_KEY not present in harness process env or PHASE4C_ENV_FILE');
  if (existsSync(PHASE4C2_ARTIFACT_PATH)) blocked('artifact already exists; refusing a second live run');
  if (git('diff', '--name-only', 'HEAD', '--', 'src', 'package.json', 'package-lock.json')) {
    blocked('backend production source differs from HEAD');
  }
  const attempts = buildPhase4c2Matrix(loadPhase4c2Requests());
  for (const a of attempts) assertDreamInputSafe(validated(a).payload);
  const frozenBefore = hashes();
  const config = phase4cConfig(apiKey);
  const production = describeDreamConfig(config);
  const artifact: Phase4c2Artifact = {
    schema: PHASE4C2_SCHEMA,
    capturedAt: new Date().toISOString(),
    startHead: git('rev-parse', 'HEAD'),
    productionSourceClean: true,
    modelWinner: PENDING_REVIEW,
    compatibility: COMPATIBILITY,
    config: {
      endpoint: production.endpoint,
      timeoutMs: production.timeoutMs,
      transportRetries: 0,
      productionModelUnchanged: { configuredModel: production.configuredGenericModel, allowedModels: production.allowedModels },
      candidates: CANDIDATES.map((c) => {
        const { messages: _m, ...body } = buildChatCompletionBody(completeOptions(c, []));
        return { id: c.id, body, pricing: c.pricing };
      }),
    },
    budget: { max: PHASE4C2_MAX_CALLS, used: 0, retries: 0, repairCalls: 0, judgeCalls: 0 },
    attempts: [],
  };
  const save = () => {
    const text = `${JSON.stringify(artifact, null, 2)}\n`;
    if (text.includes(apiKey)) throw new Error('refusing to write key material');
    writeFileSync(PHASE4C2_ARTIFACT_PATH, text);
  };
  console.log(`endpoint=${production.endpoint} attempts=${attempts.length} timeoutMs=${production.timeoutMs}`);
  const { calls } = await runPhase4c2({
    attempts,
    config,
    fetch,
    onRecord: (r, used) => {
      artifact.attempts.push(r);
      artifact.budget.used = used;
      save();
      const code = r.firstFailure ?? r.errorCode ?? '';
      console.log(`${used}/${PHASE4C2_MAX_CALLS} ${r.attemptId} ${r.httpClass} ${r.backendFinal} ${code} ${r.latencyMs}ms`);
    },
  });
  artifact.budget.used = calls;
  save();
  if (hashes().join() !== frozenBefore.join()) throw new Error('frozen 4C/4C.1 evidence changed during the run');
  const errors = validatePhase4c2Artifact(artifact);
  console.log(`REAL PROVIDER CALLS: ${calls}`);
  console.log(errors.length ? `SCHEMA ERRORS: ${errors.join('; ')}` : 'SCHEMA: PASS');
}

await main();
