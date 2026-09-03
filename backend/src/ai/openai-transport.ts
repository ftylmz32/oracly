import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError } from '../errors.js';
import type { OpenAiFetch, OpenAiMessage } from '../types.js';
import { assertGeneratedImageBytes } from './image.js';
import { extractMessageContent } from './extract-message-content.js';

export type OpenAiCompleteOptions = {
  messages: OpenAiMessage[];
  model: string;
  jsonMode?: boolean;
  /** Prefer over jsonMode when the model supports strict JSON Schema. */
  jsonSchema?: { name: string; schema: Record<string, unknown> | object };
  temperature?: number;
  /** gpt-5.6 family — omit when unsupported by the model. */
  reasoningEffort?: 'none' | 'low' | 'medium' | 'high' | 'xhigh' | 'max';
};

export class OpenAiTransport {
  constructor(
    private readonly config: AppConfig,
    private readonly fetchImpl: OpenAiFetch = fetch,
  ) {}

  async complete(options: OpenAiCompleteOptions): Promise<string> {
    if (!this.config.openaiApiKey) {
      throw new ProxyError(ErrorCode.noConfiguration);
    }
    const controller = new AbortController();
    const timer = setTimeout(
      () => controller.abort(),
      this.config.openaiTimeoutMs,
    );
    try {
      const response = await this.fetchImpl(
        `${this.config.openaiBaseUrl}/chat/completions`,
        {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.config.openaiApiKey}`,
          },
          body: JSON.stringify({
            model: options.model,
            messages: options.messages,
            ...(options.temperature !== undefined
              ? { temperature: options.temperature }
              : options.reasoningEffort
                ? {}
                : { temperature: 0.6 }),
            ...(options.reasoningEffort
              ? { reasoning_effort: options.reasoningEffort }
              : {}),
            ...(options.jsonSchema
              ? {
                  response_format: {
                    type: 'json_schema',
                    json_schema: {
                      name: options.jsonSchema.name,
                      strict: true,
                      schema: options.jsonSchema.schema,
                    },
                  },
                }
              : options.jsonMode
                ? { response_format: { type: 'json_object' } }
                : {}),
          }),
        },
      );
      if (response.status === 401 || response.status === 403) {
        throw new ProxyError(ErrorCode.noConfiguration);
      }
      if (response.status === 429) {
        throw new ProxyError(ErrorCode.rateLimited, 429);
      }
      if (response.status === 408) {
        throw new ProxyError(ErrorCode.providerTimeout, 408);
      }
      if (!response.ok) {
        throw await mapHttpFailure(response);
      }
      const body = (await response.json()) as {
        choices?: Array<{ message?: { content?: unknown } }>;
      };
      const content = extractMessageContent(
        body.choices?.[0]?.message?.content,
      );
      if (!content) {
        throw new ProxyError(ErrorCode.invalidResponse);
      }
      return content;
    } catch (error) {
      throw mapTransportError(error);
    } finally {
      clearTimeout(timer);
    }
  }

  async generateImage(
    prompt: string,
    options?: { size?: string; quality?: 'low' | 'medium' | 'high' },
  ): Promise<{ imageBase64: string; mimeType: string }> {
    if (!this.config.openaiApiKey) {
      throw new ProxyError(ErrorCode.noConfiguration);
    }
    const model = this.config.openaiImageModel.trim();
    if (!model) {
      throw new ProxyError(ErrorCode.noConfiguration);
    }
    const controller = new AbortController();
    const timer = setTimeout(
      () => controller.abort(),
      this.config.openaiImageTimeoutMs,
    );
    try {
      // GPT Image models return data[0].b64_json by default.
      // Do NOT send response_format — official gpt-image-* reject it (HTTP 400).
      const response = await this.fetchImpl(
        `${this.config.openaiBaseUrl}/images/generations`,
        {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.config.openaiApiKey}`,
          },
          body: JSON.stringify({
            model,
            prompt,
            n: 1,
            size: options?.size ?? this.config.openaiImageSize,
            quality: options?.quality ?? this.config.openaiImageQuality,
          }),
        },
      );
      if (response.status === 401 || response.status === 403) {
        throw new ProxyError(ErrorCode.noConfiguration);
      }
      if (response.status === 429) {
        throw new ProxyError(ErrorCode.rateLimited, 429);
      }
      if (response.status === 408) {
        throw new ProxyError(ErrorCode.providerTimeout, 408);
      }
      if (!response.ok) {
        throw await mapHttpFailure(response);
      }
      const body = (await response.json()) as {
        data?: Array<{ b64_json?: unknown }>;
      };
      const imageBase64 =
        typeof body.data?.[0]?.b64_json === 'string'
          ? body.data[0].b64_json.trim()
          : '';
      if (!imageBase64) {
        throw new ProxyError(ErrorCode.invalidResponse);
      }
      const checked = assertGeneratedImageBytes(imageBase64, this.config);
      return { imageBase64, mimeType: checked.mimeType };
    } catch (error) {
      throw mapTransportError(error);
    } finally {
      clearTimeout(timer);
    }
  }
}

function mapTransportError(error: unknown): ProxyError {
  if (error instanceof ProxyError) return error;
  if (error instanceof Error && error.name === 'AbortError') {
    return new ProxyError(ErrorCode.providerTimeout, 408);
  }
  if (error instanceof TypeError) {
    return new ProxyError(ErrorCode.network);
  }
  return new ProxyError(ErrorCode.providerError);
}

/** Map provider HTTP failures without leaking raw messages to clients. */
async function mapHttpFailure(response: Response): Promise<ProxyError> {
  try {
    const body = (await response.json()) as {
      error?: { code?: unknown; message?: unknown; type?: unknown };
    };
    const code = String(body.error?.code ?? '').toLowerCase();
    const type = String(body.error?.type ?? '').toLowerCase();
    const message = String(body.error?.message ?? '').toLowerCase();
    if (
      code.includes('moderation') ||
      type.includes('moderation') ||
      message.includes('moderation') ||
      message.includes('safety system') ||
      message.includes('content policy')
    ) {
      return new ProxyError(ErrorCode.moderationBlocked);
    }
    if (
      response.status === 400 &&
      (message.includes('unknown parameter') ||
        message.includes('unsupported') ||
        message.includes('model') ||
        code.includes('invalid'))
    ) {
      // User-correctable / config errors — never auto-retry upstream.
      return new ProxyError(ErrorCode.invalidRequest);
    }
  } catch {
    /* body unreadable — generic provider error */
  }
  return new ProxyError(ErrorCode.providerError);
}
