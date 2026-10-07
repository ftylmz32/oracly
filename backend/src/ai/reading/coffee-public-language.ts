import type { CoffeeNarrative } from './types.js';
import type { CoffeeStoryPlanV2 } from './coffee-story-plan.js';
import {
  DEVELOPMENT_CLASS_BY_BEAT,
  type CoffeeDevelopmentClass,
  type CoffeeForbiddenSpecific,
} from './coffee-fortune-beat.js';
import type { CoffeeUserDeclaredFact } from './coffee-intention-context.js';

/**
 * C2.11A — Coffee PUBLIC-LANGUAGE boundaries. The user receives only the life
 * interpretation: never a cup/image report (raw or "sanitized" geometry),
 * never internal machinery, and never an external specific the active
 * fortune plan forbids. Behavioural constructions, never bare vocabulary:
 * "yol", "çizgi", "iz", "açıklık", "karanlık" stay legal as life metaphors.
 */

const fold = (value: string) => value.normalize('NFC').toLocaleLowerCase('tr-TR');
const S = '(?<![\\p{L}\\p{N}])';
const E = '(?![\\p{L}\\p{N}])';
const re = (source: string) => new RegExp(source, 'u');
const sentencesOf = (texts: string[]) =>
  texts.map(fold).flatMap((text) => text.split(/[.!?;]+/u)).map((sentence) => sentence.trim()).filter(Boolean);
const publicTexts = (narrative: CoffeeNarrative) => [
  narrative.visualObservation.text, narrative.overall.text, narrative.love.text, narrative.career.text,
  narrative.money.text, narrative.nearFuture.text, narrative.takeaway.text,
];

// ---------------------------------------------------------------------------
// Visual-report voice (raw cup description + sanitized geometry)
// ---------------------------------------------------------------------------

/** The cup, the grounds, or the image itself — never public in Coffee. */
const RAW_CUP = re(`${S}(fincan|telve|tortu|kahve (kalıntı|telvesi)|fincanın (dibi|ağzı|kulbu|kenarı)|kulp (tarafı|yanı))\\p{L}*`);
/** Image-only marks: never a life metaphor in Coffee prose. */
const IMAGE_MARK = '(şekil|şekl|figür|sembol|leke|desen|kümelenme|birikinti|silüet|noktacık)';
/** Marks that ARE ordinary life metaphors ("kendi çizgin", "geçmişin izi"); they fail only with geometry. */
const LINE_MARK = '(çizgi|hat|iz|izi|izler|izleri|kıvrım)';
/** Visual zones described as image regions. */
const ZONE = '((yoğun|koyu|açık|aydınlık|seyrek|boş) (bir )?(alan|bölge|kısım|leke|kütle)\\p{L}*|boşluk\\p{L}*|açıklığın)';
/** Spatial predicates (position on an image). */
const SPATIAL = '(uzanan|uzanıyor|uzanır|geçen|geçiyor|kıvrılan|kıvrılıyor|yukarı doğru|aşağı doğru|yana doğru|ikiye ayrılan|bağlayan|birleştiren|içinden|üzerinden|yanında|kenarında|ortasında|altında|üstünde|çıkmış|belirmiş|beliren|görünüyor)';
/** Geometric motion / connection only (what a drawn line does). */
const LINE_GEOMETRY = '(uzanan|uzanıyor|kıvrılan|kıvrılıyor|yukarı doğru|aşağı doğru|yana doğru|ikiye ayrılan|bağlayan|birleştiren|içinden geçen|üzerinden geçen)';
const ZONE_GEOMETRY = '(uzanan|uzanıyor|geçen|geçiyor|kıvrılan|içinden|üzerinden|yanında|kenarında|ortasında|açılan)';
const IMAGE_POSITION = re(`${S}(üst|alt|orta|yan) (kısım|kısmı|bölüm|bölümü|duvar|duvarı|kenar)\\p{L}*`);
const VISUAL_RULES = [
  RAW_CUP,
  IMAGE_POSITION,
  re(`${S}${IMAGE_MARK}\\p{L}*[^.!?]{0,50}${S}${SPATIAL}`),
  re(`${S}${SPATIAL}[^.!?]{0,30}${S}${IMAGE_MARK}\\p{L}*`),
  re(`${S}${LINE_MARK}\\p{L}*[^.!?]{0,50}${S}${LINE_GEOMETRY}`),
  re(`${S}${LINE_GEOMETRY}[^.!?]{0,30}${S}(bir |ince bir |yeni bir )?(ilerleyen |uzanan )?${LINE_MARK}${E}`),
  re(`${S}(yukarı|aşağı|yana) doğru (ilerleyen|uzanan|giden|çıkan) (bir |ince bir )?${LINE_MARK}${E}`),
  re(`${S}${ZONE}[^.!?]{0,50}${S}${ZONE_GEOMETRY}`),
  re(`${S}iki (taraf|kenar|ucu|ucunu|yanı)\\p{L}*[^.!?]{0,20}(bağlayan|birleştiren)`),
  // a demonstrative pointing at an image figure ("bu figür …", "şu şekil …")
  re(`${S}(bu|şu|o) (figür|sembol|şekil|şekl)\\p{L}*`),
  // symbol-dictionary voice: "bu sembol/işaret … anlamına gelir / işaret eder"
  re(`${S}(sembol|figür|işaret|şekil)\\p{L}*[^.!?]{0,60}(anlamına gel|işaret ed|simgeler|temsil ed|gösterir|yorumlanır)`),
];

/** The first public sentence that reports the cup/image, or null. */
export function coffeeVisualReportVoice(narrative: CoffeeNarrative): string | null {
  return sentencesOf(publicTexts(narrative)).find((sentence) => VISUAL_RULES.some((rule) => rule.test(sentence))) ?? null;
}

// ---------------------------------------------------------------------------
// Internal machinery jargon
// ---------------------------------------------------------------------------

const INTERNAL_JARGON = re(
  `${S}(cue|beat|beats|proposition|propositions|semantic|evidence|ontology|modality|synthesis|storyplan|subject kind|fortune beat|forbidden|önerme\\p{L}*|semantik|ontoloji\\p{L}*|kanıt kimliğ\\p{L}*|anlam kategorisi\\p{L}*|sentez modu)${E}`,
);

export function coffeeInternalJargon(narrative: CoffeeNarrative): string | null {
  return sentencesOf(publicTexts(narrative)).find((sentence) => INTERNAL_JARGON.test(sentence)) ?? null;
}

// ---------------------------------------------------------------------------
// Forbidden fortune specifics (plan-driven)
// ---------------------------------------------------------------------------

/** People/roles who could be invented as a sender. */
const ROLE = '(eski sevgili|sevgili|arkadaş|dost|eş|aile|anne|baba|kardeş|akraba|komşu|patron|işveren|yönetici|müdür|şef|meslektaş|iş arkadaş|tanıdı|bir erkek|bir kadın|bir hanım|bir bey|bir yakın|yakınların)';
const ABLATIVE = '(ın|in|un|ün|n|ım|im|um|üm|ları|leri|ğın|ğin)?(dan|den|tan|ten)';
const CONTACT = '(haber|mesaj|ileti|arama|telefon|çağrı|dönüş|cevap|yanıt|davet|selam|not|söz|ses)';
const SENDER_RULES = [
  // "eski sevgilinden bir mesaj", "ailenden biri arayacak", "patronundan haber"
  re(`${S}${ROLE}${ABLATIVE}${E}[^.!?]{0,60}${S}(${CONTACT}\\p{L}*|biri${E}[^.!?]{0,15}${S}(ara|yaz|ulaş|haber ver|mesaj at)\\p{L}*)`),
  re(`${S}${CONTACT}\\p{L}*[^.!?]{0,30}${S}${ROLE}${ABLATIVE}${E}`),
  // "patronun / eski sevgilin sana yazacak"
  re(`${S}${ROLE}(ın|in|un|ün|n)${E}[^.!?]{0,40}${S}(arayacak|yazacak|ulaşacak|gönderecek|haber verecek|mesaj atacak|dönecek|dönüş yapacak|iletecek|arayabilir|yazabilir|ulaşabilir|haber verebilir)${E}`),
];

/** Concrete employment actors/entities acting or originating a development. */
const EMPLOYER = '(işveren|patron|şirket|firma|yönetici|müdür|şef|insan kaynakları|ik departmanı|kurum|holding)';
// C2.11A.1: + contact verbs, so an employer as the SOURCE of news is caught under any beat.
const EMPLOYER_ACTION = '(teklif|davet|terfi|zam|karar|çağır|ara|yaz|dön|onay|kabul|işe al|seç|ulaş|gönder|takdir|ödül|prim|görev ver|sorumluluk ver|mülakat|görüşme|haber ver|haber gönder|mesaj|bildir)';
const EMPLOYER_RULES = [
  // "işverenin / patronun / şirketin / firman / yöneticin … teklif …"
  re(`${S}${EMPLOYER}(ın|in|un|ün|n|ı|i|u|ü)?(n)${E}[^.!?]{0,60}${S}${EMPLOYER_ACTION}\\p{L}*`),
  // "şirketten / işverenden / ik departmanından … teklif/dönüş gelecek"
  re(`${S}${EMPLOYER}(ın|in|un|ün|n)?(dan|den|tan|ten)${E}[^.!?]{0,60}${S}(${EMPLOYER_ACTION}|haber|mesaj|dönüş|cevap|yanıt)\\p{L}*`),
  re(`${S}(yeni|başka|büyük|bir) (bir )?(şirket|firma|işveren|holding)\\p{L}*[^.!?]{0,40}${S}${EMPLOYER_ACTION}\\p{L}*`),
];

const ARRIVES = '(gelecek|gelebilir|geliyor|gelir|yatacak|yatabilir|yatırılacak|yatırılabilir|girecek|girebilir|geçecek|geçebilir|alacaksın|alabilirsin|ulaşacak|ulaşabilir|ödenecek|ödenebilir|eline geçecek)';
const PAYMENT_RULES = [
  re(`${S}(ödeme|havale|transfer|eft|prim|ikramiye|bonus|tahsilat|nakit|harçlık)\\p{L}*[^.!?]{0,40}${S}${ARRIVES}${E}`),
  re(`${S}hesabına${E}[^.!?]{0,20}${S}(para|ödeme|\\p{L}+)\\p{L}*[^.!?]{0,10}${S}${ARRIVES}${E}`),
  re(`${S}(para|paran|parası|bir miktar para)( \\p{L}+)? ${ARRIVES}${E}`),
  re(`${S}(biri|birisi|birileri) (sana )?(ödeme yapacak|para verecek|para gönderecek|borcunu ödeyecek)`),
];

const NUMBER_WORD = '(bir|iki|üç|dört|beş|altı|yedi|sekiz|dokuz|on|yirmi|otuz|kırk|elli|altmış|yetmiş|seksen|doksan|yüz|bin|milyon|milyar)';
const CURRENCY = '(tl|lira\\p{L}*|₺|try|dolar\\p{L}*|euro\\p{L}*|avro\\p{L}*|\\$|€)';
const AMOUNT_RULES = [
  re(`${S}\\d[\\d.,]*\\s*(bin|milyon|milyar)?\\s*${CURRENCY}(?![\\p{L}])`),
  re(`[₺$€]\\s*\\d`),
  re(`${S}(${NUMBER_WORD}\\s+){1,4}${CURRENCY}(?![\\p{L}])`),
];

/** Salary / raise / debt as money (never "borçlu hissetmek", never "zamanla"). */
const SALARY_DEBT = re(
  `${S}(maaş\\p{L}*|ücret (artış|zam)\\p{L}*|zam(mı|mın|ma|la|lar\\p{L}*)?|borc(un|unu|undan|ların|larını|larından|lar)|borç (yükü|kapan|öde|bit|azal|taksit)\\p{L}*|kredi (borcu|taksidi|kartı borcu)\\p{L}*|taksit\\p{L}*|icra\\p{L}*|faiz\\p{L}*|kredi çek\\p{L}*)${E}`,
);

/** Explicit calendar dates / day counts (proactive closure of the `date` specific). */
const DATE_RULES = [
  re(`${S}((pazartesi|salı|çarşamba|perşembe|cuma|cumartesi)(günü|ya|ye|ları|leri|dan|den|da|de|ndan|nden)?|pazar günü)${E}`),
  re(`${S}((şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|kasım)(ta|da|tan|dan|a|e|ın|in|ı|i)?|(ocak|ekim|aralık) ayı\\p{L}*)${E}`),
  re(`${S}(\\d+|${NUMBER_WORD})\\s+(gün|hafta|ay|yıl)\\s+(içinde|sonra|sonunda|kadar)${E}`),
];

/** Another person's inner state or intent stated as fact (proactive; possessed forms only). */
const OTHER_FEELINGS = re(
  `${S}(onun|o kişinin|karşındakinin|karşı tarafın|partnerinin|sevgilinin|eşinin|aklındaki kişinin) (duygu|his|niyet|düşünce|kalb|ilgi)\\p{L}*|${S}sana karşı (bir )?(his|duygu|ilgi)\\p{L}*`,
);

/** Turkish possessive/case endings a role noun may carry (never "eşinti", "ailevi"). */
const ROLE_SUFFIX = '(i|ı|u|ü|e|a|le|la|den|dan|de|da|in|ın|un|ün|inle|ınla|unla|ünle|ine|ına|une|üne|ini|ını|unu|ünü|inden|ından|undan|ünden)?';
/** C2.11A.1 exact_person: a specific person of the user's life asserted without trusted context. */
const PARTNER_ROLE = `${S}(sevgilin|eşin|partnerin|flörtün|nişanlın)${ROLE_SUFFIX}${E}`;
const OTHER_ROLE = `${S}(eski sevgilin|arkadaşın|patronun|yöneticin|müdürün|ailen|annen|baban|kardeşin|ablan|ağabeyin|abin)${ROLE_SUFFIX}${E}`;

/** C2.11A.1 relationship_history: an invented past of a relationship (never licensed). */
const RELATIONSHIP_HISTORY = re(
  `${S}(eski (sevgili|ilişki|aşk)\\p{L}*|ayrıldığınız|ayrılığınız|ayrılığın|barış(acaksınız|manız|ma ihtimali)|yeniden bir araya gel\\p{L}*|tekrar bir araya gel\\p{L}*|geçmişte yaşadığınız|eskiden yaşadığınız|geri dön(en|ecek) (eski|o) (ilişki|sevgili|aşk)\\p{L}*)`,
);

/** C2.11A.1 other_person_intent: what someone else wants / plans / has in mind. */
const OTHER_INTENT = re(
  `${S}(onun|karşı tarafın|sevgilinin|eşinin|partnerinin|birinin|birilerinin|o kişinin|aklındaki kişinin) (niyet|plan|aklı|aklında|isteğ|düşünce)\\p{L}*|${S}(o|biri|birisi|karşı taraf) (seni|sana|seninle) (istiyor|isteyecek|düşünüyor|düşünecek|planlıyor)\\p{L}*`,
);

/**
 * C2.11A.1 other_person_action: somebody noticing, praising, discussing,
 * choosing, supporting or recognizing the user — active voice with a social
 * actor, or a passive recognition of the user's effort/name/success.
 */
const SOCIAL_ACTOR = '(insanlar|çevren|çevrendekiler|etrafındakiler|başkaları|birileri|biri|birisi|herkes|arkadaşların|mesai arkadaşların|iş arkadaşların|meslektaşların|ekibin|takımın|yöneticin|ailen|dostların|sevdiklerin)';
const OTHER_ACTION = [
  re(`${S}${SOCIAL_ACTOR}\\p{L}*[^.!?]{0,50}${S}(fark ed|takdir ed|öv|beğen|seç|destek ol|destek ver|alkışla|bahsed|söz ed|ilgi göster|yardım ed|sahip çık|tebrik)\\p{L}*`),
  re(`${S}(emeğin|çaban|adın|başarın|yeteneğin|ismin|varlığın)\\p{L}*[^.!?]{0,30}(fark edil|takdir edil|konuşul|övül|beğenil|anıl|alkışlan|duyul|geç(tiği|iyor|ecek|eceği))\\p{L}*`),
];

const DETECTORS: Array<[CoffeeForbiddenSpecific, (sentence: string, declared: CoffeeUserDeclaredFact[]) => boolean]> = [
  ['exact_person', (sentence, declared) =>
    re(OTHER_ROLE).test(sentence)
    || (!declared.includes('current_relationship') && re(PARTNER_ROLE).test(sentence))],
  ['sender_identity', (sentence) => SENDER_RULES.some((rule) => rule.test(sentence))],
  ['employer_or_company', (sentence) => EMPLOYER_RULES.some((rule) => rule.test(sentence))],
  ['payment_event', (sentence) => PAYMENT_RULES.some((rule) => rule.test(sentence))],
  ['monetary_amount', (sentence) => AMOUNT_RULES.some((rule) => rule.test(sentence))],
  ['salary_or_debt', (sentence) => SALARY_DEBT.test(sentence)],
  ['date', (sentence) => DATE_RULES.some((rule) => rule.test(sentence))],
  ['relationship_history', (sentence) => RELATIONSHIP_HISTORY.test(sentence)],
  ['other_person_feelings', (sentence) => OTHER_FEELINGS.test(sentence)],
  ['other_person_intent', (sentence) => OTHER_INTENT.test(sentence)],
  ['other_person_action', (sentence) => OTHER_ACTION.some((rule) => rule.test(sentence))],
];

/** The forbidden specifics the ACTIVE fortune plan carries (lead + supporting). */
export function coffeeActiveForbiddenSpecifics(plan: CoffeeStoryPlanV2): Set<CoffeeForbiddenSpecific> {
  const beats = plan.fortune ? [plan.fortune.lead, ...plan.fortune.supporting] : [];
  return new Set(beats.flatMap((beat) => beat.forbiddenSpecifics));
}

/** Exact machine categories triggered by public prose under the active plan. */
export function coffeeForbiddenSpecificsTriggered(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): CoffeeForbiddenSpecific[] {
  const active = coffeeActiveForbiddenSpecifics(plan);
  if (active.size === 0) return [];
  const sentences = sentencesOf(publicTexts(narrative));
  const declared = plan.subject?.declaredFacts ?? [];
  return DETECTORS
    .filter(([specific]) => active.has(specific))
    .filter(([, detect]) => sentences.some((sentence) => detect(sentence, declared)))
    .map(([specific]) => specific);
}

export function coffeeForbiddenFortuneSpecificFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): 'unsupported_specific_detail' | null {
  return coffeeForbiddenSpecificsTriggered(narrative, plan).length > 0 ? 'unsupported_specific_detail' : null;
}

// ---------------------------------------------------------------------------
// C2.11A.1 — invented CURRENT user state (a subject is not a state)
// ---------------------------------------------------------------------------

/** Existing savings / investments / spending habits / shortage — never from a Money category. */
const FINANCIAL_STATE = re(
  `${S}(bir kenara (koyduğun|ayırdığın|attığın)|biriktirdiğin|birikim(in|lerin|ini|lerini|inden|lerinden)|mevcut birikim\\p{L}*|zaten ayırdığın|yatırım(ın|ların|ını|larını)|harcama alışkanlı\\p{L}*|harcarken|elindeki para\\p{L}*|cebindeki para\\p{L}*|maddi sıkıntın\\p{L}*|para sıkıntın\\p{L}*|darlığın|kıtlığın)${E}`,
);
/** Coworkers / team / project / application / promotion process — never from a Career category. */
const CAREER_STATE = re(
  `${S}(ekibin|takımın|mesai arkadaşların|iş arkadaşların|meslektaşların|projen|projelerin|başvurun|başvuruların|terfi sürec\\p{L}*|mevcut işin|şu anki işin|işyerindeki (sorun|gerginlik|çatışma)\\p{L}*)\\p{L}*`,
);
/** Someone already interested / an ongoing bond — never from a Love category. */
const LOVE_STATE = re(
  `${S}(hoşlandığın kişi\\p{L}*|ilgilendiğin kişi\\p{L}*|seninle ilgilenen|sana ilgi duyan|şu anki ilişki\\p{L}*|mevcut ilişki\\p{L}*|süren ilişki\\p{L}*)`,
);

export type CoffeeInventedStateKind = 'financial' | 'career' | 'love';

/** The current-state categories the prose presumes without a declared fact. */
export function coffeeInventedCurrentState(narrative: CoffeeNarrative, plan: CoffeeStoryPlanV2): CoffeeInventedStateKind[] {
  const sentences = sentencesOf(publicTexts(narrative));
  const declared = plan.subject?.declaredFacts ?? [];
  const found: CoffeeInventedStateKind[] = [];
  if (sentences.some((sentence) => FINANCIAL_STATE.test(sentence))) found.push('financial');
  if (sentences.some((sentence) => CAREER_STATE.test(sentence))) found.push('career');
  if (!declared.includes('current_relationship') && sentences.some((sentence) => LOVE_STATE.test(sentence))) {
    found.push('love');
  }
  return found;
}

// ---------------------------------------------------------------------------
// C2.11A.1 — fortune-development alignment (no cross-beat invention)
// ---------------------------------------------------------------------------

/**
 * Internal gate lexicon only — never sent to the writer. High-confidence
 * constructions that tell a development of each class; ordinary uses of the
 * same words in other meanings are not matched.
 */
const DEVELOPMENT_SIGNAL: Record<CoffeeDevelopmentClass, RegExp> = {
  communication: re(`${S}(haber\\p{L}*|mesaj\\p{L}*|iletişim\\p{L}*|konuşma\\p{L}*|haberleş\\p{L}*|mesajlaş\\p{L}*|yazış\\p{L}*|telefon\\p{L}*|sohbet\\p{L}*|cevap\\p{L}*|yanıt\\p{L}*|bir arama\\p{L}*|dönüş (al|gel|yap)\\p{L}*)`),
  opening: re(`${S}(fırsat\\p{L}*|imkân\\p{L}*|imkan\\p{L}*|olanak\\p{L}*|kısmet\\p{L}*|kapı(sı|ları|n)? (açıl|aralan)\\p{L}*|yeni bir kapı\\p{L}*|teklif\\p{L}*)`),
  commitment: re(`${S}(bağ (kur|kurul)\\p{L}*|bağlılı\\p{L}*|birliktelik\\p{L}*|evlilik\\p{L}*|nişan\\p{L}*|söz ver\\p{L}*|ilişki (başla|kurul)\\p{L}*|yeni bir (ilişki|bağ)\\p{L}*)`),
  feeling: re(`${S}(duygu|his|kalb|kalp|gönl|gönül)\\p{L}*[^.!?]{0,25}(derinleş|yoğunlaş|ısın|alevlen|uyan)\\p{L}*`),
  way_through: re(`${S}(çözüm\\p{L}*|çözül\\p{L}*|çıkış yolu\\p{L}*|düğüm\\p{L}*)`),
  direction: re(`${S}(yön(ün|ünü|üne)? (değiş|çevir)\\p{L}*|rota\\p{L}*|yolculuk\\p{L}*|seyahat\\p{L}*|taşın(?!\\s+altı)\\p{L}*|yer değiştir\\p{L}*|yeni bir yön\\p{L}*)`),
  // intransitive growing / accumulating only ("büyüyecek", never causative "büyütüp", never "büyük")
  // ("genişle" is excluded: it is routinely the MANNER of another development, e.g. a widening exchange)
  growth: re(`${S}(büyü(y|me)\\p{L}*|bereket\\p{L}*|çoğal(?!t)\\p{L}*|filizlen\\p{L}*|serpil\\p{L}*|katlan(arak|acak)\\p{L}*)`),
  alternatives: re(`${S}(seçenek\\p{L}*|tercih\\p{L}*|karar ver\\p{L}*|kararın\\p{L}*|yol ayrım\\p{L}*)`),
  // "çevren / yakın çevre" is plan CONTEXT (handle side), not a people development
  people: re(`${S}(insanlar\\p{L}*|kalabalık\\p{L}*|topluluk\\p{L}*|yeni (yüzler|insanlar|tanışıklık)\\p{L}*|tanışacak\\p{L}*|tanışma\\p{L}*|bir araya gel\\p{L}*|buluşma\\p{L}*|misafir\\p{L}*|davet\\p{L}*|arkadaş\\p{L}*|dost(lar|un|ların|luk)\\p{L}*)`),
};

/** Development classes licensed by the ACTIVE fortune beats (lead + supporting). */
export function coffeeActiveDevelopmentClasses(plan: CoffeeStoryPlanV2): Set<CoffeeDevelopmentClass> {
  const beats = plan.fortune ? [plan.fortune.lead, ...plan.fortune.supporting] : [];
  return new Set(beats.map((beat) => DEVELOPMENT_CLASS_BY_BEAT[beat.kind]));
}

/** Development classes the prose tells that no active beat licenses. */
export function coffeeUnsupportedDevelopments(narrative: CoffeeNarrative, plan: CoffeeStoryPlanV2): CoffeeDevelopmentClass[] {
  if (!plan.fortune) return [];
  const active = coffeeActiveDevelopmentClasses(plan);
  const text = sentencesOf(publicTexts(narrative)).join(' . ');
  return (Object.keys(DEVELOPMENT_SIGNAL) as CoffeeDevelopmentClass[])
    .filter((kind) => !active.has(kind) && DEVELOPMENT_SIGNAL[kind].test(text));
}

export function coffeeFortuneDevelopmentFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): 'unsupported_fortune_development' | null {
  return coffeeUnsupportedDevelopments(narrative, plan).length > 0 ? 'unsupported_fortune_development' : null;
}
