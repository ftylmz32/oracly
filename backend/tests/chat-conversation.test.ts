import { describe, expect, it } from 'vitest';
import { parsePersonality } from '../src/ai/chat-style.js';
import {
  authHeader,
  openaiText,
  testApp,
  testConfig,
} from './helpers.js';

describe('chat conversation memory', () => {
  it('forwards assistant turns and personality, without secrets', async () => {
    let seen = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seen = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: 'Korku ve değişmek aynı sohbetin iki yüzü.',
              },
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'chat',
        payload: {
          userMessage: 'Değişmek istiyorum ama korkuyorum.',
          priorUser: ['Son zamanlarda iş konusunda kararsızım.'],
          personality: 'direct',
          turns: [
            {
              role: 'user',
              text: 'Son zamanlarda iş konusunda kararsızım.',
            },
            {
              role: 'assistant',
              text: 'Kararsızlığın kalmakla değişmek arasında mı?',
            },
          ],
        },
      },
    });
    expect(res.json().success).toBe(true);
    expect(seen).toContain('"role":"assistant"');
    expect(seen).toContain('kararsızım');
    expect(seen).toContain('İfade DİREKT');
    expect(seen).toContain('Uzunluk tercihi: balanced');
    expect(seen).not.toContain('Kısa yazdıysa');
    expect(seen).not.toContain('sk-');
    expect(seen).not.toContain('Bearer');
    expect(seen.toLowerCase()).not.toContain('authorization');
    await app.close();
  });

  it('maps calm and warm personality aliases', () => {
    expect(parsePersonality('calm')).toBe('gentle');
    expect(parsePersonality('warm')).toBe('poetic');
    expect(parsePersonality('direct')).toBe('direct');
  });

  it('oracle forwards assistant turns personality and shared persona', async () => {
    let seen = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seen = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: 'Kartlar burada bir duraklama anlatiyor.',
              },
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'oracle',
        payload: {
          userMessage: 'Bu kart bende neyi tetikliyor?',
          priorUser: [],
          personality: 'direct',
          depth: 'balanced',
          turns: [
            { role: 'user', text: 'Acilimi anladim ama icime oturmadı.' },
            {
              role: 'assistant',
              text: 'Duraklama hissi one cikiyor.',
            },
          ],
          context: {
            kind: 'tarot',
            sessionId: 's1',
            spreadLabel: 'Tek kart',
            readingTitle: 'Bugun',
            cardsSummary: 'The Moon',
            interpretationSummary: 'Sis ve sezgi.',
          },
        },
      },
    });
    expect(res.json().success).toBe(true);
    expect(seen).toContain('"role":"assistant"');
    expect(seen).toContain('İfade DİREKT');
    expect(seen).toContain('gözlemci');
    expect(seen).toContain('Okuma türü');
    expect(seen).toContain('The Moon');
    await app.close();
  });

  it('chat without turns still answers a lone message', async () => {
    const app = await testApp(
      testConfig(),
      openaiText('Biraz açmak ister misin?'),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'chat',
        payload: { userMessage: 'Bugün biraz tuhaf hissediyorum.' },
      },
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.text).toContain('açmak');
    await app.close();
  });
});
