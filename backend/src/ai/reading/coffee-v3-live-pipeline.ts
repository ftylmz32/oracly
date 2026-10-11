/**
 * LIS2 — DARK Coffee V3 processing path (two cup views + saucer → frozen M2 writer).
 *
 * Reached ONLY through `AiProxyService.coffeeV3`, which only the durable
 * ReadingProcessor calls for an operation whose immutable
 * `coffeeCaptureContract` is 'three_view_v3'. The public /v1/ai route can never
 * select it. Nothing here changes the frozen interpretation stack: it calls the
 * frozen V3 map, M2, W2, W4 realization, prompt and QA gates as they are.
 *
 *   3 staged views (2 cup + saucer) → one V3 observer call → acceptance → buildCoffeeV3MarkMap
 *   → trusted intention → interpretCoffeeM2 → planCoffeeM2Writer
 *   → prepareCoffeeM2TurkishRealization → frozen prompt / model pins
 *   → writer (≤ 2 completions) → parser + scenario validator + checker
 *   → assembleCoffeeM2PublicReading → m2_public_v1 result
 *
 * A reading that cannot honestly be produced is NEVER returned as success:
 * it throws `CoffeeV3TerminalFailure` ('invalid' = the photos / physical signal,
 * 'unavailable' = a provider or contract defect). Transport errors propagate
 * untouched so the existing provider-stage / outcome_unknown machinery owns them.
 */
import type { AppConfig } from '../../config.js';
import type { OpenAiCompleteOptions } from '../openai-transport.js';
import type { OpenAiContentPart } from '../../types.js';
import type { CoffeeV3StagedSlot } from '../../reading/operation-staged-image-model.js';
import type { ReadingLanguage } from '../../reading/operation-model.js';
import { classifyCoffeeIntention } from './coffee-intention-context.js';
import { interpretCoffeeM2 } from './coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from './coffee-m2-writer-beat-plan.js';
import { prepareCoffeeM2TurkishRealization } from './coffee-m2-turkish-realization-policy.js';
import {
  assembleCoffeeM2PublicReading,
  checkCoffeeM2TurkishRealization,
  parseCoffeeM2QaWriterOutput,
  validateCoffeeM2ScenarioSelection,
} from './coffee-m2-turkish-realization-check.js';
import {
  coffeeM2WriterPromptSha256,
  coffeeM2WriterPromptUncoveredFields,
  coffeeM2WriterSystemPrompt,
  coffeeM2WriterUserMessage,
} from './coffee-m2-writer-prompt.js';
import { buildCoffeeV3MarkMap } from './coffee-v3-mark-map.js';
import { coffeeV3ObserverSystem, coffeeV3ObserverUser, coffeeV3SlotLabel } from './observer-prompts.js';
import { COFFEE_V3_OBSERVER_SCHEMA } from './schemas.js';
import { COFFEE_V3_CONTRACT, COFFEE_V3_SLOTS, type CoffeeMultiViewObservationV3, type CoffeeV3LiveSlot } from './types.js';

/** The writer contract accepted by W4P5 (3/3 hard gates, 3/3 premium). Integration-owned pins. */
export const FROZEN_COFFEE_M2_PROMPT_SHA256 = 'bc1b618baa26e2e113e995cc3c02f9e09e5e40d844e6c6b35c6880f599cc9e48';
export const FROZEN_COFFEE_M2_WRITER_MODEL = 'gpt-5.6-sol';
export const FROZEN_COFFEE_M2_WRITER_REASONING = 'low' as const;
/** At most one blind re-sample after a gate failure (never a repair prompt). */
export const COFFEE_V3_MAX_WRITER_COMPLETIONS = 2;
export const COFFEE_V3_OBSERVER_STAGE = 'coffee_v3_observer';

/**
 * Marker for the dedicated Slice 3 client restore path. The legacy client
 * restore (CoffeeReadingParser / CoffeeFortuneComposer) can NOT display this
 * result safely: it needs visualObservation, scrubs text and applies a length
 * floor. Creation stays off by default until Slice 3 lands.
 */
export const COFFEE_V3_RESULT_CONTRACT = 'm2_public_v1' as const;

/** The one explicit staging → semantic view mapping (no inference, no sorting). */
export const COFFEE_V3_STAGED_TO_SEMANTIC_SLOT: Readonly<Record<CoffeeV3StagedSlot, CoffeeV3LiveSlot>> = {
  v3_cup_view_a: 'cup_view_a',
  v3_cup_view_b: 'cup_view_b',
  v3_saucer_view: 'saucer',
};

export type CoffeeV3FailureCode = 'invalid' | 'unavailable';

/** Typed terminal outcome. `reason` is internal telemetry only; never sent to a client. */
export class CoffeeV3TerminalFailure extends Error {
  constructor(
    readonly failureCode: CoffeeV3FailureCode,
    readonly reason: string,
  ) {
    super(`coffee_v3_terminal_${failureCode}`);
    this.name = 'CoffeeV3TerminalFailure';
  }
}

export type CoffeeV3PublicResult = {
  coffeeResultContract: typeof COFFEE_V3_RESULT_CONTRACT;
  visualObservation: '';
  overall: string;
  love: '';
  career: '';
  money: '';
  nearFuture: '';
  takeaway: '';
  symbols: [];
};

/** The versioned result: the exact gated M2 reading in `overall`, nothing visual, no QA metadata. */
export function toCoffeeV3PublicResult(reading: string): CoffeeV3PublicResult {
  return {
    coffeeResultContract: COFFEE_V3_RESULT_CONTRACT,
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

type Transport = { complete(options: OpenAiCompleteOptions): Promise<string> };
type StageStore = {
  get<T>(identity: string, parent: string, stage: string): T | null;
  set(identity: string, parent: string, stage: string, payload: unknown): void;
};

const terminal = (failureCode: CoffeeV3FailureCode, reason: string): never => {
  throw new CoffeeV3TerminalFailure(failureCode, reason);
};

/** Pins checked before ANY provider call (prompt bytes, writer model / reasoning, vision model). */
function assertFrozenContract(config: AppConfig, expectedPromptSha256: string): { vision: string } {
  if (coffeeM2WriterPromptSha256() !== expectedPromptSha256) terminal('unavailable', 'prompt_hash_mismatch');
  if (config.openaiReadingWriterModel !== FROZEN_COFFEE_M2_WRITER_MODEL || !config.openaiAllowedModels.includes(FROZEN_COFFEE_M2_WRITER_MODEL)) {
    terminal('unavailable', 'writer_model_mismatch');
  }
  if (config.openaiReadingReasoningEffort !== FROZEN_COFFEE_M2_WRITER_REASONING) terminal('unavailable', 'writer_reasoning_mismatch');
  const vision = config.openaiReadingVisionModel;
  if (!config.openaiVision || !vision || !config.openaiAllowedModels.includes(vision)) terminal('unavailable', 'vision_unconfigured');
  return { vision: vision! };
}

function parseJson<T>(raw: string): T {
  try {
    return JSON.parse(raw) as T;
  } catch {
    return terminal('unavailable', 'observer_malformed_json');
  }
}

/** Integration-level acceptance around the frozen map (sparse is valid; no minimum mark count). */
function acceptObservation(obs: CoffeeMultiViewObservationV3): void {
  if (!obs || typeof obs !== 'object' || obs.contract !== COFFEE_V3_CONTRACT) terminal('unavailable', 'observer_wrong_contract');
  if (obs.usable !== true) terminal('invalid', 'observer_unusable');
  // Exactly the three live views: no missing, duplicated, retired or phantom view.
  const views = Array.isArray(obs.views) ? obs.views : [];
  const slots: unknown[] = views.map((v) => v?.slot);
  if (views.length !== COFFEE_V3_SLOTS.length || COFFEE_V3_SLOTS.some((s) => slots.filter((x) => x === s).length !== 1)) {
    terminal('unavailable', 'observer_views_malformed');
  }
  if (views.some((v) => v.surfaceVisible !== true || v.focusLightAdequate !== true)) terminal('invalid', 'photo_quality');
}

export async function runCoffeeV3Reading(input: {
  config: AppConfig;
  transport: Transport;
  stageStore: StageStore;
  images: ReadonlyArray<{ slot: CoffeeV3StagedSlot; mimeType: string; bytes: Buffer }>;
  intention: string;
  language: ReadingLanguage;
  identity: string;
  parentKey: string;
  /** Test seam only; production always uses the frozen hash. */
  expectedPromptSha256?: string;
}): Promise<CoffeeV3PublicResult> {
  // Turkish only: the frozen writer was accepted in Turkish (no translation, no fallback writer).
  if (input.language !== 'tr') terminal('unavailable', 'language_not_supported');
  const { vision } = assertFrozenContract(input.config, input.expectedPromptSha256 ?? FROZEN_COFFEE_M2_PROMPT_SHA256);

  // Exactly three distinct staged views, mapped explicitly into canonical semantic order.
  const bySlot = new Map<CoffeeV3LiveSlot, { mimeType: string; bytes: Buffer }>();
  for (const image of input.images) {
    const semantic = COFFEE_V3_STAGED_TO_SEMANTIC_SLOT[image.slot];
    if (!semantic || bySlot.has(semantic)) terminal('unavailable', 'staged_views_malformed');
    bySlot.set(semantic, image);
  }
  if (bySlot.size !== COFFEE_V3_SLOTS.length) terminal('unavailable', 'staged_views_malformed');

  // One observer call, three image parts, each preceded by its slot label.
  let obs = input.stageStore.get<CoffeeMultiViewObservationV3>(input.identity, input.parentKey, COFFEE_V3_OBSERVER_STAGE);
  if (!obs) {
    const content: OpenAiContentPart[] = [];
    for (const slot of COFFEE_V3_SLOTS) {
      const image = bySlot.get(slot)!;
      content.push({ type: 'text', text: coffeeV3SlotLabel(slot) });
      content.push({ type: 'image_url', image_url: { url: `data:${image.mimeType};base64,${image.bytes.toString('base64')}`, detail: 'high' } });
    }
    content.push({ type: 'text', text: coffeeV3ObserverUser() });
    const raw = await input.transport.complete({
      model: vision,
      messages: [
        { role: 'system', content: coffeeV3ObserverSystem() },
        { role: 'user', content },
      ],
      jsonSchema: { name: 'coffee_v3_observation', schema: COFFEE_V3_OBSERVER_SCHEMA },
      reasoningEffort: input.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    obs = parseJson<CoffeeMultiViewObservationV3>(raw);
    input.stageStore.set(input.identity, input.parentKey, COFFEE_V3_OBSERVER_STAGE, obs);
  }
  acceptObservation(obs);

  const built = buildCoffeeV3MarkMap(obs);
  if (built.status === 'unusable') terminal('invalid', 'map_unusable');
  if (built.status === 'invalid') terminal('unavailable', `map_invalid:${built.failure}`);
  if (built.status !== 'ok') return terminal('unavailable', 'map_unknown_status');

  // Trusted, persisted intention only; M2 owns the M1 lane internally.
  const meaning = interpretCoffeeM2(built.map, classifyCoffeeIntention(input.intention)).meaning;
  if (meaning.diagnostics.capacity === 'insufficient') terminal('invalid', 'm2_insufficient');
  const { plan } = planCoffeeM2Writer(meaning);
  if (plan.status !== 'planned' || plan.beats.length === 0) terminal('invalid', 'w2_insufficient');

  const payload = prepareCoffeeM2TurkishRealization(plan);
  if (coffeeM2WriterPromptUncoveredFields(payload).length > 0) terminal('unavailable', 'prompt_field_coverage');

  const system = coffeeM2WriterSystemPrompt();
  const user = coffeeM2WriterUserMessage(payload);
  for (let attempt = 0; attempt < COFFEE_V3_MAX_WRITER_COMPLETIONS; attempt += 1) {
    // Byte-identical request on the re-sample: no feedback, no prior output, no repair prompt.
    const raw = await input.transport.complete({
      model: FROZEN_COFFEE_M2_WRITER_MODEL,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
      reasoningEffort: FROZEN_COFFEE_M2_WRITER_REASONING,
      temperature: undefined,
      jsonMode: true,
    });
    const parsed = parseCoffeeM2QaWriterOutput(raw, payload.beats.length, { requireScenarioItems: true });
    if (!parsed.ok) continue;
    if (validateCoffeeM2ScenarioSelection(payload, parsed.beats.map((b) => b.scenarioItems)).length > 0) continue;
    if (checkCoffeeM2TurkishRealization(payload, parsed.beats.map((b) => b.text)).length > 0) continue;
    return toCoffeeV3PublicResult(assembleCoffeeM2PublicReading(parsed.beats));
  }
  return terminal('unavailable', 'writer_gates_failed');
}
