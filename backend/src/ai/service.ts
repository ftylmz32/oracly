import type { AppConfig } from '../config.js';
import { resolveModel } from '../config.js';
import { ErrorCode, fail } from '../errors.js';
import type { OpenAiFetch } from '../types.js';
import { OpenAiTransport } from './openai-transport.js';
import { extractChatText, parseDreamData, parseTarotData } from './parse-provider.js';
import {
  chatMessages,
  dreamMessages,
  oracleMessages,
} from './prompts.js';
import { tarotMessages } from './tarot-style.js';
import { buildSoulmateImagePrompt } from './soulmate-prompt.js';
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

  constructor(
    private readonly config: AppConfig,
    fetchImpl?: OpenAiFetch,
  ) {
    this.fetchImpl = fetchImpl ?? fetch;
    this.transport = new OpenAiTransport(config, this.fetchImpl);
    this.reading = new ReadingPipeline(config, this.transport);
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
      case 'tarot_analysis':
        return this.tarot(request, model);
      case 'coffee_analysis':
        return this.coffee(request, ctx);
      case 'palm_analysis':
        return this.palm(request, ctx);
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

  private async tarot(
    request: Extract<ValidatedRequest, { operation: 'tarot_analysis' }>,
    model: string,
  ) {
    const raw = await this.transport.complete({
      model,
      jsonMode: true,
      messages: tarotMessages(request.payload, request.language),
      temperature: 0.68,
    });
    return parseTarotData(raw);
  }

  private async coffee(
    request: Extract<ValidatedRequest, { operation: 'coffee_analysis' }>,
    ctx?: AiHandleContext,
  ) {
    return this.reading.coffee(request.payload, {
      identity: ctx?.identity ?? 'anon',
      parentKey: ctx?.parentKey ?? `coffee:${Date.now()}`,
      language: request.language,
    });
  }

  private async palm(
    request: Extract<ValidatedRequest, { operation: 'palm_analysis' }>,
    ctx?: AiHandleContext,
  ) {
    return this.reading.palm(request.payload, {
      identity: ctx?.identity ?? 'anon',
      parentKey: ctx?.parentKey ?? `palm:${Date.now()}`,
      language: request.language,
    });
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
      size: this.config.openaiImageSize,
      quality: this.config.openaiImageQuality,
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
