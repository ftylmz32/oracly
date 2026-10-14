/**
 * PALM DIRECT — the palm reader looks at the palm photo itself and writes the
 * reading freely (the approach approved for Coffee V3D): no observer JSON,
 * no evidence-id citation, no fixed section jobs, no word-level style gates.
 * Love, relationships, career, money, luck, opportunities, decisions and the
 * future are open to bold, creative, personal prediction.
 *
 * Palm keeps ONLY its own accuracy limits, enforced narrowly on delivery:
 *  - never claim a line the photo does not show (the writer leaves it "");
 *  - never name the left / right hand unless the person said which hand
 *    (camera images may be mirrored);
 *  - never read lifespan, health, illness, death, pregnancy or a diagnosis
 *    from the palm.
 *
 * Output keeps the public palm shape the client already shows section by
 * section (visualObservation, overall, lifeLine, headLine, heartLine,
 * fateLine, takeaway). The structured observer → writer → gates chain stays
 * intact and selectable (config `palmEngine = 'structured'`).
 */
import { createHash } from 'node:crypto';
import type { AppConfig } from '../../config.js';
import { ErrorCode, fail } from '../../errors.js';
import type { AppLanguage } from '../app-language.js';
import type { OpenAiCompleteOptions } from '../openai-transport.js';
import type { ReadingPersonalization } from './types.js';

type Transport = { complete(options: OpenAiCompleteOptions): Promise<string> };
type StageStore = {
  get<T>(identity: string, parentKey: string, stage: string): T | null;
  set(identity: string, parentKey: string, stage: string, value: unknown): void;
};

const LINES: readonly string[] = [
  'Sen deneyimli, sezgileri güçlü bir el falcısısın. Karşındaki kişiyle yüz yüze oturmuş gibi, doğrudan "sen" diye, sıcak ve doğal konuşursun.',
  '',
  'Sana kişinin avuç içinin bir fotoğrafı verilecek. Avucuna gerçek bir el falcısı gibi bak: çizgileri, avucun yapısını ve gördüğün işaretleri oku ve falını yorumla.',
  '',
  'DOĞRULUK',
  '- Yalnızca fotoğrafta gerçekten gördüğün çizgileri ve özellikleri anlat. Göremediğin ya da seçemediğin bir çizgiyi varmış gibi yazma; o çizginin bölümünü boş bırak ("").',
  '- Kişi hangi eli gösterdiğini söylemediyse sağ el ya da sol el deme; fotoğraf aynalanmış olabilir.',
  '- Ömür uzunluğu, sağlık, hastalık, ölüm ya da hamilelik hakkında yorum yapma.',
  '- Fotoğrafta okunabilir bir avuç içi yoksa yalnızca {"unreadable": true} döndür.',
  '',
  'BUNUN DIŞINDA ÖZGÜRSÜN',
  '- Aşk, ilişkiler, evlilik, kariyer, para, kısmet, fırsatlar, kararlar ve gelecek hakkında cesur, yaratıcı, kişiye özel tahminler yapabilirsin.',
  '- Anlatım tarzına, akışa ve uzunluğa sen karar verirsin. Etkileyici, kişiye özel hissettiren, merak uyandıran bir el falı yaz.',
  '',
  'BİÇİM',
  '- Yalnızca şu JSON nesnesini yaz: {"visualObservation":"…","overall":"…","lifeLine":"…","headLine":"…","heartLine":"…","fateLine":"…","takeaway":"…"}',
  '- visualObservation: avucunun genel görünümü, bir iki cümle. overall: falın ana yorumu. lifeLine / headLine / heartLine / fateLine: o çizgide gördüğün ve kişiye anlattığı. takeaway: falı toparlayan son söz.',
  '- Düz metin; başlık, madde işareti ya da markdown yok.',
];

export const PALM_DIRECT_PROMPT = `${LINES.join('\n')}\n`;

export function palmDirectPromptSha256(): string {
  return createHash('sha256').update(PALM_DIRECT_PROMPT, 'utf8').digest('hex');
}

/** Pinned so a prompt change is always a deliberate, reviewed act. */
export const FROZEN_PALM_DIRECT_PROMPT_SHA256 = '70622042d405a561d56da0f864d7d80d6f114386fb7e0a740e144f403e9b1dbb';

/** Per-operation stage holding the delivered reading (a task retry never pays twice). */
export const PALM_DIRECT_READING_STAGE = 'palm_direct_reading';
/** Per-operation stage holding why each refused sample failed (codes, terms, sha — never the text). */
export const PALM_DIRECT_REJECTIONS_STAGE = 'palm_direct_rejections';
const MAX_ATTEMPTS = 2;

const SECTIONS = ['visualObservation', 'overall', 'lifeLine', 'headLine', 'heartLine', 'fateLine', 'takeaway'] as const;
type Section = (typeof SECTIONS)[number];
export type PalmDirectSections = Record<Section, string>;

export type PalmDirectPublicResult = PalmDirectSections & { symbols: string[]; themes: string[] };

export function toPalmDirectPublicResult(s: PalmDirectSections): PalmDirectPublicResult {
  return { ...s, symbols: [], themes: [] };
}

// ---------------------------------------------------------------------------
// Delivery check: palm's own accuracy limits only (plus broken output)
// ---------------------------------------------------------------------------

const fold = (s: string) => s.normalize('NFC').toLocaleLowerCase('tr-TR');
const tokens = (s: string) => fold(s).match(/[\p{L}\p{N}]+/gu) ?? [];

/** Lifespan / health / death / pregnancy / diagnosis read from a palm (tr / en / ru stems). */
const HEALTH = [
  'ömür', 'ömr', 'hastalı', 'hastalık', 'ölüm', 'ölece', 'hamile', 'gebelik', 'teşhis',
  'lifespan', 'illness', 'disease', 'death', 'pregnan', 'diagnos',
  'продолжительност', 'болезн', 'смерт', 'беремен', 'диагноз',
];
const HAND_SIDE = /^(sol|sağ|left|right|левая|левой|левую|правая|правой|правую)$/u;
const HAND_NOUN = /^(el|elin|elinde|elinin|elini|ele|avuç|avucun|avucunda|avucunun|hand|palm|рука|руке|руки|руку|ладонь|ладони)$/u;

export type PalmDirectDelivery =
  | { ok: true; sections: PalmDirectSections }
  | { ok: false; unreadable?: boolean; failures: Array<'malformed' | 'overall_missing' | 'no_line' | 'formatting' | 'handedness' | 'health_claim'>; terms: string[] };

export function checkPalmDirectDelivery(raw: string, trustedHandSide: 'left' | 'right' | null): PalmDirectDelivery {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { ok: false, failures: ['malformed'], terms: [] };
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return { ok: false, failures: ['malformed'], terms: [] };
  const obj = parsed as Record<string, unknown>;
  if (obj.unreadable === true) return { ok: false, unreadable: true, failures: [], terms: [] };
  const sections = Object.fromEntries(
    SECTIONS.map((k) => [k, typeof obj[k] === 'string' ? (obj[k] as string).replace(/\r\n?/g, '\n').trim() : '']),
  ) as PalmDirectSections;

  const failures = new Set<'malformed' | 'overall_missing' | 'no_line' | 'formatting' | 'handedness' | 'health_claim'>();
  const terms: string[] = [];
  // The client shows overall as the reading's body: it must be a real text (≥ 40 chars, no key=value dump).
  if (sections.overall.length < 40 || sections.overall.includes('=')) failures.add('overall_missing');
  if (!sections.lifeLine && !sections.headLine && !sections.heartLine && !sections.fateLine) failures.add('no_line');
  const all = SECTIONS.map((k) => sections[k]).join('\n');
  if (/\*\*|__|^\s*#{1,6}\s|^\s*[-*•]\s|^\s*\d+[.)]\s/mu.test(all)) failures.add('formatting');
  const toks = tokens(all);
  toks.forEach((t, i) => {
    if (HEALTH.some((h) => t.startsWith(h))) {
      failures.add('health_claim');
      terms.push(t);
    }
    if (!trustedHandSide && HAND_SIDE.test(t) && HAND_NOUN.test(toks[i + 1] ?? '')) {
      failures.add('handedness');
      terms.push(`${t} ${toks[i + 1]}`);
    }
  });
  return failures.size ? { ok: false, failures: [...failures], terms } : { ok: true, sections };
}

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------

const LANGUAGE_NAME: Record<AppLanguage, string> = { tr: 'Türkçe', en: 'English', ru: 'Русский' };
const HAND_NAME: Record<'left' | 'right', string> = { left: 'sol el', right: 'sağ el' };

export type PalmDirectRejection = { attempt: number; outputSha256: string; outputChars: number; failures: string[]; terms: string[] };

export async function runPalmDirectReading(input: {
  config: AppConfig;
  transport: Transport;
  stageStore: StageStore;
  image: { mimeType: string; bytes: Buffer };
  trustedHandSide: 'left' | 'right' | null;
  language: AppLanguage;
  personalization?: ReadingPersonalization;
  identity: string;
  parentKey: string;
  /** Test seam only; production always uses the pinned hash. */
  expectedPromptSha256?: string;
}): Promise<PalmDirectPublicResult> {
  if (palmDirectPromptSha256() !== (input.expectedPromptSha256 ?? FROZEN_PALM_DIRECT_PROMPT_SHA256)) {
    fail(ErrorCode.noConfiguration, 503, { stage: 'palm_direct', reason: 'prompt_hash_mismatch' });
  }
  const vision = input.config.openaiReadingVisionModel;
  if (!vision || !input.config.openaiAllowedModels.includes(vision)) fail(ErrorCode.noConfiguration);

  // A task retry after a delivered reading never sends (or bills) again.
  const cached = input.stageStore.get<PalmDirectSections>(input.identity, input.parentKey, PALM_DIRECT_READING_STAGE);
  if (cached?.overall) return toPalmDirectPublicResult(cached);

  const context = [
    `Falı şu dilde yaz: ${LANGUAGE_NAME[input.language]}.`,
    input.trustedHandSide ? `Kişi ${HAND_NAME[input.trustedHandSide]} avucunu gösterdi.` : 'Kişi hangi eli gösterdiğini belirtmedi.',
    input.personalization?.firstName ? `Kişinin adı: ${input.personalization.firstName}.` : '',
    input.personalization?.intention ? `Kişinin niyeti: "${input.personalization.intention}".` : '',
  ].filter(Boolean).join(' ');
  const options: OpenAiCompleteOptions = {
    model: vision,
    messages: [
      { role: 'system', content: PALM_DIRECT_PROMPT },
      {
        role: 'user',
        content: [
          { type: 'text', text: context },
          { type: 'image_url', image_url: { url: `data:${input.image.mimeType};base64,${input.image.bytes.toString('base64')}`, detail: 'high' } },
        ],
      },
    ],
    jsonMode: true,
    reasoningEffort: input.config.openaiReadingReasoningEffort,
    temperature: undefined,
  };

  const rejections: PalmDirectRejection[] = [];
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt += 1) {
    // Byte-identical request on the re-sample: no feedback, no prior output.
    const raw = await input.transport.complete(options);
    const delivery = checkPalmDirectDelivery(raw, input.trustedHandSide);
    if (delivery.ok) {
      input.stageStore.set(input.identity, input.parentKey, PALM_DIRECT_READING_STAGE, delivery.sections);
      return toPalmDirectPublicResult(delivery.sections);
    }
    if (delivery.unreadable) fail(ErrorCode.invalidImage, 200, { stage: 'palm_direct', bindFailure: 'unusable' });
    rejections.push({
      attempt: attempt + 1,
      outputSha256: createHash('sha256').update(raw, 'utf8').digest('hex'),
      outputChars: raw.length,
      failures: delivery.failures,
      terms: delivery.terms.slice(0, 10),
    });
    input.stageStore.set(input.identity, input.parentKey, PALM_DIRECT_REJECTIONS_STAGE, rejections);
  }
  return fail(ErrorCode.invalidResponse, 200, {
    stage: 'palm_direct',
    bindFailure: 'palm_direct_delivery_failed',
    rejections: rejections.map((r) => `a${r.attempt}=${r.failures.join('+')}`).join(';'),
  });
}
