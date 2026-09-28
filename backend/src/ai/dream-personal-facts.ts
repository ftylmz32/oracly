import { lightFold } from './dream-lexical.js';

/**
 * Invented biography — a life domain (work, relationship, family, money,
 * school, health, childhood, social) addressed to the reader ("your job",
 * "ailen") that neither the Dream nor the safe connected memory mentions.
 * Symbolic language without a domain word always passes.
 *
 * Relationship words split three ways (Phase 4C.1): a family qualifier
 * ("семейных отношениях", "family relationships") is the family domain; a
 * romantic word, or a bare singular "your relationship", is the romantic
 * `relationship` domain and needs romantic evidence; any other
 * "relationships / ilişkiler / отношения" is a generic `social` reference,
 * supported by any person the Dream names (a friend, a sister, a partner).
 */
export type PersonalDomain =
  | 'work' | 'relationship' | 'family' | 'money' | 'school' | 'health' | 'childhood' | 'social';

const FAMILY = /^(?:family|families|familial|mother\p{L}*|father\p{L}*|mom|mum|dad|parent\p{L}*|sibling\p{L}*|brother\p{L}*|sister\p{L}*|aile\p{L}*|anne\p{L}*|baba\p{L}*|kardeş\p{L}*|ebeveyn\p{L}*|семь(?:я|и|е|ю|ей)|семейн\p{L}*|родствен\p{L}*|мать|матери|мама|мамы|маме|маму|мамой|отец|отца|отцу|отцом|папа|папы|папе|папу|родител\p{L}*|брат|брата|брату|братом|сестр\p{L}*)$/u;
const ROMANTIC = /^(?:partner\p{L}*|boyfriend\p{L}*|girlfriend\p{L}*|husband\p{L}*|wife|spouse\p{L}*|marriage\p{L}*|romanc\p{L}*|romantic\p{L}*|sevgili\p{L}*|evlilik\p{L}*|evliliğ\p{L}*|romantik\p{L}*|eşin\p{L}*|kocan\p{L}*|партнер\p{L}*|муж|мужа|мужу|мужем|муже|жена|жены|жене|жену|женой|брак\p{L}*|романтич\p{L}*|любовн\p{L}*)$/u;
const RELATION = /^(?:relationships?|ilişki\p{L}*|отношени(?:я|ях|ями|й))$/u;
const FRIEND = /^(?:friend\p{L}*|arkadaş\p{L}*|dost\p{L}*|друг|друга|другу|другом|друзья\p{L}*|друзей|подруг\p{L}*)$/u;
/** A bare possessive singular relationship reads as romantic ("your relationship", "ilişkin"). */
const ROMANTIC_POSSESSIVE = /^(?:ilişkin|ilişkiniz)$/u;
const EN_POSSESSIVE = new Set(['your', 'my']);
const RU_POSSESSIVE = new Set(['твои', 'ваши', 'твоих', 'ваших', 'твоими', 'вашими']);

const DOMAINS: Array<[PersonalDomain, RegExp]> = [
  ['work', /^(?:jobs?|careers?|boss\p{L}*|colleagu\p{L}*|coworker\p{L}*|workplace\p{L}*|office\p{L}*|iş|işi|işin\p{L}*|işyer\p{L}*|kariyer\p{L}*|patron\p{L}*|meslek\p{L}*|ofis\p{L}*|работ(?:а|ы|е|у|ой|ах)|карьер\p{L}*|начальни\p{L}*|коллег\p{L}*|офис\p{L}*)$/u],
  ['relationship', ROMANTIC],
  ['family', FAMILY],
  ['money', /^(?:money|financ\p{L}*|debts?|bills|salary|salaries|rent|para|paran\p{L}*|parası\p{L}*|paray\p{L}*|maddi|borç\p{L}*|borc\p{L}*|maaş\p{L}*|finans\p{L}*|деньг\p{L}*|денег|финанс\p{L}*|долг|долги|долгов|долгах|зарплат\p{L}*)$/u],
  ['school', /^(?:school\p{L}*|exams?|universit\p{L}*|college|homework|grades|okul\p{L}*|sınav\p{L}*|üniversite\p{L}*|школ\p{L}*|экзамен\p{L}*|учеб\p{L}*|университет\p{L}*)$/u],
  ['health', /^(?:health\p{L}*|illness\p{L}*|disease\p{L}*|sickness|sağlı\p{L}*|sağlık\p{L}*|hastalı\p{L}*|hastalık\p{L}*|здоровь\p{L}*|болезн\p{L}*)$/u],
  ['childhood', /^(?:childhood|çocukluğ\p{L}*|çocukluk\p{L}*|детств\p{L}*)$/u],
];
/** Evidence-only forms: the dreamer telling a childhood scene supports "childhood". */
const CHILDHOOD_TOLD = /^(?:çocukken|çocuktum|ребенком|kid|child)$/u;

const EN_WORK_OWNER = new Set(['your', 'my', 'at', 'from', 'after']);

const ADDRESS = new Set([
  'you', 'your', 'yours', 'yourself', "you're", "you've", "you'll",
  'sen', 'senin', 'sana', 'seni', 'sende', 'senden', 'seninle',
  'ты', 'тебя', 'тебе', 'тобой', 'твой', 'твоя', 'твое', 'твои', 'твоей',
  'твоего', 'твоих', 'твоим', 'твоими', 'твоему', 'твоем', 'вы', 'вас', 'вам',
  'ваш', 'ваша', 'ваше', 'ваши', 'вашей', 'вашего', 'ваших', 'вашим', 'вашему',
]);
/** Turkish second-person forms: possessive domain nouns and verb endings. */
const TR_ADDRESS =
  /^(?:ailen|annen|baban|kardeşin|işin|işyerin|kariyerin|patronun|ilişkin|sevgilin|eşin|evliliğin|paran|borcun|borçların|maaşın|okulun|sınavın|sağlığın|hastalığın|çocukluğun)\p{L}*$|\p{L}{3,}(?:s[ıiuü]n|s[ıiuü]n[ıiuü]z)$/u;

function words(text: string): string[] {
  return lightFold(text.replace(/[’`]/g, "'")).match(/[\p{L}']+/gu) ?? [];
}

function relationDomain(ws: string[], i: number): PersonalDomain {
  const w = ws[i]!;
  const near = ws.slice(Math.max(0, i - 2), i);
  if (near.some((x) => FAMILY.test(x))) return 'family';
  if (near.some((x) => ROMANTIC.test(x)) || ROMANTIC_POSSESSIVE.test(w)) return 'relationship';
  if (w === 'relationship' && EN_POSSESSIVE.has(ws[i - 1] ?? '')) return 'relationship';
  if (RU_POSSESSIVE.has(ws[i - 1] ?? '')) return 'relationship';
  return 'social';
}

function domainsOf(ws: string[]): Set<PersonalDomain> {
  const out = new Set<PersonalDomain>();
  ws.forEach((w, i) => {
    if (w === 'work' && EN_WORK_OWNER.has(ws[i - 1] ?? '')) out.add('work');
    if (RELATION.test(w)) out.add(relationDomain(ws, i));
    for (const [domain, pattern] of DOMAINS) if (pattern.test(w)) out.add(domain);
  });
  return out;
}

function supportedBy(evidence: string): Set<PersonalDomain> {
  const ws = words(evidence);
  const out = domainsOf(ws);
  if (ws.some((w) => CHILDHOOD_TOLD.test(w))) out.add('childhood');
  if (out.has('family') || out.has('relationship') || ws.some((w) => FRIEND.test(w))) out.add('social');
  return out;
}

/**
 * The first domain the [prose] asserts about the reader without support in
 * [evidence] (current narrative, observed symbols/emotions, safe memory).
 */
export function unsupportedPersonalDomain(
  prose: string[],
  evidence: string,
): PersonalDomain | null {
  const supported = supportedBy(evidence);
  for (const section of prose) {
    for (const sentence of section.split(/[.!?…;]+/u)) {
      const ws = words(sentence);
      if (!ws.some((w) => ADDRESS.has(w) || TR_ADDRESS.test(w))) continue;
      for (const domain of domainsOf(ws)) if (!supported.has(domain)) return domain;
    }
  }
  return null;
}
