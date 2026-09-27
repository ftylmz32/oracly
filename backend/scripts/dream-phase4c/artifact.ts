/**
 * Dream Phase 4C — live-run artifact shape and a dependency-free validator.
 * The artifact never carries headers, keys or environment values.
 */
import type { Phase4cRecord } from './harness.js';
import { PHASE4C_MAX_CALLS } from './matrix.js';

export const PHASE4C_SCHEMA = 'oracly.dream.phase4c.live-run/v1';

export type Phase4cArtifact = {
  schema: string;
  capturedAt: string;
  startHead: string;
  productionSourceClean: boolean;
  config: Record<string, unknown>;
  budget: { max: number; used: number; retries: 0; judgeCalls: 0 };
  runs: Phase4cRecord[];
  client?: unknown;
  observations?: unknown;
};

const FINALS = new Set(['PASS', 'REJECT', 'TRANSPORT_ERROR', 'SAFETY_ROUTED']);
const REQUIRED = [
  'runId', 'caseId', 'language', 'category', 'repeatOf', 'narrative', 'symbols', 'emotions',
  'memorySummary', 'history', 'resolvedModel', 'writerRevision', 'providerCallOccurred',
  'latencyMs', 'rawProviderText', 'stages', 'backendFinal',
] as const;
const SECRET = /(sk-[A-Za-z0-9_-]{8,}|bearer\s|authorization|api[_-]?key)/i;

export function validatePhase4cArtifact(a: Phase4cArtifact): string[] {
  const errors: string[] = [];
  if (a.schema !== PHASE4C_SCHEMA) errors.push('schema');
  if (!/^[0-9a-f]{40}$/.test(a.startHead)) errors.push('startHead');
  if (a.budget.max !== PHASE4C_MAX_CALLS) errors.push('budget.max');
  if (a.budget.used > PHASE4C_MAX_CALLS) errors.push('budget.used > max');
  const calls = a.runs.filter((r) => r.providerCallOccurred).length;
  if (calls !== a.budget.used) errors.push(`budget.used ${a.budget.used} != calls ${calls}`);
  if (new Set(a.runs.map((r) => r.runId)).size !== a.runs.length) errors.push('duplicate runId');
  for (const r of a.runs) {
    for (const key of REQUIRED) if (!(key in r)) errors.push(`${r.runId}: missing ${key}`);
    if (!FINALS.has(r.backendFinal)) errors.push(`${r.runId}: backendFinal`);
    if (!r.stageAgreement) errors.push(`${r.runId}: stage disagreement`);
    if (r.backendFinal === 'PASS' && r.stages?.final !== 'PASS') errors.push(`${r.runId}: PASS without stages`);
    if (r.repeatOf && !a.runs.some((x) => x.runId === r.repeatOf)) errors.push(`${r.runId}: orphan repeat`);
  }
  const { runs: _runs, ...meta } = a;
  const metaText = JSON.stringify(meta);
  const providerMeta = JSON.stringify(a.runs.map((r) => r.provider));
  if (SECRET.test(metaText) || SECRET.test(providerMeta)) errors.push('secret-like text in metadata');
  return errors;
}
