import { createHmac } from 'node:crypto';
import { loadConfig, type AppConfig } from '../src/config.js';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { buildServer } from '../src/server.js';
import type { OpenAiFetch } from '../src/types.js';
import { MemorySharedWindowStore } from '../src/rate-limit/shared-window-store.js';
import { FirestoreResponseReplayRepository } from '../src/middleware/response-replay-repository.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';

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
    READING_TASK_AUDIENCE: 'https://oracly-test.example',
    ...overrides,
  });
}

export async function testApp(
  config: AppConfig,
  fetchImpl: OpenAiFetch = defaultFetch,
  options: {
    appCheck?: import('../src/auth/app-check.js').AppCheckVerifier;
    billing?: import('../src/billing/types.js').BillingProviders;
    entitlementRepository?: import('../src/billing/entitlement-repository.js').EntitlementBindingRepository;
    readingOperationRepository?: import('../src/reading/operation-repository.js').ReadingOperationRepository;
    readingClock?: import('../src/reading/clock.js').ServerClock;
    readingWaitPolicy?: import('../src/reading/wait-policy.js').WaitPolicy;
    gemLedger?: import('../src/reading/gem-ledger.js').GemLedger;
    readingFlow?: import('../src/reading/reading-flow.js').ReadingFlow;
    readingOperationInputRepository?: import('../src/reading/operation-input-repository.js').ReadingOperationInputRepository;
    rewardedAds?: import('../src/server.js').BuildOptions['rewardedAds'];
    readingStagedImageRepository?: import('../src/reading/operation-staged-image-repository.js').ReadingStagedImageRepository;
    readingTaskScheduler?: import('../src/reading/reading-task-scheduler.js').ReadingTaskScheduler;
    sharedWindowStore?: import('../src/rate-limit/shared-window-store.js').SharedWindowStore;
    accountDeletionRepository?: import('../src/account/account-deletion.js').AccountDeletionRepository;
    responseReplayRepository?: import('../src/middleware/response-replay-repository.js').ResponseReplayRepository;
  } = {},
) {
  const app = await buildServer({
    config,
    fetchImpl,
    logger: false,
    appCheck: options.appCheck,
    billing: options.billing,
    entitlementRepository: options.entitlementRepository,
    readingOperationRepository: options.readingOperationRepository,
    readingClock: options.readingClock,
    readingWaitPolicy: options.readingWaitPolicy,
    gemLedger: options.gemLedger,
    readingFlow: options.readingFlow,
    readingOperationInputRepository: options.readingOperationInputRepository,
    rewardedAds: options.rewardedAds,
    readingStagedImageRepository: options.readingStagedImageRepository,
    readingTaskScheduler: options.readingTaskScheduler,
    sharedWindowStore: options.sharedWindowStore ?? new MemorySharedWindowStore(),
    accountDeletionRepository: options.accountDeletionRepository,
    responseReplayRepository: options.responseReplayRepository ?? new FirestoreResponseReplayRepository(new MemoryDocumentStore()),
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

// Legacy Turkish keys on purpose: the parser must keep accepting them.
export const dreamJson = JSON.stringify({
  ozet: 'Ruya, evden sessizce gecen bir yilanla sakin bir gecis hissi tasiyor.',
  semboller: ['yilan'],
  duygusalTema: 'Yilanin sessizce gidisinde belirsizlik ile sakinlik ayni anda duruyor.',
  yorum:
    'Yilanin evden sessizce gecip gitmesi, tanidik bir alandan bir seyin gurultusuz ayrildigini dusunduruyor; burada tehdit degil, fark edilmeden olan bir gecis var.',
  gunlukYansi: 'Bugun acele etmeden, sessizce uzaklasan bir seyi fark etmek iyi gelebilir.',
  sonuc: 'Senin hayatinda sessizce gecip giden sey ne olabilir?',
});

/**
 * PHASE C1: fortune-teller register (ASCII-folded, like the other helper
 * prose). The pre-C1 helper text was a residue report with a mindfulness
 * close and is now rejected by the Coffee voice gate.
 */
export const coffeeFortuneSections = {
  visualObservation: 'Fincanin ortasinda kulba yakin, demligi andiran toplu bir telve var; dibi acik kalmis, agzin kenarindan da ince bir yol geciyor.',
  overall: 'Fincaninda demlige benzeyen bir sekil var ve kulba yakin duruyor. Demlik muhabbet demektir, kulp da ev; yakinda evinde cay demlenip uzun uzun sohbet edilecek kalabalik bir aksam gorunuyor. Belki uzun zamandir gormedigin biri cikagelir, belki de bir akraba ziyareti olur. Dibin acik olmasi da o aksamin icini ferahlatacagini, aklindaki bir konunun o sofrada tatliya baglanacagini soyluyor.',
  nearFuture: 'Agzin kenarindan gecen ince yol, bir haberin yolda oldugunu gosteriyor. Onumuzdeki gunlerde sana kisa bir mesaj ulasacak; yolda olan haber pek gecikmeyecek gibi.',
  takeaway: 'Fincanin dibi acik, kismetin kapali degil. Acik dip o aksamin ferah gececegini, sofradan herkesin yuzu gulerek kalkacagini soyluyor.',
};

export const coffeeJson = JSON.stringify({
  gorselTespit: coffeeFortuneSections.visualObservation,
  genelYorum: coffeeFortuneSections.overall,
  ask: '',
  kariyer: '',
  maddiDurum: '',
  yakinDonem: coffeeFortuneSections.nearFuture,
  sonuc: coffeeFortuneSections.takeaway,
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
    { id: 'e1', region: 'handle_side', description: 'Dense residue cluster beside the handle.', confidence: 'high', visibility: 'clear', resemblance: 'may resemble a teapot' },
    { id: 'e2', region: 'base', description: 'Open clearer area at the base beside the dense cluster.', confidence: 'high', visibility: 'clear', resemblance: null },
    // Story-first closure: the narrative reads this trail as a road ("ince bir yol")
    // carrying news; context alone may not promote news, so the evidence says so.
    { id: 'e3', region: 'rim', description: 'Thin residue trail along the rim with lighter density than the middle cluster.', confidence: 'medium', visibility: 'partial', resemblance: 'may resemble a thin road' },
  ],
});

export const coffeeWriterJson = JSON.stringify({
  visualObservation: { text: coffeeFortuneSections.visualObservation, evidenceIds: ['e1','e2','e3'] },
  overall: { text: coffeeFortuneSections.overall, evidenceIds: ['e1','e2'] },
  love: { text: '', evidenceIds: [] },
  career: { text: '', evidenceIds: [] },
  money: { text: '', evidenceIds: [] },
  nearFuture: { text: coffeeFortuneSections.nearFuture, evidenceIds: ['e3'] },
  takeaway: { text: coffeeFortuneSections.takeaway, evidenceIds: ['e2'] },
});

/**
 * C2.1 writer fixture: public prose contains meanings only, never observer mechanics.
 * C2.11A.1: its plan licenses only a DIRECTION development, so the former
 * "gerçek bir imkân" (an opening) became "gerçek bir canlanma".
 */
export const coffeeMeaningWriterJson = JSON.stringify({
  visualObservation: {
    text: 'İçine sinen taraf, yakınındaki düzenle farklı yönün ortak karşılığını belirginleştirebilir.',
    evidenceIds: ['e1', 'e3'],
  },
  overall: {
    text: 'Yakın çevrende değerlendirmeye değer bir gelişme beliriyor; bu gelişme alışılmış akışa farklı bir yön katabilecek gerçek bir canlanma taşıyor. Seni yalnızca sonucu değil, gündelik düzeninde bıraktığı karşılık da ilgilendirebilir. Kesinleşmiş bir sonuçtan çok, yakın olanla değişime açık tarafın aynı anda yer bulması dikkat çekiyor.',
    evidenceIds: ['e1', 'e3'],
  },
  love: { text: '', evidenceIds: [] },
  career: { text: '', evidenceIds: [] },
  money: { text: '', evidenceIds: [] },
  nearFuture: { text: '', evidenceIds: [] },
  takeaway: {
    text: 'Yakınındaki düzenle farklı yönün ortak karşılığı artık daha kolay anlaşılabilir.',
    evidenceIds: ['e1', 'e3'],
  },
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
