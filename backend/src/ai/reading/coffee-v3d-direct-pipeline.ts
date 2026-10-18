/**
 * V3D — DIRECT fortune-teller engine for the Coffee V3 three-photo capture.
 *
 * The vision model looks at the three staged photos (two cup views + the
 * saucer) and writes the fortune itself, freely: love, relationships,
 * separation, reconciliation, marriage, news, money, work, career, luck,
 * opportunities, surprises — its own style, flow and length. No meaning
 * tables, no paragraph plan, no word-level narrative gates.
 *
 * ONE product rule is enforced: the visual analysis stays inside, the reader
 * gets the fortune. The person never reads a description of the cup, the
 * saucer, the grounds, a symbol or any seen detail. The delivery check below
 * refuses only that (and an empty / runaway / markdown-formatted text);
 * ordinary life words — yol, kalp, kuş, açıklık, kapı — stay free.
 *
 * Public result: the same server-gated `v3_narrative_v1` shape the client
 * already restores and shows verbatim. The V3N narrative engine is kept
 * intact and selectable (config `coffeeV3Engine = 'narrative'`).
 */
import { createHash } from 'node:crypto';
import type { AppConfig } from '../../config.js';
import type { ReadingLanguage } from '../../reading/operation-model.js';
import type { CoffeeV3StagedSlot } from '../../reading/operation-staged-image-model.js';
import type { OpenAiContentPart } from '../../types.js';
import {
  COFFEE_V3_MAX_WRITER_COMPLETIONS,
  COFFEE_V3_STAGED_TO_SEMANTIC_SLOT,
  assertCoffeeV3ModelPins,
  terminal,
  type StageStore,
  type Transport,
} from './coffee-v3-live-pipeline.js';
import { toCoffeeV3NarrativePublicResult, type CoffeeV3NarrativePublicResult } from './coffee-v3n-narrative-pipeline.js';

const LINES: readonly string[] = [
  'Sen deneyimli, sezgileri güçlü bir Türk kahve falcısısın. Karşındaki kişiyle yüz yüze oturmuş gibi, doğrudan "sen" diye, sıcak ve doğal bir Türkçeyle konuşursun.',
  '',
  'Sana bir kahve fincanının içinden iki fotoğraf ve tabağının bir fotoğrafı verilecek. Fincana ve tabağa bir falcı gibi bak; gördüklerinden ilham alarak bu kişinin falını yorumla.',
  '',
  'TEK KESİN KURAL',
  '- Gördüğünü kendine sakla, kişiye yalnızca falını anlat. Fincanı, tabağı, telveyi, şekilleri, sembolleri ya da gördüğün hiçbir görsel ayrıntıyı ASLA tarif etme: "fincanında bir kuş var", "kalp gibi duran şekil", "tabaktaki telve", "dipteki koyuluk" gibi anlatımlar yok.',
  '',
  'BUNUN DIŞINDA ÖZGÜRSÜN',
  '- Kişinin niyeti falın omurgasıdır. Sorduğu şeye, fincanın taşıdığı işaretlerden ilham alarak cevap ver ve tek, bütünlüklü bir hikâye kur. Herkese söylenebilecek genel bir fal yazma. Yalnız gerçekten öne çıkan konuları doğal biçimde geliştir; aşk, para, iş, aile gibi alanları sırf falda bulunsun diye sırayla dolaşma.',
  '- Somut ayrıntıları gördüklerinin taşıyabildiği ölçüde kullan. Rastgele harf, tarih ya da sayı verme; gizli bir düşman, beklenen bir ödeme veya üçüncü bir kişinin duygusu gibi görünmeyen ayrıntıları doğrulanmış gerçek gibi anlatma. Geleceği kesin olmuş bir bilgi gibi ilan etme.',
  '- Falcı sezgini, sembolik yorumunu, merakı ve yaratıcı anlatımını koru. Anlatım tarzına, hikâyenin akışına ve uzunluğa sen karar ver; kuru bir açıklama yazma, her cümleyi çekingen olasılık sözcüklerine de boğma. Yapılacaklar listesi, "şunu yaz" ödevi ya da her falın sonuna yapışan hazır bir kapanış cümlesi kurma.',
  '- Ölüm, ağır hastalık, kaza ya da hamilelik konusunda korkutucu kehanette bulunma. Kanıtsız suçlama, iftira ya da zarar verici talimat yok. Tıbbi ya da hukuki kesin hüküm verme.',
  '',
  'BİÇİM',
  '- Düz metin yaz: başlık, madde işareti ya da markdown yok; paragrafları boş bir satırla ayır.',
];

export const COFFEE_V3D_DIRECT_PROMPT = `${LINES.join('\n')}\n`;

export function coffeeV3DPromptSha256(): string {
  return createHash('sha256').update(COFFEE_V3D_DIRECT_PROMPT, 'utf8').digest('hex');
}

/** Pinned so a prompt change is always a deliberate, reviewed act. */
export const FROZEN_COFFEE_V3D_PROMPT_SHA256 = '519c6421a9cb5aadc65352ff27025d56abe6364ceded2c0b6a6bcd26e4904ba4';

/** Per-operation stage holding the delivered reading (a task retry never pays twice). */
export const COFFEE_V3D_READING_STAGE = 'coffee_v3d_reading';
/** Per-operation stage holding why each refused sample failed (codes, terms, sha — never the text). */
export const COFFEE_V3D_REJECTIONS_STAGE = 'coffee_v3d_rejections';

/** Order and plain labels of the three photos, as the person took them. */
const PHOTO_ORDER: ReadonlyArray<{ slot: 'cup_view_a' | 'cup_view_b' | 'saucer'; label: string }> = [
  { slot: 'cup_view_a', label: 'Fincanın içi (1. açı)' },
  { slot: 'cup_view_b', label: 'Fincanın içi (2. açı)' },
  { slot: 'saucer', label: 'Tabak' },
];

// ---------------------------------------------------------------------------
// Delivery check: visual description only (plus empty / runaway / markdown)
// ---------------------------------------------------------------------------

const fold = (s: string) => s.normalize('NFC').toLocaleLowerCase('tr-TR');
const tokens = (s: string) => fold(s).match(/[\p{L}\p{N}]+/gu) ?? [];

/** The cup itself: naming it is describing it (the reading never talks about the cup). */
const CUP_WORD = /^(fincan|telve|tortu|kulp|kulb|tabağ|tabak(?!a))/u;
/**
 * "figür / silüet" are context words: "bir kadın figüründen destek alacaksın"
 * speaks of a woman in the person's life (first real V3D sample, wrongly
 * refused); "kuş figürü" or "bir insan figürü beliriyor" describes a seen shape.
 */
const FIGURE = /^(figür|silüet|siluet)/u;
/** A person noun before "figür" names someone in the person's life unless it is being seen. */
const PERSON = /^(kadın|erkek|insan|çocuk|çocuğ)/u;
/** What is SEEN as a symbol: a symbol noun right before a shape construction. */
const SYMBOL_STEMS = [
  'kuş', 'balık', 'balığ', 'kalp', 'kalb', 'yılan', 'ağaç', 'ağac', 'yüzük', 'yüzüğ', 'anahtar', 'göz', 'yıldız', 'çiçek', 'kelebek',
  'köprü', 'merdiven', 'harf', 'dağ', 'kapı', 'yol', 'insan', 'kadın', 'erkek', 'çocuk', 'çocuğ', 'melek', 'taç', 'köpek', 'kedi',
  'aslan', 'kartal', 'baykuş', 'örümcek', 'akrep', 'gemi', 'uçak', 'araba', 'halka', 'daire', 'çizgi', 'nokta', 'leke',
];
const SYMBOL_EXACT = new Set(['at', 'ata', 'el', 'ay', 'ok', 'ev', 'iz', 'izi']);
const isSymbol = (t: string) => SYMBOL_EXACT.has(t) || SYMBOL_STEMS.some((s) => t.startsWith(s));
/** "kuş şeklinde", "kalbe benzeyen", "yılan figürü" — a seen shape, not a life image. */
const SHAPE_AFTER = /^(şekl|şekil|biçim|figür|silüet|siluet|benzey|benziyor|resm)/u;
/** Creatures and objects a reader only ever "sees" in a cup ("bir kuş görüyorum"). */
const SEEN_ONLY = ['kuş', 'balık', 'balığ', 'yılan', 'ağaç', 'ağac', 'yüzük', 'yüzüğ', 'anahtar', 'kelebek', 'köprü', 'merdiven', 'harf', 'melek', 'taç', 'köpek', 'kedi', 'aslan', 'kartal', 'baykuş', 'örümcek', 'akrep', 'gemi', 'uçak', 'halka', 'daire'];
const SEEING = /^(görüyorum|beliriyor|seçiliyor|çiziliyor)$/u;

export type CoffeeV3DDelivery =
  | { ok: true; reading: string; words: number }
  | { ok: false; failures: Array<'empty' | 'too_short' | 'too_long' | 'formatting' | 'visual_description'>; terms: string[]; words: number };

/**
 * Cut-off floor and runaway ceiling, not a style target.
 * Twelve words catches a truncated reply. Seven hundred stops a runaway
 * completion. The prompt leaves length to the writer.
 */
const MIN_WORDS = 12;
const MAX_WORDS = 700;

export function checkCoffeeV3DirectDelivery(raw: string): CoffeeV3DDelivery {
  const paragraphs = raw.replace(/\r\n?/g, '\n').split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean);
  const reading = paragraphs.join('\n\n');
  const wordCount = (reading.match(/\S+/g) ?? []).length;
  const failures = new Set<'empty' | 'too_short' | 'too_long' | 'formatting' | 'visual_description'>();
  const terms: string[] = [];
  if (!reading) return { ok: false, failures: ['empty'], terms: [], words: 0 };
  if (wordCount < MIN_WORDS) failures.add('too_short');
  if (wordCount > MAX_WORDS) failures.add('too_long');
  if (/\*\*|__|^\s*#{1,6}\s|^\s*[-*•]\s|^\s*\d+[.)]\s/mu.test(reading)) failures.add('formatting');
  const toks = tokens(reading);
  toks.forEach((t, i) => {
    const next = toks[i + 1] ?? '';
    const after = toks[i + 2] ?? '';
    let hit: string | null = null;
    const prev = toks[i - 1] ?? '';
    const seenSoon = toks.slice(i + 1, i + 4).some((x) => SEEING.test(x));
    if (CUP_WORD.test(t)) hit = t;
    else if (FIGURE.test(t)) {
      if ((isSymbol(prev) && !PERSON.test(prev)) || seenSoon) hit = prev ? `${prev} ${t}` : t;
    } else if (isSymbol(t) && !FIGURE.test(next) && (SHAPE_AFTER.test(next) || (next === 'gibi' && after.startsWith('duran')))) hit = `${t} ${next}`;
    else if (SEEN_ONLY.some((s) => t.startsWith(s)) && SEEING.test(next)) hit = `${t} ${next}`;
    if (hit) {
      failures.add('visual_description');
      terms.push(hit);
    }
  });
  return failures.size ? { ok: false, failures: [...failures], terms, words: wordCount } : { ok: true, reading, words: wordCount };
}

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------

export type CoffeeV3DRejection = { attempt: number; outputSha256: string; outputChars: number; failures: string[]; terms: string[] };

export async function runCoffeeV3DirectReading(input: {
  config: AppConfig;
  transport: Transport;
  stageStore: StageStore;
  images: ReadonlyArray<{ slot: CoffeeV3StagedSlot; mimeType: string; bytes: Buffer }>;
  intention: string;
  language: ReadingLanguage;
  identity: string;
  parentKey: string;
  /** Test seam only; production always uses the pinned hash. */
  expectedPromptSha256?: string;
}): Promise<CoffeeV3NarrativePublicResult> {
  if (input.language !== 'tr') terminal('unavailable', 'language_not_supported');
  if (coffeeV3DPromptSha256() !== (input.expectedPromptSha256 ?? FROZEN_COFFEE_V3D_PROMPT_SHA256)) {
    terminal('unavailable', 'v3d_prompt_hash_mismatch');
  }
  const { vision } = assertCoffeeV3ModelPins(input.config);

  // A task retry after a delivered reading never sends (or bills) again.
  const cached = input.stageStore.get<{ reading: string }>(input.identity, input.parentKey, COFFEE_V3D_READING_STAGE);
  if (cached?.reading) return toCoffeeV3NarrativePublicResult(cached.reading);

  // Exactly the three staged views, in the person's order.
  const bySlot = new Map<string, { mimeType: string; bytes: Buffer }>();
  for (const image of input.images) {
    const semantic = COFFEE_V3_STAGED_TO_SEMANTIC_SLOT[image.slot];
    if (!semantic || bySlot.has(semantic)) terminal('unavailable', 'staged_views_malformed');
    bySlot.set(semantic, image);
  }
  if (bySlot.size !== PHOTO_ORDER.length || PHOTO_ORDER.some((p) => !bySlot.has(p.slot))) terminal('unavailable', 'staged_views_malformed');

  const content: OpenAiContentPart[] = [{ type: 'text', text: `Kişinin niyeti: "${input.intention}".` }];
  for (const photo of PHOTO_ORDER) {
    const image = bySlot.get(photo.slot)!;
    content.push({ type: 'text', text: photo.label });
    content.push({ type: 'image_url', image_url: { url: `data:${image.mimeType};base64,${image.bytes.toString('base64')}`, detail: 'high' } });
  }

  const rejections: CoffeeV3DRejection[] = [];
  for (let attempt = 0; attempt < COFFEE_V3_MAX_WRITER_COMPLETIONS; attempt += 1) {
    // Byte-identical request on the re-sample: no feedback, no prior output.
    const raw = await input.transport.complete({
      model: vision,
      messages: [
        { role: 'system', content: COFFEE_V3D_DIRECT_PROMPT },
        { role: 'user', content },
      ],
      reasoningEffort: input.config.openaiReadingReasoningEffort,
      temperature: undefined,
    });
    const delivery = checkCoffeeV3DirectDelivery(raw);
    if (delivery.ok) {
      input.stageStore.set(input.identity, input.parentKey, COFFEE_V3D_READING_STAGE, { reading: delivery.reading });
      return toCoffeeV3NarrativePublicResult(delivery.reading);
    }
    rejections.push({
      attempt: attempt + 1,
      outputSha256: createHash('sha256').update(raw, 'utf8').digest('hex'),
      outputChars: raw.length,
      failures: delivery.failures,
      terms: delivery.terms.slice(0, 10),
    });
    input.stageStore.set(input.identity, input.parentKey, COFFEE_V3D_REJECTIONS_STAGE, rejections);
  }
  const summary = rejections.map((r) => `a${r.attempt}=${r.failures.join('+')}`).join(';');
  return terminal('unavailable', `v3d_delivery_failed:${summary}`);
}
