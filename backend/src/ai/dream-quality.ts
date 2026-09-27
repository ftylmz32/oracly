import type { AppLanguage } from './app-language.js';
import { asciiFold, lightFold, sameStrict, sameWord, SHORT_STOP, toldWords } from './dream-lexical.js';
import type { DreamData } from './parse-provider.js';

/**
 * Dream acceptance gate — runs after structural parse, before success.
 * Deterministic and evidence-based: the parsed sections are compared only
 * with what the user supplied (sanitized narrative, observed symbols and
 * emotions) and the request language. No identity, birth data or tokens.
 * Crisis / self-harm handling is deliberately out of scope here.
 */
export type DreamQualityInput = {
  narrative: string;
  symbols: string[];
  emotions: string[];
  language: AppLanguage;
};

export type DreamQualityFailure =
  | 'thin_section'
  | 'duplicate_sections'
  | 'invented_symbol'
  | 'ungrounded'
  | 'generic_boilerplate'
  | 'language_mismatch'
  | 'conclusion_not_question'
  | 'dictionary_style';

const MIN_CHARS: Array<[keyof DreamData, number]> = [
  ['summary', 20],
  ['emotionalTheme', 16],
  ['interpretation', 60],
  ['dailyLifeReflection', 30],
  ['conclusion', 16],
];

export const STOP = new Set([
  // tr (folded)
  'icin', 'gibi', 'olan', 'daha', 'kadar', 'sonra', 'onlar', 'bunu', 'senin',
  'sana', 'seni', 'bana', 'beni', 'olarak', 'olabilir', 'belki', 'degil',
  'simdi', 'sanki', 'icinde', 'diye', 'neden', 'nasil', 'hangi', 'bile',
  'cunku', 'ancak', 'fakat', 'yine', 'bazen', 'seyler', 'bir', 'bu', 've',
  // en
  'the', 'and', 'you', 'your', 'this', 'that', 'with', 'from', 'have',
  'there', 'their', 'what', 'when', 'where', 'which', 'while', 'about',
  'into', 'like', 'just', 'then', 'than', 'them', 'they', 'were', 'been',
  'some', 'more', 'very', 'also', 'only', 'even', 'still', 'might', 'could',
  'would', 'should', 'because', 'through', 'something', 'was', 'are', 'for',
  // ru (ё folded to е)
  'это', 'этот', 'этой', 'этом', 'который', 'которая', 'когда', 'тогда',
  'потом', 'очень', 'будто', 'словно', 'может', 'можно', 'тебя', 'тебе',
  'твой', 'твоя', 'меня', 'было', 'была', 'были', 'быть', 'есть', 'чтобы',
  'только', 'даже', 'если', 'здесь', 'него', 'себя', 'свой', 'как', 'что',
]);

const TR_MARKERS = ['bir', 've', 'bu', 'icin', 'gibi', 'ile', 'ama', 'da', 'de', 'daha', 'cok', 'olarak', 'sen', 'senin', 'ne', 'mi', 'belki', 'degil', 'olabilir'];
const EN_MARKERS = ['the', 'and', 'of', 'to', 'is', 'in', 'you', 'your', 'that', 'this', 'with', 'it', 'as', 'for', 'was', 'what', 'might', 'may', 'can', 'not'];

const DICTIONARY =
  /(^|\s)[\p{L}]+\s*=\s*[\p{L}]+|anlam\s*:|meaning\s*:|значение\s*:|temsil eder|demektir|r[uü]ya tabiri|tabirname|symbolizes|dream dictionary|символизирует|сонник/iu;

const GENERIC =
  /yeni bir ba[sş]lang[iı][cç]|yeni bir f[iı]rsat|g[uü]zel haberler|de[gğ]i[sş]im geliyor|hedeflerine ula[sş]acaks[iı]n|new beginning|new opportunit|good news is coming|change is coming|journey of self-discovery|новое начало|новые возможности|хорошие новости|грядут перемены/giu;

export function evaluateDreamQuality(
  data: DreamData,
  input: DreamQualityInput,
): DreamQualityFailure | null {
  for (const [key, min] of MIN_CHARS) {
    const value = data[key];
    if (typeof value !== 'string' || value.trim().length < min) return 'thin_section';
  }
  const sections = [
    data.summary,
    data.emotionalTheme,
    data.interpretation,
    data.dailyLifeReflection,
    data.conclusion,
  ];
  if (hasNearDuplicate(sections)) return 'duplicate_sections';
  if (sections.some((s) => DICTIONARY.test(s))) return 'dictionary_style';
  if (!isSingleQuestion(data.conclusion)) return 'conclusion_not_question';
  const prose = sections.join(' ');
  if (!languageMatches(prose, input.language)) return 'language_mismatch';
  if ((prose.match(GENERIC) ?? []).length >= 2) return 'generic_boilerplate';
  // Grounding is lexical and applies to every request. The client asks for
  // the narrative's own language when it can identify it, so input and
  // output share words; a cross-language response must still share real
  // evidence (names, told words) or it fails closed.
  const evidence = significant(
    [input.narrative, ...input.symbols, ...input.emotions].join(' '),
  );
  if (evidence.size === 0) return null;
  // Symbols are evidence claims: STRICT word forms only (see dream-lexical).
  const told = toldWords(input.narrative, input.symbols, input.language);
  for (const symbol of data.symbols) {
    const words = symbolWords(symbol, input.language);
    if (!words.length) continue;
    if (!words.some((w) => [...told].some((t) => sameStrict(w, t, input.language)))) {
      return 'invented_symbol';
    }
  }
  const grounded = (s: string) => overlaps(significant(s), evidence, input.language);
  if (!grounded(data.interpretation)) return 'ungrounded';
  if (![data.summary, data.dailyLifeReflection, data.conclusion].some(grounded)) {
    return 'ungrounded';
  }
  return null;
}

/** Lowercase + fold Turkish letters and ё so spelling variants compare. */
export const foldDream = asciiFold;

export function tokens(s: string): string[] {
  return foldDream(s).split(/[^a-z0-9\u00e0-\u00ff\u0430-\u044f]+/).filter(Boolean);
}

export function isDreamWord(w: string): boolean {
  return /^(ruya|dream|сновид)/.test(w) || ['сон', 'сне', 'сна', 'сну', 'снов', 'сном', 'снах'].includes(w);
}

export function significant(s: string): Set<string> {
  return new Set(tokens(s).filter((w) => w.length >= 3 && !STOP.has(w) && !isDreamWord(w)));
}

/** Light-folded symbol words of two or more letters that carry meaning. */
function symbolWords(symbol: string, language: AppLanguage): string[] {
  return (lightFold(symbol).match(/[\p{L}\p{N}]+/gu) ?? []).filter((w) => {
    const a = asciiFold(w);
    return w.length >= 2 && !STOP.has(a) && !isDreamWord(a) && !SHORT_STOP[language].has(w);
  });
}

/** GENERAL grounding — see dream-lexical `sameWord`. */
export function overlaps(text: Set<string>, evidence: Set<string>, language: AppLanguage): boolean {
  for (const w of text) {
    for (const e of evidence) if (sameWord(w, e, language)) return true;
  }
  return false;
}

function hasNearDuplicate(sections: string[]): boolean {
  const sets = sections.map(significant);
  for (let i = 0; i < sets.length; i++) {
    for (let j = i + 1; j < sets.length; j++) {
      const a = sets[i]!;
      const b = sets[j]!;
      if (!a.size || !b.size) continue;
      let shared = 0;
      for (const w of a) if (b.has(w)) shared++;
      if (shared / Math.min(a.size, b.size) >= 0.8 && Math.min(a.size, b.size) >= 3) return true;
      if (foldDream(sections[i]!).trim() === foldDream(sections[j]!).trim()) return true;
    }
  }
  return false;
}

/** The conclusion is exactly one open question (TR / EN / RU all use `?`). */
export function isSingleQuestion(s: string): boolean {
  return (s.match(/[?？]/g) ?? []).length === 1;
}

function scriptShare(s: string): { cyr: number; lat: number } {
  const cyr = (s.match(/[\u0400-\u04FF]/g) ?? []).length;
  const lat = (s.match(/[A-Za-z\u00C0-\u024F]/g) ?? []).length;
  return { cyr, lat };
}

function markerHits(s: string, markers: string[]): number {
  const set = new Set(markers);
  return tokens(s).filter((w) => set.has(w)).length;
}

/**
 * Conservative: proper nouns and shared words pass; only a response that
 * materially ignores the requested language is rejected.
 */
export function languageMatches(prose: string, language: AppLanguage): boolean {
  const { cyr, lat } = scriptShare(prose);
  const letters = cyr + lat;
  if (!letters) return false;
  if (language === 'ru') return cyr / letters >= 0.5;
  if (cyr / letters > 0.2) return false;
  const tr = markerHits(prose, TR_MARKERS);
  const en = markerHits(prose, EN_MARKERS);
  if (language === 'en') return !(tr >= 4 && tr > en * 2);
  return !(en >= 4 && en > tr * 2);
}
