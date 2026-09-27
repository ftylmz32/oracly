import { lightFold } from './dream-lexical.js';

/**
 * Invented biography — a life domain (work, relationship, family, money,
 * school, health, childhood) addressed to the reader ("your job", "ailen")
 * that neither the Dream nor the safe connected memory mentions. Symbolic
 * language without a domain word always passes.
 */
export type PersonalDomain =
  | 'work' | 'relationship' | 'family' | 'money' | 'school' | 'health' | 'childhood';

const DOMAINS: Array<[PersonalDomain, RegExp]> = [
  ['work', /^(?:jobs?|careers?|boss\p{L}*|colleagu\p{L}*|coworker\p{L}*|workplace\p{L}*|office\p{L}*|iş|işi|işin\p{L}*|işyer\p{L}*|kariyer\p{L}*|patron\p{L}*|meslek\p{L}*|ofis\p{L}*|работ(?:а|ы|е|у|ой|ах)|карьер\p{L}*|начальни\p{L}*|коллег\p{L}*|офис\p{L}*)$/u],
  ['relationship', /^(?:relationships?|partner\p{L}*|boyfriend\p{L}*|girlfriend\p{L}*|husband\p{L}*|wife|spouse\p{L}*|marriage\p{L}*|romanc\p{L}*|romantic\p{L}*|ilişki\p{L}*|sevgili\p{L}*|evlilik\p{L}*|evliliğ\p{L}*|eşin\p{L}*|kocan\p{L}*|отношени(?:я|ях|ями)|партнер\p{L}*|муж|мужа|мужу|мужем|муже|жена|жены|жене|жену|женой|брак\p{L}*|романтич\p{L}*)$/u],
  ['family', /^(?:famil\p{L}*|mother\p{L}*|father\p{L}*|mom|mum|dad|parent\p{L}*|sibling\p{L}*|brother\p{L}*|sister\p{L}*|aile\p{L}*|anne\p{L}*|baba\p{L}*|kardeş\p{L}*|ebeveyn\p{L}*|семь(?:я|и|е|ю|ей)|мать|матери|мама|мамы|маме|маму|мамой|отец|отца|отцу|отцом|папа|папы|папе|папу|родител\p{L}*|брат|брата|брату|братом|сестр\p{L}*)$/u],
  ['money', /^(?:money|financ\p{L}*|debts?|bills|salary|salaries|rent|para|paran\p{L}*|parası\p{L}*|paray\p{L}*|maddi|borç\p{L}*|borc\p{L}*|maaş\p{L}*|finans\p{L}*|деньг\p{L}*|денег|финанс\p{L}*|долг|долги|долгов|долгах|зарплат\p{L}*)$/u],
  ['school', /^(?:school\p{L}*|exams?|universit\p{L}*|college|homework|grades|okul\p{L}*|sınav\p{L}*|üniversite\p{L}*|школ\p{L}*|экзамен\p{L}*|учеб\p{L}*|университет\p{L}*)$/u],
  ['health', /^(?:health\p{L}*|illness\p{L}*|disease\p{L}*|sickness|sağlı\p{L}*|sağlık\p{L}*|hastalı\p{L}*|hastalık\p{L}*|здоровь\p{L}*|болезн\p{L}*)$/u],
  ['childhood', /^(?:childhood|çocukluğ\p{L}*|çocukluk\p{L}*|детств\p{L}*)$/u],
];

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

function domainsOf(ws: string[]): Set<PersonalDomain> {
  const out = new Set<PersonalDomain>();
  ws.forEach((w, i) => {
    if (w === 'work' && EN_WORK_OWNER.has(ws[i - 1] ?? '')) out.add('work');
    for (const [domain, pattern] of DOMAINS) if (pattern.test(w)) out.add(domain);
  });
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
  const supported = domainsOf(words(evidence));
  for (const section of prose) {
    for (const sentence of section.split(/[.!?…;]+/u)) {
      const ws = words(sentence);
      if (!ws.some((w) => ADDRESS.has(w) || TR_ADDRESS.test(w))) continue;
      for (const domain of domainsOf(ws)) if (!supported.has(domain)) return domain;
    }
  }
  return null;
}
