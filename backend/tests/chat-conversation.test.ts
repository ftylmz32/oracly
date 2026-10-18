import { describe, expect, it } from 'vitest';
import { chatSystem, parsePersonality } from '../src/ai/chat-style.js';
import {
  authHeader,
  openaiText,
  testApp,
  testConfig,
} from './helpers.js';

describe('chat conversation memory', () => {
  it('keeps gpt-4o sampling defaults when the OR override is unset', async () => {
    let body: Record<string, unknown> = {};
    const app = await testApp(testConfig(), async (_url, init) => {
      body = JSON.parse(String(init?.body));
      return openaiText('Yanit.')(_url, init);
    });
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: authHeader(),
      payload: { operation: 'chat', model: 'gpt-4o', payload: { userMessage: 'Merhaba.' } },
    });
    expect(res.json().success).toBe(true);
    expect(body).toMatchObject({ model: 'gpt-4o', temperature: 0.72 });
    expect(body).not.toHaveProperty('reasoning_effort');
    await app.close();
  });

  it('uses the allowlisted OR-only sol override without temperature', async () => {
    let body: Record<string, unknown> = {};
    const app = await testApp(
      testConfig({ OPENAI_OR_MODEL: 'gpt-5.6-sol' }),
      async (_url, init) => {
        body = JSON.parse(String(init?.body));
        return openaiText('Yanit.')(_url, init);
      },
    );
    const res = await app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: authHeader(),
      payload: {
        operation: 'chat', model: 'gpt-4o',
        payload: {
          userMessage: 'Ucuncu mesaj.', personality: 'mystical', depth: 'balanced', styleHint: 'samimi',
          turns: [
            { role: 'user', text: 'Ilk mesaj.' },
            { role: 'assistant', text: 'Ilk yanit.' },
            { role: 'user', text: 'Ikinci mesaj.' },
            { role: 'assistant', text: 'Ikinci yanit.' },
          ],
        },
      },
    });
    expect(res.json().success).toBe(true);
    expect(body).toMatchObject({ model: 'gpt-5.6-sol', reasoning_effort: 'none' });
    expect(body).not.toHaveProperty('temperature');
    const messages = body.messages as Array<{ role: string; content: string }>;
    expect(messages.slice(-5)).toEqual([
      { role: 'user', content: 'Ilk mesaj.' },
      { role: 'assistant', content: 'Ilk yanit.' },
      { role: 'user', content: 'Ikinci mesaj.' },
      { role: 'assistant', content: 'Ikinci yanit.' },
      { role: 'user', content: 'Ucuncu mesaj.' },
    ]);
    expect(messages[0].content).toContain('balanced');
    expect(messages[0].content).toContain('samimi');
    await app.close();
  });

  it('ignores an unsupported OR override and does not affect oracle model selection', async () => {
    const bodies: Array<Record<string, unknown>> = [];
    const app = await testApp(
      testConfig({ OPENAI_OR_MODEL: 'unsupported-model' }),
      async (_url, init) => {
        bodies.push(JSON.parse(String(init?.body)));
        return openaiText('Yanit.')(_url, init);
      },
    );
    const chat = await app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: authHeader(),
      payload: { operation: 'chat', model: 'gpt-4o-mini', payload: { userMessage: 'Merhaba.' } },
    });
    const oracle = await app.inject({
      method: 'POST', url: '/v1/ai/complete', headers: authHeader(),
      payload: {
        operation: 'oracle', model: 'gpt-4o-mini',
        payload: { userMessage: 'Yorumla.', context: { kind: 'tarot', sessionId: 's', cardsSummary: 'Ay' } },
      },
    });
    expect(chat.json().success).toBe(true);
    expect(oracle.json().success).toBe(true);
    expect(bodies.map((body) => body.model)).toEqual(['gpt-4o-mini', 'gpt-4o-mini']);
    expect(bodies[0]).toMatchObject({ temperature: 0.72 });
    expect(bodies[1]).toMatchObject({ temperature: 0.72 });
    await app.close();
  });

  it('advances one specific conversational thread instead of generic advice lists in every language', () => {
    expect(chatSystem('tr')).toContain('özgül gerilimi ilerlet');
    expect(chatSystem('tr')).toContain('tek bir canlı düşünce hattı');
    expect(chatSystem('en')).toContain('specific tension');
    expect(chatSystem('en')).toContain('one living thread of thought');
    expect(chatSystem('ru')).toContain('конкретное напряжение');
    expect(chatSystem('ru')).toContain('одну живую линию мысли');
  });

  it('turns a named fear and a one-thought request into conversation-specific continuation', () => {
    expect(chatSystem('tr')).toContain('onu "yaygın" diye genelleme');
    expect(chatSystem('tr')).toContain('Genellikle bu tür bir his');
    expect(chatSystem('en')).toContain('this kind of feeling usually');
    expect(chatSystem('ru')).toContain('обычно такое чувство');
    expect(chatSystem('tr')).toContain('otomatik küçük-adım listelerine dönme');
    expect(chatSystem('tr')).toContain('konuşmadan tek bir düşünce istediğinde');
    expect(chatSystem('en')).toContain('do not generalize it as "common"');
    expect(chatSystem('en')).toContain('asks to leave with one thought');
    expect(chatSystem('ru')).toContain('не объявляй это «обычным»');
    expect(chatSystem('ru')).toContain('просит оставить ему одну мысль');
  });

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
