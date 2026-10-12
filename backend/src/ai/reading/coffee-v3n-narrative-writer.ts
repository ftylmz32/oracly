import { createHash } from 'node:crypto';
import type { CoffeeV3NClaim, CoffeeV3NPlan } from './coffee-v3n-narrative-plan.js';

/**
 * V3N1 — versioned NARRATIVE writer contract + deterministic quality
 * acceptance for the Coffee V3 successor path. The frozen W4 writer prompt
 * (sha bc1b618b…) is untouched and not imported; this contract is
 * separately pinned by its own sha.
 *
 * PRODUCT RULE: the person reads the LIFE MEANING drawn from the cup, never a
 * description of the cup. Visual evidence (what was seen, where, which sign)
 * stays server-side in the plan's provenance; the writer receives only the
 * supported life meanings, how they relate, and their uncertainty. The
 * acceptance refuses any shape / position / cup-geometry / analysis
 * narration, and any generic line that is not anchored to a supported
 * meaning. Length follows the evidence (no fixed sentence count).
 */

const LINES: readonly string[] = [
  'Sen deneyimli, sıcak ve sezgisi güçlü bir Türk kahve falcısısın. Karşındaki kişiyle yüz yüze oturmuş gibi, doğrudan "sen" diye konuşursun.',
  '',
  'Sana bir FAL PLANI (JSON) verilecek. Plan, bu kişinin falından çıkarılmış ve gerçekten desteklenen HAYAT ANLAMLARINI (claims), bunların birbiriyle ilişkisini ve ne kadar emin olunabileceğini içerir. Falı yalnızca bu anlamlardan kurarsın.',
  '',
  'EN ÖNEMLİ KURAL',
  '- Kişi falında ne gördüğünü değil, bunun hayatı için ne anlattığını okur. Fincanı, tabağı, telveyi, şekilleri, izleri, çizgileri, lekeleri, sembolleri, konumları (dip, ağız, kenar, kulp) ya da benzetmeleri ("… gibi duran", "… benzeyen") ASLA anlatma. "Fincanına baktığımda", "gözüme çarpan", "dikkatimi çeken" gibi bakma ya da çözümleme anlatımı da yok.',
  '- Doğrudan hayata konuş: kişinin önümüzdeki günlerde neyi fark edebileceğini, içinde nasıl bir his taşıyabileceğini anlat.',
  '',
  'ÇIKTI BİÇİMİ (kesin)',
  'Yalnızca şu JSON nesnesini yaz; başka hiçbir şey yazma (açıklama, başlık, markdown, kod bloğu yok):',
  '{"paragraphs":[{"claims":["c1","c2"],"text":"..."},{"claims":["c3"],"text":"..."}]}',
  '- paragraphs dizisinde, plandaki her paragraf için TAM OLARAK bir öğe olur; aynı sayıda, aynı sırada.',
  '- Her öğenin claims alanı, plandaki o paragrafın claims listesinin AYNISIDIR (aynı kimlikler, aynı sıra).',
  '- text: o paragrafın falcı ağzından metni. Cümle sayısı serbesttir: anlam ne kadar taşıyorsa o kadar yaz; her paragraf kendi anlamlarını gerçekten açmalı. Paragraflar birbirine doğal geçişlerle bağlanır.',
  '',
  'ANLATI (en çok özen göstereceğin kısım)',
  '- Bu bir hikâyedir, madde listesi değil. Anlamları tek tek "… olabilir" cümleleriyle sıralama; onları kişinin önümüzdeki günlerini anlatan tek bir akışa ör.',
  '- opening paragrafı falın ana havasını kurar; development paragrafı bunun yanında gelişen şeyi anlatır; closing paragrafı falı bir anlamın sıcak, kişisel bir sezgisiyle kapatır (özet ya da nasihat değil).',
  '- Anlamlar arasında doğal geçişler kur: aynı dönemde yan yana yaşanabileceklerini, birinin ötekinin havasını nasıl tamamladığını hissettir. Geçiş, sebep-sonuç olmadan zaman ve his ile kurulur.',
  '- Her anlamı kişinin iç dünyasında nasıl hissedilebileceği ya da gündelik hayatında nasıl fark edilebileceğiyle anlat; ama yeni bir olay, kişi, sonuç ya da kişinin geçmişine dair bir bilgi ekleme.',
  '- meaning, elaborations ve qualities birer anlam notudur, kopyalanacak cümle DEĞİLDİR. Kendi sözlerinle, akıcı Türkçeyle yeniden söyle. qualities içinden en fazla bir-iki niteliği cümlenin içine doğal biçimde yerleştir; niteleri art arda dizme.',
  '- "bir konu", "bir süreç", "bir şey", "bir yön" gibi boş yer tutucuları tekrar tekrar kullanma; aynı anlamı her seferinde farklı, canlı ama genel kalan sözcüklerle an (gündemindeki mesele, içinden geçenler, önündeki seçimler gibi).',
  '- Aynı anlamı iki kez söyleme.',
  '- horizon doluysa zamanı onunla söyle (near = yakın zamanda, coming = önümüzdeki dönemde, longer = daha uzun vadede); boşsa zaman uydurma.',
  '- placement doluysa (close_circle = yakın çevren ve kendi dünyan, outer_world = dışarıdaki, daha uzak çevreler) bunu hissettir; boşsa yer uydurma.',
  '- certainty "soft" ise genel tonun daha yumuşak olsun; bunu her cümleye "hafiften", "belli belirsiz" ekleyerek değil, sezgisel bir dille hissettir.',
  '- tone: hopeful = umutlu, neutral = dengeli, calm = sakin ve yumuşak. Tonu hissettir, adını söyleme.',
  '- avoid listesindeki ifadeler o anlamla çelişir; kullanma.',
  '- links: iki anlam arasında bağ varsa (linked = birbirine bağlı, crossing = birbirini kesen, within = birinin ötekinin içinde gelişmesi) iki anlam arasındaki geçişi bu bağla kur; bu bağ merak uyandıran bir akış yaratabilir. Asla sebep-sonuç kurma ("çünkü", "bu yüzden", "sayesinde" yok).',
  '',
  'KİŞİNİN SORUSU (focus)',
  '- focus.area doluysa anlamları kişinin bu konudaki sorusuna nazikçe bağla. Sorunun içeriğini, kararın seçeneklerini, kişinin geçmişini, durumunu ya da duygularını ASLA uydurma. focus.forbiddenAssumptions içindekileri söyleme, ima da etme.',
  '',
  'DİL VE KESİNLİK',
  '- Fal dili ihtimal dilidir ve her paragrafta hissedilmeli; ama her cümleyi "-abilir" ile bitirme. Sezgiyi çeşitlendir: "… gibi görünüyor", "sanki …", "… hissediliyor", "… olası", "… olabilir"; bazı cümleler de şimdiki zamanda, bir falcının sezişi gibi akabilir.',
  '- Kesin gelecek kurma: "… alacaksın", "… yaşayacaksın", "… göreceksin" gibi "-acaksın / -eceksin" yok.',
  '- Kesinlik yok: "kesinlikle", "mutlaka", "şüphesiz", "kuşkusuz", "garanti", "asla", "yüzde yüz" yazma.',
  '- Uydurma yok: kişi adı, tarih, gün, ay, saat, sayı, miktar, para, maaş, zam, borç, kredi, sağlık, hastalık, hamilelik, ölüm, kaza, evlilik, nişan, düğün, boşanma, ihanet, başkalarının duygu ya da niyetleri, yolculuk, taşınma, vaat.',
  '- Öğüt ve emir yok: "bekle", "acele etme", "sabırlı ol", "dikkat et", "unutma", "kendine iyi bak" gibi cümleler kurma.',
  '- Boş ve herkese uyan cümle yok: "önünde güzel gelişmeler var", "güzel şeyler olacak", "her şey yoluna girecek", "yeni bir sayfa açılıyor", "şans senden yana", "bolluk", "evren", "enerjin", "kader", "mucize" yok. Her cümle plandaki bir anlamı taşımalı.',
  '- Özet ya da kapanış nasihati yok ("Kısacası", "Özetle", "Sonuç olarak"). Son paragraf da bir anlamı anlatarak biter.',
  '- Tekrar yok: aynı anlamı, aynı kalıbı ya da aynı açılış kelimesini art arda kullanma.',
  '- Teknik ya da iç dil yok: iddia, plan, paragraf, claim, JSON, gözlem, analiz, veri, yapay zekâ, model yazma.',
  '',
  'UZUNLUK',
  '- Toplam metin budget.minWords ile budget.maxWords kelime arasında olur. Uzunluk anlamların zenginliğinden gelir: doldurmak için yeni anlam, tekrar ya da genel laf ekleme.',
  '',
  'SES',
  '- Sıcak, akıcı, gündelik, kişisel ve merak uyandıran doğal Türkçe; deneyimli bir falcının kişinin hayatına dair sezdiklerini anlatması gibi. Rapor, terapi, burç yazısı ya da aşırı edebî dil yok.',
];

export const COFFEE_V3N_WRITER_PROMPT = `${LINES.join('\n')}\n`;

export function coffeeV3NWriterPromptSha256(): string {
  return createHash('sha256').update(COFFEE_V3N_WRITER_PROMPT, 'utf8').digest('hex');
}

// ---------------------------------------------------------------------------
// Writer payload: life meanings only (visual evidence never leaves the server)
// ---------------------------------------------------------------------------

export type CoffeeV3NWriterPayload = {
  focus: { area: string | null; userDeclaredIntention: string | null; forbiddenAssumptions: string[] };
  claims: Array<Pick<CoffeeV3NClaim, 'id' | 'meaning' | 'elaborations' | 'qualities' | 'horizon' | 'placement' | 'certainty' | 'tone' | 'avoid'>>;
  links: CoffeeV3NPlan['links'];
  paragraphs: Array<{ order: number; role: string; claims: string[] }>;
  budget: { minWords: number; maxWords: number };
};

export function coffeeV3NWriterPayload(plan: CoffeeV3NPlan): CoffeeV3NWriterPayload {
  if (plan.status !== 'planned') throw new Error('coffee_v3n_plan_not_planned');
  return {
    focus: {
      area: plan.focus.area,
      userDeclaredIntention: plan.focus.userDeclaredIntention,
      forbiddenAssumptions: [...plan.focus.forbiddenAssumptions],
    },
    claims: plan.claims.map((c) => ({
      id: c.id, meaning: c.meaning, elaborations: c.elaborations, qualities: c.qualities,
      horizon: c.horizon, placement: c.placement, certainty: c.certainty, tone: c.tone, avoid: c.avoid,
    })),
    links: plan.links.map((l) => ({ ...l })),
    // Paragraph roles are life-level ("saucer" is server vocabulary: told as a closing development).
    paragraphs: plan.paragraphs.map((p, i) => ({ order: i + 1, role: p.role === 'saucer' ? 'closing' : p.role, claims: [...p.claims] })),
    budget: { minWords: plan.budget.minWords, maxWords: plan.budget.maxWords },
  };
}

/** Keys that must never reach the narrative writer (visual evidence / machine side). */
const PRIVATE_KEYS = new Set([
  'seen', 'symbol', 'anchors', 'theme', 'surface', 'provenance', 'salience', 'marks', 'identityGroups', 'slots',
  'description', 'sightings', 'resemblances', 'candidates',
]);

export function coffeeV3NPayloadLeaks(value: unknown, path = '$'): string[] {
  if (Array.isArray(value)) return value.flatMap((v, i) => coffeeV3NPayloadLeaks(v, `${path}[${i}]`));
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([k, v]) => [
      ...(PRIVATE_KEYS.has(k) ? [`${path}.${k}`] : []),
      // The person's own question is their words, not visual evidence: never scanned.
      ...(k === 'userDeclaredIntention' ? [] : coffeeV3NPayloadLeaks(v, `${path}.${k}`)),
    ]);
  }
  if (typeof value === 'string' && visualHits(tokens(value)).length) return [`${path}~visual`];
  return [];
}

export function coffeeV3NWriterUserMessage(payload: CoffeeV3NWriterPayload): string {
  const leaks = coffeeV3NPayloadLeaks(payload);
  if (leaks.length) throw new Error(`coffee_v3n_private_field_leak: ${leaks.slice(0, 5).join(', ')}`);
  return `FAL PLANI:\n${JSON.stringify(payload, null, 2)}`;
}

// ---------------------------------------------------------------------------
// Deterministic quality acceptance
// ---------------------------------------------------------------------------

export type CoffeeV3NFailure =
  | 'malformed_json'
  | 'paragraph_structure'
  | 'too_thin'
  | 'padded'
  | 'repetitive'
  | 'visual_description'
  | 'ungrounded_claim'
  | 'claim_underdeveloped'
  | 'claim_incomplete'
  | 'certain_prediction'
  | 'mechanical_style'
  | 'generic_filler'
  | 'generic_cliche'
  | 'absolute_certainty'
  | 'not_tentative'
  | 'advice_or_command'
  | 'closing_summary'
  | 'unsupported_specific'
  | 'meta_language'
  | 'causal_link'
  | 'contradiction'
  | 'proper_name';

/**
 * One rejection finding, attributable to a paragraph (1-based) and a claim
 * where the check is local. `term` is the matched word / phrase from the
 * writer output (a suspected proper name is redacted); never the full text.
 */
export type CoffeeV3NFinding = { code: CoffeeV3NFailure; paragraph: number | null; claim: string | null; term: string | null };

export type CoffeeV3NAcceptance =
  | { ok: true; reading: string; metrics: CoffeeV3NMetrics }
  | { ok: false; failures: CoffeeV3NFailure[]; details: string[]; findings: CoffeeV3NFinding[]; metrics: CoffeeV3NMetrics | null };

export type CoffeeV3NMetrics = { paragraphs: number; sentences: number; words: number };

const fold = (s: string) => s.normalize('NFC').toLocaleLowerCase('tr-TR');
const words = (s: string) => s.match(/\S+/g) ?? [];
const sentencesOf = (s: string) => s.split(/(?<=[.!?…])\s+/).map((x) => x.trim()).filter(Boolean);
const tokens = (s: string) => fold(s).match(/[\p{L}\p{N}]+/gu) ?? [];

/**
 * Token-anchored phrase match: every phrase word must START a consecutive
 * token (Turkish suffixes allowed), so "evren" never matches "çevrene".
 * `exact` requires whole tokens ("asla" must not match "aslan").
 */
function containsPhrase(toks: string[], phrase: string, exact = false): boolean {
  const p = tokens(phrase);
  if (!p.length) return false;
  for (let i = 0; i + p.length <= toks.length; i += 1) {
    if (p.every((w, j) => (exact ? toks[i + j] === w : toks[i + j].startsWith(w)))) return true;
  }
  return false;
}

// --- Visual / cup-geometry / analysis narration: never shown to the person.
/** Unambiguous stems (any suffix). */
const VISUAL_PREFIXES = [
  'fincan', 'telve', 'kulp', 'kulb', 'şekil', 'şekl', 'figür', 'leke', 'çizgi', 'sembol', 'silüet', 'siluet',
  'damla', 'kahve', 'dallan', 'tabağ', 'kıvrıl',
];
/** Short / ambiguous words matched exactly (e.g. "iz" but not "izin" permission, "tabak" but not "tabaka" layer). */
const VISUAL_EXACT = new Set([
  'iz', 'izi', 'izler', 'izleri', 'izde', 'izden', 'ize', 'izlerde', 'izlerin', 'tabak', 'tabakta', 'tabaktaki',
  'dal', 'dalı', 'dallar', 'dalları', 'dallara', 'halka', 'halkası', 'halkalar', 'dip', 'dibi', 'dibinde', 'dibine', 'dibinden',
  'ağzı', 'ağzına', 'ağzından', 'ağzında', 'kenarı', 'kenarında', 'kenarına', 'kenarından',
]);
const VISUAL_PHRASES = ['gibi duran', 'benzeyen bir', 'gözüme çarp', 'dikkatimi çek', 'baktığımda', 'görünen şekil'];
/** Sign / symbol nouns: the sign stays server-side; the reading tells its meaning. */
const SYMBOL_STEMS: ReadonlyArray<{ stems: string[]; except?: string[] }> = [
  { stems: ['kuş'], except: ['kuşku', 'kuşat', 'kuşak'] },
  { stems: ['balık', 'balığ', 'anahtar', 'ağaç', 'ağac', 'yüzük', 'yüzüğ', 'mektup', 'mektub', 'zarf', 'çatal'] },
  // "a heart" names the sign; "kalbin / kalbinde …" (your heart) is life language.
  { stems: ['kalp', 'kalb'], except: ['kalbin', 'kalbim', 'kalbine', 'kalbini', 'kalbinde', 'kalbinden', 'kalbindeki', 'kalbimde', 'kalbiniz'] },
  { stems: ['yılan', 'kelebek', 'köpek', 'kedi', 'uçak', 'gemi', 'taç', 'melek', 'çiçek', 'aslan', 'kartal', 'baykuş', 'örümcek', 'akrep'] },
];

/** Manner adverbial "bir şekilde" (in a … way) is life language, not a shape. */
const VISUAL_EXEMPT = new Set(['şekilde']);

function visualHits(toks: string[]): string[] {
  const hits: string[] = [];
  for (const t of toks) {
    if (VISUAL_EXEMPT.has(t)) continue;
    if (VISUAL_EXACT.has(t) || VISUAL_PREFIXES.some((p) => t.startsWith(p))) hits.push(t);
    else if (SYMBOL_STEMS.some((e) => e.stems.some((s) => t.startsWith(s)) && !e.except?.some((x) => t.startsWith(x)))) hits.push(t);
  }
  for (const p of VISUAL_PHRASES) if (containsPhrase(toks, p)) hits.push(p);
  return hits;
}

const ABSOLUTE = ['kesinlikle', 'mutlaka', 'şüphesiz', 'kuşkusuz', 'garanti', 'yüzde yüz', 'hiç şüphe yok', 'kesin olarak', 'asla'];
const TENTATIVE = /(abilir|ebilir|abilecek|ebilecek|abileceğ|ebileceğ|gibi|görünüyor|olası|ihtimal|belki|sanki|muhtemel|belli belirsiz|hafiften|hissediliyor|seziliyor)/u;
/** Empty, fits-anyone fortune lines. */
const CLICHE = [
  'her şey yoluna girecek', 'yoluna girecek', 'güzel gelişme', 'güzel şeyler', 'güzel günler', 'iyi şeyler', 'iyi haberler',
  'yeni bir sayfa', 'yeni kapılar', 'kapılar ardına kadar', 'şans', 'uğur', 'bolluk', 'evren', 'enerjin', 'olumlu enerji',
  'pozitif enerji', 'yıldızın parlıyor', 'kader', 'mucize', 'rüzgâr değişiyor', 'hayatın değişecek', 'sürpriz',
  'bu falda', 'enerjine baktığımda', 'analize göre',
];
/** Clichés only as a sentence OPENER (inside a sentence they may echo the person's own question). */
const OPENER_CLICHE = ['genel olarak'];
const ADVICE = ['acele etme', 'sabırlı ol', 'dikkat et', 'unutma', 'kendine iyi bak', 'vazgeçme', 'güven bana', 'izin ver'];
/** Bare imperative "bekle" (wait) ending a clause; "bekleyen" etc. are not advice. */
const ADVICE_IMPERATIVE = /(^|\s)bekle[.,!;]/u;
const CLOSING = ['kısacası', 'özetle', 'sonuç olarak', 'toparlarsak', 'yani özetle'];
/** Internal / technical vocabulary (prefixes long enough to never hit ordinary Turkish). */
const META_PREFIXES = ['iddia', 'claim', 'json', 'paragraf', 'gözlem', 'analiz'];
const META_PHRASES = ['yapay zek', 'yorum listesi', 'veriye göre', 'verilere göre'];
const CAUSAL = ['çünkü', 'bu yüzden', 'o yüzden', 'bu sayede', 'sayesinde', 'dolayısıyla', 'sonucunda', 'neden oluyor'];
/** Concrete life events / facts / promises nothing in a cup can ground. */
const SPECIFIC_PREFIXES = [
  'hamile', 'gebelik', 'bebek', 'ölüm', 'ölece', 'hastalık', 'hastane', 'ameliyat', 'boşan', 'ihanet', 'aldat', 'maaş',
  'borç', 'kredi', 'piyango', 'miras', 'mahkeme', 'düğün', 'nişan', 'evlilik', 'evlen', 'yolculuk', 'seyahat', 'taşınma',
  'terfi', 'teklif', 'ihale', 'tayin', 'sınav',
  // Specific people the cup cannot ground (a social-presence claim speaks of "biri / çevren").
  'arkadaş', 'sevgili', 'annen', 'baban', 'eşin', 'patron', 'müdür', 'kardeş', 'komşu', 'akraba',
  'söz veriyorum', 'vaat',
];
const SPECIFIC_EXACT = new Set(['kaza', 'kazası', 'kazada', 'zam', 'zamlar', 'dava', 'davası', 'davada']);
const MONTH_DAY = [
  'şubat', 'mart', 'nisan', 'mayıs', 'haziran', 'temmuz', 'ağustos', 'eylül', 'kasım',
  'pazartesi', 'salı', 'çarşamba', 'perşembe', 'cuma', 'cumartesi',
];
/** Also ordinary words (gap, hearth, sowing, market): a date only when followed by "ay…" / "gün…". */
const AMBIGUOUS_MONTH_DAY = ['aralık', 'ocak', 'ekim', 'pazar'];
/** The asked area's own words count as grounded (the person's question, not a prediction). */
const FOCUS_ANCHORS: Partial<Record<CoffeeV3NPlan['focus']['kind'], string[]>> = {
  custom_decision: ['karar', 'seçenek', 'seçeneğ', 'seçim'],
  love_relationships: ['ilişki', 'aşk', 'gönül', 'gönl', 'sevgi'],
  career_work: ['iş', 'kariyer', 'çalışma'],
  money_finance: ['para', 'maddi', 'kazanç', 'gelir'],
  person_of_interest: ['aklındaki', 'kişi'],
};
/** Sanity floor only (an obviously cut-off paragraph); not a quality measure. */
const MIN_PARAGRAPH_WORDS = 10;
/**
 * Meaningful coverage: prose actually devoted to ONE claim. A sentence that
 * carries k claims gives each 1/k of its words, so a keyword list ("açılım,
 * sakinleşme ve dönüş var") never counts as telling three meanings.
 */
const MIN_DEDICATED_WORDS = 8;
/** A carrying sentence must say something: a predicate in fortune language. */
const PREDICATE = /(yor|abilir|ebilir|abilecek|ebilecek|acak|ecek|gibi|görünüyor|seziliyor|hissediliyor)/u;
/** The supported time of a claim must be conveyed where it is told (any natural equivalent). */
const HORIZON_WORDS: Record<'near' | 'coming' | 'longer', string[]> = {
  near: ['yakın zaman', 'yakında', 'yakın dönem', 'kısa süre', 'kısa zaman', 'çok geçmeden', 'önümüzdeki günler', 'bugünlerde', 'şu sıralar'],
  coming: ['önümüzdeki dönem', 'yaklaşan dönem', 'önündeki günler', 'önümüzdeki günler', 'bundan sonraki', 'önümüzdeki süreç', 'önümüzdeki zaman', 'gelecek dönem'],
  longer: ['uzun vade', 'ilerleyen zaman', 'ilerleyen dönem', 'daha ileride', 'ileride', 'zamanla', 'uzun soluk', 'uzun süre'],
};
/** "In that same period": refers back to a time ALREADY stated in an earlier paragraph. */
const HORIZON_BACKREF = ['aynı dönem', 'aynı zaman', 'aynı süreç', 'bu dönem', 'o dönem'];
/** The supported place (close circle / outer world) must be conveyed where it is told. */
const PLACEMENT_WORDS: Record<'close_circle' | 'outer_world', string[]> = {
  close_circle: ['yakın çevre', 'yakınların', 'kendi dünya', 'sana yakın', 'kendi çevre', 'evin', 'ailen'],
  outer_world: ['dış', 'uzak çevre', 'daha uzak', 'geniş çevre', 'uzaktaki', 'çevrenin dışında'],
};
/**
 * Mechanical style (the first accepted real reading): empty placeholders used
 * over and over, and a hedge in nearly every clause. Objective bounds only.
 */
const PLACEHOLDERS = ['bir konu', 'bir süreç', 'bir şey', 'bir yön'];
const MAX_PLACEHOLDERS = 2;
const HEDGE = /[ae]bilir/u;
const MAX_HEDGES_PER_SENTENCE = 1;
/** A definite second-person future ("…acaksın") states a prediction as fact. */
const CERTAIN_FUTURE = /(acaksın|eceksin|acaksınız|eceksiniz)$/u;

const UPPER = /^[A-ZÇĞİÖŞÜ]/u;

export function acceptCoffeeV3Narrative(plan: CoffeeV3NPlan, raw: string): CoffeeV3NAcceptance {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { ok: false, failures: ['malformed_json'], details: [], findings: [{ code: 'malformed_json', paragraph: null, claim: null, term: null }], metrics: null };
  }
  const paragraphs = (parsed as { paragraphs?: unknown })?.paragraphs;
  if (
    !Array.isArray(paragraphs) ||
    paragraphs.length !== plan.paragraphs.length ||
    paragraphs.some((p, i) =>
      !p || typeof p !== 'object' ||
      typeof (p as { text?: unknown }).text !== 'string' || !(p as { text: string }).text.trim() ||
      !Array.isArray((p as { claims?: unknown }).claims) ||
      JSON.stringify((p as { claims: unknown[] }).claims) !== JSON.stringify(plan.paragraphs[i].claims))
  ) {
    return { ok: false, failures: ['paragraph_structure'], details: [], findings: [{ code: 'paragraph_structure', paragraph: null, claim: null, term: null }], metrics: null };
  }
  const texts = (paragraphs as Array<{ text: string }>).map((p) => p.text.trim());
  const reading = texts.join('\n\n');
  const all = sentencesOf(reading);
  const metrics: CoffeeV3NMetrics = { paragraphs: texts.length, sentences: all.length, words: words(reading).length };
  const failures = new Set<CoffeeV3NFailure>();
  const details: string[] = [];
  const findings: CoffeeV3NFinding[] = [];
  const fail = (f: CoffeeV3NFailure, d: string, where: { paragraph?: number; claim?: string; term?: string } = {}) => {
    failures.add(f);
    details.push(`${f}:${d}`);
    findings.push({ code: f, paragraph: where.paragraph ?? null, claim: where.claim ?? null, term: where.term ?? null });
  };
  /** Paragraph (1-based) of a sentence of the whole reading. */
  const paragraphOfSentence: number[] = texts.flatMap((t, i) => sentencesOf(t).map(() => i + 1));
  const claimById = new Map(plan.claims.map((c) => [c.id, c]));

  // 1) The product rule: life meaning only — never the cup, its shapes or positions.
  texts.forEach((t, i) => {
    for (const hit of visualHits(tokens(t))) fail('visual_description', hit, { paragraph: i + 1, term: hit });
  });

  // 2) Substance follows the evidence: no fixed sentence count, but neither thin nor padded.
  if (metrics.words < plan.budget.minWords) fail('too_thin', `words=${metrics.words}<${plan.budget.minWords}`);
  texts.forEach((t, i) => { if (words(t).length < MIN_PARAGRAPH_WORDS) fail('too_thin', `paragraph${i + 1}_words`, { paragraph: i + 1 }); });
  if (metrics.words > plan.budget.maxWords) fail('padded', `words=${metrics.words}>${plan.budget.maxWords}`);

  // 3) Meaning coverage — what decides premium, not length: every planned claim
  //    is told where planned, with prose genuinely devoted to it (not a keyword
  //    mention), carried by a predicate in fortune language, and with its
  //    supported time / place conveyed. Most sentences must carry a supported
  //    meaning (or the person's own question): fluent generic filler is refused.
  const focusAnchors = FOCUS_ANCHORS[plan.focus.kind] ?? [];
  let filler = 0;
  const horizonsStated = new Set<string>();
  texts.forEach((t, i) => {
    const paragraph = i + 1;
    const toks = tokens(t);
    const ids = plan.paragraphs[i].claims;
    const statesHorizon = (h: 'near' | 'coming' | 'longer') =>
      HORIZON_WORDS[h].some((w) => containsPhrase(toks, w)) ||
      (horizonsStated.has(h) && HORIZON_BACKREF.some((w) => containsPhrase(toks, w)));
    const carried = sentencesOf(t).map((s) => {
      const st = tokens(s);
      return { st, words: words(s).length, claims: ids.filter((id) => (claimById.get(id)?.anchors ?? []).some((a) => containsPhrase(st, a))) };
    });
    for (const id of ids) {
      const claim = claimById.get(id)!;
      const carriers = carried.filter((c) => c.claims.includes(id));
      if (carriers.length === 0) {
        fail('ungrounded_claim', id, { paragraph, claim: id });
        continue;
      }
      const dedicated = carriers.reduce((sum, c) => sum + c.words / c.claims.length, 0);
      const predicated = carriers.some((c) => PREDICATE.test(c.st.join(' ')));
      if (dedicated < MIN_DEDICATED_WORDS || !predicated) {
        fail('claim_underdeveloped', `${id}:dedicated_words=${Math.round(dedicated)}${predicated ? '' : ':no_predicate'}`, { paragraph, claim: id });
      }
      if (claim.horizon && !statesHorizon(claim.horizon)) {
        fail('claim_incomplete', `${id}:horizon=${claim.horizon}`, { paragraph, claim: id, term: claim.horizon });
      }
      if (claim.placement && !PLACEMENT_WORDS[claim.placement].some((h) => containsPhrase(toks, h))) {
        fail('claim_incomplete', `${id}:placement=${claim.placement}`, { paragraph, claim: id, term: claim.placement });
      }
    }
    for (const c of carried) if (c.claims.length === 0 && !focusAnchors.some((a) => containsPhrase(c.st, a))) filler += 1;
    for (const h of ['near', 'coming', 'longer'] as const) if (HORIZON_WORDS[h].some((w) => containsPhrase(toks, w))) horizonsStated.add(h);
  });
  if (filler > Math.max(1, Math.floor(all.length * 0.25))) fail('generic_filler', `ungrounded_sentences=${filler}/${all.length}`);

  // 4) Repetition: identical sentences, repeated 4-grams, mechanical openers.
  const normalized = all.map((s) => tokens(s).join(' '));
  if (new Set(normalized).size !== normalized.length) fail('repetitive', 'duplicate_sentence');
  const grams = new Map<string, number>();
  for (const s of normalized) {
    const w = s.split(' ');
    for (let i = 0; i + 4 <= w.length; i += 1) {
      const g = w.slice(i, i + 4).join(' ');
      grams.set(g, (grams.get(g) ?? 0) + 1);
    }
  }
  for (const [g, n] of grams) if (n > 1) fail('repetitive', `4gram:${g}`, { term: g });
  const openers = normalized.map((s) => s.split(' ')[0]);
  for (let i = 1; i < openers.length; i += 1) {
    if (openers[i] && openers[i] === openers[i - 1]) fail('repetitive', `adjacent_opener:${openers[i]}`, { paragraph: paragraphOfSentence[i], term: openers[i] });
  }
  if (openers.length >= 4) {
    const counts = new Map<string, number>();
    for (const o of openers) counts.set(o, (counts.get(o) ?? 0) + 1);
    for (const [o, n] of counts) if (n / openers.length > 0.4) fail('repetitive', `opener_share:${o}`, { term: o });
  }

  // 4b) Mechanical style: detached "… -abilir" statements built on placeholders.
  {
    const toks = tokens(reading);
    let placeholders = 0;
    for (let k = 0; k + 1 < toks.length; k += 1) {
      if (PLACEHOLDERS.some((p) => { const [a, b] = tokens(p); return toks[k] === a && toks[k + 1].startsWith(b); })) placeholders += 1;
    }
    if (placeholders > MAX_PLACEHOLDERS) fail('mechanical_style', `placeholders=${placeholders}>${MAX_PLACEHOLDERS}`, { term: 'placeholders' });
    const hedges = toks.filter((t) => HEDGE.test(t)).length;
    if (all.length > 0 && hedges > all.length * MAX_HEDGES_PER_SENTENCE) {
      fail('mechanical_style', `hedges=${hedges}/${all.length}_sentences`, { term: 'hedging' });
    }
  }

  // 5) Language and safety.
  texts.forEach((t, i) => {
    const paragraph = i + 1;
    const toks = tokens(t);
    const at = (term: string) => ({ paragraph, term });
    for (const p of CLICHE) if (containsPhrase(toks, p)) fail('generic_cliche', p, at(p));
    // An opener-only cliché ("Genel olarak, …"); the same words inside a sentence
    // may simply echo the person's own question ("Önümüzdeki dönem genel olarak").
    for (const s of sentencesOf(t)) {
      const st = tokens(s);
      for (const p of OPENER_CLICHE) if (containsPhrase(st.slice(0, tokens(p).length), p)) fail('generic_cliche', p, at(p));
    }
    for (const p of ABSOLUTE) if (containsPhrase(toks, p, true)) fail('absolute_certainty', p, at(p));
    if (!TENTATIVE.test(fold(t))) fail('not_tentative', `paragraph${paragraph}`, { paragraph });
    // Imperatives match whole tokens: "acele etme" is advice, "acele etmeden" is not.
    for (const p of ADVICE) if (containsPhrase(toks, p, true)) fail('advice_or_command', p, at(p));
    if (ADVICE_IMPERATIVE.test(fold(t))) fail('advice_or_command', 'bekle', at('bekle'));
    for (const p of CLOSING) if (containsPhrase(toks, p)) fail('closing_summary', p, at(p));
    for (const p of CAUSAL) if (containsPhrase(toks, p)) fail('causal_link', p, at(p));
    for (const p of META_PHRASES) if (containsPhrase(toks, p)) fail('meta_language', p, at(p));
    toks.forEach((tok, j) => {
      if (META_PREFIXES.some((m) => tok.startsWith(m))) fail('meta_language', tok, at(tok));
      if (MONTH_DAY.includes(tok) || SPECIFIC_EXACT.has(tok) || SPECIFIC_PREFIXES.some((p) => !p.includes(' ') && tok.startsWith(p))) fail('unsupported_specific', tok, at(tok));
      if (AMBIGUOUS_MONTH_DAY.includes(tok) && /^(ay|gün)/u.test(toks[j + 1] ?? '')) fail('unsupported_specific', `${tok} ${toks[j + 1]}`, at(`${tok} ${toks[j + 1]}`));
    });
    for (const p of SPECIFIC_PREFIXES) if (p.includes(' ') && containsPhrase(toks, p)) fail('unsupported_specific', p, at(p));
    if (/\d/u.test(t)) fail('unsupported_specific', 'digit', at('digit'));
    for (const tok of toks) if (CERTAIN_FUTURE.test(tok)) fail('certain_prediction', tok, at(tok));
    for (const s of sentencesOf(t)) {
      const ws = s.split(/\s+/);
      for (let k = 1; k < ws.length; k += 1) {
        // A full sentence may start with a capital after a colon (TDK); that is not a name.
        if (/:["'“«]?$/u.test(ws[k - 1])) continue;
        const clean = ws[k].replace(/^[^\p{L}]+/u, '');
        // The suspected name itself is never recorded (redacted).
        if (UPPER.test(clean)) fail('proper_name', clean.replace(/[^\p{L}]+$/u, ''), { paragraph, term: '[redacted]' });
      }
    }
  });
  // Contradiction, scoped to the meaning the words modify: a claim's avoid term
  // is judged per SENTENCE. It contradicts the claim when that sentence tells
  // the claim (carries its anchors) — even if it also tells another claim
  // (ownership is then ambiguous). A sentence that tells only OTHER claims
  // attributes the term to them (a paragraph may legitimately join a
  // continuous opening and an intermittent course). A sentence that tells no
  // claim cannot be attributed and is refused, never assumed harmless.
  texts.forEach((t, i) => {
    const ids = plan.paragraphs[i].claims;
    for (const s of sentencesOf(t)) {
      const st = tokens(s);
      const tells = ids.filter((cid) => (claimById.get(cid)?.anchors ?? []).some((a) => containsPhrase(st, a)));
      for (const id of ids) {
        for (const a of claimById.get(id)?.avoid ?? []) {
          if (!containsPhrase(st, a)) continue;
          if (tells.includes(id)) fail('contradiction', `${id}:${a}`, { paragraph: i + 1, claim: id, term: a });
          else if (tells.length === 0) fail('contradiction', `${id}:${a}:unattributed`, { paragraph: i + 1, claim: id, term: a });
        }
      }
    }
  });
  // Person-of-interest bans from the trusted intention.
  if (plan.focus.forbiddenAssumptions.includes('reciprocal_feeling') && /(seni seviyor|sana aşık|seni düşünüyor|sana karşı hisler)/u.test(fold(reading))) {
    fail('unsupported_specific', 'reciprocal_feeling', { term: 'reciprocal_feeling' });
  }

  if (failures.size) return { ok: false, failures: [...failures], details, findings, metrics };
  return { ok: true, reading, metrics };
}
