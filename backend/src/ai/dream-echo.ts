import type { AppLanguage } from './app-language.js';
import { asciiFold, sameWord } from './dream-lexical.js';
import { significant } from './dream-quality.js';

/**
 * Scene echo — an interpretation that only retells what was seen.
 * Perception words are not symbol meanings. No dream dictionary.
 * A shared dream word is not enough; residue is whatever else was said.
 */
const ECHO_STEMS = [
  'gorul', 'gorunt', 'sahne', 'dikkat', 'doldur', 'kucuk', 'canli',
  'gozden', 'kacabil', 'farked', 'okunabil', 'belirgin', 'yalniz',
  'alanin', 'odaklan', 'kolayca', 'uzerinden', 'cikiyor', 'noticed',
  'notice', 'attention', 'scene', 'замет', 'вниман',
];

const ECHO_EXACT = new Set([
  'one', 'fark', 'edilir', 'hale', 'gelmesi', 'seyin', 'sey', 'seen', 'image',
]);

const HANDBACK = [
  /aklina/,
  /cagrisim/,
  /ne anlama geliyor/,
  /comes to mind/,
  /do you associate/,
  /what does (?:this|it) mean to you/,
  /приходит в голову/,
  /ассоциац/,
];

function echoToken(word: string): boolean {
  const folded = asciiFold(word).replace(/â/g, 'a');
  if (ECHO_EXACT.has(folded)) return true;
  return ECHO_STEMS.some((stem) => folded === stem || (stem.length >= 5 && folded.startsWith(stem)));
}

/** Content words that are neither the dream nor a remark that it was noticed. */
export function interpretiveResidue(
  text: string,
  narrative: string,
  language: AppLanguage,
): string[] {
  const told = [...significant(narrative)];
  return [...significant(text)].filter(
    (word) => !echoToken(word) && !told.some((toldWord) => sameWord(word, toldWord, language)),
  );
}

export function isEchoInterpretation(
  narrative: string,
  interpretation: string,
  language: AppLanguage,
): boolean {
  const sentences = interpretation
    .split(/[.!?…]+/u)
    .map((sentence) => sentence.trim())
    .filter((sentence) => sentence.length >= 12);
  if (!sentences.length) return true;
  const thin = sentences.filter(
    (sentence) => interpretiveResidue(sentence, narrative, language).length < 3,
  );
  return thin.length === sentences.length
    || interpretiveResidue(interpretation, narrative, language).length < 4;
}

/** A conclusion that asks the dreamer to supply the reading. */
export function handsInterpretationBack(conclusion: string): boolean {
  return HANDBACK.some((pattern) => pattern.test(asciiFold(conclusion)));
}
