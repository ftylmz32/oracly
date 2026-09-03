/** Production two-stage Coffee/Palm reading pipeline. */

import type { AppConfig } from '../../config.js';
import { ErrorCode, fail } from '../../errors.js';
import type { AppLanguage } from '../app-language.js';
import { coffeePayloadFromUnknown } from '../image.js';
import type { OpenAiTransport } from '../openai-transport.js';
import {
  acceptCoffeeObservation,
  acceptPalmObservation,
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
  palmObserverSystem,
  palmObserverUser,
} from './observer-prompts.js';
import {
  COFFEE_OBSERVER_SCHEMA,
  COFFEE_WRITER_SCHEMA,
  PALM_OBSERVER_SCHEMA,
  PALM_WRITER_SCHEMA,
} from './schemas.js';
import { readingStageStore } from './stage-cache.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
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

export type ReadingPipelineContext = {
  identity: string;
  parentKey: string;
  language: AppLanguage;
  trustedHandSide?: 'left' | 'right' | null;
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

  async coffee(
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const models = readingModels(this.config);
    const image = coffeePayloadFromUnknown(payload, this.config);
    const stages: Array<{ stage: string; cached: boolean; violation?: string }> = [];
    const obs = await this.runCoffeeObserver(image, ctx, models.vision, stages);
    const failObs = acceptCoffeeObservation(obs);
    if (failObs) observationFail(failObs, { observation: obs, stage: 'observer' });
    const narrative = await this.runCoffeeWriter(obs, ctx, models.writer, stages);
    return toPublicCoffee(narrative);
  }

  async palm(
    payload: Record<string, unknown>,
    ctx: ReadingPipelineContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const models = readingModels(this.config);
    const image = coffeePayloadFromUnknown(payload, this.config);
    const trusted = normalizeTrustedHand(payload.hand);
    const ctxPalm = { ...ctx, trustedHandSide: trusted };
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
    const evidenceJson = JSON.stringify(buildCoffeeWriterPacket(obs, ctx.language));
    const cached = readingStageStore.get<CoffeeNarrative>(
      ctx.identity,
      ctx.parentKey,
      'coffee_writer',
    );
    if (cached) {
      const ok = bindCoffeeNarrative(cached, obs, ctx.language);
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
    let violation = bindCoffeeNarrative(narrative, obs, ctx.language);
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
      buildPalmWriterPacket(obs, ctx.language, trusted),
    );
    const cached = readingStageStore.get<PalmNarrative>(
      ctx.identity,
      ctx.parentKey,
      'palm_writer',
    );
    if (cached) {
      const ok = bindPalmNarrative(cached, obs, ctx.language, Boolean(trusted));
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
    let violation = bindPalmNarrative(narrative, obs, ctx.language, Boolean(trusted));
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
            evidenceJson: JSON.stringify(buildCoffeeWriterPacket(obs, ctx.language)),
            rejectedJson: JSON.stringify(rejected),
            violations: [violation],
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
    const again = bindCoffeeNarrative(repaired, obs, ctx.language);
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
              buildPalmWriterPacket(obs, ctx.language, ctx.trustedHandSide ?? null),
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
    );
    if (again) narrativeFail(again, { observation: obs, stage: 'repair', priorViolation: violation });
    return repaired;
  }
}
