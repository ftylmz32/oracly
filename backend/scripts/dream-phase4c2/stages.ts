/**
 * Dream Phase 4C.2 — per-stage verdicts for one live provider text, in the
 * production 4C.1 order (`AiProxyService.dream` → `acceptDreamData`):
 * parse → output safety on the RAW body → symbol filtering (+ prose leak)
 * → Phase 2 → Phase 4A → Phase 4B on the sanitized body. `diagnostic`
 * evaluates every post-safety stage independently, for analysis only.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import { dreamHistoryClaimViolation } from '../../src/ai/dream-history-quality.js';
import { evaluateDreamPremiumQuality } from '../../src/ai/dream-premium-quality.js';
import { evaluateDreamQuality } from '../../src/ai/dream-quality.js';
import { dreamOutputFields, dreamOutputViolation } from '../../src/ai/dream-safety.js';
import { groundDreamSymbols, leakedSymbol } from '../../src/ai/dream-symbol-grounding.js';
import { parseDreamData, type DreamData } from '../../src/ai/parse-provider.js';
import { acceptanceInput } from '../dream-phase4c/stages.js';

const STAGES = ['outputSafety', 'symbols', 'phase2', 'phase4A', 'phase4B'] as const;
export type Phase4c2Stage = (typeof STAGES)[number];

export type Phase4c2Stages = {
  parseSuccess: boolean;
  parsed: DreamData | null;
  rawSymbols: string[];
  filteredSymbols: string[];
  outputSafety: string;
  symbols: string;
  phase2: string;
  phase4A: string;
  phase4B: string;
  firstFailure: string | null;
  failureStage: Phase4c2Stage | 'parse' | null;
  final: 'PASS' | 'REJECT';
  diagnostic: Record<Exclude<Phase4c2Stage, 'outputSafety'>, string> | null;
};

function tryParse(raw: string): DreamData | null {
  try {
    return parseDreamData(raw);
  } catch {
    return null;
  }
}

const NOT_REACHED = {
  outputSafety: 'NOT_REACHED',
  symbols: 'NOT_REACHED',
  phase2: 'NOT_REACHED',
  phase4A: 'NOT_REACHED',
  phase4B: 'NOT_REACHED',
};

/** `payload` is the validated request payload (`validateAiBody` output). */
export function classifyPhase4c2(raw: string, payload: Record<string, unknown>, language: AppLanguage): Phase4c2Stages {
  const parsed = tryParse(raw);
  if (!parsed) {
    return {
      parseSuccess: false,
      parsed: null,
      rawSymbols: [],
      filteredSymbols: [],
      ...NOT_REACHED,
      firstFailure: 'parse_failed',
      failureStage: 'parse',
      final: 'REJECT',
      diagnostic: null,
    };
  }
  const input = acceptanceInput(payload, language);
  const { data, removed } = groundDreamSymbols(parsed, input);
  const history = { narrative: input.narrative, history: input.history, language };
  const verdicts: Record<Phase4c2Stage, string | null> = {
    outputSafety: dreamOutputViolation(dreamOutputFields(parsed)),
    symbols: leakedSymbol(removed, data, input) ? 'invented_symbol' : null,
    phase2: evaluateDreamQuality(data, input),
    phase4A: dreamHistoryClaimViolation(data, history),
    phase4B: evaluateDreamPremiumQuality(data, input),
  };
  const failed = STAGES.find((s) => verdicts[s] !== null) ?? null;
  const reached = (s: Phase4c2Stage) =>
    failed !== null && STAGES.indexOf(s) > STAGES.indexOf(failed) ? 'NOT_REACHED' : (verdicts[s] ?? 'PASS');
  return {
    parseSuccess: true,
    parsed,
    rawSymbols: parsed.symbols,
    filteredSymbols: data.symbols,
    outputSafety: reached('outputSafety'),
    symbols: reached('symbols'),
    phase2: reached('phase2'),
    phase4A: reached('phase4A'),
    phase4B: reached('phase4B'),
    firstFailure: failed ? verdicts[failed] : null,
    failureStage: failed,
    final: failed ? 'REJECT' : 'PASS',
    diagnostic: {
      symbols: verdicts.symbols ?? 'PASS',
      phase2: verdicts.phase2 ?? 'PASS',
      phase4A: verdicts.phase4A ?? 'PASS',
      phase4B: verdicts.phase4B ?? 'PASS',
    },
  };
}
