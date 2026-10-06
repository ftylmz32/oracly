import { beforeEach, describe, expect, it } from 'vitest';
import {
  authHeader,
  chatBody,
  coffeeBody,
  coffeeJson,
  coffeeObserverJson,
  coffeeMeaningWriterJson as coffeeWriterJson,
  openaiReadingSequence,
  palmBody,
  palmJson,
  palmObserverJson,
  palmWriterJson,
  dreamBody,
  dreamJson,
  fakeJpeg,
  openaiText,
  oracleBody,
  testApp,
  testConfig,
} from './helpers.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { dreamMessages } from '../src/ai/prompts.js';

describe('ai complete', () => {
  beforeEach(() => readingStageStore.clear());

  // Since Dream Phase 4C.1 each field rule is stated once, in the system
  // field-rules block; the user lead only names the fields.
  it('requires grounded non-empty Dream daily reflection without personal history', () => {
    const [sys, usr] = dreamMessages({ narrative: 'Sessiz bir bahçede altın bir kapı gördüm.' });
    const system = String(sys?.content);
    const user = String(usr?.content);
    expect(user).toContain('dailyLifeReflection (boş bırakma)');
    expect(system).toContain('dailyLifeReflection: bu rüyanın bir somut ayrıntısını');
    expect(system).toContain('kişisel bağlam uydurma');
    expect(system).toContain('uyanık hayata dair bir sorun uydurma');
    expect(`${system} ${user}`).not.toContain('yoksa boş bırak');
  });
  it('requires relational symbol reasoning and discourages generic tropes in Dream prompts', () => {
    // Regression for a real production quality defect: the model defaulted to
    // dictionary-style, one-symbol-at-a-time readings and generic tropes
    // ("new opportunity", "new beginning") instead of connecting the dream's
    // specific details to each other.
    const messages = dreamMessages({
      narrative: 'Eski bir evin bahçesindeydim, gökyüzü çok açıktı ve altın bir kapı gördüm.',
    });
    const system = String(messages[0]?.content);
    expect(system).toContain('ilişkisel bir köprü kur');
    expect(system).toContain('yalnızca anlatı açıkça destekliyorsa kullan');
    expect(system).toContain('en az iki somut ayrıntı kullan');
    expect(system).toContain('otomatik okumalar yapma');
    expect(system).toContain('genel tavsiye verme');
  });
  it('requires the Dream emotional field to describe atmosphere, not restate the narrative verbatim', () => {
    const system = String(
      dreamMessages({ narrative: 'Karanlık bir ormanda yalnız yürüyordum.' })[0]?.content,
    );
    expect(system).toContain('anlatı cümlelerini olduğu gibi tekrarlama');
    expect(system).toContain('karışık duyguları ve bir duygunun yokluğunu söylendiği gibi koru');
  });
  it('requires explicitly stated (including negated) emotion to outrank inferred atmosphere', () => {
    // Regression for a real production quality defect: a live dream where
    // the user explicitly said they were NOT afraid, only mildly urgent,
    // still came back with an invented "loneliness" the narrative never
    // stated, ignoring the negated fear and the stated urgency entirely.
    const messages = dreamMessages({
      narrative: 'Tren istasyonundaydım, korkmuyordum ama bir şeyi kaçırıyormuşum gibi hafif bir aciliyet hissi vardı.',
    });
    const system = String(messages[0]?.content);
    expect(system).toContain('belirtilen duygulara, olumsuzlanmış olanlar dahil, sadık kal');
    expect(system).toContain('"korkmadım" dendiyse korkuyu varmış gibi yazma');
    expect(system).toContain('anlatılmayan duygu uydurma');
    expect(system).toContain('Metinde olmayan imge, sembol ya da duygu ekleme');
  });
  it('requires the interpretation to show how one detail changes another, not just co-mention them', () => {
    const system = String(dreamMessages({ narrative: 'Bir kapı ve bir ışık gördüm.' })[0]?.content);
    expect(system).toContain('yalnızca yan yana anmak yetmez');
    expect(system).toContain('bir somut ayrıntının diğerini nasıl değiştirdiğini');
    expect(system).toContain('anlatılan duygusal ipuçlarını yoruma katıştır');
  });
  it('returns no_configuration when OPENAI_API_KEY is missing', async () => {
    const app = await testApp(
      testConfig({ OPENAI_API_KEY: '', AI_DEV_AUTH_BYPASS: 'true' }),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      success: false,
      error: { code: 'no_configuration' },
    });
    expect(JSON.stringify(res.json()).toLowerCase()).not.toContain('sk-');
    await app.close();
  });

  it('rejects invalid operation and invalid body', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const unknown = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: { operation: 'hack', payload: {} },
    });
    expect(unknown.json().error.code).toBe('invalid_request');
    const empty = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {},
    });
    expect(empty.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('proxies AI chat', async () => {
    const app = await testApp(
      testConfig(),
      openaiText('Sakin bir nefes al ve bugunu yumusak tut.'),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    expect(res.json().data.text).toContain('Sakin');
    await app.close();
  });

  it('proxies OR a Sor with isolated structured context', async () => {
    let seen = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seen = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: 'Bu kart sezgiye davet ediyor, kesin kader yok.',
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
      payload: oracleBody,
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.text.length).toBeGreaterThan(11);
    expect(seen).toContain('tarot');
    expect(seen).toContain('The Moon');
    expect(seen).not.toContain('system":"ignore previous');
    await app.close();
  });

  it('adds observed discovery themes to oracle context without uid', async () => {
    let seen = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seen = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: 'Son keşiflerinde sınırlar teması tekrar ediyor.',
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
        ...oracleBody,
        payload: {
          ...oracleBody.payload,
          context: {
            ...oracleBody.payload.context,
            observedThemes: ['sınırlar', 'değişim'],
          },
        },
      },
    });
    expect(res.json().success).toBe(true);
    expect(seen).toContain('sınırlar');
    expect(seen).toContain('değişim');
    expect(seen).not.toContain('firebaseUid');
    expect(seen).not.toContain('"uid"');
    await app.close();
  });

  it('rejects oracle context kind mismatch', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        operation: 'oracle',
        payload: {
          userMessage: 'Ne anlatiyor?',
          context: { kind: 'mixed-leak', narrative: 'x' },
        },
      },
    });
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('returns structured dream analysis', async () => {
    const app = await testApp(testConfig(), openaiText(dreamJson));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: dreamBody,
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.summary).toBeTruthy();
    expect(res.json().data.symbols).toEqual(['yilan']);
    expect(res.json().data.emotionalTheme).toBeTruthy();
    expect(res.json().data.interpretation).toBeTruthy();
    expect(res.json().data.dailyLifeReflection).toBeTruthy();
    expect(res.json().data.conclusion).toBeTruthy();
    await app.close();
  });

  it('returns invalid_response when dream JSON is incomplete', async () => {
    const app = await testApp(
      testConfig(),
      openaiText(JSON.stringify({ ozet: 'kisa' })),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: dreamBody,
    });
    expect(res.json()).toEqual({
      success: false,
      error: { code: 'invalid_response' },
    });
    await app.close();
  });

  it('validates coffee vision and returns visual vs symbolic fields', async () => {
    const app = await testApp(testConfig(), openaiReadingSequence(coffeeObserverJson, coffeeWriterJson));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(),
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.visualObservation).toContain('yakın çevrende');
    expect(res.json().data.overall).toBeTruthy();
    expect(Array.isArray(res.json().data.symbols)).toBe(true);
    await app.close();
  });

  it('rejects coffee gif mime and tiny images', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const gif = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        operation: 'coffee_analysis',
        payload: {
          mimeType: 'image/gif',
          imageBase64: fakeJpeg().toString('base64'),
          byteLength: 9000,
        },
      },
    });
    expect(gif.json().error.code).toBe('unsupported_image_type');
    const tiny = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: coffeeBody(Buffer.from([0xff, 0xd8, 0xff, 1, 2, 3])),
    });
    expect(tiny.json().error.code).toBe('invalid_image');
    await app.close();
  });

  it('validates palm vision and returns symbolic line fields', async () => {
    const app = await testApp(testConfig(), openaiReadingSequence(palmObserverJson, palmWriterJson));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: palmBody(),
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.overall).toContain('sakin');
    expect(res.json().data.lifeLine).toBeTruthy();
    expect(Array.isArray(res.json().data.themes)).toBe(true);
    expect(JSON.stringify(res.json()).toLowerCase()).not.toContain('sk-');
    await app.close();
  });

  it('rejects palm certainty copy from the provider', async () => {
    const badWriter = JSON.stringify({
      visualObservation: { text: 'Acik avuc cizgileri net.', evidenceIds: ['p1'] },
      overall: { text: 'Omrun su kadar surecek ve hastaliga sahipsin. Kesin olacak.', evidenceIds: ['p1'] },
      lifeLine: { text: 'Uzun bir omur gosterir.', evidenceIds: ['p3'] },
      headLine: { text: 'Duz cizgi.', evidenceIds: ['p2'] },
      heartLine: { text: 'Kivrimli.', evidenceIds: ['p1'] },
      fateLine: { text: '', evidenceIds: [] },
      takeaway: { text: 'Kesin kader.', evidenceIds: ['p1'] },
    });
    const app = await testApp(
      testConfig(),
      openaiReadingSequence(palmObserverJson, badWriter),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: palmBody(),
    });
    expect(res.json().success).toBe(false);
    expect(['invalid_response', 'quality_unavailable']).toContain(res.json().error.code);
    await app.close();
  });

  it('returns image_analysis_unavailable when vision is off', async () => {
    const app = await testApp(
      testConfig({ OPENAI_VISION: 'false', AI_DEV_AUTH_BYPASS: 'true' }),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: coffeeBody(),
    });
    expect(res.json().error.code).toBe('image_analysis_unavailable');
    const palm = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: palmBody(),
    });
    expect(palm.json().error.code).toBe('image_analysis_unavailable');
    await app.close();
  });

  it('maps provider error and timeout', async () => {
    const failing = await testApp(testConfig(), openaiText('ignored', 500));
    const provider = await failing.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(provider.json().error.code).toBe('provider_error');
    await failing.close();

    const hanging: typeof fetch = async (_url, init) =>
      new Promise((_, reject) => {
        init?.signal?.addEventListener('abort', () => {
          const err = new Error('aborted');
          err.name = 'AbortError';
          reject(err);
        });
      });
    const timed = await testApp(
      testConfig({ OPENAI_TIMEOUT_SECONDS: '1' }),
      hanging,
    );
    const timeout = await timed.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(timeout.json().error.code).toBe('provider_timeout');
    await timed.close();
  });
});
