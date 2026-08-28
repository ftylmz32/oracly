import { createHmac } from 'node:crypto';
import { loadConfig, type AppConfig } from '../src/config.js';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { buildServer } from '../src/server.js';
import type { OpenAiFetch } from '../src/types.js';

export function testConfig(overrides: Record<string, string> = {}): AppConfig {
  return loadConfig({
    APP_ENV: 'development',
    OPENAI_API_KEY: 'sk-test-server-only',
    OPENAI_MODEL: 'gpt-4o',
    OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-4o-mini',
    OPENAI_TIMEOUT_SECONDS: '45',
    OPENAI_VISION: 'true',
    AI_AUTH_REQUIRED: 'true',
    AI_DEV_AUTH_BYPASS: 'false',
    AI_RATE_LIMIT_MAX: '20',
    AI_RATE_LIMIT_WINDOW_MS: '900000',
    AI_MAX_CONCURRENT: '2',
    ...overrides,
  });
}

export async function testApp(
  config: AppConfig,
  fetchImpl: OpenAiFetch = defaultFetch,
  options: { appCheck?: import('../src/auth/app-check.js').AppCheckVerifier } = {},
) {
  const app = await buildServer({
    config,
    fetchImpl,
    logger: false,
    appCheck: options.appCheck,
  });
  return app;
}

export const defaultFetch: OpenAiFetch = async () =>
  jsonResponse({
    choices: [
      {
        message: {
          content: 'Sakin bir nefes al ve bugunu yumusak tut.',
        },
      },
    ],
  });

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

export function openaiText(text: string, status = 200): OpenAiFetch {
  return async () =>
    jsonResponse(
      { choices: [{ message: { content: text } }] },
      status,
    );
}

export function authHeader(token = 'user-access-token'): Record<string, string> {
  return { authorization: `Bearer ${token}`, 'content-type': 'application/json' };
}

export function appCheckHeader(token = 'test-app-check'): Record<string, string> {
  return { 'X-Firebase-AppCheck': token };
}

export { StaticAppCheckVerifier };

export const palmOracleBody = {
  operation: 'oracle',
  payload: {
    userMessage: 'Bu el okumasi bana ne soyluyor?',
    priorUser: [],
    context: {
      kind: 'palm',
      sessionId: 'palm-s1',
      overall: 'Avuc acik ve sakin bir ritim tasiyor.',
      handLabel: 'Sag el',
      heartLine: 'Kalp cizgisi yakinlik temasini tasiyor.',
      headLine: 'Zihin cizgisi karar anlarini hatirlatiyor.',
      lifeLine: 'Yasam cizgisi net; tempo yavas okunuyor.',
      fateLine: 'Yon cizgisi bir sapma ihtimalini ima ediyor.',
      symbols: ['yildiz'],
      themes: ['introspection'],
      takeaway: 'Sakin bir nefes.',
      fullInterpretation: 'Bu okuma sembolik bir yansimadir.',
    },
  },
};

export function signHs256(
  secret: string,
  claims: Record<string, unknown> = {},
): string {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString(
    'base64url',
  );
  const payload = Buffer.from(
    JSON.stringify({
      sub: 'user-1',
      exp: Math.floor(Date.now() / 1000) + 3600,
      ...claims,
    }),
  ).toString('base64url');
  const data = `${header}.${payload}`;
  const sig = createHmac('sha256', secret).update(data).digest('base64url');
  return `${data}.${sig}`;
}

export function fakeJpeg(bytes = 9000): Buffer {
  const buf = Buffer.alloc(bytes, 0x41);
  buf[0] = 0xff;
  buf[1] = 0xd8;
  buf[2] = 0xff;
  return buf;
}

export const chatBody = {
  operation: 'chat',
  model: 'gpt-4o',
  payload: { userMessage: 'Merhaba, bugun nasilsin?', priorUser: [] },
};

export const oracleBody = {
  operation: 'oracle',
  payload: {
    userMessage: 'Bu kart bana ne soyluyor?',
    priorUser: [],
    context: {
      kind: 'tarot',
      sessionId: 's1',
      spreadLabel: 'Tek kart',
      readingTitle: 'Bugun',
      cardsSummary: 'The Moon',
      interpretationSummary: 'Sis ve sezgi.',
    },
  },
};

export const dreamBody = {
  operation: 'dream_analysis',
  payload: {
    narrative: 'Ruyamda uzun bir yilan evden gecti ve sessizce gitti.',
    symbols: ['yilan'],
    emotions: [],
  },
};

export const TINY_PNG_B64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

export function openaiImage(b64 = TINY_PNG_B64, status = 200): OpenAiFetch {
  return async (url) => {
    if (String(url).includes('/images/generations')) {
      return jsonResponse({ data: [{ b64_json: b64 }] }, status);
    }
    return jsonResponse({
      choices: [{ message: { content: 'unused' } }],
    });
  };
}

export const soulmateBody = {
  operation: 'soulmate_draw',
  payload: {
    name: 'Elif',
    birthDate: '1994-03-12',
    gender: 'feminine',
    intention: 'sakin bir portre',
  },
};

export function coffeeBody(image = fakeJpeg()): Record<string, unknown> {
  return {
    operation: 'coffee_analysis',
    payload: {
      mimeType: 'image/jpeg',
      imageBase64: image.toString('base64'),
      byteLength: image.length,
    },
  };
}

export function palmBody(image = fakeJpeg()): Record<string, unknown> {
  return {
    operation: 'palm_analysis',
    payload: {
      mimeType: 'image/jpeg',
      imageBase64: image.toString('base64'),
      byteLength: image.length,
      hand: 'right',
    },
  };
}

export const dreamJson = JSON.stringify({
  ozet: 'Ruya sakin bir gecis hissi tasiyor.',
  semboller: ['yilan'],
  duygusalTema: 'Belirsizlik ve yenilenme.',
  yorum: 'Yilan burada tehdit degil, bir donusum izi olabilir.',
  gunlukYansi: 'Bugun acele etmeden bir adim geri durmak iyi gelir.',
  sonuc: 'Bu ruya bir uyari degil, bir davettir.',
});

export const coffeeJson = JSON.stringify({
  gorselTespit: 'Fincanda daginik ince izler gorunuyor.',
  genelYorum: 'Bu fincan sakin bir duruluk hissi tasiyor.',
  ask: 'Iliskide yumusak bir nefes alani var burada.',
  kariyer: 'Is tarafında acele etmeden ilerlemek iyi gelir.',
  maddiDurum: 'Maddi konularda olculu kalmak faydali olabilir.',
  yakinDonem: 'Yakin donemde sakin bir tempo uygun gorunuyor.',
  sonuc: 'Bugun biraz daha yavas olmak iyi gelir.',
  semboller: [{ ad: 'Kus', anlam: 'Haber', yorum: 'Hafif bir haber hissi.' }],
});

export const palmJson = JSON.stringify({
  genelYapi: 'Avuc acik ve sakin bir ritim tasiyor.',
  yasamCizgisi: 'Yasam cizgisi net; tempo yavas okunuyor.',
  zihinCizgisi: 'Zihin cizgisi karar anlarini hatirlatiyor.',
  kalpCizgisi: 'Kalp cizgisi yakinlik temasini tasiyor.',
  kaderYon: 'Yon cizgisi bir sapma ihtimalini ima ediyor.',
  semboller: ['yildiz'],
  temalar: ['introspection'],
  sonuc: 'Bu okuma sembolik bir yansimadir.',
});
