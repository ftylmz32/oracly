/**
 * Dream Phase 4C.2 — the model comparison artifact: schema, fixed paths
 * and validation. Secrets never belong here; the validator refuses any
 * bearer/key-shaped string anywhere in the serialized artifact.
 */
import { fileURLToPath } from 'node:url';
import { CANDIDATES } from './candidates.js';
import { PHASE4C2_CASES, PHASE4C2_MAX_CALLS, rotation } from './matrix.js';
import { PENDING_REVIEW, type Phase4c2Record } from './record.js';
import { PHASE4C2_WRITER_REVISION } from './record-type.js';

export const PHASE4C2_SCHEMA = 'oracly.dream.phase4c2.model-ab/v1';
const doc = (name: string) => fileURLToPath(new URL(`../../../docs/product/dream/evals/${name}`, import.meta.url));
export const PHASE4C2_ARTIFACT_PATH = doc('DREAM_PHASE4C2_MODEL_AB_20260928.json');
export const PHASE4C2_CLIENT_REPLAY_PATH = doc('DREAM_PHASE4C2_CLIENT_REPLAY_20260928.json');
export const FROZEN_EVIDENCE = [
  doc('DREAM_PHASE4C_LIVE_RUN_20260928.json'),
  doc('DREAM_PHASE4C_CLIENT_REPLAY_20260928.json'),
  doc('DREAM_PHASE4C1_OFFLINE_RECLASSIFICATION_20260928.json'),
];

export type Phase4c2Artifact = {
  schema: typeof PHASE4C2_SCHEMA;
  capturedAt: string;
  startHead: string;
  productionSourceClean: true;
  modelWinner: typeof PENDING_REVIEW;
  compatibility: Record<string, unknown>;
  config: Record<string, unknown>;
  budget: { max: number; used: number; retries: 0; repairCalls: 0; judgeCalls: 0 };
  attempts: Phase4c2Record[];
  analysis?: Record<string, unknown>;
};

const SECRET = /(sk-[A-Za-z0-9_-]{8,}|Bearer\s+\S+|"authorization"|"api[_-]?key"\s*:)/i;

export function validatePhase4c2Artifact(a: Phase4c2Artifact): string[] {
  const errors: string[] = [];
  const need = (ok: boolean, msg: string) => ok || errors.push(msg);
  need(a.schema === PHASE4C2_SCHEMA, 'schema');
  need(a.modelWinner === PENDING_REVIEW, 'modelWinner must stay pending');
  need(a.budget.max === PHASE4C2_MAX_CALLS && a.budget.used <= PHASE4C2_MAX_CALLS, 'budget');
  need(a.budget.retries === 0 && a.budget.repairCalls === 0 && a.budget.judgeCalls === 0, 'no retry/repair/judge');
  need(a.attempts.length <= PHASE4C2_MAX_CALLS, 'too many attempts');
  need(a.attempts.filter((r) => r.providerCallOccurred).length === a.budget.used, 'budget.used = provider calls');
  need(!SECRET.test(JSON.stringify(a)), 'secret-shaped content');
  const expected = PHASE4C2_CASES.flatMap((id, i) => rotation(i).map((c) => `${id}::${c}`));
  a.attempts.forEach((r, i) => {
    const at = `${r.attemptId}`;
    need(r.attemptId === expected[i] && r.order === i + 1, `${at}: order`);
    need(CANDIDATES.some((c) => c.id === r.candidateModel && c.model === r.requestedModel), `${at}: model`);
    need(r.writerRevision === PHASE4C2_WRITER_REVISION, `${at}: writer revision`);
    need(r.endpoint === 'https://api.openai.com/v1/chat/completions', `${at}: endpoint`);
    need((r.parameters.responseFormat as { type?: string } | null)?.type === 'json_object', `${at}: json mode`);
    const reasoning = r.candidateModel !== 'gpt-4o';
    need(
      reasoning
        ? r.parameters.reasoningEffort === 'medium' && !r.parameters.temperaturePresent
        : r.parameters.reasoningEffort === null && r.parameters.temperature === 0.6,
      `${at}: parameters`,
    );
    need(!r.parameters.topPPresent && !r.parameters.logprobsPresent && !r.parameters.topLogprobsPresent, `${at}: sampling`);
    need(['PASS', 'REJECT', 'TRANSPORT_ERROR', 'PARAMETER_ERROR'].includes(r.backendFinal), `${at}: final`);
    need(r.productionAgreement, `${at}: stage/production disagreement`);
    need(r.inventedConcreteSceneContent === PENDING_REVIEW && r.inventedConcreteSceneItems.length === 0, `${at}: scene review`);
    need(r.backendFinal === 'PASS' ? r.clientResult !== 'NOT_DELIVERED' : r.clientResult === 'NOT_DELIVERED', `${at}: client`);
  });
  return errors;
}
