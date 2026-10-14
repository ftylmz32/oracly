// Dream Phase 4C.1 — the offline reclassification of the frozen Phase 4C live
// outputs re-derives (up to named 4C.2a drift), and the frozen evidence
// stays byte-identical.
// No provider call is possible here: global fetch is stubbed to fail.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { PHASE4C_ARTIFACT_PATH, PHASE4C_CLIENT_REPLAY_PATH } from '../scripts/dream-phase4c/analyze.js';
import { buildReclassification, PHASE4C1_ARTIFACT_PATH } from '../scripts/dream-phase4c1/artifact.js';
import { sha256 } from '../scripts/dream-phase4c1/reclassify.js';
import { jsonDrift } from '../scripts/dream-phase4c2a/drift.js';

const text = readFileSync(PHASE4C1_ARTIFACT_PATH, 'utf8');
const committed = JSON.parse(text) as ReturnType<typeof buildReclassification>;
const frozenText = readFileSync(PHASE4C_ARTIFACT_PATH, 'utf8');
const FIELDS = [
  'runId', 'oldBackendFinal', 'oldFirstFailure', 'newBackendFinal', 'newFirstFailure', 'rawSymbols',
  'filteredSymbols', 'historyOld', 'historyNew', 'emotionOld', 'emotionNew', 'clientOld', 'clientNew',
  'changed', 'changeReason',
];

beforeAll(() => {
  vi.stubGlobal('fetch', () => {
    throw new Error('no provider calls in regression');
  });
});
afterAll(() => vi.unstubAllGlobals());

describe('Phase 4C.1 offline reclassification', () => {
  // The 4C.1 artifact remains frozen historical evidence. Current code has
  // two exact later-contract drifts: 4C.2a Russian symbol inflection, and the
  // optional-reflection/natural-close contract. The latter makes one old
  // sample reject earlier as ungrounded instead of later as extra_question.
  it('re-derives with only the named later-contract drifts', () => {
    const now = JSON.parse(JSON.stringify(buildReclassification())) as typeof committed;
    const ruMemory = committed.runs.findIndex((r) => r.runId === 'ru-memory');
    const naturalClose = committed.runs.findIndex((r) => r.runId === 'en-no-domain#r2');
    expect(naturalClose).toBeGreaterThanOrEqual(0);
    const fields = new Set(jsonDrift(committed, now).map((d) => d.path.replace(/\.\d+$/, '')));
    expect([...fields]).toEqual([
      '$.summary.oldToNewChanged',
      '$.summary.newRejections.phase2',
      '$.summary.newRejections.phase4B',
      '$.summary.changeReasons.unchanged',
      '$.summary.changeReasons.natural_conclusion_contract',
      `$.runs.${ruMemory}.filteredSymbols`,
      `$.runs.${naturalClose}.newFirstFailure`,
      `$.runs.${naturalClose}.newFailureStage`,
      `$.runs.${naturalClose}.changed`,
      `$.runs.${naturalClose}.changeReason`,
    ]);
    expect(committed.runs[ruMemory]!.filteredSymbols).toEqual(['туман', 'освещённая дорога', 'тёмная дорога']);
    expect(now.runs[ruMemory]!.filteredSymbols).toEqual(['перекрёсток', 'туман', 'освещённая дорога', 'тёмная дорога']);
    expect(committed.runs[naturalClose]).toMatchObject({
      newFirstFailure: 'extra_question',
      newFailureStage: 'phase4B',
      changed: 'NO',
      changeReason: 'unchanged',
    });
    expect(now.runs[naturalClose]).toMatchObject({
      newFirstFailure: 'ungrounded',
      newFailureStage: 'phase2',
      changed: 'YES',
      changeReason: 'natural_conclusion_contract',
    });
  });

  it('reads the frozen evidence unchanged', () => {
    expect(committed.source.artifactSha256).toBe(sha256(frozenText));
    expect(committed.source.clientReplaySha256).toBe(sha256(readFileSync(PHASE4C_CLIENT_REPLAY_PATH, 'utf8')));
    const raw = (JSON.parse(frozenText).runs as Array<{ rawProviderText: string | null }>)
      .map((r) => r.rawProviderText ?? '').join('\u0000');
    expect(committed.source.rawProviderTextSha256).toBe(sha256(raw));
  });

  it('covers the original 36 runs with every §11 column', () => {
    expect(committed.runs).toHaveLength(36);
    expect(committed.summary.original).toBe(36);
    expect(committed.summary.oldBackendPass).toBe(2);
    for (const r of committed.runs) for (const f of FIELDS) expect(r, `${r.runId}.${f}`).toHaveProperty(f);
    expect(committed.method.providerCalls).toBe(0);
    expect(committed.method.important).toMatch(/not proof of writer quality/);
  });

  it('every change is explained by one 4C.1 fix; unchanged rows keep their verdict', () => {
    for (const r of committed.runs) {
      if (r.changed === 'NO') {
        expect([r.newBackendFinal, r.newFirstFailure], r.runId).toEqual([r.oldBackendFinal, r.oldFirstFailure]);
        expect(r.changeReason).toBe('unchanged');
      } else {
        expect(r.changeReason, r.runId).not.toBe('other_gate_change');
      }
    }
  });

  it('every new backend PASS was replayed on the client; filtered symbols stay a subset', () => {
    for (const r of committed.runs) {
      expect(r.clientNew, r.runId).toBe(r.newBackendFinal === 'PASS' ? 'PASS' : 'NOT_DELIVERED');
      for (const s of r.filteredSymbols) expect(r.rawSymbols, r.runId).toContain(s);
    }
    expect(committed.summary.newBackendPassClientFail).toBe(0);
  });

  it('carries no secret-like text', () => {
    expect(text).not.toMatch(/sk-[A-Za-z0-9_-]{8,}|Bearer\s|authorization/i);
  });
});
