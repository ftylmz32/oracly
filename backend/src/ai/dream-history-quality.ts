/**
 * Dream Phase 4A — deterministic gate on what a response claims about the
 * dreamer's history. Runs after the Phase 2 quality gate; never relaxes it.
 *
 * Per sentence of the prose fields:
 *  - history_unsupported: a recurrence/prior-dream claim (or a supplied
 *    history count) carried by no single evidence source — neither one named
 *    supplied history item whose own words are every content word (Phase
 *    4A.4) nor one dreamer recurrence sentence that grounds all its content
 *    words (Phases 4A.2/4A.3, see dream-history-echo.ts); or stored-record
 *    wording ("saved dreams", "we have seen") not carried by a named supplied
 *    item. Naming is strict
 *    (`sameStrict`: same word or a real inflection; "rainbow" never names
 *    "rain", "kapıcı" never names "kapı").
 *  - history_absolute: "always / every time / all your dreams" inflation.
 *  - history_count: a dream count that is neither supplied nor told by the
 *    dreamer, or "many dreams / many times" about dreaming.
 *  - history_fate: a recurrence claim turned into fate or diagnosis.
 *  - history_date: a calendar date the narrative does not contain.
 * Negated claims ("not necessarily recurring") are not claims.
 */
import type { AppLanguage } from './app-language.js';
import type { DreamHistoryItem } from './dream-history.js';
import { anchoredByItem, echoesDreamer, type Evidence, SAVED_HISTORY } from './dream-history-echo.js';
import { lightFold, sameStrict } from './dream-lexical.js';
import type { DreamData } from './parse-provider.js';

export type DreamHistoryClaimFailure =
  | 'history_unsupported'
  | 'history_absolute'
  | 'history_count'
  | 'history_fate'
  | 'history_date';

export type DreamHistoryClaimInput = {
  narrative: string;
  history: DreamHistoryItem[] | undefined;
  language: AppLanguage;
};

const rx = (alts: string[]) => new RegExp(`(?<![\\p{L}\\p{N}])(?:${alts.join('|')})`, 'gu');

const CLAIM = rx([
  String.raw`recur\p{L}*`,
  String.raw`(?:previous|past|earlier|prior|other|former|older|recent) dreams?`,
  String.raw`(?:appeared|appears|showed up|shown up|came up|come up|turned up) (?:in your dreams )?before`,
  String.raw`again and again`,
  String.raw`keeps? (?:coming back|returning|reappearing|appearing|showing up|turning up)`,
  String.raw`(?:returns?|returned|comes back|came back|reappears?|reappeared) (?:again )?(?:in|to|into) (?:your |my |the |these )?dreams?`,
  String.raw`(?:often|frequently|repeatedly|keep) dream\p{L}*`,
  String.raw`dream(?:t|ed)? (?:of|about) (?:it|this|that|them) before`,
  String.raw`tekrarla\p{L}*`,
  String.raw`tekrar e[dt]\p{L}*`,
  String.raw`tekrar tekrar`,
  String.raw`(?:önceki|geçmiş|eski|diğer|başka) rüya\p{L}*`,
  String.raw`daha önce(?:ki)? (?:de )?(?:bir )?rüya\p{L}*`,
  String.raw`daha önce de`,
  String.raw`sık sık`,
  String.raw`defalarca`,
  String.raw`dönüp dolaş\p{L}*`,
  String.raw`yine karşına`,
  String.raw`rüyalar\p{L}* (?:tekrar |yine )?(?:gel|gir|dön)\p{L}*`,
  String.raw`повторя\p{L}*`,
  String.raw`снова и снова`,
  String.raw`(?:снова|опять) (?:снит|снят|снил|снишь)\p{L}*`,
  String.raw`(?:прошл|предыдущ|прежн|други|ранн)\p{L}* сн\p{L}*`,
  String.raw`в который раз`,
  String.raw`уже (?:снил|снят|снит|появлял|встречал)\p{L}*`,
  String.raw`часто (?:снит|снят|вид)\p{L}*`,
  String.raw`(?:приходит|возвращается) (?:в|во) (?:твои |ваши )?сн\p{L}*`,
]);

const ABSOLUTE = rx([
  'always', 'every time', 'each time', 'every night', 'constantly', 'forever',
  'her zaman', 'her seferinde', String.raw`hep(?![\p{L}])`, 'her gece', 'sürekli', 'daima',
  'всегда', 'каждый раз', 'каждую ночь', 'постоянно', 'вечно',
]);

const ABSOLUTE_DREAM = rx([
  String.raw`always dream\p{L}*`,
  String.raw`every time you (?:dream|sleep|fall asleep)`,
  String.raw`(?:all|every one) of your dreams`,
  'all your dreams',
  'in every dream',
  String.raw`her rüyan\p{L}*`,
  String.raw`(?:tüm|bütün) rüyalar\p{L}*`,
  String.raw`hep (?:aynı|bu) rüya\p{L}*`,
  String.raw`всегда (?:снит|снят|сни)\p{L}*`,
  String.raw`во всех (?:твоих |ваших )?снах`,
  'в каждом сне',
]);

const FATE = rx([
  String.raw`destin\p{L}*`, String.raw`fate\p{L}*`, 'meant to be', String.raw`omen\p{L}*`,
  String.raw`prophe\p{L}*`, String.raw`trauma\p{L}*`, String.raw`disorder\p{L}*`, 'ptsd',
  String.raw`depress\p{L}*`, String.raw`obsess\p{L}*`, 'unresolved',
  String.raw`kader\p{L}*`, String.raw`alın yazı\p{L}*`, String.raw`alamet\p{L}*`, String.raw`kehanet\p{L}*`,
  String.raw`travma\p{L}*`, String.raw`bozukluk\p{L}*`, String.raw`depresyon\p{L}*`, String.raw`takıntı\p{L}*`,
  String.raw`судьб\p{L}*`, String.raw`предназнач\p{L}*`, String.raw`предзнаменован\p{L}*`, String.raw`пророч\p{L}*`,
  String.raw`травм\p{L}*`, String.raw`расстройств\p{L}*`, String.raw`депресс\p{L}*`, String.raw`навязчив\p{L}*`,
]);

const NUMBER = String.raw`(\d+|two|three|four|five|six|seven|eight|nine|ten|iki|üç|dört|beş|altı|yedi|sekiz|dokuz|два|две|двух|три|трех|четыре|четырех|пять|пяти)`;
const DREAM_COUNT = rx([String.raw`${NUMBER} (?:\p{L}+ ){0,3}(?:dreams|rüya\p{L}*|сн[аеиоуы]\p{L}*|сна)`]);
const TIMES_COUNT = rx([String.raw`${NUMBER} (?:times|kez|kere|defa|раз\p{L}*)`]);
const MANY = rx([
  String.raw`(?:many|countless|numerous|multiple) (?:times|dreams|nights)`,
  String.raw`(?:birçok|pek çok|çok sayıda|sayısız) (?:kez|kere|defa|rüya\p{L}*|gece)`,
  String.raw`(?:много|многих|множество|множестве|бесчисленн\p{L}*) (?:раз|сн\p{L}*|ноч\p{L}*)`,
]);
const DREAM_WORD = rx([String.raw`dream\p{L}*`, String.raw`rüya\p{L}*`, String.raw`сн[аеиоуы]\p{L}*`, 'сон']);
const WORD_VALUES: Record<string, number> = {
  two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10,
  iki: 2, üç: 3, dört: 4, beş: 5, altı: 6, yedi: 7, sekiz: 8, dokuz: 9,
  два: 2, две: 2, двух: 2, три: 3, трех: 3, четыре: 4, четырех: 4, пять: 5, пяти: 5,
};

const MONTHS = 'ocak|şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|ekim|kasım|aralık|january|february|march|april|may|june|july|august|september|october|november|december|января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря';
const DATE = rx([
  String.raw`\d{4}-\d{2}-\d{2}`,
  String.raw`\d{1,2}[./]\d{1,2}[./]\d{2,4}`,
  String.raw`\d{1,2} (?:${MONTHS})`,
  String.raw`(?:${MONTHS}) \d{1,2}(?![\p{N}])`,
]);

const NEGATORS = new Set(['not', 'never', 'no', "isn't", "doesn't", 'hiç', 'не', 'нет', 'ни']);
const POST_NEGATORS = new Set(['değil', 'değildir']);
const ENTRY_WORDS: Record<string, string[]> = {
  'entry:nightmare': ['nightmare', 'kabus', 'кошмар'],
  'entry:clear': ['clear', 'vivid', 'net', 'açık', 'ясн', 'четк'],
  'entry:symbols': ['symbol', 'sembol', 'символ'],
};
const LABEL_STOP = new Set(['had', 'the', 'was', 'there', 'were', 'and', 'bir', 'vardı', 'gördüm', 'был', 'было', 'были']);

const wordsOf = (s: string) => lightFold(s).match(/[\p{L}\p{N}]+/gu) ?? [];

function hits(pattern: RegExp, text: string): RegExpMatchArray[] {
  return [...text.matchAll(pattern)].filter((m) => !negated(text, m.index!, m.index! + m[0].length));
}

function negated(text: string, start: number, end: number): boolean {
  const before = wordsOf(text.slice(0, start)).slice(-4);
  if (before.some((w) => NEGATORS.has(w))) return true;
  return wordsOf(text.slice(end)).slice(0, 3).some((w) => POST_NEGATORS.has(w));
}

/** STRICT binding: the same word or a real inflection of it — never a longer word sharing a prefix. */
function names(segment: string, stems: string[], language: AppLanguage): boolean {
  const told = wordsOf(segment);
  return stems.some((s) => told.some((w) => sameStrict(s, w, language)));
}

function itemStems(item: DreamHistoryItem): string[] {
  return ENTRY_WORDS[item.key] ?? wordsOf(item.label).filter((w) => w.length >= 2 && !LABEL_STOP.has(w));
}

const SENTENCES = /[.!?…;\n]+/u;

/** One word list per dreamer sentence that itself states recurrence; never pooled. */
function dreamerRecurrenceSegments(narrative: string): Evidence[] {
  return narrative
    .split(SENTENCES)
    .filter((segment) => hits(CLAIM, segment).length > 0)
    .map(wordsOf);
}

/** Drops the numbers of count phrases; the count gate has already judged them. */
function withoutCounts(sentence: string): string {
  return [DREAM_COUNT, TIMES_COUNT].reduce((s, p) => s.replace(p, (m, n: string) => m.replace(n, ' ')), sentence);
}

function countValue(raw: string): number {
  return /^\d+$/.test(raw) ? Number(raw) : (WORD_VALUES[raw] ?? -1);
}

export function dreamHistoryClaimViolation(
  data: DreamData,
  input: DreamHistoryClaimInput,
): DreamHistoryClaimFailure | null {
  const history = input.history ?? [];
  const narrative = lightFold(input.narrative);
  const segments = dreamerRecurrenceSegments(narrative);
  const itemWords = history.map(itemStems);
  const allowed = new Set(history.flatMap((i) => [i.priorCount, i.priorCount + 1]));
  const prose = [data.summary, data.emotionalTheme, data.interpretation, data.dailyLifeReflection, data.conclusion];
  for (const field of prose) {
    for (const date of lightFold(field).match(DATE) ?? []) {
      if (!narrative.includes(date)) return 'history_date';
    }
    for (const raw of lightFold(field).split(SENTENCES)) {
      const s = raw.trim();
      if (!s) continue;
      const claim = hits(CLAIM, s).length > 0;
      const named = history.filter((i) => names(s, itemStems(i), input.language));
      if (hits(ABSOLUTE_DREAM, s).length) return 'history_absolute';
      if ((claim || named.length) && hits(ABSOLUTE, s).length) return 'history_absolute';
      if (claim && hits(FATE, s).length) return 'history_fate';
      const about = claim || named.length > 0 || hits(DREAM_WORD, s).length > 0;
      if (about && hits(MANY, s).some((m) => !narrative.includes(m[0]))) return 'history_count';
      const counts = [...hits(DREAM_COUNT, s), ...(claim || named.length ? hits(TIMES_COUNT, s) : [])];
      const invented = counts.filter((m) => !narrative.includes(m[0]));
      if (invented.some((m) => !allowed.has(countValue(m[1]!)))) return 'history_count';
      const saved = hits(SAVED_HISTORY, s).length > 0;
      if (!claim && !saved && !invented.length) continue;
      const words = wordsOf(withoutCounts(s).replace(CLAIM, ' ').replace(SAVED_HISTORY, ' '));
      const viaHistory = history.some(
        (item, i) => named.includes(item) && anchoredByItem(words, itemWords[i]!, input.language),
      );
      if (!viaHistory && (saved || !echoesDreamer(words, segments, input.language))) return 'history_unsupported';
    }
  }
  return null;
}
