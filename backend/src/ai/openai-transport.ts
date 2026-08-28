import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError } from '../errors.js';
import type { OpenAiFetch, OpenAiMessage } from '../types.js';
import { extractMessageContent } from './extract-message-content.js';

export type OpenAiCompleteOptions = {
  messages: OpenAiMessage[];
  model: string;
  jsonMode?: boolean;
  temperature?: number;
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
            temperature: options.temperature ?? 0.6,
            messages: options.messages,
            ...(options.jsonMode
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
        throw new ProxyError(ErrorCode.timeout, 408);
      }
      if (!response.ok) {
        throw new ProxyError(ErrorCode.providerError);
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
    options?: { size?: string },
  ): Promise<{ imageBase64: string; mimeType: string }> {
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
        `${this.config.openaiBaseUrl}/images/generations`,
        {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.config.openaiApiKey}`,
          },
          body: JSON.stringify({
            model: IMAGE_MODEL,
            prompt,
            n: 1,
            size: options?.size ?? '1024x1024',
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
        throw new ProxyError(ErrorCode.timeout, 408);
      }
      if (!response.ok) {
        throw new ProxyError(ErrorCode.providerError);
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
      return { imageBase64, mimeType: 'image/png' };
    } catch (error) {
      throw mapTransportError(error);
    } finally {
      clearTimeout(timer);
    }
  }
}

const IMAGE_MODEL = 'gpt-image-2';

function mapTransportError(error: unknown): ProxyError {
  if (error instanceof ProxyError) return error;
  if (error instanceof Error && error.name === 'AbortError') {
    return new ProxyError(ErrorCode.timeout, 408);
  }
  if (error instanceof TypeError) {
    return new ProxyError(ErrorCode.network);
  }
  return new ProxyError(ErrorCode.providerError);
}
