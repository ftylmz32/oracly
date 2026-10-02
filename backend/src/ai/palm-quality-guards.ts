/**
 * Palm-only voice and claim guards, calibrated on real provider output
 * (Batch 3A.4, E3H.1). Every input is already foldTr()-folded. Patterns
 * describe grammatical shapes and concept families — never the audited
 * sentences themselves. Coffee never calls these.
 */

export type PalmGuardFailure =
  | 'prohibited_claim'
  | 'unsupported_certainty'
  | 'unsupported_other_person'
  | 'presumed_user_state'
  | 'coaching_voice'
  | 'dictionary_voice'
  | 'person_switch'
  | 'section_redundancy';

/** Folded interpretation lanes (visualObservation excluded). */
export type PalmGuardLanes = {
  overall: string;
  lifeLine: string;
  headLine: string;
  heartLine: string;
  fateLine: string;
  takeaway: string;
};

const MEDICAL =
  /\bsaglik (sorun|problem|sikinti|risk|durum)|\bsagligin(da|i|a|la)?\b|\bhastalik|\bteshis|\btibbi\b|\bameliyat|\bomr(e|u|un|une|unu|unden)\b|\bomur\b|\byasam sures|\bolum(u|un|e|den|le)?\b|\bolece(k|gi)|\bhamile|\bgebelik|\bdogurgan|\bkisirlik|\bdiagnos|\billness|\bdisease|\blifespan|\bdeath\b|\bpregnan|\bhealth (problem|issue|condition|risk)/;

const CERTAIN_MARK =
  /\b(kesinlikle|kesin olarak|mutlaka|kuskusuz|hic suphesiz|kacinilmaz olarak|garanti(li)?|definitely|certainly|inevitably|without (a )?doubt)\b/;
const FUTURE = /\b[a-z]{2,}(acak|ecek|acag|eceg)[a-z]*|\bwill\b/;
const TIME_ANCHOR =
  /\b(yakinda|bu yil|gelecek (ay|yil|hafta)|onumuzdeki|ileride|soon|next (year|month))\b/;
const FUTURE_PERSONAL = /\b[a-z]{2,}(acaksin|eceksin|acaksiniz|eceksiniz|acaktir|ecektir)\b|\byou will\b/;

const OTHER_PERSON =
  /\bkarsi taraf|\bkarsindaki|\bpartner(in|ine|inin|inle)?\b|\bsevgilin|\b(o|diger) kisi(nin|ye|yi|de)?\b|\b(sevdigin|deger verdigin|hoslandigin|ilgilendigin|bekledigin|yakin oldugun|aklindaki|hayatindaki) (kisi|insan|biri)(nin|ye|yi|si|sine)?\b|\bbiri(si)? (seni|sana|senin)\b|\bthe other person|\byour partner|\bsomeone (you|special)/;
const OTHERS_SUBJECT = /\b(insanlar|cevrendekiler|baskalari|digerleri|yakinlarin|others|people)\b/;
const OTHER_MIND =
  /\b(sanabilir|saniyor|zannedebilir|fark etmeyebilir|fark edebilir|fark eder|anlamayabilir|anlayabilir|anliyor|anlamiyor|gormeyebilir|goremeyebilir|gorur|gorebilir|dusunebilir|dusunur|hissedebilir|bekleyebilir|bekler|algilayabilir|yorumlayabilir|may (not )?(notice|see|think|feel|realize))\b/;

const PRESUMED: RegExp[] = [
  /\b(su (siralar|sira|gunlerde|donemde|an)|bu (gunlerde|siralar|aralar|donemde)|son (zamanlarda|gunlerde|donemde|aylarda|haftalarda)|uzun (suredir|zamandir)|yillardir|aylardir|haftalardir|lately|these days)\b/,
  /\b(bekledigin|icinde tuttugun|icinde tasidigin|sakladigin|erteledigin|vazgectigin|kaybettigin|ayrildigin|takildigin)\b/,
  /\byasadigin (donem|surec|bu|o|olay|iliski|sorun|zorluk|degisim|karmasa|ayrilik|kayip|belirsizlik|gerilim|sikinti)/,
  /\b[a-z]+(meye|maya) calistigin\b/,
  /\buzun (sure|zaman)(dir)? [a-z]+ (kal|tut|bekle|tasi|sakla)(man|digin|din|mis)/,
  /\barasinda kal(mis|din|digin|diysan)/,
  /\b(zihninde|kalbinde|aklinda) (zaten |coktan )?[a-z]+(mis|mus)\b|\bicinde (birikmis|biriken|kalmis)\b/,
  /\b(fazla|gereginden fazla|asiri) buyut/,
];

const COACHING: RegExp[] = [
  /\bsana (cok |daha )?iyi (gel|olur|bir [^.;]{0,40}(sun|sagla))/,
  /\b(faydali|yararli|iyi) olur\b/,
  /\b[a-z]{3,}m[ae]n(in)?\b[^.;]{0,80}\b(saglar|gerekir|gerek|lazim|onemlidir|iyi gelir|yardimci olur)\b/,
  /\b[a-z]+(meye|maya) calis(?![a-z])/,
  /\b[a-z]+(meli|mali)(sin|siniz)\b/,
  /\bkendine\b[^.;]{0,30}\b(alan|zaman|izin|sans|firsat) (ac|tani|ver|yarat)(?![a-z])/,
  /\b(belirle|koru|ciz|sinirla|ertele|birak|dene|dinle|hatirla|unutma|odaklan|adlandir|sadelestir|azalt|yavasla|paylas|konus|dikkat et|acele etme|izin ver|ifade et)(?=\s*([.;!:]|$|,?\s+(ve|sonra|ama)\b))/,
  /\b(you should|make sure (to|you)|try to|you need to)\b/,
];

const DICTIONARY =
  /\b(bagdastiril|iliskilendiril|baglantilandiril|atfedil)[a-z]*|\bkarsilik gel[a-z]*|\bdenk gel(ir|ebilir|mektedir)\b|\b(olarak|seklinde) (okun|yorumlan|degerlendiril|ele alin)[a-z]*|\b[a-z]+(la|le) (okun|yorumlan)[a-z]*|\byorumlan(ir|abilir|maktadir)\b|\b[a-z]+(mesine|masina|mesiyle|masiyla) baglan(ir|abilir)\b|\b(is associated with|corresponds to|is interpreted as|is read as|is linked to)\b/;

const SECOND_PERSON =
  /\b(sen|sana|seni|senin|sende|senden)\b|\b[a-z]+(yorsun|ebilirsin|abilirsin|digin|dugun|tigin|tugun)\b/;
/** Active third-person verbal noun ("göstermesi"); passive "-ilmesi" is impersonal. */
const THIRD_NOMINAL = /\b[a-z]+?(?<!il|ul|in|un)(mesi|masi)\b/g;
/** A genitive subject ("çizginin ... ilerlemesi") makes the verbal noun about that subject. */
const GENITIVE = /\b[a-z]+(nin|nun|in|un)\b/;

/** Trait families a reading may share, but not restate lane after lane. */
const FAMILIES: RegExp[][] = [
  [/guven/, /olculu|secici|temkin|ihtiyat/, /hemen (sergile|dok|goster|ac)|aceleden|yavas yavas|zamanla|zamana yay/, /acilma|acma egilim|disa vur/],
  [/surek|devam/, /istikrar|tutarli/, /bagli/, /sahiplen/, /kalici|uzun sure/, /vazgec/],
  [/dusunce|dusunme|dusunur|dusunmek/, /tart[aim]/, /degerlendir/, /netles|isle(yip|me|mek)/, /karar/, /secenek|olasilik/],
];

const sentences = (t: string) => t.split(/[.!?;\n]+/).map((s) => s.trim()).filter(Boolean);

export const palmMedicalClaim = (blob: string) => MEDICAL.test(blob);

export function palmCertaintyClaim(blob: string): boolean {
  return sentences(blob).some(
    (s) => (CERTAIN_MARK.test(s) && FUTURE.test(s)) || (TIME_ANCHOR.test(s) && FUTURE_PERSONAL.test(s)),
  );
}

export function inventsOtherPerson(text: string): boolean {
  if (OTHER_PERSON.test(text)) return true;
  return sentences(text).some((s) => OTHERS_SUBJECT.test(s) && OTHER_MIND.test(s));
}

export const presumesUserState = (text: string) => PRESUMED.some((re) => re.test(text));
export const coachingVoice = (text: string) => COACHING.some((re) => re.test(text));
export const dictionaryVoice = (text: string) => DICTIONARY.test(text);

/** Second-person reading that profiles the same person in third person. */
export function personSwitch(lanes: string[]): boolean {
  if (!lanes.some((t) => SECOND_PERSON.test(t))) return false;
  let third = 0;
  for (const clause of lanes.join('. ').split(/[,.;!?:]+/)) {
    if (GENITIVE.test(clause)) continue;
    third += (clause.match(THIRD_NOMINAL) ?? []).length;
  }
  return third >= 3;
}

/** One trait family restated across lanes, or carried from overall into takeaway. */
export function conceptEcho(lanes: PalmGuardLanes): boolean {
  const named = Object.entries(lanes).filter(([, t]) => t.trim().length > 0);
  for (const family of FAMILIES) {
    const carriers = named
      .filter(([, t]) => family.filter((member) => member.test(t)).length >= 2)
      .map(([k]) => k);
    if (carriers.length >= 4) return true;
    if (carriers.length >= 3 && carriers.includes('overall') && carriers.includes('takeaway')) {
      return true;
    }
  }
  return false;
}

const ECHO_STOP = /^(avuc|cizgi|olabil|dusund|anlati|ediyor|icinde|gorun|tarafi)/;

function contentStems(text: string): Set<string> {
  const words = text.split(/[^a-z]+/).filter((w) => w.length >= 5 && !ECHO_STOP.test(w));
  return new Set(words.map((w) => w.slice(0, 6)));
}

/** The takeaway re-walks overall's own wording instead of landing somewhere new. */
export function takeawayEchoesOverall(overall: string, takeaway: string): boolean {
  if (!overall.trim() || !takeaway.trim()) return false;
  const base = contentStems(overall);
  return [...contentStems(takeaway)].filter((stem) => base.has(stem)).length >= 4;
}

export function palmClaimFailure(blob: string): PalmGuardFailure | null {
  if (palmMedicalClaim(blob)) return 'prohibited_claim';
  if (palmCertaintyClaim(blob)) return 'unsupported_certainty';
  return null;
}

/**
 * hasStatedContext: personalization supplied an intention or memory — the
 * only sources that may license a concrete present or past situation.
 */
export function palmVoiceFailure(lanes: PalmGuardLanes, hasStatedContext: boolean): PalmGuardFailure | null {
  const read = Object.values(lanes).filter((t) => t.trim().length > 0);
  if (read.some(inventsOtherPerson)) return 'unsupported_other_person';
  if (!hasStatedContext && read.some(presumesUserState)) return 'presumed_user_state';
  if (read.some(coachingVoice)) return 'coaching_voice';
  if (read.some(dictionaryVoice)) return 'dictionary_voice';
  if (personSwitch(read)) return 'person_switch';
  if (conceptEcho(lanes) || takeawayEchoesOverall(lanes.overall, lanes.takeaway)) {
    return 'section_redundancy';
  }
  return null;
}
