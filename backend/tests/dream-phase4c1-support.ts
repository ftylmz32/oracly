import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { AppLanguage } from '../src/ai/app-language.js';
import type { DreamAcceptanceInput } from '../src/ai/dream-acceptance.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { PHASE4C_ARTIFACT_PATH } from '../scripts/dream-phase4c/analyze.js';
import { acceptanceInput } from '../scripts/dream-phase4c/stages.js';

/** Read-only view of the frozen Phase 4C live artifact (never written here). */
export type FrozenRun = {
  runId: string;
  caseId: string;
  language: AppLanguage;
  narrative: string;
  symbols: string[];
  emotions: string[];
  memorySummary: string | null;
  history: DreamHistoryItem[] | null;
  rawProviderText: string;
  backendFinal: 'PASS' | 'REJECT';
  stages: {
    parsed: DreamData;
    outputSafety: string;
    phase2: string;
    phase4A: string;
    phase4B: string;
    diagnostic: { phase2: string; phase4A: string; phase4B: string };
  };
};

export const frozenRuns: FrozenRun[] = JSON.parse(readFileSync(PHASE4C_ARTIFACT_PATH, 'utf8')).runs;

export const frozen = (id: string): FrozenRun => frozenRuns.find((r) => r.runId === id)!;

export function frozenInput(r: FrozenRun): DreamAcceptanceInput {
  return acceptanceInput(
    {
      narrative: r.narrative,
      symbols: r.symbols,
      emotions: r.emotions,
      history: r.history ?? undefined,
      memorySummary: r.memorySummary ?? undefined,
    },
    r.language,
  );
}

export const proseOf = (d: DreamData) => [d.summary, d.emotionalTheme, d.interpretation, d.dailyLifeReflection, d.conclusion];

export const feelingsOf = (r: FrozenRun) => {
  const i = frozenInput(r);
  return [i.narrative, ...i.emotions].join('. ');
};

type PayloadRow = { id: string; payload: Record<string, unknown> };
const payloads: PayloadRow[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./fixtures/dream-phase4c-payloads.json', import.meta.url)), 'utf8'),
).requests;

/** The exact client request payload the live run sent for [caseId]. */
export const frozenPayload = (caseId: string) => payloads.find((p) => p.id === caseId)!.payload;
