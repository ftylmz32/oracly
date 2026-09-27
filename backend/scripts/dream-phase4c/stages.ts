/**
 * Dream Phase 4C — per-stage verdicts for one captured provider text, using
 * the production functions in production order (parse → output safety →
 * Phase 2 → Phase 4A → Phase 4B). `production` stops at the first failure
 * exactly like `AiProxyService.dream`; `diagnostic` evaluates every stage
 * independently for analysis only.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import type { DreamHistoryItem } from '../../src/ai/dream-history.js';
import { dreamHistoryClaimViolation } from '../../src/ai/dream-history-quality.js';
import { evaluateDreamPremiumQuality } from '../../src/ai/dream-premium-quality.js';
import { evaluateDreamQuality } from '../../src/ai/dream-quality.js';
import {
  dreamOutputFields,
  dreamOutputViolation,
  isSensitiveDreamMemory,
} from '../../src/ai/dream-safety.js';
import { parseDreamData, type DreamData } from '../../src/ai/parse-provider.js';
import { sanitizeText, stringList } from '../../src/ai/sanitize.js';

export type StageVerdict = 'PASS' | 'NOT_REACHED' | string;

export type StageReport = {
  parseSuccess: boolean;
  parsed: DreamData | null;
  outputSafety: StageVerdict;
  phase2: StageVerdict;
  phase4A: StageVerdict;
  phase4B: StageVerdict;
  final: 'PASS' | 'REJECT';
  diagnostic: { outputSafety: string; phase2: string; phase4A: string; phase4B: string } | null;
};

/** `payload` is the validated request payload (`validateAiBody` output). */
export function acceptanceInput(payload: Record<string, unknown>, language: AppLanguage) {
  const memory = sanitizeText(payload.memorySummary, 220);
  return {
    narrative: sanitizeText(payload.narrative),
    symbols: stringList(payload.symbols),
    emotions: stringList(payload.emotions),
    language,
    history: payload.history as DreamHistoryItem[] | undefined,
    memorySummary: (isSensitiveDreamMemory(memory) ? '' : memory) || undefined,
  };
}

function tryParse(raw: string): DreamData | null {
  try {
    return parseDreamData(raw);
  } catch {
    return null;
  }
}

export function classifyDreamOutput(
  raw: string,
  payload: Record<string, unknown>,
  language: AppLanguage,
): StageReport {
  const parsed = tryParse(raw);
  if (!parsed) {
    return {
      parseSuccess: false,
      parsed: null,
      outputSafety: 'NOT_REACHED',
      phase2: 'NOT_REACHED',
      phase4A: 'NOT_REACHED',
      phase4B: 'NOT_REACHED',
      final: 'REJECT',
      diagnostic: null,
    };
  }
  const input = acceptanceInput(payload, language);
  const verdicts = [
    dreamOutputViolation(dreamOutputFields(parsed)),
    evaluateDreamQuality(parsed, input),
    dreamHistoryClaimViolation(parsed, {
      narrative: input.narrative,
      history: input.history,
      language,
    }),
    evaluateDreamPremiumQuality(parsed, input),
  ].map((v) => v ?? 'PASS');
  const firstFail = verdicts.findIndex((v) => v !== 'PASS');
  const production = verdicts.map((v, i) => (firstFail !== -1 && i > firstFail ? 'NOT_REACHED' : v));
  return {
    parseSuccess: true,
    parsed,
    outputSafety: production[0],
    phase2: production[1],
    phase4A: production[2],
    phase4B: production[3],
    final: firstFail === -1 ? 'PASS' : 'REJECT',
    diagnostic: {
      outputSafety: verdicts[0],
      phase2: verdicts[1],
      phase4A: verdicts[2],
      phase4B: verdicts[3],
    },
  };
}
