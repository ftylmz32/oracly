import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError } from '../errors.js';
import type { OpenAiFetch } from '../types.js';
import type { ChatPersonality } from './chat-style.js';
import { prepareSpeech } from './speech-script.js';
import { ttsStyle } from './tts-style.js';

const PRIMARY_MODEL = 'gpt-4o-mini-tts-2025-12-15';
const SECONDARY_MODEL = 'gpt-4o-mini-tts';
const FALLBACK_MODEL = 'tts-1-hd';
const MAX_AUDIO_BYTES = 2_500_000;

export async function requestOpenAiSpeech(
  config: AppConfig,
  fetchImpl: OpenAiFetch,
  input: {
    text: string;
    personality?: ChatPersonality;
    language: string;
    voiceId?: string;
    speechSpeed?: string;
  },
): Promise<{ audioBase64: string; mimeType: string }> {
  if (!config.openaiApiKey) {
    throw new ProxyError(ErrorCode.noConfiguration);
  }
  const spoken = prepareSpeech(input.text).replaceAll('...', '\u2026');
  if (!spoken) {
    throw new ProxyError(ErrorCode.invalidRequest);
  }
  const style = ttsStyle(
    input.personality,
    input.language,
    input.voiceId,
    input.speechSpeed,
  );
  const primary = await speechOnce(config, fetchImpl, {
    model: PRIMARY_MODEL,
    voice: style.voice,
    speed: style.speed,
    input: spoken,
    instructions: style.instructions,
  });
  if (primary) return primary;
  const secondary = await speechOnce(config, fetchImpl, {
    model: SECONDARY_MODEL,
    voice: style.voice,
    speed: style.speed,
    input: spoken,
    instructions: style.instructions,
  });
  if (secondary) return secondary;
  const fallback = await speechOnce(config, fetchImpl, {
    model: FALLBACK_MODEL,
    voice: style.hdVoice,
    speed: style.hdSpeed,
    input: spoken,
  });
  if (fallback) return fallback;
  throw new ProxyError(ErrorCode.providerError);
}

async function speechOnce(
  config: AppConfig,
  fetchImpl: OpenAiFetch,
  body: {
    model: string;
    voice: string;
    speed: number;
    input: string;
    instructions?: string;
  },
): Promise<{ audioBase64: string; mimeType: string } | null> {
  const controller = new AbortController();
  const timer = setTimeout(
    () => controller.abort(),
    config.openaiTimeoutMs,
  );
  try {
    const response = await fetchImpl(
      `${config.openaiBaseUrl}/audio/speech`,
      {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.openaiApiKey}`,
        },
        body: JSON.stringify({
          model: body.model,
          voice: body.voice,
          input: body.input,
          speed: body.speed,
          response_format: 'mp3',
          ...(body.instructions
            ? { instructions: body.instructions }
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
    if (response.status === 400) return null;
    if (!response.ok) return null;
    const buffer = Buffer.from(await response.arrayBuffer());
    if (buffer.length < 32 || buffer.length > MAX_AUDIO_BYTES) {
      throw new ProxyError(ErrorCode.invalidResponse);
    }
    return {
      audioBase64: buffer.toString('base64'),
      mimeType: 'audio/mpeg',
    };
  } catch (error) {
    if (error instanceof ProxyError) throw error;
    if (error instanceof Error && error.name === 'AbortError') {
      throw new ProxyError(ErrorCode.timeout, 408);
    }
    if (error instanceof TypeError) {
      throw new ProxyError(ErrorCode.network);
    }
    throw new ProxyError(ErrorCode.providerError);
  } finally {
    clearTimeout(timer);
  }
}
