/**
 * Deterministic structural / safety checks for Coffee & Palm human output.
 * Strengthened in E3G for grounding, specificity, and anti-boilerplate.
 */

export type HumanQualityFailure =
  | 'empty'
  | 'too_short'
  | 'duplicate_sections'
  | 'generic'
  | 'ai_disclosure'
  | 'unsupported_certainty'
  | 'prohibited_claim'
  | 'wrong_locale_marker'
  | 'weak_observation'
  | 'closing_question_habit'
  | 'repeated_stock'
  | 'insufficient_anchors'
  | 'locale_leak'
  | 'embedded_disclaimer'
  | 'generic_closing'
  | 'inferred_handedness';

export type CoffeeQualityInput = {
  visualObservation: string;
  overall: string;
  love: string;
  career: string;
  money: string;
  nearFuture: string;
  takeaway: string;
  language?: 'tr' | 'en' | 'ru';
};

export type PalmQualityInput = {
  visualObservation: string;
  overall: string;
  lifeLine: string;
  headLine: string;
  heartLine: string;
  fateLine: string;
  takeaway: string;
  language?: 'tr' | 'en' | 'ru';
  /** When false/undefined, narrative must not assert left/right hand. */
  trustedHandSide?: boolean;
};

const AI_DISCLOSURE =
  /\b(as an ai|i'?m an ai|i am an ai|bir yapay zeka|yapay zeka olarak|как ии|я ии)\b/i;

const CERTAINTY =
  /\b(kesin olacak|definitely will|you will die|omrun|lifespan is|you will live exactly)\b/i;

const MEDICAL =
  /\b(hastalik teshis|diagnose cancer|medical diagnosis|yasam suresi|lifespan diagnosis|fertility diagnosis|hamile kalacaksin|you are pregnant|uzun (bir )?omur|omur (goster|iddia(?!si degil))|lifespan is)\b/i;

/** English technical cup terms that must not appear in Turkish narrative. */
const TR_LOCALE_LEAK =
  /\brim\b|\bupper wall\b|\blower wall\b|\bmid(?:dle)? wall\b|\bhandle side\b|\bbase edge\b|\bcup interior\b|\bright hand\b|\bleft hand\b/i;

const EN_LOCALE_LEAK_CYR =
  /[\u0400-\u04FF]{8,}/;

const EMBEDDED_DISCLAIMER =
  /eglence (ve|\/) (kisisel )?dus|yalnizca eglence|tibbi (veya|ya da).{0,24}(teshis|tani)|saglik (ya da|veya) omur|omur hakkinda yorumlanmaz|kesin (bir )?ongoru|bu yalnizca|for entertainment only|not (a )?medical|symbolic reading only|entertainment purposes/i;

const GENERIC_CLOSING =
  /enerjini .{0,48}yonelt|kisisel (bir )?dus(u|ü)?nme aynasi|dusunme aynasi|kapilar ac|beklenmedik kapilar|yeni (bir )?baslangic/i;

const INFERRED_HAND =
  /\b(sag|sol) (el|avuc|avu[cç])\b|\b(right|left) (hand|palm)\b|\bsingle right hand\b|\bsingle left hand\b/i;


const GENERIC_COFFEE =
  /^(this cup (shows|reveals) (energy|potential)\.?|fincan enerji tasiyor\.?|analysis complete\.?)$/i;

const GENERIC_PALM =
  /^(your palm (shows|reveals) (energy|potential)\.?|avuc enerji tasiyor\.?|analysis complete\.?)$/i;

/** Stock fortune fillers — match against foldTr(). */
const COFFEE_STOCK =
  /geleneksel olarak[\s\S]{0,48}anlamina gelebilir|firsatlar dogabilir|duygusal bir hareketlilik|iletisim on plana|analiz tamamlandi|yeni bir baslangic|beklenmedik kapilar|bir araya gelmeyi sembolize/i;

const PALM_STOCK =
  /guclu (bir )?enerji|dengeli (bir )?yaklasim|dikkat cekici bir yapi|belirgin ana cizgiler mevcut|genel olarak acik ve net|avuc enerji/i;

const PALM_WEAK_OBS =
  /^(acik avuc[^.!]{0,40}(mevcut|gorunuyor|net)\.?|open palm[^.!]{0,40}(visible|clear)\.?)$/i;

const COFFEE_REGION =
  /(agiz|ust\s*duvar|orta\s*duvar|ic\s*duvar|dip|taban|kulp|rim|wall|base|handle|край|стенк|дно)/i;

const COFFEE_DENSITY =
  /(yogun|acik alan|seyrek|kume|telve|birikinti|dense|open\s*space|гущ|скоплен)/i;

const COFFEE_SHAPE =
  /(andiran|benziyor|bicim|sekil|egim|yon|cizgi|kume kenar|trail|shape|форм)/i;

const PALM_ATTR =
  /(yay|kivrim|egri|duz|derin|sig|koyu|kontrast|kesik|kopuk|surekli|devam|aralik|yakin|uzak|baslar|biter|uc|bilek|origin|curv|depth|contin|spacing|endpoint|изгиб|глубин|разрыв)/i;

export function evaluateCoffeeQuality(
  input: CoffeeQualityInput,
): HumanQualityFailure | null {
  const observation = input.visualObservation.trim();
  const overall = input.overall.trim();
  const takeaway = input.takeaway.trim();
  if (!observation || !overall) return 'empty';
  if (AI_DISCLOSURE.test(joinSections(input))) return 'ai_disclosure';
  if (GENERIC_COFFEE.test(foldTr(overall)) || GENERIC_COFFEE.test(foldTr(observation))) {
    return 'generic';
  }
  const earlyBlob = joinSections(input);
  if (input.language === 'tr' && TR_LOCALE_LEAK.test(earlyBlob)) return 'locale_leak';
  if (input.language === 'en' && EN_LOCALE_LEAK_CYR.test(earlyBlob)) return 'locale_leak';
  if (EMBEDDED_DISCLAIMER.test(foldTr(earlyBlob))) return 'embedded_disclaimer';
  if (GENERIC_CLOSING.test(foldTr(takeaway)) || GENERIC_CLOSING.test(foldTr(overall))) {
    return 'generic_closing';
  }
  if (observation.length < 40 || overall.length < 80) return 'too_short';
  if (wordCount(overall + ' ' + observation) < 70) return 'too_short';
  if (sectionsDuplicate([overall, takeaway, observation])) {
    return 'duplicate_sections';
  }
  if (COFFEE_STOCK.test(foldTr(overall)) || COFFEE_STOCK.test(foldTr(takeaway))) {
    return 'repeated_stock';
  }
  if (COFFEE_STOCK.test(foldTr(joinSections(input)))) {
    return 'repeated_stock';
  }
  if (takeawayContainedInOverall(overall, takeaway)) return 'duplicate_sections';
  if (closingQuestionHabit(overall, takeaway)) return 'closing_question_habit';
  if (boilerplateClosingQuestion(overall, takeaway)) {
    return 'closing_question_habit';
  }
  if (
    wordCount(
      [overall, takeaway, input.love, input.career, input.money, input.nearFuture].join(
        ' ',
      ),
    ) < 100
  ) {
    return 'too_short';
  }
  if (coffeeAnchorScore(observation) < 3) return 'insufficient_anchors';
  if (repeatKeyIdea(joinSections(input), ['bulusma', 'baslangic', 'bir araya'])) {
    return 'repeated_stock';
  }
  if (repeatKeyIdea(overall + ' ' + takeaway, ['bulusma', 'sicak'])) {
    return 'repeated_stock';
  }
  const blob = joinSections(input);
  if (CERTAINTY.test(foldTr(blob))) return 'unsupported_certainty';
  if (MEDICAL.test(foldTr(blob))) return 'prohibited_claim';
  return localeMarkerFailure(blob, input.language);
}

export function evaluatePalmQuality(
  input: PalmQualityInput,
): HumanQualityFailure | null {
  const observation = input.visualObservation.trim();
  const overall = input.overall.trim();
  const takeaway = input.takeaway.trim();
  if (!observation || !overall) return 'empty';
  if (AI_DISCLOSURE.test(joinPalm(input))) return 'ai_disclosure';
  if (GENERIC_PALM.test(foldTr(overall)) || GENERIC_PALM.test(foldTr(observation))) {
    return 'generic';
  }
  const earlyPalm = joinPalm(input);
  if (input.language === 'tr' && TR_LOCALE_LEAK.test(earlyPalm)) return 'locale_leak';
  if (input.language === 'en' && EN_LOCALE_LEAK_CYR.test(earlyPalm)) return 'locale_leak';
  if (EMBEDDED_DISCLAIMER.test(foldTr(earlyPalm))) return 'embedded_disclaimer';
  if (GENERIC_CLOSING.test(foldTr(takeaway)) || GENERIC_CLOSING.test(foldTr(overall))) {
    return 'generic_closing';
  }
  if (!input.trustedHandSide && INFERRED_HAND.test(foldTr(earlyPalm))) {
    return 'inferred_handedness';
  }
  if (observation.length < 60 || overall.length < 40) return 'too_short';
  if (wordCount(joinPalm(input)) < 90) return 'too_short';
  if (sectionsDuplicate([overall, takeaway, observation])) {
    return 'duplicate_sections';
  }
  if (PALM_WEAK_OBS.test(foldTr(observation)) || !PALM_ATTR.test(foldTr(observation))) {
    return 'weak_observation';
  }
  if (palmAttributeCount(input) < 4) return 'insufficient_anchors';
  if (majorLinesWithMultiAttr(input) < 2) return 'insufficient_anchors';
  const blob = joinPalm(input);
  if (PALM_STOCK.test(foldTr(blob))) return 'repeated_stock';
  if (
    countMatches(foldTr(blob), /isaret ed(er|iyor)|gosterebilir|points to|suggests/gi) >= 3
  ) {
    return 'repeated_stock';
  }
  if (CERTAINTY.test(foldTr(blob))) return 'unsupported_certainty';
  if (MEDICAL.test(foldTr(blob))) return 'prohibited_claim';
  return localeMarkerFailure(blob, input.language);
}

function coffeeAnchorScore(observation: string): number {
  const o = foldTr(observation);
  let n = 0;
  if (COFFEE_REGION.test(o)) n++;
  if (COFFEE_DENSITY.test(o)) n++;
  if (COFFEE_SHAPE.test(o)) n++;
  const regions = o.match(/(agiz|ust|orta|dip|kulp|duvar|rim|base|handle)/gi);
  if (regions && new Set(regions.map((r) => r.toLowerCase())).size >= 2) {
    n++;
  }
  return n;
}

function palmAttributeCount(input: PalmQualityInput): number {
  const texts = [
    input.visualObservation,
    input.heartLine,
    input.headLine,
    input.lifeLine,
    input.fateLine,
  ].map(foldTr);
  let n = 0;
  for (const t of texts) {
    const hits = t.match(PALM_ATTR);
    if (hits) n += hits.length;
  }
  const joined = texts.join(' ');
  const classes = [
    /(yay|kivrim|egri|curv)/i,
    /(derin|sig|koyu|kontrast|depth)/i,
    /(kesik|kopuk|surekli|contin)/i,
    /(aralik|yakin|uzak|spacing)/i,
    /(baslar|biter|uc|origin|endpoint)/i,
    /(duz|straight)/i,
  ];
  return Math.max(n, classes.filter((re) => re.test(joined)).length);
}

function majorLinesWithMultiAttr(input: PalmQualityInput): number {
  const lines = [input.heartLine, input.headLine, input.lifeLine, input.fateLine].map(
    foldTr,
  );
  let count = 0;
  for (const line of lines) {
    if (!line.trim()) continue;
    const attrs = [
      /(yay|kivrim|egri|curv|duz)/i,
      /(derin|sig|koyu|kontrast|belirgin|depth)/i,
      /(kesik|kopuk|surekli|devam|contin)/i,
      /(aralik|yakin|uzak|spacing)/i,
      /(baslar|biter|uc|bilek|parmak|origin|end)/i,
    ].filter((re) => re.test(line)).length;
    if (attrs >= 2) count++;
  }
  if (
    count < 2 &&
    palmAttributeCount(input) >= 4 &&
    input.visualObservation.length >= 100
  ) {
    const filled = lines.filter((l) => l.trim().length >= 20);
    if (filled.length === 0) return 0;
  }
  return count;
}

function takeawayContainedInOverall(overall: string, takeaway: string): boolean {
  const t = foldTr(takeaway);
  if (t.length < 20) return false;
  return foldTr(overall).includes(t);
}

function closingQuestionHabit(overall: string, takeaway: string): boolean {
  const oQ = isQuestion(overall);
  const tQ = isQuestion(takeaway);
  if (!tQ) return false;
  if (oQ && tQ) {
    const a = questionCore(lastSentence(overall));
    const b = questionCore(takeaway);
    if (!a || !b) return true;
    if (a === b) return true;
    if (overlapRatio(a, b) >= 0.55) return true;
    if (
      /(bulusma|toplanti|meeting)/i.test(a) &&
      /(bulusma|toplanti|meeting)/i.test(b)
    ) {
      return true;
    }
  }
  return false;
}

/** Takeaway question that merely restates başlangıç/buluşma/kapı themes from the body. */
function boilerplateClosingQuestion(overall: string, takeaway: string): boolean {
  if (!isQuestion(takeaway)) return false;
  const t = foldTr(takeaway);
  const o = foldTr(overall);
  const theme =
    /(baslangic|bulusma|bir araya|kapilar|kapi arala)/i.test(t) &&
    /(baslangic|bulusma|bir araya|kapilar|kapi arala)/i.test(o);
  return theme;
}

function repeatKeyIdea(text: string, keys: string[]): boolean {
  const n = foldTr(text);
  for (const key of keys) {
    const re = new RegExp(key, 'gi');
    const m = n.match(re);
    if (m && m.length >= 3) return true;
  }
  return false;
}

function isQuestion(s: string): boolean {
  const t = s.trim();
  return /\?\s*$/.test(t) || /(m[ıiuü]s[ıiuü]n)\s*\?/i.test(t);
}

function lastSentence(s: string): string {
  const parts = s
    .split(/(?<=[.!?])\s+/)
    .map((p) => p.trim())
    .filter(Boolean);
  return parts[parts.length - 1] ?? s;
}

function questionCore(s: string): string {
  return foldTr(s)
    .replace(/[?!.,;:"""'']/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function overlapRatio(a: string, b: string): number {
  const wa = new Set(a.split(' ').filter((w) => w.length > 2));
  const wb = b.split(' ').filter((w) => w.length > 2);
  if (wa.size === 0 || wb.length === 0) return 0;
  let hit = 0;
  for (const w of wb) if (wa.has(w)) hit++;
  return hit / Math.max(wb.length, 1);
}

function wordCount(s: string): number {
  return s
    .trim()
    .split(/\s+/)
    .filter((w) => w.length > 0).length;
}

function countMatches(s: string, re: RegExp): number {
  return (s.match(re) ?? []).length;
}

/** Unicode-safe Turkish fold: diacritics → ASCII so patterns stay stable. */
export function foldTr(s: string): string {
  return s
    .normalize('NFC')
    .toLocaleLowerCase('tr-TR')
    .replace(/\u0131/g, 'i')
    .replace(/\u011f/g, 'g')
    .replace(/\u00fc/g, 'u')
    .replace(/\u015f/g, 's')
    .replace(/\u00f6/g, 'o')
    .replace(/\u00e7/g, 'c')
    .replace(/\u0130/g, 'i');
}

function joinSections(input: CoffeeQualityInput): string {
  return [
    input.visualObservation,
    input.overall,
    input.love,
    input.career,
    input.money,
    input.nearFuture,
    input.takeaway,
  ].join(' ');
}

function joinPalm(input: PalmQualityInput): string {
  return [
    input.visualObservation,
    input.overall,
    input.lifeLine,
    input.headLine,
    input.heartLine,
    input.fateLine,
    input.takeaway,
  ].join(' ');
}

function sectionsDuplicate(parts: string[]): boolean {
  const normalized = parts
    .map((p) => foldTr(p.trim()))
    .filter((p) => p.length >= 20);
  for (let i = 0; i < normalized.length; i++) {
    for (let j = i + 1; j < normalized.length; j++) {
      if (normalized[i] === normalized[j]) return true;
    }
  }
  return false;
}

function localeMarkerFailure(
  blob: string,
  language: 'tr' | 'en' | 'ru' | undefined,
): HumanQualityFailure | null {
  if (!language) return null;
  const cyrillic = (blob.match(/[\u0400-\u04FF]/g) ?? []).join('').length;
  const latin = (blob.match(/[A-Za-zÀ-ÿ]/g) ?? []).join('').length;
  if (language === 'ru' && cyrillic < 8 && latin > 40) {
    return 'wrong_locale_marker';
  }
  if ((language === 'tr' || language === 'en') && cyrillic > 40 && latin < 8) {
    return 'wrong_locale_marker';
  }
  return null;
}
