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
 *  - English contrastive commentary (Phase 4C.2a): a final chunk opening a
 *    new clause with though / although / but / however + its own subject,
 *    with no past or comparative wording ("The sea has appeared before,
 *    though that alone does not establish a shared meaning").
 *  - English cautious predicate (Phase 4C.2a): may / might / could +
 *    suggest / reflect / indicate after a subject already strictly bound
 *    to one supplied history item ("The recurring presence of the sea might
 *    reflect…"): unit = that subject.
 * Every other claim keeps whole-sentence scope, so "The door keeps coming
 * back, red and heavy" still attributes "red" and "heavy" to history.
 */
export type ClaimUnitTools = {
  /** True when [chunk] itself states recurrence / prior dreams. */
  isClaim: (chunk: string) => boolean;
  /** Content words of [chunk] once claim wording and generic words are removed. */
  content: (chunk: string) => string[];
  /** True when every content word of [segment] is carried by one supplied history item. */
  bound: (segment: string) => boolean;
};

const CHUNK = /\s*(?:[,()[\]:]|\s[-—–]\s|[—–])\s*/u;
const TR_NOMINAL = /\p{L}+m[ae]s[ıi]$/u;
const EN_CONTRAST = /^(?:though|although|but|however) (?:that|this|it|its|these|those|they|you|your|what|there|whether|how)\b/u;
const EN_PAST_OR_COMPARED = /\b(?:was|were|had|used|then|earlier|previously|before|last|again|still|anymore|longer|more|less|than|always|never|time|times)\b/u;
const EN_CAUTIOUS = / (?:may|might|could) (?:suggest|reflect|indicate)\p{L}*/u;

function englishUnit(chunks: string[], i: number, tools: ClaimUnitTools): string | null {
  const chunk = chunks[i]!;
  const cautious = EN_CAUTIOUS.exec(chunk);
  if (cautious) {
    const subject = [...chunks.slice(0, i), chunk.slice(0, cautious.index)].join(' ');
    return tools.isClaim(chunk.slice(0, cautious.index)) && tools.bound(subject) ? subject : null;
  }
  const next = chunks[i + 1];
  if (i + 1 === chunks.length - 1 && next && EN_CONTRAST.test(next) && !EN_PAST_OR_COMPARED.test(next)) {
    return chunks.slice(0, i + 1).join(' ');
  }
  return null;
}

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
    const english = language === 'en' ? englishUnit(chunks, i, tools) : null;
    units.push(english ?? sentence);
  });
  return units.length ? units : [sentence];
}
