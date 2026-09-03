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
    OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-4o-mini,gpt-5.6-sol',
    OPENAI_READING_VISION_MODEL: 'gpt-5.6-sol',
    OPENAI_READING_WRITER_MODEL: 'gpt-5.6-sol',
    OPENAI_READING_REASONING_EFFORT: 'low',
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
  options: {
    appCheck?: import('../src/auth/app-check.js').AppCheckVerifier;
    billing?: import('../src/billing/types.js').BillingProviders;
  } = {},
) {
  const app = await buildServer({
    config,
    fetchImpl,
    logger: false,
    appCheck: options.appCheck,
    billing: options.billing,
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
  gorselTespit:
    'Agiz kenarinda ince bir telve izi, orta duvarda daha yogun bir kume ve dipte acik bir alan duruyor. Kume kenari kulpa dogru hafif egimli; dipteki aciklikla yan yana duruyorlar. Ust duvarda seyrek bir iz seridi de gorunuyor.',
  genelYorum:
    'Orta duvardaki yogun kume ile dipteki acik alan yan yana okununca, bir toplanma izinin yaninda bir ferahlama alani gibi duruyor. Bu ikisini birlikte dusunmek, kalabalik bir gundemden sonra nefes alacak bir aralik birakma olasiligini cagristirabilir. Agizdaki ince izler henuz netlesmemis bir temasin kiyisina benziyor; kesin bir haber gibi degil. Ustteki seyrek serit ise ayni hikayenin daha hafif bir devamini ima edebilir. Bu fincanda temponun degistigini fark etmek, falin sundugu en sakin yansima olabilir; bir kehanet degil, izlerin yan yana durusuna yaklasik bir okuma.',
  ask: '',
  kariyer: '',
  maddiDurum: '',
  yakinDonem: '',
  sonuc:
    'Yogun kume ile acik dip yan yana: once neyin doldugunu, sonra nereye yer actigini fark etmek yeterli. Tempo farkini hissetmek bu falin sakin hediyesidir.',
  semboller: [{ ad: 'Kus', anlam: 'Haber', yorum: 'Hafif bir haber hissi.' }],
});

export const palmJson = JSON.stringify({
  gorselTespit:
    'Acik bir avuc ici kameraya bakiyor. Kalp cizgisi avuc ustunde hafif kivrimli ve koyu kontrastli; parmak diplerine dogru kisalarak bitiyor. Zihin cizgisi ortada daha duz, surekli ve kalp cizgisinden belirgin aralikla ayriliyor. Yasam cizgisi basparmak kokunden yay cizerek bilege dogru devam ediyor; kopuk gorunmuyor.',
  genelYapi:
    'Kivrimli kalp cizgisi ile duz zihin cizgisinin araligi, duygusal tepki ile dusunme ritminin ayni anda gorunur oldugunu dusunduruyor. Yasam cizgisinin kesiksiz yayi, temposu bozulmayan bir sureklilik izlenimi birakiyor; saglik tahmini degil, sakin bir ritim okumasi.',
  yasamCizgisi:
    'Basparmak kokunden yay cizerek bilege dogru kesiksiz devam ediyor.',
  zihinCizgisi:
    'Ortada duz ve surekli; kalp cizgisinden net aralikla ayriliyor.',
  kalpCizgisi:
    'Ustte hafif kivrimli, koyu kontrastli; parmak diplerine dogru kisalarak bitiyor.',
  kaderYon: '',
  semboller: ['yildiz'],
  temalar: ['introspection'],
  sonuc: 'Kivrim, duzluk ve yay yan yana: tempo farklarini fark etmek yeterli.',
});


export const coffeeObserverJson = JSON.stringify({
  usable: true,
  reason: '',
  checks: {
    cupInteriorVisible: true,
    adequateFocusLight: true,
    residueVisible: true,
    milkFoamObstruction: false,
    usefulRegionsVisible: true,
  },
  evidence: [
    { id: 'e1', region: 'middle_wall', description: 'Dense residue cluster on the middle wall near the handle side.', confidence: 'high', visibility: 'clear', resemblance: 'may resemble a teapot' },
    { id: 'e2', region: 'base', description: 'Open clearer area at the base beside the dense cluster.', confidence: 'high', visibility: 'clear', resemblance: null },
    { id: 'e3', region: 'rim', description: 'Thin residue trail along the rim with lighter density than the middle cluster.', confidence: 'medium', visibility: 'partial', resemblance: null },
  ],
});

export const coffeeWriterJson = JSON.stringify({
  visualObservation: { text: 'Agiz kenarinda ince bir telve izi, orta duvarda daha yogun bir kume ve dipte acik bir alan duruyor. Kume kenari kulpa dogru hafif egimli; dipteki aciklikla yan yana duruyorlar. Ust duvarda seyrek bir iz seridi de gorunuyor.', evidenceIds: ['e1','e2','e3'] },
  overall: { text: 'Orta duvardaki yogun kume ile dipteki acik alan yan yana okununca, bir toplanma izinin yaninda bir ferahlama alani gibi duruyor. Bu ikisini birlikte dusunmek, kalabalik bir gundemden sonra nefes alacak bir aralik birakma olasiligini cagristirabilir. Agizdaki ince izler henuz netlesmemis bir temasin kiyisina benziyor; kesin bir haber gibi degil. Ustteki seyrek serit ise ayni hikayenin daha hafif bir devamini ima edebilir. Bu fincanda temponun degistigini fark etmek, falin sundugu en sakin yansima olabilir; bir kehanet degil, izlerin yan yana durusuna yaklasik bir okuma.', evidenceIds: ['e1','e2','e3'] },
  love: { text: '', evidenceIds: [] },
  career: { text: '', evidenceIds: [] },
  money: { text: '', evidenceIds: [] },
  nearFuture: { text: '', evidenceIds: [] },
  takeaway: { text: 'Yogun kume ile acik dip yan yana: once neyin doldugunu, sonra nereye yer actigini fark etmek yeterli. Tempo farkini hissetmek bu falin sakin hediyesidir.', evidenceIds: ['e1','e2'] },
});

export const palmObserverJson = JSON.stringify({
  usable: true,
  reason: '',
  checks: {
    onePalmFacing: true,
    majorLinesVisible: true,
    adequateFocusLight: true,
    overlapOcclusion: false,
    dorsal: false,
  },
  evidence: [
    { id: 'p1', region: 'heart_line', description: 'Heart line curves mildly across the upper palm with darker contrast and shortens toward the finger bases.', confidence: 'high', visibility: 'clear', resemblance: null },
    { id: 'p2', region: 'head_line', description: 'Head line runs more straight through the mid-palm, continuous, spaced clearly from the heart line.', confidence: 'high', visibility: 'clear', resemblance: null },
    { id: 'p3', region: 'life_line', description: 'Life line arcs from the thumb base toward the wrist without a visible break.', confidence: 'medium', visibility: 'clear', resemblance: null },
  ],
});

export const palmWriterJson = JSON.stringify({
  visualObservation: { text: 'Acik bir avuc ici kameraya bakiyor. Kalp cizgisi avuc ustunde hafif kivrimli ve koyu kontrastli; parmak diplerine dogru kisalarak bitiyor. Zihin cizgisi ortada daha duz, surekli ve kalp cizgisinden belirgin aralikla ayriliyor. Yasam cizgisi basparmak kokunden yay cizerek bilege dogru devam ediyor; kopuk gorunmuyor.', evidenceIds: ['p1','p2','p3'] },
  overall: { text: 'Kivrimli kalp cizgisi ile duz zihin cizgisinin araligi, duygusal tepki ile dusunme ritminin ayni anda gorunur oldugunu dusunduruyor. Yasam cizgisinin kesiksiz yayi, temposu bozulmayan bir sureklilik izlenimi birakiyor; saglik tahmini degil, sakin bir ritim okumasi.', evidenceIds: ['p1','p2','p3'] },
  heartLine: { text: 'Ustte hafif kivrimli, koyu kontrastli; parmak diplerine dogru kisalarak bitiyor.', evidenceIds: ['p1'] },
  headLine: { text: 'Ortada duz ve surekli; kalp cizgisinden net aralikla ayriliyor.', evidenceIds: ['p2'] },
  lifeLine: { text: 'Basparmak kokunden yay cizerek bilege dogru kesiksiz devam ediyor.', evidenceIds: ['p3'] },
  fateLine: { text: '', evidenceIds: [] },
  takeaway: { text: 'Kivrim, duzluk ve yay yan yana: tempo farklarini fark etmek yeterli.', evidenceIds: ['p1','p2','p3'] },
});

/** Two-stage Coffee/Palm fake: observer JSON then writer JSON (optional repair). */
export function openaiReadingSequence(
  observerJson: string,
  writerJson: string,
  repairJson?: string,
): OpenAiFetch {
  let n = 0;
  return async () => {
    n += 1;
    const text = n === 1 ? observerJson : n === 2 ? writerJson : repairJson ?? writerJson;
    return jsonResponse({ choices: [{ message: { content: text } }] });
  };
}
