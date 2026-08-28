import type { AppConfig } from '../config.js';
import { resolveModel } from '../config.js';
import { ErrorCode, fail } from '../errors.js';
import type { OpenAiFetch } from '../types.js';
import { coffeePayloadFromUnknown } from './image.js';
import { OpenAiTransport } from './openai-transport.js';
import { parsePalmData } from './parse-palm.js';
import {
  extractChatText,
  parseCoffeeData,
  parseDreamData,
} from './parse-provider.js';
import { palmMessages } from './palm-prompts.js';
import {
  chatMessages,
  coffeeMessages,
  dreamMessages,
  oracleMessages,
} from './prompts.js';
import { buildSoulmateImagePrompt } from './soulmate-prompt.js';
import { requestOpenAiSpeech } from './openai-speech.js';
import type { ValidatedRequest } from './validate-request.js';

export class AiProxyService {
  private readonly transport: OpenAiTransport;
  private readonly fetchImpl: OpenAiFetch;

  constructor(
    private readonly config: AppConfig,
    fetchImpl?: OpenAiFetch,
  ) {
    this.fetchImpl = fetchImpl ?? fetch;
    this.transport = new OpenAiTransport(config, this.fetchImpl);
  }

  async handle(
    request: ValidatedRequest,
    modelHint: unknown,
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
        return this.coffee(request, model);
      case 'palm_analysis':
        return this.palm(request, model);
      case 'soulmate_draw':
        return this.soulmate(request);
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
    model: string,
  ) {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const image = coffeePayloadFromUnknown(request.payload, this.config);
    const raw = await this.transport.complete({
      model,
      jsonMode: true,
      messages: coffeeMessages(image.mimeType, image.bytes.toString('base64'), request.language),
    });
    return parseCoffeeData(raw);
  }

  private async palm(
    request: Extract<ValidatedRequest, { operation: 'palm_analysis' }>,
    model: string,
  ) {
    if (!this.config.openaiVision) fail(ErrorCode.imageAnalysisUnavailable);
    const image = coffeePayloadFromUnknown(request.payload, this.config);
    const hand =
      typeof request.payload.hand === 'string' ? request.payload.hand : '';
    const raw = await this.transport.complete({
      model,
      jsonMode: true,
      messages: palmMessages(
        image.mimeType,
        image.bytes.toString('base64'),
        hand,
        request.language,
      ),
    });
    return parsePalmData(raw);
  }

  private async soulmate(
    request: Extract<ValidatedRequest, { operation: 'soulmate_draw' }>,
  ) {
    const built = buildSoulmateImagePrompt({
      name: request.name,
      birthDate: request.birthDate,
      gender: request.gender,
      intention: request.intention,
    });
    const image = await this.transport.generateImage(built.prompt, {
      size: '1024x1536',
    });
    return {
      imageBase64: image.imageBase64,
      mimeType: image.mimeType,
      operation: 'soulmate_draw',
    };
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
