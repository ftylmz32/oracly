import type { AppConfig } from '../config.js';
import { resolveModel } from '../config.js';
import { ErrorCode, fail } from '../errors.js';
import type { OpenAiFetch } from '../types.js';
import { coffeePayloadFromUnknown, type CoffeeImage } from './image.js';
import { OpenAiTransport } from './openai-transport.js';
import { ReadingOperationError } from '../reading/operation-service.js';
import type { ReadingStagedImageService } from '../reading/operation-staged-image-service.js';
import { extractChatText, parseDreamData } from './parse-provider.js';
import {
  chatMessages,
  dreamMessages,
  oracleMessages,
} from './prompts.js';
import {
  buildSoulmateImagePrompt,
  newSoulmateNonce,
  nextSoulmateRenderNonce,
  publicSoulmateIdentity,
} from './soulmate-prompt.js';
import { SOULMATE_MAX_IMAGE_CALLS, coreSignature } from './soulmate-portrait-identity.js';
import {
  contentHashOf,
  ownerHashOf,
  soulmateUniquenessIndex,
} from './soulmate-uniqueness-index.js';
import {
  acceptSoulmateSections,
  parseSoulmateSections,
  soulmateInterpretationMessages,
} from './soulmate-interpretation.js';
import { tarotMessages } from './tarot-prompts.js';
import { narrativeTarotMessages } from './narrative-tarot-prompts.js';
import { buildNarrativeTarotCompleteOptions } from './narrative-tarot-model.js';
import { parseNarrativeTarotResult } from './narrative-tarot-result.js';
import { yildiznameNarrativeMessages } from './narrative-yildizname-prompts.js';
import { buildYildiznameNarrativeCompleteOptions } from './narrative-yildizname-model.js';
import { parseYildiznameNarrativeResult } from './narrative-yildizname-result.js';
import { requestOpenAiSpeech } from './openai-speech.js';
import type { ValidatedRequest } from './validate-request.js';
import { ReadingPipeline } from './reading/pipeline.js';

export type AiHandleContext = {
  identity: string;
  parentKey: string;
};

export class AiProxyService {
  private readonly transport: OpenAiTransport;
  private readonly fetchImpl: OpenAiFetch;
  private readonly reading: ReadingPipeline;
  private readonly stagedImages: ReadingStagedImageService | null;

  constructor(
    private readonly config: AppConfig,
    fetchImpl?: OpenAiFetch,
    stagedImages?: ReadingStagedImageService | null,
  ) {
    this.fetchImpl = fetchImpl ?? fetch;
    this.transport = new OpenAiTransport(config, this.fetchImpl);
    this.reading = new ReadingPipeline(config, this.transport);
    this.stagedImages = stagedImages ?? null;
  }

  /**
   * BATCH 5I — Coffee/Palm requests carrying an `operationId` resolve their
   * image from the durable GCS stage (server-owned reference, ownership
   * re-checked) instead of an inline `imageBase64` body. Requests without
   * an `operationId` keep the existing inline-bytes path unchanged — this
   * does not duplicate the AI pipeline, only how its input bytes arrive.
   */
  private async resolveReadingImage(
    payload: Record<string, unknown>,
    readingType: 'coffee' | 'palm',
    ctx?: AiHandleContext,
  ): Promise<CoffeeImage> {
    const operationId =
      typeof payload.operationId === 'string' ? payload.operationId : null;
    if (!operationId) {
      return coffeePayloadFromUnknown(payload, this.config);
    }
    if (!this.stagedImages) fail(ErrorCode.noConfiguration);
    const owner = ctx?.identity;
    if (!owner) fail(ErrorCode.unauthorized);
    try {
      return await this.stagedImages.retrieveForProcessing({
        ownerUserId: owner,
        operationId,
        readingType,
      });
    } catch (error) {
      if (error instanceof ReadingOperationError) {
        if (error.code === 'unavailable') fail(ErrorCode.noConfiguration);
        // not_found / forbidden / invalid / conflict — never fabricate
        // input; the caller must recover/retry via the operation itself.
        fail(ErrorCode.invalidImage);
      }
      throw error;
    }
  }

  async handle(
    request: ValidatedRequest,
    modelHint: unknown,
    ctx?: AiHandleContext,
  ): Promise<Record<string, unknown>> {
    if (!this.config.openaiApiKey) fail(ErrorCode.noConfiguration);
    const model = resolveModel(this.config, modelHint);
    switch (request.operation) {
      case 'chat':
        return this.chat(request, model);
      case 'oracle':
        return this.oracle(request, model);
      case 'dream_analysis':
        return this.dream(request, model);
      case 'coffee_analysis':
        return this.coffee(request, ctx);
      case 'palm_analysis':
        return this.palm(request, ctx);
      case 'soulmate_draw':
        return this.soulmate(request, ctx);
      case 'soulmate_interpretation':
        return this.soulmateInterpretation(request, model);
      case 'tarot_reading':
        return this.tarotReading(request, model);
      case 'yildizname_reading':
        return this.yildiznameReading(request, model);
      case 'tts':
        return this.tts(request);
    }
  }

  private async chat(
    request: Extract<ValidatedRequest, { operation: 'chat' }>,
    model: string,
  ) {
    const text = extractChatText(
      await this.transport.complete({
        model,
        messages: chatMessages(
          request.userMessage,
          request.priorUser,
          request.styleHint,
          request.turns,
          request.personality,
          request.language,
          request.depth ?? 'balanced',
          request.spoken ?? false,
        ),
        temperature: 0.72,
      }),
    );
    return { text };
  }

  private async oracle(
    request: Extract<ValidatedRequest, { operation: 'oracle' }>,
    model: string,
  ) {
    const text = extractChatText(
      await this.transport.complete({
        model,
        messages: oracleMessages(
          request.kind,
          request.context,
          request.userMessage,
          request.priorUser,
          request.language,
          request.turns,
          request.personality,
          request.styleHint,
          request.depth ?? 'balanced',
          request.spoken ?? false,
        ),
        temperature: 0.72,
      }),
    );
    return { text };
  }

  private async dream(
    request: Extract<ValidatedRequest, { operation: 'dream_analysis' }>,
    model: string,
  ) {
    const raw = await this.transport.complete({
      model,
      jsonMode: true,
      messages: dreamMessages(request.payload, request.language),
    });
    return parseDreamData(raw);
  }

  private async coffee(
    request: Extract<ValidatedRequest, { operation: 'coffee_analysis' }>,
    ctx?: AiHandleContext,
  ) {
    const pipelineContext = {
      identity: ctx?.identity ?? 'anon',
      parentKey: ctx?.parentKey ?? `coffee:${Date.now()}`,
      language: request.language,
    };
    if (request.payload.readingPhase === 'write') {
      return this.reading.writeCoffee(request.payload, pipelineContext);
    }
    // Coffee V2 (three-photo reading) — additive. Only the direct/default
    // phase (the durable worker's call shape, no readingPhase field) ever
    // checks for V2 slots; the legacy two-phase observe/write split used by
    // older clients is untouched and never sees a V2 operation today.
    const operationId =
      typeof request.payload.operationId === 'string' ? request.payload.operationId : null;
    if (operationId && request.payload.readingPhase == null && this.stagedImages) {
      const owner = ctx?.identity;
      if (owner) {
        const isCoffeeV2 = await this.stagedImages
          .hasAnyCoffeeV2Slot({ ownerUserId: owner, operationId })
          .catch(() => false);
        if (isCoffeeV2) {
          const images = await this.resolveCoffeeV2Images(operationId, owner);
          return this.reading.coffeeV2(images, request.payload, pipelineContext);
        }
      }
    }
    const image = await this.resolveReadingImage(request.payload, 'coffee', ctx);
    if (request.payload.readingPhase === 'observe') {
      return this.reading.observeCoffee(image, pipelineContext);
    }
    return this.reading.coffee(image, request.payload, pipelineContext);
  }

  /** Coffee V2 only — mirrors `resolveReadingImage`'s fail-closed contract. */
  private async resolveCoffeeV2Images(operationId: string, owner: string) {
    if (!this.stagedImages) fail(ErrorCode.noConfiguration);
    try {
      return await this.stagedImages.retrieveCoffeeV2ForProcessing({
        ownerUserId: owner,
        operationId,
      });
    } catch (error) {
      if (error instanceof ReadingOperationError) {
        if (error.code === 'unavailable') fail(ErrorCode.noConfiguration);
        fail(ErrorCode.invalidImage);
      }
      throw error;
    }
  }

  private async palm(
    request: Extract<ValidatedRequest, { operation: 'palm_analysis' }>,
    ctx?: AiHandleContext,
  ) {
    const pipelineContext = {
      identity: ctx?.identity ?? 'anon',
      parentKey: ctx?.parentKey ?? `palm:${Date.now()}`,
      language: request.language,
    };
    if (request.payload.readingPhase === 'write') {
      return this.reading.writePalm(request.payload, pipelineContext);
    }
    const image = await this.resolveReadingImage(request.payload, 'palm', ctx);
    if (request.payload.readingPhase === 'observe') {
      return this.reading.observePalm(image, request.payload, pipelineContext);
    }
    return this.reading.palm(image, request.payload, pipelineContext);
  }

  private async soulmate(
    request: Extract<ValidatedRequest, { operation: 'soulmate_draw' }>,
    ctx?: AiHandleContext,
  ) {
    const accountKey = ctx?.identity?.trim() || 'anon';
    const index = soulmateUniquenessIndex();
    const owner = ownerHashOf(accountKey);
    let nonce = newSoulmateNonce();
    let calls = 0;
    while (calls < SOULMATE_MAX_IMAGE_CALLS) {
      const built = buildSoulmateImagePrompt(
        {
          name: request.name,
          birthDate: request.birthDate,
          gender: request.gender,
          intention: request.intention,
          accountKey,
        },
        nonce,
      );
      const signature = coreSignature(built.core);
      if (index.coreOwnedByOther(owner, signature)) {
        fail(ErrorCode.invalidResponse);
      }
      if (
        built.prompt.includes(built.seed) ||
        (accountKey !== 'anon' && built.prompt.includes(accountKey))
      ) {
        fail(ErrorCode.invalidResponse);
      }
      calls += 1;
      const image = await this.transport.generateImage(built.prompt, {
        size: this.config.openaiImageSize,
        quality: this.config.openaiImageQuality,
      });
      const hash = contentHashOf(Buffer.from(image.imageBase64, 'base64'));
      const decision = index.decide(owner, hash);
      if (decision === 'collision') {
        if (calls >= SOULMATE_MAX_IMAGE_CALLS) break;
        nonce = nextSoulmateRenderNonce(nonce);
        continue;
      }
      index.remember({ owner, contentHash: hash, coreSignature: signature });
      return {
        imageBase64: image.imageBase64,
        mimeType: image.mimeType,
        operation: 'soulmate_draw',
        identity: publicSoulmateIdentity(built.identity, hash),
      };
    }
    fail(ErrorCode.invalidResponse);
  }

  private async soulmateInterpretation(
    request: Extract<ValidatedRequest, { operation: 'soulmate_interpretation' }>,
    model: string,
  ) {
    const input = {
      name: request.name,
      birthDate: request.birthDate,
      gender: request.gender,
      intention: request.intention,
      language: request.language,
      identity: request.identity,
      memorySummary: request.memorySummary,
    };
    let raw = extractChatText(
      await this.transport.complete({
        model,
        jsonMode: true,
        messages: soulmateInterpretationMessages(input),
      }),
    );
    let sections = parseSoulmateSections(raw);
    let reason = sections ? acceptSoulmateSections(sections, input) : 'raw_schema';
    if (reason) {
      raw = extractChatText(
        await this.transport.complete({
          model,
          jsonMode: true,
          messages: soulmateInterpretationMessages(input, reason),
        }),
      );
      sections = parseSoulmateSections(raw);
      reason = sections ? acceptSoulmateSections(sections, input) : 'raw_schema';
    }
    if (!sections || reason) fail(ErrorCode.invalidResponse);
    return {
      operation: 'soulmate_interpretation',
      personality: sections.personality,
      dynamic: sections.dynamic,
      attraction: sections.attraction,
      challenge: sections.challenge,
      meeting: sections.meeting,
      feeling: sections.feeling,
    };
  }

  private async tarotReading(
    request: Extract<ValidatedRequest, { operation: 'tarot_reading' }>,
    model: string,
  ) {
    if (request.mode === 'narrative_v2') {
      const raw = extractChatText(
        await this.transport.complete(
          buildNarrativeTarotCompleteOptions(
            this.config,
            model,
            narrativeTarotMessages(request.narrative, request.language),
          ),
        ),
      );
      return parseNarrativeTarotResult(raw, request.narrative);
    }
    const text = extractChatText(
      await this.transport.complete({
        model,
        messages: tarotMessages(
          {
            cards: request.cards,
            spreadLabel: request.spreadLabel,
            userQuestion: request.userQuestion,
            readingTheme: request.readingTheme,
            journeyHints: request.journeyHints,
          },
          request.language,
        ),
        temperature: 0.72,
      }),
    );
    return { text };
  }

  private async yildiznameReading(
    request: Extract<ValidatedRequest, { operation: 'yildizname_reading' }>,
    model: string,
  ) {
    const raw = extractChatText(
      await this.transport.complete(
        buildYildiznameNarrativeCompleteOptions(
          this.config,
          model,
          yildiznameNarrativeMessages(request.narrative, request.language),
        ),
      ),
    );
    return parseYildiznameNarrativeResult(raw, request.narrative);
  }

  private async tts(
    request: Extract<ValidatedRequest, { operation: 'tts' }>,
  ) {
    const spoken = await requestOpenAiSpeech(this.config, this.fetchImpl, {
      text: request.text,
      personality: request.personality,
      language: request.language,
      voiceId: request.voiceId,
      speechSpeed: request.speechSpeed,
    });
    return {
      audioBase64: spoken.audioBase64,
      mimeType: spoken.mimeType,
      operation: 'tts',
    };
  }
}
