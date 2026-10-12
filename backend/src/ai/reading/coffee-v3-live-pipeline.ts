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
 *   → premium substance floor (integration-owned, see below)
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
import { buildCoffeeV3MarkMap, type CoffeeV3MarkMap } from './coffee-v3-mark-map.js';
import { coffeeV3ObserverSystem, coffeeV3ObserverUser, coffeeV3SlotLabel } from './observer-prompts.js';
import { COFFEE_V3_OBSERVER_SCHEMA } from './schemas.js';
import { COFFEE_V3_CONTRACT, COFFEE_V3_SLOTS, type CoffeeMultiViewObservationV3, type CoffeeV3LiveSlot } from './types.js';

/** The writer contract accepted by W4P5 (3/3 hard gates, 3/3 premium). Integration-owned pins. */
export const FROZEN_COFFEE_M2_PROMPT_SHA256 = 'bc1b618baa26e2e113e995cc3c02f9e09e5e40d844e6c6b35c6880f599cc9e48';
export const FROZEN_COFFEE_M2_WRITER_MODEL = 'gpt-5.6-sol';
export const FROZEN_COFFEE_M2_WRITER_REASONING = 'low' as const;
/** At most one blind re-sample after a gate failure (never a repair prompt). */
export const COFFEE_V3_MAX_WRITER_COMPLETIONS = 2;

/**
 * Integration-owned premium substance floor (not a frozen layer). The frozen
 * writer realizes exactly ONE sentence per planned beat and adds nothing when
 * the plan is thin, so a plan with fewer beats can only become a one- or
 * two-sentence reading — the first real three-photo run delivered exactly
 * that (two generic sentences from structural marks only). Such a plan is an
 * honest terminal `invalid` before any writer call: never padded, never
 * lengthened, never delivered as a premium success. Grounding is unchanged:
 * the floor only refuses, it never licenses a meaning.
 */
export const COFFEE_V3_MIN_PREMIUM_BEATS = 3;
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

export type Transport = { complete(options: OpenAiCompleteOptions): Promise<string> };
export type StageStore = {
  get<T>(identity: string, parent: string, stage: string): T | null;
  set(identity: string, parent: string, stage: string, payload: unknown): void;
};

export const terminal = (failureCode: CoffeeV3FailureCode, reason: string): never => {
  throw new CoffeeV3TerminalFailure(failureCode, reason);
};

/** Pins checked before ANY provider call (prompt bytes, writer model / reasoning, vision model). */
function assertFrozenContract(config: AppConfig, expectedPromptSha256: string): { vision: string } {
  if (coffeeM2WriterPromptSha256() !== expectedPromptSha256) terminal('unavailable', 'prompt_hash_mismatch');
  return assertCoffeeV3ModelPins(config);
}

/** Model pins shared by every V3 writer contract (the prompt pin is per contract). */
export function assertCoffeeV3ModelPins(config: AppConfig): { vision: string } {
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

/** A possible-same pair the integration excluded from identity merging (never merged, never reclassified). */
export type CoffeeV3ExcludedAmbiguity = { marks: [string, string]; kinds: [string, string]; reason: 'cross_kind_not_mergeable' };

/**
 * An observer "possible_same_mark" pair between a residue mark and an
 * observed clear area is self-contradictory: a clear area is the visible
 * absence of residue, so the two can never be one physical mark and no merge
 * can ever follow from the pair. The frozen map treats such a pair as a
 * structural failure; this integration step removes ONLY those pairs (both
 * marks exist, kinds differ) from the identity candidates of a COPY of the
 * observation. Both marks stay exactly as observed (kind, sightings, form).
 * Every other ambiguity — unknown mark, self pair, duplicate — is passed on
 * untouched, so the map still fails closed on it. The original observation
 * (cached per operation) is never modified.
 */
export function excludeCrossKindAmbiguities(obs: CoffeeMultiViewObservationV3): {
  observation: CoffeeMultiViewObservationV3;
  excluded: CoffeeV3ExcludedAmbiguity[];
} {
  const marks = Array.isArray(obs.marks) ? obs.marks : [];
  const kindOf = new Map(marks.map((m) => [m.id, m.kind ?? 'residue']));
  const excluded: CoffeeV3ExcludedAmbiguity[] = [];
  const kept = (Array.isArray(obs.ambiguities) ? obs.ambiguities : []).filter((a) => {
    const [x, y] = Array.isArray(a?.marks) ? a.marks : [];
    if (typeof x !== 'string' || typeof y !== 'string' || x === y) return true;
    const kx = kindOf.get(x);
    const ky = kindOf.get(y);
    if (kx === undefined || ky === undefined || kx === ky) return true;
    excluded.push({ marks: [x, y], kinds: [kx, ky], reason: 'cross_kind_not_mergeable' });
    return false;
  });
  return excluded.length ? { observation: { ...obs, ambiguities: kept }, excluded } : { observation: obs, excluded };
}

/** Per-operation stage recording what the integration excluded before mapping (audit / evidence). */
export const COFFEE_V3_OBSERVATION_ADJUSTMENTS_STAGE = 'coffee_v3_observation_adjustments';

/**
 * Shared V3 observation step: exactly the three staged views → ONE observer
 * call (cached per operation) → integration acceptance → cross-kind identity
 * exclusion (see above) → the frozen deterministic mark map. Returns the map
 * and the marks whose identity question stayed unresolved.
 */
export async function observeAndMapCoffeeV3WithAdjustments(input: {
  config: AppConfig;
  transport: Transport;
  stageStore: StageStore;
  images: ReadonlyArray<{ slot: CoffeeV3StagedSlot; mimeType: string; bytes: Buffer }>;
  identity: string;
  parentKey: string;
  vision: string;
}): Promise<{ map: CoffeeV3MarkMap; unresolvedIdentityMarks: Set<string>; excluded: CoffeeV3ExcludedAmbiguity[] }> {
  return observeAndMap(input, true);
}

/**
 * Map-only form of the shared step for the retired M2 path: the RAW
 * observation goes to the frozen map exactly as before (no cross-kind
 * exclusion), so the M2 path keeps its original outcomes.
 */
export async function observeAndMapCoffeeV3(input: Parameters<typeof observeAndMapCoffeeV3WithAdjustments>[0]): Promise<CoffeeV3MarkMap> {
  return (await observeAndMap(input, false)).map;
}

async function observeAndMap(input: {
  config: AppConfig;
  transport: Transport;
  stageStore: StageStore;
  images: ReadonlyArray<{ slot: CoffeeV3StagedSlot; mimeType: string; bytes: Buffer }>;
  identity: string;
  parentKey: string;
  vision: string;
}, excludeCrossKind: boolean): Promise<{ map: CoffeeV3MarkMap; unresolvedIdentityMarks: Set<string>; excluded: CoffeeV3ExcludedAmbiguity[] }> {
  const vision = input.vision;
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

  const { observation, excluded } = excludeCrossKind ? excludeCrossKindAmbiguities(obs) : { observation: obs, excluded: [] };
  if (excluded.length) input.stageStore.set(input.identity, input.parentKey, COFFEE_V3_OBSERVATION_ADJUSTMENTS_STAGE, { excluded });
  const built = buildCoffeeV3MarkMap(observation);
  if (built.status === 'unusable') terminal('invalid', 'map_unusable');
  if (built.status === 'invalid') terminal('unavailable', `map_invalid:${built.failure}`);
  if (built.status !== 'ok') return terminal('unavailable', 'map_unknown_status');
  return { map: built.map, unresolvedIdentityMarks: new Set(excluded.flatMap((e) => e.marks)), excluded };
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
  const map = await observeAndMapCoffeeV3({ ...input, vision });

  // Trusted, persisted intention only; M2 owns the M1 lane internally.
  const meaning = interpretCoffeeM2(map, classifyCoffeeIntention(input.intention)).meaning;
  if (meaning.diagnostics.capacity === 'insufficient') terminal('invalid', 'm2_insufficient');
  const { plan } = planCoffeeM2Writer(meaning);
  if (plan.status !== 'planned' || plan.beats.length === 0) terminal('invalid', 'w2_insufficient');
  if (plan.beats.length < COFFEE_V3_MIN_PREMIUM_BEATS) terminal('invalid', 'plan_below_premium_floor');

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
