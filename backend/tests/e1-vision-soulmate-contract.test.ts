import { beforeEach, describe, expect, it } from 'vitest';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { parseCoffeeData } from '../src/ai/parse-provider.js';
import { parsePalmData } from '../src/ai/parse-palm.js';
import {
  evaluateCoffeeQuality,
  evaluatePalmQuality,
} from '../src/ai/human-quality.js';
import { ProxyError, ErrorCode } from '../src/errors.js';
import { loadConfig } from '../src/config.js';
import {
  authHeader,
  coffeeBody,
  coffeeJson,
  coffeeObserverJson,
  coffeeWriterJson,
  openaiReadingSequence,
  fakeJpeg,
  jsonResponse,
  openaiImage,
  openaiText,
  palmBody,
  palmJson,
  palmObserverJson,
  palmWriterJson,
  soulmateBody,
  testApp,
  testConfig,
  TINY_PNG_B64,
} from './helpers.js';

describe('E1 coffee/palm/soulmate contracts', () => {
  beforeEach(() => readingStageStore.clear());
  it('config exposes image model, quality, and image timeout', () => {
    const cfg = loadConfig({
      OPENAI_IMAGE_MODEL: 'gpt-image-2',
      OPENAI_IMAGE_QUALITY: 'low',
      OPENAI_IMAGE_TIMEOUT_SECONDS: '90',
      OPENAI_IMAGE_SIZE: '1024x1536',
    });
    expect(cfg.openaiImageModel).toBe('gpt-image-2');
    expect(cfg.openaiImageQuality).toBe('low');
    expect(cfg.openaiImageTimeoutMs).toBe(90_000);
    expect(cfg.openaiImageSize).toBe('1024x1536');
  });

  it('coffee requires grounded observation and rejects usable:false', () => {
    expect(() => parseCoffeeData(coffeeJson)).not.toThrow();
    expect(() =>
      parseCoffeeData('{"usable":false,"reason":"no cup"}'),
    ).toThrow(ProxyError);
    try {
      parseCoffeeData('{"usable":false,"reason":"no cup"}');
    } catch (e) {
      expect(e).toBeInstanceOf(ProxyError);
      expect((e as ProxyError).code).toBe(ErrorCode.invalidImage);
    }
    expect(() =>
      parseCoffeeData(
        '{"genelYorum":"Generic energy everywhere now.","sonuc":"ok"}',
      ),
    ).toThrow(ProxyError);
  });

  it('palm requires grounded observation and rejects medical certainty', () => {
    expect(() => parsePalmData(palmJson)).not.toThrow();
    expect(() =>
      parsePalmData(
        '{"usable":false,"reason":"closed fist"}',
      ),
    ).toThrow(ProxyError);
    expect(() =>
      parsePalmData(
        '{"gorselTespit":"Acik avuc cizgileri net gorunuyor.","genelYapi":"Omrun kesin olacak ve hastaliga sahipsin.","sonuc":"Kesin."}',
      ),
    ).toThrow(ProxyError);
  });

  it('human-quality harness rejects empty, generic, AI disclosure, certainty', () => {
    expect(
      evaluateCoffeeQuality({
        visualObservation: '',
        overall: '',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: '',
      }),
    ).toBe('empty');
    expect(
      evaluateCoffeeQuality({
        visualObservation: 'Dipte ince daginik izler ve acik alan.',
        overall: 'analysis complete.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'ok',
      }),
    ).toBe('generic');
    expect(
      evaluatePalmQuality({
        visualObservation:
          'Acik sag avuc. Kalp cizgisi hafif kivrimli ve koyu kontrastli; zihin cizgisi duz ve surekli; yasam cizgisi yay cizerek bilege devam ediyor.',
        overall:
          'As an AI I see destiny for you here with a long story about lines and spacing that fills enough words for structural checks.',
        lifeLine: 'Yay cizerek bilege dogru surekli devam ediyor.',
        headLine: 'Ortada duz ve surekli; kalpten aralikli.',
        heartLine: 'Ustte kivrimli ve koyu kontrastli; kisa bitiyor.',
        fateLine: '',
        takeaway: 'Tempo farklarini fark etmek yeterli burada.',
      }),
    ).toBe('ai_disclosure');
  });

  it('rejects unsupported mime and oversized coffee image', async () => {
    const app = await testApp(testConfig(), openaiReadingSequence(coffeeObserverJson, coffeeWriterJson));
    const badMime = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'coffee_analysis',
        payload: {
          mimeType: 'image/gif',
          imageBase64: fakeJpeg().toString('base64'),
        },
      },
    });
    expect(badMime.json().error.code).toBe('unsupported_image_type');
    await app.close();

    const tight = await testApp(
      testConfig({ AI_MAX_IMAGE_BYTES: '9000', AI_MIN_IMAGE_BYTES: '1024' }),
      openaiReadingSequence(coffeeObserverJson, coffeeWriterJson),
    );
    const tooBig = await tight.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(fakeJpeg(12_000)),
    });
    expect(tooBig.json().error.code).toBe('image_too_large');
    await tight.close();
  });

  it('coffee and palm routes succeed with mocked vision JSON', async () => {
    const coffeeApp = await testApp(testConfig(), openaiReadingSequence(coffeeObserverJson, coffeeWriterJson));
    const coffee = await coffeeApp.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(),
    });
    expect(coffee.json().success).toBe(true);
    expect(coffee.json().data.visualObservation).toBeTruthy();
    await coffeeApp.close();

    const palmApp = await testApp(testConfig(), openaiReadingSequence(palmObserverJson, palmWriterJson));
    const palm = await palmApp.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: palmBody(),
    });
    expect(palm.json().success).toBe(true);
    expect(palm.json().data.visualObservation).toContain('avuc');
    await palmApp.close();
  });

  it('soulmate omits response_format and maps moderation / malformed / 401', async () => {
    const seen: Record<string, unknown>[] = [];
    const fetchImpl: typeof fetch = async (url, init) => {
      const body = JSON.parse(String(init?.body ?? '{}')) as Record<
        string,
        unknown
      >;
      seen.push(body);
      return openaiImage()(url, init);
    };
    const okApp = await testApp(testConfig(), fetchImpl);
    const ok = await okApp.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(ok.json().success).toBe(true);
    expect(seen[0]?.response_format).toBeUndefined();
    expect(seen[0]?.quality).toBe('high');
    expect(seen[0]?.model).toBe('gpt-image-2');
    await okApp.close();

    const mod: typeof fetch = async () =>
      jsonResponse(
        {
          error: {
            code: 'moderation_blocked',
            message: 'Request rejected by the safety system',
          },
        },
        400,
      );
    const modApp = await testApp(testConfig(), mod);
    const modRes = await modApp.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(modRes.json().error.code).toBe('moderation_blocked');
    await modApp.close();

    const badB64: typeof fetch = async () =>
      jsonResponse({ data: [{ b64_json: 'not-an-image!!!' }] });
    const badApp = await testApp(testConfig(), badB64);
    const bad = await badApp.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(bad.json().error.code).toBe('invalid_response');
    await badApp.close();

    const unauth: typeof fetch = async () =>
      jsonResponse({ error: { message: 'Incorrect API key' } }, 401);
    const unauthApp = await testApp(testConfig(), unauth);
    const unauthRes = await unauthApp.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(unauthRes.json().error.code).toBe('no_configuration');
    expect(JSON.stringify(unauthRes.json()).toLowerCase()).not.toContain('sk-');
    await unauthApp.close();
  });

  it('rejects unknown top-level request fields', async () => {
    const app = await testApp(testConfig(), openaiText('ok'));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'chat',
        payload: { userMessage: 'Merhaba bugun nasilsin?' },
        openaiApiKey: 'sk-client-forged',
      },
    });
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('does not invent a fake soulmate portrait on chat-only provider', async () => {
    const app = await testApp(testConfig(), openaiText('chat-only'));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(res.json().success).toBe(false);
    expect(res.json().data).toBeUndefined();
    expect(TINY_PNG_B64.length).toBeGreaterThan(8);
    await app.close();
  });
});
