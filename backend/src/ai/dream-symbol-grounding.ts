import type { AppLanguage } from './app-language.js';
import { asciiFold, lightFold, sameStrict, sameWord, toldWords } from './dream-lexical.js';
import { significant, symbolWords } from './dream-quality.js';
import type { DreamData } from './parse-provider.js';

/**
 * Dream Phase 4C.1 — the provider `symbols` array is optional presentation
 * metadata, not a required section. After output safety has judged the raw
 * body (raw symbols included), each item is kept only when it is grounded
 * under the unchanged STRICT contract (`sameStrict`, as in the Phase 2
 * gate); the rest are removed before any quality gate runs and never reach
 * the client, storage or display. An empty array is valid: the client then
 * shows its own on-device symbol presentation.
 *
 * Filtering never hides a prose hallucination: a removed item that a prose
 * section itself names — and that is not merely another form of a told word
 * ("crying" for "cried", "sessizlik" for "sessizce", see `derivationRoot`) —
 * rejects the reading.
 */
export type SymbolGroundingInput = {
  narrative: string;
  symbols: string[];
  emotions: string[];
  language: AppLanguage;
};

export type GroundedSymbols = { data: DreamData; removed: string[] };

function grounded(symbol: string, told: Set<string>, language: AppLanguage): boolean {
  const words = symbolWords(symbol, language);
  return !words.length || words.some((w) => [...told].some((t) => sameStrict(w, t, language)));
}

export function groundDreamSymbols(data: DreamData, input: SymbolGroundingInput): GroundedSymbols {
  // Same precondition as the Phase 2 check: no told evidence, nothing to judge.
  const evidence = [input.narrative, ...input.symbols, ...input.emotions].join(' ');
  if (significant(evidence).size === 0) return { data, removed: [] };
  const told = toldWords(input.narrative, input.symbols, input.language);
  const kept = data.symbols.filter((s) => grounded(s, told, input.language));
  const removed = data.symbols.filter((s) => !kept.includes(s));
  return { data: removed.length ? { ...data, symbols: kept } : data, removed };
}

const words = (s: string) => lightFold(s).match(/[\p{L}\p{N}]+/gu) ?? [];

/**
 * Safe derivation (Phase 4C.1a): one recognised complete suffix is stripped
 * from an ASCII-folded whole word, leaving a root of a minimum length. Never
 * a shared prefix, so door/doorway, water/waterfall, rain/rainbow,
 * fear/fearless, kapı/kapıcı, deniz/denizci, вода/водопад stay distinct.
 * - en: `-ness` on a 4+ root not ending in i (dark/darkness); verb endings
 *   -ing/-ed/-es/-s with i→y on a 3+ root (cried/crying/cries → cry).
 * - tr: adverb -ca/-ce and noun -lik/-luk on a 4+ root (sessizce/sessizlik).
 * - ru: adjective endings and the abstract noun -ота on a 4+ root
 *   (пустой/пустота, тёмный/темнота).
 */
function derivationRoot(word: string, language: AppLanguage): string | null {
  if (language === 'en') {
    const ness = /^([a-z]{4,})ness$/u.exec(word);
    if (ness && !ness[1]!.endsWith('i')) return ness[1]!;
    const root = word.replace(/(?:ing|ed|es|s)$/u, '').replace(/i$/u, 'y');
    return root.length >= 3 ? root : null;
  }
  const rule = language === 'tr' ? /^([a-z]{4,})(?:ca|ce|lik|luk)$/u : /^([а-я]{4,})(?:ый|ий|ой|ая|яя|ое|ее|ые|ие|ота)$/u;
  return rule.exec(word)?.[1] ?? null;
}

const rootOf = (word: string, language: AppLanguage) => derivationRoot(word, language) ?? word;

/** Another form of a told word: the general `sameWord` match, or the same safe-derivation root. */
function looselyTold(word: string, told: Set<string>, language: AppLanguage): boolean {
  const a = asciiFold(word);
  return [...told].some((t) => {
    const b = asciiFold(t);
    return sameWord(a, b, language) || rootOf(a, language) === rootOf(b, language);
  });
}

/** The first removed symbol that the prose itself names as an image. */
export function leakedSymbol(removed: string[], data: DreamData, input: SymbolGroundingInput): string | null {
  const told = toldWords(input.narrative, input.symbols, input.language);
  const prose = [data.summary, data.emotionalTheme, data.interpretation, data.dailyLifeReflection, data.conclusion]
    .flatMap(words);
  for (const symbol of removed) {
    const parts = symbolWords(symbol, input.language);
    if (parts.every((p) => looselyTold(p, told, input.language))) continue;
    const invented = parts.filter((p) => !looselyTold(p, told, input.language));
    if (invented.some((p) => prose.some((w) => sameStrict(p, w, input.language)))) return symbol;
  }
  return null;
}
