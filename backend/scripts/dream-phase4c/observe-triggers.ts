/**
 * Dream Phase 4C — the exact sentence or section behind a Phase 4A history
 * rejection or a Phase 4B emotion contradiction, found by re-running the
 * production check on each piece alone. Evidence for review, not a verdict.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import { contradictsEmotion } from '../../src/ai/dream-emotion-contract.js';
import { dreamHistoryClaimViolation } from '../../src/ai/dream-history-quality.js';
import type { DreamData } from '../../src/ai/parse-provider.js';
import type { Phase4cRecord } from './harness.js';
import { FIELDS, sentences } from './observe-text.js';
import { acceptanceInput } from './stages.js';

const BLANK: DreamData = {
  summary: 'x', symbols: [], emotionalTheme: 'x', interpretation: 'x', dailyLifeReflection: 'x', conclusion: 'x',
};

export function gateTriggers(runs: Phase4cRecord[]) {
  const out: Array<{ runId: string; gate: string; code: string; field: string; text: string }> = [];
  for (const r of runs) {
    const d = r.stages?.diagnostic;
    const data = r.stages?.parsed;
    if (!d || !data) continue;
    const language = r.language as AppLanguage;
    const input = acceptanceInput(
      { narrative: r.narrative, symbols: r.symbols, emotions: r.emotions, history: r.history ?? undefined },
      language,
    );
    if (d.phase4A !== 'PASS') {
      for (const field of FIELDS) for (const text of sentences(data[field])) {
        const code = dreamHistoryClaimViolation({ ...BLANK, [field]: text }, {
          narrative: input.narrative, history: input.history, language,
        });
        if (code) out.push({ runId: r.runId, gate: 'phase4A', code, field, text });
      }
    }
    if (d.phase4B === 'emotion_contradiction') {
      const feelings = [input.narrative, ...input.emotions].join('. ');
      for (const field of ['summary', 'emotionalTheme'] as const) {
        if (contradictsEmotion(feelings, data[field])) {
          out.push({ runId: r.runId, gate: 'phase4B', code: 'emotion_contradiction', field, text: data[field] });
        }
      }
    }
  }
  return out;
}
