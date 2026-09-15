/** Production two-stage Coffee/Palm reading pipeline. */

import type { AppConfig } from '../../config.js';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { ErrorCode, fail } from '../../errors.js';
import type { AppLanguage } from '../app-language.js';
import type { CoffeeImage } from '../image.js';
import type { OpenAiTransport } from '../openai-transport.js';
import type { OpenAiContentPart } from '../../types.js';
// Canonical Coffee V2 image order is the SAME single source of truth Phase
// 2A's staging layer already defines -- never re-derived, never sorted.
import { COFFEE_V2_SLOTS as COFFEE_V2_CANONICAL_ORDER } from '../../reading/operation-staged-image-model.js';
import {
  acceptCoffeeObservation,
  acceptCoffeeV2Observation,
  acceptPalmObservation,
  adaptCoffeeV2ForWriter,
  bindCoffeeNarrative,
  bindPalmNarrative,
  narrativeFail,
  observationFail,
  toPublicCoffee,
  toPublicPalm,
  type BindFailure,
} from './evidence-bind.js';
import {
  coffeeObserverSystem,
  coffeeObserverUser,
  coffeeV2ObserverSystem,
  coffeeV2ObserverUser,
  coffeeV2SlotLabel,
  palmObserverSystem,
  palmObserverUser,
} from './observer-prompts.js';
import {
  COFFEE_OBSERVER_SCHEMA,
  COFFEE_V2_OBSERVER_SCHEMA,
  COFFEE_WRITER_SCHEMA,
  PALM_OBSERVER_SCHEMA,
  PALM_WRITER_SCHEMA,
} from './schemas.js';
import { readingStageStore } from './stage-cache.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
  CoffeeV2Observation,
  CoffeeV2SourceSlot,
  PalmNarrative,
  PalmObservation,
} from './types.js';
import {
  coffeeWriterSystem,
  coffeeWriterUser,
  palmWriterSystem,
  palmWriterUser,
  repairWriterSystem,
  repairWriterUser,
} from './writer-prompts.js';
import {
  buildCoffeeWriterPacket,
  buildPalmWriterPacket,
  normalizeTrustedHand,
} from './locale-vocab.js';
import { coffeeRepairFocus } from './coffee-diversity.js';
import { personalizationFromUnknown } from './personalization.js';
import type { ReadingPersonalization } from './types.js';

const EVIDENCE_THEME_RULES: ReadonlyArray<readonly [string, RegExp]> = [
  ['relationship', /relationship|love|heart|partner|connection|ili[sş]ki|a[sş]k|kalp|partner/i],
  ['decision', /decision|choice|crossroad|split|two.direction|karar|se[cç]im|yol ayr/i],
  ['communication', /communication|message|news|conversation|ileti[sş]im|mesaj|haber|konu[sş]/i],
  ['career', /career|work|job|profession|success|kariyer|\biş\b|meslek|ba[sş]ar/i],
  ['change', /change|transition|movement|journey|de[gğ]i[sş]|ge[cç]i[sş]|hareket|yolculuk/i],
  ['wellbeing', /health|energy|vital|rest|sa[gğ]l[ıi]k|enerji|dinlen/i],
];

export function evidenceThemes(
  evidence: ReadonlyArray<{
    description: string;
    resemblance?: string | null;
    confidence?: string;
    visibility?: string;
  }>,
): string[] {
  const text = evidence
    .filter((item) =>
      item.description.trim().length > 0 &&
      item.confidence !== 'low' &&
      item.visibility !== 'uncertain',
    )
    .map((item) => `${item.description} ${item.resemblance ?? ''}`)
    .join(' ');
  if (!text) return [];
  return EVIDENCE_THEME_RULES.filter(([, rule]) => rule.test(text))
    .map(([theme]) => theme)
    .slice(0, 3);
}

export function evidenceBoundPersonalization(
  evidence: ReadonlyArray<{ description: string; resemblance?: string | null }>,
  personalization?: ReadingPersonalization,
): ReadingPersonalization | undefined {
  if (!personalization) return undefined;
  const proven = new Set(evidenceThemes(evidence));
  const themes = (personalization.relevantThemes ?? []).filter((theme) =>
    proven.has(theme.trim().toLowerCase()),
  );
  const memorySummary = themes.length > 0 ? personalization.memorySummary : undefined;
  const result: ReadingPersonalization = {
    ...(personalization.firstName ? { firstName: personalization.firstName } : {}),
    ...(personalization.intention ? { intention: personalization.intention } : {}),
    ...(themes.length > 0 ? { relevantThemes: themes } : {}),
    ...(memorySummary ? { memorySummary } : {}),
  };
  return Object.keys(result).length > 0 ? result : undefined;
}

export type ReadingPipelineContext = {
  identity: string;
  parentKey: string;
  language: AppLanguage;
  trustedHandSide?: 'left' | 'right' | null;
  /** BATCH 3A.1 — optional, bounded personalization; see personalization.ts. */
  personalization?: ReadingPersonalization;
};

function readingModels(config: AppConfig): { vision: string; writer: string } {
  const vision = config.openaiReadingVisionModel;
  const writer = config.openaiReadingWriterModel;
  if (!vision || !writer) fail(ErrorCode.noConfiguration);
  if (
    !config.openaiAllowedModels.includes(vision) ||
    !config.openaiAllowedModels.includes(writer)
  ) {
    fail(ErrorCode.noConfiguration);
  }
  return { vision, writer };
}

function parseJson<T>(raw: string): T {
  try {
    return JSON.parse(raw) as T;
  } catch {
    fail(ErrorCode.invalidResponse);
  }
}

export class ReadingPipeline {
  constructor(
    private readonly config: AppConfig,
    private readonly transport: OpenAiTransport,
  ) {}

  async observeCoffee(
    image: CoffeeImage,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    const obs = await this.runCoffeeObserver(image, ctx, readingModels(this.config).vision, stages);
    const failObs = acceptCoffeeObservation(obs);
    if (failObs) observationFail(failObs, { observation: obs, stage: 'observer' });
    return {
      readingPhase: 'observed',
      relevantThemes: evidenceThemes(obs.evidence),
      observationToken: this.signObservation('coffee', obs, ctx),
    };
  }

  async writeCoffee(
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    const obs = this.verifyObservation<CoffeeObservation>('coffee', payload.observationToken, ctx);
    if (!obs) fail(ErrorCode.invalidResponse);
    const personalization = personalizationFromUnknown(payload);
    const safeCtx = { ...ctx, personalization: evidenceBoundPersonalization(obs.evidence, personalization) };
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    return toPublicCoffee(await this.runCoffeeWriter(obs, safeCtx, readingModels(this.config).writer, stages));
  }

  async observePalm(
    image: CoffeeImage,
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const trusted = normalizeTrustedHand(payload.hand);
    const palmCtx = { ...ctx, trustedHandSide: trusted };
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    const obs = await this.runPalmObserver(image, trusted, palmCtx, readingModels(this.config).vision, stages);
    const failObs = acceptPalmObservation(obs);
    if (failObs) observationFail(failObs, { observation: obs, stage: 'observer' });
    return {
      readingPhase: 'observed',
      relevantThemes: evidenceThemes(obs.evidence),
      observationToken: this.signObservation('palm', obs, ctx),
    };
  }

  async writePalm(
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    const obs = this.verifyObservation<PalmObservation>('palm', payload.observationToken, ctx);
    if (!obs) fail(ErrorCode.invalidResponse);
    const trusted = normalizeTrustedHand(payload.hand);
    const personalization = personalizationFromUnknown(payload);
    const safeCtx = {
      ...ctx,
      trustedHandSide: trusted,
      personalization: evidenceBoundPersonalization(obs.evidence, personalization),
    };
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    return toPublicPalm(await this.runPalmWriter(obs, safeCtx, readingModels(this.config).writer, stages));
  }

  private signObservation(
    type: 'coffee' | 'palm',
    observation: CoffeeObservation | PalmObservation,
    ctx: ReadingPipelineContext,
  ): string {
    const body = Buffer.from(JSON.stringify({
      type, identity: ctx.identity, parentKey: ctx.parentKey,
      expiresAt: Date.now() + 10 * 60 * 1000, observation,
    })).toString('base64url');
    const signature = createHmac('sha256', this.observationSigningKey()).update(body).digest('base64url');
    return `${body}.${signature}`;
  }

  private verifyObservation<T>(
    type: 'coffee' | 'palm',
    raw: unknown,
    ctx: ReadingPipelineContext,
  ): T {
    if (typeof raw !== 'string' || raw.length > 24000) fail(ErrorCode.invalidResponse);
    const [body, supplied] = raw.split('.');
    if (!body || !supplied) fail(ErrorCode.invalidResponse);
    const expected = createHmac('sha256', this.observationSigningKey()).update(body).digest();
    let actual: Buffer;
    try { actual = Buffer.from(supplied, 'base64url'); } catch { fail(ErrorCode.invalidResponse); }
    if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) fail(ErrorCode.invalidResponse);
    let packet: Record<string, unknown>;
    try { packet = JSON.parse(Buffer.from(body, 'base64url').toString('utf8')) as Record<string, unknown>; }
    catch { fail(ErrorCode.invalidResponse); }
    if (packet.type !== type || packet.identity !== ctx.identity || packet.parentKey !== ctx.parentKey ||
        typeof packet.expiresAt !== 'number' || packet.expiresAt < Date.now()) {
      fail(ErrorCode.invalidResponse);
    }
    return packet.observation as T;
  }

  private observationSigningKey(): string {
    const key = this.config.openaiApiKey;
    if (!key) fail(ErrorCode.noConfiguration);
    return key;
  }

  async coffee(
    image: CoffeeImage,
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const models = readingModels(this.config);
    const ctxWithPersonalization = {
      ...ctx,
      personalization: ctx.personalization ?? personalizationFromUnknown(payload),
    };
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    const obs = await this.runCoffeeObserver(image, ctxWithPersonalization, models.vision, stages);
    const failObs = acceptCoffeeObservation(obs);
    if (failObs) observationFail(failObs, { observation: obs, stage: 'observer' });
    const narrative = await this.runCoffeeWriter(obs, ctxWithPersonalization, models.writer, stages);
    return toPublicCoffee(narrative);
  }

  /**
   * Coffee V2 (three-photo reading) — additive, dedicated entry point.
   * ONE multi-image observer call covering all three photos (never three
   * separate observer calls), ONE quality gate, then the SAME unmodified
   * writer legacy Coffee already uses. Never touches `coffee()` above.
   */
  async coffeeV2(
    images: Array<{ slot: CoffeeV2SourceSlot; mimeType: string; bytes: Buffer }>,
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const models = readingModels(this.config);
    const ctxWithPersonalization = {
      ...ctx,
      personalization: ctx.personalization ?? personalizationFromUnknown(payload),
    };
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    const obs = await this.runCoffeeV2Observer(images, ctxWithPersonalization, models.vision, stages);
    const failObs = acceptCoffeeV2Observation(obs);
    if (failObs) observationFail(failObs, { observation: obs, stage: 'observer' });
    const narrative = await this.runCoffeeWriter(
      adaptCoffeeV2ForWriter(obs),
      ctxWithPersonalization,
      models.writer,
      stages,
    );
    return toPublicCoffee(narrative);
  }

  async palm(
    image: CoffeeImage,
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const models = readingModels(this.config);
    const trusted = normalizeTrustedHand(payload.hand);
    const ctxPalm = {
      ...ctx,
      trustedHandSide: trusted,
      personalization: ctx.personalization ?? personalizationFromUnknown(payload),
    };
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    const obs = await this.runPalmObserver(image, trusted, ctxPalm, models.vision, stages);
    const failObs = acceptPalmObservation(obs);
    if (failObs) observationFail(failObs, { observation: obs, stage: 'observer' });
    const narrative = await this.runPalmWriter(obs, ctxPalm, models.writer, stages);
    return toPublicPalm(narrative);
  }

  private async runCoffeeObserver(
    image: { mimeType: string; bytes: Buffer },
    ctx: ReadingPipelineContext,
    model: string,
    stages: Array<{ stage: string; cached: boolean; violation?: string }>,
  ): Promise<CoffeeObservation> {
    const cached = readingStageStore.get<CoffeeObservation>(
      ctx.identity,
      ctx.parentKey,
      'coffee_observer',
    );
    if (cached) {
      stages.push({ stage: 'observer', cached: true });
      return cached;
    }
    const raw = await this.transport.complete({
      model,
      messages: [
        { role: 'system', content: coffeeObserverSystem() },
        {
          role: 'user',
          content: [
            { type: 'text', text: coffeeObserverUser() },
            {
              type: 'image_url',
              image_url: {
                url: `data:${image.mimeType};base64,${image.bytes.toString('base64')}`,
                detail: 'high',
              },
            },
          ],
        },
      ],
      jsonSchema: {
        name: 'coffee_observation',
        schema: COFFEE_OBSERVER_SCHEMA,
      },
      reasoningEffort: this.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    const obs = parseJson<CoffeeObservation>(raw);
    readingStageStore.set(ctx.identity, ctx.parentKey, 'coffee_observer', obs);
    stages.push({ stage: 'observer', cached: false });
    return obs;
  }

  /**
   * ONE vision call, exactly three image_url content parts, in the
   * permanently locked canonical order cup_primary -> cup_secondary ->
   * saucer -- constructed explicitly here, never from storage/query order.
   */
  private async runCoffeeV2Observer(
    images: Array<{ slot: CoffeeV2SourceSlot; mimeType: string; bytes: Buffer }>,
    ctx: ReadingPipelineContext,
    model: string,
    stages: Array<{ stage: string; cached: boolean; violation?: string }>,
  ): Promise<CoffeeV2Observation> {
    const cached = readingStageStore.get<CoffeeV2Observation>(
      ctx.identity,
      ctx.parentKey,
      'coffee_v2_observer',
    );
    if (cached) {
      stages.push({ stage: 'observer', cached: true });
      return cached;
    }
    const byslot = new Map(images.map((image) => [image.slot, image]));
    const content: OpenAiContentPart[] = [];
    for (const slot of COFFEE_V2_CANONICAL_ORDER) {
      const image = byslot.get(slot);
      if (!image) fail(ErrorCode.invalidImage);
      content.push({ type: 'text', text: coffeeV2SlotLabel(slot) });
      content.push({
        type: 'image_url',
        image_url: {
          url: `data:${image.mimeType};base64,${image.bytes.toString('base64')}`,
          detail: 'high',
        },
      });
    }
    content.push({ type: 'text', text: coffeeV2ObserverUser() });
    const raw = await this.transport.complete({
      model,
      messages: [
        { role: 'system', content: coffeeV2ObserverSystem() },
        { role: 'user', content },
      ],
      jsonSchema: {
        name: 'coffee_v2_observation',
        schema: COFFEE_V2_OBSERVER_SCHEMA,
      },
      reasoningEffort: this.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    const obs = parseJson<CoffeeV2Observation>(raw);
    readingStageStore.set(ctx.identity, ctx.parentKey, 'coffee_v2_observer', obs);
    stages.push({ stage: 'observer', cached: false });
    return obs;
  }

  private async runPalmObserver(
    image: { mimeType: string; bytes: Buffer },
    trusted: 'left' | 'right' | null,
    ctx: ReadingPipelineContext,
    model: string,
    stages: Array<{ stage: string; cached: boolean; violation?: string }>,
  ): Promise<PalmObservation> {
    const cached = readingStageStore.get<PalmObservation>(
      ctx.identity,
      ctx.parentKey,
      'palm_observer',
    );
    if (cached) {
      stages.push({ stage: 'observer', cached: true });
      return cached;
    }
    const raw = await this.transport.complete({
      model,
      messages: [
        { role: 'system', content: palmObserverSystem() },
        {
          role: 'user',
          content: [
            { type: 'text', text: palmObserverUser(trusted ?? '', Boolean(trusted)) },
            {
              type: 'image_url',
              image_url: {
                url: `data:${image.mimeType};base64,${image.bytes.toString('base64')}`,
                detail: 'high',
              },
            },
          ],
        },
      ],
      jsonSchema: {
        name: 'palm_observation',
        schema: PALM_OBSERVER_SCHEMA,
      },
      reasoningEffort: this.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    const obs = parseJson<PalmObservation>(raw);
    readingStageStore.set(ctx.identity, ctx.parentKey, 'palm_observer', obs);
    stages.push({ stage: 'observer', cached: false });
    return obs;
  }

  private async runCoffeeWriter(
    obs: CoffeeObservation,
    ctx: ReadingPipelineContext,
    model: string,
    stages: Array<{ stage: string; cached: boolean; violation?: string }>,
  ): Promise<CoffeeNarrative> {
    const evidenceJson = JSON.stringify(buildCoffeeWriterPacket(obs, ctx.language, ctx.personalization));
    const cached = readingStageStore.get<CoffeeNarrative>(
      ctx.identity,
      ctx.parentKey,
      'coffee_writer',
    );
    if (cached) {
      const ok = bindCoffeeNarrative(cached, obs, ctx.language, ctx.personalization);
      if (!ok) {
        stages.push({ stage: 'writer', cached: true });
        return cached;
      }
    }
    const raw = await this.transport.complete({
      model,
      messages: [
        { role: 'system', content: coffeeWriterSystem(ctx.language) },
        { role: 'user', content: coffeeWriterUser(evidenceJson) },
      ],
      jsonSchema: { name: 'coffee_narrative', schema: COFFEE_WRITER_SCHEMA },
      reasoningEffort: this.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    let narrative = parseJson<CoffeeNarrative>(raw);
    readingStageStore.set(ctx.identity, ctx.parentKey, 'coffee_writer', narrative);
    stages.push({ stage: 'writer', cached: false });
    let violation = bindCoffeeNarrative(narrative, obs, ctx.language, ctx.personalization);
    if (!violation) return narrative;
    return this.repairCoffee(obs, narrative, violation, ctx, model, stages);
  }

  private async runPalmWriter(
    obs: PalmObservation,
    ctx: ReadingPipelineContext,
    model: string,
    stages: Array<{ stage: string; cached: boolean; violation?: string }>,
  ): Promise<PalmNarrative> {
    const trusted = ctx.trustedHandSide ?? null;
    const evidenceJson = JSON.stringify(
      buildPalmWriterPacket(obs, ctx.language, trusted, ctx.personalization),
    );
    const cached = readingStageStore.get<PalmNarrative>(
      ctx.identity,
      ctx.parentKey,
      'palm_writer',
    );
    if (cached) {
      const ok = bindPalmNarrative(cached, obs, ctx.language, Boolean(trusted), ctx.personalization);
      if (!ok) {
        stages.push({ stage: 'writer', cached: true });
        return cached;
      }
    }
    const raw = await this.transport.complete({
      model,
      messages: [
        { role: 'system', content: palmWriterSystem(ctx.language) },
        { role: 'user', content: palmWriterUser(evidenceJson) },
      ],
      jsonSchema: { name: 'palm_narrative', schema: PALM_WRITER_SCHEMA },
      reasoningEffort: this.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    let narrative = parseJson<PalmNarrative>(raw);
    readingStageStore.set(ctx.identity, ctx.parentKey, 'palm_writer', narrative);
    stages.push({ stage: 'writer', cached: false });
    let violation = bindPalmNarrative(narrative, obs, ctx.language, Boolean(trusted), ctx.personalization);
    if (!violation) return narrative;
    return this.repairPalm(obs, narrative, violation, ctx, model, stages);
  }

  private async repairCoffee(
    obs: CoffeeObservation,
    rejected: CoffeeNarrative,
    violation: BindFailure,
    ctx: ReadingPipelineContext,
    model: string,
    stages: Array<{ stage: string; cached: boolean; violation?: string }>,
  ): Promise<CoffeeNarrative> {
    if (readingStageStore.repairUsed(ctx.identity, ctx.parentKey)) {
      narrativeFail(violation, { stage: 'repair_already_used' });
    }
    readingStageStore.markRepairUsed(ctx.identity, ctx.parentKey);
    const raw = await this.transport.complete({
      model,
      messages: [
        { role: 'system', content: repairWriterSystem('coffee') },
        {
          role: 'user',
          content: repairWriterUser({
            evidenceJson: JSON.stringify(buildCoffeeWriterPacket(obs, ctx.language, ctx.personalization)),
            rejectedJson: JSON.stringify(rejected),
            violations: [violation],
            guidance:
              violation === 'insight_collapse' || violation === 'section_redundancy'
                ? coffeeRepairFocus(
                    {
                      overall: rejected.overall,
                      nearFuture: rejected.nearFuture,
                      takeaway: rejected.takeaway,
                    },
                    obs.evidence,
                  )
                : undefined,
          }),
        },
      ],
      jsonSchema: { name: 'coffee_narrative', schema: COFFEE_WRITER_SCHEMA },
      reasoningEffort: this.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    const repaired = parseJson<CoffeeNarrative>(raw);
    readingStageStore.set(ctx.identity, ctx.parentKey, 'coffee_writer', repaired);
    stages.push({ stage: 'repair', cached: false, violation });
    const again = bindCoffeeNarrative(repaired, obs, ctx.language, ctx.personalization);
    if (again) narrativeFail(again, { observation: obs, stage: 'repair', priorViolation: violation });
    return repaired;
  }

  private async repairPalm(
    obs: PalmObservation,
    rejected: PalmNarrative,
    violation: BindFailure,
    ctx: ReadingPipelineContext,
    model: string,
    stages: Array<{ stage: string; cached: boolean; violation?: string }>,
  ): Promise<PalmNarrative> {
    if (readingStageStore.repairUsed(ctx.identity, ctx.parentKey)) {
      narrativeFail(violation, { stage: 'repair_already_used' });
    }
    readingStageStore.markRepairUsed(ctx.identity, ctx.parentKey);
    const raw = await this.transport.complete({
      model,
      messages: [
        { role: 'system', content: repairWriterSystem('palm') },
        {
          role: 'user',
          content: repairWriterUser({
            evidenceJson: JSON.stringify(
              buildPalmWriterPacket(obs, ctx.language, ctx.trustedHandSide ?? null, ctx.personalization),
            ),
            rejectedJson: JSON.stringify(rejected),
            violations: [violation],
          }),
        },
      ],
      jsonSchema: { name: 'palm_narrative', schema: PALM_WRITER_SCHEMA },
      reasoningEffort: this.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    const repaired = parseJson<PalmNarrative>(raw);
    readingStageStore.set(ctx.identity, ctx.parentKey, 'palm_writer', repaired);
    stages.push({ stage: 'repair', cached: false, violation });
    const again = bindPalmNarrative(
      repaired,
      obs,
      ctx.language,
      Boolean(ctx.trustedHandSide),
      ctx.personalization,
    );
    if (again) narrativeFail(again, { observation: obs, stage: 'repair', priorViolation: violation });
    return repaired;
  }
}
