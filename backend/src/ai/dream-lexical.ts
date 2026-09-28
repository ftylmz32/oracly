import type { AppLanguage } from './app-language.js';
import { russianSame } from './dream-russian-inflection.js';

/**
 * Dream word forms — mirrors the client's TurkishLexicalMatcher and
 * DreamWordForms. Two strengths:
 *  - STRICT (symbol evidence): the same word or an inflection of the same
 *    word in the request language. "red" is not "reduce", "sea" is not
 *    "season", "yedi" (seven) is not "yedim" (I ate), "su" is not "sunum".
 *  - GENERAL (prose grounding): strict, plus two long words sharing six
 *    leading letters (paraphrase). Short accidental prefixes never count.
 * Turkish suffixes are harmony-agnostic; derivation is never accepted.
 */

/** Turkish-aware lowercase that keeps ş/ç/ğ/ö/ü/ı ("şu" stays "şu"). */
export function lightFold(s: string): string {
  return s
    .normalize('NFC')
    .replace(/I/g, 'ı')
    .replace(/İ/g, 'i')
    .toLowerCase()
    .replace(/\u0307/g, '')
    .replace(/ё/g, 'е');
}

/** Full ASCII fold for general grounding (ı ğ ü ş ö ç → i g u s o c). */
export function asciiFold(s: string): string {
  return s
    .normalize('NFC')
    .toLowerCase()
    .replace(/\u0307/g, '')
    .replace(/ı/g, 'i')
    .replace(/ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/ş/g, 's')
    .replace(/ö/g, 'o')
    .replace(/ç/g, 'c')
    .replace(/ё/g, 'е');
}

type Grammar = {
  vowels: string;
  numerals: Set<string>;
  bareOrPlural: Set<string>;
  dropped: Map<string, string>;
  soft: Map<string, string>;
  t: Record<string, string[]>;
};

const PATTERNS: Record<string, string[]> = {
  plural: ['lAr'], possC: ['Im', 'ImIz', 'In', 'InIz'], possV: ['m', 'mIz', 'nIz', 'yIm'],
  poss3C: ['I'], poss3V: ['sI', 'yI'], loc: ['DA'], locN: ['ndA'], abl: ['DAn'],
  ablN: ['ndAn'], datC: ['A'], datV: ['yA'], datN: ['nA'], accC: ['I'], accV: ['yI'],
  accN: ['nI'], genC: ['In'], genV: ['nIn', 'yIn'], insC: ['lA'], insV: ['ylA'], ki: ['ki'],
  cop: ['ydI', 'ymIş', 'yken', 'yIm', 'yIz', 'DIr', 'ysA'], person: ['m', 'n', 'k', 'nIz', 'lAr'],
};
const NUMERALS = ['iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', 'dokuz', 'yirmi', 'otuz', 'kırk', 'elli', 'altmış', 'yetmiş', 'seksen', 'doksan'];
const DROPPED: Array<[string, string]> = [['şehir', 'şehr'], ['ağız', 'ağz'], ['burun', 'burn'], ['oğul', 'oğl'], ['isim', 'ism'], ['resim', 'resm'], ['akıl', 'akl'], ['fikir', 'fikr'], ['karın', 'karn'], ['boyun', 'boyn'], ['gönül', 'gönl']];

function expand(p: string, ascii: boolean): string[] {
  const i = p.search(/[IAD]/);
  if (i < 0) return [ascii ? asciiFold(p) : p];
  const opts = p[i] === 'I' ? (ascii ? ['i', 'u'] : ['ı', 'i', 'u', 'ü']) : p[i] === 'A' ? ['e', 'a'] : ['d', 't'];
  return opts.flatMap((o) => expand(p.slice(0, i) + o + p.slice(i + 1), ascii));
}

function grammar(ascii: boolean): Grammar {
  const f = (s: string) => (ascii ? asciiFold(s) : s);
  const t: Record<string, string[]> = {};
  for (const [k, v] of Object.entries(PATTERNS)) t[k] = [...new Set(v.flatMap((p) => expand(p, ascii)))];
  return {
    vowels: ascii ? 'aeiouâîû' : 'aeıioöuüâîû',
    numerals: new Set([...NUMERALS.map(f), ...NUMERALS.map(asciiFold)]),
    bareOrPlural: new Set(['altın', 'altin']),
    dropped: new Map(DROPPED.flatMap(([k, v]) => [[f(k), f(v)], [asciiFold(k), asciiFold(v)]])),
    soft: new Map(ascii ? [['p', 'b'], ['t', 'd'], ['k', 'g']] : [['p', 'b'], ['ç', 'c'], ['t', 'd'], ['k', 'ğ']]),
    t,
  };
}

const LIGHT = grammar(false);
const ASCII = grammar(true);

type At = 'stem' | 'numeral' | 'plural' | 'poss' | 'poss3' | 'loc' | 'gen' | 'cop' | 'done';

function parse(g: Grammar, s: string, i: number, at: At, vowelEnd: boolean): boolean {
  if (i === s.length) return true;
  const t = g.t;
  const next = (forms: string[], to: At) =>
    forms.some((f) => s.startsWith(f, i) && parse(g, s, i + f.length, to, g.vowels.includes(f[f.length - 1]!)));
  const kase = (fl: 'c' | 'v' | 'n') =>
    next(fl === 'n' ? t.locN! : t.loc!, 'loc') ||
    next(fl === 'n' ? t.ablN! : t.abl!, 'done') ||
    next(fl === 'c' ? t.datC! : fl === 'v' ? t.datV! : t.datN!, 'done') ||
    next(fl === 'c' ? t.accC! : fl === 'v' ? t.accV! : t.accN!, 'done') ||
    next(fl === 'c' ? t.genC! : t.genV!, 'gen') ||
    next(fl === 'c' ? t.insC! : t.insV!, 'done');
  const fl = vowelEnd ? 'v' : 'c';
  switch (at) {
    case 'stem':
      return next(t.plural!, 'plural') || next(vowelEnd ? t.possV! : t.possC!, 'poss') ||
        next(vowelEnd ? t.poss3V! : t.poss3C!, 'poss3') || kase(fl) || (vowelEnd && next(t.cop!, 'cop'));
    case 'numeral': return kase(fl);
    case 'plural': return next(t.possC!, 'poss') || next(t.poss3C!, 'poss3') || kase('c');
    case 'poss': return kase(fl);
    case 'poss3': return kase('n');
    case 'loc': return next(t.ki!, 'done') || next(t.cop!, 'cop');
    case 'gen': return next(t.ki!, 'done');
    case 'cop': return next(t.person!, 'done');
    default: return false;
  }
}

function accepts(g: Grammar, tail: string, stem: string): boolean {
  if (!tail) return true;
  if (!stem) return false;
  if (g.bareOrPlural.has(stem)) return g.t.plural!.includes(tail);
  return parse(g, tail, 0, g.numerals.has(stem) ? 'numeral' : 'stem', g.vowels.includes(stem[stem.length - 1]!));
}

function alternates(g: Grammar, stem: string): string[] {
  const dropped = g.dropped.get(stem);
  if (dropped) return [dropped];
  if (stem.length < 3 || g.numerals.has(stem)) return [];
  const soft = g.soft.get(stem[stem.length - 1]!);
  const vowels = [...stem].filter((c) => g.vowels.includes(c)).length;
  return soft && vowels >= 2 ? [stem.slice(0, -1) + soft] : [];
}

/** [word] is Turkish [stem] itself or [stem] with a supported inflection. */
export function trInflects(word: string, stem: string, ascii = false): boolean {
  const g = ascii ? ASCII : LIGHT;
  if (word === stem) return true;
  if (word.startsWith(stem) && accepts(g, word.slice(stem.length), stem)) return true;
  return alternates(g, stem).some((alt) => {
    const tail = word.startsWith(alt) ? word.slice(alt.length) : '';
    return tail !== '' && g.vowels.includes(tail[0]!) && accepts(g, tail, stem);
  });
}

function englishBase(w: string): string {
  let base = w;
  for (const tail of ['ing', 'es', 'ed', 's']) {
    if (w.endsWith(tail) && w.length - tail.length >= 3) {
      base = w.slice(0, -tail.length);
      break;
    }
  }
  return base.length >= 4 && base.endsWith('e') ? base.slice(0, -1) : base;
}

function inflected(a: string, b: string, language: AppLanguage, ascii: boolean): boolean {
  if (a === b) return true;
  if (language === 'en') return englishBase(a) === englishBase(b);
  if (language === 'ru') return russianSame(a, b);
  return trInflects(a, b, ascii) || trInflects(b, a, ascii);
}

/** Two-letter function words never checked as symbol evidence. */
export const SHORT_STOP: Record<AppLanguage, Set<string>> = {
  tr: new Set(['ve', 'da', 'de', 'ki', 'mi', 'mı', 'mu', 'mü', 'bu', 'şu', 'ya', 'ne', 'en', 'ile']),
  en: new Set(['an', 'of', 'in', 'on', 'at', 'to', 'is', 'it', 'my', 'me', 'we', 'by', 'or', 'as', 'up', 'so', 'no', 'do', 'be', 'he', 'us', 'am']),
  ru: new Set(['во', 'на', 'не', 'по', 'за', 'из', 'от', 'до', 'же', 'ли', 'бы', 'но', 'он', 'мы', 'ты', 'со', 'ко']),
};

const VERB_HOMOGRAPHS = new Set(['yedi']);
const CLAUSE_WORDS = new Set(['ve', 'ama', 'fakat', 'sonra']);

function closesClause(s: string, end: number): boolean {
  const rest = s.slice(end).trimStart();
  if (!rest || /^[.!?,;:…]/u.test(rest)) return true;
  return CLAUSE_WORDS.has(/^\p{L}+/u.exec(rest)?.[0] ?? '');
}

/**
 * Light-folded told words for strict evidence. In a Turkish narrative a bare
 * homograph closing a clause ("yemek yedi.") is the verb, not the numeral;
 * client-observed symbols are taken as they are.
 */
export function toldWords(narrative: string, symbols: string[], language: AppLanguage): Set<string> {
  const out = new Set<string>();
  const s = lightFold(narrative);
  for (const m of s.matchAll(/[\p{L}\p{N}]+/gu)) {
    const w = m[0];
    if (language === 'tr' && VERB_HOMOGRAPHS.has(w) && closesClause(s, m.index! + w.length)) continue;
    out.add(w);
  }
  for (const symbol of symbols) for (const w of lightFold(symbol).match(/[\p{L}\p{N}]+/gu) ?? []) out.add(w);
  return out;
}

/** STRICT — light-folded words; an ASCII-typed narrative word also meets an ASCII-folded symbol. */
export function sameStrict(symbolWord: string, told: string, language: AppLanguage): boolean {
  if (inflected(symbolWord, told, language, false)) return true;
  return /^[a-z0-9]+$/.test(told) && inflected(asciiFold(symbolWord), told, language, true);
}

/** GENERAL — ASCII-folded words: strict, or a shared six-letter lead. */
export function sameWord(a: string, b: string, language: AppLanguage): boolean {
  if (a.length >= 6 && b.length >= 6 && a.slice(0, 6) === b.slice(0, 6)) return true;
  return inflected(a, b, language, true);
}
