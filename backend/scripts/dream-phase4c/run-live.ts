/**
 * Dream Phase 4C — the one live run. HARD CAP 36 real Dream writer calls,
 * no retries, no judge model, synthetic inputs only.
 *
 *   PHASE4C_LIVE=1 PHASE4C_ENV_FILE=<backend .env> npx tsx \
 *     scripts/dream-phase4c/run-live.ts
 *
 * The key comes from this process env or that file only; it is never
 * printed or stored.
 * Refuses to overwrite an existing artifact, so a second run cannot spend.
 */
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { resolveModel } from '../../src/config.js';
import { PHASE4C_SCHEMA, validatePhase4cArtifact, type Phase4cArtifact } from './artifact.js';
import { runPhase4c } from './harness.js';
import { buildPhase4cMatrix, loadPhase4cInputs, PHASE4C_MAX_CALLS } from './matrix.js';
import { readEnvFileValue } from './env-file.js';
import { describeDreamConfig, phase4cConfig } from './production-config.js';

export const PHASE4C_ARTIFACT = fileURLToPath(
  new URL('../../../docs/product/dream/evals/DREAM_PHASE4C_LIVE_RUN_20260928.json', import.meta.url),
);

const git = (...args: string[]) => execFileSync('git', args, { encoding: 'utf8' }).trim();

function blocked(reason: string): never {
  console.error(`PHASE 4C LIVE INFRASTRUCTURE BLOCKED: ${reason}`);
  console.error('REAL PROVIDER CALLS: 0');
  process.exit(2);
}

async function main() {
  if (process.env.PHASE4C_LIVE !== '1') blocked('PHASE4C_LIVE=1 not set (explicit opt-in required)');
  const envFile = process.env.PHASE4C_ENV_FILE;
  const apiKey =
    process.env.OPENAI_API_KEY?.trim() || (envFile ? readEnvFileValue(envFile, 'OPENAI_API_KEY') : undefined);
  if (!apiKey) blocked('OPENAI_API_KEY not present in harness process env or PHASE4C_ENV_FILE');
  if (existsSync(PHASE4C_ARTIFACT)) blocked('artifact already exists; refusing a second live run');
  const dirty = git('diff', '--name-only', 'HEAD', '--', 'src', 'package.json', 'package-lock.json');
  if (dirty) blocked('backend production source differs from HEAD');

  const { requests, repeats } = loadPhase4cInputs();
  const runs = buildPhase4cMatrix(requests, repeats);
  const config = phase4cConfig(apiKey);
  const hint = runs[0].clientModelHint;
  if (runs.some((r) => r.clientModelHint !== hint)) throw new Error('mixed client model hints');
  const artifact: Phase4cArtifact = {
    schema: PHASE4C_SCHEMA,
    capturedAt: new Date().toISOString(),
    startHead: git('rev-parse', 'HEAD'),
    productionSourceClean: true,
    config: { clientModelHint: hint, ...describeDreamConfig(config, resolveModel(config, hint)) },
    budget: { max: PHASE4C_MAX_CALLS, used: 0, retries: 0, judgeCalls: 0 },
    runs: [],
  };
  console.log(`model=${artifact.config.resolvedModel} endpoint=${artifact.config.endpoint} runs=${runs.length}`);
  mkdirSync(dirname(PHASE4C_ARTIFACT), { recursive: true });
  const save = () => writeFileSync(PHASE4C_ARTIFACT, `${JSON.stringify(artifact, null, 2)}\n`);

  const { calls } = await runPhase4c({
    runs,
    config,
    fetch,
    onRecord: (record, used) => {
      artifact.runs.push(record);
      artifact.budget.used = used;
      save();
      const s = record.stages;
      const code = s ? [s.outputSafety, s.phase2, s.phase4A, s.phase4B].find((v) => v !== 'PASS') : record.errorCode;
      console.log(`${used}/${PHASE4C_MAX_CALLS} ${record.runId} ${record.backendFinal} ${code ?? ''} ${record.latencyMs ?? '-'}ms`);
    },
  });
  artifact.budget.used = calls;
  save();
  const errors = validatePhase4cArtifact(artifact);
  console.log(`REAL PROVIDER CALLS: ${calls}`);
  console.log(errors.length ? `SCHEMA ERRORS: ${errors.join('; ')}` : 'SCHEMA: PASS');
}

await main();
