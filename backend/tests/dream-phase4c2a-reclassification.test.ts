// Dream Phase 4C.2a — the offline reclassification of the 27 immutable 4C.2
// live outputs re-derives exactly, the frozen evidence stays byte-identical,
// and every verdict change is owned by one calibration fix.
// No provider call is possible here: global fetch is stubbed to fail.
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { FROZEN_EVIDENCE, PHASE4C2_ARTIFACT_PATH, PHASE4C2_CLIENT_REPLAY_PATH } from '../scripts/dream-phase4c2/artifact.js';
import { PHASE4C1_CLIENT_REPLAY_PATH } from '../scripts/dream-phase4c1/artifact.js';
import { buildPhase4c2aReclassification, evidenceSha256, PHASE4C2A_ARTIFACT_PATH, sha256 } from '../scripts/dream-phase4c2a/artifact.js';

const text = readFileSync(PHASE4C2A_ARTIFACT_PATH, 'utf8');
const committed = JSON.parse(text) as ReturnType<typeof buildPhase4c2aReclassification>;
const frozenText = readFileSync(PHASE4C2_ARTIFACT_PATH, 'utf8');
const row = (id: string) => committed.attempts.find((r) => r.attemptId === id)!;
const COLUMNS = [
  'attemptId', 'model', 'oldBackendFinal', 'oldFirstFailure', 'newBackendFinal', 'newFirstFailure',
  'oldClientResult', 'newClientResult', 'changeReason',
];

beforeAll(() => {
  vi.stubGlobal('fetch', () => {
    throw new Error('no provider calls in regression');
  });
});
afterAll(() => vi.unstubAllGlobals());

describe('Phase 4C.2a offline reclassification', () => {
  it('re-derives exactly from the immutable 4C.2 outputs and the 4C.2a client replay', () => {
    expect(JSON.parse(JSON.stringify(buildPhase4c2aReclassification()))).toEqual(committed);
  });

  it('reads the frozen evidence unchanged', () => {
    expect(committed.source.artifactSha256).toBe(evidenceSha256(frozenText));
    expect(committed.source.clientReplaySha256).toBe(evidenceSha256(readFileSync(PHASE4C2_CLIENT_REPLAY_PATH, 'utf8')));
    const raw = (JSON.parse(frozenText).attempts as Array<{ rawProviderText: string | null }>)
      .map((r) => r.rawProviderText ?? '').join('\u0000');
    expect(committed.source.rawProviderTextSha256).toBe(sha256(raw));
    const frozen = [PHASE4C2_ARTIFACT_PATH, PHASE4C2_CLIENT_REPLAY_PATH, PHASE4C1_CLIENT_REPLAY_PATH, ...FROZEN_EVIDENCE];
    expect(execFileSync('git', ['diff', '--name-only', 'HEAD', '--', ...frozen], { encoding: 'utf8' }).trim()).toBe('');
  });

  it('covers all 27 attempts with every required column and no provider call', () => {
    expect(committed.attempts).toHaveLength(27);
    for (const r of committed.attempts) for (const c of COLUMNS) expect(r, `${r.attemptId}.${c}`).toHaveProperty(c);
    expect(committed.method.providerCalls).toBe(0);
    expect(committed.summary.note).toMatch(/not the semantic ranking/);
  });

  it('every change is owned by one 4C.2a fix; unchanged rows keep their verdicts', () => {
    for (const r of committed.attempts) {
      expect(r.changeReason, r.attemptId).not.toBe('other_gate_change');
      if (r.changeReason === 'unchanged') {
        expect([r.newBackendFinal, r.newFirstFailure, r.newClientResult], r.attemptId)
          .toEqual([r.oldBackendFinal, r.oldFirstFailure, r.oldClientResult]);
      }
    }
  });

  it('every new backend PASS was delivered by the client', () => {
    for (const r of committed.attempts) {
      expect(r.newClientResult, r.attemptId).toBe(r.newBackendFinal === 'PASS' ? 'PASS' : 'NOT_DELIVERED');
    }
    expect(committed.summary.newBackendPassClientFail).toEqual([]);
  });

  it.each([
    ['tr-negated-fear::gpt-6-sol', 'PASS', null, 'tr_fear_negation'],
    ['tr-negated-fear::gpt-6-astra', 'REJECT', 'emotion_contradiction', 'unchanged'],
    ['ru-negated-fear::gpt-6-sol', 'REJECT', 'emotion_contradiction', 'unchanged'],
    ['ru-negated-fear::gpt-6-astra', 'PASS', null, 'ru_cause_negation'],
    ['en-mixed-emotion::gpt-6-sol', 'REJECT', 'ungrounded_section', 'en_without_scope'],
    ['en-history::gpt-6-astra', 'PASS', null, 'history_claim_scope'],
    ['en-history::gpt-4o', 'PASS', null, 'history_claim_scope'],
    ['ru-memory::gpt-4o', 'REJECT', 'ungrounded_section', 'ru_mobile_vowel_inflection'],
    ['tr-domain-work::gpt-6-astra', 'PASS', null, 'tr_ilişkin_postposition'],
    ['tr-history::gpt-6-astra', 'PASS', null, 'provider_ai_style_guard'],
  ] as const)('re-evaluated %s → %s %s', (id, final, failure, reason) => {
    const r = row(id);
    expect([r.newBackendFinal, r.newFirstFailure, r.changeReason]).toEqual([final, failure, reason]);
  });

  it('gpt-4o one-word emotional themes stay rejected at parse', () => {
    for (const id of ['tr-negated-fear::gpt-4o', 'tr-history::gpt-4o']) {
      expect(row(id).newFirstFailure).toBe('parse_failed');
      const raw = (JSON.parse(frozenText).attempts as Array<{ attemptId: string; rawProviderText: string }>)
        .find((a) => a.attemptId === id)!.rawProviderText;
      expect((JSON.parse(raw).emotionalTheme as string).trim().length).toBeLessThan(8);
    }
  });

  it('carries no secret-like text', () => {
    expect(text).not.toMatch(/sk-[A-Za-z0-9_-]{8,}|Bearer\s|authorization/i);
  });
});
