import type { AppLanguage } from './app-language.js';

/**
 * Dream Phase 4C.1 — the historical claim unit: the exact words a history
 * claim attributes to the past. Everything inside the unit must be carried
 * by one evidence source (Phase 4A.2–4A.4, unchanged); interpretive
 * commentary outside it is not a claim about history.
 *
 * Only two constructions narrow the unit below the whole sentence:
 *  - appositive / relative: a claim chunk with no content word of its own,
 *    set off by a comma, dash or parenthesis, attaches to the chunk right
 *    before it ("The sea, a recurring symbol in your dreams, might…",
 *    "Спокойствие, которое повторяется в снах, может…"): unit = subject +
 *    claim chunk; the main-clause predicate after it is commentary.
 *  - Turkish nominalized subject clause ending the claim chunk ("Denizin
 *    tekrarlayan bir motif olması, belki de…"): unit = the sentence up to
 *    and including that chunk.
 * Every other claim keeps whole-sentence scope, so "The door keeps coming
 * back, red and heavy" still attributes "red" and "heavy" to history.
 */
export type ClaimUnitTools = {
  /** True when [chunk] itself states recurrence / prior dreams. */
  isClaim: (chunk: string) => boolean;
  /** Content words of [chunk] once claim wording and generic words are removed. */
  content: (chunk: string) => string[];
};

const CHUNK = /\s*(?:[,()[\]:]|\s[-—–]\s|[—–])\s*/u;
const TR_NOMINAL = /\p{L}+m[ae]s[ıi]$/u;

export function claimUnits(sentence: string, language: AppLanguage, tools: ClaimUnitTools): string[] {
  const chunks = sentence.split(CHUNK).map((c) => c.trim()).filter(Boolean);
  const units: string[] = [];
  chunks.forEach((chunk, i) => {
    if (!tools.isClaim(chunk)) return;
    if (i > 0 && tools.content(chunk).length === 0) {
      units.push(`${chunks[i - 1]} ${chunk}`);
      return;
    }
    const last = chunk.split(/\s+/u).pop() ?? '';
    if (language === 'tr' && i < chunks.length - 1 && TR_NOMINAL.test(last)) {
      units.push(chunks.slice(0, i + 1).join(' '));
      return;
    }
    units.push(sentence);
  });
  return units.length ? units : [sentence];
}
