import { describe, expect, it } from 'vitest';
import { ttsStyle } from '../src/ai/tts-style.js';
import { prepareSpeech } from '../src/ai/speech-script.js';
import {
  authHeader,
  testApp,
  testConfig,
} from './helpers.js';

const FAKE_MP3 = Buffer.from('ID3fake-oracly-tts-audio-bytes-here!!');

describe('tts', () => {
  it('rejects unauthenticated requests', async () => {
    const app = await testApp(testConfig(), openaiSpeech());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: ttsBody('selam', 'direct'),
    });
    expect(res.statusCode).toBe(401);
    expect(JSON.stringify(res.json()).toLowerCase()).not.toContain('sk-');
    await app.close();
  });

  it('routes authenticated tts to OpenAI speech, not chat', async () => {
    const seen: { url: string; model?: string; voice?: string; input?: string }[] =
      [];
    const fetchImpl: typeof fetch = async (url, init) => {
      const body = JSON.parse(String(init?.body ?? '{}')) as {
        model?: string;
        voice?: string;
        input?: string;
      };
      seen.push({
        url: String(url),
        model: body.model,
        voice: body.voice,
        input: body.input,
      });
      return openaiSpeech()(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: ttsBody('Bugün biraz kararsızım.', 'gentle'),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    expect(res.json().data.mimeType).toBe('audio/mpeg');
    expect(res.json().data.operation).toBe('tts');
    expect(res.json().data.audioBase64).toBe(FAKE_MP3.toString('base64'));
    expect(seen).toHaveLength(1);
    expect(seen[0]?.url).toContain('/audio/speech');
    expect(seen[0]?.url).not.toContain('/chat/completions');
    expect(seen[0]?.model).toBe('gpt-4o-mini-tts-2025-12-15');
    expect(seen[0]?.voice).toBe(ttsStyle('gentle', 'tr', 'warm').voice);
    expect(seen[0]?.input).toBe('Bugün biraz kararsızım.');
    expect(JSON.stringify(res.json())).not.toContain('sk-test');
    expect(JSON.stringify(seen[0])).not.toContain('sk-');
    await app.close();
  });

  it('sends a single think pause, not three stops', async () => {
    const seen: { input?: string }[] = [];
    const fetchImpl: typeof fetch = async (_url, init) => {
      const body = JSON.parse(String(init?.body ?? '{}')) as { input?: string };
      seen.push({ input: body.input });
      return openaiSpeech()(_url, init);
    };
    const app = await testApp(testConfig(), fetchImpl);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: ttsBody(
        'Bir dakika... burada gerçekten ilginç bir şey var.',
        'gentle',
      ),
    });
    expect(res.statusCode).toBe(200);
    expect(seen[0]?.input).toBe(
      'Bir dakika\u2026 burada gerçekten ilginç bir şey var.',
    );
    expect(seen[0]?.input?.includes('...')).toBe(false);
    await app.close();
  });

  it('keeps personality as delivery on four OR identities', () => {
    const ids = ['warm', 'calm', 'deep', 'bright'] as const;
    const voices = ids.map((id) => ttsStyle('gentle', 'tr', id).voice);
    expect(new Set(voices).size).toBe(4);
    expect(ttsStyle('gentle', 'tr', 'warm').voice).toBe(
      ttsStyle('direct', 'tr', 'warm').voice,
    );
    expect(ttsStyle('gentle', 'tr', 'warm').speed).not.toBe(
      ttsStyle('direct', 'tr', 'warm').speed,
    );
    expect(ttsStyle('gentle', 'tr', 'female_natural').voice).toBe(
      ttsStyle('gentle', 'tr', 'warm').voice,
    );
  });

  it('does not speak markdown headings', () => {
    expect(prepareSpeech('### Bugün dikkatimi çeken şey...')).toBe(
      'Bugün dikkatimi çeken şey...',
    );
  });

  it('groups short sentences and keeps a real question', () => {
    const spoken = prepareSpeech(
      'Burada bir yol var. Bir kuş var. Bu haber demek. Yakında olabilir.',
    );
    expect(spoken).toContain('Burada bir yol var, bir kuş var');
    expect(prepareSpeech('Sen olsan ne yapardın?').endsWith('?')).toBe(true);
    expect(prepareSpeech('Selam, bugün nasılsın.').endsWith('?')).toBe(true);
    expect(prepareSpeech('### AŞK')).toContain('Aşk tarafında');
  });

  it('restores Turkish question rise and a paragraph think pause', () => {
    expect(
      prepareSpeech('Gerçekten bunu istiyor musun.').endsWith('?'),
    ).toBe(true);
    expect(prepareSpeech('Bu senin değil mi.').includes('?')).toBe(true);
    expect(prepareSpeech('Onun ismi Ali.').includes('?')).toBe(false);
    const spoken = prepareSpeech(
      'Birinci düşünce burada.\n\nİkinci düşünce ayrı durur.',
    );
    expect(spoken).toContain('...');
    expect(spoken).toContain('Birinci düşünce burada');
  });

  it('keeps fast speech intelligible', () => {
    const normal = ttsStyle('gentle', 'tr', 'warm', 'normal').speed;
    const fast = ttsStyle('gentle', 'tr', 'warm', 'fast').speed;
    const slow = ttsStyle('gentle', 'tr', 'warm', 'slow').speed;
    expect(fast).toBeGreaterThan(normal);
    expect(slow).toBeLessThan(normal);
    expect(fast).toBeLessThanOrEqual(1.15);
    expect(slow).toBeGreaterThanOrEqual(0.85);
  });

  it('speaks as an original OR voice, not phone TTS', () => {
    const ids = ['warm', 'calm', 'deep', 'bright'] as const;
    const lines = ids.map((id) => ttsStyle('mystical', 'tr', id).instructions);
    expect(new Set(lines).size).toBe(4);
    for (const line of lines) {
      expect(line.toLowerCase()).toContain('original');
      expect(line.toLowerCase()).toContain('never imitate');
      expect(line).toMatch(/phone TTS/i);
      expect(line.toLowerCase()).toContain('nasılsın');
      expect(line.toLowerCase()).toContain('metronome');
      expect(line.toLowerCase()).toContain('one presence');
      expect(line.toLowerCase()).not.toMatch(
        /ataturk|adele|freeman|ssml|<speak/,
      );
    }
  });

  it('rejects empty speech text', async () => {
    const app = await testApp(testConfig(), openaiSpeech());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: ttsBody('   ', 'mystical'),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(false);
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });
});

function ttsBody(text: string, personality: string) {
  return {
    operation: 'tts',
    payload: { text, personality, language: 'tr' },
  };
}

function openaiSpeech(): typeof fetch {
  return async () =>
    new Response(FAKE_MP3, {
      status: 200,
      headers: { 'content-type': 'audio/mpeg' },
    });
}
