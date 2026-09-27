/**
 * Dream Phase 4A.2 / 4A.3 — what one piece of recurrence evidence establishes.
 *
 * A dreamer sentence that says something recurs is evidence only for the
 * words in that sentence. A provider echo may repeat those words (strictly,
 * via `sameStrict`) and generic recurrence wording, nothing else: a generic
 * "this dream keeps coming back" authorizes only a generic echo. There is
 * no coreference inference; an unlinkable subject fails closed.
 *
 * Evidence sources are never combined: one recurrence sentence, or one
 * supplied history item, must carry the claim. "Red" from one sentence and
 * "sea" from another (or from a history item) never make a "red sea".
 */
import type { AppLanguage } from './app-language.js';
import { sameStrict } from './dream-lexical.js';

const rx = (alts: string[]) => new RegExp(`(?<![\\p{L}\\p{N}])(?:${alts.join('|')})`, 'gu');

/** Wording that presents recurrence as ORACLY-recorded rather than user-reported. */
export const SAVED_HISTORY = rx([
  String.raw`(?:saved|recorded|stored|logged|tracked) dreams?`,
  String.raw`(?:your|the|previous|past|earlier) (?:dream )?(?:records?|journal|log|entries)`,
  String.raw`(?:we|oracly|i) (?:have |has |had |'ve )?(?:already )?(?:seen|saw|noticed|recorded|tracked|observed)`,
  String.raw`(?:kaydedilmiş|kayıtlı|kaydettiğin|kaydedilen) rüya\p{L}*`,
  String.raw`kayıtlar\p{L}*`,
  String.raw`(?:oracly|biz) (?:bunu |bu \p{L}+ )?(?:daha önce )?(?:gördü|kaydetti|fark etti)\p{L}*`,
  String.raw`(?:daha önce )?(?:gördük|kaydettik|fark ettik)`,
  String.raw`(?:сохран|записан)\p{L}* сн\p{L}*`,
  String.raw`(?:в |во )?(?:твоих |ваших )?записях`,
  String.raw`(?:мы|oracly) (?:уже )?(?:видел|замечал|записал)\p{L}*`,
]);

const GENERIC = new Set([
  // en
  'the', 'a', 'an', 'this', 'that', 'these', 'those', 'it', 'its', 'is', 'are', 'was', 'were', 'be', 'been',
  'being', 'to', 'of', 'in', 'on', 'at', 'for', 'with', 'by', 'from', 'as', 'and', 'or', 'but', 'so', 'too',
  'also', 'again', 'still', 'once', 'more', 'you', 'your', 'yours', 'i', 'my', 'me', 'we', 'our', 'what',
  'which', 'how', 'when', 'where', 'there', 'here', 'has', 'have', 'had', 'having', 'do', 'does', 'did',
  'can', 'could', 'may', 'might', 'will', 'would', 'should', 'feel', 'feels', 'felt', 'look', 'looks',
  'perhaps', 'maybe', 'possibly', 'likely', 'often', 'sometimes', 'say', 'says', 'said', 'tell', 'told',
  'image', 'scene', 'same', 'similar', 'familiar', 'kind', 'one', 'like', 'just', 'keep', 'keeps', 'kept',
  'come', 'comes', 'coming', 'came', 'back', 'show', 'shows', 'showing', 'up', 'before', 'earlier',
  'previous', 'past', 'prior', 'other', 'time', 'times', 'pattern', 'theme', 'element', 'thread',
  // tr
  'bu', 'şu', 'o', 'bir', 've', 'da', 'de', 'ki', 'mi', 'gibi', 'ile', 'için', 'çok', 'daha', 'önce', 'yine',
  'hâlâ', 'hala', 'sen', 'senin', 'sana', 'seni', 'ben', 'benim', 'imge', 'sahne', 'öğe', 'unsur', 'tema',
  'iz', 'olabilir', 'olarak', 'olan', 'oluyor', 'var', 'vardı', 'sık', 'kez', 'kere', 'defa', 'aynı',
  'benzer', 'tanıdık', 'eden', 'ediyor', 'ettiği', 'etmesi', 'geliyor', 'giriyor', 'dönüyor',
  // ru
  'это', 'этот', 'эта', 'эти', 'этого', 'этом', 'тот', 'он', 'она', 'оно', 'и', 'а', 'но', 'в', 'во', 'на',
  'с', 'со', 'к', 'по', 'из', 'у', 'о', 'об', 'уже', 'опять', 'еще', 'ты', 'тебе', 'тебя', 'твой', 'твои',
  'твоих', 'твоем', 'вы', 'вам', 'ваш', 'ваших', 'я', 'мне', 'мой', 'образ', 'сцена', 'элемент', 'деталь',
  'видимо', 'может', 'возможно', 'будто', 'как', 'что', 'раз', 'такой', 'знакомый', 'часто', 'иногда',
  'быть', 'был', 'была', 'было', 'были', 'есть', 'является',
]);

/** Dream nouns and recurrence / reporting verb families in any inflection. */
const GENERIC_STEM = new RegExp(
  '^(?:' +
    [
      'dream', 'rüya', 'recur', 'return', 'repeat', 'reappear', 'appear', 'seem', 'describ', 'mention',
      'tekrar', 'yinelen', 'anlaşıl', 'görün', 'gözük', 'söyl', 'anlat', 'bahs',
      'сон$', 'сн(?:а|е|у|ом|ы|ов|ам|ами|ах)$', 'снов', 'снит', 'снил', 'снят', 'снишь',
      'повтор', 'возвращ', 'приход', 'появл', 'встречал', 'встречает', 'кажет', 'похож', 'говор', 'описыва', 'рассказ',
    ].join('|') +
    ')',
  'u',
);

/** Numbers are owned by the count gate, which runs first. */
export function isGenericWord(word: string): boolean {
  return GENERIC.has(word) || GENERIC_STEM.test(word) || /^\p{N}+$/u.test(word);
}

/** The words of one evidence source: a dreamer recurrence sentence or a history item. */
export type Evidence = readonly string[];

const bound = (a: string, b: string, language: AppLanguage) => sameStrict(a, b, language) || sameStrict(b, a, language);
const within = (word: string, source: Evidence, language: AppLanguage) => source.some((d) => bound(d, word, language));

/**
 * True when ONE dreamer recurrence sentence grounds every content word of a
 * provider claim (claim wording already removed); sentences are never pooled.
 */
export function echoesDreamer(providerWords: string[], segments: readonly Evidence[], language: AppLanguage): boolean {
  return segments.some((segment) => providerWords.every((w) => isGenericWord(w) || within(w, segment, language)));
}

/**
 * True when a named history item carries the claim alone: no content word
 * outside the item is borrowed from another evidence source.
 */
export function anchoredByItem(
  providerWords: string[],
  item: Evidence,
  others: readonly Evidence[],
  language: AppLanguage,
): boolean {
  return providerWords.every(
    (w) => isGenericWord(w) || within(w, item, language) || !others.some((o) => within(w, o, language)),
  );
}
