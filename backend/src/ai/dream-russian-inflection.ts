/**
 * Russian strict inflection: one lemma, two case endings. Derivation and
 * accidental shared prefixes never count.
 */
const RU_ENDINGS = new Set(['', 'а', 'я', 'о', 'е', 'ы', 'и', 'у', 'ю', 'ь', 'й', 'ой', 'ей', 'ом', 'ем', 'ам', 'ям', 'ах', 'ях', 'ов', 'ев', 'ью', 'ую', 'юю', 'ая', 'яя', 'ое', 'ее', 'ые', 'ие', 'ий', 'ый', 'ого', 'его', 'ому', 'ему', 'ым', 'им', 'ых', 'их', 'ыми', 'ими', 'ами', 'ями']);

/** Masculine -ок/-ек drops its vowel when inflected: перекрёсток → перекрёстке. */
function russianMobileVowel(nominative: string, form: string): boolean {
  const m = /^(\p{L}{3,})[ое]к$/u.exec(nominative);
  if (!m) return false;
  const stem = `${m[1]}к`;
  return form.length > stem.length && form.startsWith(stem) && RU_ENDINGS.has(form.slice(stem.length));
}

/** Light-folded (ё → е) Russian words that inflect one lemma. */
export function russianSame(a: string, b: string): boolean {
  if (russianMobileVowel(a, b) || russianMobileVowel(b, a)) return true;
  let common = 0;
  while (common < Math.min(a.length, b.length) && a[common] === b[common]) common++;
  for (let k = common; k >= 3; k--) {
    if (RU_ENDINGS.has(a.slice(k)) && RU_ENDINGS.has(b.slice(k))) return true;
  }
  return false;
}
