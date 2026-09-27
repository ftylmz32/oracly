import type { AppLanguage } from './app-language.js';
import { emotionStances } from './dream-emotion-contract.js';
import { asciiFold, lightFold, sameStrict, sameWord, trInflects } from './dream-lexical.js';
import { isDreamWord, STOP, tokens } from './dream-quality.js';

/**
 * Client delivery parity — the evidence rules the Flutter `DreamAnalysisGuard`
 * applies to every required section, mirrored so a backend PASS is never
 * dropped on device (Phase 4B: no silent premium degradation).
 *
 * 1. Told grounding: a section shares a meaningful word of four or more
 *    letters with the told evidence, or strictly names an observed symbol
 *    or emotion (the client's understanding facts).
 * 2. Catalogue images (TR / EN only): a section never names a catalogue
 *    image the narrative does not tell. A catalogue feeling (fear) is told
 *    when the dreamer names it in any form, negated included.
 */
export const CLIENT_CATALOGUE_IMAGES: ReadonlyArray<{ id: string; en: string; tr: string }> = [
  { id: 'dream_cat', en: 'cat', tr: 'kedi' },
  { id: 'dream_snake', en: 'snake', tr: 'yılan' },
  { id: 'dream_door', en: 'door', tr: 'kapı' },
  { id: 'dream_water', en: 'water', tr: 'su' },
  { id: 'dream_red', en: 'red', tr: 'kırmızı' },
  { id: 'dream_mosque', en: 'mosque', tr: 'cami' },
  { id: 'dream_fear', en: 'fear', tr: 'korku' },
  { id: 'dream_sea', en: 'sea', tr: 'deniz' },
  { id: 'dream_rain', en: 'rain', tr: 'yağmur' },
  { id: 'dream_seven', en: 'seven', tr: 'yedi' },
  { id: 'dream_mother', en: 'mother', tr: 'anne' },
];

/** Client connectors not already in the Phase 2 STOP list (ASCII-folded). */
const CLIENT_CONNECTORS = new Set([
  'being', 'sunu', 'этого', 'которое', 'твое', 'твоем', 'своей',
]);

function meaningful(s: string): Set<string> {
  return new Set(
    tokens(s).filter((w) => w.length >= 4 && !STOP.has(w) && !CLIENT_CONNECTORS.has(w) && !isDreamWord(w)),
  );
}

function words(s: string): string[] {
  return lightFold(s).match(/[\p{L}\p{N}]+/gu) ?? [];
}

/** Directional, like the client `mentions`: the text word is [stem] or [stem] inflected. */
function isForm(word: string, stem: string, language: AppLanguage): boolean {
  if (language !== 'tr') return sameStrict(stem, word, language);
  return trInflects(word, stem) || trInflects(asciiFold(word), asciiFold(stem), true);
}

function names(text: string, token: string, language: AppLanguage): boolean {
  const parts = words(token);
  const ws = words(text);
  return parts.length > 0 && parts.every((p) => ws.some((w) => isForm(w, p, language)));
}

export function touchesTold(
  text: string,
  told: string,
  observed: string[],
  language: AppLanguage,
): boolean {
  const own = meaningful(text);
  const evidence = meaningful(told);
  for (const w of own) for (const e of evidence) if (sameWord(w, e, language)) return true;
  return observed.some((o) => names(text, o, language));
}

export function inventsCatalogueImage(text: string, told: string, language: AppLanguage): boolean {
  if (language === 'ru') return false;
  for (const image of CLIENT_CATALOGUE_IMAGES) {
    const token = language === 'en' ? image.en : image.tr;
    if (!names(text, token, language) || names(told, token, language)) continue;
    if (image.id === 'dream_fear' && emotionStances(told).has('fear')) continue;
    return true;
  }
  return false;
}
