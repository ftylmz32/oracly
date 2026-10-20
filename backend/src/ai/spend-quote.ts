/**
 * Upper-bound quotes from OpenAI's published standard rates.
 * Micros are 1e-6 USD. This is not an invoice match.
 * Text input is counted as one token per character (over-estimate).
 * Vision images use the published high-detail patch or tile ceiling.
 * Output uses the model's published maximum output tokens.
 */
import type { OpenAiMessage } from '../types.js';

export type SpendQuote = { ceilingMicros: number } | { unpriced: 'unknown_model' | 'unpriced_output' };

const M = 1_000_000;

type TextRate = {
  maxOutput: number;
  input: number;
  output: number;
  longInput?: number;
  longOutput?: number;
  longAt?: number;
  imageTokens: number | null;
};

const TEXT: Record<string, TextRate> = {
  'gpt-4o': { maxOutput: 16_384, input: 2_500_000, output: 10_000_000, imageTokens: 85 + 170 * 8 },
  'gpt-5.6-sol': {
    maxOutput: 128_000,
    input: 4_000_000,
    output: 20_000_000,
    longInput: 8_000_000,
    longOutput: 30_000_000,
    longAt: 272_000,
    imageTokens: 3_000,
  },
  'gpt-6-astra': {
    maxOutput: 128_000,
    input: 10_000_000,
    output: 50_000_000,
    longInput: 20_000_000,
    longOutput: 75_000_000,
    longAt: 272_000,
    imageTokens: 3_000,
  },
};

function micros(units: number, perMillion: number): number {
  return Math.ceil((units * perMillion) / M);
}

function parts(messages: OpenAiMessage[]): { chars: number; images: number } {
  let chars = 0;
  let images = 0;
  for (const message of messages) {
    if (typeof message.content === 'string') {
      chars += message.content.length;
      continue;
    }
    for (const part of message.content) {
      if (part.type === 'text') chars += part.text.length;
      if (part.type === 'image_url') images += 1;
    }
  }
  return { chars, images };
}

export function quoteChat(model: string, messages: OpenAiMessage[]): SpendQuote {
  const rate = TEXT[model];
  if (!rate) return { unpriced: 'unknown_model' };
  const seen = parts(messages);
  if (seen.images > 0 && rate.imageTokens == null) return { unpriced: 'unpriced_output' };
  const inputTokens = seen.chars + seen.images * (rate.imageTokens ?? 0);
  const long = rate.longAt != null && inputTokens > rate.longAt;
  const inputRate = long && rate.longInput ? rate.longInput : rate.input;
  const outputRate = long && rate.longOutput ? rate.longOutput : rate.output;
  return {
    ceilingMicros: micros(inputTokens, inputRate) + micros(rate.maxOutput, outputRate),
  };
}

export function quoteChatActual(
  model: string,
  inputTokens: number,
  outputTokens: number,
): number | null {
  const rate = TEXT[model];
  if (!rate || inputTokens < 0 || outputTokens < 0) return null;
  const long = rate.longAt != null && inputTokens > rate.longAt;
  const inputRate = long && rate.longInput ? rate.longInput : rate.input;
  const outputRate = long && rate.longOutput ? rate.longOutput : rate.output;
  return micros(inputTokens, inputRate) + micros(outputTokens, outputRate);
}

/** gpt-image-2, high, 1024x1536: published 6240 image-output tokens. */
export function quoteImage(model: string, size: string, quality: string, promptChars: number): SpendQuote {
  if (model !== 'gpt-image-2' || size !== '1024x1536' || quality !== 'high') {
    return { unpriced: 'unknown_model' };
  }
  return { ceilingMicros: micros(promptChars, 5_000_000) + micros(6_240, 30_000_000) };
}

export function quoteImageActual(inputTokens: number, outputTokens: number): number | null {
  if (inputTokens < 0 || outputTokens < 0) return null;
  return micros(inputTokens, 5_000_000) + micros(outputTokens, 30_000_000);
}

/** tts-1-hd is priced per character. Mini-TTS audio output has no published ceiling. */
export function quoteSpeech(model: string, chars: number): SpendQuote {
  if (model === 'tts-1-hd') return { ceilingMicros: micros(chars, 30_000_000) };
  return { unpriced: 'unpriced_output' };
}
