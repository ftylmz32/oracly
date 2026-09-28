/**
 * Dream Phase 4C.1 — offline reclassification of the frozen Phase 4C live
 * outputs through the final 4C.1 pipeline (no provider call):
 * parse → output safety on the RAW body (raw symbols included) → symbol
 * filtering (+ prose leak) → Phase 2 → Phase 4A → Phase 4B, all on the
 * sanitized body. The frozen artifact and its client replay are only read.
 */
import { createHash } from 'node:crypto';
import type { AppLanguage } from '../../src/ai/app-language.js';
import { contradictsEmotion } from '../../src/ai/dream-emotion-contract.js';
import { dreamHistoryClaimViolation } from '../../src/ai/dream-history-quality.js';
import { evaluateDreamPremiumQuality } from '../../src/ai/dream-premium-quality.js';
import { evaluateDreamQuality } from '../../src/ai/dream-quality.js';
import { dreamOutputFields, dreamOutputViolation } from '../../src/ai/dream-safety.js';
import { groundDreamSymbols, leakedSymbol } from '../../src/ai/dream-symbol-grounding.js';
import { parseDreamData, type DreamData } from '../../src/ai/parse-provider.js';
import { acceptanceInput } from '../dream-phase4c/stages.js';

export const PHASE4C1_SCHEMA = 'oracly.dream.phase4c1.offline-reclassification/v1';

export type FrozenRecord = {
  runId: string;
  language: string;
  narrative: string;
  symbols: unknown;
  emotions: unknown;
  memorySummary: string | null;
  history: unknown;
  rawProviderText: string | null;
  backendFinal: string;
  stages: {
    parseSuccess: boolean;
    outputSafety: string;
    phase2: string;
    phase4A: string;
    phase4B: string;
    diagnostic: { phase4A: string; phase4B: string } | null;
  } | null;
};

export type ClientResults = { old: Map<string, string>; next: Map<string, string> | null };

type Stage = 'parse' | 'outputSafety' | 'symbols' | 'phase2' | 'phase4A' | 'phase4B';

/** The fix that removed the old first failure, one code per run. */
const REASON: Record<string, string> = {
  invented_symbol: 'symbol_array_filtered',
  history_unsupported: 'history_claim_unit',
  emotion_contradiction: 'emotion_negation_contract',
  plot_recap: 'recap_detector',
  unsupported_personal_fact: 'personal_domain_contract',
  ungrounded_section: 'emotional_theme_role_grounding',
};

export const sha256 = (text: string) => createHash('sha256').update(text.replace(/\r\n/g, '\n')).digest('hex');

function oldFirstFailure(r: FrozenRecord): string {
  const s = r.stages;
  if (!s?.parseSuccess) return 'parse_failed';
  return [s.outputSafety, s.phase2, s.phase4A, s.phase4B].find((v) => v !== 'PASS') ?? 'PASS';
}

function tryParse(raw: string | null): DreamData | null {
  try {
    return raw === null ? null : parseDreamData(raw);
  } catch {
    return null;
  }
}

export function reclassifyRun(r: FrozenRecord, client: ClientResults) {
  const language = r.language as AppLanguage;
  const input = acceptanceInput(
    { narrative: r.narrative, symbols: r.symbols, emotions: r.emotions, history: r.history ?? undefined, memorySummary: r.memorySummary ?? undefined },
    language,
  );
  const raw = tryParse(r.rawProviderText);
  const grounded = raw ? groundDreamSymbols(raw, input) : null;
  const data = grounded?.data ?? null;
  const verdicts: Array<[Stage, string | null]> = raw && data
    ? [
        ['outputSafety', dreamOutputViolation(dreamOutputFields(raw))],
        ['symbols', leakedSymbol(grounded!.removed, data, input) ? 'invented_symbol' : null],
        ['phase2', evaluateDreamQuality(data, input)],
        ['phase4A', dreamHistoryClaimViolation(data, { narrative: input.narrative, history: input.history, language })],
        ['phase4B', evaluateDreamPremiumQuality(data, input)],
      ]
    : [['parse', 'parse_failed']];
  const first = verdicts.find(([, v]) => v !== null);
  const newFirstFailure = first ? first[1]! : 'PASS';
  const oldFirst = oldFirstFailure(r);
  const newBackendFinal = first ? 'REJECT' : 'PASS';
  const changed = oldFirst !== newFirstFailure || r.backendFinal !== newBackendFinal;
  const feelings = [input.narrative, ...input.emotions].join('. ');
  return {
    runId: r.runId,
    oldBackendFinal: r.backendFinal,
    oldFirstFailure: oldFirst,
    newBackendFinal,
    newFirstFailure,
    newFailureStage: first ? first[0] : null,
    rawSymbols: raw?.symbols ?? [],
    filteredSymbols: data?.symbols ?? [],
    historyOld: r.stages?.diagnostic?.phase4A ?? 'NOT_REACHED',
    historyNew: data ? (dreamHistoryClaimViolation(data, { narrative: input.narrative, history: input.history, language }) ?? 'PASS') : 'NOT_REACHED',
    emotionOld: r.stages?.diagnostic?.phase4B === 'emotion_contradiction' ? 'emotion_contradiction' : 'NOT_FLAGGED',
    emotionNew: data && [data.emotionalTheme, data.summary].some((s) => contradictsEmotion(feelings, s)) ? 'emotion_contradiction' : 'PASS',
    clientOld: r.backendFinal === 'PASS' ? (client.old.get(r.runId) ?? 'MISSING') : 'NOT_DELIVERED',
    clientNew: newBackendFinal === 'PASS' ? (client.next?.get(r.runId) ?? 'PENDING_CLIENT_REPLAY') : 'NOT_DELIVERED',
    changed: changed ? 'YES' : 'NO',
    changeReason: changed ? (REASON[oldFirst] ?? 'other_gate_change') : 'unchanged',
  };
}

export type Reclassified = ReturnType<typeof reclassifyRun>;

export function summarize(rows: Reclassified[]) {
  const count = (f: (r: Reclassified) => boolean) => rows.filter(f).length;
  const byStage = (stage: string) => count((r) => r.newFailureStage === stage);
  return {
    original: rows.length,
    oldBackendPass: count((r) => r.oldBackendFinal === 'PASS'),
    newOfflineBackendPass: count((r) => r.newBackendFinal === 'PASS'),
    oldToNewChanged: count((r) => r.changed === 'YES'),
    newRejections: {
      outputSafety: byStage('outputSafety'),
      symbols: byStage('symbols'),
      phase2: byStage('phase2'),
      phase4A: byStage('phase4A'),
      phase4B: byStage('phase4B'),
    },
    newBackendPassClientPass: count((r) => r.newBackendFinal === 'PASS' && r.clientNew === 'PASS'),
    newBackendPassClientFail: count((r) => r.newBackendFinal === 'PASS' && r.clientNew !== 'PASS'),
    changeReasons: rows.reduce<Record<string, number>>((m, r) => ({ ...m, [r.changeReason]: (m[r.changeReason] ?? 0) + 1 }), {}),
  };
}
