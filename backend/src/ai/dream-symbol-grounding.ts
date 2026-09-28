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
 * ("crying" for "cried", "sessizlik" for "sessizce") — rejects the reading.
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
const enRoot = (w: string) => w.replace(/(?:ing|ed|es|s)$/u, '').replace(/i$/u, 'y');

/** Another form of a told word: general match, a shared 4-letter lead, or English y/ie. */
function looselyTold(word: string, told: Set<string>, language: AppLanguage): boolean {
  const a = asciiFold(word);
  return [...told].some((t) => {
    const b = asciiFold(t);
    if (sameWord(a, b, language)) return true;
    if (a.length >= 4 && b.length >= 4 && a.slice(0, 4) === b.slice(0, 4)) return true;
    return language === 'en' && enRoot(a).length >= 3 && enRoot(a) === enRoot(b);
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
