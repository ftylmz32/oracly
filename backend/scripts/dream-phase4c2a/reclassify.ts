/**
 * Dream Phase 4C.2a — one immutable 4C.2 live output re-run through the
 * calibrated production gates (no provider call): parse → raw output
 * safety → symbol filtering → Phase 2 → 4A → 4B, then the client verdict
 * from the 4C.2a Flutter replay of every new backend PASS.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import type { CandidateId } from '../dream-phase4c2/candidates.js';
import type { Phase4c2Attempt } from '../dream-phase4c2/matrix.js';
import type { Phase4c2Record } from '../dream-phase4c2/record.js';
import { classifyPhase4c2 } from '../dream-phase4c2/stages.js';

export const PHASE4C2A_SCHEMA = 'oracly.dream.phase4c2a.offline-reclassification/v1';

/** The 4C.2a fix that owns each old first failure; anything else is unexplained. */
const OWNER: Record<string, Partial<Record<string, string>>> = {
  emotion_contradiction: { tr: 'tr_fear_negation', ru: 'ru_cause_negation', en: 'en_without_scope' },
  history_unsupported: { en: 'history_claim_scope', tr: 'history_claim_scope', ru: 'history_claim_scope' },
  invented_symbol: { ru: 'ru_mobile_vowel_inflection' },
  unsupported_personal_fact: { tr: 'tr_ilişkin_postposition' },
};

export type ClientVerdict = { clientResult: string; clientGap?: string | null };

export type Phase4c2aRow = {
  attemptId: string;
  model: CandidateId;
  caseId: string;
  language: string;
  oldBackendFinal: string;
  oldFirstFailure: string | null;
  newBackendFinal: string;
  newFirstFailure: string | null;
  oldFilteredSymbols: string[];
  newFilteredSymbols: string[];
  newDiagnostic: Record<string, string> | null;
  oldClientResult: string;
  newClientResult: string;
  newClientGap: string | null;
  changeReason: string;
};

function changeReason(r: Phase4c2Record, row: Omit<Phase4c2aRow, 'changeReason'>): string {
  const backendSame = row.oldBackendFinal === row.newBackendFinal && row.oldFirstFailure === row.newFirstFailure;
  if (!backendSame) return OWNER[row.oldFirstFailure ?? '']?.[r.language] ?? 'other_gate_change';
  if (row.oldClientResult !== row.newClientResult) return 'provider_ai_style_guard';
  if (JSON.stringify(row.oldFilteredSymbols) !== JSON.stringify(row.newFilteredSymbols)) {
    return r.language === 'ru' ? 'ru_mobile_vowel_inflection' : 'other_gate_change';
  }
  return 'unchanged';
}

export function reclassifyAttempt(
  r: Phase4c2Record,
  attempt: Phase4c2Attempt,
  client: Map<string, ClientVerdict> | null,
): Phase4c2aRow {
  if (attempt.attemptId !== r.attemptId) throw new Error(`matrix drift at ${r.attemptId}`);
  const language = r.language as AppLanguage;
  const s = r.rawProviderText === null ? null : classifyPhase4c2(r.rawProviderText, attempt.payload, language);
  const newBackendFinal = s ? s.final : r.backendFinal;
  const verdict = newBackendFinal === 'PASS' ? client?.get(r.attemptId) : undefined;
  const row = {
    attemptId: r.attemptId,
    model: r.candidateModel,
    caseId: r.caseId,
    language: r.language,
    oldBackendFinal: r.backendFinal,
    oldFirstFailure: r.firstFailure,
    newBackendFinal,
    newFirstFailure: s ? s.firstFailure : r.firstFailure,
    oldFilteredSymbols: r.filteredSymbols,
    newFilteredSymbols: s ? s.filteredSymbols : r.filteredSymbols,
    newDiagnostic: s?.diagnostic ?? null,
    oldClientResult: r.clientResult ?? 'NOT_DELIVERED',
    newClientResult: newBackendFinal !== 'PASS' ? 'NOT_DELIVERED' : (verdict?.clientResult ?? 'PENDING_CLIENT_REPLAY'),
    newClientGap: verdict?.clientGap ?? null,
  };
  return { ...row, changeReason: changeReason(r, row) };
}

export function summarize(rows: Phase4c2aRow[]) {
  const models = [...new Set(rows.map((r) => r.model))];
  const count = (m: string, pick: (r: Phase4c2aRow) => boolean) => rows.filter((r) => r.model === m && pick(r)).length;
  return {
    note: 'Counts are gate outcomes, not the semantic ranking.',
    attempts: rows.length,
    changed: rows.filter((r) => r.changeReason !== 'unchanged').length,
    reasons: Object.fromEntries(
      [...new Set(rows.map((r) => r.changeReason))].sort().map((k) => [k, rows.filter((r) => r.changeReason === k).length]),
    ),
    perModel: Object.fromEntries(models.map((m) => [m, {
      attempts: count(m, () => true),
      oldBackendPass: count(m, (r) => r.oldBackendFinal === 'PASS'),
      newBackendPass: count(m, (r) => r.newBackendFinal === 'PASS'),
      oldClientPass: count(m, (r) => r.oldClientResult === 'PASS'),
      newClientPass: count(m, (r) => r.newClientResult === 'PASS'),
    }])),
    newBackendPassClientFail: rows
      .filter((r) => r.newBackendFinal === 'PASS' && r.newClientResult !== 'PASS')
      .map((r) => ({ attemptId: r.attemptId, clientResult: r.newClientResult, clientGap: r.newClientGap })),
  };
}
