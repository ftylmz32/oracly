/**
 * V3N1 — Coffee V3 NARRATIVE processing path (versioned successor of the
 * frozen M2 → W2 → W4 chain, which stays intact and tested on its own).
 *
 *   3 staged views → the SAME observer call + acceptance + frozen mark map
 *   → planCoffeeV3Narrative (grounded claims, cross-view dedup, saucer only
 *     when physically supported, honest insufficient)
 *   → V3N1 narrative writer (separately pinned prompt, same model pins)
 *   → deterministic quality acceptance (thin / padded / repetitive / generic /
 *     unsupported / contradictory / certain readings are rejected)
 *   → v3_narrative_v1 result
 *
 * Fail-closed exactly like the M2 path: `invalid` = not enough grounded
 * evidence in the photos, `unavailable` = provider / contract defect. At most
 * two byte-identical writer requests (one blind re-sample, never a repair).
 */
import { createHash } from 'node:crypto';
import type { AppConfig } from '../../config.js';
import type { ReadingLanguage } from '../../reading/operation-model.js';
import type { CoffeeV3StagedSlot } from '../../reading/operation-staged-image-model.js';
import { classifyCoffeeIntention } from './coffee-intention-context.js';
import {
  COFFEE_V3_MAX_WRITER_COMPLETIONS,
  FROZEN_COFFEE_M2_WRITER_MODEL,
  FROZEN_COFFEE_M2_WRITER_REASONING,
  assertCoffeeV3ModelPins,
  observeAndMapCoffeeV3WithAdjustments,
  terminal,
  type StageStore,
  type Transport,
} from './coffee-v3-live-pipeline.js';
import { planCoffeeV3Narrative } from './coffee-v3n-narrative-plan.js';
import {
  COFFEE_V3N_WRITER_PROMPT,
  type CoffeeV3NFailure,
  type CoffeeV3NFinding,
  type CoffeeV3NMetrics,
  acceptCoffeeV3Narrative,
  coffeeV3NWriterPayload,
  coffeeV3NWriterPromptSha256,
  coffeeV3NWriterUserMessage,
} from './coffee-v3n-narrative-writer.js';

/** The V3N1 writer contract bytes (separate from the frozen W4 sha bc1b618b…). */
export const FROZEN_COFFEE_V3N_PROMPT_SHA256 = 'b6c9b1bf8c7af54d2f2463ad510f4f19aa591e10d2d47068ca654fb13c1d4d20';
export const COFFEE_V3N_RESULT_CONTRACT = 'v3_narrative_v1' as const;
/** Per-operation stage holding the structured reasons each refused writer sample failed. */
export const COFFEE_V3N_WRITER_REJECTIONS_STAGE = 'coffee_v3n_writer_rejections';

export type CoffeeV3NWriterRejection = {
  attempt: number;
  outputSha256: string;
  outputChars: number;
  failures: CoffeeV3NFailure[];
  findings: CoffeeV3NFinding[];
  metrics: CoffeeV3NMetrics | null;
};

export type CoffeeV3NarrativePublicResult = {
  coffeeResultContract: typeof COFFEE_V3N_RESULT_CONTRACT;
  visualObservation: '';
  overall: string;
  love: '';
  career: '';
  money: '';
  nearFuture: '';
  takeaway: '';
  symbols: [];
};

export function toCoffeeV3NarrativePublicResult(reading: string): CoffeeV3NarrativePublicResult {
  return {
    coffeeResultContract: COFFEE_V3N_RESULT_CONTRACT,
    visualObservation: '',
    overall: reading,
    love: '',
    career: '',
    money: '',
    nearFuture: '',
    takeaway: '',
    symbols: [],
  };
}

export async function runCoffeeV3NarrativeReading(input: {
  config: AppConfig;
  transport: Transport;
  stageStore: StageStore;
  images: ReadonlyArray<{ slot: CoffeeV3StagedSlot; mimeType: string; bytes: Buffer }>;
  intention: string;
  language: ReadingLanguage;
  identity: string;
  parentKey: string;
  /** Test seam only; production always uses the pinned hash. */
  expectedPromptSha256?: string;
}): Promise<CoffeeV3NarrativePublicResult> {
  // Turkish only (no translation, no fallback writer).
  if (input.language !== 'tr') terminal('unavailable', 'language_not_supported');
  if (coffeeV3NWriterPromptSha256() !== (input.expectedPromptSha256 ?? FROZEN_COFFEE_V3N_PROMPT_SHA256)) {
    terminal('unavailable', 'v3n_prompt_hash_mismatch');
  }
  const { vision } = assertCoffeeV3ModelPins(input.config);
  const { map, unresolvedIdentityMarks } = await observeAndMapCoffeeV3WithAdjustments({ ...input, vision });

  // A mark whose identity question the observer left unresolved is told softly.
  const plan = planCoffeeV3Narrative(map, classifyCoffeeIntention(input.intention), { softMarks: unresolvedIdentityMarks });
  if (plan.status !== 'planned') terminal('invalid', `v3n_${plan.reason ?? 'insufficient'}`);

  const user = coffeeV3NWriterUserMessage(coffeeV3NWriterPayload(plan));
  const rejections: CoffeeV3NWriterRejection[] = [];
  for (let attempt = 0; attempt < COFFEE_V3_MAX_WRITER_COMPLETIONS; attempt += 1) {
    // Byte-identical request on the re-sample: no feedback, no prior output.
    const raw = await input.transport.complete({
      model: FROZEN_COFFEE_M2_WRITER_MODEL,
      messages: [
        { role: 'system', content: COFFEE_V3N_WRITER_PROMPT },
        { role: 'user', content: user },
      ],
      reasoningEffort: FROZEN_COFFEE_M2_WRITER_REASONING,
      temperature: undefined,
      jsonMode: true,
    });
    const accepted = acceptCoffeeV3Narrative(plan, raw);
    if (accepted.ok) return toCoffeeV3NarrativePublicResult(accepted.reading);
    // Safe diagnosis of WHY this sample was refused: codes, paragraph / claim
    // attribution and matched terms only — never the text (its sha256 lets a
    // reviewer correlate), never a secret, photo or personal datum.
    rejections.push({
      attempt: attempt + 1,
      outputSha256: createHash('sha256').update(raw, 'utf8').digest('hex'),
      outputChars: raw.length,
      failures: accepted.failures,
      findings: accepted.findings,
      metrics: accepted.metrics,
    });
    input.stageStore.set(input.identity, input.parentKey, COFFEE_V3N_WRITER_REJECTIONS_STAGE, rejections);
  }
  // The terminal reason carries the refused codes per attempt (logged by the worker).
  return terminal('unavailable', `v3n_quality_gates_failed:${rejections.map((r) => `a${r.attempt}=${r.failures.join('+')}`).join(';')}`);
}
