import type { CoffeeTrustedIntentionContext } from './coffee-intention-context.js';
import { coffeeM1MarkSign, type CoffeeM1Sign } from './coffee-m1-interpretation.js';
import type { CoffeeV3MapMark, CoffeeV3MarkMap } from './coffee-v3-mark-map.js';
import type { CoffeeV3CupBand, CoffeeV3SaucerZone } from './types.js';

/**
 * V3N1 — Coffee V3 NARRATIVE successor: grounded meaning + narrative plan.
 *
 * The frozen M2 → W2 chain (kept intact for its own regression coverage)
 * compresses every structural cup into at most three families and drops the
 * saucer, so a real cup becomes one or two generic sentences. This versioned
 * successor reads the SAME validated mark map (same observer, same schema,
 * same cross-view identity groups) and keeps what M2 discards — form,
 * topology, band, band span, handle side, grouping, cross-mark relations and
 * physically supported saucer evidence — as grounded CLAIMS, each with its
 * provenance. It never reads observer prose and never invents a sign:
 * - one claim per identity group (a mark seen in both cup photos, or a
 *   possible-same pair, is ONE claim), and same-theme / same-place claims are
 *   merged (never two claims for one reading of the cup);
 * - a symbol is named only for a strong candidate on a clearly seen mark
 *   (the map's `usable`), through the existing curated M1 lexicon;
 * - the saucer contributes only when something is physically there (a flow,
 *   or a mark that itself yields a claim); a clean / film saucer adds nothing;
 * - too few grounded claims is an honest `insufficient`, never padded.
 * Writer-visible text is built ONLY from closed enums and closed Turkish
 * tables below.
 */

export type CoffeeV3NTheme =
  | 'object'
  | 'opening'
  | 'completion'
  | 'options'
  | 'turn'
  | 'rising'
  | 'settling'
  | 'steady_path'
  | 'path'
  | 'weight'
  | 'many_details'
  | 'wish_gathering'
  | 'release'
  | 'circulating';

export type CoffeeV3NHorizon = 'near' | 'coming' | 'longer';
export type CoffeeV3NPlacement = 'close_circle' | 'outer_world';
export type CoffeeV3NTone = 'hopeful' | 'neutral' | 'calm';

export type CoffeeV3NProvenance = {
  surface: 'cup' | 'saucer';
  identityGroups: string[];
  marks: string[];
  slots: string[];
  /** The same physical mark was trusted in both cup photos. */
  seenInBothCupViews: boolean;
};

/** One grounded idea the reading may say. Writer-visible except `provenance`. */
export type CoffeeV3NClaim = {
  id: string;
  theme: CoffeeV3NTheme;
  surface: 'cup' | 'saucer';
  /**
   * SERVER-SIDE evidence only: what was seen, as a Turkish phrase built from
   * enums. Never sent to the writer, never shown to the user (the reading
   * tells life meaning, not the cup).
   */
  seen: string;
  /** The licensed interpretive core, in Turkish. */
  meaning: string;
  /** Licensed elaborations of THIS meaning (no new prediction). */
  elaborations: string[];
  /** Licensed qualities (tempo, scope, multiplicity) in Turkish. */
  qualities: string[];
  /**
   * Everyday life developments a fortune teller reads from THIS meaning
   * (a message, an offer, a reconciliation, a short trip …), told by the
   * writer as possibilities. Nothing outside them may be added.
   */
  lifeScenes: string[];
  /** SERVER-SIDE: event words this meaning licenses (else refused as unsupported). Never sent. */
  licensedEvents: string[];
  horizon: CoffeeV3NHorizon | null;
  placement: CoffeeV3NPlacement | null;
  /** SERVER-SIDE evidence only: the recognized sign, or null. Never sent / shown. */
  symbol: string | null;
  /**
   * SERVER-SIDE acceptance anchors: word stems one of which must appear where
   * this claim is told — proof the text says THIS meaning, not a generic line.
   */
  anchors: string[];
  certainty: 'clear' | 'soft';
  /**
   * The claim's place in the STORY (not in the cup): `core` is the reading's
   * central development (the strongest, best-supported meaning and what is
   * visually linked to it), `support` is told briefly beside or inside it,
   * `minor` is optional colour the writer may leave out. A reading is one
   * development, not one explanation per meaning.
   */
  weight: CoffeeV3NWeight;
  tone: CoffeeV3NTone;
  /** Words that would contradict or overreach this claim. */
  avoid: string[];
  salience: number;
  provenance: CoffeeV3NProvenance;
};

export type CoffeeV3NLink = { a: string; b: string; kind: 'linked' | 'crossing' | 'within' };

export type CoffeeV3NWeight = 'core' | 'support' | 'minor';

export type CoffeeV3NParagraph = { role: 'opening' | 'development' | 'saucer'; claims: string[] };

export type CoffeeV3NFocus = {
  kind: CoffeeTrustedIntentionContext['subjectKind'] | 'none';
  /** The user's own question, verbatim (the only user-provided text). */
  userDeclaredIntention: string | null;
  /** Turkish name of the asked area, or null for general. */
  area: string | null;
  /** Never assert these about the user / others. */
  forbiddenAssumptions: string[];
};

export type CoffeeV3NPlan = {
  status: 'planned' | 'insufficient';
  reason: 'no_grounded_claims' | 'below_min_claims' | null;
  focus: CoffeeV3NFocus;
  claims: CoffeeV3NClaim[];
  links: CoffeeV3NLink[];
  paragraphs: CoffeeV3NParagraph[];
  budget: { minWords: number; maxWords: number };
};

/** Fewer grounded claims than this cannot carry a reading worth paying for. */
export const COFFEE_V3N_MIN_CLAIMS = 3;

// ---------------------------------------------------------------------------
// Closed Turkish tables
// ---------------------------------------------------------------------------

type ThemeText = { meaning: string; elaborations: string[]; tone: CoffeeV3NTone; avoid: string[]; salience: number };

/**
 * Life meanings in the reader's own world, never placeholders ("bir konu",
 * "bir süreç", "bir şey"): the writer re-tells these notes, so a placeholder
 * here became a placeholder in the real reading. A meaning / elaboration
 * never uses another theme's acceptance anchor (see the overlap test): a
 * shared word would attribute one claim's sentence to another.
 */
const THEME_TEXT: Record<Exclude<CoffeeV3NTheme, 'object'>, ThemeText> = {
  opening: {
    meaning: 'önünün açılması, içini ferahlatan bir genişlik',
    elaborations: ['daha rahat hareket edebileceğin bir alan', 'derin bir nefes aldıran bir açılım'],
    tone: 'hopeful', avoid: ['kapanıyor', 'tıkanıyor'], salience: 4,
  },
  completion: {
    meaning: 'elindeki işlerin toparlanıp tamamlanması, bir dönemin olgunlaşarak kapanması',
    elaborations: ['yarım kalanların yerli yerine oturması', 'emeklerinin bir bütün hâline gelmesi'],
    tone: 'neutral', avoid: ['yarıda kalıyor'], salience: 3,
  },
  options: {
    meaning: 'önünde birden fazla seçeneğin, bir yol ayrımının belirmesi',
    elaborations: ['seçeneklerin zamanla birbirinden ayrışması', 'seçenekleri tek tek tartıp sana yakın olanı arama ihtiyacı'],
    tone: 'neutral', avoid: ['tek seçenek', 'doğru seçenek', 'yanlış seçenek'], salience: 3,
  },
  turn: {
    meaning: 'planlarında beklenmedik bir dönüş, alışık olduğun düzenin değişmesi',
    elaborations: ['planladığından farklı bir rotaya dönme', 'hiç hesaba katmadığın anda gelen bir dönüş'],
    tone: 'neutral', avoid: ['taşınma'], salience: 3,
  },
  rising: {
    meaning: 'attığın adımların ivme kazanması, emeklerinin yükselişe geçmesi',
    elaborations: ['adım adım güçlenen bir ilerleyiş', 'giderek hız kazanan bir hareket'],
    tone: 'hopeful', avoid: ['düşüş', 'geriliyor', 'geriye gidiyor'], salience: 3,
  },
  settling: {
    meaning: 'zihnini yoran telaşın yavaş yavaş durulması, günlerinin sakinleşmesi',
    elaborations: ['içindeki dalgalanmanın yatışması', 'telaşın azaldığı, daha dingin günler'],
    tone: 'calm', avoid: ['hızlanıyor', 'alevleniyor'], salience: 2,
  },
  steady_path: {
    meaning: 'istikrarlı ve sağlam adımlarla ilerleyen bir dönem',
    elaborations: ['acele etmeden ama durmadan süren bir ilerleyiş', 'sağlam adımlarla süren bir ilerleme'],
    tone: 'hopeful', avoid: ['kesik kesik', 'ara ara', 'duraksıyor'], salience: 2,
  },
  path: {
    meaning: 'hayatında hareketlenen, yol almaya başlayan bir gidişat',
    elaborations: ['durgun kalan işlerinin yeniden yol alması', 'adım adım ilerlemeye başlayan bir gidişat'],
    tone: 'neutral', avoid: ['taşınma'], salience: 2,
  },
  weight: {
    meaning: 'önümüzdeki dönemde zihnini ve vaktini daha çok meşgul edecek bir mesele',
    elaborations: ['dikkatini kendine çeken, üzerinde durmak isteyeceğin bir mesele', 'gündeminde öne çıkan bir ağırlık'],
    tone: 'calm', avoid: ['felaket', 'kötü haber', 'dert'], salience: 2,
  },
  many_details: {
    meaning: 'küçük işlerle, ayrıntılarla ve koşturmacayla dolu hareketli günler',
    elaborations: ['birçok küçük işin aynı anda yürümesi', 'kalabalık ama dağınık olmayan, canlı bir tempo'],
    tone: 'neutral', avoid: ['kaos', 'karmaşa'], salience: 1,
  },
  wish_gathering: {
    meaning: 'içinde taşıdığın bir dileğin ya da isteğin bir araya toplanıp netleşmesi',
    elaborations: ['dağınık duran isteklerinin tek bir dilekte birleşmesi', 'aklındaki dileğin merkeze yerleşmesi'],
    tone: 'hopeful', avoid: ['gerçekleşti', 'kesin olacak'], salience: 2,
  },
  release: {
    meaning: 'içinde tuttuklarını dışa vurman, dile dökünce gelen hafiflik',
    elaborations: ['omuzlarındaki yükün hafiflemesi', 'içindekileri paylaşma ihtiyacı'],
    tone: 'calm', avoid: ['kayıp', 'kaybedeceksin'], salience: 2,
  },
  circulating: {
    meaning: 'zihninde dönüp dolaşan, olgunlaşmayı bekleyen düşünceler',
    elaborations: ['aynı düşüncelere tekrar tekrar dönüp bakmak'],
    tone: 'neutral', avoid: ['kısır döngü', 'çıkmaz'], salience: 1,
  },
};

/**
 * Acceptance anchors per theme / sign (stems; matched at token starts). A stem
 * ending in k / ç also lists its softened form (seçenek → seçeneğin, dilek →
 * dileğin), otherwise a correctly told claim would read as untold.
 */
const THEME_ANCHORS: Record<Exclude<CoffeeV3NTheme, 'object'>, string[]> = {
  opening: ['açıl', 'açılım', 'ferah', 'nefes', 'rahatla', 'rahatlık', 'önünün aç', 'genişl', 'rahat hareket', 'çözül'],
  completion: ['tamamlan', 'toparlan', 'yerine otur', 'olgunlaş', 'kapanış', 'netleş', 'bir bütün', 'sonuçlan'],
  options: ['seçenek', 'seçeneğ', 'ihtimal', 'yön', 'alternatif', 'seçim', 'yol ayrım', 'teklif', 'karar'],
  turn: ['yön', 'dönüş', 'değiş', 'beklenmedik', 'rota'],
  rising: ['ivme', 'yüksel', 'güçlen', 'yükseliş', 'ilerle', 'hız kazan', 'karşılık bul'],
  // Not the bare stem 'telaş': it also starts 'telaşlı' (many_details) and would
  // attribute a busy-days sentence to the settling claim.
  settling: ['durul', 'sakinleş', 'yatış', 'yerine otur', 'telaşın', 'telaş azal', 'düzel', 'yumuşa', 'barış'],
  steady_path: ['istikrar', 'kararlı', 'sağlam', 'durmadan', 'ilerle'],
  path: ['ilerle', 'hareketlen', 'gidişat', 'yol al', 'yolculuk', 'seyahat', 'yola çık'],
  weight: ['ağırlık', 'ağırlığ', 'gündem', 'dikkat', 'meşgul', 'mesele'],
  many_details: ['ayrıntı', 'küçük iş', 'hareketli', 'yoğun', 'telaşlı', 'koşturma', 'kalabalık', 'koşuştur', 'ayak iş'],
  wish_gathering: ['dilek', 'dileğ', 'istek', 'isteğ', 'netleş', 'toplan'],
  // 'hafifl' covers hafifleme / hafiflik / hafifliyor (the plan itself says "hafiflik").
  release: ['hafifl', 'rahatla', 'rahatlık', 'paylaş', 'dışa vur', 'içini dök', 'dile dök', 'söze dök', 'dertleş', 'sohbet', 'dile getir'],
  circulating: ['yeniden gündem', 'olgunlaş', 'dönüp dolaş', 'tekrar tekrar', 'kafa yor'],
};
const SIGN_ANCHORS: Record<CoffeeM1Sign, string[]> = {
  incoming_contact: ['haber', 'iletişim', 'ses', 'mesaj', 'telefon', 'konuşma'],
  written_contact: ['yazı', 'mesaj', 'haber', 'not', 'evrak'],
  opportunity: ['kısmet', 'fırsat', 'imkân', 'bereket', 'kazanç', 'teklif'],
  commitment: ['bağ', 'söz', 'güven', 'bağlılık', 'anlaşma'],
  emotion: ['duygu', 'gönl', 'gönül', 'his', 'yakınlaş', 'barış', 'aşk', 'sevgi'],
  access: ['kapı', 'çıkış', 'aralan', 'açıl', 'çözül'],
  direction: ['yön', 'gidişat', 'yolculuk', 'seyahat', 'yola çık'],
  growth: ['büyü', 'kök', 'filiz', 'gelişme', 'meyve'],
  choice: ['seçim', 'karar', 'seçenek', 'seçeneğ', 'teklif'],
  social_presence: ['çevre', 'biri', 'insan', 'kişi', 'tanıdık', 'karşılaş', 'arkadaş'],
};

/** Curated M1 signs → licensed symbol noun + meaning. Never anything outside the M1 lexicon. */
const SIGN_TEXT: Record<CoffeeM1Sign, ThemeText & { symbol: string }> = {
  incoming_contact: { symbol: 'kuş', meaning: 'bir haber ya da beklemediğin bir iletişim', elaborations: ['sana doğru gelen bir ses', 'bir haberin sana ulaşması'], tone: 'hopeful', avoid: ['kesin haber', 'kimden'], salience: 5 },
  written_contact: { symbol: 'mektup', meaning: 'yazılı bir haber ya da bir mesaj', elaborations: ['eline geçecek bir yazı, bir not'], tone: 'hopeful', avoid: ['kimden'], salience: 5 },
  opportunity: { symbol: 'balık', meaning: 'bir kısmet ya da bir fırsat', elaborations: ['bereketli bir dönem', 'eline geçebilecek bir imkân'], tone: 'hopeful', avoid: ['para kazanacaksın', 'zengin'], salience: 5 },
  commitment: { symbol: 'yüzük', meaning: 'bir bağlılık, verilen bir söz ya da derinleşen bir bağ', elaborations: ['sözün ve güvenin önem kazanması'], tone: 'hopeful', avoid: ['evlilik', 'nişan', 'düğün'], salience: 5 },
  emotion: { symbol: 'kalp', meaning: 'gönlünü kıpırdatan bir duygu', elaborations: ['duygularının ön plana çıkması', 'gönlünün kıpırdanması'], tone: 'hopeful', avoid: ['aşık olacak', 'seni seviyor'], salience: 5 },
  access: { symbol: 'anahtar', meaning: 'bir kapının açılması, bir çıkış yolunun eline geçmesi', elaborations: ['kapalı görünen bir kapının aralanması'], tone: 'hopeful', avoid: ['kesin çözüm'], salience: 5 },
  direction: { symbol: 'yol', meaning: 'hayatının yönünün yeniden çizilmesi', elaborations: ['gidişatının belirginleşmesi'], tone: 'neutral', avoid: ['taşınma'], salience: 4 },
  growth: { symbol: 'ağaç', meaning: 'zamanla büyüyen, kök salan bir gelişme', elaborations: ['yavaş ama kalıcı bir büyüme', 'emeklerin zamanla filizlenmesi'], tone: 'hopeful', avoid: ['hızla', 'birdenbire', 'aniden'], salience: 5 },
  choice: { symbol: 'çatal', meaning: 'bir seçim anı, iki yol arasında bir karar', elaborations: ['seçeneklerin birbirinden ayrışması'], tone: 'neutral', avoid: ['doğru seçenek', 'yanlış seçenek'], salience: 4 },
  social_presence: { symbol: 'insan', meaning: 'çevrende belirginleşen biri ya da bir çevre', elaborations: ['hayatında varlığı belirginleşen biri'], tone: 'neutral', avoid: ['seni seviyor', 'ihanet', 'düşman'], salience: 4 },
};

/**
 * Life scenes: the concrete, everyday developments an experienced fortune
 * teller reads from each meaning — what lets a reading say "a half-finished
 * conversation may reopen" instead of "a matter may change". They never add a
 * meaning: each scene restates its own theme in life terms (own anchors,
 * no other theme's words — see the table tests).
 */
const THEME_SCENES: Record<Exclude<CoffeeV3NTheme, 'object'>, string[]> = {
  opening: ['sıkışan bir işin çözülmeye başlaması', 'beklenen bir cevabın gelip içini rahatlatması'],
  completion: ['yarım kalmış bir işin sonunda tamamlanması', 'uzun süren bir uğraşın sonuçlanması'],
  options: ['iki teklif ya da iki yol arasında kalmak', 'önüne gelen seçenekler arasında bir karar anı'],
  turn: ['planların son anda değişmesi', 'beklenmedik bir durumun bütün dengeleri değiştirmesi'],
  rising: ['emeklerinin görülmesi, iş tarafında bir yükseliş', 'çabalarının karşılık bulmaya başlaması'],
  settling: ['bir gerginliğin yatışması, araların düzelmesi', 'zihnini yoran bir durumun yumuşayıp çözüme varması'],
  steady_path: ['adım adım ilerleyen bir işin sağlamlaşması'],
  path: ['yola çıkma, kısa bir yolculuk', 'durgun işlerin yeniden hareketlenmesi'],
  weight: ['üzerinde çok düşündüğün bir meselenin gündemini doldurması'],
  many_details: ['küçük işler, ayak işleri ve koşuşturmalarla dolu günler'],
  wish_gathering: ['tuttuğun bir dileğin gerçeğe yaklaşması'],
  release: ['içini dökeceğin, dertleşeceğin bir sohbet', 'içinde tuttuklarını sonunda dile getirmek'],
  circulating: ['aynı düşüncelere dönüp dolaşıp yeniden kafa yormak'],
};
const SIGN_SCENES: Record<CoffeeM1Sign, string[]> = {
  incoming_contact: ['bir mesaj, bir telefon ya da uzaktan gelen bir haber', 'yarım kalmış bir konuşmanın yeniden başlaması'],
  written_contact: ['yazılı bir haber, bir mesaj ya da beklenen bir evrak'],
  opportunity: ['iş ya da para tarafında bir kısmet, bir teklif', 'umulmadık bir yerden gelen kazanç'],
  commitment: ['bir anlaşmanın, bir sözün ya da ilişkide atılacak bir adımın konuşulması'],
  emotion: ['gönül tarafında bir kıpırdanma, bir yakınlaşma', 'araya giren bir küslüğün bitip barışmaya varması'],
  access: ['tıkanan bir işin çözülmesi', 'kapalı görünen bir kapının, bir görüşmenin ya da başvurunun aralanması'],
  direction: ['bir yolculuk ya da hayatının yönünü belirleyen bir adım'],
  growth: ['emeklerinin zamanla meyve vermesi'],
  choice: ['iki teklif ya da iki yol arasında bir karar'],
  social_presence: ['hayatına yeni girecek ya da yeniden görünecek biri', 'bir tanıdıkla tesadüfi bir karşılaşma'],
};
/**
 * Event words the quality gate refuses unless a meaning in THIS reading
 * licenses them (a road / path sign licenses a trip; a fish, options or a
 * fork licenses an offer; a bird, letter or person sign licenses a friend).
 */
const THEME_LICENSES: Partial<Record<Exclude<CoffeeV3NTheme, 'object'>, string[]>> = {
  options: ['teklif'],
  path: ['yolculuk', 'seyahat'],
};
const SIGN_LICENSES: Partial<Record<CoffeeM1Sign, string[]>> = {
  incoming_contact: ['arkadaş', 'komşu'],
  written_contact: ['arkadaş'],
  opportunity: ['teklif'],
  direction: ['yolculuk', 'seyahat'],
  choice: ['teklif'],
  social_presence: ['arkadaş', 'komşu'],
};

const SHAPE: Record<Exclude<CoffeeV3NTheme, 'object' | 'wish_gathering' | 'release' | 'circulating'>, string> = {
  opening: 'telvenin çekildiği açık, ferah bir alan',
  completion: 'kendi etrafında kapanan halka gibi bir şekil',
  options: 'dallara ayrılan bir iz',
  turn: 'kıvrılarak yön değiştiren bir iz',
  rising: 'yukarı doğru uzanan bir çizgi',
  settling: 'aşağıya doğru inen bir iz',
  steady_path: 'düz ve kesintisiz ilerleyen bir çizgi',
  path: 'ince bir yol gibi uzanan bir iz',
  weight: 'koyulaşıp toplanmış bir telve',
  many_details: 'küçük küçük kümelenmiş izler',
};

const BAND_PLACE: Record<CoffeeV3CupBand, string> = {
  rim_upper: 'fincanın ağzına yakın',
  middle: 'fincanın ortalarında',
  lower_base: 'fincanın dibine doğru',
};
/** A mark explicitly seen crossing bands (rim → base span): where it lies, as a bounded place. */
const SPAN_PLACE: Record<string, string> = {
  'rim_upper>middle': 'fincanın ağzından ortalarına kadar',
  'rim_upper>lower_base': 'fincanın ağzından dibine kadar',
  'middle>lower_base': 'fincanın ortalarından dibine kadar',
};
/** A spanning line WITH a vertical direction is described by that direction (never "spans down, rises up"). */
const SPAN_RISING: Record<string, string> = {
  'rim_upper>middle': 'fincanın ortalarından ağzına doğru yükselen bir çizgi',
  'rim_upper>lower_base': 'fincanın dibinden ağzına doğru yükselen bir çizgi',
  'middle>lower_base': 'fincanın dibinden ortalarına doğru yükselen bir çizgi',
};
const SPAN_SETTLING: Record<string, string> = {
  'rim_upper>middle': 'fincanın ağzından ortalarına doğru inen bir iz',
  'rim_upper>lower_base': 'fincanın ağzından dibine doğru inen bir iz',
  'middle>lower_base': 'fincanın ortalarından dibine doğru inen bir iz',
};
const SAUCER_PLACE: Record<Exclude<CoffeeV3SaucerZone, 'unknown'>, string> = {
  center: 'tabağın ortasında',
  middle_ring: 'tabağın orta kısmında',
  edge: 'tabağın kenarında',
};
const HORIZON_BY_BAND: Record<CoffeeV3CupBand, CoffeeV3NHorizon> = { rim_upper: 'near', middle: 'coming', lower_base: 'longer' };

const AREA: Partial<Record<CoffeeTrustedIntentionContext['subjectKind'], string>> = {
  love_relationships: 'aşk ve ilişkiler',
  career_work: 'iş ve kariyer',
  money_finance: 'para ve maddi konular',
  person_of_interest: 'aklındaki kişi',
  custom_decision: 'vermen gereken bir karar',
};

// ---------------------------------------------------------------------------
// Grounded claims
// ---------------------------------------------------------------------------

type Draft = Omit<CoffeeV3NClaim, 'id'>;

const knownBands = (marks: CoffeeV3MapMark[]): CoffeeV3CupBand[] => {
  const bands = new Set<CoffeeV3CupBand>();
  for (const m of marks) {
    for (const b of m.bandSpan ?? []) bands.add(b);
    if (m.band && m.band !== 'unknown') bands.add(m.band as CoffeeV3CupBand);
  }
  return (['rim_upper', 'middle', 'lower_base'] as const).filter((b) => bands.has(b));
};

/** A value every member of a (possible-same) group agrees on, else 'unknown'. */
function agreed<T extends string>(values: T[]): T | 'unknown' {
  const set = new Set(values);
  return set.size === 1 ? values[0] : 'unknown';
}

/** Theme of one identity group from its physical form only (null = context, no claim). */
function structuralTheme(marks: CoffeeV3MapMark[]): Exclude<CoffeeV3NTheme, 'object' | 'wish_gathering' | 'release' | 'circulating'> | null {
  if (marks.every((m) => m.kind === 'clear_area')) return 'opening';
  if (marks.some((m) => m.kind === 'clear_area')) return null; // a residue/clear disagreement is never resolved by guessing
  const topology = agreed(marks.map((m) => m.topology));
  const course = agreed(marks.map((m) => m.form.course));
  const vertical = agreed(marks.map((m) => m.form.verticalDirection));
  const continuity = agreed(marks.map((m) => m.form.continuity));
  const grouping = agreed(marks.map((m) => m.form.grouping));
  if (topology === 'closed_loop') return 'completion';
  // Grounds always settle at the base: a base pool is physical context, not a sign.
  if (topology === 'pool') return marks.every((m) => m.surface === 'cup_base' || m.band === 'lower_base') ? null : 'weight';
  if (topology === 'patch') return grouping === 'clustered' ? 'many_details' : null;
  if (course === 'branching') return 'options';
  if (course === 'bending') return 'turn';
  if (vertical === 'rising') return 'rising';
  if (vertical === 'descending') return 'settling';
  if (topology === 'line') return course === 'straight' && continuity === 'continuous' ? 'steady_path' : 'path';
  if (grouping === 'clustered') return 'many_details';
  return null;
}

function qualitiesOf(marks: CoffeeV3MapMark[], theme: CoffeeV3NTheme): { qualities: string[]; avoid: string[] } {
  const qualities: string[] = [];
  const avoid: string[] = [];
  // A clear area is the absence of grounds: it has no tempo. Its outline's
  // "continuity" must never become "kesintisiz akan" (which also forbade
  // "ara ara" in a paragraph whose other meaning is intermittent).
  const continuity = theme === 'opening' ? 'unknown' : agreed(marks.map((m) => m.form.continuity));
  if (continuity === 'broken' && theme !== 'steady_path') {
    qualities.push('kesik kesik, ara ara ilerleyen');
    avoid.push('kesintisiz', 'hiç durmadan', 'tek solukta ilerliyor');
  }
  if (continuity === 'continuous' && theme !== 'steady_path') {
    qualities.push('kesintisiz akan');
    avoid.push('kesik kesik', 'ara ara');
  }
  if (knownBands(marks).length >= 2) qualities.push('zamana yayılan, uzun soluklu');
  if (agreed(marks.map((m) => m.form.openness)) === 'open' && theme !== 'opening') qualities.push('ucu açık');
  return { qualities, avoid };
}

function cupDraft(marks: CoffeeV3MapMark[], softMarks: ReadonlySet<string>): Draft | null {
  const sign = coffeeM1MarkSign({ candidates: marks.flatMap((m) => m.candidates) });
  const objectSign = sign && sign !== 'ambiguous' ? sign : null;
  const theme: CoffeeV3NTheme | null = objectSign ? 'object' : structuralTheme(marks);
  if (!theme) return null;
  const bands = knownBands(marks);
  const surfaceBase = marks.every((m) => m.surface === 'cup_base');
  const span = bands.length >= 2 ? `${bands[0]}>${bands[bands.length - 1]}` : null;
  const place = surfaceBase
    ? 'fincanın dibinde'
    : span ? SPAN_PLACE[span] : bands.length === 1 ? BAND_PLACE[bands[0]] : 'fincanın içinde';
  const handle = agreed(marks.map((m) => m.handleRelation ?? 'unknown'));
  const placement: CoffeeV3NPlacement | null = handle === 'handle_near' ? 'close_circle' : handle === 'handle_opposite' ? 'outer_world' : null;
  const handlePlace = placement === 'close_circle' ? ', kulbun yakınında' : placement === 'outer_world' ? ', kulbun karşı tarafında' : '';
  const text = objectSign ? SIGN_TEXT[objectSign] : THEME_TEXT[theme as Exclude<CoffeeV3NTheme, 'object'>];
  const shape = objectSign ? `${SIGN_TEXT[objectSign].symbol} gibi duran bir şekil` : SHAPE[theme as keyof typeof SHAPE];
  const directional = span && !surfaceBase ? (theme === 'rising' ? SPAN_RISING[span] : theme === 'settling' ? SPAN_SETTLING[span] : null) : null;
  const seen = directional ? `${directional}${handlePlace}` : `${place}${handlePlace} ${shape}`;
  const { qualities, avoid } = qualitiesOf(marks, theme);
  const slots = [...new Set(marks.flatMap((m) => m.coverage.slots))].sort();
  const bothViews = slots.filter((s) => s !== 'saucer').length >= 2;
  // An unresolved identity question (e.g. an excluded cross-kind pair) keeps the claim soft.
  const certain = marks.every((m) => m.identity === 'certain' && !softMarks.has(m.id));
  return {
    theme,
    surface: 'cup',
    seen: seen.replace(/\s+/g, ' ').trim(),
    meaning: text.meaning,
    elaborations: [...text.elaborations],
    qualities,
    lifeScenes: [...(objectSign ? SIGN_SCENES[objectSign] : THEME_SCENES[theme as Exclude<CoffeeV3NTheme, 'object'>])],
    licensedEvents: [...((objectSign ? SIGN_LICENSES[objectSign] : THEME_LICENSES[theme as Exclude<CoffeeV3NTheme, 'object'>]) ?? [])],
    horizon: surfaceBase ? 'longer' : bands.length ? HORIZON_BY_BAND[bands[0]] : null,
    placement,
    symbol: objectSign ? SIGN_TEXT[objectSign].symbol : null,
    anchors: objectSign ? [...SIGN_ANCHORS[objectSign]] : [...THEME_ANCHORS[theme as Exclude<CoffeeV3NTheme, 'object'>]],
    certainty: certain && (bothViews || objectSign !== null || marks.length === 1) ? 'clear' : 'soft',
    weight: 'minor',
    tone: text.tone,
    avoid: [...text.avoid, ...avoid],
    salience: text.salience + (bothViews ? 1 : 0) + (bands.length >= 2 ? 1 : 0),
    provenance: {
      surface: 'cup',
      identityGroups: [...new Set(marks.map((m) => m.identityGroup))].sort(),
      marks: marks.map((m) => m.id).sort(),
      slots,
      seenInBothCupViews: bothViews,
    },
  };
}

function saucerDrafts(map: CoffeeV3MarkMap): Draft[] {
  const out: Draft[] = [];
  const flow = map.saucer.flow;
  const flowTheme = flow.present
    ? flow.direction === 'toward_center' ? 'wish_gathering' : flow.direction === 'toward_edge' ? 'release' : flow.direction === 'around' ? 'circulating' : null
    : null;
  if (flowTheme) {
    const t = THEME_TEXT[flowTheme];
    const seen = flowTheme === 'wish_gathering'
      ? 'tabakta telvenin ortaya doğru toplanan akışı'
      : flowTheme === 'release' ? 'tabakta kenara doğru akan telve' : 'tabakta dönerek akan telve';
    out.push({
      theme: flowTheme, surface: 'saucer', seen, meaning: t.meaning, elaborations: [...t.elaborations], qualities: [],
      lifeScenes: [...THEME_SCENES[flowTheme]], licensedEvents: [...(THEME_LICENSES[flowTheme] ?? [])],
      horizon: null, placement: null, symbol: null, anchors: [...THEME_ANCHORS[flowTheme]], certainty: 'soft', weight: 'minor', tone: t.tone, avoid: [...t.avoid], salience: t.salience,
      provenance: { surface: 'saucer', identityGroups: [], marks: [], slots: ['saucer'], seenInBothCupViews: false },
    });
  }
  // Saucer marks contribute only through the same grounded tables (an object
  // sign, or a meaningful form); pools / blobs on a saucer stay context.
  const groups = new Map<string, CoffeeV3MapMark[]>();
  for (const m of map.saucerMarks) groups.set(m.identityGroup, [...(groups.get(m.identityGroup) ?? []), m]);
  for (const marks of groups.values()) {
    const sign = coffeeM1MarkSign({ candidates: marks.flatMap((m) => m.candidates) });
    const objectSign = sign && sign !== 'ambiguous' ? sign : null;
    const theme = objectSign ? 'object' : structuralTheme(marks);
    if (!theme || theme === 'weight' || theme === 'many_details') continue;
    const zone = agreed(marks.map((m) => m.saucerZone ?? 'unknown'));
    const place = zone === 'unknown' ? 'tabakta' : SAUCER_PLACE[zone];
    const text = objectSign ? SIGN_TEXT[objectSign] : THEME_TEXT[theme as Exclude<CoffeeV3NTheme, 'object'>];
    const shape = objectSign ? `${SIGN_TEXT[objectSign].symbol} gibi duran bir şekil` : SHAPE[theme as keyof typeof SHAPE];
    out.push({
      theme: theme as CoffeeV3NTheme, surface: 'saucer', seen: `${place} ${shape}`, meaning: text.meaning, elaborations: [...text.elaborations],
      lifeScenes: [...(objectSign ? SIGN_SCENES[objectSign] : THEME_SCENES[theme as Exclude<CoffeeV3NTheme, 'object'>])],
      licensedEvents: [...((objectSign ? SIGN_LICENSES[objectSign] : THEME_LICENSES[theme as Exclude<CoffeeV3NTheme, 'object'>]) ?? [])],
      qualities: [], horizon: null, placement: null, symbol: objectSign ? SIGN_TEXT[objectSign].symbol : null,
      anchors: objectSign ? [...SIGN_ANCHORS[objectSign]] : [...THEME_ANCHORS[theme as Exclude<CoffeeV3NTheme, 'object'>]],
      certainty: objectSign ? 'clear' : 'soft', weight: 'minor', tone: text.tone, avoid: [...text.avoid], salience: text.salience,
      provenance: {
        surface: 'saucer', identityGroups: [...new Set(marks.map((m) => m.identityGroup))].sort(), marks: marks.map((m) => m.id).sort(),
        slots: ['saucer'], seenInBothCupViews: false,
      },
    });
  }
  return out;
}

/**
 * One meaning is one claim: the same theme / symbol seen again (another mark,
 * the other cup view, or the saucer) strengthens that claim, never repeats it.
 * Drafts arrive cup first, so a merged claim keeps the cup's own place.
 */
function mergeDrafts(drafts: Draft[]): Draft[] {
  const byKey = new Map<string, Draft>();
  for (const d of drafts) {
    const key = [d.theme, d.symbol ?? ''].join('|');
    const prev = byKey.get(key);
    if (!prev) {
      byKey.set(key, { ...d, qualities: [...d.qualities], avoid: [...d.avoid], anchors: [...d.anchors] });
      continue;
    }
    prev.qualities = [...new Set([...prev.qualities, ...d.qualities, 'güçlü biçimde vurgulanan'])];
    prev.avoid = [...new Set([...prev.avoid, ...d.avoid])];
    prev.anchors = [...new Set([...prev.anchors, ...d.anchors])];
    prev.salience = Math.max(prev.salience, d.salience) + 1;
    prev.provenance = {
      ...prev.provenance,
      identityGroups: [...new Set([...prev.provenance.identityGroups, ...d.provenance.identityGroups])].sort(),
      marks: [...new Set([...prev.provenance.marks, ...d.provenance.marks])].sort(),
      slots: [...new Set([...prev.provenance.slots, ...d.provenance.slots])].sort(),
      seenInBothCupViews: prev.provenance.seenInBothCupViews || d.provenance.seenInBothCupViews,
    };
  }
  return [...byKey.values()];
}

const HORIZON_RANK: Record<CoffeeV3NHorizon, number> = { near: 0, coming: 1, longer: 2 };

const MAX_QUALITIES = 2;
/** Tempo (continuity) carries the contradiction guard, so it is always kept first. */
const QUALITY_PRIORITY = ['kesik kesik, ara ara ilerleyen', 'kesintisiz akan', 'güçlü biçimde vurgulanan', 'zamana yayılan, uzun soluklu', 'ucu açık'];
const qualityRank = (q: string) => {
  const i = QUALITY_PRIORITY.indexOf(q);
  return i === -1 ? QUALITY_PRIORITY.length : i;
};

function focusOf(intention: CoffeeTrustedIntentionContext | null): CoffeeV3NFocus {
  if (!intention) return { kind: 'none', userDeclaredIntention: null, area: null, forbiddenAssumptions: [] };
  return {
    kind: intention.subjectKind,
    userDeclaredIntention: intention.intention,
    area: AREA[intention.subjectKind] ?? null,
    forbiddenAssumptions: [...intention.intentionForbiddenAssumptions],
  };
}

export function planCoffeeV3Narrative(
  map: CoffeeV3MarkMap,
  intention: CoffeeTrustedIntentionContext | null,
  options: { softMarks?: ReadonlySet<string> } = {},
): CoffeeV3NPlan {
  const softMarks = options.softMarks ?? new Set<string>();
  const focus = focusOf(intention);
  const groups = new Map<string, CoffeeV3MapMark[]>();
  for (const m of map.cupMarks) groups.set(m.identityGroup, [...(groups.get(m.identityGroup) ?? []), m]);
  const cup = [...groups.values()].map((marks) => cupDraft(marks, softMarks)).filter((d): d is Draft => d !== null);
  const drafts = mergeDrafts([...cup, ...saucerDrafts(map)]);

  const empty = (reason: CoffeeV3NPlan['reason']): CoffeeV3NPlan => ({
    status: 'insufficient', reason, focus, claims: [], links: [], paragraphs: [], budget: { minWords: 0, maxWords: 0 },
  });
  if (drafts.length === 0) return empty('no_grounded_claims');
  // Two DISTINCT recognized signs, each clearly identified, carry a reading
  // of their own (key + path, ring + heart); a lone sign, a soft / ambiguous
  // identity or structural traces alone still fall below the floor.
  const twoClearSigns =
    drafts.length === 2 && drafts.every((d) => d.theme === 'object' && d.certainty === 'clear') && drafts[0].symbol !== drafts[1].symbol;
  if (drafts.length < COFFEE_V3N_MIN_CLAIMS && !twoClearSigns) return empty('below_min_claims');

  // Order: the most salient cup claims open the reading; the rest follow the
  // cup's own time axis (rim → middle → base); the saucer closes.
  const cupDrafts = drafts.filter((d) => d.surface === 'cup').sort((a, b) => b.salience - a.salience);
  const opening = cupDrafts.slice(0, Math.min(2, cupDrafts.length));
  const rest = cupDrafts.slice(opening.length).sort(
    (a, b) => (a.horizon ? HORIZON_RANK[a.horizon] : 1) - (b.horizon ? HORIZON_RANK[b.horizon] : 1) || b.salience - a.salience,
  );
  const saucer = drafts.filter((d) => d.surface === 'saucer');
  const ordered = [...opening, ...rest, ...saucer];
  // At most two qualities per claim (tempo first): the real writer copied a
  // three-quality list verbatim ("ara ara … ucu açık ve uzun soluklu").
  const claims: CoffeeV3NClaim[] = ordered.map((d, i) => ({
    id: `c${i + 1}`,
    ...d,
    qualities: [...d.qualities].sort((x, y) => qualityRank(x) - qualityRank(y)).slice(0, MAX_QUALITIES),
  }));

  // Links: accepted, purely visual relations between two claimed groups.
  const claimOfGroup = new Map<string, string>();
  for (const c of claims) for (const g of c.provenance.identityGroups) claimOfGroup.set(g, c.id);
  const groupOfMark = new Map([...map.cupMarks, ...map.saucerMarks].map((m) => [m.id, m.identityGroup]));
  const links: CoffeeV3NLink[] = [];
  const seenLinks = new Set<string>();
  for (const r of map.relations) {
    const kind = r.kind === 'connected' || r.kind === 'continuation_of' ? 'linked' : r.kind === 'crossing' ? 'crossing' : r.kind === 'contained_by' ? 'within' : null;
    if (!kind) continue;
    const [a, b] = [claimOfGroup.get(groupOfMark.get(r.a) ?? ''), claimOfGroup.get(groupOfMark.get(r.b) ?? '')];
    if (!a || !b || a === b) continue;
    const key = [a, b].sort().join('|');
    if (seenLinks.has(key)) continue;
    seenLinks.add(key);
    links.push({ a, b, kind });
  }
  // Hub links: claims whose marks are CONNECTED to the same unclaimed mark
  // are linked through it. In every real cup the branching lines and the
  // descending trails ran into the base pool — a pool is context, never a
  // claim, so without this the plan carried no link at all and the reading
  // became a list. Claims are chained in plan order (no pairwise explosion).
  const order = new Map(claims.map((c, i) => [c.id, i]));
  const hubs = new Map<string, Set<string>>();
  for (const r of map.relations) {
    if (r.kind !== 'connected' && r.kind !== 'continuation_of') continue;
    for (const [hub, other] of [[r.a, r.b], [r.b, r.a]]) {
      const hubGroup = groupOfMark.get(hub);
      const claim = claimOfGroup.get(groupOfMark.get(other) ?? '');
      if (!hubGroup || claimOfGroup.has(hubGroup) || !claim) continue;
      hubs.set(hubGroup, (hubs.get(hubGroup) ?? new Set<string>()).add(claim));
    }
  }
  for (const ids of hubs.values()) {
    const chain = [...ids].sort((x, y) => order.get(x)! - order.get(y)!);
    for (let i = 1; i < chain.length; i += 1) {
      const key = [chain[i - 1], chain[i]].sort().join('|');
      if (seenLinks.has(key)) continue;
      seenLinks.add(key);
      links.push({ a: chain[i - 1], b: chain[i], kind: 'linked' });
    }
  }

  const told = tellLinkedTogether(claims, links, opening.length, rest.length);
  const weighted = weighClaims(told.claims, told.links);
  // Length follows the STORY: only core and support meanings must be told.
  // A short, dense reading is the target; maxWords refuses a padded list.
  const required = weighted.filter((c) => c.weight !== 'minor').length;
  return {
    status: 'planned',
    reason: null,
    focus,
    claims: weighted,
    links: told.links,
    paragraphs: told.paragraphs,
    budget: { minWords: 8 * required + 16, maxWords: 25 * required + 60 },
  };
}

/**
 * Story weights. The real six-meaning plan was told as six equal
 * explanations in plan order (174 words, technically clean, a report). The
 * centre is the strongest, best-supported claim (a recognized sign, a clear
 * identity, salience, its links) together with what is visually linked to it
 * (at most three claims: one development). Recognized signs and other linked
 * claims support it; unlinked structural traces are optional colour. No link
 * is invented: weights only order what was observed.
 */
function weighClaims(claims: CoffeeV3NClaim[], links: CoffeeV3NLink[]): CoffeeV3NClaim[] {
  const degree = (id: string) => links.filter((l) => l.a === id || l.b === id).length;
  const partners = (id: string) => links.flatMap((l) => (l.a === id ? [l.b] : l.b === id ? [l.a] : []));
  const score = (c: CoffeeV3NClaim) =>
    c.salience + (c.certainty === 'clear' ? 2 : 0) + (c.theme === 'object' ? 2 : 0) + degree(c.id);
  const ranked = [...claims].sort((a, b) => score(b) - score(a));
  const centre = ranked[0];
  const core = new Set([centre.id]);
  for (const p of partners(centre.id).map((id) => claims.find((c) => c.id === id)!).sort((a, b) => score(b) - score(a))) {
    if (core.size < 3) core.add(p.id);
  }
  const support = new Set(claims.filter((c) => !core.has(c.id) && (c.theme === 'object' || degree(c.id) > 0)).map((c) => c.id));
  // Without links a cup still has more than one strong meaning: the story
  // keeps at least half of them (min. two), the strongest first.
  const target = Math.min(claims.length, Math.max(2, Math.ceil(claims.length / 2)));
  for (const c of ranked) {
    if (core.size + support.size >= target) break;
    if (!core.has(c.id)) support.add(c.id);
  }
  return claims.map((c) => ({ ...c, weight: core.has(c.id) ? 'core' : support.has(c.id) ? 'support' : 'minor' }));
}

/**
 * Paragraphs keep VISUALLY linked meanings together. Salience alone used to
 * open a reading with two unrelated signs (bird + fish) while the path the
 * bird is connected to went to the next paragraph, so the writer listed
 * "haber var, fırsat var" and the one real connection was split. Only an
 * existing link moves a claim (no link is ever invented): an unlinked
 * opening claim gives its place to the opening claim's linked partner, and
 * a development pair is completed with a linked partner. Ids and links are
 * renumbered in the new order; a plan without such a split is unchanged.
 */
function tellLinkedTogether(
  claims: CoffeeV3NClaim[],
  links: CoffeeV3NLink[],
  openingCount: number,
  restCount: number,
): { claims: CoffeeV3NClaim[]; links: CoffeeV3NLink[]; paragraphs: CoffeeV3NParagraph[] } {
  const linked = (x: string, y: string) => links.some((l) => (l.a === x && l.b === y) || (l.a === y && l.b === x));
  const hasLink = (x: string) => links.some((l) => l.a === x || l.b === x);
  const byId = new Map(claims.map((c) => [c.id, c]));
  const opening = claims.slice(0, openingCount).map((c) => c.id);
  let rest = claims.slice(openingCount, openingCount + restCount).map((c) => c.id);
  const saucer = claims.slice(openingCount + restCount).map((c) => c.id);
  const timeOrder = (ids: string[]) =>
    [...ids].sort((x, y) => {
      const [a, b] = [byId.get(x)!, byId.get(y)!];
      return (a.horizon ? HORIZON_RANK[a.horizon] : 1) - (b.horizon ? HORIZON_RANK[b.horizon] : 1) || b.salience - a.salience;
    });

  if (opening.length === 2 && !linked(opening[0], opening[1])) {
    for (const [keep, give] of [[0, 1], [1, 0]] as const) {
      const partner = rest.find((r) => linked(opening[keep], r));
      if (!partner || hasLink(opening[give])) continue;
      rest = timeOrder([...rest.filter((r) => r !== partner), opening[give]]);
      opening.splice(0, 2, opening[keep], partner); // the more salient sign leads, its partner follows
      break;
    }
  }
  for (let i = 0; i + 1 < rest.length; i += 2) {
    if (linked(rest[i], rest[i + 1])) continue;
    const j = rest.findIndex((r, k) => k > i + 1 && linked(rest[i], r));
    if (j !== -1) rest = [...rest.slice(0, i + 1), rest[j], ...rest.slice(i + 1).filter((r) => r !== rest[j])];
  }

  const order = [...opening, ...rest, ...saucer];
  const rename = new Map(order.map((id, i) => [id, `c${i + 1}`]));
  const id = (x: string) => rename.get(x)!;
  const paragraphs: CoffeeV3NParagraph[] = [];
  if (opening.length) paragraphs.push({ role: 'opening', claims: opening.map(id) });
  for (let i = 0; i < rest.length; i += 2) paragraphs.push({ role: 'development', claims: rest.slice(i, i + 2).map(id) });
  if (saucer.length) paragraphs.push({ role: 'saucer', claims: saucer.map(id) });
  return {
    claims: order.map((x) => ({ ...byId.get(x)!, id: id(x) })),
    links: links.map((l) => ({ ...l, a: id(l.a), b: id(l.b) })),
    paragraphs,
  };
}

/** Exported for diagnostics / tests only. */
export const COFFEE_V3N_TABLES = { THEME_TEXT, SIGN_TEXT, THEME_ANCHORS, SIGN_ANCHORS, THEME_SCENES, SIGN_SCENES } as const;
